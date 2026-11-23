class_name PanelNacionCompleto
extends RefCounted
## Pantalla "Chile por regiones" completa: mapa con lista, banner del evento y botón central para avanzar el turno.


static func crear(motor: MotorTurno, geo: Dictionary, regiones: Array, texto_evento: String, al_avanzar: Callable) -> Control:
	var pn := PanelNacion.new()
	pn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pn.custom_minimum_size = Vector2(0, 470)
	var vn := VBoxContainer.new()
	vn.add_theme_constant_override("separation", 8)
	vn.add_child(pn)
	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", Tema.caja(Color("#12395A"), 12, Color("#2B5D86"), 1))
	banner.add_child(Tema.etiqueta(texto_evento, 12, Tema.TEXTO))
	var mb := MarginContainer.new()
	mb.add_theme_constant_override("margin_left", 12)
	mb.add_theme_constant_override("margin_right", 12)
	mb.add_child(banner)
	vn.add_child(mb)
	var avanzar := Button.new()
	avanzar.custom_minimum_size = Vector2(64, 64)
	avanzar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for e in ["normal", "hover", "pressed"]:
		var sb := Tema.caja(Tema.ROJO, 32, Color("#E8806F"), 3)
		sb.shadow_color = Color(0.76, 0.23, 0.18, 0.55)
		sb.shadow_size = 10
		avanzar.add_theme_stylebox_override(e, sb)
	avanzar.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vc := VBoxContainer.new()
	vc.add_theme_constant_override("separation", -2)
	vc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ip := Icono.crear("play", Tema.TEXTO, 20.0)
	ip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vc.add_child(ip)
	vc.add_child(Tema.etiqueta_corta("Día %d" % (motor.estado.dia_actual + motor.estado.dias_por_turno), 10, Tema.TEXTO, true))
	cc.add_child(vc)
	avanzar.add_child(cc)
	avanzar.pressed.connect(al_avanzar)
	vn.add_child(avanzar)
	var obras_n: Dictionary = {}
	for o in motor.estado.obras_en_curso:
		obras_n[o["region"]] = int(obras_n.get(o["region"], 0)) + 1
	pn.configurar(geo, regiones, motor.estado.aprobacion_regional, obras_n)
	return vn
