extends SceneTree
## Lo tapado no se dibuja: con un panel abierto (Comité, Congreso, Nación) la vista del día se oculta, salvo con Gabinete,
## que deja ver la fila de botones. Las vistas a pantalla completa (mapa urbano, hito, cartera) ocultan la pantalla del día
## mientras están abiertas y la devuelven al cerrarse. Ahorra unas 970 llamadas de dibujo por cuadro (tests/medir_cuadros.gd).

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


func _correr() -> void:
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_tapa.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var resp: Array[Dictionary] = []
	for p in main.datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(main.datos, 11, GeneradorPartido.construir_partido("T", "T", "metropolitana", resp, main.datos["ideologia"]))
	main.mostrar_dia()
	await _cuadros(2)
	var dia: PantallaDia = main._pantalla
	var vista: Control = dia._mapa.get_parent()
	_check(vista.visible, "al abrir el día se ve el mapa")
	for panel in ["comite", "congreso", "nacion"]:
		dia._abrir_panel(panel)
		await _cuadros(1)
		_check(not vista.visible, "con el panel %s la vista de abajo no se dibuja" % panel)
	dia._abrir_panel("gabinete")
	await _cuadros(1)
	_check(vista.visible and dia._btn_jugar.is_visible_in_tree(), "con Gabinete se ve la fila de botones")
	dia._abrir_panel("mapa")
	await _cuadros(1)
	_check(vista.visible and not dia._zona_panel.visible, "al volver al mapa se ve de nuevo")
	dia._abrir_urbano()
	await _cuadros(2)
	_check(not dia._raiz.visible, "el mapa urbano oculta la pantalla del día")
	dia._abrir_hito({"nombre": "Obra", "dias_totales": 400, "dias_avanzados": 200, "retrasos": 0, "carta_id": "", "region": "metropolitana", "efectos_final": []})
	await _cuadros(2)
	var vistas: Array = dia._capa.get_children().filter(func(h: Node) -> bool: return h is ColorRect)
	_check(vistas.size() == 2, "urbano y hito abiertos a la vez")
	(vistas[1] as Node).queue_free()  # cierra el hito: el urbano sigue tapando
	await _cuadros(2)
	_check(not dia._raiz.visible, "con el urbano aún abierto la pantalla del día sigue oculta")
	(vistas[0] as Node).queue_free()
	await _cuadros(2)
	_check(dia._raiz.visible, "al cerrar el urbano vuelve la pantalla del día")
	dia._abrir_cartera()
	await _cuadros(2)
	_check(not dia._raiz.visible, "la cartera oculta la pantalla del día")
	for h in dia._capa.get_children():
		if h is PantallaCartera:
			h.queue_free()
	await _cuadros(2)
	_check(dia._raiz.visible, "al cerrar la cartera vuelve la pantalla del día")
	var menu := PantallaCartera.crear(main.datos)  # fuera del día (desde el menú) no oculta nada
	root.add_child(menu)
	await _cuadros(1)
	_check(main.visible, "fuera del día la cartera no oculta nada")
	menu.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	if _fallos == 0:
		print("TAPA OK")
	quit(1 if _fallos > 0 else 0)
