class_name EscenaTV
extends Control
## Escenografía de los eventos con escena (dirección visual v4): debates y entrevistas por rondas.
## Televisión y debates: focos que barren, marco de cámara, insignia «EN VIVO» que late y puntos de ronda.
## Radio: insignia «AL AIRE» y ondas que salen del micrófono. Va detrás del texto del evento; solo presentación.
## Sin animaciones se dibuja quieta (sin barrido ni latido).
## Pedido del usuario del 27-nov-2026 («Entrevistas, campaña, debates, campaña en TV»): en el debate, dos atriles (tú y el
## rival) y un medidor de reacción del público; en la entrevista, dos sillas, zócalo y cinta de titulares; en la franja
## electoral, barras de color al entrar, insignia «FRANJA ELECTORAL» y el reloj del spot. Todo de fondo, tenue.

var nombre: String = ""
var tipo: String = ""  # "franja" para los eventos de la franja electoral (se reconocen por su id)
var titular: String = ""  # texto de la cinta de titulares de la entrevista
var ronda: int = 1
var rondas: int = 1
var _t: float = 0.0


static func crear(escena: Dictionary) -> EscenaTV:
	var e := EscenaTV.new()
	e.tipo = String(escena.get("tipo", ""))
	e.titular = String(escena.get("titular", ""))
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
	if tipo == "franja":
		_franja(w, h)
	elif nombre.to_lower().contains("entrevista"):
		_entrevista(w, h)
	elif not _radio():
		_debate(w, h)
	var vivo := "FRANJA ELECTORAL" if tipo == "franja" else ("AL AIRE" if _radio() else "EN VIVO")  # insignia que late
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


func _silueta(base: Vector2, escala: float, color: Color) -> void:
	draw_circle(base + Vector2(0.0, -46.0) * escala, 13.0 * escala, color)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-24.0, -10.0) * escala, base + Vector2(-16.0, -32.0) * escala, base + Vector2(16.0, -32.0) * escala, base + Vector2(24.0, -10.0) * escala]), color)


func _debate(w: float, h: float) -> void:
	## Dos atriles al pie (tú en dorado, el rival en rojo) y el medidor de reacción del público que oscila.
	var y := h * 0.74
	for lado: float in [-1.0, 1.0]:
		var x := w * 0.5 + lado * w * 0.3
		var col := Color(Tema.ORO if lado < 0.0 else Tema.ROJO, 0.16)
		_silueta(Vector2(x, y), 1.0, col)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 26.0, y - 10.0), Vector2(x + 26.0, y - 10.0), Vector2(x + 20.0, y + 36.0), Vector2(x - 20.0, y + 36.0)]), col)
	var r := Rect2(w * 0.5 - 50.0, y - 30.0, 100.0, 6.0)  # reacción del público, entre los atriles: sube y baja
	draw_string(Tema.fuente_texto(600), Vector2(r.position.x, r.position.y - 6.0), "Reacción del público", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(Tema.CREMA, 0.55))
	var mov := 0.5 + 0.35 * sin(_t * 1.3) + 0.1 * sin(_t * 3.7) if Movimiento.activo() else 0.6
	draw_rect(r, Color(Tema.CREMA, 0.12))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(mov, 0.0, 1.0), r.size.y)), Color(Tema.ORO, 0.45))


func _entrevista(w: float, h: float) -> void:
	## Dos sillas frente a frente, zócalo dorado y cinta de titulares que corre al pie.
	var y := h * 0.72
	_silueta(Vector2(w * 0.3, y), 0.9, Color(Tema.CREMA, 0.12))
	_silueta(Vector2(w * 0.7, y), 0.9, Color(Tema.CREMA, 0.12))
	var cinta := Rect2(0.0, y + 26.0, w, 18.0)
	draw_rect(cinta, Color(Tema.ROJO, 0.35))
	var f := Tema.fuente_texto(600)
	var texto := ("ÚLTIMA HORA · " + titular.to_upper() + " · CAMPAÑA PRESIDENCIAL · ") if titular != "" else "ÚLTIMA HORA · CAMPAÑA PRESIDENCIAL · "
	var ancho := f.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var x0 := -fmod(_t * 40.0, ancho) if Movimiento.activo() else 0.0
	var x := x0
	while x < w:
		draw_string(f, Vector2(x, cinta.position.y + 13.0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(Tema.CREMA, 0.75))
		x += ancho


func _franja(w: float, h: float) -> void:
	## Barras de color que se retiran al entrar (como al comenzar una transmisión) y reloj del spot de 30 segundos.
	var barras := [Tema.CREMA, Tema.ORO, Color("#4CC38A"), Color("#2A6290"), Tema.ROJO, Tema.PANEL, Tema.OCEANO]
	var salida := clampf(_t / 0.8, 0.0, 1.0) if Movimiento.activo() else 1.0
	if salida < 1.0:
		var bw := w / float(barras.size())
		for i in range(barras.size()):
			draw_rect(Rect2(bw * float(i), 0.0, bw + 1.0, h * (1.0 - salida)), Color(barras[i], 0.55 * (1.0 - salida)))
	var r := Rect2(w * 0.5 - 70.0, h * 0.72, 140.0, 6.0)  # reloj del spot, en el espacio libre sobre las opciones
	draw_string(Tema.fuente_texto(600), Vector2(r.position.x, r.position.y - 6.0), "Spot al aire", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(Tema.CREMA, 0.6))
	var avance := fmod(_t / 6.0, 1.0) if Movimiento.activo() else 0.5
	draw_rect(r, Color(Tema.CREMA, 0.12))
	draw_rect(Rect2(r.position, Vector2(r.size.x * avance, r.size.y)), Color(Tema.ROJO, 0.6))
	var f := Tema.fuente_texto(600)
	draw_string(f, Vector2(r.end.x + 6.0, r.position.y + 7.0), "0:%02d" % roundi(avance * 30.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(Tema.CREMA, 0.7))

