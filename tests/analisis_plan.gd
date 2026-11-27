extends SceneTree
## Análisis de las 16 cartas `plan_*` del Plan Estratégico (docs/PLAN_ESTRATEGICO_CARTAS.md): para cada carta, en N partidas de gobierno (bot «codicioso»),
## se juega en la semana 1 y se miden: % de partidas en que se aprueba su votación en 26 semanas (alcanzable), % en que sale mal el riesgo, y el efecto
## neto sobre aprobación y fiscal a 52 semanas frente a la misma partida sin jugarla (dominancia: ¿conviene SIEMPRE jugarla?).
## Uso: godot --headless --path . -s tests/analisis_plan.gd -- [partidas=16] [semana_horizonte=52]

var _datos: Dictionary


func _partido() -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in _datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	return GeneradorPartido.construir_partido("Plan", "PLN", "metropolitana", resp, _datos["ideologia"])


func _gobierno(semilla: int) -> MotorTurno:
	var m := Partida.crear(_datos, semilla, _partido())
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	for _s in range(int(_datos["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	if Bots.elegir(m, _datos, "codicioso", rng):
		return m
	return null


func _aprobada(m: MotorTurno, id: String) -> bool:
	for a in m.estado.registro_acciones:
		if a["tipo"] == "votacion" and String(a["detalle"].get("carta", "")) == id and bool(a["detalle"].get("aprobada", false)):
			return true
	return false


func _correr_semanas(m: MotorTurno, rng: RandomNumberGenerator, n: int) -> void:
	for _s in range(n):
		if not MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa):
			return
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 16
	var hor := int(args[1]) if args.size() > 1 else 52
	_datos = Datos.cargar_todo()
	var cartas: Array = _datos["cartas"].filter(func(c: Dictionary) -> bool: return String(c["id"]).begins_with("plan_"))
	print("%-28s %-9s %5s %6s %6s %8s %8s %8s" % ["carta", "ley", "PA", "pasa%", "mal%", "d_aprob", "d_fiscal", "d_capit"])
	for carta in cartas:
		var pasa := 0
		var mal := 0
		var jugadas := 0
		var da := 0.0
		var df := 0.0
		var dc := 0.0
		var validas := 0
		for i in range(n):
			var sd := 5000 + i
			var con := _gobierno(sd)
			var sin := _gobierno(sd)
			if con == null or sin == null:
				continue
			validas += 1
			con.estado.mano.insert(0, carta.duplicate(true))
			con.estado.pa_actual = maxi(con.estado.pa_actual, 5)
			var r := con.jugar_carta(0)
			if bool(r.get("ok", false)):
				jugadas += 1
				if bool(r.get("salio_mal", false)):
					mal += 1
			var r1 := RandomNumberGenerator.new()
			r1.seed = sd + 77
			var r2 := RandomNumberGenerator.new()
			r2.seed = sd + 77
			_correr_semanas(con, r1, hor)
			_correr_semanas(sin, r2, hor)
			if _aprobada(con, String(carta["id"])) or (carta["requisitos"]["ley"] == null and bool(r.get("ok", false))):
				pasa += 1
			da += con.estado.ind("aprobacion") - sin.estado.ind("aprobacion")
			df += con.estado.ind("fiscal") - sin.estado.ind("fiscal")
			dc += con.estado.ind("capital") - sin.estado.ind("capital")
		var v := float(maxi(1, validas))
		print("%-28s %-9s %5d %5.0f%% %5.0f%% %+8.2f %+8.2f %+8.2f" % [carta["id"], String(carta["requisitos"]["ley"]).left(9), int(carta["costo_pa"]), 100.0 * pasa / v, 100.0 * mal / maxf(1.0, float(jugadas)), da / v, df / v, dc / v])
	quit(0)
