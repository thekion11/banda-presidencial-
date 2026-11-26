class_name LeyendaMetro
extends VBoxContainer
## Leyenda interactiva de las líneas de Metro: una ficha por línea (toca para ocultarla o mostrarla y enfocarte en el resto)
## y un botón para ocultarlas o mostrarlas todas. El estado es común a todos los mapas (UrbanoBase.ocultas).

signal cambiado

var _fichas: Dictionary = {}  # id -> Button
var _todas: Button
var _nota: Label
var oscuro: bool = false  # true sobre fondo oscuro (Comité)
var compacta: bool = false  # una sola fila que se desliza de lado (mapa urbano: deja más alto al mapa, como la maqueta)
var notas_aparte: Container = null  # si se da, las notas de líneas futuras y propias van ahí (p. ej. bajo el mapa)


func _init() -> void:
	add_theme_constant_override("separation", 4)


func _ready() -> void:
	var cab := HBoxContainer.new()
	_nota = Tema.etiqueta_corta("Toca: ocultar · mantén: solo esa", 11, Tema.TEXTO_SUAVE if oscuro else Tema.GRIS_CLARO, false, 600)
	_nota.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nota.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cab.add_child(_nota)
	_todas = Tema.boton("", Color.WHITE, Tema.TINTA, 11, 44)
	_todas.custom_minimum_size = Vector2(112, 44)
	_todas.pressed.connect(_alternar_todas)
	cab.add_child(_todas)
	add_child(cab)
	var fila: Container = HFlowContainer.new()  # si hay más de 7 líneas (las del jugador), las fichas pasan a una segunda fila
	fila.add_theme_constant_override("h_separation", 2)
	fila.add_theme_constant_override("v_separation", 4)
	if compacta:
		fila = HBoxContainer.new()
		fila.add_theme_constant_override("separation", 2)
	for l in UrbanoBase.ids_lineas():
		var b := Button.new()
		b.custom_minimum_size = Vector2(44, 44)
		b.text = UrbanoBase.nombre_corto(String(l["id"]))
		b.add_theme_font_override("font", Tema.fuente_titulo())
		b.add_theme_font_size_override("font_size", 14)
		b.focus_mode = Control.FOCUS_NONE
		var id := String(l["id"])
		var estado := {"largo": false, "abajo": false, "n": 0}
		b.button_down.connect(func() -> void:
			estado["largo"] = false
			estado["abajo"] = true
			estado["n"] = int(estado["n"]) + 1
			var mi_pulsacion: int = estado["n"]  # un temporizador de una pulsación anterior no debe actuar sobre la actual
			var t := get_tree().create_timer(0.45)
			t.timeout.connect(func() -> void:
				if estado["abajo"] and int(estado["n"]) == mi_pulsacion:  # pulsación larga: deja visible solo esta línea
					estado["largo"] = true
					UrbanoBase.solo_linea(id)
					_pintar()
					cambiado.emit()))
		b.button_up.connect(func() -> void: estado["abajo"] = false)
		b.pressed.connect(func() -> void:
			if estado["largo"]:
				estado["largo"] = false
				return
			UrbanoBase.alternar_linea(id)
			_pintar()
			cambiado.emit())
		_fichas[id] = b
		fila.add_child(b)
	if compacta:
		var desliza := ScrollContainer.new()
		desliza.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		desliza.custom_minimum_size = Vector2(0, 44)
		desliza.add_child(fila)
		add_child(desliza)
	else:
		add_child(fila)
	var destino: Container = notas_aparte if notas_aparte != null else self
	var futuras: Array[String] = []
	for l in UrbanoBase.datos().get("metro", []):
		if bool(l.get("futuro", false)):
			futuras.append("%s %s (%s)" % [l["id"], "abierta" if UrbanoBase.abierta(l) else String(l["estado"]), String(l["apertura"])])
	if not futuras.is_empty():
		destino.add_child(Tema.etiqueta(" · ".join(futuras), 10, Tema.TEXTO_SUAVE if oscuro else Tema.GRIS_CLARO, false, 600))
	for ln in UrbanoBase.propias:  # estado de cada línea creada por el jugador
		var txt := "%s · %s · %s" % [ln["id"], String(ln["nombre"]), "operativa" if ln["estado"] == "operativa" else "en construcción"]
		destino.add_child(Tema.etiqueta(txt, 10, Tema.TEXTO_SUAVE if oscuro else Tema.GRIS_CLARO, false, 600))
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
		var tinta := color.darkened(0.25) if oculta else UrbanoBase.tinta_sobre(id)
		for e in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(e, Tema.caja(fondo, 12, borde, 3))
		for e in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(e, tinta)
		b.tooltip_text = "Línea %s: %s" % [UrbanoBase.nombre_corto(id), "oculta" if oculta else "visible"]
		b.text = UrbanoBase.nombre_corto(id) + (" ×" if oculta else "")  # «×» está en Space Grotesk; «✕» no estaba en ninguna fuente embebida
	var todas_ocultas := UrbanoBase.ocultas.size() >= _fichas.size()
	_todas.text = "Mostrar todas" if todas_ocultas else "Ocultar todas"
