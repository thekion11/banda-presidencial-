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
const COLOR_PROPIA := Color("#00A99D")  # líneas creadas por el jugador (P1, P2…): distinto de todas las reales
static var propias: Array = []  # estado.lineas_jugador de la partida abierta (las pantallas lo asignan antes de dibujar)
static var fecha_iso: String = "2026-03-11"  # fecha de la partida (la fija cada pantalla que dibuja el mapa)
static var ocultas: Dictionary = {}  # ids de líneas de Metro ocultas (se comparte entre los mapas de la partida)


static func datos() -> Dictionary:
	if _datos.is_empty():
		var d: Variant = Datos.leer_json("res://data/geo/urbano_real.json")
		_datos = d if d != null else {}
		if not _datos.is_empty():
			_fusionar_futuras(_datos)
	return _datos


static func _norm(n: String) -> String:
	return n.to_lower().replace("-", " ").strip_edges()


static func _fusionar_futuras(d: Dictionary) -> void:
	## Líneas 7, 8 y 9 (en construcción o proyectadas): se suman a las líneas y estaciones reales. Una estación que ya existe
	## (Baquedano, Puente Cal y Canto, Matta…) se comparte y pasa a ser combinación; las nuevas se añaden con la marca «futuro».
	var f: Variant = Datos.leer_json("res://data/geo/metro_futuro.json")
	if f == null:
		return
	var por_nombre := {}
	for i in range(d["estaciones"].size()):
		por_nombre[_norm(String(d["estaciones"][i]["n"]))] = i
	for lid in f["lineas"]:
		var ln: Dictionary = f["lineas"][lid]
		var orden: Array = []
		var dentro: Array = []  # [nombre, posición] de las estaciones dentro de la ventana del mapa, en orden
		var fuera_ini := false
		var fuera_fin := false
		var n := (ln["estaciones"] as Array).size()
		for k in range(n):
			var e: Dictionary = ln["estaciones"][k]
			var p: Array = e["p"]
			var visible: bool = p[0] >= 0.0 and p[0] <= 1.0 and p[1] >= 0.0 and p[1] <= 1.0
			if not visible:
				if k < n / 2:
					fuera_ini = true
				else:
					fuera_fin = true
				continue
			var clave := _norm(String(e["n"]))
			var nombre := String(e["n"])
			if por_nombre.has(clave):
				var ex: Dictionary = d["estaciones"][por_nombre[clave]]
				if not (ex.get("l", []) as Array).has(lid):
					ex["l"] = (ex.get("l", []) as Array) + [lid]
				nombre = String(ex["n"])
				p = ex["p"]
			else:
				d["estaciones"].append({"n": nombre, "p": p, "l": [lid], "futuro": true})
				por_nombre[clave] = d["estaciones"].size() - 1
			orden.append(nombre)
			dentro.append(p)
		var cabos: Array = []
		if dentro.size() >= 2:
			for fin in range(2):
				var a: Array = dentro[0] if fin == 0 else dentro[dentro.size() - 1]
				var b: Array = dentro[1] if fin == 0 else dentro[dentro.size() - 2]
				var dir := Vector2(float(a[0]) - float(b[0]), float(a[1]) - float(b[1])).normalized()
				cabos.append({"n": orden[0 if fin == 0 else orden.size() - 1], "p": a, "d": [dir.x, dir.y], "sigue": fuera_ini if fin == 0 else fuera_fin})
		d["metro"].append({"id": lid, "color": ln["color"], "vias": ln["vias"], "cabos": cabos, "orden": orden, "futuro": true,
				"estado": ln["estado"], "apertura": ln["apertura"], "apertura_fecha": ln["apertura_fecha"]})


static func abierta(l: Dictionary) -> bool:
	## Una línea futura se dibuja continua si la fecha de la partida ya pasó su apertura estimada; las reales siempre.
	return not bool(l.get("futuro", false)) or fecha_iso >= String(l["apertura_fecha"])


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


static func area(tam: Vector2, margen: Vector2) -> Rect2:
	## Rectángulo donde se dibuja el plano: conserva el aspecto real de Gran Santiago (1,229) centrado en el espacio disponible,
	## en vez de estirarlo al tamaño del control (con 358×250 se deformaba un 16 %).
	var libre := tam - margen * 2.0
	var w := libre.x
	var h := w / aspecto()
	if h > libre.y:
		h = libre.y
		w = h * aspecto()
	return Rect2(margen + (libre - Vector2(w, h)) * 0.5, Vector2(w, h))


static func a_px(p: Array, tam: Vector2, margen: Vector2) -> Vector2:
	var r := area(tam, margen)
	return r.position + Vector2(float(p[0]) * r.size.x, float(p[1]) * r.size.y)


static func _segmentos(lista: Array, tam: Vector2, margen: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for pl in lista:
		for i in range(pl.size() - 1):
			out.append(a_px(pl[i], tam, margen))
			out.append(a_px(pl[i + 1], tam, margen))
	return out


static func preparar(tam: Vector2, margen: Vector2) -> Dictionary:
	var clave := "%d,%d,%d,%d,%s" % [int(tam.x), int(tam.y), int(margen.x), int(margen.y), fecha_iso]  # «abierta» de las líneas futuras depende de la fecha
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
		var vias_px: Array = []
		var seg := PackedVector2Array()
		for via in l["vias"]:
			var pv := PackedVector2Array()
			for q in via:
				pv.append(a_px(q, tam, margen))
			pv = UrbanoTrazo.redondear(pv, UrbanoTrazo.metros_a_px(220.0, tam, margen))
			vias_px.append(pv)
			for k in range(pv.size() - 1):
				seg.append(pv[k])
				seg.append(pv[k + 1])
		c["metro"].append({"id": String(l["id"]), "color": Color(String(l["color"])), "seg": seg, "vias": vias_px, "cabos": cabos, "abierta": abierta(l)})
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
	for i in range(c["estaciones"].size()):  # cada estación se ajusta al trazado suavizado de sus líneas (queda exactamente sobre la línea)
		var mejor_p: Vector2 = c["estaciones"][i]
		var mejor_d := 14.0
		for lid in c["est_lineas"][i]:
			for l2 in c["metro"]:
				if l2["id"] != lid:
					continue
				for via2 in l2["vias"]:
					var q2 := UrbanoTrazo.mas_cercano(c["estaciones"][i], via2)
					if q2.distance_to(c["estaciones"][i]) < mejor_d:
						mejor_d = q2.distance_to(c["estaciones"][i])
						mejor_p = q2
		c["estaciones"][i] = mejor_p
	c["_tam"] = tam
	c["_margen"] = margen
	_cache_clave = clave
	_cache = c
	return c


static func dibujar(ci: CanvasItem, tam: Vector2, margen: Vector2 = Vector2(8, 8), con_metro: bool = true, escala_linea: float = 1.0, suave: float = 0.0, detalle: bool = true) -> void:
	## `suave` (0..1) atenúa el mapa base (relieve, calles, parques) para que el Metro y la propuesta destaquen.
	var c := preparar(tam, margen)
	if c["calles"].is_empty():
		return
	var fondo := Color("#EFEADF")
	var limpio := suave >= 0.99  # modo "Metro": sin relieve (su imagen es de baja resolución) y solo avenidas principales, muy tenues
	var rel := relieve()
	if rel != null and not limpio:
		ci.draw_texture_rect(rel, area(tam, margen), false, Color(1, 1, 1, lerpf(0.75, 0.32, suave)))
	var color_parque := Color("#C4DDB8").lerp(fondo, suave * 0.5)
	for pk in c["parques"]:
		ci.draw_colored_polygon(pk["poly"], color_parque)
	if c["rio"].size() > 1:
		ci.draw_multiline(c["rio"], Color("#A9CFE4").lerp(fondo, suave * 0.4), 5.0 * escala_linea, true)
	for cl in [4, 3, 2, 1, 0]:
		if (limpio and cl > 2) or (not detalle and cl > 1):
			continue  # en modo limpio solo avenidas; mientras se arrastra o se hace zoom, solo las vías mayores (fluidez en el teléfono)
		if c["calles"][cl].size() > 1:
			ci.draw_multiline(c["calles"][cl], COLORES_CALLE[cl].lerp(fondo, suave * (0.62 if limpio else 0.6)), ANCHOS_CALLE[cl] * escala_linea * (0.8 if limpio else 1.0), cl <= 1)  # suavizado solo en avenidas: las ~18.600 calles menores con suavizado costaban ~150 MB de RAM (tests/medir_memoria.gd)
	if con_metro:
		_dibujar_metro(ci, c, escala_linea)


static func reiniciar() -> void:
	## Estado de los mapas ligado a la partida: se limpia al empezar o cargar otra.
	ocultas.clear()
	propias = []
	_cache_clave = ""


static func tinta_sobre(id: String) -> Color:
	## Color de texto legible (contraste ≥ 4,5) sobre la ficha de una línea: tinta sobre el amarillo de L2 y el celeste de L4A.
	return Tema.TINTA if id in ["L2", "L4A", "L7", "L8", "L9"] or id.begins_with("P") else Color.WHITE


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
		pts = UrbanoTrazo.redondear(pts, UrbanoTrazo.metros_a_px(300.0, c["_tam"], c["_margen"]), 5)
		var est := PackedVector2Array()
		for q in ln["estaciones"]:
			var e0 := a_px(q, c["_tam"], c["_margen"])
			var e1 := UrbanoTrazo.mas_cercano(e0, pts)
			est.append(e1 if e1 != Vector2.INF and e1.distance_to(e0) < 14.0 else e0)
		res.append({"id": String(ln["id"]), "pts": pts, "est": est, "nombres": ln.get("nombres_estaciones", []), "operativa": String(ln["estado"]) == "operativa"})
	return res


static func _dibujar_metro(ci: CanvasItem, c: Dictionary, esc: float) -> void:
	for l in c["metro"]:
		if ocultas.has(l["id"]):
			continue
		for via in l["vias"]:
			UrbanoTrazo.trazo(ci, via, Color(1, 1, 1, 0.92), 7.4 * esc)
	for l in c["metro"]:
		if ocultas.has(l["id"]):
			continue
		for via in l["vias"]:
			if bool(l["abierta"]):
				UrbanoTrazo.trazo(ci, via, l["color"], 4.6 * esc)
			else:  # línea en construcción o proyectada: trazo discontinuo
				UrbanoTrazo.discontinua(ci, via, l["color"], 4.6 * esc, 9.0 * esc, 6.0 * esc)
	for pl in _propias_px(c):
		var pts: PackedVector2Array = pl["pts"]
		if pts.size() < 2:
			continue
		UrbanoTrazo.trazo(ci, pts, Color(1, 1, 1, 0.95), 8.0 * esc)
		if pl["operativa"]:
			UrbanoTrazo.trazo(ci, pts, COLOR_PROPIA, 4.8 * esc)
		else:  # en construcción: trazo discontinuo
			UrbanoTrazo.discontinua(ci, pts, COLOR_PROPIA, 4.8 * esc, 10.0 * esc, 7.0 * esc)
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
	for pl in _propias_px(c):  # estaciones de las líneas del jugador (con el nombre que les puso)
		for i in range(pl["est"].size()):
			var d2 := (pl["est"][i] as Vector2).distance_to(pos)
			if d2 < mejor:
				mejor = d2
				res = {"n": String(pl["nombres"][i]) if i < pl["nombres"].size() else "Estación %d" % (i + 1), "l": [pl["id"]], "p": pl["est"][i]}
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
