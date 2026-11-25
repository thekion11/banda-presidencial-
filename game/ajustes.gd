class_name Ajustes
extends RefCounted
## Preferencias del jugador (sonido, vibración, animaciones). Se guardan en user://ajustes.json; todo es opcional y el juego funciona igual sin el archivo.

const RUTA := "user://ajustes.json"
static var sonido: bool = true
static var vibracion: bool = true
static var animaciones: bool = true


static func cargar() -> void:
	if not FileAccess.file_exists(RUTA):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	if d is Dictionary:
		sonido = bool(d.get("sonido", true))
		vibracion = bool(d.get("vibracion", true))
		animaciones = bool(d.get("animaciones", true))


static func guardar() -> void:
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"sonido": sonido, "vibracion": vibracion, "animaciones": animaciones}))


static func leer(clave: String) -> bool:
	match clave:
		"sonido": return sonido
		"vibracion": return vibracion
		_: return animaciones


static func poner(clave: String, valor: bool) -> void:
	match clave:
		"sonido": sonido = valor
		"vibracion": vibracion = valor
		_: animaciones = valor
