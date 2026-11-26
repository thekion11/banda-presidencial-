extends SceneTree
## El corte de legado (semana 104 y 208): al cerrar el turno 104 y el 208, cada promesa de campaña pendiente resta penal_capital de capital y penal_aprobacion de aprobación,
## una sola vez por corte. La interfaz anuncia estas cifras («Corte de legado en N semanas…»): esta prueba fija que el motor las aplica exactamente así.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Legado", "LEG", "metropolitana", resp, datos["ideologia"])
	var lg: Dictionary = datos["leyes"]["legado"]
	var m: MotorTurno = null
	for semilla in range(1500, 1560):
		m = Partida.crear(datos, semilla, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		for _s in range(8):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		if Bots.elegir(m, datos, "codicioso", rng):
			break
	var e := m.estado
	_check(e.etapa == "gobierno", "se llegó al gobierno")
	e.promesas_campana.clear()
	for i in range(4):
		e.promesas_campana.append({"carta_id": "p%d" % i, "titulo": "Promesa %d" % i, "cumplida": i == 0})
	var pend := e.promesas_pendientes().size()
	_check(pend == 3, "3 promesas pendientes (%d)" % pend)
	for t in lg["turnos_evaluacion"]:
		e.turno_actual = int(t)
		e.indicadores["capital"] = 80.0
		for id in e.aprobacion_regional.keys():
			e.aprobacion_regional[id] = 60.0
		m.regiones.recalcular(e)
		var cap0 := e.ind("capital")
		var apr0 := e.ind("aprobacion")
		m.mandato.evaluar_legado()
		_check(absf((cap0 - e.ind("capital")) - float(lg["penal_capital"]) * pend) < 0.0001, "turno %d: el capital baja %.1f por %d pendientes (bajó %.2f)" % [int(t), float(lg["penal_capital"]) * pend, pend, cap0 - e.ind("capital")])
		_check(absf((apr0 - e.ind("aprobacion")) - float(lg["penal_aprobacion"]) * pend) < 0.01, "turno %d: la aprobación baja %.1f (bajó %.2f)" % [int(t), float(lg["penal_aprobacion"]) * pend, apr0 - e.ind("aprobacion")])
		var cap1 := e.ind("capital")
		m.mandato.evaluar_legado()
		_check(absf(e.ind("capital") - cap1) < 0.0001, "turno %d: el corte se aplica una sola vez" % int(t))
	# un turno que no es de corte no cobra nada
	e.turno_actual = int(lg["turnos_evaluacion"][0]) + 1
	var cap2 := e.ind("capital")
	m.mandato.evaluar_legado()
	_check(absf(e.ind("capital") - cap2) < 0.0001, "fuera de los turnos de corte no se cobra nada")
	# sin promesas pendientes, el corte no cuesta
	for p in e.promesas_campana:
		p["cumplida"] = true
	e.legado_evaluado.clear()
	e.turno_actual = int(lg["turnos_evaluacion"][0])
	var cap3 := e.ind("capital")
	m.mandato.evaluar_legado()
	_check(absf(e.ind("capital") - cap3) < 0.0001, "con todas las promesas cumplidas el corte no cuesta")
	print("test_legado_corte: ", "OK" if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
