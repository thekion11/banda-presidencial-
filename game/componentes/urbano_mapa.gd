class_name UrbanoMapa
extends Control
## Mapa urbano esquemático de Gran Santiago (tema claro): manzanas, río, parques, líneas de Metro, propuesta punteada y obras con %.

var datos: Dictionary = {}
var propuesta: Array = []  # trazado de la propuesta abierta/aprobada (coordenadas 0..1)
var marcadores: Array = []  # [{"pct": int, "color": Color}]
var mostrar_metro: bool = true
var trazo: float = 1.0:
	set(v):
		trazo = v
		queue_redraw()


func _init() -> void:
	clip_contents = true


func cargar(p_datos: Dictionary) -> void:
	datos = p_datos
	trazo = 0.0
	create_tween().tween_property(self, "trazo", 1.0, 1.0).set_trans(Tween.TRANS_SINE)


func _p(x: float, y: float) -> Vector2:
	return Vector2(10.0 + x * (size.x - 20.0), 10.0 + y * (size.y - 20.0))


func _draw() -> void:
	draw_style_box(Tema.caja(Color("#EFEADF"), 16, Tema.BORDE_CLARO, 1), Rect2(Vector2.ZERO, size))
	if datos.is_empty():
		return
	var bw := 0.135
	var bh := 0.115
	for i in range(6):
		for j in range(7):
			var x := 0.03 + float(i) * 0.162
			var y := 0.03 + float(j) * 0.138
			draw_style_box(Tema.caja(Color("#DDD3BC"), 5), Rect2(_p(x, y), Vector2(bw * (size.x - 20.0), bh * (size.y - 20.0))))
	for pk in datos["parques"]:
		draw_style_box(Tema.caja(Color("#BFD9B4"), 5), Rect2(_p(pk[0], pk[1]), Vector2(pk[2] * (size.x - 20.0), pk[3] * (size.y - 20.0))))
	var rio := PackedVector2Array()
	for q in datos["rio"]:
		rio.append(_p(q[0], q[1]))
	draw_polyline(rio, Color("#A9CFE4"), size.y * 0.055, true)
	if mostrar_metro:
		for l in datos["lineas"]:
			var pts := PackedVector2Array()
			for q in l["puntos"]:
				pts.append(_p(q[0], q[1]))
			var hasta := maxi(2, int(ceil(float(pts.size()) * trazo)))
			draw_polyline(pts.slice(0, hasta), Color(l["color"]), 4.5, true)
			if trazo > 0.95:
				for t in l["estaciones"]:
					var c := _punto_en(pts, float(t))
					draw_circle(c, 5.6, Tema.TINTA)
					draw_circle(c, 3.8, Color.WHITE)
	if propuesta.size() >= 2:
		var pp := PackedVector2Array()
		for q in propuesta:
			pp.append(_p(q[0], q[1]))
		var hasta2 := maxi(2, int(ceil(float(pp.size()) * trazo)))
		for k in range(hasta2 - 1):
			draw_dashed_line(pp[k], pp[k + 1], Color("#2B4BA8"), 3.2, 7.0, true)
		for q in pp.slice(0, hasta2):
			draw_circle(q, 4.4, Color("#2B4BA8"))
			draw_circle(q, 2.4, Color.WHITE)
	var mk: Array = datos["marcadores"]
	for i in range(mini(mk.size(), marcadores.size())):
		var c2 := _p(mk[i][0], mk[i][1])
		var m: Dictionary = marcadores[i]
		draw_circle(c2, 15.0, Color(1, 1, 1, 0.9))
		draw_circle(c2, 13.0, m["color"])
		draw_string(Tema.fuente_titulo(), c2 + Vector2(-13, 4.5), "%d%%" % int(m["pct"]), HORIZONTAL_ALIGNMENT_CENTER, 26.0, 11, Tema.TEXTO)
	var leyenda := Rect2(10, size.y - 34, 150, 24)
	draw_style_box(Tema.caja(Color("#FBF7EC"), 8, Tema.BORDE_CLARO, 1), leyenda)
	draw_line(leyenda.position + Vector2(8, 12), leyenda.position + Vector2(24, 12), Tema.ROJO, 3.0)
	draw_string(Tema.fuente_texto(500), leyenda.position + Vector2(28, 16), "Líneas", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TINTA)
	draw_dashed_line(leyenda.position + Vector2(74, 12), leyenda.position + Vector2(92, 12), Color("#2B4BA8"), 3.0, 4.0)
	draw_string(Tema.fuente_texto(500), leyenda.position + Vector2(96, 16), "Propuesta", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TINTA)
	draw_string(Tema.fuente_texto(400), Vector2(size.x - 190, size.y - 14), "© colaboradores de OpenStreetMap (Fase 3)", HORIZONTAL_ALIGNMENT_RIGHT, 180, 9, Color("#6A7684"))


static func _punto_en(pts: PackedVector2Array, t: float) -> Vector2:
	var largo := 0.0
	for i in range(pts.size() - 1):
		largo += pts[i].distance_to(pts[i + 1])
	var objetivo := clampf(t, 0.0, 1.0) * largo
	for i in range(pts.size() - 1):
		var d := pts[i].distance_to(pts[i + 1])
		if objetivo <= d:
			return pts[i].lerp(pts[i + 1], objetivo / maxf(d, 0.001))
		objetivo -= d
	return pts[pts.size() - 1]
