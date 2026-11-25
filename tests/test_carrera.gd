extends SceneTree
## Carrera política: derrota -> oposición -> campaña -> elección -> gobierno -> (reelección si hubo reforma) -> ..., con replay exacto.

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
	var partido := GeneradorPartido.construir_partido("Carrera", "CAR", "metropolitana", resp, datos["ideologia"])
	var m := Partida.crear(datos, 77, partido)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var sem := int(datos["leyes"]["hemiciclo"]["semanas_campana"])
	# 1) campaña sin promesas -> derrota
	for _i in range(sem):
		m.terminar_turno()
	_check(not bool(m.resolver_eleccion_presidencial()["electo"]) and m.estado.etapa == "derrota_electoral", "sin promesas se pierde la elección")
	_check(bool(m.continuar_carrera().get("ok", false)), "tras la derrota la carrera continúa")
	_check(m.estado.etapa == "oposicion" and m.estado.ciclo == 2, "pasa a la oposición (ciclo 2)")
	m.iniciar_turno()
	_check(m.estado.mano.size() == 5 and m.estado.mano.all(func(c: Dictionary) -> bool: return c["categoria"] == "oposicion"), "en oposición solo circulan cartas de oposición")
	# 2) oposición jugable
	var semanas_opo := int(datos["leyes"]["oposicion"]["semanas"])
	var aprob0 := m.estado.ind("aprobacion")
	for _t in range(semanas_opo):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	_check(m.estado.etapa == "campana" and m.estado.ciclo == 3 and m.estado.turno_actual == 1, "terminada la oposición empieza una nueva campaña")
	_check(m.estado.ind("aprobacion") != aprob0, "la oposición mueve tu aprobación")
	_check(m.estado.mano.all(func(c: Dictionary) -> bool: return c["categoria"] != "oposicion"), "en campaña no circulan cartas de oposición")
	# 3) campaña jugada -> elección -> (si gana) gobierno
	for _t in range(sem):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	var gano := Bots.elegir(m, datos, "codicioso", rng)
	_check(m.estado.etapa == ("gobierno" if gano else "derrota_electoral"), "la elección de la segunda campaña decide gobierno o derrota")
	if gano:
		# hitos con fecha real no se repiten en el 2.º periodo
		var reales := 0
		for a in m.estado.registro_acciones:
			if a["tipo"] == "evento" and String(a["detalle"]["id"]).begins_with("evt_real_") and int(a["turno"]) >= 1 and a["etapa"] == "gobierno" and int(m.estado.ciclo) > 1:
				reales += 1
		for _t in range(208):
			if m.estado.etapa != "gobierno":
				break
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		print("el segundo periodo de gobierno terminó en: ", m.estado.etapa)
		_replay(m, datos, "replay idéntico de la carrera hasta el fin del mandato")  # antes de forzar la reforma (que no es una entrada del jugador)
		if m.estado.etapa == "fin_mandato":
			m.estado.cartas_ejecutadas["reforma_reeleccion"] = true
			_check(String(m.continuar_carrera()["etapa"]) == "campana", "con la reforma aprobada se puede postular a la reelección")
			m.iniciar_turno()
		elif m.estado.etapa in ["crisis", "derrota_electoral"]:
			_check(String(m.continuar_carrera()["etapa"]) == "oposicion", "tras una caída se pasa a la oposición")
			m.iniciar_turno()
	_check(m.estado.carrera.size() >= 2, "la carrera registra los periodos cerrados")
	_replay(m, datos, "replay idéntico de la carrera completa") if not m.estado.cartas_ejecutadas.has("reforma_reeleccion") else null
	print("test_carrera: ", "OK" if _fallos == 0 else "FALLO", " (ciclos: %d)" % m.estado.ciclo)
	quit(1 if _fallos > 0 else 0)


func _replay(m: MotorTurno, datos: Dictionary, msg: String) -> void:
	var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(Datos.huella(datos))))
	var re := Partida.reproducir(datos, g)
	_check(re.estado.calcular_huella() == m.estado.calcular_huella(), msg)
