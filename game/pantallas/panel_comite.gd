class_name PanelComite
extends RefCounted
## Comité de Planificación: variantes A/B/C (nivel 1), sliders (nivel 2) y estaciones sobre el grafo con Dijkstra (nivel 3).


static func _scroll(contenido: VBoxContainer) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.add_child(contenido)
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sc


static func crear(motor: MotorTurno, al_aprobar: Callable) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.add_child(Tema.etiqueta("COMITÉ DE PLANIFICACIÓN", 10, Tema.ORO, true))
	var abiertas := motor.estado.propuestas_abiertas
	if abiertas.is_empty():
		col.add_child(Tema.etiqueta("No hay propuestas abiertas. Juega una carta de Comité (Metro, tren) para recibir tres variantes.", 13, Tema.TEXTO_SUAVE))
	for pid in abiertas:
		_propuesta(col, motor, String(pid), al_aprobar)
	return _scroll(col)


static func _propuesta(col: VBoxContainer, motor: MotorTurno, pid: String, al_aprobar: Callable) -> void:
	var prop: Dictionary = motor.catalogo_propuestas[pid]
	col.add_child(Tema.etiqueta(String(prop["titulo"]), 20, Tema.TEXTO, true))
	col.add_child(Tema.etiqueta("Presenta la " + String(prop["presenta"]) + " · cifras ilustrativas", 11, Tema.TEXTO_SUAVE))
	var mapa := ComiteMapa.new()
	mapa.semilla = hash(pid) % 1000
	var pila := Control.new()
	pila.custom_minimum_size = Vector2(0, 220)
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
	b3.pressed.connect(func() -> void:
		if not mapa.editando:
			mapa.modo_3d(true))
	tog.add_child(b2)
	tog.add_child(b3)
	pila.add_child(tog)
	col.add_child(pila)
	var estado := {"v": prop["variantes"][0], "custom": {}}
	var detalle := VBoxContainer.new()
	var edicion := VBoxContainer.new()
	edicion.visible = false
	var fila_v := HBoxContainer.new()
	for v in prop["variantes"]:
		var b := Tema.boton("Variante " + String(v["id"]), Tema.OCEANO.lightened(0.14), Tema.TEXTO, 13, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			mapa.terminar_edicion()
			edicion.visible = false
			estado["v"] = v
			estado["custom"] = {}
			mapa.poner_variante(v["trazado"], bool(v["elevada"]))
			_ficha(detalle, pid, v, prop, motor, al_aprobar, {}, func() -> void: _activar_edicion(mapa, edicion, detalle, pid, estado, prop, motor, al_aprobar)))
		fila_v.add_child(b)
	col.add_child(fila_v)
	col.add_child(edicion)
	col.add_child(detalle)
	var v0: Dictionary = prop["variantes"][0]
	mapa.trazado = v0["trazado"]
	mapa.elevada = bool(v0["elevada"])
	_ficha(detalle, pid, v0, prop, motor, al_aprobar, {}, func() -> void: _activar_edicion(mapa, edicion, detalle, pid, estado, prop, motor, al_aprobar))


static func _activar_edicion(mapa: ComiteMapa, edicion: VBoxContainer, detalle: VBoxContainer, pid: String, estado: Dictionary, prop: Dictionary, motor: MotorTurno, al_aprobar: Callable) -> void:
	if not motor.grafo.listo():
		return
	var base: Dictionary = estado["v"]
	var ests := motor.grafo.estaciones_de(base["trazado"])
	var ctrl := {"ritmo": 0.0, "cobertura": 0.0}
	for h in edicion.get_children():
		h.queue_free()
	edicion.visible = true
	edicion.add_theme_constant_override("separation", 8)
	edicion.add_child(Tema.etiqueta("Modificar trazado · arrastra las estaciones sobre las calles", 13, Tema.ORO, true))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var mas := Tema.boton("+ Estación", Tema.PANEL, Tema.TEXTO, 12, 44)
	var menos := Tema.boton("− Quitar", Tema.PANEL, Tema.TEXTO, 12, 44)
	mas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mas.pressed.connect(mapa.agregar_estacion)
	menos.pressed.connect(mapa.quitar_estacion)
	fila.add_child(mas)
	fila.add_child(menos)
	edicion.add_child(fila)
	var actualizar := func() -> void:
		var custom := {"base": String(base["id"]), "estaciones": mapa.estaciones.duplicate(), "ritmo": snappedf(ctrl["ritmo"], 0.05), "cobertura": snappedf(ctrl["cobertura"], 0.05)}
		estado["custom"] = custom
		if motor.grafo.estaciones_validas(custom["estaciones"]):
			var vm := motor.grafo.variante_modificada(base, custom["estaciones"], custom["ritmo"], custom["cobertura"])
			vm["corrector_texto"] = " ".join(motor.grafo.advertencias(vm, prop))
			_ficha(detalle, pid, vm, prop, motor, al_aprobar, custom, Callable())
	for par in [["ritmo", "Ritmo de construcción: más lento y barato ↔ más rápido y caro"], ["cobertura", "Cobertura: menos población y conflicto ↔ más población y expropiaciones"]]:
		edicion.add_child(Tema.etiqueta(String(par[1]), 11, Tema.TEXTO_SUAVE))
		var sl := HSlider.new()
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.05
		sl.custom_minimum_size = Vector2(0, 32)
		sl.add_theme_stylebox_override("slider", Tema.caja(Color("#274A66"), 4))
		sl.add_theme_stylebox_override("grabber_area", Tema.caja(Tema.ORO, 4))
		sl.add_theme_stylebox_override("grabber_area_highlight", Tema.caja(Tema.ORO.lightened(0.2), 4))
		sl.value_changed.connect(func(v: float) -> void:
			ctrl[par[0]] = v
			actualizar.call())
		edicion.add_child(sl)
	mapa.estaciones_cambiadas.connect(func(_e: Array) -> void: actualizar.call())
	mapa.iniciar_edicion(motor.grafo, ests)


static func _ficha(detalle: VBoxContainer, pid: String, v: Dictionary, prop: Dictionary, motor: MotorTurno, al_aprobar: Callable, custom: Dictionary, al_modificar: Callable) -> void:
	for h in detalle.get_children():
		h.queue_free()
	detalle.add_theme_constant_override("separation", 8)
	detalle.add_child(Tema.etiqueta("Variante %s · %s" % [v["id"], v["nombre"]], 16, Tema.TEXTO, true))
	var cifras := HBoxContainer.new()
	cifras.add_child(PanelesDia._chip("Costo", "US$%s M" % str(roundi(float(v["costo_musd"]))), Tema.CREMA))
	cifras.add_child(PanelesDia._chip("Plazo", "%s años" % str(v["plazo_anios"]), Tema.CREMA))
	cifras.add_child(PanelesDia._chip("Población servida", "%d mil" % int(v["poblacion_miles"]), Tema.CREMA))
	detalle.add_child(cifras)
	var efectos := HBoxContainer.new()
	var nombres := {"aprobacion": "Aprobación regional", "fiscal": "Credibilidad fiscal", "riesgo_ejecucion": "Riesgo de ejecución"}
	var fondos := {"aprobacion": Color("#DDF1E6"), "fiscal": Color("#FBEFD2"), "riesgo_ejecucion": Color("#F7D9D5")}
	for ef in v["efectos"]:
		efectos.add_child(PanelesDia._chip(nombres[ef["ind"]], Tema.signo(float(ef["delta"])), fondos[ef["ind"]]))
	detalle.add_child(efectos)
	detalle.add_child(Tema.etiqueta("Expropiaciones: %d predios · Rechazo vecinal: %s" % [int(v["expropiaciones"]), v["rechazo_vecinal"]], 12, Tema.TEXTO_SUAVE))
	var corr := PanelContainer.new()
	corr.add_theme_stylebox_override("panel", Tema.caja(Color("#FBEFD2"), 10))
	var txt := String(v["corrector_texto"])
	var ratio := float(prop["capacidad_musd"]) / float(v["costo_musd"])
	if custom.is_empty() and ratio < 1.0:
		txt += " (Capacidad fiscal disponible: US$%d M; se construye el %d %% en el primer tramo.)" % [roundi(float(prop["capacidad_musd"])), roundi(ratio * 100.0)]
	corr.add_child(Tema.etiqueta("Corrector de realismo: " + txt, 12, Tema.TINTA))
	detalle.add_child(corr)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	if al_modificar.is_valid():
		var mod := Tema.boton("Modificar trazado", Color.WHITE, Tema.TINTA, 13, 52)
		for e in ["normal", "hover", "pressed"]:
			mod.add_theme_stylebox_override(e, Tema.caja(Color.WHITE, 18, Tema.TINTA, 2))
		mod.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mod.pressed.connect(al_modificar)
		fila.add_child(mod)
	var ok := Barras.boton_jugar()
	ok.text = "Aprobar · %d PA" % int(prop["costo_pa"])
	ok.add_theme_font_size_override("font_size", 14)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.disabled = int(prop["costo_pa"]) > motor.estado.pa_actual
	ok.pressed.connect(func() -> void: al_aprobar.call(pid, String(v["id"]), custom))
	fila.add_child(ok)
	detalle.add_child(fila)
