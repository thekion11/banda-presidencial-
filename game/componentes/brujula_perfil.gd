class_name BrujulaPerfil
extends Control
## Brújula del perfil ideológico (P5/P6 del video de prueba): usa el espacio bajo las preguntas del test para
## mostrar dónde quedas en los dos ejes que miden las respuestas (data/ideologia.json):
## horizontal = económico (más Estado ← → más mercado), vertical = institucional (movilización ↓ ↑ vía institucional).
## Las zonas de los 6 perfiles se dibujan tenues; la tuya se ilumina. El punto se desliza tras cada respuesta.

var perfiles: Array = []
var desde: Vector2 = Vector2.ZERO  # posición antes de la última respuesta (ejes de -1 a 1)
var hasta: Vector2 = Vector2.ZERO
var nombre: String = ""
var vacio: bool = true
var _t: float = 1.0


static func crear(p_perfiles: Array, p_desde: Vector2, p_hasta: Vector2, p_nombre: String, p_vacio: bool) -> BrujulaPerfil:
	var b := BrujulaPerfil.new()
	b.perfiles = p_perfiles
	b.desde = p_desde
	b.hasta = p_hasta
	b.nombre = p_nombre
	b.vacio = p_vacio
	b.custom_minimum_size = Vector2(0, 116 if Tema.pantalla_baja() else 150)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _ready() -> void:
	if Movimiento.activo() and not desde.is_equal_approx(hasta):
		_t = 0.0
		create_tween().tween_method(func(t: float) -> void:
			_t = t
			queue_redraw(), 0.0, 1.0, 0.7).set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _plano() -> Rect2:
	var alto := size.y - 34.0
	var ancho := minf(size.x - 120.0, alto * 1.6)
	return Rect2(Vector2((size.x - ancho) * 0.5, 4.0), Vector2(ancho, alto))


func _a_px(r: Rect2, e: Vector2) -> Vector2:
	return Vector2(r.position.x + (e.x + 1.0) * 0.5 * r.size.x, r.position.y + (1.0 - (e.y + 1.0) * 0.5) * r.size.y)


func _draw() -> void:
	var r := _plano()
	draw_style_box(Tema.caja(Color(0.06, 0.18, 0.3, 0.6), 10, Color("#2B5D86"), 1), r.grow(2.0))
	for p in perfiles:  # zonas de los perfiles
		var a := _a_px(r, Vector2(float(p["eco_min"]), float(p["inst_max"])))
		var b := _a_px(r, Vector2(float(p["eco_max"]), float(p["inst_min"])))
		var mio := String(p["nombre"]) == nombre and not vacio
		draw_rect(Rect2(a, b - a), Color(Tema.ORO, 0.22) if mio else Color(1, 1, 1, 0.04))
		if mio:
			draw_rect(Rect2(a, b - a), Color(Tema.ORO, 0.8), false, 1.5)
	var c := r.get_center()
	draw_line(Vector2(r.position.x, c.y), Vector2(r.end.x, c.y), Color(1, 1, 1, 0.25), 1.0)
	draw_line(Vector2(c.x, r.position.y), Vector2(c.x, r.end.y), Color(1, 1, 1, 0.25), 1.0)
	var f := Tema.fuente_texto(600)
	var fs := 10
	draw_string(f, Vector2(r.position.x - 56.0, c.y + 4.0), "Estado", HORIZONTAL_ALIGNMENT_RIGHT, 50.0, fs, Tema.TEXTO_SUAVE)
	draw_string(f, Vector2(r.end.x + 6.0, c.y + 4.0), "Mercado", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Tema.TEXTO_SUAVE)
	draw_string(f, Vector2(c.x - 70.0, r.position.y - 0.0 + 12.0), "Vía institucional", HORIZONTAL_ALIGNMENT_CENTER, 140.0, fs, Tema.TEXTO_SUAVE)
	draw_string(f, Vector2(c.x - 70.0, r.end.y - 4.0), "Movilización", HORIZONTAL_ALIGNMENT_CENTER, 140.0, fs, Tema.TEXTO_SUAVE)
	if not vacio:
		var p0 := _a_px(r, desde)
		var p1 := _a_px(r, desde.lerp(hasta, _t))
		draw_line(p0, p1, Color(Tema.ORO, 0.5), 2.0, true)
		draw_circle(p1, 9.0, Color(Tema.ORO, 0.25))
		draw_circle(p1, 5.5, Tema.ORO)
		draw_arc(p1, 5.5, 0.0, TAU, 20, Tema.OCEANO, 1.5, true)
	var leyenda := "Cada respuesta mueve tu punto. Tu perfil es la zona dorada." if not vacio else "Responde y verás dónde queda tu partido en estos dos ejes."
	draw_string(Tema.fuente_texto(500), Vector2(0.0, size.y - 8.0), leyenda, HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Tema.TEXTO_SUAVE)
