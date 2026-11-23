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
	var c: Dictionary = {"calles": [], "metro": [], "rio": PackedVector2Array(), "parques": [], "estaciones": PackedVector2Array()}
	if d.is_empty():
		return c
	var por_clase: Array = [[], [], [], [], []]
	for k in d["calles"]:
		por_clase[int(k["c"])].append(k["p"])
	for cl in range(5):
		c["calles"].append(_segmentos(por_clase[cl], tam, margen))
	c["rio"] = _segmentos(d["rio"], tam, margen)
	for l in d["metro"]:
		c["metro"].append({"color": Color(String(l["color"])), "seg": _segmentos(l["vias"], tam, margen)})
	for pk in d["parques"]:
		var poly := PackedVector2Array()
		for p in pk:
			poly.append(a_px(p, tam, margen))
		var tri := Geometry2D.triangulate_polygon(poly)
		if not tri.is_empty():
			c["parques"].append({"poly": poly, "tri": tri})
	for e in d["estaciones"]:
		c["estaciones"].append(a_px(e["p"], tam, margen))
	_cache_clave = clave
	_cache = c
	return c


static func dibujar(ci: CanvasItem, tam: Vector2, margen: Vector2 = Vector2(8, 8), con_metro: bool = true, escala_linea: float = 1.0, con_lugares: bool = false) -> void:
	var c := preparar(tam, margen)
	if c["calles"].is_empty():
		return
	var rel := relieve()
	if rel != null:
		ci.draw_texture_rect(rel, Rect2(margen, tam - margen * 2.0), false, Color(1, 1, 1, 0.75))
	for pk in c["parques"]:
		var poly: PackedVector2Array = pk["poly"]
		var tri: PackedInt32Array = pk["tri"]
		for i in range(0, tri.size(), 3):
			ci.draw_colored_polygon(PackedVector2Array([poly[tri[i]], poly[tri[i + 1]], poly[tri[i + 2]]]), Color("#C4DDB8"))
	if c["rio"].size() > 1:
		ci.draw_multiline(c["rio"], Color("#A9CFE4"), 5.0 * escala_linea, true)
	for cl in [4, 3, 2, 1, 0]:
		if c["calles"][cl].size() > 1:
			ci.draw_multiline(c["calles"][cl], COLORES_CALLE[cl], ANCHOS_CALLE[cl] * escala_linea, true)
	if con_metro:
		for l in c["metro"]:
			if l["seg"].size() > 1:
				ci.draw_multiline(l["seg"], l["color"], 3.2 * escala_linea, true)
		for p in c["estaciones"]:
			ci.draw_circle(p, 3.4 * escala_linea, Tema.TINTA)
			ci.draw_circle(p, 2.2 * escala_linea, Color.WHITE)
	if con_lugares:
		var f := Tema.fuente_texto(700)
		var ocupados: Array[Rect2] = []
		for l in datos().get("lugares", []):
			var p := a_px(l["p"], tam, margen)
			ci.draw_circle(p, 3.0, Tema.ROJO)
			var txt := String(l["n"]).replace("Parque Metropolitano de Santiago", "Parque Metropolitano")
			var ancho_txt := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			var x := minf(p.x + 5.0, tam.x - ancho_txt - 4.0)
			var caja := Rect2(x - 2.0, p.y - 7.0, ancho_txt + 4.0, 13.0)
			var choca := false
			for r in ocupados:
				if r.intersects(caja):
					choca = true
					break
			if choca:
				continue  # evita nombres encimados: los lugares se priorizan en el orden de los datos
			ocupados.append(caja)
			ci.draw_string_outline(f, Vector2(x, p.y + 3.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 4, Color(0.94, 0.92, 0.87, 0.95))
			ci.draw_string(f, Vector2(x, p.y + 3.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TINTA)
