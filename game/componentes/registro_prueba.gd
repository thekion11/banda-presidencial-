class_name RegistroPrueba
extends RefCounted
## Registro LOCAL para las pruebas con personas: una línea JSON por acción en user://registro_prueba.jsonl.
## No sale del teléfono: el jugador lo copia a mano desde «Informe de prueba». No guarda datos personales.

const RUTA := "user://registro_prueba.jsonl"
const MAX_LINEAS := 1500

static var _n: int = -1  # líneas del archivo (se cuentan una vez)


static func anotar(tipo: String, motor: MotorTurno, huella: String, extra: Dictionary = {}) -> void:
	if motor == null:
		return
	var e := motor.estado
	var linea := {"t": int(Time.get_unix_time_from_system()), "ev": tipo, "sem": e.semilla, "d": huella.substr(0, 8), "etapa": e.etapa,
			"turno": e.turno_actual, "ap": snappedf(e.ind("aprobacion"), 0.1), "mov": e.pa_actual, "ent": e.entradas.size(),
			"fps": int(Engine.get_frames_per_second()), "mem": int(OS.get_static_memory_usage() / 1048576.0)}
	linea.merge(extra)
	if _n < 0:  # primera vez en esta ejecución: se cuentan las líneas existentes una sola vez
		_n = FileAccess.get_file_as_string(RUTA).split("\n", false).size() if FileAccess.file_exists(RUTA) else 0
	if _n > MAX_LINEAS + 200:  # el archivo se recorta de vez en cuando; el resto de las veces solo se añade una línea (antes se releía y reescribía entero)
		var lineas := FileAccess.get_file_as_string(RUTA).split("\n", false)
		lineas = lineas.slice(lineas.size() - MAX_LINEAS)
		var fr := FileAccess.open(RUTA, FileAccess.WRITE)
		if fr != null:
			fr.store_string("\n".join(lineas) + "\n")
			_n = lineas.size()
	var f := FileAccess.open(RUTA, FileAccess.READ_WRITE if FileAccess.file_exists(RUTA) else FileAccess.WRITE)
	if f != null:
		f.seek_end()
		f.store_line(JSON.stringify(linea))
		_n += 1


static func informe() -> String:
	var v: Variant = Datos.leer_json("res://data/version.json")
	var cab: Array[String] = []
	var vd: Dictionary = v if v is Dictionary else {}
	cab.append("PRESIDENTE DE CHILE · informe de prueba")
	cab.append("versión %s · commit %s · compilado %s UTC" % [vd.get("version", "?"), vd.get("commit", "?"), vd.get("fecha_utc", "?")])
	cab.append("dispositivo: %s · %s · pantalla %s · motor Godot %s" % [OS.get_model_name(), OS.get_name(), DisplayServer.window_get_size(), Engine.get_version_info().get("string", "?")])
	var por_semilla := {}
	var fps_min := 999
	var mem_max := 0
	var finales: Array[String] = []
	if FileAccess.file_exists(RUTA):
		for l in FileAccess.get_file_as_string(RUTA).split("\n", false):
			var d: Variant = JSON.parse_string(l)
			if not d is Dictionary:
				continue
			var s := str(d["sem"])
			if not por_semilla.has(s):
				por_semilla[s] = {"acciones": 0, "turno_max": 0, "etapa": "", "ap": 0.0, "t0": int(d["t"]), "t1": int(d["t"])}
			var p: Dictionary = por_semilla[s]
			p["acciones"] = int(p["acciones"]) + 1
			p["turno_max"] = maxi(int(p["turno_max"]), int(d["turno"]))
			p["etapa"] = d["etapa"]
			p["ap"] = d["ap"]
			p["t1"] = int(d["t"])
			if int(d["fps"]) > 0:
				fps_min = mini(fps_min, int(d["fps"]))
			mem_max = maxi(mem_max, int(d["mem"]))
			if d["ev"] == "fin":
				finales.append("semilla %s: %s, puntaje %s" % [s, d.get("motivo", "?"), d.get("puntaje", "?")])
	cab.append("partidas registradas: %d · fps mínimo observado: %s · memoria estática máx: %d MB" % [por_semilla.size(), str(fps_min) if fps_min < 999 else "?", mem_max])
	for s in por_semilla.keys():
		var p: Dictionary = por_semilla[s]
		cab.append("- semilla %s: %d acciones, turno máx %d, etapa %s, aprobación %s, duración %d min" % [s, p["acciones"], p["turno_max"], p["etapa"], p["ap"], int((int(p["t1"]) - int(p["t0"])) / 60)])
	if por_semilla.is_empty():
		cab.append("Todavía no hay partidas registradas: juega una partida y vuelve aquí; el informe se llena solo con tus acciones (turno, aprobación, fps y memoria).")
	for f in finales:
		cab.append("  fin · " + f)
	cab.append("")
	cab.append("Cuéntame también: ¿qué te confundió?, ¿ganaste la elección?, ¿se trabó o se vio mal algo?, ¿qué cambiarías?")
	return "\n".join(cab)
