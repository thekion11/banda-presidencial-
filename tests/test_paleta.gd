extends SceneTree
## Paleta congelada (CLAUDE.md §5): todo color escrito en game/ debe salir de la paleta. Vale un color de la paleta
## (océano, panel, oro, rojo, crema, escala de aprobación y su versión Okabe-Ito para daltonismo) o una mezcla de dos
## de ellos o con negro o blanco: tonos, sombras y degradados entre colores de la paleta. Se acepta una diferencia
## perceptual de hasta ΔE 8 (CIELAB) con la mezcla más cercana. Lee los Color("#RRGGBB") y Color(r, g, b) del código.
## Excepciones (datos reales, no diseño): los colores de las líneas de Metro y la cartografía vienen de data/.

const DELTA_MAX := 8.0
const PASOS := 40

var _fallos := 0
var _anclas: Array[Color] = []
var _mezclas_lab: Array[Vector3] = []


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


static func _lineal(x: float) -> float:
	return x / 12.92 if x <= 0.04045 else pow((x + 0.055) / 1.055, 2.4)


static func lab(c: Color) -> Vector3:
	var r := _lineal(c.r)
	var g := _lineal(c.g)
	var b := _lineal(c.b)
	var x := (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
	var y := 0.2126 * r + 0.7152 * g + 0.0722 * b
	var z := (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
	var f := func(t: float) -> float: return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0
	var fx: float = f.call(x)
	var fy: float = f.call(y)
	var fz: float = f.call(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


func _preparar() -> void:
	_anclas.assign([Tema.OCEANO, Tema.PANEL, Tema.ORO, Tema.ROJO, Tema.CREMA, Tema.SUBE, Tema.BAJA, Color.BLACK, Color.WHITE,
		Color("#0072B2"), Color("#9A5200")])  # tintas Okabe-Ito sobre crema (Tema.bien_tinta / mal_tinta)
	_anclas.append_array(Tema.ESCALA_APROBACION)
	_anclas.append_array(Tema.ESCALA_DALTONICA)
	for i in range(_anclas.size()):
		for j in range(i, _anclas.size()):
			for k in range(PASOS + 1):
				_mezclas_lab.append(lab(_anclas[i].lerp(_anclas[j], float(k) / float(PASOS))))


func distancia(c: Color) -> float:
	var l := lab(c)
	var mejor := INF
	for m in _mezclas_lab:
		mejor = minf(mejor, l.distance_to(m))
	return mejor


func _archivos(dir: String) -> Array[String]:
	var res: Array[String] = []
	for sub in DirAccess.get_directories_at(dir):
		res.append_array(_archivos(dir + "/" + sub))
	for a in DirAccess.get_files_at(dir):
		if a.ends_with(".gd"):
			res.append(dir + "/" + a)
	return res


func _correr() -> void:
	_preparar()
	var re_hex := RegEx.create_from_string("Color\\(\"(#[0-9A-Fa-f]{6})")
	var re_num := RegEx.create_from_string("(?<![\\w.])Color\\(\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*,\\s*([0-9.]+)")
	var vistos := 0
	var cache := {}
	for ruta in _archivos("res://game"):
		var lineas := FileAccess.get_file_as_string(ruta).split("\n")
		for n in range(lineas.size()):
			var l: String = lineas[n]
			var colores: Array[Color] = []
			for m in re_hex.search_all(l):
				colores.append(Color(m.get_string(1)))
			for m in re_num.search_all(l):
				var c := Color(float(m.get_string(1)), float(m.get_string(2)), float(m.get_string(3)))
				if c.r <= 1.0 and c.g <= 1.0 and c.b <= 1.0:
					colores.append(c)
			for c in colores:
				vistos += 1
				var clave := c.to_html(false)
				if not cache.has(clave):
					cache[clave] = distancia(c)
				var d: float = cache[clave]
				_check(d <= DELTA_MAX, "%s:%d usa #%s, fuera de la paleta (ΔE %.1f con la mezcla más cercana; máx. %.0f)" % [ruta, n + 1, clave.to_upper(), d, DELTA_MAX])
	_check(vistos > 150, "la auditoría debe revisar muchos colores (revisó %d)" % vistos)
	_check(distancia(Color("#7E6BB0")) > DELTA_MAX, "un violeta saturado no es de la paleta (control de la prueba)")
	_check(distancia(Tema.PANEL.lerp(Tema.OCEANO, 0.5)) < 0.5, "una mezcla de panel y océano sí es de la paleta (control)")
	if _fallos == 0:
		print("PALETA OK (%d colores, %d distintos)" % [vistos, cache.size()])
	quit(1 if _fallos > 0 else 0)
