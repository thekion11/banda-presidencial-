extends SceneTree
## Estado tardío (semanas 150–208 de gobierno): muchas obras, leyes, promesas y coalición, con la mano llena.
## Un bot juega con semilla fija hasta la semana ≥ 150 y la interfaz se abre con ese estado en el teléfono más bajo
## (390×693) y con letra ×1,5: ningún texto ni botón se sale de la pantalla (salvo en zonas desplazables), los botones
## miden ≥ 44 px y abrir cada panel no tarda de más.

const SEMANA_MIN := 150
const MS_MAX := 1500.0  # abrir un panel con todo el historial (escritorio, sin GPU)

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


static func _en_scroll(n: Node) -> bool:
	var p := n.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


func _auditar(raiz: Node, donde: String, alto: int) -> void:
	for n in raiz.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or _en_scroll(c):
			continue
		var r := c.get_global_rect()
		if (c is Label or c is Button) and String(c.get("text")).strip_edges() != "":
			_check(r.position.x >= -0.5 and r.end.x <= Tema.ANCHO + 0.5 and r.end.y <= alto + 0.5, "%s: «%s» se sale de la pantalla (%s)" % [donde, String(c.get("text")).left(30), r])
		if c is BaseButton:
			_check(r.size.x >= Tema.TACTIL - 0.5 and r.size.y >= Tema.TACTIL - 0.5, "%s: botón «%s» mide %s" % [donde, String(c.get("text")).left(30), r.size])


func _motor_tardio(datos: Dictionary) -> MotorTurno:
	for semilla in [11, 23, 37, 51, 77]:
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		var resp: Array[Dictionary] = []
		for p in datos["ideologia"]["preguntas"]:
			resp.append(p["opciones"][1])
		var motor := Partida.crear(datos, semilla, GeneradorPartido.construir_partido("Partido Tardío", "PTA", "metropolitana", resp, datos["ideologia"]))
		for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
			Bots.jugar_turno(motor, "experto", rng)
			motor.terminar_turno()
		if not Bots.elegir(motor, datos, "experto", rng):
			continue
		while motor.estado.etapa == "gobierno" and motor.estado.turno_actual < SEMANA_MIN + 20:
			Bots.jugar_turno(motor, "experto", rng)
			motor.terminar_turno()
		if motor.estado.etapa == "gobierno" and motor.estado.turno_actual >= SEMANA_MIN:
			return motor
	return null


func _correr() -> void:
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_tardio.json"
	Tutorial.marcar_visto()
	var datos := Datos.cargar_todo()
	var motor := _motor_tardio(datos)
	_check(motor != null, "algún bot llega a la semana %d de gobierno" % SEMANA_MIN)
	if motor == null:
		quit(1)
		return
	var est := motor.estado
	print("estado tardío: semana %d · obras %d · leyes en trámite %d · promesas %d · aliados %d · mano %d" % [est.turno_actual, est.obras_en_curso.size(), est.proyectos_en_tramite.size() if "proyectos_en_tramite" in est else -1, est.promesas_campana.size(), est.coalicion.size(), est.mano.size()])
	for caso in [[693, 0.0], [693, 1.5], [844, 1.5]]:
		var alto: int = caso[0]
		Ajustes.escala_prueba = caso[1]
		root.content_scale_size = Vector2i(390, alto)
		var main: Node = load("res://game/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		main.motor = motor
		main.mostrar_dia()
		await _cuadros(3)
		var dia: PantallaDia = main._pantalla
		var tag := "[%d, letra ×%s]" % [alto, str(caso[1]) if caso[1] > 0.0 else "1"]
		_auditar(main, "día " + tag, alto)
		var pasos: Array = [["comite", ""], ["congreso", ""], ["gabinete", "gabinete"], ["gabinete", "equipo"], ["gabinete", "coalicion"], ["gabinete", "internos"], ["nacion", ""]]
		for p in pasos:
			if String(p[1]) != "":
				PanelGestion.pestana = String(p[1])
			var t0 := Time.get_ticks_usec()
			dia._abrir_panel(String(p[0]))
			var ms := (Time.get_ticks_usec() - t0) / 1000.0
			await _cuadros(3)
			_check(ms < MS_MAX, "%s abrir %s %s tarda %.0f ms" % [tag, p[0], p[1], ms])
			_auditar(main, "%s %s %s" % [p[0], p[1], tag], alto)
		PanelGestion.pestana = "gabinete"
		dia._abrir_panel("mapa")
		dia._abrir_urbano()
		await _cuadros(3)
		_auditar(main, "urbano " + tag, alto)
		main.queue_free()
		await _cuadros(2)
	# pantalla de fin con el mandato completo: puntaje, hitos, leyes («y N más») y epílogo, en el teléfono bajo y letra ×1,5
	motor.mandato.finalizar("fin_mandato")
	for caso in [[693, 0.0], [693, 1.5]]:
		Ajustes.escala_prueba = caso[1]
		root.content_scale_size = Vector2i(390, int(caso[0]))
		var mf: Node = load("res://game/main.tscn").instantiate()
		root.add_child(mf)
		await process_frame
		mf.motor = motor
		mf.mostrar_fin()
		await _cuadros(3)
		_auditar(mf, "fin [%d, letra ×%s]" % [caso[0], str(caso[1])], int(caso[0]))
		mf.queue_free()
		await _cuadros(2)
	Ajustes.escala_prueba = 0.0
	root.content_scale_size = Vector2i(390, 844)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://guardado.json"))
	if _fallos == 0:
		print("ESTADO TARDÍO OK")
	quit(1 if _fallos > 0 else 0)
