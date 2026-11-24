class_name PanelSectra
extends RefCounted
## Cartera real del Plan Maestro de Transporte de SECTRA por región: el jugador impulsa cada proyecto etapa por etapa.

const ETAPAS := ["Perfil", "Prefactibilidad", "Diseño", "Ejecución"]
const MAX_MOSTRADOS := 12


static func crear(motor: MotorTurno, region_ini: String, al_impulsar: Callable) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.add_child(Tema.etiqueta("PLAN MAESTRO DE TRANSPORTE · SECTRA", 10, Tema.ORO, true))
	col.add_child(Tema.etiqueta("Proyectos reales publicados por SECTRA (sectra.gob.cl). Impulsa uno por etapa; en ejecución se vuelve obra.", 11, Tema.TEXTO_SUAVE))
	var ids: Array = motor.sectra.proyectos.keys()
	ids.sort()
	if ids.is_empty():
		return col
	var sel: String = region_ini if ids.has(region_ini) else String(ids[0])
	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(0, 44)
	opt.add_theme_font_size_override("font_size", 13)
	for i in range(ids.size()):
		opt.add_item(_nombre_region(motor, String(ids[i])), i)
		if ids[i] == sel:
			opt.select(i)
	col.add_child(opt)
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 8)
	col.add_child(lista)
	_llenar(lista, motor, sel, al_impulsar)
	opt.item_selected.connect(func(i: int) -> void: _llenar(lista, motor, String(ids[i]), al_impulsar))
	return col


static func _nombre_region(motor: MotorTurno, rid: String) -> String:
	for r in motor.regiones.catalogo:
		if r["id"] == rid:
			return String(r["nombre"])
	return rid


static func _llenar(lista: VBoxContainer, motor: MotorTurno, rid: String, al_impulsar: Callable) -> void:
	for h in lista.get_children():
		h.queue_free()
	var items: Array = motor.sectra.proyectos[rid].duplicate()
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["inversion_uf"]) > float(b["inversion_uf"]))
	for p in items.slice(0, MAX_MOSTRADOS):
		lista.add_child(_tarjeta(motor, p, al_impulsar))
	if items.size() > MAX_MOSTRADOS:
		lista.add_child(Tema.etiqueta("+ %d proyectos más en la cartera de la región." % (items.size() - MAX_MOSTRADOS), 11, Tema.TEXTO_SUAVE))


static func _tarjeta(motor: MotorTurno, p: Dictionary, al_impulsar: Callable) -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, 12))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	v.add_child(Tema.etiqueta(String(p["nombre"]), 14, Tema.TEXTO, true))
	var st: Dictionary = motor.sectra.estado_de(String(p["id"]))
	var etapa := int(st["etapa"])
	var fila := HBoxContainer.new()
	var mm := motor.sectra.musd(p)
	fila.add_child(PanelesDia._chip("Inversión", ("US$%d M" % roundi(mm)) if mm > 0.0 else "s/d", Tema.CREMA))
	fila.add_child(PanelesDia._chip("TIR", ("%.1f %%" % float(p["tir"])) if bool(p["tiene_tir"]) else "s/d", Tema.CREMA))
	fila.add_child(PanelesDia._chip("Etapa", ETAPAS[mini(etapa, 3)], Tema.CREMA))
	v.add_child(fila)
	v.add_child(Tema.etiqueta("Mandante: %s · Estado SECTRA: %s" % [p["mandante"], p["estado"]], 11, Tema.TEXTO_SUAVE))
	var btn := Barras.boton_jugar()
	btn.add_theme_font_size_override("font_size", 13)
	btn.custom_minimum_size = Vector2(0, 48)
	var costo := int(motor.catalogo_leyes["sectra"]["costo_pa_impulso"])
	if etapa >= 3:
		btn.text = "En ejecución como obra"
		btn.disabled = true
	elif int(st["hasta"]) > 0:
		btn.text = "En trámite hasta el día %d" % int(st["hasta"])
		btn.disabled = true
	else:
		btn.text = "Impulsar a %s · %d mov" % [ETAPAS[etapa + 1].to_lower(), costo]
		btn.disabled = motor.estado.etapa != "gobierno" or costo > motor.estado.pa_actual or motor.sectra.en_curso() >= int(motor.catalogo_leyes["sectra"]["max_simultaneos"])
		btn.pressed.connect(func() -> void: al_impulsar.call(String(p["id"])))
	v.add_child(btn)
	return pc
