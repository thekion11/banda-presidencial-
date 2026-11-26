class_name EscenaTV
extends Control
## Escenografía de los eventos con escena (dirección visual v4): debates y entrevistas por rondas.
## Televisión y debates: focos que barren, marco de cámara, insignia «EN VIVO» que late y puntos de ronda.
## Radio: insignia «AL AIRE» y ondas que salen del micrófono. Va detrás del texto del evento; solo presentación.
## Sin animaciones se dibuja quieta (sin barrido ni latido).

var nombre: String = ""
var ronda: int = 1
var rondas: int = 1
var _t: float = 0.0


static func crear(escena: Dictionary) -> EscenaTV:
	var e := EscenaTV.new()
	e.nombre = String(escena.get("nombre", ""))
	e.ronda = int(escena.get("ronda", 1))
	e.rondas = int(escena.get("rondas", 1))
	return e


func _radio() -> bool:
	return nombre.to_lower().contains("radio")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(Movimiento.activo())


func _process(delta: float) -> void:
	_t += delta
	if Movimiento.toca_redibujar(self, delta):
		queue_redraw()


func _draw() -> void:
	var w := size.x if size.x > 0.0 else Tema.ANCHO
	var h := size.y if size.y > 0.0 else Tema.ALTO
	if _radio():
		_ondas(Vector2(w * 0.5, 320.0))  # en el espacio libre bajo la descripción
	else:
		for lado: float in [-1.0, 1.0]:  # dos focos desde las esquinas superiores que barren lento
			var origen := Vector2(w * 0.5 + lado * (w * 0.5 + 10.0), -10.0)
			var ang := PI * 0.5 - lado * (0.55 + 0.12 * sin(_t * 0.7 + (0.0 if lado < 0.0 else 1.7)))
			var dir := Vector2(cos(ang), sin(ang))
			var nor := Vector2(-dir.y, dir.x)
			var largo := h * 0.75
			var punta := origen + dir * largo
			draw_colored_polygon(PackedVector2Array([origen - nor * 6.0, punta - nor * 120.0, punta + nor * 120.0, origen + nor * 6.0]),
				Color(1.0, 0.95, 0.8, 0.12))
			draw_colored_polygon(PackedVector2Array([origen - nor * 3.0, punta - nor * 55.0, punta + nor * 55.0, origen + nor * 3.0]),
				Color(1.0, 0.95, 0.8, 0.10))
		var m := 10.0  # marco de visor de cámara en las cuatro esquinas
		for c: Vector2 in [Vector2(m, m), Vector2(w - m, m), Vector2(m, h - m), Vector2(w - m, h - m)]:
			var sx := 1.0 if c.x < w * 0.5 else -1.0
			var sy := 1.0 if c.y < h * 0.5 else -1.0
			draw_line(c, c + Vector2(22.0 * sx, 0.0), Color(Tema.CREMA, 0.55), 2.0)
			draw_line(c, c + Vector2(0.0, 22.0 * sy), Color(Tema.CREMA, 0.55), 2.0)
	var vivo := "AL AIRE" if _radio() else "EN VIVO"  # insignia que late
	var f := Tema.fuente_titulo()
	var ancho := f.get_string_size(vivo, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 26.0
	var r := Rect2(16.0, 14.0, ancho, 22.0)
	draw_style_box(Tema.caja(Tema.ROJO, 6), r)
	var a: float = 0.55 + 0.45 * sin(_t * 4.0) if Movimiento.activo() else 1.0
	draw_circle(r.position + Vector2(10.0, 11.0), 4.0, Color(Tema.CREMA, a))
	draw_string(f, r.position + Vector2(18.0, 15.5), vivo, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Tema.TEXTO)
	for k in range(rondas):  # puntos de ronda a la derecha
		var p := Vector2(w - 22.0 - 16.0 * float(rondas - 1 - k), 25.0)
		if k < ronda:
			draw_circle(p, 5.0, Tema.ORO)
		else:
			draw_arc(p, 5.0, 0.0, TAU, 20, Color(Tema.ORO, 0.6), 1.5, true)


func _ondas(c: Vector2) -> void:
	## Micrófono de radio con ondas que salen hacia los lados.
	draw_rect(Rect2(c + Vector2(-9.0, -22.0), Vector2(18.0, 30.0)), Color(Tema.CREMA, 0.16))
	draw_circle(c + Vector2(0.0, -22.0), 9.0, Color(Tema.CREMA, 0.16))
	draw_line(c + Vector2(0.0, 8.0), c + Vector2(0.0, 22.0), Color(Tema.CREMA, 0.16), 3.0)
	for k in range(3):
		var fase: float = fmod(_t * 0.6 + float(k) / 3.0, 1.0) if Movimiento.activo() else (float(k) + 1.0) / 4.0
		var rad := 26.0 + 70.0 * fase
		var col := Color(Tema.ORO, 0.35 * (1.0 - fase))
		draw_arc(c + Vector2(0.0, -10.0), rad, -0.6, 0.6, 20, col, 2.0, true)
		draw_arc(c + Vector2(0.0, -10.0), rad, PI - 0.6, PI + 0.6, 20, col, 2.0, true)
