class_name MapaChile
extends Control
## Mapa nacional: regiones reales coloreadas por aprobación, mar y marcadores de obras.

signal region_tocada(id: String)

## Geometría triangulada una sola vez por ejecución (la geografía no cambia): abrir Día/Nación ya no la recalcula.
static var _cache: Dictionary = {}

var estirar_x: float = 2.3  # licencia gráfica: Chile es muy angosto para una pantalla vertical

var _piezas: Dictionary = {}  # id -> Array[PackedVector2Array] normalizadas (contornos)
var _mallas: Dictionary = {}  # id -> ArrayMesh pretriangulada
var _banda_y: Dictionary = {}  # id -> Vector2(y_min, y_max)
var _ancho_rel: float = 0.2
var valores: Dictionary = {}
var seleccion: String = "":
	set(v):
		if v != seleccion:
			seleccion = v
			queue_redraw()
var obras: Dictionary = {}  # id -> cantidad de obras en curso
var bastion: String = ""
var _ciudades: Array = []
var _este: PackedVector2Array = PackedVector2Array()  # borde oriental (Cordillera) por franjas de latitud
var propuestas: Dictionary = {}
var _decor: Control
var animar: bool = true
var _relieve: Texture2D
var x_centro_rel: float = 0.5
var leyenda: bool = true
var ciudades_visibles: bool = true
var _camara := Transform2D.IDENTITY  # golpe de cámara al recibir una carta (dirección visual v4); el fondo no se mueve
var _onda: Dictionary = {}  # {pos, t, color}: ondas del último impacto
var _destello_id: String = ""
var _destello: float = 0.0
var _reaccion: Tween
var _vivo: Control  # capa animada barata: tendencias, bastión, obras y propuestas (solo ella se redibuja cada cuadro)
var _previos: Dictionary = {}
var _tendencia: Dictionary = {}  # id -> +1 / -1 desde el último cambio de aprobación regional
var _t: float = 0.0
var _contornos_px: Dictionary = {}  # id -> contornos ya transformados y cerrados (caché por tamaño: la capa viva los dibuja cada cuadro)
var _centros_px: Dictionary = {}
var _tam_px: Vector4 = Vector4(-1, -1, -1, -1)  # tamaño, centro horizontal y estiramiento: lo que mueve los contornos
var enlace: Control:  # tarjeta de la región elegida: la maqueta la une con una línea punteada a su región
	set(v):
		enlace = v
		if v != null:
			v.item_rect_changed.connect(queue_redraw)
var _segs_tendencia: Dictionary = {}  # signo -> segmentos de las regiones que suben o bajan (caché de la capa viva)
var _segs_clave := Vector4(-2, -2, -2, -2)
var _segs_de: Dictionary = {}  # la tendencia con que se armó la caché (se reasigna al cambiar)
var _zoom := MapaZoom.new()  # acercar y desplazar (pedido del usuario del 27-nov); se compone con la cámara
var _ver_todo: Button
var nombres: Dictionary = {}  # id -> nombre de la región: se rotulan al acercar
var _rotulos: Array = []  # [[id, área de toque]] de los nombres dibujados
var _fuegos: Array[Dictionary] = []  # {pos, inicio, color}: obra terminada (dirección visual v4)


func cargar_geo(geo: Dictionary) -> void:
	_ancho_rel = float(geo["ancho_rel"])
	_ciudades = geo.get("ciudades", [])
	if ResourceLoader.exists("res://data/geo/relieve.png"):
		_relieve = load("res://data/geo/relieve.png")
	if _cache.has("piezas"):
		_piezas = _cache["piezas"]
		_mallas = _cache["mallas"]
		_banda_y = _cache["banda_y"]
	else:
		_cache = MapaGeometria.triangular(geo, _ancho_rel)
		_piezas = _cache["piezas"]
		_mallas = _cache["mallas"]
		_banda_y = _cache["banda_y"]
	_este = MapaGeometria.borde_este(_piezas)
	if _vivo == null:
		_vivo = Control.new()
		_vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
		_vivo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_vivo.draw.connect(_dibujar_vivo)
		add_child(_vivo)
	if animar and _decor == null:
		_decor = MapaDecor.new()
		_decor.mapa = self
		_decor.set_anchors_preset(Control.PRESET_FULL_RECT)
		_decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_decor)
	queue_redraw()


func actualizar(p_valores: Dictionary, p_obras: Dictionary = {}, p_propuestas: Dictionary = {}) -> void:
	var cambios := {}
	for id in p_valores.keys():
		if _previos.has(id) and absf(float(p_valores[id]) - float(_previos[id])) >= 0.3:
			cambios[id] = 1 if float(p_valores[id]) > float(_previos[id]) else -1
	if not cambios.is_empty():
		_tendencia = cambios  # laten las regiones que se movieron en el último cambio
	_previos = p_valores.duplicate()  # copia: el estado modifica el diccionario en su lugar
	for id in obras.keys():  # una obra salió de «en curso»: se terminó esta semana
		if int(p_obras.get(id, 0)) < int(obras[id]):
			lanzar_fuegos(id, 2.6)  # tras el telón de fin de semana
	valores = p_valores
	obras = p_obras
	propuestas = p_propuestas
	queue_redraw()


func _cam() -> Transform2D:
	## Vista del jugador (zoom y desplazamiento) sobre la cámara de las reacciones (golpe al recibir una carta).
	return _zoom.vista() * _camara


func a_pantalla(p: Vector2) -> Vector2:
	## Punto del mapa (centro(), contornos) a coordenadas del control, con el zoom y la cámara aplicados.
	return _cam() * p


func _transformar(p: Vector2) -> Vector2:
	var h := size.y - 16.0
	var ancho := _ancho_rel * h * estirar_x
	return Vector2(size.x * x_centro_rel - ancho * 0.5 + p.x * h * estirar_x, 8.0 + p.y * h)


func _draw() -> void:
	## Quieto, la capa base (océano, regiones, contornos, Cordillera y ciudades) sale de una textura pintada una vez
	## (UrbanoCache): ~7,7 ms de CPU de render menos por cuadro (tests/medir_transiciones.gd). Mientras reacciona a una
	## carta (golpe de cámara, destello, ondas) se dibuja en vivo.
	var animando := _camara != Transform2D.IDENTITY or _onda.has("pos") or _destello > 0.0 or _zoom.moviendo
	if animando:
		_pintar_base(self, Transform2D.IDENTITY, _cam())
	else:
		_base_en_cache()
		draw_texture_rect(_textura_base.get_texture(), Rect2(Vector2.ZERO, size), false)
		draw_set_transform_matrix(_cam())
	if _onda.has("pos"):  # ondas del impacto de la carta en la región
		var o := _onda
		var t: float = o["t"]
		for k in range(2):
			var tk := clampf(t * 1.25 - 0.22 * float(k), 0.0, 1.0)
			if tk > 0.0:
				draw_arc(o["pos"], 6.0 + 54.0 * tk, 0.0, TAU, 48, Color(o["color"], (1.0 - tk) * 0.9), 3.0 - 1.5 * tk, true)
		draw_circle(o["pos"], 7.0 * (1.0 - t), Color(Tema.CREMA, 1.0 - t))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if enlace != null and enlace.is_visible_in_tree() and _banda_y.has(seleccion):
		var desde := _cam() * centro(seleccion)
		var r := get_global_transform().affine_inverse() * enlace.get_global_rect()
		var hasta := Vector2(r.position.x - 2.0, clampf(desde.y, r.position.y + 14.0, r.end.y - 14.0))
		if hasta.x - desde.x > 16.0:
			draw_dashed_line(desde + (hasta - desde).normalized() * 7.0, hasta, Color(Tema.ORO, 0.85), 1.5, 5.0)
			draw_circle(desde, 3.0, Tema.ORO)
	if leyenda:
		var r := Rect2(size.x - 178.0, size.y - 34.0, 168.0, 26.0)
		draw_style_box(Tema.caja(Color(0.04, 0.13, 0.21, 0.85), 10), r)
		draw_string(Tema.fuente_texto(500), r.position + Vector2(8, 17), "Aprobación", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TEXTO_SUAVE)
		for k in range(60):
			draw_rect(Rect2(r.position.x + 74.0 + float(k) * 1.4, r.position.y + 9.0, 1.6, 8.0), Tema.color_aprobacion(30.0 + float(k) / 59.0 * 30.0))
	var ids: Array = _banda_y.keys()
	if ids.has(seleccion):  # el nombre de la región elegida va primero: nunca lo tapa otro
		ids.erase(seleccion)
		ids.push_front(seleccion)
	_rotulos = MapaZoom.rotular(self, nombres, ids, _zoom.zoom, func(id: String) -> Vector2: return _cam() * centro(id))  # nombres al acercar
	if _vivo != null:
		_vivo.queue_redraw()  # obras y propuestas se dibujan en la capa viva (siguen al golpe de cámara)


func _pintar_base(ci: CanvasItem, base: Transform2D, cam: Transform2D) -> void:
	ci.draw_set_transform_matrix(base)
	var fondo := PackedColorArray([Color("#0E2B45"), Color("#0E2B45"), Color("#0A1E31"), Color("#0A1E31")])
	ci.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]), fondo)
	var reja := PackedVector2Array()  # cuadrícula y olas en una sola llamada de dibujo cada una (antes ~220 llamadas por cuadro)
	for gx in range(0, int(size.x), 26):
		reja.append_array([Vector2(gx, 0), Vector2(gx, size.y)])
	for gy in range(0, int(size.y), 26):
		reja.append_array([Vector2(0, gy), Vector2(size.x, gy)])
	ci.draw_multiline(reja, Color(1, 1, 1, 0.035), 1.0)
	var olas := PackedVector2Array()
	var fila := 0
	for gy in range(14, int(size.y), 20):
		for gx in range(int(fila % 2) * 15, int(size.x), 30):
			for k in range(5):  # arco de 6 puntos entre 0,15π y 0,85π, como draw_arc
				var a0 := PI * (0.15 + 0.14 * float(k))
				olas.append_array([Vector2(gx, gy) + Vector2(cos(a0), sin(a0)) * 4.5, Vector2(gx, gy) + Vector2(cos(a0 + PI * 0.14), sin(a0 + PI * 0.14)) * 4.5])
		fila += 1
	ci.draw_multiline(olas, Color(0.55, 0.78, 1.0, 0.10), 1.2)
	ci.draw_set_transform_matrix(base * cam)
	for id in _piezas.keys():
		var col := Tema.color_aprobacion(float(valores.get(id, 50.0)))
		if id == seleccion:
			col = col.lightened(0.18)
		if id == _destello_id and _destello > 0.0:
			col = col.lerp(Tema.CREMA, 0.55 * _destello)
		if _mallas.has(id):
			var h := size.y - 16.0
			ci.draw_set_transform_matrix(base * cam * Transform2D(0.0, Vector2(h * estirar_x, h), 0.0, _transformar(Vector2.ZERO) + Vector2(5.0, 6.0)))
			ci.draw_mesh(_mallas[id], null, Transform2D.IDENTITY, Color(0, 0, 0, 0.38))
			var origen := _transformar(Vector2.ZERO)
			ci.draw_set_transform_matrix(base * cam * Transform2D(0.0, Vector2(h * estirar_x, h), 0.0, origen))
			ci.draw_mesh(_mallas[id], null, Transform2D.IDENTITY, col)
			if _relieve != null:
				ci.draw_mesh(_mallas[id], _relieve, Transform2D.IDENTITY, Color(1, 1, 1, 0.7))
			ci.draw_set_transform_matrix(base * cam)
	var bordes := PackedVector2Array()  # contornos (116 piezas): uno solo draw_multiline tras los rellenos; la región elegida va encima
	for id in _piezas.keys():
		if id != seleccion:
			for pts in _contornos(id):
				bordes.append_array(_segmentos(pts))
	ci.draw_multiline(bordes, Color(1, 0.97, 0.9, 0.5), 0.9, false)  # sin suavizado: con suavizado la CPU de render se triplicaba (tests/medir_transiciones.gd)
	for pts in (_contornos(seleccion) if _piezas.has(seleccion) else []):
		ci.draw_polyline(pts, Tema.ORO, 2.5, true)
	var cerros := PackedVector2Array()  # Cordillera: todos los cerros en un solo arreglo de triángulos (antes 3 llamadas por cerro)
	var tonos := PackedColorArray()
	for i in range(0, _este.size(), 2):
		var q := _transformar(_este[i] + Vector2(0.004, 0.0))
		var h := 5.0 + float((i * 7) % 4)
		var q2 := q + Vector2(9.0, 7.0)
		cerros.append_array([q + Vector2(-5, h * 0.6), q + Vector2(0, -h), q + Vector2(5, h * 0.6), q + Vector2(-2.2, -h * 0.35), q + Vector2(0, -h),
			q + Vector2(2.2, -h * 0.35), q2 + Vector2(-3.5, 3), q2 + Vector2(0, -3.5), q2 + Vector2(3.5, 3)])
		for c: Color in [Color("#2F6288", 0.65), Color(1, 1, 1, 0.55), Color("#2F6288", 0.35)]:
			tonos.append_array([c, c, c])
	if not cerros.is_empty():
		var idx := PackedInt32Array(range(cerros.size()))
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, cerros, tonos)
	var fuente := Tema.fuente_texto(600)
	ci.draw_set_transform_matrix(base)  # ciudades: posición con zoom, pero letra y punto a tamaño fijo (nítidos a cualquier zoom)
	for c in (_ciudades if ciudades_visibles else []):
		if c["nombre"] == "Santiago":
			continue
		var pc := cam * _transformar(Vector2(float(c["x"]), float(c["y"])))
		ci.draw_circle(pc, 3.6, Tema.CREMA)
		ci.draw_circle(pc, 2.0, Tema.OCEANO)
		var nombre := String(c["nombre"])
		var ancho_txt := fuente.get_string_size(nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		ci.draw_string(fuente, Vector2(pc.x - 8.0 - ancho_txt, pc.y + 3.5), nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TEXTO)


var _textura_base: UrbanoCache


func _base_en_cache() -> void:
	if _textura_base == null:
		_textura_base = UrbanoCache.new()
		add_child(_textura_base)
	var s := clampf(get_viewport().get_final_transform().get_scale().x, 1.0, 4.0)  # escala real de la pantalla: nítido en el teléfono
	var clave := "%d|%s|%.3f|%.3f|%s|%s|%.2f|%.3f|%s" % [hash(valores), seleccion, estirar_x, x_centro_rel, ciudades_visibles, _relieve != null, s, _zoom.zoom, _zoom.pan.round()]
	var vista := _zoom.vista()  # la caché se repinta solo cuando cambian el zoom o el encuadre
	_textura_base.pintar = func(ci: CanvasItem) -> void: _pintar_base(ci, Transform2D(0.0, Vector2(s, s), 0.0, Vector2.ZERO), vista)
	_textura_base.preparar(size, s, clave)


func reaccionar(id: String, color: Color) -> void:
	## El mapa recibe la carta: golpe de cámara hacia la región (acerca y rebota con un leve temblor), ondas y destello.
	if not Movimiento.activo():
		return
	var p := centro(id) if _banda_y.has(id) else size * 0.5
	var onda := {"pos": p, "t": 0.0, "color": color}  # propia de esta reacción: dos cartas seguidas no se pisan
	_onda = onda
	_destello_id = id
	if _reaccion != null and _reaccion.is_valid():
		_reaccion.kill()  # la reacción nueva reemplaza a la anterior (cámara, destello y ondas)
	var fuerza := 1.0 if Movimiento.intenso() else 0.0  # con «Reducir movimiento»: ondas y destello, sin golpe de cámara
	_reaccion = create_tween()
	_reaccion.tween_method(func(t: float) -> void:
		var s := 1.0 + 0.07 * fuerza * sin(t * 2.6 * PI) * exp(-3.2 * t)
		var temblor := Vector2(sin(t * 41.0), cos(t * 33.0)) * 3.0 * fuerza * pow(1.0 - t, 2.0)
		_camara = Transform2D(0.0, Vector2(s, s), 0.0, p * (1.0 - s) + temblor)
		_destello = 1.0 - t
		onda["t"] = t
		if t >= 1.0:
			_camara = Transform2D.IDENTITY
			_destello = 0.0
			if _onda == onda:
				_onda = {}
		queue_redraw(), 0.0, 1.0, 0.9)


func lanzar_fuegos(id: String, demora: float = 0.0) -> void:
	## Tres fuegos artificiales (oro, crema y rojo) sobre la región de una obra terminada.
	if not Movimiento.intenso() or not _banda_y.has(id):
		return
	for k in range(3):
		_fuegos.append({"id": id, "dx": -18.0 + 18.0 * float(k), "inicio": _t + demora + 0.28 * float(k), "color": [Tema.ORO, Tema.CREMA, Tema.ROJO][k]})
	get_tree().create_timer(demora).timeout.connect(func() -> void: Feedback.sonar("exito"))


func posicion_global(id: String) -> Vector2:
	## Punto de la región en coordenadas de pantalla (destino de la carta que vuela).
	return get_global_transform() * (_cam() * centro(id) if _banda_y.has(id) else size * 0.5)


func _contornos(id: String) -> Array:
	## Contornos de la región en píxeles, cerrados. Se recalculan solo si cambia el tamaño del mapa
	## (antes se transformaban ~3.000 puntos en cada cuadro de la capa viva: ~0,8 ms en escritorio).
	var clave := Vector4(size.x, size.y, x_centro_rel, estirar_x)
	if clave != _tam_px:
		_contornos_px.clear()
		_centros_px.clear()
		_tam_px = clave
	if not _contornos_px.has(id):
		var lista: Array = []
		for pieza in _piezas.get(id, []):
			var pts := PackedVector2Array()
			for p in pieza:
				pts.append(_transformar(p))
			if not pts.is_empty():
				pts.append(pts[0])
			lista.append(pts)
		_contornos_px[id] = lista
	return _contornos_px[id]


static func _segmentos(pts: PackedVector2Array) -> PackedVector2Array:
	## Polilínea como pares de puntos para draw_multiline (sin arreglos temporales por segmento).
	var r := PackedVector2Array()
	if pts.size() < 2:
		return r
	r.resize((pts.size() - 1) * 2)
	for i in range(pts.size() - 1):
		r[i * 2] = pts[i]
		r[i * 2 + 1] = pts[i + 1]
	return r


func centro(id: String) -> Vector2:
	## Centroide aproximado (en píxeles del control) de la pieza más grande de la región (en caché por tamaño).
	_contornos(id)  # valida la caché con la clave actual
	if not _centros_px.has(id):
		_centros_px[id] = _centro_calculado(id)
	return _centros_px[id]


func _centro_calculado(id: String) -> Vector2:
	var mejor: PackedVector2Array = PackedVector2Array()
	for pieza in _piezas.get(id, []):
		if pieza.size() > mejor.size():
			mejor = pieza
	if mejor.is_empty():
		return Vector2.ZERO
	var acc := Vector2.ZERO
	for p in mejor:
		acc += p
	return _transformar(acc / float(mejor.size()))


func _gui_input(event: InputEvent) -> void:
	## Pellizco, rueda, doble toque y arrastre van a MapaZoom; un toque simple (soltar sin arrastrar) elige la región.
	var r := _zoom.gestionar(event, size, self, _al_cambiar_vista)
	if r.get("consumido", false):
		accept_event()
	if r.has("toque"):
		for rt in _rotulos:  # tocar el nombre de una región la elige (área ≥ 44 px)
			if (rt[1] as Rect2).has_point(r["toque"]):
				seleccion = String(rt[0])
				queue_redraw()
				region_tocada.emit(seleccion)
				return
		_elegir_en(_cam().affine_inverse() * Vector2(r["toque"]))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _zoom.acercado():  # el control cambió de tamaño con zoom: la vista vuelve a sus límites
		_zoom.limitar(size)
		_al_cambiar_vista()


func _al_cambiar_vista() -> void:
	if _ver_todo == null:
		_ver_todo = Tema.boton_secundario("Ver todo", Tema.CREMA, 44)
		_ver_todo.custom_minimum_size = Vector2(96, 44)
		_ver_todo.pressed.connect(func() -> void: _zoom.ir_a(1.0, size * 0.5, size, self, _al_cambiar_vista))
		add_child(_ver_todo)
	_ver_todo.position = Vector2(8.0, size.y - 52.0)
	_ver_todo.visible = _zoom.acercado()
	queue_redraw()


func _elegir_en(pos: Vector2) -> void:
	var mejor := MapaGeometria.region_en(_banda_y, (pos.y - 8.0) / maxf(1.0, size.y - 16.0))
	if mejor != "":
		seleccion = mejor
		queue_redraw()
		region_tocada.emit(mejor)


func _process(delta: float) -> void:
	## Solo la capa viva se redibuja; con Animaciones apagado queda quieta (dibujada una vez por cambio).
	if _vivo == null or not Movimiento.activo() or not is_visible_in_tree():
		return
	_t += delta
	if Movimiento.toca_redibujar(self, delta):
		_vivo.queue_redraw()


func _dibujar_vivo() -> void:
	## Mapa vivo (dirección visual v4): regiones con tendencia laten en verde o coral, el bastión tiene un pulso
	## dorado, las obras se mecen y las propuestas laten. Todo sigue al golpe de cámara.
	var v := _vivo
	v.draw_set_transform_matrix(_cam())
	var pulso := 0.5 + 0.5 * sin(_t * 3.2)
	var clave := Vector4(size.x, size.y, x_centro_rel, estirar_x)
	if clave != _segs_clave or not is_same(_segs_de, _tendencia):  # los segmentos solo cambian con el tamaño o la tendencia, no cada cuadro
		_segs_clave = clave
		_segs_de = _tendencia
		for sg in [1, -1]:
			var acum := PackedVector2Array()
			for id in _tendencia.keys():
				if int(_tendencia[id]) == sg:
					for pts in _contornos(id):
						if pts.size() >= 9:
							acum.append_array(_segmentos(pts))
			_segs_tendencia[sg] = acum
	for signo in [1, -1]:  # regiones que suben y que bajan: una llamada de dibujo por color
		var segs: PackedVector2Array = _segs_tendencia.get(signo, PackedVector2Array())
		if not segs.is_empty():
			v.draw_multiline(segs, Color(Tema.bien() if signo > 0 else Tema.mal(), 0.25 + 0.55 * pulso), 2.0 + 1.5 * pulso, false)
	if bastion != "" and _banda_y.has(bastion):
		var cb := centro(bastion) + Vector2(0.0, 12.0)
		var k := fmod(_t, 2.2) / 2.2
		v.draw_arc(cb, 5.0 + 16.0 * k, 0.0, TAU, 32, Color(Tema.ORO, 0.8 * (1.0 - k)), 2.0, true)
		v.draw_circle(cb, 3.5 + 0.8 * pulso, Tema.ORO)
		v.draw_arc(cb, 3.5 + 0.8 * pulso, 0.0, TAU, 20, Tema.OCEANO, 1.2, true)
	for id in obras.keys():
		if int(obras[id]) > 0 and _banda_y.has(id):
			var c := centro(id) + Vector2(10.0, -2.0 * sin(_t * 2.4 + float(id.length())))
			v.draw_circle(c, 11.0, Tema.OCEANO)
			v.draw_circle(c, 9.5, Tema.ORO)
			v.draw_string(Tema.fuente_titulo(), c + Vector2(-9.5, 4.5), str(int(obras[id])), HORIZONTAL_ALIGNMENT_CENTER, 19.0, 13, Tema.TINTA)
	for id in propuestas.keys():
		if bool(propuestas[id]) and _banda_y.has(id):
			var c2 := centro(id) + Vector2(-12.0, -2.0)
			var e := 1.0 + 0.12 * pulso
			v.draw_circle(c2, 11.0 * e, Tema.CREMA)
			v.draw_circle(c2, 9.5 * e, Tema.ROJO)
			v.draw_colored_polygon(PackedVector2Array([c2 + Vector2(-5, 1), c2 + Vector2(0, -5), c2 + Vector2(5, 1)]), Tema.TEXTO)
			v.draw_rect(Rect2(c2 + Vector2(-3.5, 1), Vector2(7, 5)), Tema.TEXTO)
	_fuegos = FuegosMapa.dibujar(v, _fuegos, _t, centro)  # obras terminadas (fuegos_mapa.gd)
	v.draw_set_transform_matrix(Transform2D.IDENTITY)
