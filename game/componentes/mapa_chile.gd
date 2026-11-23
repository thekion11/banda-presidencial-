class_name MapaChile
extends Control
## Mapa nacional: regiones reales coloreadas por aprobación, mar y marcadores de obras.

signal region_tocada(id: String)

const ESTIRAR_X := 2.0  # licencia gráfica: Chile es muy angosto para una pantalla vertical

var _piezas: Dictionary = {}  # id -> Array[PackedVector2Array] normalizadas (contornos)
var _mallas: Dictionary = {}  # id -> ArrayMesh pretriangulada
var _banda_y: Dictionary = {}  # id -> Vector2(y_min, y_max)
var _ancho_rel: float = 0.2
var valores: Dictionary = {}
var seleccion: String = ""
var obras: Dictionary = {}  # id -> cantidad de obras en curso
var bastion: String = ""


func cargar_geo(geo: Dictionary) -> void:
	_ancho_rel = float(geo["ancho_rel"])
	for id in geo["regiones"].keys():
		var lista: Array[PackedVector2Array] = []
		var vertices := PackedVector2Array()
		var indices := PackedInt32Array()
		var y0 := 9.0
		var y1 := -9.0
		for poly in geo["regiones"][id]:
			var pv := PackedVector2Array()
			for p in poly:
				pv.append(Vector2(float(p[0]), float(p[1])))
				y0 = minf(y0, float(p[1]))
				y1 = maxf(y1, float(p[1]))
			for limpio in Geometry2D.offset_polygon(pv, 0.0):
				var tri := Geometry2D.triangulate_polygon(limpio)
				lista.append(limpio)
				if tri.is_empty():
					continue
				var base := vertices.size()
				vertices.append_array(limpio)
				for t in tri:
					indices.append(base + t)
		_piezas[id] = lista
		if not indices.is_empty():
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			var v3 := PackedVector3Array()
			for v in vertices:
				v3.append(Vector3(v.x, v.y, 0.0))
			arrays[Mesh.ARRAY_VERTEX] = v3
			arrays[Mesh.ARRAY_INDEX] = indices
			var malla := ArrayMesh.new()
			malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			_mallas[id] = malla
		_banda_y[id] = Vector2(y0, y1)
	queue_redraw()


func actualizar(p_valores: Dictionary, p_obras: Dictionary = {}) -> void:
	valores = p_valores
	obras = p_obras
	queue_redraw()


func _transformar(p: Vector2) -> Vector2:
	var h := size.y - 16.0
	var ancho := _ancho_rel * h * ESTIRAR_X
	return Vector2(8.0 + (size.x - ancho) * 0.5 + p.x * h * ESTIRAR_X, 8.0 + p.y * h)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Tema.OCEANO)
	for id in _piezas.keys():
		var col := Tema.color_aprobacion(float(valores.get(id, 50.0)))
		if id == seleccion:
			col = col.lightened(0.18)
		if _mallas.has(id):
			var h := size.y - 16.0
			var origen := _transformar(Vector2.ZERO)
			draw_set_transform(origen, 0.0, Vector2(h * ESTIRAR_X, h))
			draw_mesh(_mallas[id], null, Transform2D.IDENTITY, col)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for pieza in _piezas[id]:
			var pts := PackedVector2Array()
			for p in pieza:
				pts.append(_transformar(p))
			var borde := Tema.ORO if id == seleccion else Color(0.04, 0.13, 0.21, 0.9)
			pts.append(pts[0])
			draw_polyline(pts, borde, 2.0 if id == seleccion else 1.0, true)
	for id in obras.keys():
		if int(obras[id]) > 0 and _banda_y.has(id):
			var c := _transformar(Vector2(_ancho_rel * 0.5, (_banda_y[id].x + _banda_y[id].y) * 0.5))
			draw_circle(c, 7.0, Tema.OCEANO)
			draw_circle(c, 5.0, Tema.ORO)
	if bastion != "" and _banda_y.has(bastion):
		var cb := _transformar(Vector2(_ancho_rel * 0.5, (_banda_y[bastion].x + _banda_y[bastion].y) * 0.5))
		draw_arc(cb, 10.0, 0.0, TAU, 20, Tema.CREMA, 1.5)


func _gui_input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pos = event.position
	else:
		return
	var yn := (pos.y - 8.0) / maxf(1.0, size.y - 16.0)
	var mejor := ""
	var mejor_d := 9.0
	for id in _banda_y.keys():
		var b: Vector2 = _banda_y[id]
		var d := 0.0 if yn >= b.x and yn <= b.y else minf(absf(yn - b.x), absf(yn - b.y))
		if d < mejor_d or (d == mejor_d and (b.y - b.x) < (_banda_y[mejor].y - _banda_y[mejor].x)):
			mejor_d = d
			mejor = id
	if mejor != "":
		seleccion = mejor
		queue_redraw()
		region_tocada.emit(mejor)
