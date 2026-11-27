class_name MapaZoom
extends RefCounted
## Zoom del mapa de Chile (pedido del usuario del 27-nov-2026: «El mapa del país debe agrandarse un poco para ver todas
## las regiones, además de poder hacerle zoom»). Lleva la vista (acercamiento y desplazamiento con límites) y entiende
## los gestos: pellizco (InputEventMagnifyGesture en Android y trackpad), rueda, doble toque para acercar o volver,
## y arrastre con un dedo cuando está acercado. MapaChile compone `vista` con su cámara y decide el toque simple.

const MAX := 4.0
const DOBLE := 2.5  # acercamiento del doble toque
const UMBRAL_ARRASTRE := 10.0
const DOBLE_MS := 320

var zoom := 1.0
var pan := Vector2.ZERO  # desplazamiento de la vista, en píxeles del control
var _serie := 0  # cuenta los eventos de un gesto continuo (el último cierra el gesto)
var moviendo := false  # gesto o animación en curso: el mapa se dibuja en vivo (sin caché)
var _tam := Vector2.ZERO
var _pulsado := false
var _movido := false
var _origen := Vector2.ZERO
var _ultimo_toque_ms := -10000
var _ultimo_toque := Vector2.ZERO
var _tween: Tween


func vista() -> Transform2D:
	return Transform2D(0.0, Vector2(zoom, zoom), 0.0, pan)


func acercado() -> bool:
	return zoom > 1.01


func limitar(tam: Vector2) -> void:
	## La vista nunca deja ver fuera del mapa: el contenido acercado cubre siempre el control.
	_tam = tam
	zoom = clampf(zoom, 1.0, MAX)
	pan.x = clampf(pan.x, tam.x * (1.0 - zoom), 0.0)
	pan.y = clampf(pan.y, tam.y * (1.0 - zoom), 0.0)


func acercar_en(factor: float, punto: Vector2, tam: Vector2) -> void:
	## Acerca o aleja manteniendo fijo el punto bajo el dedo.
	var antes := zoom
	zoom = clampf(zoom * factor, 1.0, MAX)
	pan = punto - (punto - pan) * (zoom / antes)
	limitar(tam)


func ir_a(nuevo_zoom: float, punto: Vector2, tam: Vector2, nodo: Node, al_cambiar: Callable) -> void:
	## Cambio de zoom del doble toque o de «Ver todo»: animado si hay movimiento, inmediato con «Reducir movimiento».
	var z0 := zoom
	var p0 := pan
	var destino := MapaZoom.new()
	destino.zoom = z0
	destino.pan = p0
	destino.acercar_en(nuevo_zoom / maxf(z0, 0.001), punto, tam)
	if nuevo_zoom <= 1.0:
		destino.zoom = 1.0
		destino.pan = Vector2.ZERO
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not Movimiento.activo() or Ajustes.reducir:
		zoom = destino.zoom
		pan = destino.pan
		moviendo = false
		al_cambiar.call()
		return
	moviendo = true
	_tween = nodo.create_tween()
	_tween.tween_method(func(t: float) -> void:
		zoom = lerpf(z0, destino.zoom, t)
		pan = p0.lerp(destino.pan, t)
		al_cambiar.call(), 0.0, 1.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func() -> void:
		moviendo = false
		al_cambiar.call())


func _gesto_continuo(nodo: Node, al_cambiar: Callable) -> void:
	## Pellizco o arrastre con dos dedos: mientras llegan eventos el mapa mueve su caché (sin repintarla); 150 ms después
	## del último, se da por terminado y la caché se repinta una vez, nítida (informe del teléfono: mínimo 34 fps).
	moviendo = true
	_serie += 1
	var mia := _serie
	al_cambiar.call()
	if nodo != null and nodo.is_inside_tree():
		nodo.get_tree().create_timer(0.15).timeout.connect(func() -> void:
			if mia == _serie and moviendo and not _pulsado:
				moviendo = false
				al_cambiar.call())


func gestionar(ev: InputEvent, tam: Vector2, nodo: Node, al_cambiar: Callable) -> Dictionary:
	## Devuelve {"consumido": bool, "toque": Vector2 o null}. «toque» es un toque simple (soltar sin arrastre) que
	## MapaChile convierte en elegir región.
	if ev is InputEventMagnifyGesture:
		acercar_en(ev.factor, ev.position, tam)
		_gesto_continuo(nodo, al_cambiar)
		return {"consumido": true}
	if ev is InputEventPanGesture and acercado():
		pan -= ev.delta * 8.0
		limitar(tam)
		_gesto_continuo(nodo, al_cambiar)
		return {"consumido": true}
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			acercar_en(1.2, ev.position, tam)
			al_cambiar.call()
			return {"consumido": true}
		if ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			acercar_en(1.0 / 1.2, ev.position, tam)
			al_cambiar.call()
			return {"consumido": true}
		if ev.button_index != MOUSE_BUTTON_LEFT:
			return {"consumido": false}
		if ev.pressed:
			_pulsado = true
			_movido = false
			_origen = ev.position
			return {"consumido": true}
		var era: bool = _pulsado and not _movido and not ev.canceled
		_pulsado = false
		if moviendo and _movido:
			moviendo = false
			al_cambiar.call()  # termina el arrastre: vuelve la caché
		if not era:
			return {"consumido": true}
		var ahora := Time.get_ticks_msec()
		if ahora - _ultimo_toque_ms < DOBLE_MS and ev.position.distance_to(_ultimo_toque) < 30.0:  # doble toque
			_ultimo_toque_ms = -10000
			ir_a(1.0 if acercado() else DOBLE, ev.position, tam, nodo, al_cambiar)
			return {"consumido": true}
		_ultimo_toque_ms = ahora
		_ultimo_toque = ev.position
		return {"consumido": true, "toque": ev.position}
	if ev is InputEventMouseMotion and _pulsado:
		if not _movido and ev.position.distance_to(_origen) > UMBRAL_ARRASTRE:
			_movido = true
		if _movido and acercado():
			moviendo = true
			pan += ev.relative
			limitar(tam)
			al_cambiar.call()
		return {"consumido": true}
	return {"consumido": false}


static func rotular(ci: CanvasItem, nombres: Dictionary, ids: Array, zoom: float, a_pantalla: Callable) -> Array:
	## Al acercar (zoom ≥ 1,6) cada región visible lleva su nombre, a tamaño fijo y legible sobre una pastilla oscura;
	## si dos nombres se encimarían, se salta el segundo. Devuelve [[id, área de toque ≥ 44 px], …] para elegir tocándolos.
	var tocables: Array = []
	if zoom < 1.6 or nombres.is_empty():
		return tocables
	var f := Tema.fuente_texto(600)
	var vista := Rect2(Vector2.ZERO, (ci as Control).size)
	var puestos: Array[Rect2] = []
	for id in ids:
		var p: Vector2 = a_pantalla.call(String(id))
		var nombre := String(nombres.get(id, ""))
		if nombre == "" or not vista.grow(-8.0).has_point(p):
			continue
		var w := f.get_string_size(nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var r := Rect2(p + Vector2(10.0, -10.0), Vector2(w + 12.0, 20.0))
		if puestos.any(func(o: Rect2) -> bool: return o.grow(2.0).intersects(r)):
			continue
		puestos.append(r)
		ci.draw_style_box(Tema.caja(Color(0.04, 0.13, 0.21, 0.82), 8), r)
		ci.draw_string(f, r.position + Vector2(6.0, 14.5), nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Tema.TEXTO)
		tocables.append([String(id), Rect2(r.position.x, r.get_center().y - 22.0, maxf(r.size.x, 44.0), 44.0)])
	return tocables
