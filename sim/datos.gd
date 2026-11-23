class_name Datos
extends RefCounted
## Carga de los JSON de data/ (única fuente de números del juego).

const ARCHIVOS: Array[String] = ["cartas", "eventos", "leyes", "ministros", "ideologia", "regiones", "propuestas", "fuentes", "metas"]


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
	var reales: Variant = leer_json(base + "cartas_reales.json")  # generado por tools/generar_cartas.py desde datos públicos
	if reales is Array:
		d["cartas"] = Array(d["cartas"]) + Array(reales)
	var evs: Variant = leer_json(base + "juego_eventos_reales.json")  # generado por tools/generar_eventos.py
	if evs is Array:
		d["eventos"] = Array(d["eventos"]) + Array(evs)
	d["grafo"] = leer_json(base + "geo/grafo_urbano.json")
	d["sectra"] = leer_json(base + "sectra_planes.json")
	return d


static func huella(d: Dictionary) -> String:
	## SHA-256 de los datos que afectan al resultado de la simulación. Un guardado solo es reproducible con la misma huella.
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	for n in ["cartas", "eventos", "leyes", "ministros", "ideologia", "regiones", "propuestas", "sectra", "grafo", "metas"]:
		hc.update(JSON.stringify(d.get(n, {}), "", true).to_utf8_buffer())
	return hc.finish().hex_encode()
