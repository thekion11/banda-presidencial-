extends SceneTree
## Fuzz de las decisiones de eventos (MotorEventos.decidir) a lo largo de carreras completas: decisiones válidas, índices fuera de rango, ids inexistentes, eventos
## sin opciones o que no ocurrieron, y decisiones repetidas. Propiedades:
##  (1) una decisión rechazada (ok = false) NO cambia el estado (ni propiedades, ni generador aleatorio, ni registro, ni entradas);
##  (2) una decisión aceptada queda en estado.decisiones y una segunda decisión sobre el mismo evento se rechaza con «ya_decidido»;
##  (3) toda decisión pendiente (evento con opciones que ocurrió) se puede resolver con alguna opción válida;
##  (4) el replay del guardado (con las decisiones intercaladas con el juego) da la misma huella que la partida en vivo.
## Uso: godot --headless --path . -s tests/fuzz_decisiones.gd -- [partidas] [semilla_inicial]

var _fallos: int = 0
var _datos: Dictionary
var _aceptadas: int = 0
var _rechazadas: int = 0
var _repetidas: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ DECISIONES: ", msg)


func _decidir(m: MotorTurno, id: String, idx: int, ctx: String) -> void:
	var antes := AyudaFuzz.props(m)
	var r: Dictionary = m.eventos.decidir(id, idx)
	if bool(r.get("ok", false)):
		_aceptadas += 1
		_check(m.estado.decisiones.has(id), "%s: la decisión aceptada de %s no quedó en estado.decisiones" % [ctx, id])
		var r2: Dictionary = m.eventos.decidir(id, idx)
		_repetidas += 1
		_check(not bool(r2.get("ok", false)) and String(r2.get("razon", "")) == "ya_decidido", "%s: decidir %s dos veces debe dar «ya_decidido» (%s)" % [ctx, id, str(r2)])
	else:
		_rechazadas += 1
		var despues := AyudaFuzz.props(m)
		var dif: Array[String] = []
		for k in antes.keys():
			if antes[k] != despues.get(k, ""):
				dif.append(k)
		_check(dif.is_empty(), "%s: decidir(%s, %d) fue rechazada (%s) pero cambió %s" % [ctx, id, idx, str(r.get("razon", "?")), str(dif)])


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 3
	var s0 := int(args[1]) if args.size() > 1 else 3100
	_datos = Datos.cargar_todo()
	var huella := Datos.huella(_datos)
	var con_opciones: Array = _datos["eventos"].filter(func(ev: Dictionary) -> bool: return ev.has("opciones")).map(func(ev: Dictionary) -> String: return String(ev["id"]))
	var sin_opciones: Array = _datos["eventos"].filter(func(ev: Dictionary) -> bool: return not ev.has("opciones")).map(func(ev: Dictionary) -> String: return String(ev["id"]))
	for i in range(n):
		var semilla := s0 + i
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla * 31 + 9
		var resp: Array[Dictionary] = []
		for p in _datos["ideologia"]["preguntas"]:
			resp.append(p["opciones"][rng.randi_range(0, 2)])
		var partido := GeneradorPartido.construir_partido("D", "DDD", "metropolitana", resp, _datos["ideologia"])
		partido["indicadores_iniciales"]["aprobacion"] = 90.0
		var m := Partida.crear(_datos, semilla, partido)
		var ctx := "semilla %d" % semilla
		var pasos := 0
		var sem_camp := int(_datos["leyes"]["hemiciclo"]["semanas_campana"])
		while MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa) and pasos < 400:
			pasos += 1
			# decisiones pendientes: eventos con opciones que ocurrieron y aún no se decidieron
			for ev in m.estado.eventos_ocurridos.keys():
				if con_opciones.has(String(ev)) and not m.estado.decisiones.has(String(ev)) and rng.randf() < 0.5:
					var evt := {}
					for x in _datos["eventos"]:
						if String(x["id"]) == String(ev):
							evt = x
					var idx_ok := rng.randi_range(0, (evt["opciones"] as Array).size() - 1)
					_check((evt["opciones"] as Array).size() > 0, "%s: el evento %s tiene opciones vacías" % [ctx, ev])
					_decidir(m, String(ev), idx_ok, ctx)
			# entradas inválidas
			for _k in range(rng.randi_range(0, 3)):
				var ids: Array = con_opciones + sin_opciones + ["no_existe", ""]
				_decidir(m, String(ids[rng.randi_range(0, ids.size() - 1)]), rng.randi_range(-2, 6), ctx)
			if rng.randf() < 0.6:
				Bots.jugar_turno(m, "codicioso", rng)
			if m.estado.eleccion_pendiente(sem_camp):
				Bots.elegir(m, _datos, "codicioso", rng)
			else:
				m.terminar_turno()
		var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(huella)))
		var decisiones := (g["entradas"] as Array).filter(func(e: Dictionary) -> bool: return e["tipo"] == "decision").size()
		_check(Partida.reproducir(_datos, g).estado.calcular_huella() == m.estado.calcular_huella(), "%s: el replay con %d decisiones intercaladas no es idéntico (etapa %s)" % [ctx, decisiones, m.estado.etapa])
	print("FUZZ DECISIONES %s (%d partidas, %d decisiones aceptadas, %d rechazadas, %d repeticiones rechazadas, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _aceptadas, _rechazadas, _repetidas, _fallos])
	quit(1 if _fallos > 0 else 0)
