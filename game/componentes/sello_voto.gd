class_name SelloVoto
extends Control
## Sello APROBADA / RECHAZADA de una votación (dirección visual v4). Vive fuera de los contenedores para que
## su giro y su escala no se reinicien: cae girado desde grande, golpea (onda expansiva, chispas, temblor de la
## capa y sonido) y, si se rechaza, hace un vaivén de «no». Sin animaciones queda quieto en su estado final.

const GIRO := -6.0

var aprobada: bool = true
var demora: float = 1.35
var _caja: PanelContainer
var _onda: float = -1.0  # 0..1 tras el golpe
var _chispas: Array[Vector2] = []


static func crear(p_aprobada: bool, p_demora: float = 1.35) -> SelloVoto:
	var s := SelloVoto.new()
	s.aprobada = p_aprobada
	s.demora = p_demora
	s.custom_minimum_size = Vector2(0, 70)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _color() -> Color:
	return Tema.bien() if aprobada else Tema.mal()


func _ready() -> void:
	_caja = PanelContainer.new()
	_caja.add_theme_stylebox_override("panel", Tema.caja(Color(_color(), 0.12), 10, _color(), 3))
	_caja.add_child(Tema.etiqueta_corta("APROBADA" if aprobada else "RECHAZADA", 30, _color(), true))
	_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caja)
	_caja.rotation_degrees = GIRO
	resized.connect(_centrar)
	_caja.resized.connect(_centrar)
	_centrar()
	for i in range(14):
		var a := TAU * float(i) / 14.0 + 0.2 * sin(float(i) * 7.0)
		_chispas.append(Vector2(cos(a), sin(a) * 0.55) * (1.0 + 0.35 * float(i % 3)))
	if not Movimiento.activo():
		return
	_caja.modulate.a = 0.0
	_caja.scale = Vector2.ONE * 3.0
	_caja.rotation_degrees = -18.0
	var tw := _caja.create_tween()
	tw.tween_interval(demora)
	tw.tween_property(_caja, "modulate:a", 1.0, 0.08)
	tw.parallel().tween_property(_caja, "scale", Vector2.ONE * 0.9, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_caja, "rotation_degrees", GIRO, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_golpe)
	tw.tween_property(_caja, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not aprobada:  # vaivén de «no»
		for g in [GIRO + 5.0, GIRO - 5.0, GIRO + 3.0, GIRO]:
			tw.tween_property(_caja, "rotation_degrees", g, 0.07).set_trans(Tween.TRANS_SINE)


func _centrar() -> void:
	if _caja == null:
		return
	_caja.size = _caja.get_combined_minimum_size()
	_caja.position = (size - _caja.size) * 0.5
	_caja.pivot_offset = _caja.size * 0.5


func _golpe() -> void:
	Feedback.sonar("exito" if aprobada else "error")
	Feedback.vibrar(45 if aprobada else 70)
	var capa := get_parent()  # la columna del evento tiembla un instante (no es un contenedor: su posición no se reinicia)
	if Movimiento.intenso() and capa != null and capa.get_parent() is Control and not (capa.get_parent() is Container):
		var c := capa as Control
		var tw := c.create_tween()
		for d in [Vector2(0, 7), Vector2(-4, -3), Vector2(3, 2), Vector2(0, 0)]:
			tw.tween_property(c, "position", d + Vector2(c.offset_left, c.offset_top), 0.05)
	create_tween().tween_method(func(t: float) -> void:
		_onda = t
		queue_redraw(), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	if _onda < 0.0 or _onda >= 1.0 or _caja == null:
		return
	var col := _color()
	var r := Rect2(_caja.position, _caja.size).grow(8.0 + 34.0 * _onda)
	draw_style_box(_contorno(col, 1.0 - _onda), r)
	var c := size * 0.5
	for v in (_chispas if Movimiento.intenso() else []):
		var p := c + v * (_caja.size.x * 0.5 + 70.0 * _onda)
		draw_circle(p, 3.5 * (1.0 - _onda), Color(col if aprobada else Tema.mal(), 1.0 - _onda))


func _contorno(col: Color, a: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(3)
	sb.border_color = Color(col, a * 0.8)
	return sb
