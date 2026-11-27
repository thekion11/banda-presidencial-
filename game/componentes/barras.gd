class_name Barras
extends RefCounted
## Piezas de la pantalla de día según la maqueta: cabecera, chips, tarjetas sobre el mapa, botones redondos y barra inferior.

const DIAS := ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
const MESES := ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]


static func _fecha(leyes: Dictionary, etapa: String, turno: int, dia: int, ciclo: int = 1, dias_carrera: int = 0) -> Dictionary:
	## Desde el ciclo 2 de la carrera hay un solo reloj: inicio del mandato + días de los periodos cerrados + días del periodo actual.
	var cal: Dictionary = leyes["calendario"]
	var base := String(cal["fecha_inicio_mandato"] if (etapa == "gobierno" or ciclo > 1) else cal["fecha_inicio_campana"])
	var t := Time.get_unix_time_from_datetime_string(base + "T00:00:00")
	var dias := (dia - 1) if etapa == "gobierno" else (turno - 1) * 7
	return Time.get_datetime_dict_from_unix_time(t + (dias + (dias_carrera if ciclo > 1 else 0)) * 86400)


static func fecha_iso(leyes: Dictionary, etapa: String, turno: int, dia: int, ciclo: int = 1, dias_carrera: int = 0) -> String:
	var d := _fecha(leyes, etapa, turno, dia, ciclo, dias_carrera)
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]


static func legado(est: EstadoSimulacion, lg: Dictionary) -> Dictionary:
	## Próximo corte de legado (MotorMandato.evaluar_legado): al cerrar las semanas de gobierno de leyes.json › legado,
	## cada promesa de campaña pendiente resta capital y aprobación. {} si no hay corte pendiente o nada pendiente.
	var pend := est.promesas_pendientes().size()
	if est.etapa != "gobierno" or pend == 0:
		return {}
	for t in lg["turnos_evaluacion"]:
		if int(t) >= est.turno_actual and not est.legado_evaluado.has(int(t)):
			var faltan := int(t) - est.turno_actual
			var cap := float(lg["penal_capital"]) * float(pend)
			var apr := float(lg["penal_aprobacion"]) * float(pend)
			var cuando := "al cerrar esta semana" if faltan == 0 else ("en 1 semana" if faltan == 1 else "en %d semanas" % faltan)
			return {"faltan": faltan, "texto": "Corte de legado %s (semana %d): cada promesa pendiente cuesta %s de capital y %s de aprobación. Con %d pendiente%s: −%s y −%s." % [
				cuando, int(t), Tema.dec(float(lg["penal_capital"])), Tema.dec(float(lg["penal_aprobacion"])), pend, "" if pend == 1 else "s", Tema.dec(cap), Tema.dec(apr)]}
	return {}


static func crisis(est: EstadoSimulacion, din: Dictionary) -> Dictionary:
	## Cuenta regresiva de la caída por crisis (MotorMandato.evaluar_crisis, solo en gobierno): con la aprobación bajo el
	## umbral, cada cierre de semana suma una a la racha y al completarla el gobierno cae. {} si no hay crisis.
	var umbral := float(din["umbral_crisis_aprobacion"])
	if est.etapa != "gobierno" or est.ind("aprobacion") >= umbral:
		return {}
	var quedan := maxi(1, int(din["semanas_crisis_para_caida"]) - est.semanas_en_crisis)
	return {"corto": "Crisis: caes en %d semana%s" % [quedan, "" if quedan == 1 else "s"],
		"largo": "Aprobación bajo %d %%: si no sube, el gobierno cae %s." % [roundi(umbral), "al cerrar esta semana" if quedan == 1 else "en %d semanas" % quedan]}


static func fecha_texto(leyes: Dictionary, etapa: String, turno: int, dia: int, ciclo: int = 1, dias_carrera: int = 0) -> String:
	var d := _fecha(leyes, etapa, turno, dia, ciclo, dias_carrera)
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
	p.add_theme_stylebox_override("panel", Tema.caja_degradada(Color("#FFD76A"), Color("#E3A92A"), 16, Color("#FFE9A8"), 1))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.add_child(Icono.crear("bolt", Tema.TINTA, 18.0))  # el símbolo de los movimientos (sin la palabra, que se cortaba)
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
	m.add_theme_constant_override("margin_top", roundi(Tema.margen_superior()))  # zona segura del teléfono (antes 30 fijos; la maqueta casi no deja aire)
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
	refs["ev_cab"] = Tema.etiqueta_corta("", 11, Tema.ORO, false, 600)  # el evento del día va en la cabecera (el riel ocupa su tarjeta)
	refs["ev_cab"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refs["ev_cab"].mouse_filter = Control.MOUSE_FILTER_STOP  # tocarlo muestra el evento completo
	for l: Label in [refs["dia"], refs["fecha"], refs["ev_cab"]]:  # recortan con «…» en vez de ensanchar la barra más allá de los 390 px
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	refs["fecha"].clip_text = false  # la fecha es corta y va entera; el evento a su lado es el que se recorta
	col.add_child(refs["dia"])
	var linea := HBoxContainer.new()
	linea.add_theme_constant_override("separation", 6)
	linea.add_child(refs["fecha"])
	linea.add_child(refs["ev_cab"])
	col.add_child(linea)
	fila.add_child(col)
	fila.add_child(pastilla_pa(refs))
	v.add_child(fila)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 5)
	refs["chips"] = {}
	refs["captions"] = {}
	for par in [["aprobacion", "Aprob."], ["capital", "Capital"], ["cohesion", "Cohes."], ["fiscal", "Fiscal"]]:
		var p := PanelContainer.new()
		var caja := Tema.caja_degradada(Color("#17476C"), Color("#0F3355"), 10, Color("#2A6290"), 1)
		caja.content_margin_top = 3  # chips compactos como en la maqueta; abajo queda lugar para la mini barra
		caja.content_margin_bottom = 6
		caja.content_margin_left = 9
		caja.content_margin_right = 9
		p.add_theme_stylebox_override("panel", caja)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.set_meta("frac", 0.0)
		p.draw.connect(func() -> void:  # mini barra del indicador dentro del chip (no cambia su alto: el mapa sigue > 1/3)
			var w := (p.size.x - 16.0)
			p.draw_rect(Rect2(8, p.size.y - 5, w, 2), Color("#274A66"))
			p.draw_rect(Rect2(8, p.size.y - 5, w * clampf(float(p.get_meta("frac")), 0.0, 1.0), 2), p.get_meta("tinta", Tema.ORO)))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 3)
		var cap := Tema.etiqueta_corta(par[1], 10, Tema.TEXTO_SUAVE)
		refs["captions"][par[0]] = cap
		h.add_child(cap)
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
	refs["rg_nombre"].clip_text = true  # un nombre largo no ensancha la columna de tarjetas sobre el mapa: se recorta con «…»
	refs["rg_nombre"].text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	refs["rg_valor"] = Tema.etiqueta_corta("", 14, Tema.bien(), true)
	fila.add_child(refs["rg_nombre"])
	fila.add_child(refs["rg_valor"])
	v.add_child(fila)
	refs["rg_sub"] = Tema.etiqueta("", 11, Tema.TEXTO_SUAVE)
	v.add_child(refs["rg_sub"])
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 7)
	barra.add_theme_stylebox_override("background", Tema.caja(Color("#274A66"), 4))
	barra.add_theme_stylebox_override("fill", Tema.caja(Tema.bien(), 4))
	refs["rg_barra"] = barra
	v.add_child(barra)
	p.add_child(v)
	return p


static func boton_redondo(tipo: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(54, 54)
	for e in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(e, Tema.caja_degradada(Color("#1B4F78"), Color("#0F2F4A"), 27, Color("#4C84AE"), 2))
	b.add_theme_stylebox_override("disabled", Tema.caja_degradada(Color("#0F2A40"), Color("#0A1E31"), 27, Color("#25506F"), 2))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(Icono.crear(tipo, Tema.TEXTO, 24.0))
	b.add_child(centro)
	return b


static func boton_jugar() -> Button:
	var b := Tema.boton("Jugar", Tema.ROJO, Tema.TEXTO, 18, 54)
	b.add_theme_stylebox_override("normal", Tema.caja_degradada(Color("#D65545"), Color("#B7332A"), 27, Color("#F2A08F"), 2))
	b.add_theme_stylebox_override("hover", Tema.caja_degradada(Color("#F07C66"), Color("#C23B2E"), 27, Color("#F2A08F"), 2))
	b.add_theme_stylebox_override("pressed", Tema.caja_degradada(Color("#A92F27"), Color("#C23B2E"), 27, Color("#E8806F"), 2))
	b.add_theme_stylebox_override("disabled", Tema.caja_degradada(Color("#6B3A3A"), Color("#4C2A2A"), 27))
	return b


static func _boton_central(texto: String, al_avanzar: Callable) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(64, 64)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for e in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(e, Tema.caja_degradada(Color("#D65545") if e != "pressed" else Color("#A92F27"), Color("#B7332A"), 32, Color("#F4F0E4"), 3))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vc := VBoxContainer.new()
	vc.add_theme_constant_override("separation", -2)
	vc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ip := Icono.crear("play", Tema.TEXTO, 16.0)
	ip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vc.add_child(ip)
	var l2 := Tema.etiqueta_corta(texto, 13, Tema.TEXTO, true)  # destino, como la maqueta («▶ Día 37»); la cabecera muestra el día actual
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vc.add_child(l2)
	cc.add_child(vc)
	b.add_child(cc)
	b.pressed.connect(al_avanzar)
	return b


static func nav(al_pulsar: Callable, nacion: bool = false, texto_dia: String = "", al_avanzar: Callable = Callable(), etq_gestion: String = "Gabinete", activo: String = "mapa") -> Control:
	## Barra inferior. En "Nación" la maqueta usa Cartas / Comité / [Día N] / Congreso / Gabinete.
	## La pestaña abierta va en oro con un filo arriba (dirección visual v4).
	var fila := HBoxContainer.new()
	fila.custom_minimum_size = Vector2(0, 58)
	var items: Array = [["Mapa", "mapa", "map"], ["Comité", "comite", "bars"], ["Congreso", "congreso", "building"], [etq_gestion, "gabinete", "people"]]
	if nacion:
		items = [["Cartas", "mapa", "card"], ["Comité", "comite", "bars"], ["", "", ""], ["Congreso", "congreso", "building"], [etq_gestion, "gabinete", "people"]]
	for par in items:
		if par[1] == "":
			fila.add_child(_boton_central(texto_dia, al_avanzar))
			continue
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
		var es_activo: bool = par[1] == activo
		var tinta: Color = Tema.ORO if es_activo else Tema.TEXTO
		var ic := Icono.crear(par[2], tinta, 20.0)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(ic)
		if es_activo:
			b.draw.connect(func() -> void: b.draw_rect(Rect2(b.size.x * 0.5 - 14.0, 0, 28, 3), Tema.ORO))
		var l := Tema.etiqueta_corta(par[0], 11, tinta, false, 600)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
		b.add_child(col)
		b.pressed.connect(al_pulsar.bind(par[1]))
		fila.add_child(b)
	var fondo := PanelContainer.new()
	var sb := Tema.caja(Color("#0A1E31"), 0, Color("#1E4E72"), 0)
	sb.content_margin_top = 2  # barra compacta como en la maqueta (antes 8 + 8 de aire); los botones siguen ≥ 44 px
	sb.content_margin_bottom = 4
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
		refs["ev_hora"].text = "• EVENTO · %s" % String(ev["hora"])
		refs["ev_titulo"].text = String(ev["titulo"])
		refs["ev_sub"].text = String(ev["descripcion"])
		return
	var prox: Dictionary = {}
	for e in motor.catalogo_eventos:
		if e["tipo"] == "programado" and String(e.get("etapa", "gobierno")) == est.etapa and int(e["dia_objetivo"]) >= est.dia_actual:
			if prox.is_empty() or int(e["dia_objetivo"]) < int(prox["dia_objetivo"]):
				prox = e
	if prox.is_empty():
		refs["ev_hora"].text = "• SIN EVENTOS"
		refs["ev_titulo"].text = "Semana tranquila"
		refs["ev_sub"].text = "No hay eventos programados."
		return
	refs["ev_hora"].text = "• PRÓXIMO · %s · DÍA %d" % [String(prox["hora_etiqueta"]), int(prox["dia_objetivo"])]
	refs["ev_titulo"].text = String(prox["titulo"])
	var v: Variant = prox.get("votacion", null)
	refs["ev_sub"].text = ("%d votos firmes · mínimo %d" % [int(v["votos_firmes_base"]), int(motor.legal.tipo(String(v["tipo_ley"]))["votos_minimos"])]) if v != null else String(prox["descripcion"])


static func resumen_cambios(antes: Dictionary, despues: Dictionary) -> String:
	## «Aprob. +2 · Capital −3»: lo que la carta cambió en los indicadores visibles (solo los que se movieron al menos 0,5).
	var partes: Array[String] = []
	for par in [["aprobacion", "Aprob."], ["capital", "Capital"], ["cohesion", "Cohes."], ["fiscal", "Fiscal"], ["rival", "Rival"]]:
		var d := float(despues.get(par[0], 0.0)) - float(antes.get(par[0], 0.0))
		if absf(d) >= 0.5:
			partes.append("%s %s" % [par[1], Tema.signo(d)])
	return " · ".join(partes)


static func texto_decision(r: Dictionary, antes: Dictionary, despues: Dictionary) -> String:
	## Aviso tras responder un evento: lo que cambió, si la opción salió mal y si habrá consecuencias más adelante.
	if not bool(r.get("ok", false)):
		return "No se pudo registrar la decisión."
	var t := "Decisión tomada."
	var c := resumen_cambios(antes, despues)
	if c != "":
		t += " " + c + "."
	if bool(r.get("congreso", false)):
		t += " Perdiste la votación." if bool(r.get("salio_mal", false)) else " Ganaste la votación."
	elif bool(r.get("salio_mal", false)):
		t += " Salió mal."
	if int(r.get("futuro", 0)) > 0:
		t += " Habrá consecuencias en unas %d semanas." % int(r["futuro"])
	if not r.get("renuncia", {}).is_empty():
		t += " Renunció %s; asume %s." % [r["renuncia"]["ministro"], r["renuncia"]["nuevo"]]
	return t


static func sufijo_carta(r: Dictionary) -> String:
	## Texto que se suma al aviso de una carta con riesgo o efecto a futuro.
	return (" Salió mal." if bool(r.get("salio_mal", false)) else "") + (" Habrá consecuencias en unas %d semanas." % int(r["futuro"]) if int(r.get("futuro", 0)) > 0 else "")


static func texto_consecuencia(ev: Dictionary) -> String:
	## Aviso de una consecuencia programada por una carta: su frase y lo que cambió.
	var d := {}
	for ef in ev["efectos"]:
		d[String(ef["ind"])] = float(ef["delta"])
	var c := resumen_cambios({}, d)
	var cabeza := "Consecuencia: %s" % String(ev["descripcion"]) if String(ev["id"]).begins_with("dif_") else "%s: %s" % [String(ev["titulo"]), String(ev["descripcion"])]
	return cabeza + ((" " + c + ".") if c != "" else "")


static func pintar_chips(refs: Dictionary, est: EstadoSimulacion) -> void:
	## Indicadores de la cabecera. En oposición el chip de Fiscal pasa a mostrar la aprobación del gobierno rival.
	for k in refs["chips"].keys():
		var oposicion: bool = est.etapa == "oposicion" and k == "fiscal"
		var ind: String = "rival" if oposicion else String(k)
		(refs["captions"][k] as Label).text = "Rival" if oposicion else {"aprobacion": "Aprob.", "capital": "Capital", "cohesion": "Cohes.", "fiscal": "Fiscal"}[k]
		var l: Label = refs["chips"][k]
		var nuevo := float(roundi(est.ind(ind)))
		var previo := float(l.get_meta("valor", nuevo)) if l.get_meta("ind", ind) == ind else nuevo
		l.set_meta("valor", nuevo)
		l.set_meta("ind", ind)
		Movimiento.contar(l, nuevo, func(x: float) -> String: return str(roundi(x)), previo, 0.55)  # la cifra cuenta hasta su valor
		var chip: Control = l.get_parent().get_parent()
		chip.set_meta("tinta", Tema.color_aprobacion(nuevo + 12.0) if k == "aprobacion" or oposicion else Tema.ORO)
		if Movimiento.activo():
			chip.create_tween().tween_method(func(f: float) -> void:
				chip.set_meta("frac", f)
				chip.queue_redraw(), float(chip.get_meta("frac")), nuevo / 100.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			chip.set_meta("frac", nuevo / 100.0)
			chip.queue_redraw()
		if not is_equal_approx(previo, nuevo):  # el chip destella: verde si subió, coral si bajó (en «Rival», subir es malo)
			Movimiento.destello(l.get_parent().get_parent(), Tema.bien() if (nuevo > previo) != (ind == "rival") else Tema.mal())
		l.add_theme_color_override("font_color", Tema.bien() if (k == "aprobacion" and est.ind(ind) >= 50.0) else Tema.TEXTO)
