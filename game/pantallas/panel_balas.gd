class_name PanelBalas
extends RefCounted
## Baúl de las balas de plata (pedido del usuario del 27-nov-2026: «falta poder usar las balas de plata»; PR-17). Hoja
## sobre el día, como la de delegar: las 7 balas con su costo en capital, su riesgo y por qué no se pueden usar ahora
## (con la alternativa: nunca un «no» seco). Usar pide un segundo toque que confirma costo y riesgo. Solo lee y llama a
## motor.balas (baul() y usar()).


static func _efectos(lista: Array) -> String:
	## «Aprob. +2 · Cohes. −1»: los efectos de una bala son puntos enteros (sin «,00»).
	var partes: Array[String] = []
	for ef in lista:
		var x := float(ef["delta"])
		var cifra := str(absi(roundi(x))) if absf(x - roundf(x)) < 0.05 else Tema.dec(absf(x))
		partes.append("%s %s%s" % [String(TableroGabinete.NOMBRES_IND.get(String(ef["ind"]), ef["ind"])), "+" if x >= 0.0 else "−", cifra])
	return " · ".join(partes)


static func crear(motor: MotorTurno, al_usar: Callable, al_cerrar: Callable = Callable()) -> Control:
	var b := motor.balas.baul()
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.62)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(velo)
	var cerrar := func() -> void:
		raiz.queue_free()
		if al_cerrar.is_valid():
			al_cerrar.call()
	raiz.set_meta("atras", cerrar)  # botón Atrás de Android
	velo.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and not ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			cerrar.call())
	var hoja := PanelContainer.new()
	hoja.add_theme_stylebox_override("panel", Tema.caja(Tema.OCEANO, 22, Tema.ORO, 2))
	hoja.anchor_right = 1.0
	hoja.anchor_top = 1.0
	hoja.anchor_bottom = 1.0
	hoja.offset_left = 8.0
	hoja.offset_right = -8.0
	hoja.offset_top = -minf(620.0, Tema.alto_util() - Tema.margen_superior() - 24.0)
	hoja.offset_bottom = -8.0 - Tema.margen_inferior()
	raiz.add_child(hoja)
	var v := FilasUI.col(8)
	hoja.add_child(v)
	var cab := HBoxContainer.new()
	var tv := FilasUI.col(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(Tema.etiqueta_corta("BALAS DE PLATA · %d de %d disponibles" % [int(b["usos_restantes"]), int(b["usos_habilitados"])], 10, Tema.ORO, true))
	tv.add_child(Tema.etiqueta("Recursos extraordinarios: no cuestan movimientos sino capital político, y cada una sirve una vez por mandato.", 11, Tema.TEXTO_SUAVE))
	if int(b["semanas_espera"]) > 0:
		tv.add_child(Tema.etiqueta("La próxima se puede usar en %d %s." % [int(b["semanas_espera"]), "semana" if int(b["semanas_espera"]) == 1 else "semanas"], 11, Tema.ORO, false, 600))
	cab.add_child(tv)
	var x := Tema.boton("×", Color(0, 0, 0, 0), Tema.TEXTO, 22, Tema.TACTIL)
	x.custom_minimum_size = Vector2(Tema.TACTIL, Tema.TACTIL)
	x.pressed.connect(cerrar)
	cab.add_child(x)
	v.add_child(cab)
	var lista := FilasUI.col(8)
	var confirmar := {"id": ""}
	for it: Dictionary in b["items"]:
		lista.add_child(_tarjeta(motor, it, confirmar, al_usar, cerrar))
	v.add_child(FilasUI.scroll(lista))
	if Movimiento.activo():  # el baúl se abre: la hoja sube desde abajo y las balas entran de a una
		Movimiento.aparecer(hoja, 0.0, Movimiento.BASE)
		Movimiento.escalonar(lista, 0.12, 0.05, 7)
	return raiz


static func destello(capa: Node, mal: bool) -> void:
	## Al usar una bala: destello plateado sobre la pantalla; si salió mal, rojo y una vibración.
	if not Movimiento.activo() or capa == null or not capa.is_inside_tree():
		return
	var f := ColorRect.new()
	f.color = Color(Tema.ROJO, 0.45) if mal else Color(Tema.CREMA, 0.55)
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(f)
	var tw := f.create_tween()
	tw.tween_property(f, "color:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(f.queue_free)
	Feedback.vibrar(40 if mal else 20)


static func _tarjeta(motor: MotorTurno, it: Dictionary, confirmar: Dictionary, al_usar: Callable, cerrar: Callable) -> Control:
	var usada := bool(it["usada"])
	var t := FilasUI.col(4)
	var arriba := HBoxContainer.new()
	var tit := Tema.etiqueta(String(it["titulo"]), 13, Tema.TEXTO if not usada else Tema.TEXTO_SUAVE, true)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(tit)
	arriba.add_child(Tema.etiqueta_corta("capital %s" % Tema.dec(float(it["costo_capital"]), 0), 11, Tema.ORO, false, 700))
	t.add_child(arriba)
	t.add_child(Tema.etiqueta(String(it["texto"]), 11, Tema.TEXTO_SUAVE))
	var ef := _efectos(it["efectos"])
	var riesgo := float(it["riesgo_estimado"])
	t.add_child(Tema.etiqueta("%sRiesgo %s: %s" % ["" if ef == "" else ef + " · ", Tema.pct(riesgo * 100.0), String(it["riesgo_texto"])], 11, PanelDelegar.color_riesgo(riesgo), false, 600))
	var objs: Array = it["objetivos"]
	if not objs.is_empty():
		var lejos: Dictionary = objs[0]
		for o in objs:
			if int(o["dias"]) > int(lejos["dias"]):
				lejos = o
		t.add_child(Tema.etiqueta("Actúa sobre: %s (el más lejano de votarse)" % String(lejos["titulo"]), 11, Tema.TEXTO_SUAVE))
	if usada:
		t.add_child(Tema.etiqueta("Ya la usaste en la semana %d." % int(it["turno_uso"]), 11, Tema.TEXTO_SUAVE))
	elif not bool(it["disponible"]) and not bool(it["viable_reducida"]):
		t.add_child(Tema.etiqueta(String(it["mensaje"]), 11, Tema.ORO, false, 600))  # por qué no, y qué hacer (nunca un «no» seco)
		if String(it["alternativa"]) != "":
			t.add_child(Tema.etiqueta(String(it["alternativa"]), 11, Tema.TEXTO_SUAVE))
	else:
		var reducida := not bool(it["disponible"])
		if reducida:
			t.add_child(Tema.etiqueta(String(it["mensaje"]), 11, Tema.ORO, false, 600))
		var usar := Tema.boton("Versión reducida" if reducida else "Usar", Tema.ROJO, Tema.TEXTO, 14, Tema.TACTIL)
		usar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var respuesta := Tema.etiqueta("", 11, Tema.ORO, false, 600)
		usar.pressed.connect(func() -> void:
			if confirmar["id"] != it["id"]:  # primer toque: confirma costo y riesgo
				confirmar["id"] = it["id"]
				usar.text = "Confirmar · capital %s · riesgo %s" % [Tema.dec(float(it["costo_capital"]), 0), Tema.pct(riesgo * 100.0)]
				return
			var r := motor.balas.usar(String(it["id"]), -1, reducida)
			if not bool(r.get("ok", false)):
				respuesta.text = "%s %s" % [String(r.get("mensaje", Razones.texto(r))), String(r.get("alternativa", ""))]
				return
			Feedback.sonar("decision")
			var capa_dia: Node = hoja_raiz(usar)
			cerrar.call()
			destello(capa_dia, bool(r.get("salio_mal", false)))
			al_usar.call("Salió mal: %s" % String(r.get("texto_riesgo", "")) if bool(r.get("salio_mal", false)) else "Usaste «%s»." % String(it["titulo"])))
		t.add_child(usar)
		t.add_child(respuesta)
	var tarjeta := FilasUI.tarjeta(t, Tema.PANEL if not usada else Color(Tema.PANEL, 0.5))
	if usada:
		tarjeta.modulate.a = 0.75
	return tarjeta


static func hoja_raiz(n: Node) -> Node:
	## La capa del día que contiene la hoja del baúl (para el destello, que sigue después de cerrarla).
	var p := n
	while p != null and not p.has_meta("atras"):
		p = p.get_parent()
	return p.get_parent() if p != null else null

