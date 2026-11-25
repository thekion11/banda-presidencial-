class_name Datos
extends RefCounted
## Carga de los JSON de data/ (única fuente de números del juego).

const ARCHIVOS: Array[String] = ["cartas", "eventos", "leyes", "ministros", "ideologia", "regiones", "propuestas", "fuentes", "metas", "asesores", "coalicion"]


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
	if FileAccess.file_exists(base + "cartas_curadas.json"):  # cartas diseñadas a mano con riesgo, efecto a futuro y texto propio (Fase B)
		var curadas: Variant = leer_json(base + "cartas_curadas.json")
		if curadas is Array:
			d["cartas"] = Array(d["cartas"]) + Array(curadas)
	var evs: Variant = leer_json(base + "juego_eventos_reales.json")  # generado por tools/generar_eventos.py
	if evs is Array:
		d["eventos"] = Array(d["eventos"]) + Array(evs)
	d["grafo"] = leer_json(base + "geo/grafo_urbano.json")
	d["sectra"] = leer_json(base + "sectra_planes.json")
	return d


static func huella(d: Dictionary) -> String:
	## SHA-256 de los datos que afectan al resultado de la simulación. Un guardado solo es reproducible con la misma huella.
	var partes := {}
	for n in ["cartas", "eventos", "leyes", "ministros", "ideologia", "regiones", "propuestas", "sectra", "grafo", "metas", "asesores", "coalicion"]:
		partes[n] = d.get(n, {})
	return Huella.sha(partes)


const EXTRAS: Array[String] = ["cartas_reales.json", "cartas_curadas.json", "juego_eventos_reales.json", "geo/grafo_urbano.json", "sectra_planes.json"]


static func clave_archivos(base: String = "res://data/") -> String:
	## SHA-256 nativo (milisegundos) de los archivos de los que sale `cargar_todo`: identifica una versión exacta de los datos.
	var partes: PackedStringArray = []
	for n in ARCHIVOS:
		partes.append(FileAccess.get_sha256("%s%s.json" % [base, n]))
	for n in EXTRAS:
		partes.append(FileAccess.get_sha256(base + n))
	return "\n".join(partes).sha256_text()


static func huella_rapida(d: Dictionary, cache: String = "user://huella_datos.json", base: String = "res://data/") -> String:
	## Igual que `huella(d)` para datos recién cargados, pero la primera vez la guarda junto a la clave de los archivos: los arranques
	## siguientes (misma versión de la app) se ahorran el cálculo, que en un teléfono modesto tarda ~2 s. No usar con datos modificados en memoria.
	var clave := clave_archivos(base)
	if FileAccess.file_exists(cache):
		var c: Variant = JSON.parse_string(FileAccess.get_file_as_string(cache))
		if c is Dictionary and String(c.get("clave", "")) == clave and String(c.get("huella", "")).length() == 64:
			return String(c["huella"])
	var h := huella(d)
	var f := FileAccess.open(cache, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"clave": clave, "huella": h}))
	return h
