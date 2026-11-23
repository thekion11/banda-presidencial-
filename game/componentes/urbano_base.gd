class_name UrbanoBase
extends RefCounted
## Cartografía real de Gran Santiago (© colaboradores de OpenStreetMap, ODbL) lista para dibujar:
## calles por jerarquía, río, parques, líneas y estaciones de Metro. Se prepara una vez por tamaño y se dibuja con pocas llamadas.

const COLORES_CALLE: Array[Color] = [Color("#B9AE95"), Color("#B9AE95"), Color("#C9BFA8"), Color("#D6CDB8"), Color("#E0D9C8")]
const ANCHOS_CALLE: Array[float] = [3.2, 3.0, 2.3, 1.5, 0.9]

static var _datos: Dictionary = {}
static var _cache_clave: String = ""
static var _cache: Dictionary = {}


static func datos() -> Dictionary:
	if _datos.is_empty():
		var d: Variant = Datos.leer_json("res://data/geo/urbano_real.json")
		_datos = d if d != null else {}
	return _datos


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


static func dibujar(ci: CanvasItem, tam: Vector2, margen: Vector2 = Vector2(8, 8), con_metro: bool = true, escala_linea: float = 1.0) -> void:
	var c := preparar(tam, margen)
	if c["calles"].is_empty():
		return
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
