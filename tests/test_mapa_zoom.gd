extends SceneTree
## Zoom del mapa de Chile (pedido del usuario del 27-nov-2026): doble toque acerca y vuelve, «Ver todo» vuelve,
## pellizco y rueda acercan sobre el dedo, arrastrar desplaza sin salirse, tocar (o tocar un nombre) elige la región
## también acercado, la carta vuela al punto correcto, sin animación con el movimiento apagado y por el camino real
## de los toques (Input.parse_input_event).

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


static func _clic(pos: Vector2, p: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = p
	e.position = pos
	return e


func _tocar(m: MapaChile, pos: Vector2) -> void:
	m._gui_input(_clic(pos, true))
	m._gui_input(_clic(pos, false))
	await _cuadros(1)


func _toque_real(pos_global: Vector2, pulsado: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.pressed = pulsado
	e.position = root.get_final_transform() * pos_global
	Input.parse_input_event(e)


func _correr() -> void:
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_zoom.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _cuadros(2)
	var d: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(d, 23, GeneradorPartido.construir_partido("Z", "Z", "metropolitana", resp, d["ideologia"]))
	main.mostrar_dia()
	await _cuadros(3)
	var dia: PantallaDia = main._pantalla
	var m: MapaChile = dia._mapa
	var z: MapaZoom = m._zoom
	_check(not z.acercado(), "el mapa empieza con la vista completa")
	# doble toque: acerca sobre la región; otro doble toque o «Ver todo» vuelve
	var c := m.centro("biobio")
	await _tocar(m, c)
	await _tocar(m, c)
	_check(is_equal_approx(z.zoom, MapaZoom.DOBLE), "el doble toque acerca ×%.1f (%.2f)" % [MapaZoom.DOBLE, z.zoom])
	_check(m.a_pantalla(c).distance_to(c) < 1.0, "el doble toque acerca sobre el punto tocado")
	_check(m._ver_todo != null and m._ver_todo.visible and m._ver_todo.size.y >= Tema.TACTIL, "acercado aparece «Ver todo» (≥ 44 px)")
	_check(m.seleccion == "biobio", "tocar elige la región también al acercar (%s)" % m.seleccion)
	# acercado, tocar un punto elige la región que está bajo el dedo (la vista se invierte)
	var otra := m.a_pantalla(m.centro("araucania"))
	if Rect2(Vector2.ZERO, m.size).has_point(otra):
		await _tocar(m, otra)
		await _cuadros(8)  # que no cuente como doble toque con el anterior
		_check(m.seleccion == "araucania" or m.seleccion == "biobio", "acercado, el toque elige la región bajo el dedo (%s)" % m.seleccion)
	# los nombres de las regiones aparecen y tocarlos elige (área ≥ 44 px)
	m.queue_redraw()
	await _cuadros(2)
	_check(not m._rotulos.is_empty(), "acercado, las regiones llevan su nombre")
	if not m._rotulos.is_empty():
		var rt: Array = m._rotulos.back()
		_check((rt[1] as Rect2).size.y >= Tema.TACTIL and (rt[1] as Rect2).size.x >= Tema.TACTIL, "el nombre se toca con un área de al menos 44 px")
		await _cuadros(30)
		await _tocar(m, (rt[1] as Rect2).get_center())
		_check(m.seleccion == String(rt[0]), "tocar el nombre «%s» elige su región (%s)" % [rt[0], m.seleccion])
	# arrastrar desplaza sin salir del mapa
	var pan0 := z.pan
	m._gui_input(_clic(m.size * 0.5, true))
	for k in range(6):
		var mv := InputEventMouseMotion.new()
		mv.position = m.size * 0.5 + Vector2(40.0 * (k + 1), 400.0 * (k + 1))
		mv.relative = Vector2(40.0, 400.0)
		m._gui_input(mv)
	m._gui_input(_clic(m.size * 0.5 + Vector2(240, 2400), false))
	_check(z.pan != pan0 and z.pan.x <= 0.0 and z.pan.y <= 0.0 and z.pan.x >= m.size.x * (1.0 - z.zoom) - 0.5 and z.pan.y >= m.size.y * (1.0 - z.zoom) - 0.5, "arrastrar desplaza y no deja ver fuera del mapa (%s)" % z.pan)
	_check(not z.moviendo, "al soltar el arrastre la base vuelve a la caché")
	# la carta vuela al punto que se ve en pantalla
	var pg := m.posicion_global("biobio")
	_check(pg.distance_to(m.get_global_transform() * m.a_pantalla(m.centro("biobio"))) < 1.0, "la carta vuela a la región con el zoom aplicado")
	# «Ver todo»: vuelve a la vista completa al instante (movimiento apagado)
	m._ver_todo.pressed.emit()
	await _cuadros(1)
	_check(not z.acercado() and z.pan == Vector2.ZERO and not m._ver_todo.visible, "«Ver todo» vuelve a la vista completa")
	# pellizco y rueda acercan dejando fijo el punto bajo el dedo
	var punto := m.size * Vector2(0.3, 0.6)
	var g := InputEventMagnifyGesture.new()
	g.factor = 1.8
	g.position = punto
	m._gui_input(g)
	var dentro := m._cam().affine_inverse() * punto
	_check(is_equal_approx(z.zoom, 1.8) and m.a_pantalla(dentro).distance_to(punto) < 1.0, "el pellizco acerca sobre los dedos (%.2f)" % z.zoom)
	var rueda := InputEventMouseButton.new()
	rueda.button_index = MOUSE_BUTTON_WHEEL_UP
	rueda.pressed = true
	rueda.position = punto
	m._gui_input(rueda)
	_check(z.zoom > 1.8 and z.zoom <= MapaZoom.MAX, "la rueda acerca (%.2f)" % z.zoom)
	for k in range(20):
		m._gui_input(g)
	_check(is_equal_approx(z.zoom, MapaZoom.MAX), "el zoom tiene tope (%.1f)" % z.zoom)
	m._ver_todo.pressed.emit()
	await _cuadros(1)
	# por el camino real: doble toque con InputEventScreenTouch
	var pr := m.get_global_transform() * m.centro("maule")
	for k in range(2):
		_toque_real(pr, true)
		await _cuadros(1)
		_toque_real(pr, false)
		await _cuadros(1)
	_check(z.acercado(), "el doble toque real (pantalla táctil) acerca el mapa")
	_check(main.motor.estado.entradas.size() == 0, "acercar el mapa no juega cartas ni registra acciones")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	if _fallos == 0:
		print("MAPA ZOOM OK")
	quit(1 if _fallos > 0 else 0)
