class_name PantallaHito
extends RefCounted
## Hito de obra en tema claro, como la maqueta: isométrica, 5 fases, chips de impacto y acceso al mapa urbano.

const CORTAS: Array[String] = ["Licitación", "Faena", "Estructura", "Terminación", "Inauguración"]


static func _chip(titulo: String, valor: String, fondo: Color, tinta: Color) -> PanelContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.add_child(Tema.etiqueta(titulo, 10, tinta, false, 700))
	v.add_child(Tema.etiqueta(valor, 16, Tema.TINTA, true))
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caja(fondo, 10))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(v)
	return p


static func _pildora(texto: String, fondo: Color, tinta: Color) -> Label:
	var l := Tema.etiqueta_corta(texto, 11, tinta, false, 700)
	l.add_theme_stylebox_override("normal", Tema.caja(fondo, 12))
	return l


static func _recorrido(linea: Dictionary) -> Control:
	## Recorrido de la línea del jugador: sus estaciones en orden, en una tira que se desliza con el dedo.
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Color.WHITE, 14, Tema.BORDE_CLARO, 1))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var estado := "operativa" if String(linea["estado"]) == "operativa" else "en construcción"
	v.add_child(Tema.etiqueta_corta("%s · %s · %s" % [linea["id"], String(linea["nombre"]), estado], 11, Tema.GRIS_CLARO, false, 700))
	var sc := ScrollContainer.new()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 40)
	sc.get_h_scroll_bar().modulate.a = 0.0
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 0)
	var nombres: Array = linea.get("nombres_estaciones", [])
	for i in range(nombres.size()):
		if i > 0:
			var tramo := ColorRect.new()
			tramo.color = UrbanoBase.COLOR_PROPIA
			tramo.custom_minimum_size = Vector2(18, 4)
			tramo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			fila.add_child(tramo)
		var punto := PanelContainer.new()
		var sb := Tema.caja(Color.WHITE, 8, UrbanoBase.COLOR_PROPIA, 3)
		sb.content_margin_left = 0
		sb.content_margin_right = 0
		sb.content_margin_top = 0
		sb.content_margin_bottom = 0
		punto.add_theme_stylebox_override("panel", sb)
		punto.custom_minimum_size = Vector2(14, 14)
		punto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(punto)
		var l := Tema.etiqueta_corta(" " + String(nombres[i]) + " ", 11, Tema.TINTA, false, 600)
		fila.add_child(l)
	sc.add_child(fila)
	v.add_child(sc)
	caja.add_child(v)
	return caja


static func crear(obra: Dictionary, fases: Array, al_cerrar: Callable, al_ver_mapa: Callable, lineas_jugador: Array = []) -> Control:
	var capa := ColorRect.new()
	capa.color = Tema.FONDO_CLARO
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 16
	col.offset_right = -16
	col.offset_top = Tema.margen_superior() + 8.0  # zona segura del teléfono (antes 40 fijos; en la maqueta el título casi toca el borde)
	col.offset_bottom = -22
	col.add_theme_constant_override("separation", 10)
	capa.add_child(col)
	var variante := String(obra.get("variante", ""))
	col.add_child(Tema.etiqueta("OBRA APROBADA%s" % ((" · VARIANTE " + variante) if variante != "" else ""), 10, Tema.GRIS_CLARO, false, 700))
	col.add_child(Tema.etiqueta(String(obra["nombre"]), 24, Tema.TINTA, true))
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", Tema.caja(Color("#D6E6EF"), 18, Tema.BORDE_CLARO, 2))
	tarjeta.custom_minimum_size = Vector2(0, 250)
	var iso := Obra3D.new()
	iso.fase = float(MotorObras.fase_de(obra))
	tarjeta.add_child(iso)
	var pila := Control.new()
	pila.custom_minimum_size = Vector2(0, 250)
	tarjeta.add_child(pila)
	pila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dia := _pildora("Día %d de %d" % [int(obra["dias_avanzados"]), int(obra["dias_totales"])], Color.WHITE, Tema.TINTA)
	dia.position = Vector2(12, 10)
	pila.add_child(dia)
	var fase_pill := _pildora("", Tema.TINTA, Tema.TEXTO)
	fase_pill.anchor_left = 1.0
	fase_pill.anchor_right = 1.0
	fase_pill.offset_left = -118.0
	fase_pill.offset_top = 10.0
	fase_pill.offset_right = -12.0
	fase_pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pila.add_child(fase_pill)
	col.add_child(tarjeta)
	for ln in lineas_jugador:  # obra de una línea del jugador: muestra su recorrido
		if ln["id"] == String(obra.get("linea", "")):
			col.add_child(_recorrido(ln))
	var info := Tema.etiqueta("", 12, Color("#3C4A5A"))
	var nom := Tema.etiqueta("", 16, Tema.TINTA, true)
	var botones: Array[Button] = []
	var actualizar := func(f: int) -> void:
		nom.text = String(fases[f - 1]["titulo"])
		info.text = String(fases[f - 1]["descripcion"])
		fase_pill.text = CORTAS[f - 1]
		for i in range(5):
			var sel := i == f - 1
			var fondo := Tema.TINTA if sel else Color.WHITE
			for e in ["normal", "hover", "pressed"]:
				botones[i].add_theme_stylebox_override(e, Tema.caja(fondo, 12, Tema.TINTA, 2))
			for e in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				botones[i].add_theme_color_override(e, Tema.TEXTO if sel else Tema.TINTA)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	for i in range(5):
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 2)
		var b := Tema.boton(str(i + 1), Color.WHITE, Tema.TINTA, 16, 46)
		b.pressed.connect(func() -> void:
			iso.ir_a(i + 1)
			actualizar.call(i + 1))
		botones.append(b)
		v.add_child(b)
		var l := Tema.etiqueta_corta(CORTAS[i], 10, Tema.GRIS_CLARO)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		fila.add_child(v)
	col.add_child(fila)
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 7)
	barra.value = 100.0 * float(obra["dias_avanzados"]) / float(obra["dias_totales"])
	barra.add_theme_stylebox_override("background", Tema.caja(Color("#E0DACB"), 4))
	barra.add_theme_stylebox_override("fill", Tema.caja(Tema.ROJO, 4))
	col.add_child(barra)
	var ficha := PanelContainer.new()
	ficha.add_theme_stylebox_override("panel", Tema.caja(Color.WHITE, 16, Tema.BORDE_CLARO, 1))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 6)
	tv.add_child(nom)
	tv.add_child(info)
	var ap := 0.0
	for ef in obra["efectos_final"]:
		if String(ef["ind"]) == "aprobacion":  # antes sumaba también fiscal y riesgo de ejecución
			ap += float(ef["delta"])
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	chips.add_child(_chip("Empleo (ilustrativo)", "+" + Tema.miles(roundi(float(obra["dias_totales"]) * 1.6 / 10.0) * 10), Color("#DDEFE6"), Color("#1F6B4A")))
	chips.add_child(_chip("Aprobación local", Tema.signo(ap), Color("#F7E7C4"), Color("#6F500C")))
	chips.add_child(_chip("Riesgo de retraso", "Bajo" if int(obra["retrasos"]) == 0 else "Medio", Color("#F7D9D5"), Color("#9A3026")))
	tv.add_child(chips)
	ficha.add_child(tv)
	col.add_child(ficha)
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(esp)
	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 8)
	var rep := Tema.boton("Reproducir obra", Color.WHITE, Tema.TINTA, 14, 52)
	for e in ["normal", "hover", "pressed"]:
		rep.add_theme_stylebox_override(e, Tema.caja(Color.WHITE, 18, Tema.TINTA, 2))
	rep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rep.pressed.connect(func() -> void:
		iso.reproducir()
		actualizar.call(5))
	var ver := Barras.boton_jugar()
	ver.text = "Ver en el mapa 2D"
	ver.add_theme_font_size_override("font_size", 14)
	ver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ver.pressed.connect(func() -> void:
		capa.queue_free()
		al_ver_mapa.call())
	var volver := Button.new()
	volver.text = "×"
	volver.flat = true
	volver.add_theme_font_size_override("font_size", 26)
	volver.add_theme_color_override("font_color", Tema.TINTA)
	volver.anchor_left = 1.0
	volver.anchor_right = 1.0
	volver.offset_left = -56.0
	volver.offset_right = -8.0
	volver.offset_top = 30.0
	volver.offset_bottom = 78.0
	volver.pressed.connect(func() -> void:
		capa.queue_free()
		al_cerrar.call())
	capa.add_child(volver)
	acciones.add_child(rep)
	acciones.add_child(ver)
	col.add_child(acciones)
	actualizar.call(MotorObras.fase_de(obra))
	return Tapa.cubrir(capa)
