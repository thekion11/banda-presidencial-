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
	var obras_n: Dictionary = {}
	for o in motor.estado.obras_en_curso:
		obras_n[o["region"]] = int(obras_n.get(o["region"], 0)) + 1
	pn.configurar(geo, regiones, motor.estado.aprobacion_regional, obras_n)
	return vn
