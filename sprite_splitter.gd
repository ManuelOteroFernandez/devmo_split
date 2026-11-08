@tool
extends RefCounted


static func split(json_path: String, image_path: String, output_path: String) -> Dictionary:
	var json_file := FileAccess.open(json_path, FileAccess.READ)
	if json_file == null:
		return {"error": "No se pudo abrir el JSON: %s" % json_path}

	var parser := JSON.new()
	var parse_error := parser.parse(json_file.get_as_text())
	if parse_error != OK:
		return {
			"error": "JSON inválido en la línea %d: %s"
				% [parser.get_error_line(), parser.get_error_message()]
		}
	if typeof(parser.data) != TYPE_DICTIONARY:
		return {"error": "El JSON debe contener un objeto de sprites."}

	if not output_path.begins_with("res://"):
		return {"error": "La carpeta de salida debe estar dentro del proyecto (res://)."}

	var source_image := Image.new()
	var image_error := source_image.load(ProjectSettings.globalize_path(image_path))
	if image_error != OK:
		return {"error": "No se pudo cargar la imagen: %s" % image_path}

	var source_texture := ResourceLoader.load(image_path) as Texture2D
	if source_texture == null:
		return {"error": "Godot no pudo importar la imagen como textura: %s" % image_path}

	var sprites: Array[Dictionary] = []
	var filenames: Dictionary = {}
	for sprite_name: Variant in parser.data:
		if typeof(sprite_name) != TYPE_STRING:
			return {"error": "Todos los nombres de sprite deben ser texto."}

		var definition: Variant = parser.data[sprite_name]
		if typeof(definition) == TYPE_ARRAY:
			for frame_index: int in range(definition.size()):
				var entry := _make_entry(
					sprite_name, definition[frame_index], frame_index, source_image.get_size()
				)
				if entry.has("error"):
					return entry
				if filenames.has(entry["filename"]):
					return {"error": "Dos sprites generan el mismo archivo: %s" % entry["filename"]}
				filenames[entry["filename"]] = true
				sprites.append(entry)
		else:
			var entry := _make_entry(sprite_name, definition, -1, source_image.get_size())
			if entry.has("error"):
				return entry
			if filenames.has(entry["filename"]):
				return {"error": "Dos sprites generan el mismo archivo: %s" % entry["filename"]}
			filenames[entry["filename"]] = true
			sprites.append(entry)

	var output_absolute := ProjectSettings.globalize_path(output_path).simplify_path()
	var json_absolute := ProjectSettings.globalize_path(json_path).simplify_path()
	var image_absolute := ProjectSettings.globalize_path(image_path).simplify_path()
	var manifest_absolute := output_absolute.path_join("split_manifest.json").simplify_path()
	if manifest_absolute.to_lower() == json_absolute.to_lower():
		return {"error": "La carpeta de salida sobrescribiría el JSON de origen."}
	if manifest_absolute.to_lower() == image_absolute.to_lower():
		return {"error": "La carpeta de salida sobrescribiría la imagen de origen."}
	for entry: Dictionary in sprites:
		var target_absolute := output_absolute.path_join(entry["filename"]).simplify_path()
		if target_absolute.to_lower() == json_absolute.to_lower():
			return {"error": "La carpeta de salida sobrescribiría el JSON de origen."}
		if target_absolute.to_lower() == image_absolute.to_lower():
			return {"error": "La carpeta de salida sobrescribiría la imagen de origen."}

	var directory_error := DirAccess.make_dir_recursive_absolute(output_absolute)
	if directory_error != OK:
		return {"error": "No se pudo crear la carpeta de salida: %s" % output_path}

	var manifest: Array[Dictionary] = []
	for entry: Dictionary in sprites:
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = source_texture
		atlas_texture.region = Rect2(entry["rect"])
		var save_error := ResourceSaver.save(
			atlas_texture, output_absolute.path_join(entry["filename"])
		)
		if save_error != OK:
			return {
				"error": "No se pudo guardar el recurso AtlasTexture '%s' (código %d)."
					% [entry["filename"], save_error]
			}
		manifest.append({
			"name": entry["name"],
			"file": entry["filename"],
			"region": {
				"x": entry["rect"].position.x,
				"y": entry["rect"].position.y,
				"w": entry["rect"].size.x,
				"h": entry["rect"].size.y,
			},
			"metadata": entry["metadata"],
		})

	var manifest_file := FileAccess.open(output_absolute.path_join("split_manifest.json"), FileAccess.WRITE)
	if manifest_file == null:
		return {"error": "No se pudo crear split_manifest.json en la carpeta de salida."}
	manifest_file.store_string(JSON.stringify({
		"image": image_path,
		"sprites": manifest,
	}, "\t"))

	return {"count": sprites.size(), "output_path": output_path}


static func _make_entry(
	sprite_name: String, definition: Variant, frame_index: int, image_size: Vector2i
) -> Dictionary:
	if typeof(definition) != TYPE_DICTIONARY:
		return {"error": "La definición de '%s' debe ser un objeto." % sprite_name}

	var coordinates := ["x", "y", "w", "h"]
	for coordinate: String in coordinates:
		if not definition.has(coordinate):
			return {
				"error": "Falta la coordenada entera '%s' en '%s'."
					% [coordinate, sprite_name]
			}
		var value: Variant = definition[coordinate]
		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			return {
				"error": "La coordenada '%s' de '%s' debe ser un número entero."
					% [coordinate, sprite_name]
			}
		if typeof(value) == TYPE_FLOAT:
			if value != floor(value) or abs(value) > 2147483647.0:
				return {
					"error": "La coordenada '%s' de '%s' debe ser un número entero válido."
						% [coordinate, sprite_name]
				}

	var x := int(definition["x"])
	var y := int(definition["y"])
	var width := int(definition["w"])
	var height := int(definition["h"])
	if x < 0 or y < 0 or width <= 0 or height <= 0:
		return {"error": "El rectángulo de '%s' tiene coordenadas o dimensiones inválidas." % sprite_name}
	if x + width > image_size.x or y + height > image_size.y:
		return {
			"error": "El rectángulo de '%s' queda fuera de la imagen (%d x %d)."
				% [sprite_name, image_size.x, image_size.y]
		}

	var safe_name := sprite_name.validate_filename()
	if safe_name.is_empty():
		return {"error": "El nombre de sprite '%s' no es válido como archivo." % sprite_name}
	var frame_suffix := "_%02d" % (frame_index + 1) if frame_index >= 0 else ""

	return {
		"name": sprite_name,
		"filename": "%s%s.tres" % [safe_name, frame_suffix],
		"rect": Rect2i(x, y, width, height),
		"metadata": definition.duplicate(true),
	}
