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
		var mapa := ComiteMapa.new()
		mapa.custom_minimum_size = Vector2(0, 210)
		mapa.semilla = hash(pid) % 1000
		var pila := Control.new()
		pila.custom_minimum_size = Vector2(0, 210)
		mapa.set_anchors_preset(Control.PRESET_FULL_RECT)
		pila.add_child(mapa)
		var tog := HBoxContainer.new()
		tog.anchor_left = 1.0
		tog.anchor_right = 1.0
		tog.offset_left = -96.0
		tog.offset_right = -8.0
		tog.offset_top = 8.0
		var b2 := Tema.boton("2D", Tema.CREMA, Tema.TINTA, 12, 36)
		var b3 := Tema.boton("3D", Tema.OCEANO, Tema.TEXTO, 12, 36)
		b2.custom_minimum_size = Vector2(44, 36)
		b3.custom_minimum_size = Vector2(44, 36)
		b2.pressed.connect(func() -> void: mapa.modo_3d(false))
		b3.pressed.connect(func() -> void: mapa.modo_3d(true))
		tog.add_child(b2)
		tog.add_child(b3)
		pila.add_child(tog)
		col.add_child(pila)
		var detalle := VBoxContainer.new()
		var fila_v := HBoxContainer.new()
		for v in prop["variantes"]:
			var b := Tema.boton("Variante " + String(v["id"]), Tema.OCEANO.lightened(0.14), Tema.TEXTO, 13, 44)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func() -> void:
				mapa.poner_variante(v["trazado"], bool(v["elevada"]))
				_mostrar_variante(detalle, pid, v, prop, motor, al_aprobar))
			fila_v.add_child(b)
		col.add_child(fila_v)
		col.add_child(detalle)
		var v0: Dictionary = prop["variantes"][0]
		mapa.trazado = v0["trazado"]
		mapa.elevada = bool(v0["elevada"])
		_mostrar_variante(detalle, pid, v0, prop, motor, al_aprobar)
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


static func congreso(motor: MotorTurno, al_abrir_obra: Callable = Callable()) -> Control:
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
