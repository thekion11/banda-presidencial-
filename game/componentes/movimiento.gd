class_name Movimiento
extends RefCounted
## Sistema de movimiento de la dirección visual v4 (lienzo de Claude Design «Dirección visual v4», 25-nov-2026):
## entradas escalonadas, presión de botones, halo del botón principal, cifras que cuentan, barras que se llenan.
## Solo presentación (nunca toca sim/). Se apaga con Ajustes › Animaciones y en modo headless: las pruebas
## miden siempre el estado final, sin escalas ni desplazamientos a medio camino.

const RAPIDO := 0.12  # toque, presión de botón
const BASE := 0.26  # entrar a una pantalla, hojas
const ENFASIS := 0.7  # cifras que cuentan, barras que se llenan
const PASO := 0.04  # separación entre hijos de una entrada escalonada
const ALZA := 16.0  # píxeles que sube una pantalla al entrar


static var forzado: int = -1  # solo pruebas: -1 automático, 0 apagado, 1 encendido (tests/test_movimiento.gd)


static func activo() -> bool:
	if forzado >= 0:
		return forzado == 1
	return Ajustes.animaciones and DisplayServer.get_name() != "headless"


static func entrar_pantalla(p: Control) -> void:
	## La pantalla nueva se funde y sube unos píxeles (salida cúbica). Sin animaciones, aparece de inmediato.
	if not activo():
		p.modulate.a = 1.0
		return
	p.modulate.a = 0.0
	p.position.y = ALZA
	var tw := p.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate:a", 1.0, BASE)
	tw.tween_property(p, "position:y", 0.0, BASE + 0.08)


static func aparecer(c: Control, demora: float = 0.0, dur: float = BASE) -> void:
	## Un bloque se funde y crece de 0,96 a 1 desde su centro (seguro dentro de contenedores: no toca su posición).
	if not activo() or c == null:
		return
	var alfa := c.modulate.a
	c.modulate.a = 0.0
	var tw := c.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", alfa, dur).set_delay(demora)
	tw.tween_method(func(t: float) -> void:
		c.pivot_offset = c.size * 0.5
		c.scale = Vector2.ONE * lerpf(0.96, 1.0, t), 0.0, 1.0, dur).set_delay(demora)


static func escalonar(cont: Node, demora: float = 0.0, paso: float = PASO, max_hijos: int = 14) -> void:
	## Entrada escalonada de los hijos visibles de un contenedor (los que pasan de `max_hijos` entran juntos).
	if not activo() or cont == null:
		return
	var i := 0
	for h in cont.get_children():
		if h is Control and (h as Control).visible:
			aparecer(h, demora + paso * float(mini(i, max_hijos)))
			i += 1


static func presion(b: BaseButton) -> void:
	## El botón se hunde a 0,95 al tocarlo y rebota al soltarlo. Se engancha una vez por botón (main.gd lo hace con todos).
	if b.has_meta("_presion") or b.has_meta("sin_presion"):
		return
	b.set_meta("_presion", true)
	b.button_down.connect(func() -> void: _escalar(b, 0.95, RAPIDO, false))
	b.button_up.connect(func() -> void: _escalar(b, 1.0, 0.24, true))


static func _escalar(c: Control, e: float, dur: float, rebote: bool) -> void:
	if not activo() or not is_instance_valid(c) or not c.is_inside_tree():
		return
	c.pivot_offset = c.size * 0.5
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2.ONE * e, dur).set_trans(Tween.TRANS_BACK if rebote else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


static func latido(c: Control, fuerza: float = 1.12) -> void:
	## Pulso breve (cambió la cifra que muestra: movimientos, contador).
	if not activo() or c == null or not c.is_inside_tree():
		return
	c.pivot_offset = c.size * 0.5
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2.ONE * fuerza, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func halo(b: Control, color: Color = Tema.ORO, radio: int = 27) -> void:
	## Halo que respira detrás del botón principal. Es un hijo dibujado detrás: el rectángulo del botón no cambia
	## (regla del botón principal fijo, tests/test_ui_humo.gd).
	if not activo() or b.has_meta("_halo"):
		return
	b.set_meta("_halo", true)
	var h := Panel.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.show_behind_parent = true
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["offset_left", "offset_top"]:
		h.set(lado, -3.0)
	for lado in ["offset_right", "offset_bottom"]:
		h.set(lado, 3.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, 0.0)
	sb.draw_center = false
	sb.set_corner_radius_all(radio + 3)
	sb.border_color = Color(color, 0.55)
	sb.set_border_width_all(2)
	sb.shadow_color = Color(color, 0.42)
	sb.shadow_size = 12
	h.add_theme_stylebox_override("panel", sb)
	b.add_child(h)
	b.move_child(h, 0)
	h.modulate.a = 0.1
	var tw := h.create_tween().set_loops()
	tw.tween_property(h, "modulate:a", 0.9, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(h, "modulate:a", 0.1, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


static func contar(l: Label, hasta: float, formato: Callable, desde: float = 0.0, dur: float = ENFASIS, demora: float = 0.0) -> void:
	## La cifra cuenta de `desde` a `hasta`. `formato` recibe el número y devuelve el texto. Sin animaciones, pone el final.
	if not activo() or is_equal_approx(desde, hasta):
		l.text = formato.call(hasta)
		return
	l.text = formato.call(desde)
	var tw := l.create_tween()
	tw.tween_method(func(v: float) -> void: l.text = formato.call(v), desde, hasta, dur).set_delay(demora).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func destello(c: CanvasItem, color: Color, dur: float = 0.6) -> void:
	## Tiñe el elemento un instante (verde si subió, coral si bajó) y vuelve a su color.
	if not activo() or c == null:
		return
	c.modulate = Color.WHITE.lerp(color, 0.65)
	c.create_tween().tween_property(c, "modulate", Color.WHITE, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func barra(b: Range, valor: float, desde: float = -1.0, dur: float = ENFASIS) -> void:
	## Barra que se llena hasta `valor` (desde su valor actual, o desde `desde` si se indica).
	if not activo():
		b.value = valor
		return
	if desde >= 0.0:
		b.value = desde
	b.create_tween().tween_property(b, "value", valor, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func ancho(c: Control, w: float, demora: float = 0.0, dur: float = ENFASIS) -> void:
	## Un relleno (ColorRect u otro Control fuera de contenedores) crece desde 0 hasta `w` de ancho.
	if not activo():
		c.size.x = w
		return
	c.size.x = 0.0
	c.create_tween().tween_property(c, "size:x", w, dur).set_delay(demora).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func mecer(c: Control, y: float, amplitud: float = 3.0, demora: float = 0.45) -> void:
	## Vaivén vertical suave y continuo (la carta elegida de la mano). El tween muere con el nodo.
	if not activo():
		return
	var tw := c.create_tween().set_loops()
	tw.tween_interval(demora)
	tw.tween_property(c, "position:y", y - amplitud, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(c, "position:y", y, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
