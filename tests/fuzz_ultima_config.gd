extends SceneTree
## «Partida rápida» (Main._repetir_ultima) con un ultima_config.json dañado: 300 mutaciones del partido guardado (clave borrada, retipada, valores como -1, 10^6,
## null, texto, {} o []). Propiedades: (1) nunca hay SCRIPT ERROR ni queda el juego sin pantalla o sin motor; (2) siempre se llega a la pantalla del día en campaña,
## con los indicadores finitos y en 0..100; (3) un archivo que ValidarGuardado.partido_valido rechaza se descarta y se reemplaza por un partido válido (el de
## por defecto); (4) lo que queda escrito en ultima_config.json es siempre un partido válido. Respalda y restaura los archivos de usuario.
## Uso: godot --headless --path . -s tests/fuzz_ultima_config.gd -- [mutaciones] [semilla]

const ARCHIVOS := ["ultima_config.json", "guardado.json", "guardado.cache", "guardado.bak"]
var _fallos := 0
var _descartadas := 0
var _aceptadas := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ ULTIMA: ", msg)


func _otro(v: Variant, rng: RandomNumberGenerator) -> Variant:
	var cand: Array = ["texto", [], {}, true, null, -1, 1000000.0, -1000000.0, 0.0]
	var res: Array = cand.filter(func(x: Variant) -> bool: return typeof(x) != typeof(v) or (typeof(v) == TYPE_FLOAT and x is float and x != v))
	return res[rng.randi_range(0, res.size() - 1)]


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 300
	var rng := RandomNumberGenerator.new()
	rng.seed = int(args[1]) if args.size() > 1 else 5
	for a in ARCHIVOS:
		if FileAccess.file_exists("user://" + a):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a), ProjectSettings.globalize_path("user://" + a + ".bak_ult"))
	Tutorial.ruta = "user://preferencias_ultima.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var datos: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var base := GeneradorPartido.construir_partido_afiliado("propio", {}, "Prueba", "PRU", "metropolitana", resp, datos["ideologia"], datos["leyes"]["afiliacion"])
	GeneradorPartido.aplicar_habilidad(base, String(datos["leyes"]["habilidades"]["defecto"]), String(datos["leyes"]["habilidades"]["colores"][0]), datos["leyes"]["habilidades"])
	base["dificultad"] = "normal"
	base = JSON.parse_string(JSON.stringify(base))
	for i in range(n):
		var p: Dictionary = base.duplicate(true)
		var destino: Dictionary = p if rng.randf() < 0.5 else p["indicadores_iniciales"]
		var ks: Array = destino.keys()
		var k: String = ks[rng.randi_range(0, ks.size() - 1)]
		if rng.randf() < 0.4:
			destino.erase(k)
		else:
			destino[k] = _otro(destino[k], rng)
		var valido := ValidarGuardado.partido_valido(p)
		var f := FileAccess.open("user://ultima_config.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(p))
		f.close()
		main._repetir_ultima()
		await process_frame
		var ctx := "mutación %d" % i
		_check(main._pantalla is PantallaDia and main.motor != null, "%s: no se llegó a la pantalla del día con motor" % ctx)
		if main.motor != null:
			_check(main.motor.estado.etapa == "campana", "%s: la partida rápida no empieza en campaña (%s)" % [ctx, main.motor.estado.etapa])
			for ind in main.motor.estado.indicadores:
				var v := float(main.motor.estado.indicadores[ind])
				_check(is_finite(v) and (ind == "viviendas_anio" or (v >= -0.001 and v <= 100.001)), "%s: indicador %s fuera de rango (%s)" % [ctx, ind, str(v)])
		var escrito: Variant = Datos.leer_json("user://ultima_config.json")
		_check(ValidarGuardado.partido_valido(escrito), "%s: ultima_config.json quedó con un partido inválido" % ctx)
		if valido:
			_aceptadas += 1
		else:
			_descartadas += 1
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	for a in ARCHIVOS:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + a))
		if FileAccess.file_exists("user://" + a + ".bak_ult"):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a + ".bak_ult"), ProjectSettings.globalize_path("user://" + a))
	print("FUZZ ULTIMA CONFIG %s (%d mutaciones: %d válidas aceptadas, %d inválidas descartadas, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _aceptadas, _descartadas, _fallos])
	quit(1 if _fallos > 0 else 0)
