class_name ComiteMapa
extends Control
## Mapa urbano de una propuesta del Comité: trazado de la variante, vista 2D/3D con inclinación animada y trazo que se dibuja solo.

const CELDAS := 9

var trazado: Array = []
var elevada: bool = false
var t3d: float = 0.0:
	set(v):
		t3d = v
		queue_redraw()
var trazo: float = 1.0:
	set(v):
		trazo = v
		queue_redraw()
var semilla: int = 7
signal estaciones_cambiadas(estaciones: Array)
var grafo: GrafoTrazado
var editando: bool = false
var estaciones: Array = []  # ids de nodo
var seleccion: int = -1
var _arrastre: int = -1
var _ruta_edicion: Array = []  # puntos [x, y] del camino Dijkstra entre estaciones


func _init() -> void:
	clip_contents = true


func iniciar_edicion(p_grafo: GrafoTrazado, p_estaciones: Array) -> void:
	grafo = p_grafo
	estaciones = p_estaciones.duplicate()
	editando = true
	seleccion = -1
	create_tween().tween_property(self, "t3d", 0.0, 0.3)
	_recalcular_ruta()


func terminar_edicion() -> void:
	editando = false
	queue_redraw()


func _recalcular_ruta() -> void:
	var ev := grafo.evaluar(estaciones)
	_ruta_edicion = []
	for id in ev["nodos"]:
		_ruta_edicion.append([grafo.pos[id].x, grafo.pos[id].y])
	queue_redraw()
	estaciones_cambiadas.emit(estaciones)


func agregar_estacion() -> void:
	if estaciones.size() < 2 or estaciones.size() >= int(grafo.params.get("max_estaciones", 7)):
		return
	var i := seleccion if seleccion >= 0 and seleccion < estaciones.size() - 1 else estaciones.size() - 2
	var medio: Vector2 = (grafo.pos[estaciones[i]] + grafo.pos[estaciones[i + 1]]) * 0.5
	var id := grafo.nodo_cercano(medio)
	if estaciones.has(id):
		return
	estaciones.insert(i + 1, id)
	seleccion = i + 1
	_recalcular_ruta()


func quitar_estacion() -> void:
	if estaciones.size() <= int(grafo.params.get("min_estaciones", 3)) or seleccion < 0:
		return
	estaciones.remove_at(seleccion)
	seleccion = -1
	_recalcular_ruta()


func _plano(p: Vector2) -> Vector2:
	return Vector2(size.x * 0.06 + p.x * size.x * 0.88, size.y * 0.06 + p.y * size.y * 0.88)


func _gui_input(event: InputEvent) -> void:
	if not editando or grafo == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_arrastre = -1
			var mejor := 28.0
			for i in range(estaciones.size()):
				var d := _plano(grafo.pos[estaciones[i]]).distance_to(event.position)
				if d < mejor:
					mejor = d
					_arrastre = i
			seleccion = _arrastre
			queue_redraw()
		else:
			_arrastre = -1
	elif event is InputEventMouseMotion and _arrastre >= 0:
		var q: Vector2 = (event.position - Vector2(size.x * 0.06, size.y * 0.06)) / Vector2(size.x * 0.88, size.y * 0.88)
		var id := grafo.nodo_cercano(q)
		if id != String(estaciones[_arrastre]) and not estaciones.has(id):
			estaciones[_arrastre] = id
			_recalcular_ruta()


func poner_variante(p_trazado: Array, p_elevada: bool) -> void:
	trazado = p_trazado
	elevada = p_elevada
	trazo = 0.0
	create_tween().tween_property(self, "trazo", 1.0, 0.9).set_trans(Tween.TRANS_SINE)


func modo_3d(activo: bool) -> void:
	create_tween().tween_property(self, "t3d", 1.0 if activo else 0.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _proj(x: float, y: float, z: float = 0.0) -> Vector2:
	var plano := Vector2(size.x * 0.06 + x * size.x * 0.88, size.y * 0.06 + y * size.y * 0.88)
	var ancho := size.x * 0.52
	var iso := Vector2(size.x * 0.5 + (x - y) * ancho, size.y * 0.16 + (x + y) * size.y * 0.30)
	return plano.lerp(iso, t3d) + Vector2(0, -z * t3d)


func _poly(pts: Array, col: Color) -> void:
	var a := 0.0
	for i in range(pts.size()):
		var q: Vector2 = pts[(i + 1) % pts.size()]
		a += pts[i].x * q.y - q.x * pts[i].y
	if absf(a) > 1.0:
		draw_colored_polygon(PackedVector2Array(pts), col)


func _h(i: int, j: int) -> int:
	return absi(hash("%d:%d:%d" % [semilla, i, j])) % 100


func _draw() -> void:
	draw_style_box(Tema.caja(Color("#3A9C6B"), 14), Rect2(Vector2.ZERO, size))
	var base := Color("#2F8A5E")
	_poly([_proj(0, 0), _proj(1, 0), _proj(1, 1), _proj(0, 1)], base)
	var c := 1.0 / float(CELDAS)
	var rio := 0.58
	_poly([_proj(0, rio), _proj(1, rio + 0.04), _proj(1, rio + 0.09), _proj(0, rio + 0.05)], Color("#8CC4E8"))
	for suma in range(CELDAS * 2 - 1):
		for i in range(CELDAS):
			var j := suma - i
			if j < 0 or j >= CELDAS:
				continue
			var x0 := float(i) * c + c * 0.12
			var y0 := float(j) * c + c * 0.12
			var x1 := x0 + c * 0.76
			var y1 := y0 + c * 0.76
			if y1 > rio and y0 < rio + 0.09:
				continue
			var dist := Vector2(float(i) - 4.0, float(j) - 4.0).length()
			var alto := (6.0 + float(_h(i, j)) * 0.30) * clampf(1.4 - dist * 0.14, 0.25, 1.4)
			var cima := Color("#F2EEE4") if _h(i, j) % 3 != 0 else Color("#E8D9A8")
			if dist > 4.2:
				cima = Color("#C9E4D2")
				alto *= 0.4
			_poly([_proj(x0, y1, 0), _proj(x1, y1, 0), _proj(x1, y1, alto), _proj(x0, y1, alto)], cima.darkened(0.22))
			_poly([_proj(x1, y0, 0), _proj(x1, y1, 0), _proj(x1, y1, alto), _proj(x1, y0, alto)], cima.darkened(0.36))
			_poly([_proj(x0, y0, alto), _proj(x1, y0, alto), _proj(x1, y1, alto), _proj(x0, y1, alto)], cima)
	if editando and grafo != null:
		_dibujar_edicion()
		return
	if trazado.size() < 2:
		return
	var elev := 20.0 if elevada else 0.0
	var largo := 0.0
	var tramos: Array[float] = []
	for k in range(trazado.size() - 1):
		var d := Vector2(trazado[k][0], trazado[k][1]).distance_to(Vector2(trazado[k + 1][0], trazado[k + 1][1]))
		tramos.append(d)
		largo += d
	var recorrido := largo * trazo
	var pts := PackedVector2Array()
	pts.append(_proj(trazado[0][0], trazado[0][1], elev))
	var acum := 0.0
	for k in range(tramos.size()):
		var a := Vector2(trazado[k][0], trazado[k][1])
		var b := Vector2(trazado[k + 1][0], trazado[k + 1][1])
		if acum + tramos[k] <= recorrido:
			pts.append(_proj(b.x, b.y, elev))
		else:
			var f := (recorrido - acum) / tramos[k]
			if f > 0.0:
				var m := a.lerp(b, f)
				pts.append(_proj(m.x, m.y, elev))
			break
		acum += tramos[k]
	if elevada and t3d > 0.05:
		for k in range(trazado.size()):
			var pie := _proj(trazado[k][0], trazado[k][1], 0.0)
			var tope := _proj(trazado[k][0], trazado[k][1], elev)
			draw_line(pie, tope, Color(0, 0, 0, 0.35 * t3d), 3.0)
	if pts.size() >= 2:
		draw_polyline(pts, Tema.CREMA, 9.0, true)
		draw_polyline(pts, Tema.ROJO, 5.5, true)
	for k in range(mini(pts.size(), trazado.size())):
		draw_circle(pts[k], 7.0, Tema.ROJO)
		draw_circle(pts[k], 4.8, Tema.CREMA)
	draw_string(Tema.fuente_texto(500), Vector2(10, size.y - 8), "Trazado ilustrativo · © colaboradores de OpenStreetMap (fase 3)", HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 9, Color(1, 1, 1, 0.75))


func _dibujar_edicion() -> void:
	for id in grafo.orden:
		draw_circle(_plano(grafo.pos[id]), 2.2, Color(1, 1, 1, 0.35))
	if _ruta_edicion.size() >= 2:
		var pts := PackedVector2Array()
		for q in _ruta_edicion:
			pts.append(_plano(Vector2(q[0], q[1])))
		draw_polyline(pts, Tema.CREMA, 9.0, true)
		draw_polyline(pts, Tema.ROJO, 5.5, true)
	for i in range(estaciones.size()):
		var c := _plano(grafo.pos[estaciones[i]])
		var sel := i == seleccion
		draw_circle(c, 13.0 if sel else 10.0, Tema.ORO if sel else Tema.TINTA)
		draw_circle(c, 9.5 if sel else 7.0, Tema.CREMA)
		draw_string(Tema.fuente_titulo(), c + Vector2(-6, 4.5), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 12.0, 11, Tema.TINTA)
