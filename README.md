# Devmo-split

Addon de Godot para generar recursos `AtlasTexture` a partir de una hoja de imágenes y un JSON, sin crear copias de los píxeles de cada sprite.

## Uso

1. Activa **Devmo-split** en **Proyecto > Ajustes del proyecto > Plugins**.
2. En el dock de la derecha, selecciona el JSON y la hoja de sprites.
3. El addon sugiere la imagen PNG que comparte nombre con el JSON y una carpeta de salida terminada en `_split`.
4. Pulsa **Separar sprites**. Se creará un recurso `.tres` por sprite o frame.

El JSON debe contener un objeto cuyas claves sean nombres de sprites. Cada valor puede ser un objeto con coordenadas `x`, `y`, `w` y `h`, o un array de esos objetos para generar varias regiones con el mismo nombre. Por ejemplo, `PuertaSalir` produce `PuertaSalir_01.tres`, `PuertaSalir_02.tres`, etc. Los campos adicionales de cada objeto se conservan en `split_manifest.json`.

Cada recurso referencia la hoja original mediante `AtlasTexture`; los píxeles no se duplican. Si cambia la imagen, las texturas reflejan el cambio al reimportarse. Si cambian las coordenadas del JSON, vuelve a pulsar **Separar sprites** para actualizar los `.tres`.

Los recursos y el manifiesto se generan en una carpeta `res://` del proyecto. Si ya existe un `.tres` con el mismo nombre, se reemplaza.
