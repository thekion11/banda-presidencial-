class_name Ajustes
extends RefCounted
## Preferencias del jugador (sonido, vibración, animaciones). Se guardan en user://ajustes.json; todo es opcional y el juego funciona igual sin el archivo.

const RUTA := "user://ajustes.json"
static var sonido: bool = true
static var vibracion: bool = true
static var animaciones: bool = true
static var texto_grande: bool = false  # letra un 15 % mayor en las etiquetas con ajuste de línea
static var daltonico: bool = false  # escala de aprobación azul-naranja (Okabe-Ito) en lugar de verde-rojo
static var musica: bool = true  # música ambiente por etapa (Musica)
static var reducir: bool = false  # reducir movimiento: sin temblores, golpes de cámara, destellos ni partículas


static func cargar() -> void:
	if not FileAccess.file_exists(RUTA):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	if d is Dictionary:
		sonido = bool(d.get("sonido", true))
		vibracion = bool(d.get("vibracion", true))
		animaciones = bool(d.get("animaciones", true))
		texto_grande = bool(d.get("texto_grande", false))
		daltonico = bool(d.get("daltonico", false))
		musica = bool(d.get("musica", true))
		reducir = bool(d.get("reducir", false))


static func guardar() -> void:
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"sonido": sonido, "vibracion": vibracion, "animaciones": animaciones, "texto_grande": texto_grande, "daltonico": daltonico, "musica": musica, "reducir": reducir}))


static func leer(clave: String) -> bool:
	match clave:
		"sonido": return sonido
		"vibracion": return vibracion
		"texto_grande": return texto_grande
		"daltonico": return daltonico
		"musica": return musica
		"reducir": return reducir
		_: return animaciones


static func poner(clave: String, valor: bool) -> void:
	match clave:
		"sonido": sonido = valor
		"vibracion": vibracion = valor
		"texto_grande": texto_grande = valor
		"daltonico": daltonico = valor
		"musica":
			musica = valor
			Musica.al_cambiar_ajuste()
		"reducir": reducir = valor
		_: animaciones = valor
