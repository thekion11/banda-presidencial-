class_name PanelesDia
extends RefCounted
## Paneles inferiores de la pantalla de día: Comité, Congreso y Gabinete. Construyen Controls a partir del motor.


static func _scroll(contenido: VBoxContainer) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.add_child(contenido)
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sc


static func _tarjeta(hijo: Control, color: Color = Tema.PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caja(color, 14))
	p.add_child(hijo)
	return p


static func _chip(titulo: String, valor: String, color: Color, tinta: Color = Tema.TINTA) -> PanelContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.add_child(Tema.etiqueta(titulo, 10, tinta))
	v.add_child(Tema.etiqueta(valor, 13, tinta, true))
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caja(color, 10))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(v)
	return p


static func _camara_bloques(motor: MotorTurno, camara: bool, titulo: String, col: VBoxContainer) -> void:
	var comp := motor.legal.composicion(motor.estado, camara)
	var fila := HBoxContainer.new()
	fila.add_child(Tema.etiqueta_corta(titulo, 15, Tema.TEXTO, true))
	var espacio := Control.new()
	espacio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(espacio)
	fila.add_child(Tema.etiqueta_corta("%d miembros" % int(comp["total"]), 11, Tema.TEXTO_SUAVE))
	col.add_child(fila)
	var h := Hemiciclo.new()
	h.custom_minimum_size = Vector2(0, 150 if not camara else 170)
	h.configurar_bloques(int(comp["total"]), [[comp["propios"], Tema.ORO], [comp["aliados"], Tema.SUBE], [comp["oposicion"], Tema.BAJA]], int(comp["propios"]) + int(comp["aliados"]), "apoyo esperado")
	col.add_child(h)
	h.animar(0.9)
	var minimo := int(motor.legal.tipo("quorum_calificado").get("votos_minimos_camara" if camara else "votos_minimos", 0))
	var leyenda := HBoxContainer.new()
	leyenda.alignment = BoxContainer.ALIGNMENT_CENTER
	leyenda.add_theme_constant_override("separation", 10)
	for par in [[Tema.ORO, "Tu bancada %d" % int(comp["propios"])], [Tema.SUBE, "Aliados %d" % int(comp["aliados"])], [Tema.BAJA, "Oposición %d" % int(comp["oposicion"])]]:
		leyenda.add_child(Icono.crear("dot", par[0], 12.0))
		leyenda.add_child(Tema.etiqueta_corta(par[1], 11, Tema.TEXTO_SUAVE))
	col.add_child(leyenda)
	col.add_child(Tema.etiqueta("Mayoría necesaria para leyes de quórum calificado: %d votos." % minimo, 11, Tema.TEXTO_SUAVE))


static func congreso(motor: MotorTurno, al_abrir_obra: Callable = Callable(), al_cartera: Callable = Callable()) -> Control:
	var est := motor.estado
	var nombres: Dictionary = motor.catalogo_leyes["congreso"]["nombres"]
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.add_child(Tema.etiqueta("CONGRESO NACIONAL · BICAMERAL", 10, Tema.ORO, true))
	_camara_bloques(motor, true, String(nombres["camara"]), col)
	_camara_bloques(motor, false, String(nombres["senado"]), col)
	col.add_child(Tema.etiqueta("Proyectos en tramitación", 15, Tema.TEXTO, true))
	if est.proyectos_ley.is_empty():
		col.add_child(Tema.etiqueta("Ninguno. Las cartas con ley entran por una cámara, pasan a la otra y se votan en ambas; luego puede intervenir el Tribunal Constitucional.", 12, Tema.TEXTO_SUAVE))
	for p in est.proyectos_ley:
		var c: Dictionary = motor._cartas_por_id[p["carta_id"]]
		var t := motor.legal.tipo(String(p["tipo_ley"]))
		var total := maxi(1, int(p["dia_votacion"]) - int(p["dia_ingreso"]))
		var frac := float(est.dia_actual - int(p["dia_ingreso"])) / float(total)
		var origen := String(p["origen"])
		var revisora := "senado" if origen == "camara" else "camara"
		var donde := String(nombres[origen]) if frac < 0.5 else String(nombres[revisora])
		var barra := ProgressBar.new()
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(0, 6)
		barra.value = clampf(frac, 0.0, 1.0) * 100.0
		barra.add_theme_stylebox_override("background", Tema.caja(Color("#274A66"), 3))
		barra.add_theme_stylebox_override("fill", Tema.caja(Tema.ORO, 3))
		var v := VBoxContainer.new()
		v.add_child(Tema.etiqueta("%s\n%s · %s → %s" % [c["titulo"], t["nombre"], nombres[origen], nombres[revisora]], 12, Tema.TEXTO))
		v.add_child(barra)
		v.add_child(Tema.etiqueta("Hoy en la %s · votación el día %d · mínimo %d senadores y %d diputados" % [donde, int(p["dia_votacion"]), int(t["votos_minimos"]), int(t.get("votos_minimos_camara", 0))], 11, Tema.TEXTO_SUAVE))
		col.add_child(_tarjeta(v))
	col.add_child(Tema.etiqueta("Obras en curso", 15, Tema.TEXTO, true))
	if est.obras_en_curso.is_empty():
		col.add_child(Tema.etiqueta("Sin obras en curso.", 12, Tema.TEXTO_SUAVE))
	for o in est.obras_en_curso:
		var fase := MotorObras.fase_de(o)
		var bo := Tema.boton("%s\nFase %d de 5: %s · %d %% · ver hito" % [o["nombre"], fase, MotorObras.FASES[fase - 1], roundi(100.0 * float(o["dias_avanzados"]) / float(o["dias_totales"]))], Tema.PANEL, Tema.TEXTO, 12, 56)
		bo.pressed.connect(func() -> void:
			if al_abrir_obra.is_valid():
				al_abrir_obra.call(o))
		col.add_child(bo)
	if not est.promesas_campana.is_empty():
		col.add_child(Tema.etiqueta("Metas de legado (promesas de campaña)", 15, Tema.TEXTO, true))
		for pr in est.promesas_campana:
			col.add_child(Tema.etiqueta(("Cumplida · " if pr["cumplida"] else "Pendiente · ") + String(pr["titulo"]), 12, Tema.SUBE if pr["cumplida"] else Tema.TEXTO))
	if al_cartera.is_valid():
		var bc := Tema.boton("Cartera de proyectos reales", Tema.PANEL.lightened(0.1), Tema.TEXTO, 13, 48)
		bc.pressed.connect(al_cartera)
		col.add_child(bc)
	return _scroll(col)


static func pintar_region(_r: Dictionary, motor: MotorTurno, datos: Dictionary, _region: String) -> void:
	## Tarjeta de la región elegida (nombre, aprobación, obras en curso).
	var est := motor.estado
	if _region == "" or not est.aprobacion_regional.has(_region):
		_r["rg_nombre"].text = "Elige una región"
		_r["rg_valor"].text = ""
		_r["rg_sub"].text = "Toca el mapa para %s." % ("dirigir tu promesa de campaña" if est.etapa == "campana" else "ver su aprobación")
		_r["rg_barra"].value = 0
		return
	var nombre := _region
	for r in datos["regiones"]:
		if r["id"] == _region:
			nombre = String(r["nombre"]).replace(" de Santiago", "")
	var n_obras := 0
	for o in est.obras_en_curso:
		if o["region"] == _region:
			n_obras += 1
	var v := float(est.aprobacion_regional[_region])
	_r["rg_nombre"].text = nombre
	_r["rg_valor"].text = Tema.pct(v)
	_r["rg_valor"].add_theme_color_override("font_color", Tema.color_aprobacion(v + 12.0))
	_r["rg_sub"].text = "%d obra(s) en curso%s" % [n_obras, " · 1 propuesta nueva" if est.propuestas_abiertas.size() > 0 and _region == "metropolitana" else ""]
	_r["rg_barra"].value = v
	_r["rg_barra"].add_theme_stylebox_override("fill", Tema.caja(Tema.color_aprobacion(v + 12.0), 4))
