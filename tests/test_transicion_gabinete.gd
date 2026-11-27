extends SceneTree
## Gabinete después de la elección: tras ganar, `gabinete.pendiente_confirmar()` es verdadero hasta nombrar el gabinete (también el preseleccionado); sobrevive a recargar por replay.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		print("FALLO TRANSICION: ", msg)


func _ganar(datos: Dictionary, semilla: int) -> MotorTurno:
	## Campaña con el bot «completo» y votación (con segunda vuelta si hace falta); devuelve el motor en el turno 1 de gobierno, o null si pierde.
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Prueba", "PRU", "metropolitana", resp, datos["ideologia"])
	var m := Partida.crear(datos, semilla, partido)
	for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "completo", rng)
		m.terminar_turno()
	var r := m.resolver_eleccion_presidencial()
	if bool(r["balotaje"]):
		m.iniciar_turno()
		for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_balotaje"])):
			Bots.jugar_turno(m, "completo", rng)
			m.terminar_turno()
		r = m.resolver_eleccion_presidencial()
	if not bool(r["electo"]):
		return null
	m.iniciar_turno()
	return m


func _init() -> void:
	var datos := Datos.cargar_todo()
	var m: MotorTurno = null
	var semilla := 0
	for s in range(2026, 2046):
		m = _ganar(datos, s)
		if m != null:
			semilla = s
			break
	_check(m != null, "alguna semilla gana la elección con el bot completo")
	if m == null:
		quit(1)
		return
	_check(m.estado.etapa == "gobierno" and m.estado.turno_actual == 1, "ganó: turno 1 de gobierno")
	_check(m.gabinete.pendiente_confirmar(), "recién ganada, el gabinete está por confirmar")
	# recargar sin confirmar: sigue pendiente (la app se cerró en la pantalla del gabinete)
	var g0: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado("")))
	var m0 := Partida.reproducir(datos, g0)
	_check(m0 != null and m0.gabinete.pendiente_confirmar(), "replay sin confirmar: sigue pendiente")
	# confirmar el preseleccionado cuenta
	var res := m.elegir_gabinete(m.estado.gabinete.duplicate())
	_check(bool(res["ok"]), "confirmar el gabinete preseleccionado")
	_check(not m.gabinete.pendiente_confirmar(), "tras nombrar ya no está pendiente")
	var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado("")))
	var m2 := Partida.reproducir(datos, g)
	_check(m2 != null and not m2.gabinete.pendiente_confirmar(), "replay confirmado: no pendiente")
	# en la campaña y a partir del turno 2 no hay transición
	m.terminar_turno()
	_check(not m.gabinete.pendiente_confirmar(), "en el turno 2 no hay transición")
	var c := Partida.crear(datos, semilla, GeneradorPartido.construir_partido("P", "PP", "metropolitana", [], datos["ideologia"]))
	_check(not c.gabinete.pendiente_confirmar(), "en campaña no hay transición")
	print("test_transicion_gabinete: ", "OK" if _fallos == 0 else "FALLOS %d" % _fallos)
	quit(1 if _fallos > 0 else 0)
