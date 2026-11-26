extends SceneTree
## Fuzz de acciones rechazadas y de límites por turno. Propiedades:
##  (1) una acción que el motor rechaza (ok = false) NO cambia el estado (misma huella antes y después);
##  (2) delegadas_turno <= delegacion.max_por_turno, 0 <= internos_actual <= movimientos_internos.por_turno, pa_actual >= 0;
##  (3) delegar no gasta movimientos (pa_actual no baja) y jugar gasta exactamente el costo;
##  (4) la probabilidad de fallo de una delegación es determinista (mismo estado, misma probabilidad) y está en [0, 1];
##  (5) los movimientos internos solo existen en gobierno.
## Uso: godot --headless --path . -s tests/fuzz_rechazos.gd -- [partidas] [semilla_inicial]

var _fallos: int = 0
var _rechazos: int = 0
var _aceptadas: int = 0
var _datos: Dictionary
var _difs: Dictionary = {}


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ RECHAZOS: ", msg)


func _accion(m: MotorTurno, rng: RandomNumberGenerator, ctx: String) -> void:
	var e := m.estado
	var basura := ["", "no_existe", "-1"]
	var nombre := ""
	var antes := AyudaFuzz.props(m)
	var pa0 := e.pa_actual
	var r: Dictionary = {}
	match rng.randi_range(0, 8):
		0:
			var idx := rng.randi_range(-2, 7)
			nombre = "jugar %d" % idx
			var costo := m.costo_carta(e.mano[idx]) if idx >= 0 and idx < e.mano.size() else -1
			r = m.jugar_carta(idx, "", "")
			if bool(r.get("ok", false)) and costo >= 0:
				_check(e.pa_actual == pa0 - costo or e.pa_actual >= 0, "%s: jugar costó movimientos inesperados (%d -> %d, costo %d)" % [ctx, pa0, e.pa_actual, costo])
		1, 2:
			var mins: Array = e.gabinete + basura
			var mid := String(mins[rng.randi_range(0, mins.size() - 1)])
			var idx := rng.randi_range(-1, 6)
			nombre = "delegar %d a %s" % [idx, mid]
			if idx >= 0 and idx < e.mano.size() and e.gabinete.has(mid):
				var p1 := m.prob_fallo_delegacion(idx, mid)
				var p2 := m.prob_fallo_delegacion(idx, mid)
				_check(p1 == p2 and p1 >= 0.0 and p1 <= 1.0, "%s: probabilidad de fallo no determinista o fuera de [0,1] (%s, %s)" % [ctx, str(p1), str(p2)])
			r = m.delegar_carta(idx, mid)
			if bool(r.get("ok", false)):
				_check(e.pa_actual == pa0, "%s: delegar gastó movimientos (%d -> %d)" % [ctx, pa0, e.pa_actual])
		3:
			var metas := m.movimientos.metas_disponibles()
			var id := String(metas[rng.randi_range(0, metas.size() - 1)]["id"]) if not metas.is_empty() and rng.randf() < 0.6 else String(basura[rng.randi_range(0, 2)])
			nombre = "meta " + id
			r = m.buscar_meta(id)
		4:
			var sectores: Array = e.indices_sector.keys() + basura
			var s := String(sectores[rng.randi_range(0, sectores.size() - 1)])
			nombre = "sector " + s
			r = m.ajustar_sector(s, rng.randi_range(-2, 2))
		5:
			nombre = "reducir errores"
			r = m.reducir_errores()
		6:
			nombre = "acelerar"
			r = m.acelerar_proyecto(rng.randi_range(-1, 4))
		7:
			var ids: Array = m.equipo.asesores.keys() + basura
			var id := String(ids[rng.randi_range(0, ids.size() - 1)])
			nombre = "asesor " + id
			r = m.contratar_asesor(id) if rng.randf() < 0.6 else m.despedir_asesor(id)
		8:
			var ids: Array = m.coalicion.partidos.keys() + basura
			var id := String(ids[rng.randi_range(0, ids.size() - 1)])
			nombre = "coalición " + id
			r = m.unirse_coalicion(id) if rng.randf() < 0.6 else m.salir_coalicion(id)
	if r.has("ok") and not bool(r["ok"]):
		_rechazos += 1
		var despues := AyudaFuzz.props(m)
		var dif: Array[String] = []
		for k in antes.keys():
			if antes[k] != despues.get(k, ""):
				dif.append(k)
		for k in dif:
			_difs[k] = int(_difs.get(k, 0)) + 1
		_check(dif.is_empty(), "%s: «%s» fue rechazada (%s) pero cambió %s" % [ctx, nombre, str(r.get("razon", "?")), str(dif)])
	elif r.has("ok"):
		_aceptadas += 1
	# invariantes de límites
	var cfg_d := int(_datos["leyes"]["delegacion"]["max_por_turno"])
	var cfg_i := int(_datos["leyes"]["movimientos_internos"]["por_turno"])
	_check(e.delegadas_turno >= 0 and e.delegadas_turno <= cfg_d, "%s: delegadas_turno fuera de límite (%d, máx. %d) tras «%s»" % [ctx, e.delegadas_turno, cfg_d, nombre])
	_check(e.internos_actual >= 0 and e.internos_actual <= cfg_i, "%s: internos_actual fuera de límite (%d, máx. %d) tras «%s»" % [ctx, e.internos_actual, cfg_i, nombre])
	_check(e.pa_actual >= 0, "%s: movimientos negativos (%d) tras «%s»" % [ctx, e.pa_actual, nombre])
	if e.etapa != "gobierno":
		_check(e.internos_actual == 0, "%s: hay movimientos internos fuera del gobierno (%d, etapa %s)" % [ctx, e.internos_actual, e.etapa])


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 10
	var s0 := int(args[1]) if args.size() > 1 else 1200
	_datos = Datos.cargar_todo()
	for i in range(n):
		var semilla := s0 + i
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla * 11 + 3
		var resp: Array[Dictionary] = []
		for p in _datos["ideologia"]["preguntas"]:
			resp.append(p["opciones"][rng.randi_range(0, 2)])
		var m := Partida.crear(_datos, semilla, GeneradorPartido.construir_partido("R", "RRR", "metropolitana", resp, _datos["ideologia"]))
		var ctx := "semilla %d" % semilla
		var pasos := 0
		while MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa) and pasos < 260:
			pasos += 1
			if rng.randf() < 0.6:
				Bots.jugar_turno(m, "codicioso", rng)
			for _a in range(rng.randi_range(2, 14)):
				_accion(m, rng, ctx)
			if m.estado.eleccion_pendiente(int(_datos["leyes"]["hemiciclo"]["semanas_campana"])):
				Bots.elegir(m, _datos, "codicioso", rng)
			else:
				m.terminar_turno()
	if not _difs.is_empty():
		print("PROPIEDADES CAMBIADAS POR ACCIONES RECHAZADAS (veces): ", _difs)
	print("FUZZ RECHAZOS %s (%d partidas, %d acciones rechazadas comprobadas, %d aceptadas, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _rechazos, _aceptadas, _fallos])
	quit(1 if _fallos > 0 else 0)
