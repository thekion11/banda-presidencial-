class_name MapaContinente
extends Control
## Sudamérica en 2D (Natural Earth, mapa ilustrativo): cada país coloreado por su relación con Chile; las potencias van como íconos fuera del mapa.

signal pais_tocado(iso: String)

var _geo: Dictionary = {}
var _vec: Dictionary = {}
var seleccion: String = ""
var relaciones: Dictionary = {}  # iso -> relación actual (base + eventos de la partida)
var _tri: Dictionary = {}  # iso -> Array[PackedVector2Array] ya limpios


func cargar(geo: Dictionary, vecinos: Dictionary) -> void:
	_geo = geo
	_vec = vecinos
	for iso in geo["paises"].keys():
		var lista: Array[PackedVector2Array] = []
		for c in geo["paises"][iso]["contornos"]:
			var pv := PackedVector2Array()
			for p in c:
				pv.append(Vector2(float(p[0]), float(p[1])))
			for limpio in Geometry2D.offset_polygon(pv, 0.0):
				lista.append(limpio)
		_tri[iso] = lista
	queue_redraw()


func _area() -> Rect2:
	## Mapa a la izquierda y columna de potencias a la derecha; conserva la proporción.
	var ancho := size.x * 0.72
	var alto := minf(size.y - 12.0, ancho / float(_geo["ancho_rel"]))
	var ancho_real := alto * float(_geo["ancho_rel"])
	return Rect2(Vector2(6.0, (size.y - alto) * 0.5), Vector2(ancho_real, alto))


func _a_pantalla(p: Vector2, r: Rect2) -> Vector2:
	return r.position + Vector2(p.x / float(_geo["ancho_rel"]) * r.size.x, p.y * r.size.y)


func _draw() -> void:
	if _geo.is_empty():
		return
	var r := _area()
	var rel: Dictionary = _vec["paises"]
	for iso in _tri.keys():
		var col := Tema.color_aprobacion(float(relaciones.get(iso, rel.get(iso, {}).get("relacion", 50.0))))
		if iso == "CHL":
			col = Tema.ORO
		for pieza in _tri[iso]:
			var pts := PackedVector2Array()
			for p in pieza:
				pts.append(_a_pantalla(p, r))
			draw_colored_polygon(pts, col.darkened(0.15 if iso != seleccion else 0.0))
			pts.append(pts[0])
			draw_polyline(pts, Color(0.04, 0.13, 0.21) if iso != seleccion else Tema.CREMA, 1.2 if iso != seleccion else 2.2, true)
	var f := Tema.fuente_texto(600)
	var x := r.end.x + 14.0
	var y := 40.0
	draw_string(f, Vector2(x, y - 14.0), "Potencias", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Tema.TEXTO_SUAVE)
	for pt in _vec["potencias"]:
		draw_circle(Vector2(x + 14.0, y + 12.0), 14.0, Tema.color_aprobacion(float(pt["relacion"])).darkened(0.1))
		draw_string(f, Vector2(x + 34.0, y + 17.0), String(pt["nombre"]), HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 36.0, 11, Tema.TEXTO)
		y += 56.0


func _gui_input(ev: InputEvent) -> void:
	if not (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or _geo.is_empty():
		return
	var r := _area()
	for iso in _tri.keys():
		for pieza in _tri[iso]:
			var pts := PackedVector2Array()
			for p in pieza:
				pts.append(_a_pantalla(p, r))
			if Geometry2D.is_point_in_polygon(ev.position, pts):
				seleccion = String(iso)
				pais_tocado.emit(seleccion)
				queue_redraw()
				return
