class_name ComiteMapa
extends UrbanoVista
## Mapa 2D del Comité sobre calles reales de Gran Santiago: trazado de la variante con animación y modo edición
## (estaciones arrastrables que se ajustan a los cruces del grafo; el camino entre ellas lo calcula Dijkstra).

signal estaciones_cambiadas(estaciones: Array)
signal cambio_linea

var trazado: Array = []  # polilínea en coordenadas del plano (0..1)
var estaciones_pos: Array = []  # posiciones (plano) de las estaciones de la variante mostrada
var elevada: bool = false
var semilla: int = 7
var trazo: float = 1.0:
	set(v):
		trazo = v
		queue_redraw()
var grafo: GrafoTrazado
var editando: bool = false
var estaciones: Array = []  # ids de nodo en edición
var seleccion: int = -1
var _arrastre: int = -1
var _ruta_edicion: Array = []


func _init() -> void:
	clip_contents = true


func _ready() -> void:
	_iniciar_vista()


func poner_variante(p_trazado: Array, p_elevada: bool, p_estaciones: Array = []) -> void:
	trazado = p_trazado
	elevada = p_elevada
	estaciones_pos = p_estaciones
	trazo = 0.0
	create_tween().tween_property(self, "trazo", 1.0, 0.9).set_trans(Tween.TRANS_SINE)


func iniciar_edicion(p_grafo: GrafoTrazado, p_estaciones: Array) -> void:
	grafo = p_grafo
	estaciones = p_estaciones.duplicate()
	editando = true
	seleccion = -1
	_recalcular_ruta()


func terminar_edicion() -> void:
	editando = false
	queue_redraw()


func _recalcular_ruta() -> void:
	_ruta_edicion = grafo.evaluar(estaciones)["puntos"]
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


func _px(p: Vector2) -> Vector2:
	return UrbanoBase.a_px([p.x, p.y], size, MARGEN) * zoom + pan  # coordenadas de pantalla (con zoom y desplazamiento)


func _plano(px: Vector2) -> Vector2:
	var l := a_local(px)
	var r := UrbanoBase.area(size, MARGEN)
	return Vector2((l.x - r.position.x) / r.size.x, (l.y - r.position.y) / r.size.y)


func _vista_empieza(pos: Vector2) -> bool:
	## En edición, pulsar cerca de una estación (30 px) la selecciona y se queda con el arrastre; en otro sitio el arrastre mueve el mapa.
	if not editando or grafo == null:
		return false
	_arrastre = -1
	var mejor := 30.0
	for i in range(estaciones.size()):
		var d := _px(grafo.pos[estaciones[i]]).distance_to(pos)
		if d < mejor:
			mejor = d
			_arrastre = i
	seleccion = _arrastre
	queue_redraw()
	return _arrastre >= 0


func _vista_mueve(event: InputEventMouseMotion) -> void:
	if _arrastre < 0:
		return
	var id := grafo.nodo_cercano(_plano(event.position))
	if id != String(estaciones[_arrastre]) and not estaciones.has(id):
		estaciones[_arrastre] = id
		_recalcular_ruta()


func _vista_suelta(_pos: Vector2) -> void:
	_arrastre = -1


func _vista_toque(pos: Vector2) -> void:
	if editando:
		return
	var id := UrbanoBase.linea_en(a_local(pos), size, MARGEN, 16.0 / zoom)
	if id != "":
		UrbanoBase.alternar_linea(id)
		queue_redraw()
		cambio_linea.emit()


func _linea(puntos: Array, hasta: float) -> void:
	var pts := PackedVector2Array()
	for q in puntos:
		pts.append(_px(Vector2(q[0], q[1])))
	pts = UrbanoTrazo.redondear(pts, UrbanoTrazo.metros_a_px(300.0, size, MARGEN) * zoom, 5)
	var largo := 0.0
	for i in range(pts.size() - 1):
		largo += pts[i].distance_to(pts[i + 1])
	var tope := largo * hasta
	var vis := PackedVector2Array([pts[0]]) if not pts.is_empty() else PackedVector2Array()
	var acum := 0.0
	for i in range(pts.size() - 1):
		var d := pts[i].distance_to(pts[i + 1])
		if acum + d <= tope:
			vis.append(pts[i + 1])
		else:
			vis.append(pts[i].lerp(pts[i + 1], (tope - acum) / maxf(d, 0.001)))
			break
		acum += d
	if vis.size() >= 2:
		UrbanoTrazo.trazo(self, vis, Tema.CREMA, 9.0)
		UrbanoTrazo.trazo(self, vis, Tema.ROJO, 5.5)


func _draw() -> void:
	draw_style_box(Tema.caja(Color("#EFEADF"), 14, Tema.BORDE_CLARO, 1), Rect2(Vector2.ZERO, size))
	var esc := (1.0 + 0.35 * (zoom - 1.0)) / zoom
	draw_set_transform(pan, 0.0, Vector2(zoom, zoom))
	UrbanoBase.dibujar(self, size, MARGEN, true, 0.9 * esc, 0.45, not _en_movimiento)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	UrbanoRotulos.fichas(self, size, MARGEN, zoom, pan)
	if editando and grafo != null:
		if _ruta_edicion.size() >= 2:
			_linea(_ruta_edicion, 1.0)
		for i in range(estaciones.size()):
			var c := _px(grafo.pos[estaciones[i]])
			var sel := i == seleccion
			draw_circle(c, 14.0 if sel else 11.0, Tema.ORO if sel else Tema.TINTA)
			draw_circle(c, 10.5 if sel else 8.0, Tema.CREMA)
			draw_string(Tema.fuente_titulo(), c + Vector2(-6, 4.5), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 12.0, 11, Tema.TINTA)
	elif trazado.size() >= 2:
		_linea(trazado, trazo)
		if trazo > 0.95:
			for q in estaciones_pos:
				var c2 := _px(Vector2(q[0], q[1]))
				draw_circle(c2, 8.0, Tema.ROJO)
				draw_circle(c2, 5.5, Tema.CREMA)
	draw_string(Tema.fuente_texto(400), Vector2(10, size.y - 8), "© colaboradores de OpenStreetMap (ODbL) · trazado ilustrativo", HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 10, Tema.GRIS_CLARO)  # mínimo 10 pt
