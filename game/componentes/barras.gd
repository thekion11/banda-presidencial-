class_name Barras
extends RefCounted
## Piezas de la pantalla de día según la maqueta: cabecera, chips, tarjetas sobre el mapa, botones redondos y barra inferior.

const DIAS := ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
const MESES := ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]


static func fecha_texto(leyes: Dictionary, etapa: String, turno: int, dia: int) -> String:
	var cal: Dictionary = leyes["calendario"]
	var base := String(cal["fecha_inicio_mandato"] if etapa == "gobierno" else cal["fecha_inicio_campana"])
	var t := Time.get_unix_time_from_datetime_string(base + "T00:00:00")
	var dias := (dia - 1) if etapa == "gobierno" else (turno - 1) * 7
	var d := Time.get_datetime_dict_from_unix_time(t + dias * 86400)
	return "%s %d %s %d" % [DIAS[int(d["weekday"])], int(d["day"]), MESES[int(d["month"]) - 1], int(d["year"])]


static func insignia() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(36, 36)
	c.draw.connect(func() -> void:
		c.draw_circle(Vector2(18, 18), 17.0, Color("#E5BDB6"))
		c.draw_circle(Vector2(18, 18), 15.0, Tema.ROJO))
	var st := Icono.crear("star", Tema.TEXTO, 18.0)
	st.position = Vector2(9, 9)
	c.add_child(st)
	return c


static func pastilla_pa(refs: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caja(Tema.ORO, 16, Color("#FFE49A"), 1))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.add_child(Icono.crear("bolt", Tema.TINTA, 16.0))
	var l := Tema.etiqueta_corta("", 15, Tema.TINTA, true)
	h.add_child(l)
	p.add_child(h)
	p.custom_minimum_size = Vector2(0, 32)
	refs["pa"] = l
	return p


static func cabecera(refs: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 30)
	m.add_theme_constant_override("margin_bottom", 6)
	m.add_child(v)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.add_child(insignia())
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refs["dia"] = Tema.etiqueta_corta("", 18, Tema.TEXTO, true)
	refs["fecha"] = Tema.etiqueta_corta("", 11, Tema.TEXTO_SUAVE)
	col.add_child(refs["dia"])
	col.add_child(refs["fecha"])
	fila.add_child(col)
	fila.add_child(pastilla_pa(refs))
	v.add_child(fila)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 5)
	refs["chips"] = {}
	for par in [["aprobacion", "Aprob."], ["capital", "Capital"], ["cohesion", "Cohes."], ["fiscal", "Fiscal"]]:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Tema.caja(Color("#12395A"), 10, Color("#1E5078"), 1))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 3)
		h.add_child(Tema.etiqueta_corta(par[1], 10, Tema.TEXTO_SUAVE))
		var val := Tema.etiqueta_corta("", 13, Tema.TEXTO, true)
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(val)
		p.add_child(h)
		refs["chips"][par[0]] = val
		chips.add_child(p)
	v.add_child(chips)
	return m


static func tarjeta_evento(refs: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caja(Color(0.07, 0.2, 0.32, 0.95), 12, Color("#2B5D86"), 1))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	refs["ev_hora"] = Tema.etiqueta_corta("", 10, Tema.ORO, true)
	refs["ev_titulo"] = Tema.etiqueta("", 14, Tema.TEXTO, true)
	refs["ev_sub"] = Tema.etiqueta("", 11, Tema.TEXTO_SUAVE)
	v.add_child(refs["ev_hora"])
	v.add_child(refs["ev_titulo"])
	v.add_child(refs["ev_sub"])
	p.add_child(v)
	return p


static func tarjeta_region(refs: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caja(Color(0.07, 0.2, 0.32, 0.95), 12, Tema.ORO, 1))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var fila := HBoxContainer.new()
	refs["rg_nombre"] = Tema.etiqueta_corta("", 14, Tema.TEXTO, true)
	refs["rg_nombre"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refs["rg_valor"] = Tema.etiqueta_corta("", 14, Tema.SUBE, true)
	fila.add_child(refs["rg_nombre"])
	fila.add_child(refs["rg_valor"])
	v.add_child(fila)
	refs["rg_sub"] = Tema.etiqueta("", 11, Tema.TEXTO_SUAVE)
	v.add_child(refs["rg_sub"])
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 7)
	barra.add_theme_stylebox_override("background", Tema.caja(Color("#274A66"), 4))
	barra.add_theme_stylebox_override("fill", Tema.caja(Tema.SUBE, 4))
	refs["rg_barra"] = barra
	v.add_child(barra)
	p.add_child(v)
	return p


static func boton_redondo(tipo: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(54, 54)
	for e in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(e, Tema.caja(Color("#12395A") if e != "disabled" else Color("#0C2336"), 27, Color("#3A6E98"), 2))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(Icono.crear(tipo, Tema.TEXTO, 24.0))
	b.add_child(centro)
	return b


static func boton_jugar() -> Button:
	var b := Tema.boton("Jugar", Tema.ROJO, Tema.TEXTO, 18, 54)
	for e in ["normal", "hover", "pressed"]:
		var sb := Tema.caja(Tema.ROJO if e != "pressed" else Tema.ROJO.darkened(0.15), 27, Color("#E8806F"), 2)
		sb.shadow_color = Color(0.76, 0.23, 0.18, 0.5)
		sb.shadow_size = 10
		b.add_theme_stylebox_override(e, sb)
	return b


static func nav(al_pulsar: Callable) -> Control:
	var fila := HBoxContainer.new()
	fila.custom_minimum_size = Vector2(0, 58)
	for par in [["Mapa", "mapa", "map"], ["Comité", "comite", "bars"], ["Congreso", "congreso", "building"], ["Gabinete", "gabinete", "people"]]:
		var b := Button.new()
		b.flat = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(Tema.TACTIL, 56)
		for e in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(e, StyleBoxEmpty.new())
		var col := VBoxContainer.new()
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := Icono.crear(par[2], Tema.TEXTO, 20.0)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(ic)
		var l := Tema.etiqueta_corta(par[0], 11, Tema.TEXTO, false, 600)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
		b.add_child(col)
		b.pressed.connect(al_pulsar.bind(par[1]))
		fila.add_child(b)
	var fondo := PanelContainer.new()
	var sb := Tema.caja(Color("#0A1E31"), 0, Color("#1E4E72"), 0)
	sb.border_width_top = 1
	sb.border_color = Color("#1E4E72")
	fondo.add_theme_stylebox_override("panel", sb)
	fondo.add_child(fila)
	return fondo


static func actualizar_evento(refs: Dictionary, motor: MotorTurno) -> void:
	var est := motor.estado
	var ev: Dictionary = {}
	if not motor.ultimos_eventos.is_empty():
		ev = motor.ultimos_eventos[0]
		refs["ev_hora"].text = "● EVENTO · %s" % String(ev["hora"])
		refs["ev_titulo"].text = String(ev["titulo"])
		refs["ev_sub"].text = String(ev["descripcion"])
		return
	var prox: Dictionary = {}
	for e in motor.catalogo_eventos:
		if e["tipo"] == "programado" and String(e.get("etapa", "gobierno")) == est.etapa and int(e["dia_objetivo"]) >= est.dia_actual:
			if prox.is_empty() or int(e["dia_objetivo"]) < int(prox["dia_objetivo"]):
				prox = e
	if prox.is_empty():
		refs["ev_hora"].text = "● SIN EVENTOS"
		refs["ev_titulo"].text = "Semana tranquila"
		refs["ev_sub"].text = "No hay eventos programados."
		return
	refs["ev_hora"].text = "● PRÓXIMO · %s · DÍA %d" % [String(prox["hora_etiqueta"]), int(prox["dia_objetivo"])]
	refs["ev_titulo"].text = String(prox["titulo"])
	var v: Variant = prox.get("votacion", null)
	refs["ev_sub"].text = ("%d votos firmes · mínimo %d" % [int(v["votos_firmes_base"]), int(motor.legal.tipo(String(v["tipo_ley"]))["votos_minimos"])]) if v != null else String(prox["descripcion"])
