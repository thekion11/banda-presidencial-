class_name GolpePrensa
extends RefCounted
## Escándalo con peso (dirección visual v4): la pantalla se tiñe de rojo un instante, entra girando un titular de
## prensa con el ministerio y el alias del ministro, y los chips de Aprobación y Capital tiemblan. Solo presentación:
## el castigo ya lo aplicó el motor. Sin animaciones no hace nada (el aviso de texto de siempre sigue apareciendo).


static func ministro_del_escandalo(motor: MotorTurno, desde: int) -> Dictionary:
	## El ministro del escándalo recién registrado (o {} si el registro no lo trae).
	var reg: Array = motor.estado.registro_acciones
	for i in range(reg.size() - 1, maxi(desde, 0) - 1, -1):
		if reg[i]["tipo"] == "escandalo_ministro":
			return motor.catalogo_ministros.get(String(reg[i]["detalle"].get("ministro", "")), {})
	return {}


static func mostrar(capa: Control, ministro: Dictionary, chips: Array) -> void:
	if not Movimiento.activo():
		return
	Feedback.sonar("alerta")
	Feedback.vibrar(90)
	var rojo := ColorRect.new()  # destello rojo con viñeta (suave con «Reducir movimiento»)
	rojo.color = Color(Tema.ROJO, 0.42 if Movimiento.intenso() else 0.15)
	rojo.set_anchors_preset(Control.PRESET_FULL_RECT)
	rojo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(rojo)
	var tr := rojo.create_tween()
	tr.tween_property(rojo, "color:a", 0.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tr.tween_callback(rojo.queue_free)
	var hoja := PanelContainer.new()  # titular de diario
	var sb := Tema.caja(Tema.CREMA, 6, Tema.TINTA, 2)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 14
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 14
	hoja.add_theme_stylebox_override("panel", sb)
	hoja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	var cinta := Tema.etiqueta_corta("ÚLTIMA HORA · POLÉMICA", 11, Tema.ROJO, true)
	v.add_child(cinta)
	var cartera := String(ministro.get("cartera", "el gabinete"))
	v.add_child(Tema.etiqueta("Estalla una polémica en %s%s" % ["el " if cartera.begins_with("Ministerio") else "", cartera], 20, Tema.TINTA, true))
	if ministro.has("alias"):
		v.add_child(Tema.etiqueta("La prensa cuestiona a %s (personaje ficticio). El gobierno pierde aprobación y capital político." % String(ministro["alias"]), 12, Tema.GRIS_CLARO, false, 600))
	hoja.add_child(v)
	var marco := Control.new()  # soporte de tamaño fijo fuera de contenedores: gira y escala sin que nadie lo reacomode
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.size = Vector2(330, 140)
	marco.position = Vector2((Tema.ANCHO - marco.size.x) * 0.5, 280.0)
	marco.pivot_offset = marco.size * 0.5
	hoja.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marco.add_child(hoja)
	capa.add_child(marco)
	marco.scale = Vector2.ONE * 0.1
	marco.rotation_degrees = -200.0
	var th := marco.create_tween()
	th.tween_property(marco, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	th.parallel().tween_property(marco, "rotation_degrees", -4.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	th.tween_interval(1.7)
	th.tween_property(marco, "modulate:a", 0.0, 0.3)
	th.parallel().tween_property(marco, "position:y", 240.0, 0.3)
	th.tween_callback(marco.queue_free)
	for c in chips:  # los chips golpeados tiemblan
		temblar(c as Control)


static func temblar(c: Control, fuerza: float = 4.0) -> void:
	## Sacudida horizontal breve. Si el control está en un contenedor, este lo reacomoda al final.
	if not Movimiento.intenso() or c == null:
		return
	var x0 := c.position.x
	var tw := c.create_tween()
	for k in range(6):
		tw.tween_property(c, "position:x", x0 + fuerza * (1.0 if k % 2 == 0 else -1.0) * (1.0 - float(k) / 6.0), 0.045)
	tw.tween_property(c, "position:x", x0, 0.045)
	tw.tween_callback(func() -> void:
		if c.get_parent() is Container:
			(c.get_parent() as Container).queue_sort())
