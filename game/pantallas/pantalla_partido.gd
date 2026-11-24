class_name PantallaPartido
extends Control
## Test ideológico (8 dilemas) + fundación del partido. Reutiliza los componentes congelados de la maqueta.

signal fundado(partido: Dictionary)

var datos: Dictionary = {}
var _respuestas: Array[Dictionary] = []
var _paso: int = 0
var _contenido: VBoxContainer
var _franja_perfil: Label
var _franja_escanos: Label
var _barra: ColorRect
var _titulo: Label
var _nombre: LineEdit
var _sigla: LineEdit
var _region: OptionButton


func _ready() -> void:
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 0)
	add_child(raiz)
	var cab := VBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_right", 20)
	margen.add_theme_constant_override("margin_top", 44)
	margen.add_child(cab)
	raiz.add_child(margen)
	_titulo = Tema.etiqueta("", 18, Tema.TEXTO, true)
	cab.add_child(_titulo)
	var pista := ColorRect.new()
	pista.color = Tema.PANEL
	pista.custom_minimum_size = Vector2(0, 6)
	cab.add_child(pista)
	_barra = ColorRect.new()
	_barra.color = Tema.ORO
	_barra.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	pista.add_child(_barra)
	var mc := MarginContainer.new()
	mc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mc.add_theme_constant_override("margin_left", 16)
	mc.add_theme_constant_override("margin_right", 16)
	mc.add_theme_constant_override("margin_top", 16)
	raiz.add_child(mc)
	_contenido = VBoxContainer.new()
	_contenido.add_theme_constant_override("separation", 10)
	mc.add_child(_contenido)
	var franja := PanelContainer.new()
	franja.add_theme_stylebox_override("panel", Tema.caja(Tema.CREMA, 0))
	var fv := VBoxContainer.new()
	franja.add_child(fv)
	_franja_perfil = Tema.etiqueta("", 14, Tema.TINTA, true)
	_franja_escanos = Tema.etiqueta("", 11, Tema.TINTA)
	fv.add_child(_franja_perfil)
	fv.add_child(_franja_escanos)
	var pie := Control.new()  # alto fijo: el botón principal queda en la misma posición sea cual sea la métrica del texto
	pie.custom_minimum_size = Vector2(0, 53)
	pie.clip_contents = true
	franja.set_anchors_preset(Control.PRESET_FULL_RECT)
	pie.add_child(franja)
	raiz.add_child(pie)
	_mostrar_pregunta()


func _preguntas() -> Array:
	return datos["ideologia"]["preguntas"]


func _actualizar_franja() -> void:
	var ejes := GeneradorPartido.calcular_ejes(_respuestas)
	if _respuestas.is_empty():
		_franja_perfil.text = "Perfil: sin definir"
		_franja_escanos.text = "Responde para proyectar tu bancada inicial."
		return
	_franja_perfil.text = "Perfil: " + GeneradorPartido.perfil_para(ejes.x, ejes.y, datos["ideologia"])
	_franja_escanos.text = "Proyección: %d de %d escaños en el Senado" % [GeneradorPartido.escanos_para(ejes.x, ejes.y), int(datos["leyes"]["hemiciclo"]["total_senadores"])]


func _limpiar() -> void:
	for h in _contenido.get_children():
		h.queue_free()


func _mostrar_pregunta() -> void:
	_limpiar()
	var total := _preguntas().size()
	_titulo.text = "Fundación de Partido · Pregunta %d de %d" % [_paso + 1, total]
	_barra.anchor_right = float(_paso) / float(total + 1)
	_actualizar_franja()
	var p: Dictionary = _preguntas()[_paso]
	var img := Tema.imagen(String(p.get("arte", "politica")), 150.0, 16.0)
	_contenido.add_child(img)
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", Tema.caja_degradada(Color("#1A4C73"), Color("#133C5C"), 16, Color("#2E6490"), 1))
	tarjeta.add_child(Tema.etiqueta(String(p["texto"]), 17, Tema.TEXTO, true))
	_contenido.add_child(tarjeta)
	var i := 0
	for op in p["opciones"]:
		var b := _boton_opcion(["A", "B", "C"][i], String(op["etiqueta"]))
		b.pressed.connect(_responder.bind(op))
		_contenido.add_child(b)
		b.modulate.a = 0.0
		b.create_tween().tween_property(b, "modulate:a", 1.0, 0.25).set_delay(0.08 * float(i))
		i += 1


func _boton_opcion(letra: String, texto: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 62)
	b.add_theme_stylebox_override("normal", Tema.caja_degradada(Color("#1B4F78"), Color("#0F2F4A"), 18, Color("#3A6E98"), 2))
	b.add_theme_stylebox_override("hover", Tema.caja_degradada(Color("#246190"), Color("#143A5C"), 18, Color("#F2C14E"), 2))
	b.add_theme_stylebox_override("pressed", Tema.caja_degradada(Color("#0F2F4A"), Color("#1B4F78"), 18, Color("#F2C14E"), 2))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12
	h.offset_right = -12
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge := Tema.etiqueta_corta(letra, 15, Tema.TINTA, true)
	badge.add_theme_stylebox_override("normal", Tema.caja_degradada(Color("#FFD76A"), Color("#E3A92A"), 16))
	badge.custom_minimum_size = Vector2(32, 32)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(badge)
	var t := Tema.etiqueta(texto, 13, Tema.TEXTO, false, 600)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)
	b.add_child(h)
	return b


func _responder(op: Dictionary) -> void:
	_respuestas.append(op)
	_paso += 1
	if _paso < _preguntas().size():
		_mostrar_pregunta()
	else:
		_mostrar_fundacion()


func _mostrar_fundacion() -> void:
	_limpiar()
	_titulo.text = "Fundación de Partido · Identidad"
	_barra.anchor_right = float(_preguntas().size()) / float(_preguntas().size() + 1)
	_actualizar_franja()
	var ficha := PanelContainer.new()
	ficha.add_theme_stylebox_override("panel", Tema.caja_degradada(Color("#1A4C73"), Color("#133C5C"), 18, Color("#2E6490"), 1))
	var fh := HBoxContainer.new()
	fh.add_theme_constant_override("separation", 14)
	var emblema := Tema.etiqueta_corta("MCA", 17, Tema.TINTA, true)
	emblema.add_theme_stylebox_override("normal", Tema.caja_degradada(Color("#FFD76A"), Color("#E3A92A"), 36, Color("#FFF0B8"), 3))
	emblema.custom_minimum_size = Vector2(72, 72)
	emblema.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblema.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fh.add_child(emblema)
	var fv := VBoxContainer.new()
	fv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ejes := GeneradorPartido.calcular_ejes(_respuestas)
	var nombre_prev := Tema.etiqueta("", 16, Tema.TEXTO, true)
	fv.add_child(nombre_prev)
	fv.add_child(Tema.etiqueta(GeneradorPartido.perfil_para(ejes.x, ejes.y, datos["ideologia"]), 12, Tema.ORO, false, 700))
	fh.add_child(fv)
	ficha.add_child(fh)
	_contenido.add_child(ficha)
	_contenido.add_child(Tema.etiqueta("Nombre del partido", 12, Tema.TEXTO_SUAVE))
	_nombre = LineEdit.new()
	_nombre.text = "Movimiento Cívico Austral"
	_nombre.max_length = 32
	_nombre.custom_minimum_size = Vector2(0, 48)
	_contenido.add_child(_nombre)
	_contenido.add_child(Tema.etiqueta("Sigla (hasta 5 letras)", 12, Tema.TEXTO_SUAVE))
	_sigla = LineEdit.new()
	_sigla.text = "MCA"
	_sigla.max_length = 5
	_sigla.custom_minimum_size = Vector2(0, 48)
	_contenido.add_child(_sigla)
	nombre_prev.text = _nombre.text
	_nombre.text_changed.connect(func(t: String) -> void: nombre_prev.text = t)
	_sigla.text_changed.connect(func(t: String) -> void: emblema.text = t.to_upper())
	_contenido.add_child(Tema.etiqueta("Región bastión (+ aprobación inicial)", 12, Tema.TEXTO_SUAVE))
	_region = OptionButton.new()
	_region.custom_minimum_size = Vector2(0, 48)
	for r in datos["regiones"]:
		_region.add_item(String(r["nombre"]))
		_region.set_item_metadata(_region.item_count - 1, String(r["id"]))
		if r["id"] == "metropolitana":
			_region.select(_region.item_count - 1)
	_contenido.add_child(_region)
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_contenido.add_child(esp)
	var ir := Tema.boton("Iniciar Campaña · %d Semanas" % int(datos["leyes"]["hemiciclo"]["semanas_campana"]), Tema.ROJO)
	ir.pressed.connect(_fundar)
	_contenido.add_child(ir)


func _fundar() -> void:
	var nombre := _nombre.text.strip_edges()
	var sigla := _sigla.text.strip_edges().to_upper()
	if nombre == "":
		nombre = "Partido Independiente"
	if sigla == "":
		sigla = nombre.substr(0, 3)
	var region := String(_region.get_item_metadata(_region.selected))
	fundado.emit(GeneradorPartido.construir_partido(nombre, sigla, region, _respuestas, datos["ideologia"]))
