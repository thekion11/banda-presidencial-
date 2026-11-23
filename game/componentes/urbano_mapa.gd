class_name UrbanoMapa
extends Control
## Mapa urbano de Gran Santiago con cartografía real de OpenStreetMap (tema claro): calles, río, parques, Metro,
## propuesta punteada y obras con porcentaje.

const MARGEN := Vector2(8, 8)

var datos: Dictionary = {}
var propuesta: Array = []  # trazado de la propuesta abierta/aprobada (plano 0..1)
var marcadores: Array = []  # [{"pct": int, "color": Color}]
var mostrar_metro: bool = true
var trazo: float = 1.0:
	set(v):
		trazo = v
		queue_redraw()


func _init() -> void:
	clip_contents = true


func cargar(_p_datos: Dictionary = {}) -> void:
	datos = UrbanoBase.datos()
	trazo = 0.0
	create_tween().tween_property(self, "trazo", 1.0, 1.0).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	draw_style_box(Tema.caja(Color("#EFEADF"), 16, Tema.BORDE_CLARO, 1), Rect2(Vector2.ZERO, size))
	if datos.is_empty():
		return
	UrbanoBase.dibujar(self, size, MARGEN, mostrar_metro)
	if propuesta.size() >= 2:
		var pp := PackedVector2Array()
		for q in propuesta:
			pp.append(UrbanoBase.a_px(q, size, MARGEN))
		var hasta := maxi(2, int(ceil(float(pp.size()) * trazo)))
		draw_polyline(pp.slice(0, hasta), Color(1, 1, 1, 0.9), 7.0, true)
		for k in range(hasta - 1):
			draw_dashed_line(pp[k], pp[k + 1], Color("#2B4BA8"), 3.6, 7.0, true)
	var mk: Array = datos["marcadores"]
	for i in range(mini(mk.size(), marcadores.size())):
		var c := UrbanoBase.a_px(mk[i], size, MARGEN)
		var m: Dictionary = marcadores[i]
		draw_circle(c, 15.0, Color(1, 1, 1, 0.92))
		draw_circle(c, 13.0, m["color"])
		draw_string(Tema.fuente_titulo(), c + Vector2(-13, 4.5), "%d%%" % int(m["pct"]), HORIZONTAL_ALIGNMENT_CENTER, 26.0, 11, Tema.TEXTO)
	var leyenda := Rect2(10, size.y - 34, 150, 24)
	draw_style_box(Tema.caja(Color("#FBF7EC"), 8, Tema.BORDE_CLARO, 1), leyenda)
	draw_line(leyenda.position + Vector2(8, 12), leyenda.position + Vector2(24, 12), Tema.ROJO, 3.0)
	draw_string(Tema.fuente_texto(500), leyenda.position + Vector2(28, 16), "Líneas", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TINTA)
	draw_dashed_line(leyenda.position + Vector2(74, 12), leyenda.position + Vector2(92, 12), Color("#2B4BA8"), 3.0, 4.0)
	draw_string(Tema.fuente_texto(500), leyenda.position + Vector2(96, 16), "Propuesta", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TINTA)
	draw_string(Tema.fuente_texto(400), Vector2(size.x - 232, size.y - 14), "© colaboradores de OpenStreetMap (ODbL)", HORIZONTAL_ALIGNMENT_RIGHT, 222, 9, Color("#6A7684"))
