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


static func comite(motor: MotorTurno, al_aprobar: Callable) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.add_child(Tema.etiqueta("COMITÉ DE PLANIFICACIÓN", 10, Tema.ORO, true))
	var abiertas := motor.estado.propuestas_abiertas
	if abiertas.is_empty():
		col.add_child(Tema.etiqueta("No hay propuestas abiertas. Juega una carta de Comité (Metro, tren) para recibir tres variantes.", 13, Tema.TEXTO_SUAVE))
	for pid in abiertas:
		var prop: Dictionary = motor.catalogo_propuestas[pid]
		col.add_child(Tema.etiqueta(String(prop["titulo"]), 20, Tema.TEXTO, true))
		col.add_child(Tema.etiqueta("Presenta la " + String(prop["presenta"]) + " · cifras ilustrativas", 11, Tema.TEXTO_SUAVE))
		var detalle := VBoxContainer.new()
		var fila_v := HBoxContainer.new()
		for v in prop["variantes"]:
			var b := Tema.boton("Variante " + String(v["id"]), Tema.OCEANO.lightened(0.14), Tema.TEXTO, 13, 44)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(_mostrar_variante.bind(detalle, pid, v, prop, motor, al_aprobar))
			fila_v.add_child(b)
		col.add_child(fila_v)
		col.add_child(detalle)
		_mostrar_variante(detalle, pid, prop["variantes"][0], prop, motor, al_aprobar)
	return _scroll(col)


static func _mostrar_variante(detalle: VBoxContainer, pid: String, v: Dictionary, prop: Dictionary, motor: MotorTurno, al_aprobar: Callable) -> void:
	for h in detalle.get_children():
		h.queue_free()
	detalle.add_theme_constant_override("separation", 8)
	detalle.add_child(Tema.etiqueta("Variante %s · %s" % [v["id"], v["nombre"]], 16, Tema.TEXTO, true))
	var cifras := HBoxContainer.new()
	cifras.add_child(_chip("Costo", "US$%s M" % str(roundi(float(v["costo_musd"]))), Tema.CREMA))
	cifras.add_child(_chip("Plazo", "%s años" % str(v["plazo_anios"]), Tema.CREMA))
	cifras.add_child(_chip("Población servida", "%d mil" % int(v["poblacion_miles"]), Tema.CREMA))
	detalle.add_child(cifras)
	var efectos := HBoxContainer.new()
	var nombres := {"aprobacion": "Aprobación regional", "fiscal": "Credibilidad fiscal", "riesgo_ejecucion": "Riesgo de ejecución"}
	var fondos := {"aprobacion": Color("#DDF1E6"), "fiscal": Color("#FBEFD2"), "riesgo_ejecucion": Color("#F7D9D5")}
	for ef in v["efectos"]:
		efectos.add_child(_chip(nombres[ef["ind"]], Tema.signo(float(ef["delta"])), fondos[ef["ind"]]))
	detalle.add_child(efectos)
	detalle.add_child(Tema.etiqueta("Expropiaciones: %d predios · Rechazo vecinal: %s" % [int(v["expropiaciones"]), v["rechazo_vecinal"]], 12, Tema.TEXTO_SUAVE))
	var corr := PanelContainer.new()
	corr.add_theme_stylebox_override("panel", Tema.caja(Color("#FBEFD2"), 10))
	var ratio := float(prop["capacidad_musd"]) / float(v["costo_musd"])
	var txt := String(v["corrector_texto"])
	if ratio < 1.0:
		txt += " (Capacidad fiscal disponible: US$%d M; se construye el %d %% en el primer tramo.)" % [roundi(float(prop["capacidad_musd"])), roundi(ratio * 100.0)]
	corr.add_child(Tema.etiqueta("Corrector de realismo: " + txt, 12, Tema.TINTA))
	detalle.add_child(corr)
	var ok := Tema.boton("Aprobar · %d PA" % int(prop["costo_pa"]), Tema.ROJO)
	ok.disabled = int(prop["costo_pa"]) > motor.estado.pa_actual
	ok.pressed.connect(func() -> void: al_aprobar.call(pid, String(v["id"])))
	detalle.add_child(ok)


static func congreso(motor: MotorTurno) -> Control:
	var est := motor.estado
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.add_child(Tema.etiqueta("CONGRESO", 10, Tema.ORO, true))
	var propios := int(est.partido.get("escanos_propios", 0))
	col.add_child(Tema.etiqueta("Tu bancada: %d de 50 senadores · %d de 155 diputados" % [propios, roundi(float(propios) * 155.0 / 50.0)], 14, Tema.TEXTO, true))
	var h := Hemiciclo.new()
	h.custom_minimum_size = Vector2(0, 150)
	h.configurar(50, propios, 0)
	col.add_child(h)
	col.add_child(Tema.etiqueta("Proyectos en tramitación", 15, Tema.TEXTO, true))
	if est.proyectos_ley.is_empty():
		col.add_child(Tema.etiqueta("Ninguno. Las cartas con ley (quórum calificado, ley simple) entran aquí y se votan en ambas cámaras.", 12, Tema.TEXTO_SUAVE))
	for p in est.proyectos_ley:
		var c: Dictionary = motor._cartas_por_id[p["carta_id"]]
		var t := motor.legal.tipo(String(p["tipo_ley"]))
		col.add_child(_tarjeta(Tema.etiqueta("%s\n%s · votación el día %d · mínimo %d senadores" % [c["titulo"], t["nombre"], int(p["dia_votacion"]), int(t["votos_minimos"])], 12, Tema.TEXTO)))
	col.add_child(Tema.etiqueta("Obras en curso", 15, Tema.TEXTO, true))
	if est.obras_en_curso.is_empty():
		col.add_child(Tema.etiqueta("Sin obras en curso.", 12, Tema.TEXTO_SUAVE))
	for o in est.obras_en_curso:
		var fase := MotorObras.fase_de(o)
		col.add_child(_tarjeta(Tema.etiqueta("%s\nFase %d de 5: %s · %d %%" % [o["nombre"], fase, MotorObras.FASES[fase - 1], roundi(100.0 * float(o["dias_avanzados"]) / float(o["dias_totales"]))], 12, Tema.TEXTO)))
	if not est.promesas_campana.is_empty():
		col.add_child(Tema.etiqueta("Metas de legado (promesas de campaña)", 15, Tema.TEXTO, true))
		for pr in est.promesas_campana:
			col.add_child(Tema.etiqueta(("Cumplida · " if pr["cumplida"] else "Pendiente · ") + String(pr["titulo"]), 12, Tema.SUBE if pr["cumplida"] else Tema.TEXTO))
	return _scroll(col)


static func gabinete(motor: MotorTurno, elegido: String, al_elegir: Callable) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.add_child(Tema.etiqueta("GABINETE · 25 MINISTERIOS", 10, Tema.ORO, true))
	col.add_child(Tema.etiqueta("Delegar la próxima carta a un ministro baja su costo en PA y mejora la ejecución si es de su área, a cambio de riesgo de escándalo.", 12, Tema.TEXTO_SUAVE))
	var ninguno := Tema.boton("Sin delegar" + (" (elegido)" if elegido == "" else ""), Tema.OCEANO.lightened(0.14), Tema.TEXTO, 13, 44)
	ninguno.pressed.connect(func() -> void: al_elegir.call(""))
	col.add_child(ninguno)
	var disponible := motor.estado.etapa == "gobierno"
	if not disponible:
		col.add_child(Tema.etiqueta("El gabinete se forma al asumir la presidencia.", 12, Tema.ORO))
	for id in motor.catalogo_ministros.keys():
		var m: Dictionary = motor.catalogo_ministros[id]
		var b := Tema.boton("%s · %s%s\n%s" % [m["alias"], m["categoria_afin"], " (elegido)" if elegido == id else "", m["cartera"]], Tema.PANEL, Tema.TEXTO, 12, 56)
		b.disabled = not disponible
		b.pressed.connect(func() -> void: al_elegir.call(id))
		col.add_child(b)
	return _scroll(col)


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


static func evento(ev: Dictionary, al_continuar: Callable, total_senadores: int, dia: int = 0) -> Control:
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
	var v: Variant = ev.get("votacion", null)
	var cab := ("SENADO · %s" % String(ev["hora"])) if v != null else ("EVENTO · %s" % String(ev["hora"]))
	if dia > 0:
		cab += " · DÍA %d" % dia
	col.add_child(_centrada(cab, 11, Tema.ORO, true))
	col.add_child(_centrada(String(ev["titulo"]), 25, Tema.TEXTO, true))
	col.add_child(_centrada(String(ev["descripcion"]), 13, Tema.TEXTO_SUAVE))
	var consecuencia := ""
	var sello := ""
	if v != null:
		var voto: Dictionary = v["voto"]
		var abst := roundi(0.35 * float(voto["en_contra_senado"]))
		var h := Hemiciclo.new()
		h.custom_minimum_size = Vector2(0, 230)
		h.configurar(total_senadores, int(voto["senado"]), int(voto["en_contra_senado"]) - abst, abst, true)
		col.add_child(h)
		var leyenda := HBoxContainer.new()
		leyenda.alignment = BoxContainer.ALIGNMENT_CENTER
		leyenda.add_theme_constant_override("separation", 12)
		for par in [[Tema.SUBE, "A favor %d" % int(voto["senado"])], [Color("#9AA9C0"), "Abstención %d" % abst], [Tema.BAJA, "En contra %d" % (int(voto["en_contra_senado"]) - abst)]]:
			leyenda.add_child(Icono.crear("dot", par[0], 12.0))
			leyenda.add_child(Tema.etiqueta_corta(par[1], 11, Tema.TEXTO_SUAVE))
		col.add_child(leyenda)
		sello = "APROBADA" if voto["aprobada"] else "RECHAZADA"
		var tc: Dictionary = v["tc"]
		if not bool(voto["aprobada"]):
			consecuencia = "El proyecto no alcanzó el quórum (Cámara: %d de %d requeridos): pierdes capital político." % [int(voto["camara"]), int(voto["min_camara"])]
		elif bool(tc["recurso"]) and bool(tc["cae"]):
			consecuencia = "El Tribunal Constitucional acoge el recurso de la oposición: la norma cae y pierdes capital político."
		elif bool(tc["recurso"]):
			consecuencia = "La oposición recurrió al Tribunal Constitucional, pero fue rechazado: la norma se promulga."
		else:
			consecuencia = "Aprobada en ambas cámaras (Cámara: %d votos, mínimo %d). Se promulga sin reparos." % [int(voto["camara"]), int(voto["min_camara"])]
	if sello != "":
		var ok: bool = v["voto"]["aprobada"]
		var color := Tema.SUBE if ok else Tema.BAJA
		var sc := CenterContainer.new()
		var caja := PanelContainer.new()
		caja.add_theme_stylebox_override("panel", Tema.caja(Color(color, 0.12), 10, color, 3))
		var lt := Tema.etiqueta_corta(sello, 30, color, true)
		lt.add_theme_constant_override("outline_size", 0)
		caja.add_child(lt)
		caja.pivot_offset = Vector2(100, 24)
		sc.add_child(caja)
		caja.set_deferred("rotation_degrees", -4.0)
		sc.custom_minimum_size = Vector2(0, 70)
		col.add_child(sc)
	var efectos: Variant = ev.get("efectos", null)
	if (efectos != null and not efectos.is_empty()) or consecuencia != "":
		var tarjeta := PanelContainer.new()
		tarjeta.add_theme_stylebox_override("panel", Tema.caja(Color(0.06, 0.18, 0.3, 0.55), 14, Color("#2B5D86"), 1))
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 8)
		cv.add_child(Tema.etiqueta("Consecuencias", 14, Tema.TEXTO, true))
		if efectos != null and not efectos.is_empty():
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
			cv.add_child(fila)
		if consecuencia != "":
			cv.add_child(Tema.etiqueta(consecuencia, 12, Tema.TEXTO))
		tarjeta.add_child(cv)
		col.add_child(tarjeta)
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(esp)
	var b := Barras.boton_jugar()
	b.text = "Continuar"
	b.pressed.connect(func() -> void:
		capa.queue_free()
		al_continuar.call())
	col.add_child(b)
	return capa
