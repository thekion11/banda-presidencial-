class_name Datos
extends RefCounted
## Carga de los JSON de data/ (única fuente de números del juego).

const ARCHIVOS: Array[String] = ["cartas", "eventos", "leyes", "ministros", "ideologia", "regiones", "propuestas", "fuentes"]


static func leer_json(ruta: String) -> Variant:
	var texto := FileAccess.get_file_as_string(ruta)
	if texto == "":
		push_error("No se pudo leer %s" % ruta)
		return null
	return JSON.parse_string(texto)


static func cargar_todo(base: String = "res://data/") -> Dictionary:
	var d := {}
	for n in ARCHIVOS:
		d[n] = leer_json("%s%s.json" % [base, n])
	d["grafo"] = leer_json(base + "geo/grafo_urbano.json")
	d["sectra"] = leer_json(base + "sectra_planes.json")
	return d
