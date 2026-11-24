class_name LeyendaMetro
extends VBoxContainer
## Leyenda interactiva de las líneas de Metro: una ficha por línea (toca para ocultarla o mostrarla y enfocarte en el resto)
## y un botón para ocultarlas o mostrarlas todas. El estado es común a todos los mapas (UrbanoBase.ocultas).

signal cambiado

var _fichas: Dictionary = {}  # id -> Button
var _todas: Button
var _nota: Label


func _init() -> void:
	add_theme_constant_override("separation", 4)


func _ready() -> void:
	var cab := HBoxContainer.new()
	_nota = Tema.etiqueta_corta("Líneas de Metro · toca una para ocultarla", 11, Color("#6A7684"), false, 600)
	_nota.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nota.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cab.add_child(_nota)
	_todas = Tema.boton("", Color.WHITE, Tema.TINTA, 11, 44)
	_todas.custom_minimum_size = Vector2(112, 44)
	_todas.pressed.connect(_alternar_todas)
	cab.add_child(_todas)
	add_child(cab)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	for l in UrbanoBase.ids_lineas():
		var b := Button.new()
		b.custom_minimum_size = Vector2(46, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.text = UrbanoBase.nombre_corto(String(l["id"]))
		b.add_theme_font_override("font", Tema.fuente_titulo())
		b.add_theme_font_size_override("font_size", 14)
		b.focus_mode = Control.FOCUS_NONE
		var id := String(l["id"])
		b.pressed.connect(func() -> void:
			UrbanoBase.alternar_linea(id)
			_pintar()
			cambiado.emit())
		_fichas[id] = b
		fila.add_child(b)
	add_child(fila)
	_pintar()


func refrescar() -> void:
	_pintar()


func _alternar_todas() -> void:
	var ocultar := UrbanoBase.ocultas.size() < _fichas.size()
	UrbanoBase.ocultas.clear()
	if ocultar:
		for id in _fichas:
			UrbanoBase.ocultas[id] = true
	_pintar()
	cambiado.emit()


func _pintar() -> void:
	for l in UrbanoBase.ids_lineas():
		var id := String(l["id"])
		var b: Button = _fichas[id]
		var oculta := UrbanoBase.ocultas.has(id)
		var color: Color = l["color"]
		var fondo := Color.WHITE if oculta else color
		var borde := color
		var tinta := color.darkened(0.25) if oculta else (Tema.TINTA if id == "L2" else Color.WHITE)
		for e in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(e, Tema.caja(fondo, 12, borde, 3))
		for e in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(e, tinta)
		b.tooltip_text = "Línea %s: %s" % [UrbanoBase.nombre_corto(id), "oculta" if oculta else "visible"]
		b.text = UrbanoBase.nombre_corto(id) + (" ✕" if oculta else "")
	var todas_ocultas := UrbanoBase.ocultas.size() >= _fichas.size()
	_todas.text = "Mostrar todas" if todas_ocultas else "Ocultar todas"
