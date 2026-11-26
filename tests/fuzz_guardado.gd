extends SceneTree
## Fuzz de guardado.json dañado en el contenido (no en el texto): mutaciones estructurales que conservan «huella_datos», «semilla» y «entradas» (clave borrada
## o retipada en el partido o en una entrada, entrada que no es diccionario, tipo de entrada desconocido). Propiedad: toda mutación que ValidarGuardado acepta
## debe poder reproducirse (Partida.reproducir no devuelve null ni da error de script); las que rechaza, no llegan al motor. El guardado intacto debe ser
## válido y reproducirse con la misma huella. «MUT n» se imprime antes de cada mutación para ubicar un SCRIPT ERROR.
## Uso: godot --headless --path . -s tests/fuzz_guardado.gd -- [mutaciones] [semilla]

var _datos: Dictionary
var _huella: String
var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ GUARDADO: ", msg)


func _otro_tipo(v: Variant, rng: RandomNumberGenerator) -> Variant:
	var cand: Array = ["texto", [], {}, true, null, -1]
	var res: Array = cand.filter(func(x: Variant) -> bool: return typeof(x) != typeof(v))
	return res[rng.randi_range(0, res.size() - 1)]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 120
	var semilla := int(args[1]) if args.size() > 1 else 77
	_datos = Datos.cargar_todo()
	_huella = Datos.huella(_datos)
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var resp: Array[Dictionary] = []
	for p in _datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var m := Partida.crear(_datos, semilla, GeneradorPartido.construir_partido("G", "GGG", "metropolitana", resp, _datos["ideologia"]))
	for _t in range(8):
		Bots.jugar_turno(m, "completo", rng)
		m.terminar_turno()
	Bots.elegir(m, _datos, "codicioso", rng)
	for _t in range(25):
		if m.estado.etapa != "gobierno":
			break
		Bots.jugar_turno(m, "completo", rng)
		m.terminar_turno()
	var base: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(_huella)))
	print("GUARDADO BASE: %d entradas, etapa %s" % [base["entradas"].size(), m.estado.etapa])
	_check(ValidarGuardado.guardado_valido(base), "el guardado intacto debe ser válido")
	_check(Partida.reproducir(_datos, base).estado.calcular_huella() == m.estado.calcular_huella(), "el guardado intacto debe reproducirse con la misma huella")
	var aceptadas := 0
	var rechazadas := 0
	var tipos_entrada := {}
	for e in base["entradas"]:
		tipos_entrada[e["tipo"]] = true
	print("TIPOS DE ENTRADA: ", tipos_entrada.keys())
	for i in range(n):
		var g: Dictionary = base.duplicate(true)
		var desc := ""
		match rng.randi_range(0, 6):
			0:  # clave de nivel superior retipada (no huella, semilla ni entradas)
				var k: String = ["partido", "version"][rng.randi_range(0, 1)]
				g[k] = _otro_tipo(g[k], rng)
				desc = "superior %s retipada" % k
			1:  # clave del partido borrada
				var ks: Array = g["partido"].keys()
				var k := String(ks[rng.randi_range(0, ks.size() - 1)])
				g["partido"].erase(k)
				desc = "partido sin «%s»" % k
			2:  # clave del partido retipada
				var ks: Array = g["partido"].keys()
				var k := String(ks[rng.randi_range(0, ks.size() - 1)])
				g["partido"][k] = _otro_tipo(g["partido"][k], rng)
				desc = "partido «%s» retipada" % k
			3:  # entrada: clave borrada
				var j := rng.randi_range(0, g["entradas"].size() - 1)
				var ks: Array = g["entradas"][j].keys()
				var k := String(ks[rng.randi_range(0, ks.size() - 1)])
				g["entradas"][j].erase(k)
				desc = "entrada %d (%s) sin «%s»" % [j, g["entradas"][j].get("tipo", "?"), k]
			4:  # entrada: valor retipado
				var j := rng.randi_range(0, g["entradas"].size() - 1)
				var ks: Array = g["entradas"][j].keys()
				var k := String(ks[rng.randi_range(0, ks.size() - 1)])
				g["entradas"][j][k] = _otro_tipo(g["entradas"][j][k], rng)
				desc = "entrada %d (%s) «%s» retipada" % [j, g["entradas"][j].get("tipo", "?"), k]
			6:  # valor del tipo correcto pero absurdo (índice enorme o negativo, ministro, región o evento inexistentes): pasa la validación de tipos
				var j := rng.randi_range(0, g["entradas"].size() - 1)
				var ks: Array = g["entradas"][j].keys().filter(func(x: Variant) -> bool: return String(x) != "tipo")
				if ks.is_empty():
					continue
				var k := String(ks[rng.randi_range(0, ks.size() - 1)])
				var v: Variant = g["entradas"][j][k]
				if v is String:
					g["entradas"][j][k] = ["no_existe", "zzz", "", "min_otro_partido", "x".repeat(500)][rng.randi_range(0, 4)]
				elif v is int or v is float:
					g["entradas"][j][k] = [1000000000, -1000000000, 99, -1, 2147483647, 0][rng.randi_range(0, 5)]
				elif v is bool:
					g["entradas"][j][k] = not v
				desc = "entrada %d (%s) «%s» con valor absurdo %s" % [j, g["entradas"][j].get("tipo", "?"), k, str(g["entradas"][j][k]).left(14)]
			5:  # entrada que no es diccionario, o tipo desconocido
				var j := rng.randi_range(0, g["entradas"].size() - 1)
				if rng.randf() < 0.5:
					g["entradas"][j] = _otro_tipo({}, rng)
					desc = "entrada %d no es diccionario" % j
				else:
					g["entradas"][j]["tipo"] = "tipo_desconocido"
					desc = "entrada %d de tipo desconocido" % j
		print("MUT %d: %s" % [i, desc])
		if not ValidarGuardado.guardado_valido(g):
			rechazadas += 1
			continue
		aceptadas += 1
		var r := Partida.reproducir(_datos, g)
		_check(r != null, "la mutación %d («%s») pasó la validación pero reproducir devolvió null" % [i, desc])
	print("FUZZ GUARDADO %s (%d mutaciones: %d rechazadas, %d aceptadas y reproducidas, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, rechazadas, aceptadas, _fallos])
	quit(1 if _fallos > 0 else 0)
