class_name UrbanoEsquema
extends RefCounted
## Vista esquemática del Metro (plano de líneas): las estaciones conservan su posición relativa, pero el centro se «abre» (lente de
## pescado) para que se lea, y cada tramo entre estaciones se dibuja en 0°, 45° o 90°. Incluye las líneas del jugador con los nombres
## que les puso. Solo cambia la presentación: los datos y las posiciones reales no se tocan.

const GAMMA := 0.58  # <1 abre el centro y junta la periferia (0,5 y relajación de distancias se probaron: deforman más las líneas)
const M_ANCHO := 26003.0
const M_ALTO := 21128.0

static var _clave: String = ""
static var _cache: Dictionary = {}


static func _octilineal(a: Vector2, b: Vector2) -> PackedVector2Array:
	## Camino de a a b con tramos horizontales, verticales o a 45°: primero la diagonal y luego el tramo recto.
	var d := b - a
	var ax := absf(d.x)
	var ay := absf(d.y)
	if ax < 0.5 or ay < 0.5 or absf(ax - ay) < 0.5:
		return PackedVector2Array([a, b])
	var diag := minf(ax, ay)
	var codo := a + Vector2(signf(d.x), signf(d.y)) * diag
	return PackedVector2Array([a, codo, b])


static func preparar(tam: Vector2, margen: Vector2, propias: Array) -> Dictionary:
	var clave := "%d,%d,%d,%d,%d,%s" % [int(tam.x), int(tam.y), int(margen.x), int(margen.y), propias.size(), UrbanoBase.fecha_iso]
	for ln in propias:
		clave += "|%s%d" % [ln["id"], (ln["estaciones"] as Array).size()]
	if clave == _clave:
		return _cache
	var d := UrbanoBase.datos()
	var pos := {}
	for e in d["estaciones"]:
		pos[String(e["n"])] = Vector2(float(e["p"][0]), float(e["p"][1]))
	var centro := Vector2.ZERO
	for p in pos.values():
		centro += p
	centro /= float(maxi(1, pos.size()))
	var rmax := 1.0
	for p in pos.values():
		rmax = maxf(rmax, ((p - centro) * Vector2(M_ANCHO, M_ALTO)).length())
	var lente := func(p: Vector2) -> Vector2:
		var m: Vector2 = (p - centro) * Vector2(M_ANCHO, M_ALTO)
		var r := m.length()
		return Vector2.ZERO if r < 1.0 else m / r * rmax * pow(r / rmax, GAMMA)
	# ajuste a la vista (escala isótropa) con las estaciones reales
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for p in pos.values():
		var q: Vector2 = lente.call(p)
		mn = mn.min(q)
		mx = mx.max(q)
	var caja := tam - margen * 2.0 - Vector2(70, 30)  # espacio para los nombres a los lados
	var esc := minf(caja.x / (mx.x - mn.x), caja.y / (mx.y - mn.y))
	var origen := margen + Vector2(35, 15) + (caja - (mx - mn) * esc) * 0.5
	var a_px := func(p: Vector2) -> Vector2:
		var q: Vector2 = lente.call(p)
		return origen + (q - mn) * esc
	var en_px := {}
	for n in pos:
		en_px[n] = a_px.call(pos[n])
	_relajar(en_px, 0.0, 0)  # sin relajación: separar las estaciones a la fuerza deformaba las líneas (probado con 17 px)
	var lineas: Array = []
	for l in d["metro"]:
		var pts: Array = []
		var nombres: Array = []
		for n in l["orden"]:
			pts.append(en_px[String(n)])
			nombres.append(String(n))
		lineas.append(_linea(String(l["id"]), Color(String(l["color"])), pts, nombres, l.get("cabos", []), UrbanoBase.abierta(l)))
	for ln in propias:
		var pts2: Array = []
		for q in ln["estaciones"]:
			pts2.append(a_px.call(Vector2(float(q[0]), float(q[1]))))
		lineas.append(_linea(String(ln["id"]), UrbanoBase.COLOR_PROPIA, pts2, ln.get("nombres_estaciones", []), [], String(ln["estado"]) == "operativa"))
	var rio := PackedVector2Array()
	for pl in d["rio"]:
		var rp := PackedVector2Array()
		for q in pl:
			rp.append(a_px.call(Vector2(float(q[0]), float(q[1]))))
		rio.append_array(UrbanoTrazo.redondear(rp, 6.0))
		rio.append(Vector2.INF)  # separador entre tramos del río
	_cache = {"lineas": lineas, "rio": rio, "combinaciones": _combinaciones(lineas)}
	_clave = clave
	return _cache


static func _relajar(pos: Dictionary, dmin: float, iteraciones: int) -> void:
	## Cada pareja de estaciones a menos de `dmin` px se aleja a partes iguales: conserva la forma general y evita montones.
	var claves := pos.keys()
	for _it in range(iteraciones):
		var movido := false
		for i in range(claves.size()):
			for j in range(i + 1, claves.size()):
				var a: Vector2 = pos[claves[i]]
				var b: Vector2 = pos[claves[j]]
				var d := b - a
				var l := d.length()
				if l < dmin:
					var u := d / l if l > 0.01 else Vector2(1, 0)
					var m := u * (dmin - l) * 0.5
					pos[claves[i]] = a - m
					pos[claves[j]] = b + m
					movido = true
		if not movido:
			break


static func _linea(id: String, color: Color, pts: Array, nombres: Array, cabos: Array, operativa: bool = true) -> Dictionary:
	var ruta := PackedVector2Array()
	for i in range(pts.size()):
		if i == 0:
			ruta.append(pts[0])
		else:
			var tramo := _octilineal(pts[i - 1], pts[i])
			for k in range(1, tramo.size()):
				ruta.append(tramo[k])
	return {"id": id, "color": color, "estaciones": PackedVector2Array(pts), "nombres": nombres, "ruta": UrbanoTrazo.redondear(ruta, 12.0, 4),
			"sigue": [bool(cabos[0]["sigue"]), bool(cabos[1]["sigue"])] if cabos.size() == 2 else [false, false], "operativa": operativa}


static func _combinaciones(lineas: Array) -> Dictionary:
	var veces := {}
	for l in lineas:
		for i in range(l["estaciones"].size()):
			var clave := Vector2i((l["estaciones"][i] as Vector2).round())
			veces[clave] = int(veces.get(clave, 0)) + 1
	return veces


static func dibujar(ci: CanvasItem, tam: Vector2, margen: Vector2, zoom: float, pan: Vector2, propias: Array, detalle: bool = true) -> void:
	var c := preparar(tam, margen, propias)
	var esc := (1.0 + 0.35 * (zoom - 1.0)) / zoom
	ci.draw_set_transform(pan, 0.0, Vector2(zoom, zoom))
	var rio: PackedVector2Array = c["rio"]
	var tramo := PackedVector2Array()
	for p in rio:
		if p == Vector2.INF:
			if tramo.size() > 1:
				ci.draw_polyline(tramo, Color("#CFE3EE"), 7.0 * esc, true)
			tramo = PackedVector2Array()
		else:
			tramo.append(p)
	for l in c["lineas"]:
		if UrbanoBase.ocultas.has(l["id"]):
			continue
		UrbanoTrazo.trazo(ci, l["ruta"], Color(1, 1, 1, 0.95), 9.0 * esc)
	for l in c["lineas"]:
		if UrbanoBase.ocultas.has(l["id"]):
			continue
		if l["operativa"]:
			UrbanoTrazo.trazo(ci, l["ruta"], l["color"], 6.0 * esc)
		else:
			UrbanoTrazo.discontinua(ci, l["ruta"], l["color"], 6.0 * esc, 12.0 * esc, 8.0 * esc)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_rotulos(ci, c, tam, zoom, pan, detalle)


static func _rotulos(ci: CanvasItem, c: Dictionary, tam: Vector2, zoom: float, pan: Vector2, detalle: bool) -> void:
	var f := Tema.fuente_texto(700)
	var ocupados: Array[Rect2] = []
	var vistos := {}
	var cola: Array = []  # [prioridad, posición pantalla, nombre, es_combinacion, color]
	for l in c["lineas"]:
		if UrbanoBase.ocultas.has(l["id"]):
			continue
		var est: PackedVector2Array = l["estaciones"]
		for i in range(est.size()):
			var p: Vector2 = est[i] * zoom + pan
			var comb: bool = int(c["combinaciones"].get(Vector2i(est[i].round()), 1)) > 1
			var base_ok := p.x >= -4.0 and p.y >= -4.0 and p.x <= tam.x + 4.0 and p.y <= tam.y + 4.0
			if not base_ok:
				continue
			var nombre := String(l["nombres"][i]) if i < l["nombres"].size() else ""
			cola.append([0 if comb else 1, p, nombre, comb, l["color"], i == 0 or i == est.size() - 1, l["id"]])
	cola.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	for k in cola:
		var p: Vector2 = k[1]
		var nombre: String = k[2]
		# marca de estación
		if bool(k[3]):
			ci.draw_circle(p, 6.2, Tema.TINTA)
			ci.draw_circle(p, 4.4, Color.WHITE)
		else:
			ci.draw_circle(p, 4.0, Color.WHITE)
			ci.draw_circle(p, 2.6, k[4])
		if nombre == "" or (not detalle and not bool(k[3])):
			continue
		if zoom < 1.8 and not bool(k[3]) and not bool(k[5]):
			continue  # sin zoom solo se rotulan combinaciones y terminales; con zoom, todas las estaciones
		if vistos.has(nombre) and zoom < 2.5:
			continue
		var ancho := f.get_string_size(nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		for desp in [Vector2(8, 0), Vector2(-8 - ancho, 0), Vector2(-ancho * 0.5, -14), Vector2(-ancho * 0.5, 15), Vector2(8, -12), Vector2(8, 12), Vector2(-8 - ancho, -12), Vector2(-8 - ancho, 12)]:
			var caja := Rect2(p.x + desp.x - 2.0, p.y + desp.y - 8.0, ancho + 4.0, 14.0)
			if caja.position.x < 1.0 or caja.end.x > tam.x - 1.0 or caja.position.y < 1.0 or caja.end.y > tam.y - 1.0:
				continue
			var choca := false
			for r in ocupados:
				if r.intersects(caja):
					choca = true
					break
			if choca:
				continue
			ocupados.append(caja)
			vistos[nombre] = true
			var o := Vector2(p.x + desp.x, p.y + desp.y + 3.5)
			ci.draw_rect(caja, Color(0.98, 0.97, 0.93, 0.82))  # fondo suave: el nombre se lee aunque pase una línea por detrás
			ci.draw_string_outline(f, o, nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color(0.98, 0.97, 0.93, 0.9))
			ci.draw_string(f, o, nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TINTA)
			break
	# fichas con el número de la línea en los terminales y flechas donde la línea sigue fuera del mapa
	var fb := Tema.fuente_titulo()
	for l in c["lineas"]:
		if UrbanoBase.ocultas.has(l["id"]):
			continue
		var est2: PackedVector2Array = l["estaciones"]
		if est2.size() < 2:
			continue
		var tinta: Color = UrbanoBase.tinta_sobre(String(l["id"]))
		for fin in range(2):
			var p2: Vector2 = (est2[0] if fin == 0 else est2[est2.size() - 1]) * zoom + pan
			if p2.x < -12.0 or p2.y < -12.0 or p2.x > tam.x + 12.0 or p2.y > tam.y + 12.0:
				continue
			if l["sigue"][fin]:
				var vecina: Vector2 = (est2[1] if fin == 0 else est2[est2.size() - 2]) * zoom + pan
				var d := (p2 - vecina).normalized()
				var n := Vector2(-d.y, d.x)
				var pt := p2 + d * 16.0
				ci.draw_colored_polygon(PackedVector2Array([pt + d * 8.0, pt + n * 6.0, pt - n * 6.0]), Color(1, 1, 1, 0.9))
				ci.draw_colored_polygon(PackedVector2Array([pt + d * 6.0, pt + n * 4.2, pt - n * 4.2]), l["color"])
			else:
				ci.draw_circle(p2, 10.0, Color.WHITE)
				ci.draw_circle(p2, 8.4, l["color"])
				ci.draw_string(fb, p2 + Vector2(-8, 4.2), UrbanoBase.nombre_corto(String(l["id"])), HORIZONTAL_ALIGNMENT_CENTER, 16.0, 10, tinta)


static func linea_en(pos_local: Vector2, tam: Vector2, margen: Vector2, propias: Array, umbral: float = 14.0) -> String:
	var c := preparar(tam, margen, propias)
	var mejor := umbral
	var res := ""
	for l in c["lineas"]:
		if UrbanoBase.ocultas.has(l["id"]):
			continue
		var r: PackedVector2Array = l["ruta"]
		for i in range(r.size() - 1):
			var q := Geometry2D.get_closest_point_to_segment(pos_local, r[i], r[i + 1])
			if q.distance_to(pos_local) < mejor:
				mejor = q.distance_to(pos_local)
				res = String(l["id"])
	return res


static func estacion_en(pos_local: Vector2, tam: Vector2, margen: Vector2, propias: Array, umbral: float = 12.0) -> Dictionary:
	## Estación visible más cercana al toque: {"n": nombre, "l": [líneas que la sirven], "p": posición} o {} si no hay ninguna cerca.
	var c := preparar(tam, margen, propias)
	var mejor := umbral
	var res: Dictionary = {}
	for l in c["lineas"]:
		if UrbanoBase.ocultas.has(l["id"]):
			continue
		var est: PackedVector2Array = l["estaciones"]
		for i in range(est.size()):
			var dd := est[i].distance_to(pos_local)
			if dd < mejor:
				mejor = dd
				res = {"n": String(l["nombres"][i]) if i < l["nombres"].size() else "", "l": [l["id"]], "p": est[i]}
	if res.is_empty():
		return res
	for l in c["lineas"]:  # añade las demás líneas visibles que pasan por la misma posición (combinaciones)
		if UrbanoBase.ocultas.has(l["id"]) or res["l"].has(l["id"]):
			continue
		for q in l["estaciones"]:
			if (q as Vector2).distance_to(res["p"]) < 1.0:
				res["l"].append(l["id"])
				break
	return res
