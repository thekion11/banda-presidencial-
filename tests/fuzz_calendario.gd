extends SceneTree
## Fuzz del calendario real y de la segunda vuelta. Recorre carreras completas (campaña, 1ª y 2ª vuelta, gobierno, oposición, derrotas, reelección) y comprueba:
##  (1) ciclo 1, campaña: el turno t cae el 21-sep-2025 + 7·(t-1); la 1ª vuelta se vota el 16-nov-2025 y la 2ª el 14-dic-2025;
##  (2) gobierno: el turno 1 cae el 11-mar-2026 y cada turno avanza 7 días;
##  (3) desde el ciclo 2 hay un solo reloj: la fecha nunca retrocede y avanza exactamente 7 días por turno, también entre periodos; la única excepción es el
##      paso de campaña a gobierno, que empieza el mismo día de la elección (+0);
##  (4) el mes que usa el director de eventos (MotorEventos.mes_actual) es el mismo que muestra la interfaz (Barras.fecha_iso).
## Uso: godot --headless --path . -s tests/fuzz_calendario.gd -- [partidas] [semilla_inicial]

var _fallos: int = 0
var _datos: Dictionary


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		if _fallos <= 20:
			print("FALLO FUZZ CALENDARIO: ", msg)


func _dia(iso: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(iso + "T00:00:00") / 86400)


func _iso(m: MotorTurno) -> String:
	var e := m.estado
	return Barras.fecha_iso(_datos["leyes"], e.etapa, e.turno_actual, e.dia_actual, e.ciclo, e.dias_carrera)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 8
	var s0 := int(args[1]) if args.size() > 1 else 1500
	_datos = Datos.cargar_todo()
	var cal: Dictionary = _datos["leyes"]["calendario"]
	var sem_camp := int(_datos["leyes"]["hemiciclo"]["semanas_campana"])
	var retrocesos := 0
	var segundas_vueltas := 0
	for i in range(n):
		var semilla := s0 + i
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla * 19 + 7
		var resp: Array[Dictionary] = []
		for p in _datos["ideologia"]["preguntas"]:
			resp.append(p["opciones"][rng.randi_range(0, 2)])
		var partido := GeneradorPartido.construir_partido("C", "CCC", "metropolitana", resp, _datos["ideologia"])
		if rng.randf() < 0.5:
			partido["indicadores_iniciales"]["aprobacion"] = rng.randf_range(20.0, 95.0)
		var m := Partida.crear(_datos, semilla, partido)
		var e := m.estado
		var ctx := "semilla %d" % semilla
		var ultimo_dia := -1
		var ultimo_ciclo := 1
		var ultimo_etapa := ""
		var pasos := 0
		while pasos < 900 and e.ciclo < 4:
			pasos += 1
			var iso := _iso(m)
			var d := _dia(iso)
			# (4) el director de eventos y la interfaz usan el mismo mes
			if MotorTurno.ETAPAS_JUEGO.has(e.etapa):
				var mes_ui := int(iso.substr(5, 2))
				_check(m.eventos.director.mes_actual() == mes_ui, "%s: mes del director (%d) distinto del de la interfaz (%d) en %s (ciclo %d, %s, turno %d)" % [ctx, m.eventos.director.mes_actual(), mes_ui, iso, e.ciclo, e.etapa, e.turno_actual])
			if e.ciclo == 1 and e.etapa == "campana":
				_check(d == _dia(String(cal["fecha_inicio_campana"])) + 7 * (e.turno_actual - 1), "%s: campaña ciclo 1 turno %d cae el %s" % [ctx, e.turno_actual, iso])
				if e.eleccion_pendiente(sem_camp):
					var esperada := String(cal["fecha_primera_vuelta"]) if e.ronda_electoral == 1 else String(cal["fecha_segunda_vuelta"])
					_check(iso == esperada, "%s: la %s vuelta se vota el %s, esperado %s" % [ctx, "1ª" if e.ronda_electoral == 1 else "2ª", iso, esperada])
			if e.ciclo == 1 and e.etapa == "gobierno":
				_check(d == _dia(String(cal["fecha_inicio_mandato"])) + 7 * (e.turno_actual - 1), "%s: gobierno turno %d cae el %s" % [ctx, e.turno_actual, iso])
			if e.ciclo >= 2 and ultimo_ciclo >= 2 and ultimo_dia >= 0 and MotorTurno.ETAPAS_JUEGO.has(e.etapa) and MotorTurno.ETAPAS_JUEGO.has(ultimo_etapa):
				var salto := 0 if (e.etapa == "gobierno" and e.turno_actual == 1 and ultimo_etapa == "campana") else 7
				if d != ultimo_dia + salto:
					retrocesos += 1
					_check(false, "%s: ciclo %d, de %s a %s (%+d días en vez de %+d) al pasar a %s turno %d" % [ctx, e.ciclo, str(ultimo_dia), iso, d - ultimo_dia, salto, e.etapa, e.turno_actual])
			if MotorTurno.ETAPAS_JUEGO.has(e.etapa):
				ultimo_dia = d
				ultimo_ciclo = e.ciclo
				ultimo_etapa = e.etapa
			# avanzar un paso, igual que fuzz_carrera
			match e.etapa:
				"fin_mandato", "crisis", "derrota_electoral":
					if bool(m.continuar_carrera().get("ok", false)):
						m.iniciar_turno()
				_:
					Bots.jugar_turno(m, "codicioso" if rng.randf() < 0.8 else "azar", rng)
					if e.eleccion_pendiente(sem_camp):
						var antes := e.ronda_electoral
						Bots.elegir(m, _datos, "codicioso", rng)
						if antes == 1 and e.ronda_electoral == 2:
							segundas_vueltas += 1
					else:
						m.terminar_turno()
	print("FUZZ CALENDARIO %s (%d partidas, %d segundas vueltas, %d saltos de reloj, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, segundas_vueltas, retrocesos, _fallos])
	quit(1 if _fallos > 0 else 0)
