class_name UrbanoBase
extends RefCounted
## Cartografía real de Gran Santiago (© colaboradores de OpenStreetMap, ODbL) lista para dibujar:
## calles por jerarquía, río, parques, líneas y estaciones de Metro. Se prepara una vez por tamaño y se dibuja con pocas llamadas.

const COLORES_CALLE: Array[Color] = [Color("#B9AE95"), Color("#B9AE95"), Color("#C9BFA8"), Color("#D6CDB8"), Color("#E0D9C8")]
const ANCHOS_CALLE: Array[float] = [3.2, 3.0, 2.3, 1.5, 0.9]

static var _relieve: Texture2D
static var _edif: PackedByteArray = PackedByteArray()
static var _elev: PackedByteArray = PackedByteArray()
static var _datos: Dictionary = {}
static var _cache_clave: String = ""
static var _cache: Dictionary = {}
const COLOR_PROPIA := Color("#D6336C")  # líneas creadas por el jugador (P1, P2…): distinto de todas las reales
static var propias: Array = []  # estado.lineas_jugador de la partida abierta (las pantallas lo asignan antes de dibujar)
static var ocultas: Dictionary = {}  # ids de líneas de Metro ocultas (se comparte entre los mapas de la partida)


static func datos() -> Dictionary:
	if _datos.is_empty():
		var d: Variant = Datos.leer_json("res://data/geo/urbano_real.json")
		_datos = d if d != null else {}
	return _datos


static func edificios_total() -> int:
	if _edif.is_empty():
		_edif = FileAccess.get_file_as_bytes("res://data/geo/edificios_santiago.bin")
	return _edif.decode_u32(0) if _edif.size() >= 4 else 0


static func edificios_en(ventana: Rect2, maximo: int) -> Array:
	## Edificios reales (OSM) dentro de una ventana del plano. Devuelve [{x, y, w, d, ang, pisos}] (x,y en 0..1; w,d en metros).
	var n := edificios_total()
	var res: Array = []
	var paso := 1
	var cuenta := 0
	for i in range(n):  # primera pasada: contar para decidir el submuestreo determinista
		var o := 4 + 8 * i
		var x := float(_edif.decode_u16(o)) / 65535.0
		var y := float(_edif.decode_u16(o + 2)) / 65535.0
		if ventana.has_point(Vector2(x, y)):
			cuenta += 1
	if cuenta > maximo:
		paso = int(ceil(float(cuenta) / float(maximo)))
	var k := 0
	for i in range(n):
		var o := 4 + 8 * i
		var x := float(_edif.decode_u16(o)) / 65535.0
		var y := float(_edif.decode_u16(o + 2)) / 65535.0
		if not ventana.has_point(Vector2(x, y)):
			continue
		k += 1
		var pisos := _edif.decode_u8(o + 7)
		if paso > 1 and k % paso != 0 and pisos < 8:
			continue  # el submuestreo conserva los edificios altos
		res.append({"x": x, "y": y, "w": _edif.decode_u8(o + 4), "d": _edif.decode_u8(o + 5), "ang": _edif.decode_u8(o + 6), "pisos": pisos})
	return res


static func elevacion_m(px: float, py: float) -> float:
	## Elevación real (m) con interpolación bilineal sobre la malla de 128×104.
	if _elev.is_empty():
		_elev = FileAccess.get_file_as_bytes("res://data/geo/elevacion_santiago.bin")
	if _elev.size() < 4:
		return 0.0
	var w := (_elev[0] << 8) | _elev[1]
	var h := (_elev[2] << 8) | _elev[3]
	var fx := clampf(px, 0.0, 1.0) * float(w - 1)
	var fy := clampf(py, 0.0, 1.0) * float(h - 1)
	var x0 := int(fx)
	var y0 := int(fy)
	var x1 := mini(x0 + 1, w - 1)
	var y1 := mini(y0 + 1, h - 1)
	var g := func(x: int, y: int) -> float:
		var o := 4 + 2 * (y * w + x)
		return float((_elev[o] << 8) | _elev[o + 1])
	var tx := fx - float(x0)
	var ty := fy - float(y0)
	return lerpf(lerpf(g.call(x0, y0), g.call(x1, y0), tx), lerpf(g.call(x0, y1), g.call(x1, y1), tx), ty)


static func relieve() -> Texture2D:
	if _relieve == null and ResourceLoader.exists("res://data/geo/relieve_santiago.png"):
		_relieve = load("res://data/geo/relieve_santiago.png")
	return _relieve


static func aspecto() -> float:
	return float(datos().get("aspecto", 1.2))


static func a_px(p: Array, tam: Vector2, margen: Vector2) -> Vector2:
	return Vector2(margen.x + float(p[0]) * (tam.x - 2.0 * margen.x), margen.y + float(p[1]) * (tam.y - 2.0 * margen.y))


static func _segmentos(lista: Array, tam: Vector2, margen: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for pl in lista:
		for i in range(pl.size() - 1):
			out.append(a_px(pl[i], tam, margen))
			out.append(a_px(pl[i + 1], tam, margen))
	return out


static func preparar(tam: Vector2, margen: Vector2) -> Dictionary:
	var clave := "%d,%d,%d,%d" % [int(tam.x), int(tam.y), int(margen.x), int(margen.y)]
	if clave == _cache_clave:
		return _cache
	var d := datos()
	var c: Dictionary = {"calles": [], "metro": [], "rio": PackedVector2Array(), "parques": [], "estaciones": PackedVector2Array(), "est_lineas": []}
	if d.is_empty():
		return c
	var por_clase: Array = [[], [], [], [], []]
	for k in d["calles"]:
		por_clase[int(k["c"])].append(k["p"])
	for cl in range(5):
		c["calles"].append(_segmentos(por_clase[cl], tam, margen))
	c["rio"] = _segmentos(d["rio"], tam, margen)
	for l in d["metro"]:
		var cabos: Array = []
		for cb in l.get("cabos", []):
			cabos.append({"p": a_px(cb["p"], tam, margen), "d": Vector2(float(cb["d"][0]), float(cb["d"][1])), "sigue": bool(cb["sigue"])})
		c["metro"].append({"id": String(l["id"]), "color": Color(String(l["color"])), "seg": _segmentos(l["vias"], tam, margen), "cabos": cabos})
	for pk in d["parques"]:
		var poly := PackedVector2Array()
		for p in pk:
			poly.append(a_px(p, tam, margen))
		var tri := Geometry2D.triangulate_polygon(poly)
		if not tri.is_empty():
			c["parques"].append({"poly": poly, "tri": tri})
	c["est_lineas"] = []
	c["est_nombres"] = []
	for e in d["estaciones"]:
		c["estaciones"].append(a_px(e["p"], tam, margen))
		c["est_lineas"].append(e.get("l", []))
		c["est_nombres"].append(String(e["n"]))
	c["_tam"] = tam
	c["_margen"] = margen
	_cache_clave = clave
	_cache = c
	return c


static func dibujar(ci: CanvasItem, tam: Vector2, margen: Vector2 = Vector2(8, 8), con_metro: bool = true, escala_linea: float = 1.0, suave: float = 0.0) -> void:
	## `suave` (0..1) atenúa el mapa base (relieve, calles, parques) para que el Metro y la propuesta destaquen.
	var c := preparar(tam, margen)
	if c["calles"].is_empty():
		return
	var fondo := Color("#EFEADF")
	var limpio := suave >= 0.99  # modo "Metro": sin relieve (su imagen es de baja resolución) y solo avenidas principales, muy tenues
	var rel := relieve()
	if rel != null and not limpio:
		ci.draw_texture_rect(rel, Rect2(margen, tam - margen * 2.0), false, Color(1, 1, 1, lerpf(0.75, 0.32, suave)))
	for pk in c["parques"]:
		var poly: PackedVector2Array = pk["poly"]
		var tri: PackedInt32Array = pk["tri"]
		for i in range(0, tri.size(), 3):
			ci.draw_colored_polygon(PackedVector2Array([poly[tri[i]], poly[tri[i + 1]], poly[tri[i + 2]]]), Color("#C4DDB8").lerp(fondo, suave * 0.5))
	if c["rio"].size() > 1:
		ci.draw_multiline(c["rio"], Color("#A9CFE4").lerp(fondo, suave * 0.4), 5.0 * escala_linea, true)
	for cl in [4, 3, 2, 1, 0]:
		if limpio and cl > 2:
			continue
		if c["calles"][cl].size() > 1:
			ci.draw_multiline(c["calles"][cl], COLORES_CALLE[cl].lerp(fondo, suave * (0.62 if limpio else 0.6)), ANCHOS_CALLE[cl] * escala_linea * (0.8 if limpio else 1.0), true)
	if con_metro:
		_dibujar_metro(ci, c, escala_linea)


static func etiquetas(ci: CanvasItem, tam: Vector2, margen: Vector2, zoom: float, pan: Vector2, reservados: Array[Rect2] = []) -> void:
	## Nombres en coordenadas de pantalla (tamaño fijo con cualquier zoom), sin pisarse ni salir del mapa.
	## Prioridad: combinaciones de Metro (desde zoom 1,5), lugares conocidos y, con mucho zoom, todas las estaciones.
	var c := preparar(tam, margen)
	var f := Tema.fuente_texto(700)
	var ocupados: Array[Rect2] = reservados.duplicate()
	var cand: Array = []  # [prioridad, posición local, texto, es_lugar]
	for i in range(c["estaciones"].size()):
		var lineas: Array = c["est_lineas"][i]
		var visibles := 0
		for lid in lineas:
			if not ocultas.has(lid):
				visibles += 1
		if visibles == 0:
			continue
		if lineas.size() > 1 and zoom >= 1.5:
			cand.append([0, c["estaciones"][i], c["est_nombres"][i], false])
		elif zoom >= 3.0:
			cand.append([2, c["estaciones"][i], c["est_nombres"][i], false])
	var nombres_est := {}
	for i in range(c["estaciones"].size()):
		nombres_est[String(c["est_nombres"][i])] = true
	for l in datos().get("lugares", []):
		if nombres_est.has(String(l["n"])) and zoom >= 1.5:
			continue  # ya se rotula como estación
		cand.append([1, a_px(l["p"], tam, margen), String(l["n"]).replace("Parque Metropolitano de Santiago", "Parque Metropolitano"), true])
	cand.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	for k in cand:
		var p: Vector2 = k[1] * zoom + pan
		if p.x < 0.0 or p.y < 0.0 or p.x > tam.x or p.y > tam.y:
			continue
		var txt: String = k[2]
		var ancho := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		var colocada := false
		for desp in [Vector2(7, 0), Vector2(-7 - ancho, 0), Vector2(-ancho * 0.5, -14), Vector2(-ancho * 0.5, 14)]:
			var caja := Rect2(p.x + desp.x - 2.0, p.y + desp.y - 8.0, ancho + 4.0, 14.0)
			if caja.position.x < 2.0 or caja.end.x > tam.x - 2.0 or caja.position.y < 2.0 or caja.end.y > tam.y - 2.0:
				continue
			var choca := false
			for r in ocupados:
				if r.intersects(caja):
					choca = true
					break
			if choca:
				continue
			ocupados.append(caja)
			if bool(k[3]):
				ci.draw_circle(p, 3.0, Tema.ROJO)
			var o := Vector2(p.x + desp.x, p.y + desp.y + 3.5)
			ci.draw_string_outline(f, o, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 4, Color(0.94, 0.92, 0.87, 0.95))
			ci.draw_string(f, o, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TINTA)
			colocada = true
			break
		if not colocada and bool(k[3]):
			ci.draw_circle(p, 2.5, Tema.ROJO)


static func nombre_corto(id: String) -> String:
	return id.trim_prefix("L")


static func alternar_linea(id: String) -> void:
	if ocultas.has(id):
		ocultas.erase(id)
	else:
		ocultas[id] = true


static func ids_lineas() -> Array:
	var res: Array = []
	for l in datos().get("metro", []):
		res.append({"id": String(l["id"]), "color": Color(String(l["color"]))})
	for ln in propias:
		res.append({"id": String(ln["id"]), "color": COLOR_PROPIA})
	return res


static func _propias_px(c: Dictionary) -> Array:
	var res: Array = []
	for ln in propias:
		if ocultas.has(ln["id"]):
			continue
		var pts := PackedVector2Array()
		for q in ln["trazado"]:
			pts.append(a_px(q, c["_tam"], c["_margen"]))
		var est := PackedVector2Array()
		for q in ln["estaciones"]:
			est.append(a_px(q, c["_tam"], c["_margen"]))
		res.append({"id": String(ln["id"]), "pts": pts, "est": est, "operativa": String(ln["estado"]) == "operativa"})
	return res


static func _dibujar_metro(ci: CanvasItem, c: Dictionary, esc: float) -> void:
	for l in c["metro"]:
		if ocultas.has(l["id"]) or l["seg"].size() < 2:
			continue
		ci.draw_multiline(l["seg"], Color(1, 1, 1, 0.92), 7.4 * esc, true)
	for l in c["metro"]:
		if ocultas.has(l["id"]) or l["seg"].size() < 2:
			continue
		ci.draw_multiline(l["seg"], l["color"], 4.6 * esc, true)
	for pl in _propias_px(c):
		var pts: PackedVector2Array = pl["pts"]
		if pts.size() < 2:
			continue
		ci.draw_polyline(pts, Color(1, 1, 1, 0.95), 8.0 * esc, true)
		if pl["operativa"]:
			ci.draw_polyline(pts, COLOR_PROPIA, 4.8 * esc, true)
		else:  # en construcción: trazo discontinuo
			for k in range(pts.size() - 1):
				ci.draw_dashed_line(pts[k], pts[k + 1], COLOR_PROPIA, 4.8 * esc, 9.0 * esc, true)
		for e in pl["est"]:
			ci.draw_circle(e, 4.4 * esc, COLOR_PROPIA)
			ci.draw_circle(e, 2.6 * esc, Color.WHITE)
	for i in range(c["estaciones"].size()):
		var lineas: Array = c["est_lineas"][i]
		var visibles := 0
		for lid in lineas:
			if not ocultas.has(lid):
				visibles += 1
		if not lineas.is_empty() and visibles == 0:
			continue
		var p: Vector2 = c["estaciones"][i]
		if lineas.size() > 1:  # combinación: círculo más grande con anillo oscuro
			ci.draw_circle(p, 5.4 * esc, Tema.TINTA)
			ci.draw_circle(p, 3.8 * esc, Color.WHITE)
		else:
			ci.draw_circle(p, 3.4 * esc, Tema.TINTA)
			ci.draw_circle(p, 2.2 * esc, Color.WHITE)


static func fichas(ci: CanvasItem, tam: Vector2, margen: Vector2, zoom: float, pan: Vector2) -> Array[Rect2]:
	## Fichas numeradas en los terminales y flechas donde la línea continúa fuera del mapa, en coordenadas de pantalla
	## (tamaño fijo con cualquier zoom). Devuelve los rectángulos ocupados para que las etiquetas no los pisen.
	var usados: Array[Rect2] = []
	var c := preparar(tam, margen)
	var f := Tema.fuente_titulo()
	for l in c["metro"]:
		if ocultas.has(l["id"]):
			continue
		var tinta: Color = Tema.TINTA if l["id"] == "L2" else Color.WHITE
		for cb in l["cabos"]:
			var p: Vector2 = Vector2(cb["p"]) * zoom + pan
			if p.x < -12.0 or p.y < -12.0 or p.x > tam.x + 12.0 or p.y > tam.y + 12.0:
				continue
			if cb["sigue"]:  # la línea continúa fuera de la ventana del mapa: flecha en el borde
				var d: Vector2 = cb["d"]
				var n := Vector2(-d.y, d.x)
				var pt := p + d * 16.0
				ci.draw_colored_polygon(PackedVector2Array([pt + d * 8.0, pt + n * 6.0, pt - n * 6.0]), Color(1, 1, 1, 0.9))
				ci.draw_colored_polygon(PackedVector2Array([pt + d * 6.0, pt + n * 4.2, pt - n * 4.2]), l["color"])
			else:  # terminal dentro del mapa: ficha con el número de la línea
				ci.draw_circle(p, 10.0, Color.WHITE)
				ci.draw_circle(p, 8.4, l["color"])
				ci.draw_string(f, p + Vector2(-8, 4.2), nombre_corto(l["id"]), HORIZONTAL_ALIGNMENT_CENTER, 16.0, 10, tinta)
				usados.append(Rect2(p - Vector2(11, 11), Vector2(22, 22)))
	for pl in _propias_px(c):
		var pts2: PackedVector2Array = pl["pts"]
		for q in ([pts2[0], pts2[pts2.size() - 1]] if pts2.size() >= 2 else []):
			var p2: Vector2 = q * zoom + pan
			if p2.x < -12.0 or p2.y < -12.0 or p2.x > tam.x + 12.0 or p2.y > tam.y + 12.0:
				continue
			ci.draw_circle(p2, 10.0, Color.WHITE)
			ci.draw_circle(p2, 8.4, COLOR_PROPIA)
			ci.draw_string(f, p2 + Vector2(-8, 4.2), String(pl["id"]), HORIZONTAL_ALIGNMENT_CENTER, 16.0, 10, Color.WHITE)
			usados.append(Rect2(p2 - Vector2(11, 11), Vector2(22, 22)))
	return usados


static func linea_en(pos: Vector2, tam: Vector2, margen: Vector2, umbral: float = 14.0) -> String:
	## Id de la línea visible de Metro más cercana al punto tocado (dentro del umbral en px) o "" si no hay.
	var c := preparar(tam, margen)
	var mejor := umbral
	var res := ""
	for pl in _propias_px(c):
		var pp: PackedVector2Array = pl["pts"]
		for i in range(pp.size() - 1):
			var qq := Geometry2D.get_closest_point_to_segment(pos, pp[i], pp[i + 1])
			if qq.distance_to(pos) < mejor:
				mejor = qq.distance_to(pos)
				res = String(pl["id"])
	for l in c.get("metro", []):
		if ocultas.has(l["id"]):
			continue
		var seg: PackedVector2Array = l["seg"]
		for i in range(0, seg.size() - 1, 2):
			var q := Geometry2D.get_closest_point_to_segment(pos, seg[i], seg[i + 1])
			var d := q.distance_to(pos)
			if d < mejor:
				mejor = d
				res = l["id"]
	return res


static func estacion_en(pos: Vector2, tam: Vector2, margen: Vector2, umbral: float = 14.0) -> Dictionary:
	## Estación visible más cercana al punto (px locales): {"n": nombre, "l": [líneas], "p": posición local} o {} si no hay.
	var c := preparar(tam, margen)
	var mejor := umbral
	var res: Dictionary = {}
	for i in range(c["estaciones"].size()):
		var lineas: Array = c["est_lineas"][i]
		var visibles: Array = []
		for lid in lineas:
			if not ocultas.has(lid):
				visibles.append(lid)
		if visibles.is_empty():
			continue
		var d := (c["estaciones"][i] as Vector2).distance_to(pos)
		if d < mejor:
			mejor = d
			res = {"n": c["est_nombres"][i], "l": lineas, "p": c["estaciones"][i]}
	return res


static func color_linea(id: String) -> Color:
	for l in ids_lineas():
		if l["id"] == id:
			return l["color"]
	return Tema.TINTA


static func solo_linea(id: String) -> void:
	## Deja visible únicamente esta línea (enfoque rápido).
	ocultas.clear()
	for l in ids_lineas():
		if l["id"] != id:
			ocultas[l["id"]] = true
