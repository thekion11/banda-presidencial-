class_name MapaDecor
extends Control
## Capa animada sobre el mapa: barcos que se mecen y pulso sobre la región elegida. Barata: solo redibuja ~20 fps.

var mapa: MapaChile
var _t: float = 0.0
var _acum: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	_acum += delta
	if _acum >= 0.05 and is_visible_in_tree():
		_acum = 0.0
		queue_redraw()


func _barco(c: Vector2) -> void:
	var y := sin(_t * 1.6 + c.x) * 1.6
	var o := c + Vector2(0, y)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-9, 0), o + Vector2(9, 0), o + Vector2(6, 5), o + Vector2(-6, 5)]), Tema.CREMA)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-1, -1), o + Vector2(-1, -12), o + Vector2(7, -1)]), Tema.ROJO)
	draw_line(o + Vector2(-1, -1), o + Vector2(-1, -13), Tema.CREMA, 1.2)
	draw_arc(o + Vector2(0, 7), 8.0, PI * 0.1, PI * 0.9, 8, Color(0.6, 0.85, 1.0, 0.35), 1.2)


func _draw() -> void:
	if mapa == null:
		return
	var h := size.y - 16.0
	_barco(Vector2(size.x * 0.06 + 6.0, 8.0 + h * 0.37))
	_barco(Vector2(size.x * 0.05 + 12.0, 8.0 + h * 0.62))
	if mapa.seleccion != "" and mapa.valores.has(mapa.seleccion):
		var c := mapa.centro(mapa.seleccion)
		var f := fmod(_t * 0.9, 1.0)
		draw_arc(c, 8.0 + f * 18.0, 0.0, TAU, 28, Color(Tema.ORO, 1.0 - f), 2.0)
		draw_arc(c, 6.0, 0.0, TAU, 20, Tema.ORO, 2.0)
