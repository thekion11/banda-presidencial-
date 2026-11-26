class_name UrbanoTrazo
extends RefCounted
## Geometría de trazados del mapa: esquinas redondeadas (empalmes), trazo discontinuo continuo a lo largo del recorrido,
## punto más cercano de un trazado y polilíneas con extremos redondos.

const M_ANCHO := 26003.0  # metros que abarca el ancho del plano de Gran Santiago


static func metros_a_px(m: float, tam: Vector2, margen: Vector2) -> float:
	return m / (M_ANCHO / maxf(1.0, UrbanoBase.area(tam, margen).size.x))


static func redondear(pts: PackedVector2Array, radio: float, pasos: int = 4) -> PackedVector2Array:
	## Cada vértice interior se sustituye por un arco (Bézier cuadrático) de hasta `radio` px: quita los codos de los trazados
	## simplificados sin alejarse de la geometría original más que ese radio.
	if pts.size() < 3 or radio <= 0.0:
		return pts
	var out := PackedVector2Array([pts[0]])
	for i in range(1, pts.size() - 1):
		var a := pts[i - 1]
		var b := pts[i]
		var c := pts[i + 1]
		var d1 := minf(radio, a.distance_to(b) * 0.45)
		var d2 := minf(radio, b.distance_to(c) * 0.45)
		var p0 := b + (a - b).normalized() * d1
		var p2 := b + (c - b).normalized() * d2
		for k in range(pasos + 1):
			var t := float(k) / float(pasos)
			out.append(p0 * ((1.0 - t) * (1.0 - t)) + b * (2.0 * (1.0 - t) * t) + p2 * (t * t))
	out.append(pts[pts.size() - 1])
	return out


static func trazo(ci: CanvasItem, pts: PackedVector2Array, color: Color, ancho: float) -> void:
	## Polilínea con extremos redondos.
	if pts.size() < 2:
		return
	ci.draw_polyline(pts, color, ancho, true)
	ci.draw_circle(pts[0], ancho * 0.5, color)
	ci.draw_circle(pts[pts.size() - 1], ancho * 0.5, color)


static func discontinua(ci: CanvasItem, pts: PackedVector2Array, color: Color, ancho: float, trazo_px: float, hueco_px: float) -> void:
	## Trazo discontinuo que no se reinicia en cada vértice (el patrón sigue de un tramo al siguiente).
	## Todos los trazos van en un solo draw_multiline: una llamada de dibujo por línea en vez de una por trazo.
	var segs := PackedVector2Array()
	var pintar := true
	var restante := trazo_px
	for i in range(pts.size() - 1):
		var a := pts[i]
		var largo := a.distance_to(pts[i + 1])
		if largo < 0.001:
			continue
		var dir := (pts[i + 1] - a) / largo
		var pos := 0.0
		while pos < largo:
			var paso := minf(restante, largo - pos)
			if pintar:
				segs.append_array([a + dir * pos, a + dir * (pos + paso)])
			pos += paso
			restante -= paso
			if restante <= 0.0001:
				pintar = not pintar
				restante = trazo_px if pintar else hueco_px
	if not segs.is_empty():
		ci.draw_multiline(segs, color, ancho, true)


static func circulos(ci: CanvasItem, lista: Array) -> void:
	## Círculos rellenos [centro, radio, color] en un solo arreglo de triángulos (una llamada de dibujo), en el orden
	## de la lista: el que va después queda encima, igual que con draw_circle uno tras otro.
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for c in lista:
		var centro: Vector2 = c[0]
		var r: float = c[1]
		var col: Color = c[2]
		for k in range(LADOS):
			pts.append_array([centro, centro + _UNIDAD[k] * r, centro + _UNIDAD[(k + 1) % LADOS] * r])
			cols.append_array([col, col, col])
	if not pts.is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), PackedInt32Array(range(pts.size())), pts, cols)


const LADOS := 20
static var _UNIDAD: PackedVector2Array = _unidad()


static func _unidad() -> PackedVector2Array:
	var u := PackedVector2Array()
	for k in range(LADOS):
		u.append(Vector2.from_angle(TAU * float(k) / float(LADOS)))
	return u


static func mas_cercano(p: Vector2, pts: PackedVector2Array) -> Vector2:
	var mejor := Vector2.INF
	var d_mejor := INF
	for i in range(pts.size() - 1):
		var q := Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1])
		var d := q.distance_to(p)
		if d < d_mejor:
			d_mejor = d
			mejor = q
	return mejor
