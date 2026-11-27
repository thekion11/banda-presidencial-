class_name PanelPresupuesto
extends RefCounted
## Presupuesto extra a ministerios, pestaña «Fondos» del panel Gabinete (pedido literal del usuario del 27-nov-2026:
## «darle presupuesto extra a los ministros para qué hagan sus proyectos con prioridad en nuestras propuestas pero tienen
## autonomía»; PR-18). Por ministerio: nivel (costo fiscal y capital), hasta N prioridades y cuánto del extra responde a
## ellas (autonomía) con su riesgo de incidente. Solo lee y llama a motor.presupuesto (panel(), asignar()).

static var _abierto := ""  # ministerio desplegado


static func crear(motor: MotorTurno, avisar: Callable, al_cambio: Callable) -> Control:
	var p := motor.presupuesto.panel()
	var col := FilasUI.col(8)
	col.add_child(Tema.etiqueta("Presupuesto extra a ministerios", 15, Tema.TEXTO, true))
	col.add_child(Tema.etiqueta("Le das recursos a un ministerio por %d semanas: acelera sus obras y leyes, sobre todo tus prioridades, pero el ministro tiene autonomía y parte del extra va a su propia agenda." % int(p["duracion_semanas"]), 11, Tema.TEXTO_SUAVE))
	col.add_child(Tema.etiqueta("Este año: %s de %s de fiscal usados · %d de %d ministerios con extra · el fiscal no puede bajar de %s" % [Tema.dec(float(p["gastado_anio"]), 0), Tema.dec(float(p["tope_anual"]), 0), int(p["simultaneos"]), int(p["max_simultaneos"]), Tema.dec(float(p["piso_fiscal"]), 0)], 11, Tema.ORO, false, 600))
	var filas: Array = p["ministerios"]
	var orden := func(x: Dictionary) -> int: return 2 if bool(x["activo"]) else (1 if bool(x["puede_asignar"]) else 0)
	filas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return orden.call(a) > orden.call(b))  # con extra, luego los que pueden recibirlo
	for m: Dictionary in filas:
		col.add_child(_fila(motor, p, m, avisar, al_cambio))
	return FilasUI.scroll(col)


static func _alineada(f: float, riesgo: float) -> Control:
	## «Responde a tus prioridades: 62 %» con barra, y el riesgo semanal de incidente.
	var v := FilasUI.col(2)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var barra := FilasUI.chip_barra(f * 100.0, Tema.color_aprobacion(30.0 + f * 30.0))
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(Tema.etiqueta_corta("Responde a tus prioridades", 11, Tema.TEXTO_SUAVE))
	h.add_child(barra)
	h.add_child(Tema.etiqueta_corta(Tema.pct(f * 100.0), 11, Tema.TEXTO, false, 700))
	v.add_child(h)
	v.add_child(Tema.etiqueta("Riesgo de incidente por semana: %s (pide más, discrepa, filtra, desvía o renuncia)" % Tema.pct(riesgo * 100.0), 11, PanelDelegar.color_riesgo(riesgo * 3.0)))
	return v


static func _fila(motor: MotorTurno, p: Dictionary, m: Dictionary, avisar: Callable, al_cambio: Callable) -> Control:
	var slot := String(m["slot"])
	var abierta := _abierto == slot
	var v := FilasUI.col(6)
	var cab := Button.new()
	cab.custom_minimum_size = Vector2(0, Tema.TACTIL)
	for st in ["normal", "hover", "pressed", "focus"]:
		cab.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var fila := HBoxContainer.new()
	fila.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tx := FilasUI.col(0)
	tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tx.custom_minimum_size.x = 1.0
	tx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nom := Tema.etiqueta_corta(TableroGabinete.corto(slot, String(m["cartera"])), 12, Tema.TEXTO, false, 700)
	nom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tx.add_child(nom)
	var sub := Tema.etiqueta_corta(String(m["alias"]), 11, Tema.TEXTO_SUAVE)
	sub.clip_text = true
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tx.add_child(sub)
	fila.add_child(tx)
	var estado := "%s · %d sem" % [String(p["niveles"][m["nivel"]]["nombre"]).replace("Refuerzo ", ""), int(m["semanas_restantes"])] if bool(m["activo"]) else ("Dar extra" if bool(m["puede_asignar"]) else "No ahora")
	var et := Tema.etiqueta_corta(estado, 11, Tema.ORO if bool(m["activo"]) or bool(m["puede_asignar"]) else Tema.TEXTO_SUAVE, false, 700)
	et.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(et)
	cab.add_child(fila)
	cab.pressed.connect(func() -> void:
		_abierto = "" if abierta else slot
		al_cambio.call())  # se rehace el panel con la fila desplegada
	v.add_child(cab)
	if abierta:
		v.add_child(_detalle(motor, p, m, avisar, al_cambio))
	return FilasUI.tarjeta(v, Tema.PANEL, Tema.ORO if abierta else Color(0, 0, 0, 0))


static func _detalle(motor: MotorTurno, p: Dictionary, m: Dictionary, avisar: Callable, al_cambio: Callable) -> Control:
	var slot := String(m["slot"])
	var v := FilasUI.col(6)
	v.add_child(_alineada(float(m["fraccion_alineada"]), float(m["riesgo_desvio"])))
	if bool(m["activo"]):
		var nombres: Array = m["candidatos"].filter(func(c: Dictionary) -> bool: return (m["prioridades"] as Array).has(c["carta_id"])).map(func(c: Dictionary) -> String: return String(c["titulo"]))
		v.add_child(Tema.etiqueta("Prioridades: %s" % (", ".join(nombres) if not nombres.is_empty() else "las del sector, en orden"), 11, Tema.TEXTO_SUAVE))
		return v
	if not bool(m["puede_asignar"]):
		v.add_child(Tema.etiqueta(String(m["mensaje"]), 11, Tema.ORO, false, 600))  # por qué no, y qué hacer (nunca un «no» seco)
		if String(m["alternativa"]) != "":
			v.add_child(Tema.etiqueta(String(m["alternativa"]), 11, Tema.TEXTO_SUAVE))
		return v
	var elegidas: Array = []
	var cands: Array = m["candidatos"]
	if not cands.is_empty():
		v.add_child(Tema.etiqueta("Marca hasta %d prioridades (sin marcar: las del sector, en orden):" % int(p["max_prioridades"]), 11, Tema.TEXTO_SUAVE))
		for c: Dictionary in cands.slice(0, 6):
			var chk := CheckButton.new()
			chk.text = String(c["titulo"])
			chk.custom_minimum_size = Vector2(0, Tema.TACTIL)
			chk.add_theme_font_size_override("font_size", 12)
			chk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			chk.toggled.connect(func(on: bool) -> void:
				if on and elegidas.size() >= int(p["max_prioridades"]):
					chk.set_pressed_no_signal(false)
					return
				if on:
					elegidas.append(String(c["carta_id"]))
				else:
					elegidas.erase(String(c["carta_id"])))
			v.add_child(chk)
	var respuesta := Tema.etiqueta("", 11, Tema.ORO, false, 600)
	for nivel in m["niveles_posibles"]:
		var n: Dictionary = p["niveles"][nivel]
		var costo := "fiscal −%s" % Tema.dec(float(n["fiscal"]), 0) + ("" if float(n["capital"]) <= 0.0 else " · capital −%s" % Tema.dec(float(n["capital"]), 0))
		var b := Tema.boton("%s · %s" % [String(n["nombre"]), costo], Tema.ROJO if nivel == "medio" else Tema.OCEANO.lightened(0.14), Tema.TEXTO, 12, Tema.TACTIL)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func() -> void:
			var r := motor.presupuesto.asignar(slot, String(nivel), elegidas)
			if not bool(r.get("ok", false)):
				respuesta.text = "%s %s" % [String(r.get("mensaje", Razones.texto(r))), String(r.get("alternativa", ""))]
				return
			Feedback.sonar("decision")
			_abierto = slot
			avisar.call("%s: %s por %d semanas; responde a tus prioridades en un %s." % [TableroGabinete.corto(slot, String(m["cartera"])), String(n["nombre"]).to_lower(), int(p["duracion_semanas"]), Tema.pct(float(r["fraccion_alineada"]) * 100.0)])
			al_cambio.call())
		v.add_child(b)
	v.add_child(respuesta)
	return v
