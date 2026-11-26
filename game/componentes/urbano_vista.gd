class_name UrbanoVista
extends Control
## Base de los mapas de Gran Santiago con zoom: pellizco, rueda, doble toque y botones «+» / «−»; arrastre con el dedo; y
## dibujo con menos detalle mientras se mueve (fluidez en el teléfono). Las subclases deciden qué hace un toque y pueden
## quedarse con un arrastre (p. ej. mover una estación) devolviendo true en `_vista_empieza`.

const MARGEN := Vector2(8, 8)
const ZOOM_MAX := 5.0
const UMBRAL_ARRASTRE := 10.0

var zoom: float = 1.0
var pan: Vector2 = Vector2.ZERO
var _en_movimiento: bool = false  # mientras se arrastra o se acerca se dibuja con menos detalle
var _fin_movimiento: Timer
var _pulsado: bool = false
var _movido: bool = false
var _capturado: bool = false  # la subclase se quedó con este arrastre
var _origen: Vector2 = Vector2.ZERO
var _ultimo_toque: float = -10.0
var _pos_ultimo_toque: Vector2 = Vector2.ZERO


func _iniciar_vista() -> void:
	_fin_movimiento = Timer.new()
	_fin_movimiento.one_shot = true
	_fin_movimiento.wait_time = 0.18
	_fin_movimiento.timeout.connect(func() -> void:
		_en_movimiento = false
		queue_redraw())
	add_child(_fin_movimiento)
	var col := VBoxContainer.new()
	col.offset_left = 8.0
	col.offset_right = 52.0
	col.offset_top = 8.0
	col.add_theme_constant_override("separation", 4)
	for par in [["+", 1.5], ["−", 1.0 / 1.5]]:
		var b := Tema.boton(String(par[0]), Color.WHITE, Tema.TINTA, 18, 44)
		b.custom_minimum_size = Vector2(44, 44)
		for e in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(e, Tema.caja(Color(1, 1, 1, 0.94), 12, Tema.BORDE_CLARO, 1))
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void: _zoom_en(float(par[1]), size * 0.5))
		col.add_child(b)
	add_child(col)


var _cache: UrbanoCache


func _dibujar_base(con_metro: bool, escala_linea: float, suave: float, radio: int) -> void:
	## Capa base de Gran Santiago. Quieta, sale de una textura pintada una vez (UrbanoCache): una llamada de dibujo y casi
	## nada de CPU. Mientras se arrastra o se acerca, en vivo y con menos detalle. Deja puesta la transformación (pan, zoom).
	if _en_movimiento:
		draw_set_transform(pan, 0.0, Vector2(zoom, zoom))
		UrbanoBase.dibujar(self, size, MARGEN, con_metro, escala_linea, suave, false)
		return
	if _cache == null:
		_cache = UrbanoCache.new()
		add_child(_cache)
	var s := clampf(get_viewport().get_final_transform().get_scale().x, 1.0, 4.0)  # escala real de la pantalla
	var clave := "%s|%.3f|%.3f|%.4f|%.1f,%.1f|%s|%d|%s|%.2f" % [con_metro, escala_linea, suave, zoom, pan.x, pan.y, str(UrbanoBase.ocultas.keys()), hash(UrbanoBase.propias), UrbanoBase.fecha_iso, s]
	var tam := size
	var p := pan
	var z := zoom
	_cache.pintar = func(ci: CanvasItem) -> void:
		ci.draw_style_box(Tema.caja(Color("#EFEADF"), roundi(radio * s)), Rect2(Vector2.ZERO, tam * s))  # fondo con las esquinas redondeadas
		ci.draw_set_transform(p * s, 0.0, Vector2(z * s, z * s))
		UrbanoBase.dibujar(ci, tam, MARGEN, con_metro, escala_linea, suave, true)
	_cache.preparar(size, s, clave)
	draw_texture_rect(_cache.get_texture(), Rect2(Vector2.ZERO, size), false)
	draw_style_box(Tema.caja(Color(0, 0, 0, 0), radio, Tema.BORDE_CLARO, 1), Rect2(Vector2.ZERO, size))
	draw_set_transform(pan, 0.0, Vector2(zoom, zoom))


func _limitar() -> void:
	zoom = clampf(zoom, 1.0, ZOOM_MAX)
	pan = Vector2(clampf(pan.x, size.x - size.x * zoom, 0.0), clampf(pan.y, size.y - size.y * zoom, 0.0))
	_en_movimiento = true
	if _fin_movimiento != null:
		_fin_movimiento.start()
	queue_redraw()


func _zoom_en(factor: float, centro: Vector2) -> void:
	var nuevo := clampf(zoom * factor, 1.0, ZOOM_MAX)
	pan = centro - (centro - pan) * (nuevo / zoom)
	zoom = nuevo
	_limitar()


func a_local(pos: Vector2) -> Vector2:
	## Punto de pantalla -> coordenadas del dibujo sin zoom.
	return (pos - pan) / zoom


func _vista_empieza(_pos: Vector2) -> bool:
	return false  # las subclases devuelven true para quedarse con el arrastre


func _vista_mueve(_event: InputEventMouseMotion) -> void:
	pass


func _vista_suelta(_pos: Vector2) -> void:
	pass


func _vista_toque(_pos: Vector2) -> void:
	pass


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		_zoom_en(event.factor, event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_en(1.2, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_en(1.0 / 1.2, event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pulsado = true
				_movido = false
				_origen = event.position
				_capturado = _vista_empieza(event.position)
			else:
				if _pulsado and _capturado:
					_vista_suelta(event.position)
				elif _pulsado and not _movido:
					_toque(event.position)
				_pulsado = false
				_capturado = false
	elif event is InputEventMouseMotion and _pulsado:
		if _capturado:
			_vista_mueve(event)
			return
		if not _movido and event.position.distance_to(_origen) > UMBRAL_ARRASTRE:
			_movido = true
		if _movido:
			pan += event.relative
			_limitar()


func _toque(pos: Vector2) -> void:
	var ahora := Time.get_ticks_msec() / 1000.0
	if ahora - _ultimo_toque < 0.35 and pos.distance_to(_pos_ultimo_toque) < 30.0:  # doble toque: acerca o vuelve a la vista completa
		_ultimo_toque = -10.0
		_vista_toque(_pos_ultimo_toque)  # el primer toque ya había actuado (ocultar línea, abrir burbuja): se deshace
		if zoom < 2.0:
			_zoom_en(2.5 / zoom, pos)
		else:
			zoom = 1.0
			pan = Vector2.ZERO
			_limitar()
		return
	_ultimo_toque = ahora
	_pos_ultimo_toque = pos
	_vista_toque(pos)
