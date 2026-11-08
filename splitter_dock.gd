@tool
extends VBoxContainer

const SPRITE_SPLITTER = preload("res://addons/devmo_split/sprite_splitter.gd")

var _json_edit: LineEdit
var _image_edit: LineEdit
var _output_edit: LineEdit
var _status_label: Label
var _json_dialog: EditorFileDialog
var _image_dialog: EditorFileDialog
var _output_dialog: EditorFileDialog
var _split_button: Button


func _ready() -> void:
	name = "Devmo Split"
	custom_minimum_size = Vector2(280, 0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_make_heading("Devmo Split"))
	add_child(_make_description(
		"Crea AtlasTexture .tres que referencian la hoja sin duplicar sus píxeles."
	))

	_json_edit = _make_path_row("JSON", _on_choose_json)
	_image_edit = _make_path_row("Imagen", _on_choose_image)
	_output_edit = _make_path_row("Salida", _on_choose_output)
	add_child(_json_edit.get_parent())
	add_child(_image_edit.get_parent())
	add_child(_output_edit.get_parent())

	_split_button = Button.new()
	_split_button.text = "Separar sprites"
	_split_button.pressed.connect(_on_split_pressed)
	add_child(_split_button)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status_label)

	_setup_dialogs()


func _make_heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	return label


func _make_description(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_path_row(label_text: String, callback: Callable) -> LineEdit:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 52
	row.add_child(label)

	var path_edit := LineEdit.new()
	path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(path_edit)

	var button := Button.new()
	button.text = "..."
	button.pressed.connect(callback)
	row.add_child(button)

	return path_edit


func _setup_dialogs() -> void:
	_json_dialog = EditorFileDialog.new()
	_json_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_json_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_json_dialog.add_filter("*.json", "JSON Files")
	_json_dialog.file_selected.connect(_on_json_selected)
	add_child(_json_dialog)

	_image_dialog = EditorFileDialog.new()
	_image_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_image_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_image_dialog.add_filter("*.png,*.webp,*.jpg,*.jpeg", "Image Files")
	_image_dialog.file_selected.connect(_on_image_selected)
	add_child(_image_dialog)

	_output_dialog = EditorFileDialog.new()
	_output_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	_output_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_output_dialog.dir_selected.connect(_on_output_selected)
	add_child(_output_dialog)


func _on_choose_json() -> void:
	_json_dialog.popup_centered_ratio(0.7)


func _on_choose_image() -> void:
	_image_dialog.popup_centered_ratio(0.7)


func _on_choose_output() -> void:
	_output_dialog.popup_centered_ratio(0.7)


func _on_json_selected(path: String) -> void:
	_json_edit.text = path
	var base_path := path.get_basename()
	_image_edit.text = base_path + ".png"
	_output_edit.text = path.get_base_dir().path_join(
		path.get_file().get_basename() + "_split"
	)


func _on_image_selected(path: String) -> void:
	_image_edit.text = path


func _on_output_selected(path: String) -> void:
	_output_edit.text = path


func _on_split_pressed() -> void:
	_status_label.text = ""
	_split_button.disabled = true
	var result: Dictionary = SPRITE_SPLITTER.split(
		_json_edit.text.strip_edges(),
		_image_edit.text.strip_edges(),
		_output_edit.text.strip_edges()
	)
	_split_button.disabled = false

	if result.has("error"):
		_show_status(result["error"], Color(1.0, 0.35, 0.35))
		return

	EditorInterface.get_resource_filesystem().scan()
	_show_status(
		"Se sincronizaron %d AtlasTexture en %s."
			% [result["count"], result["output_path"]],
		Color(0.4, 1.0, 0.55)
	)


func _show_status(message: String, color: Color) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", color)
