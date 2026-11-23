class_name MapaChile
extends Control
## Mapa nacional: regiones reales coloreadas por aprobación, mar y marcadores de obras.

signal region_tocada(id: String)

var estirar_x: float = 2.3  # licencia gráfica: Chile es muy angosto para una pantalla vertical

var _piezas: Dictionary = {}  # id -> Array[PackedVector2Array] normalizadas (contornos)
var _mallas: Dictionary = {}  # id -> ArrayMesh pretriangulada
var _banda_y: Dictionary = {}  # id -> Vector2(y_min, y_max)
var _ancho_rel: float = 0.2
var valores: Dictionary = {}
var seleccion: String = ""
var obras: Dictionary = {}  # id -> cantidad de obras en curso
var bastion: String = ""
var _ciudades: Array = []
var _este: PackedVector2Array = PackedVector2Array()  # borde oriental (Cordillera) por franjas de latitud
var propuestas: Dictionary = {}
var _decor: Control
var animar: bool = true
var _relieve: Texture2D
var x_centro_rel: float = 0.5
var leyenda: bool = true
var ciudades_visibles: bool = true


func cargar_geo(geo: Dictionary) -> void:
	_ancho_rel = float(geo["ancho_rel"])
	_ciudades = geo.get("ciudades", [])
	if ResourceLoader.exists("res://data/geo/relieve.png"):
		_relieve = load("res://data/geo/relieve.png")
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
			var uvs := PackedVector2Array()
			for v in vertices:
				v3.append(Vector3(v.x, v.y, 0.0))
				uvs.append(Vector2(v.x / _ancho_rel, v.y))
			arrays[Mesh.ARRAY_TEX_UV] = uvs
			arrays[Mesh.ARRAY_VERTEX] = v3
			arrays[Mesh.ARRAY_INDEX] = indices
			var malla := ArrayMesh.new()
			malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			_mallas[id] = malla
		_banda_y[id] = Vector2(y0, y1)
	_calcular_borde_este()
	if animar and _decor == null:
		_decor = MapaDecor.new()
		_decor.mapa = self
		_decor.set_anchors_preset(Control.PRESET_FULL_RECT)
		_decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_decor)
	queue_redraw()


func _calcular_borde_este() -> void:
	var bins := 110
	var xmax: Array[float] = []
	xmax.resize(bins)
	xmax.fill(-1.0)
	for id in _piezas.keys():
		for pieza in _piezas[id]:
			for p in pieza:
				var b := clampi(int(p.y * float(bins)), 0, bins - 1)
				xmax[b] = maxf(xmax[b], p.x)
	_este.clear()
	for b in range(bins):
		if xmax[b] >= 0.0:
			_este.append(Vector2(xmax[b], (float(b) + 0.5) / float(bins)))


func actualizar(p_valores: Dictionary, p_obras: Dictionary = {}, p_propuestas: Dictionary = {}) -> void:
	valores = p_valores
	obras = p_obras
	propuestas = p_propuestas
	queue_redraw()


func _transformar(p: Vector2) -> Vector2:
	var h := size.y - 16.0
	var ancho := _ancho_rel * h * estirar_x
	return Vector2(size.x * x_centro_rel - ancho * 0.5 + p.x * h * estirar_x, 8.0 + p.y * h)


func _draw() -> void:
	var fondo := PackedColorArray([Color("#0E2B45"), Color("#0E2B45"), Color("#0A1E31"), Color("#0A1E31")])
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]), fondo)
	for gx in range(0, int(size.x), 26):
		draw_line(Vector2(gx, 0), Vector2(gx, size.y), Color(1, 1, 1, 0.035), 1.0)
	for gy in range(0, int(size.y), 26):
		draw_line(Vector2(0, gy), Vector2(size.x, gy), Color(1, 1, 1, 0.035), 1.0)
	var fila := 0
	for gy in range(14, int(size.y), 20):
		for gx in range(int(fila % 2) * 15, int(size.x), 30):
			draw_arc(Vector2(gx, gy), 4.5, PI * 0.15, PI * 0.85, 6, Color(0.55, 0.78, 1.0, 0.10), 1.2)
		fila += 1
	for id in _piezas.keys():
		var col := Tema.color_aprobacion(float(valores.get(id, 50.0)))
		if id == seleccion:
			col = col.lightened(0.18)
		if _mallas.has(id):
			var h := size.y - 16.0
			draw_set_transform(_transformar(Vector2.ZERO) + Vector2(5.0, 6.0), 0.0, Vector2(h * estirar_x, h))
			draw_mesh(_mallas[id], null, Transform2D.IDENTITY, Color(0, 0, 0, 0.38))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var origen := _transformar(Vector2.ZERO)
			draw_set_transform(origen, 0.0, Vector2(h * estirar_x, h))
			draw_mesh(_mallas[id], null, Transform2D.IDENTITY, col)
			if _relieve != null:
				draw_mesh(_mallas[id], _relieve, Transform2D.IDENTITY, Color(1, 1, 1, 0.7))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for pieza in _piezas[id]:
			var pts := PackedVector2Array()
			for p in pieza:
				pts.append(_transformar(p))
			var borde := Tema.ORO if id == seleccion else Color(1, 0.97, 0.9, 0.5)
			pts.append(pts[0])
			draw_polyline(pts, borde, 2.5 if id == seleccion else 0.9, true)
	for i in range(0, _este.size(), 2):
		var q := _transformar(_este[i] + Vector2(0.004, 0.0))
		var h := 5.0 + float((i * 7) % 4)
		draw_colored_polygon(PackedVector2Array([q + Vector2(-5, h * 0.6), q + Vector2(0, -h), q + Vector2(5, h * 0.6)]), Color("#2F6288", 0.65))
		draw_colored_polygon(PackedVector2Array([q + Vector2(-2.2, -h * 0.35), q + Vector2(0, -h), q + Vector2(2.2, -h * 0.35)]), Color(1, 1, 1, 0.55))
		var q2 := q + Vector2(9.0, 7.0)
		draw_colored_polygon(PackedVector2Array([q2 + Vector2(-3.5, 3), q2 + Vector2(0, -3.5), q2 + Vector2(3.5, 3)]), Color("#2F6288", 0.35))
	var fuente := Tema.fuente_texto(600)
	for c in (_ciudades if ciudades_visibles else []):
		if c["nombre"] == "Santiago":
			continue
		var pc := _transformar(Vector2(float(c["x"]), float(c["y"])))
		draw_circle(pc, 3.6, Tema.CREMA)
		draw_circle(pc, 2.0, Tema.OCEANO)
		var nombre := String(c["nombre"])
		var ancho_txt := fuente.get_string_size(nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(fuente, Vector2(pc.x - 8.0 - ancho_txt, pc.y + 3.5), nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TEXTO)
	if leyenda:
		var r := Rect2(size.x - 178.0, size.y - 34.0, 168.0, 26.0)
		draw_style_box(Tema.caja(Color(0.04, 0.13, 0.21, 0.85), 10), r)
		draw_string(Tema.fuente_texto(500), r.position + Vector2(8, 17), "Aprobación", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TEXTO_SUAVE)
		for k in range(60):
			draw_rect(Rect2(r.position.x + 74.0 + float(k) * 1.4, r.position.y + 9.0, 1.6, 8.0), Tema.color_aprobacion(30.0 + float(k) / 59.0 * 30.0))
	for id in obras.keys():
		if int(obras[id]) > 0 and _banda_y.has(id):
			var c := centro(id) + Vector2(10.0, 0.0)
			draw_circle(c, 11.0, Tema.OCEANO)
			draw_circle(c, 9.5, Tema.ORO)
			draw_string(Tema.fuente_titulo(), c + Vector2(-9.5, 4.5), str(int(obras[id])), HORIZONTAL_ALIGNMENT_CENTER, 19.0, 13, Tema.TINTA)
	for id in propuestas.keys():
		if bool(propuestas[id]) and _banda_y.has(id):
			var c2 := centro(id) + Vector2(-12.0, -2.0)
			draw_circle(c2, 11.0, Tema.CREMA)
			draw_circle(c2, 9.5, Tema.ROJO)
			draw_colored_polygon(PackedVector2Array([c2 + Vector2(-5, 1), c2 + Vector2(0, -5), c2 + Vector2(5, 1)]), Tema.TEXTO)
			draw_rect(Rect2(c2 + Vector2(-3.5, 1), Vector2(7, 5)), Tema.TEXTO)
	if bastion != "" and _banda_y.has(bastion):
		pass


func centro(id: String) -> Vector2:
	## Centroide aproximado (en píxeles del control) de la pieza más grande de la región.
	var mejor: PackedVector2Array = PackedVector2Array()
	for pieza in _piezas.get(id, []):
		if pieza.size() > mejor.size():
			mejor = pieza
	if mejor.is_empty():
		return Vector2.ZERO
	var acc := Vector2.ZERO
	for p in mejor:
		acc += p
	return _transformar(acc / float(mejor.size()))


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
