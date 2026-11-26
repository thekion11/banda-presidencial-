class_name CambioMando
extends Control
## Cambio de mando (dirección visual v4): al ganar la elección, antes del primer día de gobierno, la banda
## presidencial (azul, crema y rojo con filo dorado, en la paleta congelada) cruza la pantalla sobre La Moneda y
## la piocha dorada aparece en el cruce. Se va sola en ~3,5 s o al tocarla. Solo presentación: el motor ya inició
## el gobierno. Sin animaciones no aparece y `al_terminar` corre al instante.

const DURACION := 3.6

var fecha: String = ""
var partido: String = ""
var al_terminar: Callable
var _avance: float = 0.0
var _piocha: float = 0.0
var _saliendo: bool = false


static func mostrar(capa: Control, p_fecha: String, p_partido: String, fin: Callable) -> void:
	if not Movimiento.activo():
		Musica.etapa("gobierno")
		fin.call()
		return
	Musica.etapa("gobierno")  # empieza el mandato
	var c := CambioMando.new()
	c.fecha = p_fecha
	c.partido = p_partido
	c.al_terminar = fin
	capa.add_child(c)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_salir())
	add_child(Tema.fondo_hero("politica", 0.7, 0.35, "res://game/arte/marca/portada.jpg"))
	var banda := Control.new()
	banda.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banda.draw.connect(_dibujar_banda.bind(banda))
	add_child(banda)
	var motas := Particulas.new()
	motas.cantidad = 30
	add_child(motas)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 24
	col.offset_right = -24
	col.offset_top = 540
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	col.add_child(Tema.etiqueta(("%s · CONGRESO PLENO" % fecha).to_upper(), 11, Tema.ORO, true))
	col.add_child(Tema.etiqueta("Asumes la Presidencia de la República", 28, Tema.TEXTO, true))
	if partido != "":
		col.add_child(Tema.etiqueta("Comienza el gobierno de %s. Tienes cuatro años." % partido, 14, Tema.TEXTO_SUAVE))
	col.add_child(Tema.etiqueta("Toca para comenzar", 11, Tema.TEXTO_SUAVE))
	Movimiento.escalonar(col, 1.1, 0.12)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.35)
	tw.tween_method(func(t: float) -> void:
		_avance = t
		banda.queue_redraw(), 0.0, 1.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		Feedback.sonar("exito")
		Feedback.vibrar(40))
	tw.tween_method(func(t: float) -> void:
		_piocha = t
		banda.queue_redraw(), 0.0, 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(DURACION - 1.7)
	tw.tween_callback(_salir)


func _dibujar_banda(b: Control) -> void:
	## Banda en diagonal (de arriba a la izquierda hacia abajo a la derecha) que se despliega con `_avance`.
	var a := Vector2(-40.0, 90.0)
	var z := Vector2(Tema.ANCHO + 40.0, 470.0)
	var fin := a.lerp(z, _avance)
	var dir := (z - a).normalized()
	var nor := Vector2(-dir.y, dir.x)
	var ancho := 22.0
	var franjas: Array[Color] = [Tema.PANEL, Tema.CREMA, Tema.ROJO]
	b.draw_colored_polygon(PackedVector2Array([a - nor * (ancho * 1.5 + 3.0), fin - nor * (ancho * 1.5 + 3.0), fin + nor * (ancho * 1.5 + 3.0), a + nor * (ancho * 1.5 + 3.0)]), Tema.ORO)
	for i in range(3):
		var o0 := nor * (-ancho * 1.5 + ancho * float(i))
		var o1 := nor * (-ancho * 1.5 + ancho * float(i + 1))
		b.draw_colored_polygon(PackedVector2Array([a + o0, fin + o0, fin + o1, a + o1]), franjas[i])
	if _piocha <= 0.0:
		return
	var c := a.lerp(z, 0.62)  # la piocha: estrella dorada de cinco puntas sobre la banda
	var r := 34.0 * _piocha
	b.draw_circle(c, r + 5.0, Color(Tema.ORO, 0.35))
	b.draw_circle(c, r, Tema.ORO)
	b.draw_circle(c, r * 0.82, Color("#E3A92A"))
	var pts := PackedVector2Array()
	for k in range(10):
		var ang := -PI * 0.5 + PI * float(k) / 5.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * (r * 0.62 if k % 2 == 0 else r * 0.26))
	b.draw_colored_polygon(pts, Tema.CREMA)


func _salir() -> void:
	if _saliendo:
		return
	_saliendo = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func() -> void:
		var fin := al_terminar
		queue_free()
		if fin.is_valid():
			fin.call())
