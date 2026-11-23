class_name ObraIso
extends Control
## Hito de obra en vista isométrica: 5 fases (licitación, faena, estructura, terminación, inauguración) con interpolación suave.

var fase: float = 1.0:
	set(v):
		fase = v
		queue_redraw()
var _t: float = 0.0


func _init() -> void:
	clip_contents = true


func _poli(pts: PackedVector2Array, col: Color) -> void:
	var a := 0.0
	for i in range(pts.size()):
		var q := pts[(i + 1) % pts.size()]
		a += pts[i].x * q.y - q.x * pts[i].y
	if absf(a) > 1.0:
		draw_colored_polygon(pts, col)


func reproducir() -> void:
	fase = 1.0
	create_tween().tween_property(self, "fase", 5.0, 4.5).set_trans(Tween.TRANS_LINEAR)


func ir_a(f: int) -> void:
	create_tween().tween_property(self, "fase", float(f), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _p(x: float, y: float, z: float) -> Vector2:
	var u := size.x / 17.0
	return Vector2(size.x * 0.5 + (x - y) * u * 0.9, size.y * 0.40 + (x + y) * u * 0.45 - z * u * 0.8)


func _caja(x: float, y: float, w: float, d: float, h: float, col: Color, z0: float = 0.0) -> void:
	if h <= 0.01:
		return
	var z1 := z0 + h
	_poli(PackedVector2Array([_p(x, y + d, z0), _p(x + w, y + d, z0), _p(x + w, y + d, z1), _p(x, y + d, z1)]), col.darkened(0.2))
	_poli(PackedVector2Array([_p(x + w, y, z0), _p(x + w, y + d, z0), _p(x + w, y + d, z1), _p(x + w, y, z1)]), col.darkened(0.36))
	_poli(PackedVector2Array([_p(x, y, z1), _p(x + w, y, z1), _p(x + w, y + d, z1), _p(x, y + d, z1)]), col)


func _prog(desde: float, hasta: float) -> float:
	return clampf((fase - desde) / (hasta - desde), 0.0, 1.0)


func _draw() -> void:
	_caja(-0.5, -0.5, 8.0, 7.0, 0.25, Color("#DDD3BA"))  # terreno
	_caja(0.6, 3.6, 6.2, 0.9, 0.12, Color("#BDB39A"))  # calle
	# Fase 1: licitación (cartel de obra)
	var a1 := 1.0 - _prog(1.6, 2.2)
	_caja(0.2, 0.3, 0.2, 0.2, 1.6 * a1, Color("#8B5E3C"), 0.25)
	_caja(0.0, 0.3, 1.2 * a1, 0.12, 0.7 * a1, Tema.ORO, 1.2)
	# Fase 2: faena (excavación + grúa)
	var f2 := _prog(1.6, 2.6)
	_caja(1.6, 0.8, 4.6, 3.0, 0.1 * f2, Color("#B8A98A"), 0.25)
	if fase > 1.7:
		var g := _prog(1.7, 2.4)
		_caja(6.2, 0.6, 0.25, 0.25, 4.2 * g, Tema.ROJO, 0.25)
		_caja(3.2, 0.6, 3.3 * g, 0.18, 0.18, Tema.ROJO, 4.4 * g)
		if g > 0.9:
			draw_line(_p(3.6, 0.7, 4.5), _p(3.6, 0.7, 2.2 + 0.5 * sin(_t)), Color("#555"), 1.5)
	# Fase 3: estructura
	var f3 := _prog(2.6, 3.6)
	for i in range(3):
		for j in range(2):
			_caja(1.8 + float(i) * 2.0, 0.9 + float(j) * 2.0, 0.34, 0.34, 3.0 * f3, Color("#C9BFA5"), 0.25)
	_caja(1.7, 0.8, 4.6, 2.6, 0.3 * _prog(3.2, 3.9), Color("#D8CFB8"), 3.25)
	# Fase 4: terminación (muros y accesos)
	var f4 := _prog(3.7, 4.6)
	_caja(1.8, 0.9, 4.4, 0.18, 2.9 * f4, Color("#E6DFCD"), 0.3)
	_caja(1.8, 0.9, 0.18, 2.4, 2.9 * f4, Color("#E6DFCD"), 0.3)
	_caja(2.4, 3.4, 1.4, 0.7, 0.14 * f4, Color("#EFEAD9"), 0.25)
	# Fase 5: inauguración (techo, mástil y cinta)
	var f5 := _prog(4.5, 5.0)
	_caja(1.6, 0.7, 4.9, 2.8, 0.4 * f5, Color("#F2EEE2"), 3.55)
	_caja(5.9, 3.3, 0.08, 0.08, 2.4 * f5, Color("#EEE"), 3.9)
	if f5 > 0.2:
		_poli(PackedVector2Array([_p(5.9, 3.3, 6.2), _p(5.9, 3.3, 5.6), _p(5.9 + 1.1, 3.3 + 0.2, 5.9)]), Tema.ROJO)
	if f5 > 0.5:
		draw_line(_p(2.4, 4.2, 0.4), _p(3.8, 4.2, 0.4), Tema.ROJO, 3.0)


func _process(delta: float) -> void:
	_t += delta * 2.0
	if fase > 1.7 and fase < 2.6 and is_visible_in_tree():
		queue_redraw()
