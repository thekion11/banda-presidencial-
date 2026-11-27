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
	# Las 16 regiones de norte a sur (orden de data/regiones.json), también las que SECTRA no cubre (Metropolitana, Aysén):
	# pedido del usuario del 27-nov («Faltan»). Antes solo salían las regiones con cartera y ordenadas por id.
	var ids: Array = motor.regiones.catalogo.map(func(r: Dictionary) -> String: return String(r["id"]))
	if ids.is_empty():
		return col
	var sel := region_ini if _cantidad(motor, region_ini) > 0 else _inicial(motor, ids)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	var desliza := ScrollContainer.new()  # chips en una fila que se desliza: compacto en 360×640 y con letra grande
	desliza.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desliza.custom_minimum_size = Vector2(0, 52)
	desliza.add_child(chips)
	col.add_child(desliza)
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 8)
	col.add_child(lista)
	var botones := {}
	var elegir := func(rid: String) -> void:
		for k in botones.keys():
			var on: bool = k == rid
			(botones[k] as Button).add_theme_stylebox_override("normal", Tema.caja(Tema.ORO if on else Tema.PANEL, 14))
			(botones[k] as Button).add_theme_color_override("font_color", Tema.TINTA if on else Tema.TEXTO)
		_llenar(lista, motor, rid, al_impulsar)
		if botones.has(rid):  # la región elegida siempre a la vista en la fila
			desliza.ensure_control_visible.call_deferred(botones[rid])
	for rid: String in ids:
		var n := _cantidad(motor, rid)
		var b := Tema.boton("%s · %s" % [nombre_corto(_nombre_region(motor, rid)), str(n) if n > 0 else "—"], Tema.PANEL, Tema.TEXTO, 12, 44)
		b.pressed.connect(elegir.bind(rid))
		chips.add_child(b)
		botones[rid] = b
	elegir.call(sel)
	return col


static func nombre_corto(nombre: String) -> String:
	## «Metropolitana de Santiago» -> «Metropolitana», «Magallanes y la Antártica Chilena» -> «Magallanes», «Arica y Parinacota» -> «Arica».
	return nombre.replace(" de Santiago", "").replace(" y la Antártica Chilena", "").replace(" y Parinacota", "")


static func _cantidad(motor: MotorTurno, rid: String) -> int:
	return (motor.sectra.proyectos.get(rid, []) as Array).size()


static func _inicial(motor: MotorTurno, ids: Array) -> String:
	## Sin región elegida con cartera: el bastión del jugador si tiene proyectos, si no la región con más proyectos.
	var bastion := String(motor.estado.partido.get("region_bastion", ""))
	if _cantidad(motor, bastion) > 0:
		return bastion
	var mejor: String = ids[0]
	for rid: String in ids:
		if _cantidad(motor, rid) > _cantidad(motor, mejor):
			mejor = rid
	return mejor


static func _nombre_region(motor: MotorTurno, rid: String) -> String:
	for r in motor.regiones.catalogo:
		if r["id"] == rid:
			return String(r["nombre"])
	return rid


static func _llenar(lista: VBoxContainer, motor: MotorTurno, rid: String, al_impulsar: Callable) -> void:
	for h in lista.get_children():
		h.queue_free()
	if _cantidad(motor, rid) == 0:  # nunca una lista vacía: qué pasa con esa región y dónde se trabaja
		var nota := "SECTRA no publica proyectos de su Plan Maestro de Transporte para esta región."
		if rid == "metropolitana":
			nota += " Santiago: trabaja las líneas de Metro y tren en las propuestas del Comité (arriba)."
		elif rid == "aysen":
			nota += " Aysén no tiene un plan maestro publicado; sus obras llegan por las cartas de transporte."
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, 12))
		pc.add_child(Tema.etiqueta(nota, 12, Tema.TEXTO))
		lista.add_child(pc)
		return
	var items: Array = motor.sectra.proyectos[rid].duplicate()
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["inversion_uf"]) > float(b["inversion_uf"]))
	for p in items.slice(0, MAX_MOSTRADOS):
		lista.add_child(_tarjeta(motor, p, al_impulsar))
	if items.size() > MAX_MOSTRADOS:
		lista.add_child(Tema.etiqueta("Hay más proyectos en la cartera de la región.", 11, Tema.TEXTO_SUAVE))


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
	fila.add_child(PanelesDia._chip("Inversión", ("US$%s M" % Tema.miles(roundi(mm))) if mm > 0.0 else "s/d", Tema.CREMA))
	fila.add_child(PanelesDia._chip("TIR", ("%s %%" % Tema.dec(float(p["tir"]))) if bool(p["tiene_tir"]) else "s/d", Tema.CREMA))
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
