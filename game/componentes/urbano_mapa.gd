class_name UrbanoMapa
extends UrbanoVista
## Mapa urbano de Gran Santiago con cartografía real de OpenStreetMap (tema claro): calles atenuadas, río, parques, Metro,
## propuesta punteada y obras con porcentaje. Se acerca con pellizco, rueda, doble toque o botones y se arrastra con el dedo;
## un toque sobre una línea de Metro la oculta.

signal cambio_linea

var datos: Dictionary = {}
var propuesta: Array = []  # trazado de la propuesta abierta/aprobada (plano 0..1)
var marcadores: Array = []  # [{"pct": int, "color": Color}]
var mostrar_metro: bool = true
var trazo: float = 1.0:
	set(v):
		trazo = v
		queue_redraw()
var _estacion: Dictionary = {}  # estación tocada (burbuja con nombre y líneas)


func _init() -> void:
	clip_contents = true


func _ready() -> void:
	_iniciar_vista()


func _vista_toque(pos: Vector2) -> void:
	if not mostrar_metro:
		return
	var local := (pos - pan) / zoom
	var est := UrbanoBase.estacion_en(local, size, MARGEN, 12.0 / zoom) if zoom >= 1.8 else {}  # sin zoom las estaciones quedan a ~13 px y taparían toda la línea
	if not est.is_empty():  # un toque sobre una estación muestra su nombre y sus líneas
		_estacion = est if _estacion.is_empty() or _estacion["n"] != est["n"] else {}
		queue_redraw()
		return
	if not _estacion.is_empty():
		_estacion = {}
		queue_redraw()
	var id := UrbanoBase.linea_en(local, size, MARGEN, 16.0 / zoom)
	if id != "":
		UrbanoBase.alternar_linea(id)
		queue_redraw()
		cambio_linea.emit()


func cargar(_p_datos: Dictionary = {}) -> void:
	datos = UrbanoBase.datos()
	trazo = 0.0
	create_tween().tween_property(self, "trazo", 1.0, 1.0).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	draw_style_box(Tema.caja(Color("#EFEADF"), 16, Tema.BORDE_CLARO, 1), Rect2(Vector2.ZERO, size))
	if datos.is_empty():
		return
	var esc := (1.0 + 0.35 * (zoom - 1.0)) / zoom  # el grosor crece menos que el mapa: las líneas no se vuelven brochazos
	draw_set_transform(pan, 0.0, Vector2(zoom, zoom))
	UrbanoBase.dibujar(self, size, MARGEN, mostrar_metro, esc, 1.0 if mostrar_metro else 0.0, not _en_movimiento)
	if propuesta.size() >= 2:
		var pp := PackedVector2Array()
		for q in propuesta:
			pp.append(UrbanoBase.a_px(q, size, MARGEN))
		pp = UrbanoTrazo.redondear(pp, UrbanoTrazo.metros_a_px(300.0, size, MARGEN), 5)
		var hasta := maxi(2, int(ceil(float(pp.size()) * trazo)))
		var vis := pp.slice(0, hasta)
		UrbanoTrazo.trazo(self, vis, Color.WHITE, 6.6 * esc)
		UrbanoTrazo.discontinua(self, vis, Tema.TINTA, 4.2 * esc, 10.0 * esc, 7.0 * esc)  # tinta oscura: no se confunde con ninguna línea
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var reservados: Array[Rect2] = []
	if mostrar_metro:
		reservados.append_array(UrbanoRotulos.fichas(self, size, MARGEN, zoom, pan))
	var mk: Array = datos["marcadores"]
	for i in range(mini(mk.size(), marcadores.size())):
		var c := UrbanoBase.a_px(mk[i], size, MARGEN) * zoom + pan
		reservados.append(Rect2(c - Vector2(18, 18), Vector2(36, 36)))
	UrbanoRotulos.etiquetas(self, size, MARGEN, zoom, pan, reservados)
	for i in range(mini(mk.size(), marcadores.size())):
		var c2 := UrbanoBase.a_px(mk[i], size, MARGEN) * zoom + pan
		var m: Dictionary = marcadores[i]
		draw_circle(c2, 15.0, Color(1, 1, 1, 0.92))
		draw_circle(c2, 13.0, m["color"])
		draw_string(Tema.fuente_titulo(), c2 + Vector2(-13, 4.5), "%d%%" % int(m["pct"]), HORIZONTAL_ALIGNMENT_CENTER, 26.0, 11, Tema.TEXTO)
	if not _estacion.is_empty():
		_dibujar_burbuja()
	if propuesta.size() >= 2:
		var leyenda := Rect2(10, size.y - 34, 96, 24)
		draw_style_box(Tema.caja(Color("#FBF7EC"), 8, Tema.BORDE_CLARO, 1), leyenda)
		draw_dashed_line(leyenda.position + Vector2(8, 12), leyenda.position + Vector2(28, 12), Tema.TINTA, 4.0, 6.0)
		draw_string(Tema.fuente_texto(500), leyenda.position + Vector2(33, 16), "Propuesta", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TINTA)
	draw_string(Tema.fuente_texto(400), Vector2(size.x - 232, size.y - 14), "© colaboradores de OpenStreetMap (ODbL)", HORIZONTAL_ALIGNMENT_RIGHT, 222, 9, Color("#6A7684"))


func _dibujar_burbuja() -> void:
	## Burbuja con el nombre de la estación y una pastilla de color por línea que la sirve.
	var p: Vector2 = Vector2(_estacion["p"]) * zoom + pan
	var f := Tema.fuente_titulo()
	var nombre := String(_estacion["n"])
	var ancho := maxf(f.get_string_size(nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 20.0, 34.0 + 26.0 * float(_estacion["l"].size()))
	var caja := Rect2(clampf(p.x - ancho * 0.5, 4.0, size.x - ancho - 4.0), p.y - 56.0, ancho, 44.0)
	if caja.position.y < 4.0:
		caja.position.y = p.y + 14.0
	draw_circle(p, 9.0, Color(1, 1, 1, 0.95))
	draw_circle(p, 6.5, Tema.TINTA)
	draw_style_box(Tema.caja(Color("#FBF7EC"), 10, Tema.TINTA, 2), caja)
	draw_string(f, caja.position + Vector2(10, 17), nombre, HORIZONTAL_ALIGNMENT_LEFT, ancho - 16.0, 12, Tema.TINTA)
	var x := caja.position.x + 10.0
	for lid in _estacion["l"]:
		var col := UrbanoBase.color_linea(String(lid))
		draw_circle(Vector2(x + 9.0, caja.position.y + 31.0), 9.0, col)
		draw_string(f, Vector2(x + 1.0, caja.position.y + 35.0), UrbanoBase.nombre_corto(String(lid)), HORIZONTAL_ALIGNMENT_CENTER, 16.0, 10, Tema.TINTA if lid == "L2" else Color.WHITE)
		x += 24.0
