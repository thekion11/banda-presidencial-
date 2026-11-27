class_name Icono
extends Control
## Íconos de línea vectoriales (sin emojis). Se dibujan en un cuadrado de `size`.

const TIPOS := ["star", "bolt", "play", "person", "people", "map", "bars", "building", "up", "down", "train", "home", "grid", "dot", "card", "baul"]
const TAMANOS := [12.0, 16.0, 18.0, 20.0, 24.0]  # punto de leyenda, junto a texto, en cápsula, navegación, botón redondo
const TRAZO_POR_LADO := 2.0 / 24.0  # trazo de los íconos de línea: 2 px a 24 px, como la maqueta (antes 1,5 con piso 1,3)

var tipo: String = "star"
var color: Color = Tema.TEXTO
var relleno: bool = false


static func crear(p_tipo: String, p_color: Color, lado: float = 22.0, p_relleno: bool = false) -> Icono:
	var i := Icono.new()
	i.tipo = p_tipo
	i.color = p_color
	i.relleno = p_relleno
	i.custom_minimum_size = Vector2(lado, lado)
	i.size = Vector2(lado, lado)
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return i


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) * 0.5
	var u := s / 24.0
	var w := maxf(1.3, s * TRAZO_POR_LADO)  # mismo peso visual en todos los tamaños
	var P := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * u
	match tipo:
		"star":
			var pts := PackedVector2Array()
			for k in range(10):
				var r := 10.0 if k % 2 == 0 else 4.2
				var a := -PI / 2.0 + float(k) * PI / 5.0
				pts.append(P.call(12.0 + cos(a) * r, 12.5 + sin(a) * r))
			draw_colored_polygon(pts, color)
		"bolt":
			draw_colored_polygon(PackedVector2Array([P.call(13, 2), P.call(5, 13.5), P.call(11, 13.5), P.call(9.5, 22), P.call(19, 9.5), P.call(13, 9.5)]), color)
		"play":
			draw_colored_polygon(PackedVector2Array([P.call(7, 4), P.call(20, 12), P.call(7, 20)]), color)
		"person":
			draw_arc(P.call(12, 8), 4.2 * u, 0, TAU, 20, color, w, true)
			draw_arc(P.call(12, 22), 8.0 * u, PI * 1.08, PI * 1.92, 16, color, w, true)
		"people":
			draw_arc(P.call(9.5, 8), 3.8 * u, 0, TAU, 18, color, w, true)  # como la maqueta: una persona entera y otra asomada detrás
			draw_arc(P.call(9.5, 21.5), 7.0 * u, PI * 1.08, PI * 1.92, 14, color, w, true)
			draw_arc(P.call(15.5, 8), 3.4 * u, -PI * 0.45, PI * 0.45, 10, color, w, true)
			draw_arc(P.call(16.5, 21.5), 6.0 * u, PI * 1.6, PI * 1.92, 8, color, w, true)
		"map":
			var pl := PackedVector2Array([P.call(3, 6), P.call(9, 4), P.call(15, 6), P.call(21, 4), P.call(21, 18), P.call(15, 20), P.call(9, 18), P.call(3, 20), P.call(3, 6)])
			draw_polyline(pl, color, w, true)
			draw_line(P.call(9, 4), P.call(9, 18), color, w, true)
			draw_line(P.call(15, 6), P.call(15, 20), color, w, true)
		"bars":
			draw_line(P.call(4, 20), P.call(20, 20), color, w, true)
			for x in [6.0, 10.0, 14.0, 18.0]:
				draw_line(P.call(x, 20), P.call(x, 20.0 - (9.0 + fmod(x * 3.0, 8.0))), color, w * 1.2, true)
		"building":
			draw_polyline(PackedVector2Array([P.call(3, 9), P.call(12, 3), P.call(21, 9)]), color, w, true)  # el frontón en dos trazos: un triángulo cerrado deja puntas de inglete en las esquinas agudas
			draw_line(P.call(3, 9), P.call(21, 9), color, w, true)
			for x in [6.0, 10.0, 14.0, 18.0]:
				draw_line(P.call(x, 11), P.call(x, 19), color, w, true)
			draw_line(P.call(3, 21), P.call(21, 21), color, w, true)
		"up":
			draw_colored_polygon(PackedVector2Array([P.call(12, 4), P.call(20, 14), P.call(14, 14), P.call(14, 20), P.call(10, 20), P.call(10, 14), P.call(4, 14)]), color)
		"down":
			draw_colored_polygon(PackedVector2Array([P.call(12, 20), P.call(20, 10), P.call(14, 10), P.call(14, 4), P.call(10, 4), P.call(10, 10), P.call(4, 10)]), color)
		"train":
			draw_polyline(PackedVector2Array([P.call(6, 4), P.call(18, 4), P.call(18, 16), P.call(6, 16), P.call(6, 4)]), color, w, true)
			draw_line(P.call(6, 10), P.call(18, 10), color, w, true)
			draw_line(P.call(8, 20), P.call(10, 16), color, w, true)
			draw_line(P.call(16, 20), P.call(14, 16), color, w, true)
			draw_circle(P.call(9, 13), 1.1 * u, color)
			draw_circle(P.call(15, 13), 1.1 * u, color)
		"home":
			draw_polyline(PackedVector2Array([P.call(3, 12), P.call(12, 4), P.call(21, 12)]), color, w, true)
			draw_polyline(PackedVector2Array([P.call(6, 11), P.call(6, 20), P.call(18, 20), P.call(18, 11)]), color, w, true)
			draw_line(P.call(10, 20), P.call(10, 14), color, w, true)
			draw_line(P.call(14, 20), P.call(14, 14), color, w, true)
			draw_line(P.call(10, 14), P.call(14, 14), color, w, true)
		"grid":
			draw_rect(Rect2(P.call(4, 4), Vector2(16, 16) * u), color, false, w, true)
			draw_line(P.call(12, 4), P.call(12, 20), color, w, true)
			draw_line(P.call(4, 12), P.call(20, 12), color, w, true)
		"dot":
			draw_circle(P.call(12, 12), 6.0 * u, color)
		"baul":  # baúl de las balas de plata: tapa curva, cuerpo y cerradura
			draw_arc(P.call(12, 11), 8.0 * u, PI, TAU, 18, color, w, true)
			draw_rect(Rect2(P.call(4, 11), Vector2(16, 9) * u), color, false, w, true)
			draw_line(P.call(4, 11), P.call(20, 11), color, w, true)
			draw_rect(Rect2(P.call(10.5, 9.5), Vector2(3, 4) * u), color, true)
		"card":
			draw_rect(Rect2(P.call(6, 3), Vector2(12, 18) * u), color, false, w, true)
			draw_line(P.call(9, 8), P.call(15, 8), color, w, true)
			draw_line(P.call(9, 12), P.call(15, 12), color, w, true)
