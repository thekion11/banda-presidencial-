extends SceneTree
## Cartera real del Plan Maestro de SECTRA: etapas, PA, límite simultáneo, obra con inversión real y replay exacto.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO SECTRA: ", msg)


func _init() -> void:
	var datos := Datos.cargar_todo()
	_check(MotorSectra.etapa_de("Perfil") == 0 and MotorSectra.etapa_de("Diseño") == 2 and MotorSectra.etapa_de("Ejecución en desarrollo") == -1, "normalización de estados")
	var partido := GeneradorPartido.construir_partido("P", "P", "arica", _respuestas(datos), datos["ideologia"])
	var motor := Partida.crear(datos, 11, partido)
	var lista: Array = motor.sectra.proyectos.get("arica", [])
	_check(lista.size() > 0, "Arica tiene proyectos gestionables")
	_check(not motor.sectra.proyectos.has("metropolitana"), "RM sin datos publicados: no se inventan proyectos")
	var pid := String(lista[0]["id"])
	_check(not bool(motor.impulsar_proyecto(pid)["ok"]), "en campaña no se puede impulsar")
	motor = _hasta_gobierno(datos, partido)
	_check(motor.estado.etapa == "gobierno", "se alcanzó el gobierno")
	var r := motor.impulsar_proyecto(pid)
	_check(bool(r["ok"]), "impulsar en gobierno")
	_check(not bool(motor.impulsar_proyecto(pid)["ok"]), "no se puede impulsar dos veces el mismo trámite")
	var otros := 1
	while otros < lista.size() and motor.sectra.en_curso() < 3:
		motor.impulsar_proyecto(String(lista[otros]["id"]))
		otros += 1
	_check(motor.sectra.en_curso() == 3, "máximo simultáneo = 3")
	_check(not bool(motor.impulsar_proyecto(String(lista[otros]["id"]))["ok"]), "el cuarto trámite simultáneo se rechaza")
	var obras0 := motor.estado.obras_en_curso.size()
	for _i in range(40):
		motor.terminar_turno()
		if motor.estado.etapa != "gobierno":
			break
		motor.impulsar_proyecto(pid)
		if int(motor.estado.sectra[pid]["etapa"]) >= 3:
			break
	_check(int(motor.estado.sectra[pid]["etapa"]) >= 3, "el proyecto llega a ejecución")
	_check(motor.estado.obras_en_curso.size() > obras0 or motor.estado.obras_terminadas.size() > 0, "ejecución crea obra")
	var panel := PanelSectra.crear(motor, "arica", func(_p: String) -> void: pass)
	root.add_child(panel)
	_check(panel.find_children("*", "Button", true, false).size() >= 5, "el panel lista proyectos de la región")
	panel.queue_free()
	var guard := {"semilla": motor.estado.semilla, "partido": motor.estado.partido, "entradas": motor.estado.entradas.duplicate(true)}
	var h1 := motor.estado.calcular_huella()
	var rep := Partida.reproducir(datos, guard)
	_check(rep.estado.calcular_huella() == h1, "replay idéntico con proyectos SECTRA")
	print("SECTRA OK" if _fallos == 0 else "SECTRA FALLÓ (%d)" % _fallos)
	quit(1 if _fallos > 0 else 0)


func _respuestas(datos: Dictionary) -> Array[Dictionary]:
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	return resp


func _hasta_gobierno(datos: Dictionary, partido: Dictionary) -> MotorTurno:
	for semilla in range(11, 80):
		var m := Partida.crear(datos, semilla, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		for _i in range(8):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		if bool(m.resolver_eleccion_presidencial()["electo"]):
			m.iniciar_turno()
			return m
	return null
