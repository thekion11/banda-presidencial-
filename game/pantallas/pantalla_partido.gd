class_name PantallaPartido
extends Control
## Test ideológico (8 dilemas) + fundación del partido. Reutiliza los componentes congelados de la maqueta.

signal fundado(partido: Dictionary)

var datos: Dictionary = {}
var afiliacion: String = "propio"  # propio | independiente | existente (PR-01)
var base: Dictionary = {}  # partido existente elegido (data/coalicion.json)
var _respuestas: Array[Dictionary] = []
var _paso: int = 0
var _rapido: bool = true  # test rápido de 3 preguntas (data/ideologia.json › rapido); «test completo» lo desactiva
var _contenido: VBoxContainer
var _franja_perfil: Label
var _franja_escanos: Label
var _barra: ColorRect
var _titulo: Label
var _nombre: LineEdit
var _sigla: LineEdit
var _region: OptionButton
var _dificultad: OptionButton
var _habilidad: OptionButton
var _color: String = ""


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
	var todas: Array = datos["ideologia"]["preguntas"]
	if afiliacion == "existente":  # quien entra a un partido solo confirma unas pocas posturas
		return todas.slice(0, int(datos["leyes"]["afiliacion"]["opciones"]["existente"]["preguntas"]))
	if _rapido:
		var ids: Array = datos["ideologia"]["rapido"]["preguntas"]
		return todas.filter(func(q: Dictionary) -> bool: return ids.has(q["id"]))
	return todas


func _actualizar_franja() -> void:
	var ejes := GeneradorPartido.calcular_ejes(_respuestas)
	if _respuestas.is_empty():
		_franja_perfil.text = "Perfil: sin definir"
		_franja_escanos.text = "Responde para proyectar tu bancada inicial."
		return
	_franja_perfil.text = "Perfil: " + GeneradorPartido.perfil_para(ejes.x, ejes.y, datos["ideologia"])
	_franja_escanos.text = "Proyección: %d de %d escaños en el Senado" % [GeneradorPartido.escanos_para(ejes.x, ejes.y), int(datos["leyes"]["hemiciclo"]["total_senadores"])]


func _avance(fraccion: float) -> void:
	## La barra de progreso del test se desliza al siguiente paso (sin animaciones, salta).
	if not Movimiento.activo():
		_barra.anchor_right = fraccion
		return
	_barra.create_tween().tween_property(_barra, "anchor_right", fraccion, Movimiento.BASE + 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _limpiar() -> void:
	for h in _contenido.get_children():
		h.queue_free()


func _mostrar_pregunta() -> void:
	_limpiar()
	var total := _preguntas().size()
	_titulo.text = "%s · Pregunta %d de %d" % ["Confirma tus posturas" if afiliacion == "existente" else "Fundación de Partido", _paso + 1, total]
	_avance(float(_paso) / float(total + 1))
	_actualizar_franja()
	var p: Dictionary = _preguntas()[_paso]
	var img := Tema.imagen(String(p.get("arte", "politica")), 150.0, 16.0)
	_contenido.add_child(img)
	Movimiento.aparecer(img)
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", Tema.caja_degradada(Color("#1A4C73"), Color("#133C5C"), 16, Color("#2E6490"), 1))
	tarjeta.add_child(Tema.etiqueta(String(p["texto"]), 17, Tema.TEXTO, true))
	_contenido.add_child(tarjeta)
	var i := 0
	for op in p["opciones"]:
		var b := _boton_opcion(["A", "B", "C"][i], String(op["etiqueta"]))
		b.pressed.connect(_responder.bind(op))
		_contenido.add_child(b)
		Movimiento.aparecer(b, 0.12 + 0.07 * float(i))
		i += 1
	if afiliacion != "existente" and _paso == 0:
		var alt := Button.new()
		alt.text = "Hacer el test completo (8 preguntas)" if _rapido else "Volver al test rápido (3 preguntas)"
		alt.flat = true
		alt.custom_minimum_size = Vector2(0, 44)
		alt.add_theme_font_size_override("font_size", 12)
		alt.add_theme_color_override("font_color", Tema.ORO)
		alt.pressed.connect(func() -> void:
			_rapido = not _rapido
			_mostrar_pregunta())
		_contenido.add_child(alt)


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
	if afiliacion != "existente" and _rapido:  # el test rápido cubre el mismo rango de ejes con menos preguntas
		var f := float(datos["ideologia"]["rapido"]["escala"])
		op = op.duplicate()
		op["delta_eco"] = float(op["delta_eco"]) * f
		op["delta_inst"] = float(op["delta_inst"]) * f
	_respuestas.append(op)
	_paso += 1
	if _paso < _preguntas().size():
		_mostrar_pregunta()
	else:
		_mostrar_fundacion()


func _mostrar_fundacion() -> void:
	_limpiar()
	_titulo.text = "Tu candidatura · Identidad" if afiliacion != "propio" else "Fundación de Partido · Identidad"
	_avance(float(_preguntas().size()) / float(_preguntas().size() + 1))
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
	var scroll := ScrollContainer.new()  # el formulario crece (habilidad, color, dificultad): se desplaza y el botón principal queda fijo
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 8)
	scroll.add_child(form)
	_contenido.add_child(scroll)
	form.add_child(Tema.etiqueta("Nombre del partido", 12, Tema.TEXTO_SUAVE))
	_nombre = LineEdit.new()
	_nombre.text = "Movimiento Cívico Austral"
	_nombre.max_length = 32
	_nombre.custom_minimum_size = Vector2(0, 48)
	form.add_child(_nombre)
	form.add_child(Tema.etiqueta("Sigla (hasta 5 letras)", 12, Tema.TEXTO_SUAVE))
	_sigla = LineEdit.new()
	_sigla.text = "MCA"
	_sigla.max_length = 5
	_sigla.custom_minimum_size = Vector2(0, 48)
	form.add_child(_sigla)
	if afiliacion == "independiente":
		_nombre.text = "Candidatura Independiente"
		_sigla.text = "IND"
		emblema.text = "IND"
	elif afiliacion == "existente":
		_nombre.text = String(base["nombre"])
		_sigla.text = String(base["sigla"])
		emblema.text = String(base["sigla"])
		_nombre.editable = false
		_sigla.editable = false
	nombre_prev.text = _nombre.text
	_nombre.text_changed.connect(func(t: String) -> void: nombre_prev.text = t)
	_sigla.text_changed.connect(func(t: String) -> void: emblema.text = t.to_upper())
	form.add_child(Tema.etiqueta("Región bastión (+ aprobación inicial)", 12, Tema.TEXTO_SUAVE))
	_region = OptionButton.new()
	_region.custom_minimum_size = Vector2(0, 48)
	for r in datos["regiones"]:
		_region.add_item(String(r["nombre"]))
		_region.set_item_metadata(_region.item_count - 1, String(r["id"]))
		if r["id"] == "metropolitana":
			_region.select(_region.item_count - 1)
	form.add_child(_region)
	form.add_child(Tema.etiqueta("Tu habilidad personal", 12, Tema.TEXTO_SUAVE))
	var hab: Dictionary = datos["leyes"]["habilidades"]
	_habilidad = OptionButton.new()
	_habilidad.custom_minimum_size = Vector2(0, 48)
	for k in hab["opciones"]:
		_habilidad.add_item(String(hab["opciones"][k]["nombre"]))
		_habilidad.set_item_metadata(_habilidad.item_count - 1, String(k))
		if k == hab["defecto"]:
			_habilidad.select(_habilidad.item_count - 1)
	form.add_child(_habilidad)
	var hdesc := Tema.etiqueta("", 11, Tema.TEXTO_SUAVE)
	hdesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var _mh := func(_i: int = 0) -> void: hdesc.text = String(hab["opciones"][String(_habilidad.get_item_metadata(_habilidad.selected))]["descripcion"])
	_habilidad.item_selected.connect(_mh)
	_mh.call()
	form.add_child(hdesc)
	form.add_child(Tema.etiqueta("Color de tu emblema", 12, Tema.TEXTO_SUAVE))
	var fila_col := HBoxContainer.new()
	fila_col.add_theme_constant_override("separation", 6)
	_color = String(hab["colores"][0])
	for hexa in hab["colores"]:
		var bc := Button.new()
		bc.custom_minimum_size = Vector2(44, 44)
		bc.add_theme_stylebox_override("normal", Tema.caja(Color(String(hexa)), 22))
		bc.add_theme_stylebox_override("hover", Tema.caja(Color(String(hexa)).lightened(0.15), 22))
		bc.add_theme_stylebox_override("pressed", Tema.caja(Color(String(hexa)), 22, Tema.CREMA, 3))
		bc.focus_mode = Control.FOCUS_NONE
		bc.pressed.connect(func() -> void:
			_color = String(hexa)
			emblema.add_theme_stylebox_override("normal", Tema.caja_degradada(Color(_color).lightened(0.25), Color(_color).darkened(0.15), 36, Color("#FFF0B8"), 3)))
		fila_col.add_child(bc)
	form.add_child(fila_col)
	form.add_child(Tema.etiqueta("Dificultad", 12, Tema.TEXTO_SUAVE))
	_dificultad = OptionButton.new()
	_dificultad.custom_minimum_size = Vector2(0, 48)
	var niveles: Dictionary = datos["leyes"]["dificultad"]["niveles"]
	for k in niveles:
		_dificultad.add_item(String(niveles[k]["nombre"]))
		_dificultad.set_item_metadata(_dificultad.item_count - 1, String(k))
		if k == datos["leyes"]["dificultad"]["defecto"]:
			_dificultad.select(_dificultad.item_count - 1)
	form.add_child(_dificultad)
	var desc := Tema.etiqueta("", 11, Tema.TEXTO_SUAVE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var _mostrar := func(_i: int = 0) -> void: desc.text = String(niveles[String(_dificultad.get_item_metadata(_dificultad.selected))]["descripcion"])
	_dificultad.item_selected.connect(_mostrar)
	_mostrar.call()
	form.add_child(desc)
	var ir := Tema.boton("Iniciar Campaña · %d Semanas" % int(datos["leyes"]["hemiciclo"]["semanas_campana"]), Tema.ROJO)
	ir.pressed.connect(_fundar)
	_contenido.add_child(ir)
	Movimiento.escalonar(_contenido, 0.0, 0.06)


func _fundar() -> void:
	var nombre := _nombre.text.strip_edges()
	var sigla := _sigla.text.strip_edges().to_upper()
	if nombre == "":
		nombre = "Partido Independiente"
	if sigla == "":
		sigla = nombre.substr(0, 3)
	var region := String(_region.get_item_metadata(_region.selected))
	var partido := GeneradorPartido.construir_partido_afiliado(afiliacion, base, nombre, sigla, region, _respuestas, datos["ideologia"], datos["leyes"]["afiliacion"])
	partido["dificultad"] = String(_dificultad.get_item_metadata(_dificultad.selected))
	GeneradorPartido.aplicar_habilidad(partido, String(_habilidad.get_item_metadata(_habilidad.selected)), _color, datos["leyes"]["habilidades"])
	fundado.emit(partido)
