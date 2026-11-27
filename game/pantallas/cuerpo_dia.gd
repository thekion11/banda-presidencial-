class_name CuerpoDia
extends RefCounted
## Construcción del cuerpo de la pantalla del día (mapa con sus tarjetas, mano, Corrector, fila de botones y zona de
## paneles). Se separó de PantallaDia para mantenerla bajo el límite de 450 líneas (CLAUDE.md §3); asigna las
## referencias de la pantalla y conecta sus señales a los métodos de la pantalla.


static func construir(d: PantallaDia) -> Control:
	var corto := Tema.pantalla_baja()  # teléfono bajo (360×640 → 390×693 lógicos): todo cabe y el botón principal queda en pantalla
	var cuerpo := Control.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vista := VBoxContainer.new()
	vista.set_anchors_preset(Control.PRESET_FULL_RECT)
	vista.add_theme_constant_override("separation", 0)
	cuerpo.add_child(vista)
	d._mapa = MapaChile.new()
	d._mapa.custom_minimum_size = Vector2(0, 150 if corto else 290)
	d._mapa.size_flags_vertical = Control.SIZE_EXPAND_FILL
	d._mapa.cargar_geo(d.geo)
	for r in d.datos["regiones"]:  # al acercar el mapa se rotulan las regiones
		d._mapa.nombres[String(r["id"])] = String(r["nombre"])
	d._mapa.region_tocada.connect(d._on_region)
	vista.add_child(d._mapa)
	d._mapa.x_centro_rel = 0.29
	d._mapa.estirar_x = 2.7  # más ancho que antes (2,3): las regiones se ven y se tocan mejor (pedido del usuario, 27-nov)
	var col_tarjetas := VBoxContainer.new()  # las tarjetas de evento y región siguen armadas (textos para Nación y el telón), ocultas
	col_tarjetas.visible = false
	col_tarjetas.add_child(Barras.tarjeta_evento(d._r))
	col_tarjetas.add_child(Barras.tarjeta_region(d._r))
	d._mapa.add_child(col_tarjetas)
	d._mapa.leyenda = false  # el riel ya dice el porcentaje y el color de cada región
	d._riel = RielRegiones.new()  # riel de las 16 regiones (pedido del usuario del 27-nov, «Mapa A + riel»)
	d._riel.construir(d.datos["regiones"])
	d._riel.anchor_left = 1.0
	d._riel.anchor_right = 1.0
	d._riel.anchor_bottom = 1.0
	d._riel.offset_left = -186.0
	d._riel.offset_right = -8.0
	d._riel.offset_top = 8.0
	d._riel.offset_bottom = -8.0
	d._riel.elegida.connect(func(id: String) -> void:
		d._on_region(id)
		d._mapa.acercar_a(id))
	d._riel.detalle.connect(func(id: String) -> void:
		if id == "metropolitana":
			d._abrir_urbano()
		else:
			d._abrir_panel("nacion"))
	d._mapa.add_child(d._riel)
	var cab_mano := HBoxContainer.new()
	var mm := MarginContainer.new()
	mm.add_theme_constant_override("margin_left", 14)
	mm.add_theme_constant_override("margin_right", 14)
	mm.add_child(cab_mano)
	cab_mano.add_child(Tema.etiqueta_corta("Tu mano", 13, Tema.TEXTO, true))
	d._lbl_mov = Tema.etiqueta_corta("", 11, Tema.TEXTO_SUAVE)
	d._lbl_mov.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d._lbl_mov.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cab_mano.add_child(d._lbl_mov)
	mm.visible = not corto  # teléfono bajo: sin la fila «Tu mano» (los movimientos siguen en la pastilla) y el mapa supera el tercio (§5)
	vista.add_child(mm)
	d._mano = ManoUI.new()
	d._mano.custom_minimum_size = Vector2(0, 198 if corto else 214)
	d._mano.arriba = 30.0 if corto else 46.0  # en pantalla baja, menos aire sobre las cartas
	d._mano.clip_contents = false
	d._mano.tocada.connect(d._on_carta)
	d._mano.arrastrada.connect(d._gesto_mano)  # deslizar hacia el mapa juega; soltar sobre el ícono izquierdo delega (PR-02)
	vista.add_child(d._mano)
	var corr := PanelContainer.new()
	corr.add_theme_stylebox_override("panel", Tema.caja(Tema.CREMA, 10, Color("#E8D9A8"), 1))
	d._lbl_corrector = RichTextLabel.new()
	d._lbl_corrector.bbcode_enabled = true
	d._lbl_corrector.fit_content = false  # alto fijo (66 px del panel): el texto largo se recorta, nunca empuja el botón principal
	d._lbl_corrector.scroll_active = false
	d._lbl_corrector.custom_minimum_size = Vector2(330, 0)
	d._lbl_corrector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d._lbl_corrector.add_theme_color_override("default_color", Tema.TINTA)
	d._lbl_corrector.add_theme_font_override("normal_font", Tema.fuente_texto(400))
	d._lbl_corrector.add_theme_font_override("bold_font", Tema.fuente_texto(800))
	d._lbl_corrector.add_theme_font_size_override("normal_font_size", 10)
	d._lbl_corrector.add_theme_font_size_override("bold_font_size", 10)
	corr.custom_minimum_size = Vector2(0, 50 if corto else 66)  # alto fijo: el botón principal no se mueve
	corr.add_child(d._lbl_corrector)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 12)
	mc.add_theme_constant_override("margin_right", 12)
	mc.add_child(corr)
	vista.add_child(mc)
	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 8)
	d._btn_deleg = Barras.boton_redondo("person")
	d._btn_deleg.pressed.connect(d._delegar)
	d._badge = Tema.etiqueta_corta("", 10, Tema.ORO, true)
	d._badge.position = Vector2(36, 34)
	d._btn_deleg.add_child(d._badge)
	d._btn_jugar = Barras.boton_jugar()  # botón del medio: avanzar la semana (PR-02); las cartas se juegan deslizándolas o tocándolas dos veces
	d._btn_jugar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d._btn_jugar.clip_text = true
	d._btn_jugar.pressed.connect(d._avanzar)
	Movimiento.halo(d._btn_jugar)  # el botón principal respira; su rectángulo no cambia
	var libre := Control.new()  # la esquina inferior derecha queda vacía a propósito
	libre.custom_minimum_size = Vector2(54, 54)
	acciones.add_child(d._btn_deleg)
	acciones.add_child(d._btn_jugar)
	acciones.add_child(libre)
	var ma := MarginContainer.new()
	ma.add_theme_constant_override("margin_left", 12)
	ma.add_theme_constant_override("margin_right", 12)
	ma.add_theme_constant_override("margin_top", 2 if corto else 6)
	ma.add_theme_constant_override("margin_bottom", 2 if corto else 6)
	ma.add_child(acciones)
	vista.add_child(ma)
	d._zona_panel = PanelContainer.new()
	d._zona_panel.add_theme_stylebox_override("panel", Tema.caja(Tema.OCEANO, 0))
	d._zona_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	d._zona_panel.visible = false
	cuerpo.add_child(d._zona_panel)
	return cuerpo


