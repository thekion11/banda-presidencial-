class_name PanelDelegar
extends RefCounted
## Hoja de delegación (DISENO_V2 §5): elige un ministro del gabinete, muestra su probabilidad de fallo ANTES de confirmar
## y ejecuta la carta sin gastar movimientos. Máximo `leyes.delegacion.max_por_turno` por turno.


static func color_riesgo(p: float) -> Color:
	return Tema.SUBE if p <= 0.25 else (Tema.ORO if p <= 0.45 else FilasUI.ROJO_TEXTO)


static func crear(motor: MotorTurno, idx: int, region: String, al_terminar: Callable, al_cerrar: Callable = Callable()) -> Control:
	var est := motor.estado
	var carta: Dictionary = est.mano[idx]
	var maximo := int(motor.catalogo_leyes["delegacion"]["max_por_turno"])
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.62)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(velo)
	var hoja := PanelContainer.new()
	hoja.add_theme_stylebox_override("panel", Tema.caja(Tema.OCEANO, 22, Color("#4C84AE"), 2))
	hoja.anchor_left = 0.0
	hoja.anchor_right = 1.0
	hoja.anchor_top = 1.0
	hoja.anchor_bottom = 1.0
	hoja.offset_left = 8.0
	hoja.offset_right = -8.0
	hoja.offset_top = -560.0
	hoja.offset_bottom = -8.0
	raiz.add_child(hoja)
	var v := FilasUI.col(8)
	hoja.add_child(v)
	v.add_child(Tema.etiqueta("DELEGAR EN UN MINISTRO · %d de %d hoy" % [est.delegadas_turno, maximo], 10, Tema.ORO, true))
	v.add_child(Tema.etiqueta(String(carta["titulo"]), 16, Tema.TEXTO, true))
	v.add_child(Tema.etiqueta("No gasta movimientos, pero puede salir mal: si falla, el efecto se reduce a la mitad y puede haber escándalo.", 11, Tema.TEXTO_SUAVE))
	var cerrar := func() -> void:
		raiz.queue_free()
		if al_cerrar.is_valid():
			al_cerrar.call()
	var motivo := ""
	if est.etapa != "gobierno":
		motivo = "Solo se puede delegar en gobierno."
	elif est.delegadas_turno >= maximo:
		motivo = Razones.texto({"razon": "limite_delegaciones"})
	var lista := FilasUI.col(6)
	var elegido := [""]
	var detalle := Tema.etiqueta("", 12, Tema.TEXTO, false, 600)
	var confirmar := Tema.boton("Delegar", Tema.ROJO, Tema.TEXTO, 15, 48)
	var botones := {}
	var elegir := func(id: String) -> void:
		elegido[0] = id
		var p := motor.prob_fallo_delegacion(idx, id)
		var mi: Dictionary = motor.catalogo_ministros[id]
		detalle.text = "%s: %d %% de fallar. %s" % [mi["alias"], roundi(p * 100.0),
				"Es de su área: ejecuta mejor." if mi["categoria_afin"] == carta["categoria"] else "Fuera de su área: más riesgo."]
		detalle.add_theme_color_override("font_color", color_riesgo(p))
		confirmar.text = "Delegar con %d %% de riesgo" % roundi(p * 100.0)
		confirmar.disabled = motivo != ""
		for k in botones.keys():
			var on: bool = k == id
			for e in ["normal", "hover", "pressed", "focus"]:
				botones[k].add_theme_stylebox_override(e, Tema.caja(Tema.PANEL if not on else Color("#2A6A96"), 14, Tema.ORO if on else Color(0, 0, 0, 0), 2 if on else 0))
	var mejor := ""
	var mejor_p := 2.0
	var orden: Array = est.gabinete.duplicate()
	orden.sort_custom(func(a: String, b: String) -> bool: return motor.prob_fallo_delegacion(idx, a) < motor.prob_fallo_delegacion(idx, b))
	for id in orden:
		var mi: Dictionary = motor.catalogo_ministros[id]
		var p := motor.prob_fallo_delegacion(idx, id)
		if p < mejor_p:
			mejor_p = p
			mejor = id
		var afin: bool = mi["categoria_afin"] == carta["categoria"]
		var b := FilasUI.fila_boton([["%s%s" % [mi["alias"], " · de su área" if afin else ""], 13, Tema.TEXTO, true],
				[mi["cartera"], 11, Tema.TEXTO_SUAVE], ["Probabilidad de fallo: %d %%" % roundi(p * 100.0), 11, color_riesgo(p)]], Tema.PANEL, 62.0)
		botones[id] = b
		b.pressed.connect(elegir.bind(id))
		lista.add_child(b)
	var sc := FilasUI.scroll(lista)
	sc.custom_minimum_size = Vector2(0, 290)
	v.add_child(sc)
	if motivo != "":
		v.add_child(Tema.etiqueta(motivo, 12, Tema.ORO, true))
	v.add_child(detalle)
	confirmar.pressed.connect(func() -> void:
		var r := motor.delegar_carta(idx, String(elegido[0]), region)
		cerrar.call()
		al_terminar.call(r))
	v.add_child(confirmar)
	var cancelar := Tema.boton("Cancelar", Tema.PANEL, Tema.TEXTO, 14, 44)
	cancelar.pressed.connect(cerrar)
	v.add_child(cancelar)
	if mejor != "":
		elegir.call(mejor)
	return raiz
