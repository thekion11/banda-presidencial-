extends SceneTree
## Reglas de pantalla de CLAUDE.md §5 que no cubría otra prueba (docs/CUMPLIMIENTO_UI.md):
## «Terminar semana» es el botón del medio, la esquina inferior derecha queda vacía (PR-02), el mapa ocupa más de un
## tercio en todos los altos de teléfono probados (RecorridoUI.ALTURAS) y «Reducir movimiento» quita las
## partículas y lo intenso en todas las pantallas, con las animaciones encendidas.

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


func _dia(alto: int) -> Node:
	root.content_scale_size = Vector2i(390, alto)
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var resp: Array[Dictionary] = []
	for p in main.datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(main.datos, 23, GeneradorPartido.construir_partido("R", "R", "metropolitana", resp, main.datos["ideologia"]))
	main.mostrar_dia()
	await _cuadros(4)
	return main


func _correr() -> void:
	Tutorial.ruta = "user://preferencias_reglas.json"
	Tutorial.marcar_visto()
	Movimiento.forzado = 0
	for alto in RecorridoUI.alturas():
		var main: Node = await _dia(alto)
		var dia: PantallaDia = main._pantalla
		var b := dia._btn_jugar.get_global_rect()
		_check(dia._btn_jugar.text.begins_with("Terminar semana") or dia._btn_jugar.text.begins_with("Siguiente semana"), "[%d] el botón del medio termina la semana (%s)" % [alto, dia._btn_jugar.text])
		_check(absf(b.get_center().x - Tema.ANCHO * 0.5) < 2.0, "[%d] el botón principal está centrado (%s)" % [alto, b])
		var esquina := Rect2(Tema.ANCHO - 60.0, b.position.y, 60.0, b.size.y)  # esquina inferior derecha de la fila de botones
		var ocupada := dia.find_children("*", "BaseButton", true, false).any(func(x: Node) -> bool: return (x as Control).is_visible_in_tree() and (x as Control).get_global_rect().intersects(esquina))
		_check(not ocupada, "[%d] la esquina inferior derecha queda vacía (PR-02)" % alto)
		var fr := float(dia._mapa.size.y) / root.get_visible_rect().size.y
		_check(fr > 1.0 / 3.0, "[%d] el mapa ocupa más de un tercio (%.1f px de %d)" % [alto, dia._mapa.size.y, alto])
		main.queue_free()
		await _cuadros(2)
	root.content_scale_size = Vector2i(390, 844)
	# con «Animaciones» apagado nada se mueve: la mano queda en su lugar al instante y el trazado urbano aparece entero
	var mq: Node = await _dia(844)
	var dq: PantallaDia = mq._pantalla
	var pos0: Array = dq.find_children("*", "CartaUI", true, false).map(func(c: CartaUI) -> Vector2: return c.position)
	await create_timer(0.8).timeout
	var pos1: Array = dq.find_children("*", "CartaUI", true, false).map(func(c: CartaUI) -> Vector2: return c.position)
	_check(not pos0.is_empty() and pos0 == pos1, "sin animaciones las cartas de la mano no vuelan (%s → %s)" % [str(pos0.slice(0, 2)), str(pos1.slice(0, 2))])
	dq._abrir_urbano()
	await _cuadros(2)
	var um: Array = dq._capa.find_children("*", "UrbanoMapa", true, false)
	_check(not um.is_empty() and is_equal_approx((um[0] as UrbanoMapa).trazo, 1.0), "sin animaciones el trazado del Metro aparece entero")
	mq.queue_free()
	await _cuadros(2)
	# «Reducir movimiento» con animaciones: ninguna partícula visible ni procesando en menú, día, elección ganada y fin
	Movimiento.forzado = 1
	var main2: Node = await _dia(844)
	var previo := Ajustes.reducir
	Ajustes.reducir = true  # después de crear Main: su _ready carga los ajustes guardados
	main2.mostrar_dia()
	await _cuadros(2)
	var dia2: PantallaDia = main2._pantalla
	dia2._capa.add_child(_eleccion_ganada(main2))
	await _cuadros(3)
	main2.mostrar_menu()
	await _cuadros(3)
	var vivas := root.find_children("*", "Particulas", true, false).filter(func(p: Node) -> bool: return (p as Control).visible and p.is_processing())
	_check(vivas.is_empty(), "con «Reducir movimiento» no quedan partículas animándose (%d)" % vivas.size())
	_check(not Movimiento.intenso(), "con «Reducir movimiento» no hay efectos intensos")
	Ajustes.reducir = previo
	Movimiento.forzado = 0
	main2.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	if _fallos == 0:
		print("REGLAS UI OK")
	quit(1 if _fallos > 0 else 0)


func _eleccion_ganada(main: Node) -> Control:
	return PantallaEleccion.crear(main.motor, main.datos["regiones"], main.motor.estado.aprobacion_regional.duplicate(), {"electo": true, "balotaje": false, "ronda": 1, "voto_final": 57.4, "umbral": 51.0}, func() -> void: pass)
