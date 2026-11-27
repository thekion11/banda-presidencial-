class_name MapaGeometria
extends RefCounted
## Geometría del mapa de Chile que se calcula una vez al cargar (separada de MapaChile para no acercarse al tope de 450 líneas).


static func triangular(geo: Dictionary, ancho_rel: float) -> Dictionary:
	## Contornos limpios, mallas pretrianguladas y banda de latitud de cada región: {piezas, mallas, banda_y}.
	var piezas := {}
	var mallas := {}
	var banda_y := {}
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
		piezas[id] = lista
		if not indices.is_empty():
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			var v3 := PackedVector3Array()
			var uvs := PackedVector2Array()
			for v in vertices:
				v3.append(Vector3(v.x, v.y, 0.0))
				uvs.append(Vector2(v.x / ancho_rel, v.y))
			arrays[Mesh.ARRAY_TEX_UV] = uvs
			arrays[Mesh.ARRAY_VERTEX] = v3
			arrays[Mesh.ARRAY_INDEX] = indices
			var malla := ArrayMesh.new()
			malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			mallas[id] = malla
		banda_y[id] = Vector2(y0, y1)
	return {"piezas": piezas, "mallas": mallas, "banda_y": banda_y}


static func borde_este(piezas: Dictionary) -> PackedVector2Array:
	## Borde oriental (Cordillera) por franjas de latitud: el máximo x de cada franja.
	var bins := 110
	var xmax: Array[float] = []
	xmax.resize(bins)
	xmax.fill(-1.0)
	for id in piezas.keys():
		for pieza in piezas[id]:
			for p in pieza:
				var b := clampi(int(p.y * float(bins)), 0, bins - 1)
				xmax[b] = maxf(xmax[b], p.x)
	var este := PackedVector2Array()
	for b in range(bins):
		if xmax[b] >= 0.0:
			este.append(Vector2(xmax[b], (float(b) + 0.5) / float(bins)))
	return este


static func region_en(banda_y: Dictionary, yn: float) -> String:
	## Región cuya franja de latitud contiene `yn` (0 arriba, 1 abajo); si ninguna, la más cercana (y la más angosta al empatar).
	var mejor := ""
	var mejor_d := 9.0
	for id in banda_y.keys():
		var b: Vector2 = banda_y[id]
		var d := 0.0 if yn >= b.x and yn <= b.y else minf(absf(yn - b.x), absf(yn - b.y))
		if d < mejor_d or (d == mejor_d and (b.y - b.x) < (banda_y[mejor].y - banda_y[mejor].x)):
			mejor_d = d
			mejor = id
	return mejor
