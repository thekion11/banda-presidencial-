class_name TelonSemana
extends Control
## Telón entre semanas (dirección visual v4): al terminar la semana baja un telón con «Semana 6 → 7» y cada
## indicador contando de su valor anterior al nuevo, con flecha y color. Se va solo (o al tocarlo) y entonces
## siguen los eventos de la semana nueva. Sin animaciones no aparece: `al_terminar` corre al instante.

const IND := [["aprobacion", "Aprobación"], ["capital", "Capital político"], ["cohesion", "Cohesión"], ["fiscal", "Fiscal"]]
const ESPERA := 1.7

var titulo_antes: String = ""
var titulo_despues: String = ""
var subtitulo: String = ""
var antes: Dictionary = {}
var despues: Dictionary = {}
var oposicion: bool = false
var al_terminar: Callable
var _panel: Control
var _saliendo: bool = false


static func mostrar(capa: Control, p_antes: Array, p_despues: Array, ind_antes: Dictionary, ind_despues: Dictionary, p_oposicion: bool, fin: Callable) -> void:
	## p_antes / p_despues: [título, subtítulo] de la cabecera antes y después de avanzar.
	if not Movimiento.activo():
		fin.call()
		return
	var t := TelonSemana.new()
	t.titulo_antes = String(p_antes[0])
	t.titulo_despues = String(p_despues[0])
	t.subtitulo = String(p_despues[1])
	t.antes = ind_antes
	t.despues = ind_despues
	t.oposicion = p_oposicion
	t.al_terminar = fin
	capa.add_child(t)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_salir())
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("#154F7A"), Tema.OCEANO, Color("#07182A")])
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.3)
	gt.fill_to = Vector2(0.5, 1.1)
	var fondo := TextureRect.new()
	fondo.texture = gt
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(fondo)
	var filo := ColorRect.new()  # borde dorado inferior del telón
	filo.color = Tema.ORO
	filo.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	filo.offset_top = -4
	filo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(filo)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 28
	col.offset_right = -28
	col.offset_top = 210
	col.add_theme_constant_override("separation", 12)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(col)
	col.add_child(Tema.etiqueta("FIN DE LA SEMANA", 12, Tema.ORO, true))
	var tit := Tema.etiqueta(titulo_antes, 30, Tema.TEXTO_SUAVE, true)
	col.add_child(tit)
	col.add_child(Tema.etiqueta(subtitulo, 13, Tema.TEXTO_SUAVE))
	var sep := ColorRect.new()
	sep.color = Color(Tema.ORO, 0.5)
	sep.custom_minimum_size = Vector2(0, 2)
	col.add_child(sep)
	var filas := VBoxContainer.new()
	filas.add_theme_constant_override("separation", 10)
	col.add_child(filas)
	for par in IND:
		var k: String = "rival" if oposicion and par[0] == "fiscal" else String(par[0])
		filas.add_child(_fila("Rival" if k == "rival" else String(par[1]), float(antes.get(k, 0.0)), float(despues.get(k, 0.0)), k == "rival"))
	col.add_child(Tema.etiqueta("Toca para continuar", 11, Tema.TEXTO_SUAVE))
	_panel.position.y = -Tema.ALTO
	var tw := create_tween()
	tw.tween_property(_panel, "position:y", 0.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:  # el título cambia a la semana nueva con un latido
		tit.text = titulo_despues
		tit.add_theme_color_override("font_color", Tema.TEXTO)
		Movimiento.latido(tit, 1.08))
	Movimiento.escalonar(filas, 0.4, 0.08)
	tw.tween_interval(ESPERA)
	tw.tween_callback(_salir)


func _fila(nombre: String, a: float, d: float, invertido: bool) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var n := Tema.etiqueta_corta(nombre, 14, Tema.TEXTO, false, 600)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	var v := Tema.etiqueta_corta("", 20, Tema.TEXTO, true)
	Movimiento.contar(v, roundf(d), func(x: float) -> String: return str(roundi(x)), roundf(a), 0.9, 0.45)
	h.add_child(v)
	var delta := roundi(d) - roundi(a)
	var bueno := (delta > 0) != invertido
	var txt := "= 0" if delta == 0 else Tema.signo(float(delta))
	var dl := Tema.etiqueta_corta(txt, 14, Tema.TEXTO_SUAVE if delta == 0 else (Tema.SUBE if bueno else Tema.BAJA), true)
	dl.custom_minimum_size = Vector2(58, 0)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(dl)
	return h


func _salir() -> void:
	if _saliendo:
		return
	_saliendo = true
	var tw := create_tween()
	tw.tween_property(_panel, "position:y", -Tema.ALTO, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		var fin := al_terminar
		queue_free()
		if fin.is_valid():
			fin.call())
