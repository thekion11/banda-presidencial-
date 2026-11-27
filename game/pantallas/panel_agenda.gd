class_name PanelAgenda
extends RefCounted
## Agenda legislativa del gobierno en la pestaña Congreso (pedido del usuario del 27-nov-2026: «Falta poder solicitar que
## se presenten leyes desdé mi gobierno»). Solo lee y llama a motor.agenda (docs/DECISIONES.md §BM): proyectos en
## trámite, catálogo por categoría con su costo en movimientos, urgencias con capital y probabilidad, delegar en el
## ministro del área y el Corrector como alternativas tocables (nunca un «no» seco).

const POR_PAGINA := 8


static func _area(cat: String) -> String:
	return "Descentralización" if cat == "descentralizacion" else String(TableroGabinete.AREAS.get(cat, cat.capitalize()))


static func _costo(n: int) -> HBoxContainer:
	## «⚡ 2»: costo en movimientos con el mismo rayo de la cabecera.
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 2)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := Icono.crear("bolt", Tema.ORO, 16.0, true)  # tamaño de la guía junto a texto
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	h.add_child(Tema.etiqueta_corta(str(n), 12, Tema.ORO, true))
	return h


static func tramite(motor: MotorTurno) -> VBoxContainer:
	## Proyectos del gobierno en trámite: etapa, cámara, semanas restantes, probabilidad estimada y si va delegado.
	var col := FilasUI.col(6)
	var ea := motor.agenda.estado_agenda()
	col.add_child(Tema.etiqueta("Agenda del gobierno · %d de %d en trámite" % [int(ea["en_tramite"]), int(ea["maximo"])], 15, Tema.TEXTO, true))
	var lista := motor.agenda.en_tramite()
	if lista.is_empty():
		col.add_child(Tema.etiqueta("Aún no presentas proyectos propios. Abajo eliges uno y su urgencia.", 12, Tema.TEXTO_SUAVE))
	for p in lista:
		var v := FilasUI.col(3)
		v.add_child(Tema.etiqueta(String(p["titulo"]), 12, Tema.TEXTO, false, 600))
		var donde := String(p["etapa_nombre"]) + ((" · " + String(motor.catalogo_leyes["congreso"]["nombres"].get(p["camara"], p["camara"]))) if String(p["camara"]) != "" else "")
		v.add_child(Tema.etiqueta("%s · faltan %d %s%s" % [donde, int(p["semanas_restantes"]), "semana" if int(p["semanas_restantes"]) == 1 else "semanas", " · delegado" if bool(p["delegada"]) else ""], 11, Tema.TEXTO_SUAVE))
		var prob := float(p["prob_aprobacion"])
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		var barra := FilasUI.chip_barra(prob * 100.0, PanelDelegar.color_riesgo(1.0 - prob))
		barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(barra)
		fila.add_child(Tema.etiqueta_corta("aprobación %s" % Tema.pct(prob * 100.0), 11, Tema.TEXTO, false, 600))
		v.add_child(fila)
		col.add_child(FilasUI.tarjeta(v))
	return col


static func presentar(motor: MotorTurno, al_presentar: Callable, abierto_inicial: String = "") -> VBoxContainer:
	## «Presentar un proyecto»: categorías, catálogo y, al tocar uno, sus urgencias, la delegación y el Corrector.
	## Atajo: el chip «En tu mano» reúne las leyes de tu mano, y la carta elegida en la mano llega ya desplegada.
	var col := FilasUI.col(8)
	col.add_child(Tema.etiqueta("Presentar un proyecto", 15, Tema.TEXTO, true))
	var ea := motor.agenda.estado_agenda()
	if not bool(ea["puede_presentar"]):
		col.add_child(Tema.etiqueta(Razones.texto({"razon": ea["razon"]}), 12, Tema.ORO, false, 600))
		return col
	var catalogo := motor.agenda.agenda_catalogo()
	if catalogo.is_empty():
		col.add_child(Tema.etiqueta("Con tu gabinete y esta etapa no hay proyectos de ley presentables. Revisa el gabinete o espera la próxima ventana.", 12, Tema.TEXTO_SUAVE))
		return col
	var en_mano := {}
	for c in motor.estado.mano:
		en_mano[String(c["id"])] = true
	var hay_mano := catalogo.any(func(e: Dictionary) -> bool: return en_mano.has(String(e["carta_id"])))
	var cats: Array[String] = (["mano", ""] as Array[String]) if hay_mano else ([""] as Array[String])
	for e in catalogo:
		if not cats.has(String(e["categoria"])):
			cats.append(String(e["categoria"]))
	var inicial_en := catalogo.any(func(e: Dictionary) -> bool: return String(e["carta_id"]) == abierto_inicial)
	var estado := {"cat": "mano" if hay_mano else "", "abierto": abierto_inicial if inicial_en else "", "max": POR_PAGINA}
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	var sc := ScrollContainer.new()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, Tema.TACTIL)
	sc.add_child(chips)
	col.add_child(sc)
	var lista := FilasUI.col(6)
	col.add_child(lista)
	var acc := {}
	acc["pintar"] = func() -> void:
		for c in chips.get_children():
			var on: bool = String(c.get_meta("cat")) == estado["cat"]
			for e in ["normal", "hover", "pressed"]:
				(c as Button).add_theme_stylebox_override(e, Tema.caja(Tema.ORO if on else Tema.PANEL, 22, Tema.ORO, 1))
			(c as Button).add_theme_color_override("font_color", Tema.TINTA if on else Tema.TEXTO)
		for h in lista.get_children():
			h.queue_free()
		var vistos := 0
		for e in catalogo:
			if estado["cat"] == "mano" and not en_mano.has(String(e["carta_id"])):
				continue
			if estado["cat"] != "" and estado["cat"] != "mano" and String(e["categoria"]) != estado["cat"]:
				continue
			vistos += 1
			if vistos > int(estado["max"]):
				var mas := Tema.boton("Ver más proyectos", Tema.OCEANO.lightened(0.14), Tema.TEXTO, 12, Tema.TACTIL)
				mas.pressed.connect(func() -> void:
					estado["max"] = int(estado["max"]) + POR_PAGINA
					acc["pintar"].call())
				lista.add_child(mas)
				break
			lista.add_child(_entrada(motor, e, String(estado["abierto"]) == String(e["carta_id"]), func() -> void:
				estado["abierto"] = "" if estado["abierto"] == e["carta_id"] else String(e["carta_id"])
				acc["pintar"].call(), al_presentar))
	for cat in cats:
		var b := Tema.boton("Todas" if cat == "" else ("En tu mano" if cat == "mano" else _area(cat)), Tema.PANEL, Tema.TEXTO, 12, Tema.TACTIL)
		b.set_meta("cat", cat)
		b.pressed.connect(func() -> void:
			estado["cat"] = cat
			estado["abierto"] = ""
			estado["max"] = POR_PAGINA
			acc["pintar"].call())
		chips.add_child(b)
	acc["pintar"].call()
	return col


static func _entrada(motor: MotorTurno, e: Dictionary, abierta: bool, al_tocar: Callable, al_presentar: Callable) -> Control:
	var v := FilasUI.col(6)
	var cab := Button.new()
	cab.custom_minimum_size = Vector2(0, 52)
	for st in ["normal", "hover", "pressed", "focus"]:
		cab.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	cab.pressed.connect(al_tocar)
	var fila := HBoxContainer.new()
	fila.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fila.add_theme_constant_override("separation", 8)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tx := FilasUI.col(1)
	tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tx.custom_minimum_size.x = 1.0
	tx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var titulo := Tema.etiqueta_corta(String(e["titulo"]), 12, Tema.TEXTO, false, 600)
	titulo.clip_text = true
	titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tx.add_child(titulo)
	var simple: Dictionary = e["urgencias"][0]
	var sub := Tema.etiqueta_corta("aprobación %s · %s · %s" % [Tema.pct(float(simple["prob"]) * 100.0), _area(String(e["categoria"])), String(motor.legal.tipo(String(e["tipo_ley"])).get("nombre", e["tipo_ley"]))], 11, Tema.TEXTO_SUAVE)
	sub.clip_text = true  # lo importante va primero: si no cabe, se corta el tipo de ley
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tx.add_child(sub)
	for l in tx.get_children():
		(l as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(tx)
	fila.add_child(_costo(int(e["costo_mov"])))
	cab.add_child(fila)
	v.add_child(cab)
	if abierta:
		v.add_child(_detalle(motor, e, al_presentar))
	return FilasUI.tarjeta(v, Tema.PANEL, Tema.ORO if abierta else Color(0, 0, 0, 0))


static func _detalle(motor: MotorTurno, e: Dictionary, al_presentar: Callable) -> VBoxContainer:
	var v := FilasUI.col(6)
	var id := String(e["carta_id"])
	var carta: Dictionary = motor._cartas_por_id[id]
	var ministro := motor.gabinete.titular(String(e["categoria"]))
	var delegar := CheckButton.new()
	delegar.custom_minimum_size = Vector2(0, Tema.TACTIL)
	delegar.add_theme_font_size_override("font_size", 12)
	delegar.text = "Delegar en el ministro"
	if ministro != "" and bool(motor.gabinete.validar_delegacion(ministro)["ok"]):
		delegar.text = "Delegar en %s · no gasta movimientos · falla %s" % [motor.catalogo_ministros[ministro]["alias"], Tema.pct(motor.gabinete.prob_fallo(carta, ministro) * 100.0)]
	else:
		delegar.disabled = true
	delegar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var respuesta := FilasUI.col(4)
	v.add_child(Tema.etiqueta("Elige la urgencia (más rápida cuesta capital político):", 11, Tema.TEXTO_SUAVE))
	for u in e["urgencias"]:
		var b := Tema.boton("%s · %d días · capital %s · aprobación %s" % [u["nombre"], int(u["dias"]), Tema.dec(float(u["costo_capital"]), 0), Tema.pct(float(u["prob"]) * 100.0)], Tema.ROJO if String(u["id"]) == "simple" else Tema.OCEANO.lightened(0.14), Tema.TEXTO, 12, Tema.TACTIL)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.disabled = not bool(u["alcanza"])
		b.pressed.connect(func() -> void: _enviar(motor, id, String(u["id"]), ministro, delegar.button_pressed, respuesta, al_presentar))
		v.add_child(b)
	v.add_child(delegar)
	if not (e["corrector"] as Dictionary).is_empty():
		v.add_child(Tema.etiqueta("Apoyo bajo en el Congreso. Alternativas:", 11, Tema.ORO, false, 600))
		_opciones(motor, id, ministro, delegar, e["corrector"], respuesta, al_presentar)
	v.add_child(respuesta)
	return v


static func _enviar(motor: MotorTurno, id: String, urgencia: String, ministro: String, delegar: bool, respuesta: VBoxContainer, al_presentar: Callable) -> void:
	var r := motor.agenda.presentar(id, urgencia, ministro, delegar)
	if bool(r.get("ok", false)):
		Feedback.sonar("decision")
		al_presentar.call("Proyecto presentado: «%s», urgencia %s. Lo ves arriba, en la agenda del gobierno." % [motor._cartas_por_id[id]["titulo"], String(motor.agenda.urgencia(urgencia)["nombre"]).to_lower()])
		return
	for h in respuesta.get_children():
		h.queue_free()
	respuesta.add_child(Tema.etiqueta(Razones.texto(r), 12, Tema.ORO, false, 600))  # el Corrector: nunca un «no» seco
	if r.has("corrector"):
		_opciones(motor, id, ministro, null, r["corrector"], respuesta, al_presentar)


static func _opciones(motor: MotorTurno, id: String, ministro: String, delegar: CheckButton, corrector: Dictionary, destino: VBoxContainer, al_presentar: Callable) -> void:
	## Opciones del Corrector: otra urgencia (tocable: la presenta así), versión por tramos o esperar (solo explican).
	for o in corrector.get("opciones", []):
		if String(o["tipo"]) == "urgencia":
			var b := Tema.boton(String(o["texto"]), Tema.OCEANO.lightened(0.14), Tema.TEXTO, 12, Tema.TACTIL)
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.pressed.connect(func() -> void: _enviar(motor, id, String(o["urgencia"]), ministro, delegar != null and delegar.button_pressed, destino, al_presentar))
			destino.add_child(b)
		else:
			destino.add_child(Tema.etiqueta("· " + String(o["texto"]), 11, Tema.TEXTO_SUAVE))
