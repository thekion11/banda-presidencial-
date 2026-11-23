class_name OverlaysDia
extends RefCounted
## Capas a pantalla completa: eventos y votaciones bicamerales, e hito de obra.


static func _fondo_radial() -> TextureRect:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("#154F7A"), Color("#0B2236"), Color("#081A2B")])
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.22)
	t.fill_to = Vector2(0.5, 1.05)
	t.width = 390
	t.height = 844
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func _centrada(texto: String, tam: int, color: Color, titulo: bool = false, peso: int = 400) -> Label:
	var l := Tema.etiqueta(texto, tam, color, titulo, peso)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func _pagina_votacion(col: VBoxContainer, camara: String, voto: Dictionary, nombres: Dictionary, requiere: String) -> void:
	var es_cam := camara == "camara"
	var total := int(voto["total_camara"]) if es_cam else int(voto["total_senado"])
	var favor := int(voto["camara"]) if es_cam else int(voto["senado"])
	var abst := int(voto["abst_camara"]) if es_cam else int(voto["abst_senado"])
	var contra := int(voto["contra_camara"]) if es_cam else int(voto["contra_senado"])
	var minimo := int(voto["min_camara"]) if es_cam else int(voto["min_senado"])
	col.add_child(_centrada("%s · %d MIEMBROS" % [String(nombres[camara]).to_upper(), total], 11, Tema.ORO, true))
	col.add_child(_centrada("Requiere %d votos de %d %s" % [minimo, total, "diputados" if es_cam else "senadores"], 13, Tema.TEXTO_SUAVE))
	var h := Hemiciclo.new()
	h.custom_minimum_size = Vector2(0, 230)
	h.configurar_votos(total, favor, abst, contra)
	col.add_child(h)
	h.animar(1.3)
	var leyenda := HBoxContainer.new()
	leyenda.alignment = BoxContainer.ALIGNMENT_CENTER
	leyenda.add_theme_constant_override("separation", 12)
	for par in [[Tema.SUBE, "A favor %d" % favor], [Color("#9AA9C0"), "Abstención %d" % abst], [Tema.BAJA, "En contra %d" % contra]]:
		leyenda.add_child(Icono.crear("dot", par[0], 12.0))
		leyenda.add_child(Tema.etiqueta_corta(par[1], 11, Tema.TEXTO_SUAVE))
	col.add_child(leyenda)
	var ok := favor >= minimo
	var color := Tema.SUBE if ok else Tema.BAJA
	var sc := CenterContainer.new()
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Color(color, 0.12), 10, color, 3))
	caja.add_child(Tema.etiqueta_corta("APROBADA" if ok else "RECHAZADA", 30, color, true))
	caja.pivot_offset = Vector2(100, 24)
	sc.add_child(caja)
	sc.custom_minimum_size = Vector2(0, 70)
	col.add_child(sc)
	caja.set_deferred("rotation_degrees", -4.0)
	caja.modulate.a = 0.0
	caja.scale = Vector2(2.2, 2.2)
	var tws := caja.create_tween().set_parallel(true)
	tws.tween_property(caja, "modulate:a", 1.0, 0.12).set_delay(1.35)
	tws.tween_property(caja, "scale", Vector2.ONE, 0.32).set_delay(1.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func _camino(col: VBoxContainer, paginas: Array, i: int, nombres: Dictionary) -> void:
	## Camino de la ley: cámara de origen -> cámara revisora -> promulgación (con posible Tribunal Constitucional).
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", Tema.caja(Color(0.06, 0.18, 0.3, 0.55), 14, Color("#2B5D86"), 1))
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	cv.add_child(Tema.etiqueta("Camino de la ley", 14, Tema.TEXTO, true))
	var pasos := [["1", "%s (cámara de origen)" % nombres[paginas[0]]], ["2", "%s (cámara revisora)" % nombres[paginas[1]]], ["3", "Promulgación · posible Tribunal Constitucional"]]
	for k in range(3):
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 8)
		var hecho := k < i or (k == i and i == 0)
		var c := Tema.etiqueta_corta(pasos[k][0], 12, Tema.TINTA, true)
		c.add_theme_stylebox_override("normal", Tema.caja(Tema.SUBE if hecho else Color("#9AA9C0"), 12))
		f.add_child(c)
		var txt := Tema.etiqueta(String(pasos[k][1]), 12, Tema.TEXTO if k <= i + 1 else Tema.TEXTO_SUAVE)
		txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f.add_child(txt)
		cv.add_child(f)
	tarjeta.add_child(cv)
	col.add_child(tarjeta)


static func _consecuencias(col: VBoxContainer, ev: Dictionary, voto: Dictionary, tc: Dictionary, nombres: Dictionary, orden: Array) -> void:
	var texto := ""
	var primera_ok: bool = (int(voto["camara"]) >= int(voto["min_camara"])) if orden[0] == "camara" else (int(voto["senado"]) >= int(voto["min_senado"]))
	var segunda_ok: bool = (int(voto["senado"]) >= int(voto["min_senado"])) if orden[0] == "camara" else (int(voto["camara"]) >= int(voto["min_camara"]))
	if not primera_ok:
		texto = "El proyecto cae en la %s y no llega a la %s: pierdes capital político." % [nombres[orden[0]], nombres[orden[1]]]
	elif not segunda_ok:
		texto = "Aprobado en la %s, pero rechazado en la %s: el proyecto muere y pierdes capital político." % [nombres[orden[0]], nombres[orden[1]]]
	elif bool(tc["recurso"]) and bool(tc["cae"]):
		texto = "Aprobado en ambas cámaras, pero el Tribunal Constitucional acoge el recurso de la oposición: la norma cae y pierdes capital político."
	elif bool(tc["recurso"]):
		texto = "Aprobado en ambas cámaras. La oposición recurrió al Tribunal Constitucional, pero fue rechazado: la norma se promulga."
	else:
		texto = "Aprobado en la %s y en la %s. Se promulga sin reparos." % [nombres[orden[0]], nombres[orden[1]]]
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", Tema.caja(Color(0.06, 0.18, 0.3, 0.55), 14, Color("#2B5D86"), 1))
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	cv.add_child(Tema.etiqueta("Consecuencias", 14, Tema.TEXTO, true))
	var efectos: Variant = ev.get("efectos", null)
	if efectos != null and not efectos.is_empty():
		cv.add_child(_fila_efectos(efectos))
	cv.add_child(Tema.etiqueta(texto, 12, Tema.TEXTO))
	tarjeta.add_child(cv)
	col.add_child(tarjeta)


static func _fila_efectos(efectos: Array) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var nombres := {"aprobacion": "Aprobación", "capital": "Capital político", "cohesion": "Cohesión", "fiscal": "Credibilidad fiscal", "riesgo_ejecucion": "Riesgo de ejecución", "viviendas_anio": "Viviendas/año"}
	for ef in efectos:
		var d := float(ef["delta"])
		var bueno := d >= 0.0 if ef["ind"] != "riesgo_ejecucion" else d <= 0.0
		var cp := PanelContainer.new()
		cp.add_theme_stylebox_override("panel", Tema.caja(Color("#14405F"), 10))
		cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cvv := VBoxContainer.new()
		cvv.add_theme_constant_override("separation", 0)
		cvv.add_child(Tema.etiqueta(String(nombres[ef["ind"]]), 10, Tema.TEXTO_SUAVE))
		cvv.add_child(Tema.etiqueta(Tema.signo(d), 16, Tema.SUBE if bueno else Tema.BAJA, true))
		cp.add_child(cvv)
		fila.add_child(cp)
	return fila


static func evento(ev: Dictionary, al_continuar: Callable, nombres: Dictionary, dia: int = 0) -> Control:
	## Evento del día. Si trae votación, se muestra cámara por cámara en el orden de tramitación (origen -> revisora).
	var capa := Control.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(_fondo_radial())
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 20
	col.offset_right = -20
	col.offset_top = 46
	col.offset_bottom = -26
	col.add_theme_constant_override("separation", 10)
	capa.add_child(col)
	var boton := Barras.boton_jugar()
	var v: Variant = ev.get("votacion", null)
	var paginas: Array = []
	if v != null:
		var origen := String(v.get("origen", "camara"))
		paginas = [origen, "senado" if origen == "camara" else "camara"]
	var estado := {"i": 0, "armar": Callable()}  # el diccionario se captura por referencia (la lambda no se ve a sí misma)
	estado["armar"] = func() -> void:
		for h in col.get_children():
			h.queue_free()
		var cab := ("EVENTO · %s" % String(ev["hora"]))
		if dia > 0:
			cab += " · DÍA %d" % dia
		col.add_child(_centrada(cab, 11, Tema.ORO, true))
		col.add_child(_centrada(String(ev["titulo"]), 24, Tema.TEXTO, true))
		if v == null:
			col.add_child(_centrada(String(ev["descripcion"]), 13, Tema.TEXTO_SUAVE))
			var ef: Variant = ev.get("efectos", null)
			if ef != null and not ef.is_empty():
				col.add_child(_fila_efectos(ef))
		else:
			var i: int = estado["i"]
			var voto: Dictionary = v["voto"]
			var pag_ok := true
			if i >= 0 and i < 2:
				_pagina_votacion(col, String(paginas[i]), voto, nombres, "")
				var fav: int = int(voto["camara"]) if paginas[i] == "camara" else int(voto["senado"])
				var minimo: int = int(voto["min_camara"]) if paginas[i] == "camara" else int(voto["min_senado"])
				pag_ok = fav >= minimo
			if i == 0 and pag_ok:
				_camino(col, paginas, 0, nombres)
			if i == 1 or not pag_ok:
				_consecuencias(col, ev, voto, v["tc"], nombres, paginas)
		var esp := Control.new()
		esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(esp)
		var b := Barras.boton_jugar()
		var ultima := v == null or int(estado["i"]) == 1 or not _pasa(v, paginas, int(estado["i"]))
		b.text = "Continuar" if ultima else "Pasa a la %s" % nombres[paginas[1]]
		b.pressed.connect(func() -> void:
			if ultima:
				capa.queue_free()
				al_continuar.call()
			else:
				estado["i"] = int(estado["i"]) + 1
				estado["armar"].call())
		col.add_child(b)
	boton.free()
	estado["armar"].call()
	return capa


static func _pasa(v: Dictionary, paginas: Array, i: int) -> bool:
	var voto: Dictionary = v["voto"]
	var fav: int = int(voto["camara"]) if paginas[i] == "camara" else int(voto["senado"])
	var minimo: int = int(voto["min_camara"]) if paginas[i] == "camara" else int(voto["min_senado"])
	return fav >= minimo


static func hito(obra: Dictionary, fases: Array, al_cerrar: Callable) -> Control:
	var capa := Control.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(_fondo_radial())
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 18
	col.offset_right = -18
	col.offset_top = 44
	col.offset_bottom = -24
	col.add_theme_constant_override("separation", 10)
	capa.add_child(col)
	col.add_child(Tema.etiqueta("OBRA EN CURSO · HITO", 10, Tema.ORO, true))
	col.add_child(Tema.etiqueta(String(obra["nombre"]), 22, Tema.TEXTO, true))
	var iso := ObraIso.new()
	iso.custom_minimum_size = Vector2(0, 250)
	iso.fase = float(MotorObras.fase_de(obra))
	col.add_child(iso)
	var info := Tema.etiqueta("", 12, Tema.TEXTO_SUAVE)
	var nom := Tema.etiqueta("", 16, Tema.TEXTO, true)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	var actualizar := func(f: int) -> void:
		nom.text = "Fase %d · %s" % [f, fases[f - 1]["nombre"]]
		info.text = String(fases[f - 1]["descripcion"])
	for i in range(5):
		var b := Tema.boton(str(i + 1), Tema.PANEL, Tema.TEXTO, 15, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			iso.ir_a(i + 1)
			actualizar.call(i + 1))
		fila.add_child(b)
	col.add_child(fila)
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 8)
	barra.value = 100.0 * float(obra["dias_avanzados"]) / float(obra["dias_totales"])
	barra.add_theme_stylebox_override("background", Tema.caja(Color("#274A66"), 4))
	barra.add_theme_stylebox_override("fill", Tema.caja(Tema.ROJO, 4))
	col.add_child(barra)
	col.add_child(Tema.etiqueta("Día %d de %d · retrasos: %d" % [int(obra["dias_avanzados"]), int(obra["dias_totales"]), int(obra["retrasos"])], 11, Tema.TEXTO_SUAVE))
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", Tema.caja(Tema.CREMA, 14))
	var tv := VBoxContainer.new()
	nom.add_theme_color_override("font_color", Tema.TINTA)
	info.add_theme_color_override("font_color", Tema.TINTA)
	tv.add_child(nom)
	tv.add_child(info)
	var chips := HBoxContainer.new()
	var emp := roundi(float(obra["dias_totales"]) * 1.6 / 10.0) * 10
	var ap := 0.0
	for ef in obra["efectos_final"]:
		ap += float(ef["delta"])
	chips.add_child(PanelesDia._chip("Empleo (ilustrativo)", "+%d" % emp, Color("#DDF1E6")))
	chips.add_child(PanelesDia._chip("Aprobación local", Tema.signo(ap), Color("#FBEFD2")))
	chips.add_child(PanelesDia._chip("Riesgo de retraso", "Bajo" if int(obra["retrasos"]) == 0 else "Medio", Color("#F7D9D5")))
	tv.add_child(chips)
	tarjeta.add_child(tv)
	col.add_child(tarjeta)
	actualizar.call(MotorObras.fase_de(obra))
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(esp)
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 8)
	var rep := Tema.boton("Reproducir obra", Tema.PANEL, Tema.TEXTO, 14, 52)
	rep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rep.pressed.connect(func() -> void:
		iso.reproducir()
		actualizar.call(5))
	var cer := Barras.boton_jugar()
	cer.text = "Volver"
	cer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cer.pressed.connect(func() -> void:
		capa.queue_free()
		al_cerrar.call())
	botones.add_child(rep)
	botones.add_child(cer)
	col.add_child(botones)
	return capa


static func eventos_de_votaciones(motor: MotorTurno) -> Array[Dictionary]:
	## Las leyes que llegaron a votación esta semana se muestran cámara por cámara.
	var evs: Array[Dictionary] = []
	for vt in motor.votaciones_semana:
		var carta: Dictionary = motor._cartas_por_id[vt["carta_id"]]
		var tipo := motor.legal.tipo(String(carta["requisitos"]["ley"]))
		evs.append({"titulo": String(carta["titulo"]), "hora": "VOTACIÓN", "descripcion": String(tipo["nombre"]),
				"efectos": carta["efectos"], "votacion": {"voto": vt["voto"], "tc": vt["tc"], "aprobada": vt["aprobada"], "origen": vt["origen"]}})
	return evs
