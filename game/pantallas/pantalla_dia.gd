class_name PantallaDia
extends Control
## Día de campaña/gobierno: mapa + mano + PA, con Comité, Congreso y Gabinete como paneles.

signal accion_hecha
signal terminado

var motor: MotorTurno
var datos: Dictionary = {}
var geo: Dictionary = {}

var _sel: int = 0
var _ministro: String = ""
var _region: String = ""
var _lbl_dia: Label
var _lbl_fecha: Label
var _lbl_pa: Label
var _chips: Dictionary = {}
var _mapa: MapaChile
var _lbl_region: Label
var _mano: Control
var _lbl_corrector: Label
var _btn_jugar: Button
var _btn_fin: Button
var _btn_deleg: Button
var _zona_panel: Control
var _capa: Control
var _toast: Label
var _cola_eventos: Array[Dictionary] = []


func _ready() -> void:
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 0)
	add_child(raiz)
	raiz.add_child(_construir_cabecera())
	raiz.add_child(_construir_cuerpo())
	raiz.add_child(_construir_nav())
	_capa = Control.new()
	_capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_capa)
	_toast = Tema.etiqueta("", 12, Tema.TINTA, true)
	_toast.add_theme_stylebox_override("normal", Tema.caja(Tema.ORO, 12))
	_toast.position = Vector2(20, 112)
	_toast.size = Vector2(350, 30)
	_toast.custom_minimum_size = Vector2(350, 0)
	_toast.visible = false
	_capa.add_child(_toast)
	_cola_eventos = motor.ultimos_eventos.duplicate()
	_refrescar()
	_siguiente_evento()


# ------------------------------------------------------------------ construcción
func _construir_cabecera() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 36)
	m.add_child(v)
	var fila := HBoxContainer.new()
	var ins := Tema.etiqueta_corta("★ ", 20, Tema.ORO, true)
	fila.add_child(ins)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_dia = Tema.etiqueta("", 17, Tema.TEXTO, true)
	_lbl_fecha = Tema.etiqueta("", 11, Tema.TEXTO_SUAVE)
	col.add_child(_lbl_dia)
	col.add_child(_lbl_fecha)
	fila.add_child(col)
	_lbl_pa = Tema.etiqueta_corta("", 15, Tema.TINTA, true)
	_lbl_pa.add_theme_stylebox_override("normal", Tema.caja(Tema.ORO, 16))
	_lbl_pa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(_lbl_pa)
	v.add_child(fila)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 4)
	for k in ["aprobacion", "capital", "cohesion", "fiscal"]:
		var l := Tema.etiqueta_corta("", 11, Tema.TEXTO, false, 600)
		l.add_theme_stylebox_override("normal", Tema.caja(Tema.PANEL, 8))
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_chips[k] = l
		chips.add_child(l)
	v.add_child(chips)
	return m


func _construir_cuerpo() -> Control:
	var cuerpo := Control.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vista := VBoxContainer.new()
	vista.set_anchors_preset(Control.PRESET_FULL_RECT)
	vista.add_theme_constant_override("separation", 0)
	cuerpo.add_child(vista)
	_mapa = MapaChile.new()
	_mapa.custom_minimum_size = Vector2(0, 220)
	_mapa.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mapa.cargar_geo(geo)
	_mapa.region_tocada.connect(_on_region)
	vista.add_child(_mapa)
	_lbl_region = Tema.etiqueta("", 12, Tema.TEXTO, true)
	_lbl_region.add_theme_stylebox_override("normal", Tema.caja(Color(0.09, 0.25, 0.37, 0.92), 10, Tema.ORO, 1))
	_lbl_region.position = Vector2(150, 24)
	_lbl_region.custom_minimum_size = Vector2(228, 0)
	_mapa.add_child(_lbl_region)
	var cab_mano := HBoxContainer.new()
	var mm := MarginContainer.new()
	mm.add_theme_constant_override("margin_left", 14)
	mm.add_theme_constant_override("margin_right", 14)
	mm.add_child(cab_mano)
	cab_mano.add_child(Tema.etiqueta_corta("Tu mano", 13, Tema.TEXTO, true))
	var tip := Tema.etiqueta_corta("Toca una carta", 11, Tema.TEXTO_SUAVE)
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cab_mano.add_child(tip)
	vista.add_child(mm)
	_mano = Control.new()
	_mano.custom_minimum_size = Vector2(0, 186)
	_mano.clip_contents = false
	vista.add_child(_mano)
	var corr := PanelContainer.new()
	corr.add_theme_stylebox_override("panel", Tema.caja(Tema.CREMA, 8))
	_lbl_corrector = Tema.etiqueta("", 11, Tema.TINTA)
	_lbl_corrector.custom_minimum_size = Vector2(340, 0)
	corr.add_child(_lbl_corrector)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 12)
	mc.add_theme_constant_override("margin_right", 12)
	mc.add_child(corr)
	vista.add_child(mc)
	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 8)
	_btn_deleg = Tema.boton("Min.", Tema.PANEL, Tema.TEXTO, 12, 52)
	_btn_deleg.custom_minimum_size = Vector2(58, 52)
	_btn_deleg.pressed.connect(func() -> void: _abrir_panel("gabinete"))
	_btn_jugar = Tema.boton("Jugar", Tema.ROJO, Tema.TEXTO, 17, 52)
	_btn_jugar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_jugar.pressed.connect(_jugar)
	_btn_fin = Tema.boton("Fin", Tema.PANEL, Tema.TEXTO, 12, 52)
	_btn_fin.custom_minimum_size = Vector2(58, 52)
	_btn_fin.pressed.connect(_terminar_turno)
	acciones.add_child(_btn_deleg)
	acciones.add_child(_btn_jugar)
	acciones.add_child(_btn_fin)
	var ma := MarginContainer.new()
	ma.add_theme_constant_override("margin_left", 12)
	ma.add_theme_constant_override("margin_right", 12)
	ma.add_theme_constant_override("margin_top", 6)
	ma.add_theme_constant_override("margin_bottom", 6)
	ma.add_child(acciones)
	vista.add_child(ma)
	_zona_panel = PanelContainer.new()
	_zona_panel.add_theme_stylebox_override("panel", Tema.caja(Tema.OCEANO, 0))
	_zona_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_zona_panel.visible = false
	cuerpo.add_child(_zona_panel)
	return cuerpo


func _construir_nav() -> Control:
	var nav := HBoxContainer.new()
	nav.custom_minimum_size = Vector2(0, 56)
	for par in [["Mapa", "mapa"], ["Comité", "comite"], ["Congreso", "congreso"], ["Gabinete", "gabinete"]]:
		var b := Button.new()
		b.text = par[0]
		b.flat = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(Tema.TACTIL, Tema.TACTIL)
		b.add_theme_font_override("font", Tema.fuente_texto(600))
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
		b.add_theme_color_override("font_pressed_color", Tema.ORO)
		b.pressed.connect(_abrir_panel.bind(par[1]))
		nav.add_child(b)
	var fondo := PanelContainer.new()
	fondo.add_theme_stylebox_override("panel", Tema.caja(Tema.OCEANO.darkened(0.2), 0))
	fondo.add_child(nav)
	return fondo


# ------------------------------------------------------------------ estado -> UI
func _refrescar() -> void:
	var est := motor.estado
	var sem_camp := int(datos["leyes"]["hemiciclo"]["semanas_campana"])
	if est.etapa == "campana":
		_lbl_dia.text = "Campaña · Semana %d de %d" % [mini(est.turno_actual, sem_camp), sem_camp]
		_lbl_fecha.text = "%s · %s" % [est.partido.get("nombre", ""), est.partido.get("perfil", "")]
	else:
		_lbl_dia.text = "Día %d" % est.dia_actual
		_lbl_fecha.text = "Año %d · Turno %d de %d" % [(est.dia_actual - 1) / 365 + 1, est.turno_actual, motor.turnos_mandato()]
	_lbl_pa.text = " %d PA " % est.pa_actual
	var nombres := {"aprobacion": "Aprob.", "capital": "Capital", "cohesion": "Cohes.", "fiscal": "Fiscal"}
	for k in _chips.keys():
		_chips[k].text = "%s %d" % [nombres[k], roundi(est.ind(k))]
	var obras: Dictionary = {}
	for o in est.obras_en_curso:
		obras[o["region"]] = int(obras.get(o["region"], 0)) + 1
	_mapa.bastion = String(est.partido.get("region_bastion", ""))
	_mapa.actualizar(est.aprobacion_regional, obras)
	_actualizar_region()
	_pintar_mano()
	_actualizar_botones()


func _actualizar_region() -> void:
	var est := motor.estado
	if _region == "" or not est.aprobacion_regional.has(_region):
		_lbl_region.text = "Toca una región del mapa\n%s" % ("para dirigir tu promesa de campaña." if est.etapa == "campana" else "para ver su aprobación.")
		return
	var nombre := _region
	for r in datos["regiones"]:
		if r["id"] == _region:
			nombre = String(r["nombre"])
	var n_obras := 0
	for o in est.obras_en_curso:
		if o["region"] == _region:
			n_obras += 1
	_lbl_region.text = "%s  %s\n%d obra(s) en curso" % [nombre, Tema.pct(float(est.aprobacion_regional[_region])), n_obras]


func _pintar_mano() -> void:
	for h in _mano.get_children():
		h.queue_free()
	var est := motor.estado
	var n := est.mano.size()
	if n == 0:
		_lbl_corrector.text = "Sin cartas en la mano. Termina el turno para robar más."
		return
	_sel = clampi(_sel, 0, n - 1)
	var ancho := 98.0
	var alto := 142.0
	var paso := 0.0 if n < 2 else minf(ancho * 0.8, (Tema.ANCHO - 20.0 - ancho) / float(n - 1))
	var x0 := (Tema.ANCHO - (ancho + paso * float(n - 1))) * 0.5
	var orden: Array[int] = []
	for i in range(n):
		if i != _sel:
			orden.append(i)
	orden.append(_sel)  # la elegida se agrega al final para dibujarse encima
	for i in orden:
		var c := CartaUI.new()
		var costo := motor.costo_carta(est.mano[i], _ministro)
		c.configurar(est.mano[i], costo)
		c.elegida = i == _sel
		c.atenuada = i != _sel or costo > est.pa_actual
		c.size = Vector2(ancho, alto)
		c.pivot_offset = Vector2(ancho * 0.5, alto)
		c.position = Vector2(x0 + paso * float(i), 38.0)
		c.rotation_degrees = float(i - (n - 1) * 0.5) * 3.0
		if i == _sel:
			c.scale = Vector2(1.18, 1.18)
			c.position.y = 12.0
			c.rotation_degrees = 0.0
		c.tocada.connect(_on_carta.bind(i))
		_mano.add_child(c)
	var v := motor.vista_carta(_sel, _ministro)
	if est.etapa == "campana":
		_lbl_corrector.text = "Campaña: cada carta es una promesa. Sube la aprobación de la región elegida (+50 %) y queda como meta de legado."
	elif v["corrector"]["aplica"]:
		_lbl_corrector.text = "Corrector de realismo: " + String(v["corrector"]["mensaje"])
	else:
		_lbl_corrector.text = "Corrector de realismo: sin observaciones; la meta es viable con la capacidad actual."


func _actualizar_botones() -> void:
	var est := motor.estado
	var n := est.mano.size()
	if n > 0:
		var costo := motor.costo_carta(est.mano[_sel], _ministro)
		_btn_jugar.text = "Jugar · %d PA" % costo
		_btn_jugar.disabled = costo > est.pa_actual
	else:
		_btn_jugar.text = "Sin cartas"
		_btn_jugar.disabled = true
	_btn_deleg.text = "Min." if _ministro == "" else "Min.\n✓"
	_btn_deleg.disabled = est.etapa != "gobierno"
	var elec := est.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"]))
	_btn_fin.text = "Urnas" if elec else "Fin"
	_btn_jugar.disabled = _btn_jugar.disabled or elec


# ------------------------------------------------------------------ interacción
func _on_carta(_c: CartaUI, i: int) -> void:
	_sel = i
	_pintar_mano()
	_actualizar_botones()


func _on_region(id: String) -> void:
	_region = id
	_actualizar_region()


func _jugar() -> void:
	var r := motor.jugar_carta(_sel, _ministro, _region)
	if not bool(r["ok"]):
		var razones := {"pa_insuficiente": "No te alcanzan los PA.", "ya_ejecutada": "Esa meta ya está en marcha.", "region_invalida": "Región inválida."}
		_avisar(String(razones.get(r["razon"], "No se pudo jugar la carta.")))
		return
	_ministro = ""
	var msg := "Carta jugada."
	if r.get("promesa", false):
		msg = "Promesa registrada: +%.1f de aprobación" % float(r["delta_aprobacion"])
	elif r.get("escandalo", false):
		msg = "Escándalo ministerial: pierdes aprobación y capital."
	elif r.get("propuesta") != null:
		msg = "Propuesta abierta en el Comité de Planificación."
		_abrir_panel("comite")
	elif r.get("proyecto") != null:
		msg = "Proyecto ingresado al Congreso."
	elif r["corrector"].get("aplica", false):
		msg = "Versión viable aplicada (%d %%)." % roundi(float(r["corrector"]["ratio"]) * 100.0)
	_avisar(msg)
	accion_hecha.emit()
	_refrescar()


func _avisar(txt: String) -> void:
	_toast.text = txt
	_toast.visible = true
	var tw := create_tween()
	tw.tween_interval(1.8)
	tw.tween_callback(func() -> void: _toast.visible = false)


func _terminar_turno() -> void:
	var est := motor.estado
	var sem := int(datos["leyes"]["hemiciclo"]["semanas_campana"])
	if est.eleccion_pendiente(sem):
		_resolver_eleccion()
		return
	var nuevos := motor.terminar_turno()
	accion_hecha.emit()
	if est.eleccion_pendiente(sem):
		_avisar("Termina la campaña: toca Fin para ir a las urnas.")
		_btn_fin.text = "Urnas"
	elif est.etapa != "campana" and est.etapa != "gobierno":
		terminado.emit()
		return
	_cola_eventos = nuevos.duplicate()
	_refrescar()
	if est.eleccion_pendiente(sem):
		_btn_fin.text = "Urnas"
	_siguiente_evento()


func _resolver_eleccion() -> void:
	var res := motor.resolver_eleccion_presidencial()
	if res["electo"]:
		motor.iniciar_turno()  # mismo orden que la reproducción desde guardado
	accion_hecha.emit()
	var ev := {"titulo": "Elección presidencial", "hora": "20:00", "votacion": null,
		"descripcion": "Obtuviste %.1f %% de los votos con un umbral de %.0f %%. %s" % [float(res["voto_final"]), float(res["umbral"]),
			"¡Eres el nuevo Presidente de Chile! Asumes el gobierno con tus promesas como metas de legado." if res["electo"] else "No alcanzaste la presidencia."]}
	_capa.add_child(PanelesDia.evento(ev, func() -> void:
		if res["electo"]:
			_cola_eventos = motor.ultimos_eventos.duplicate()
			_refrescar()
			_siguiente_evento()
		else:
			terminado.emit(), 50))


func _siguiente_evento() -> void:
	if _cola_eventos.is_empty():
		return
	var ev: Dictionary = _cola_eventos.pop_front()
	_capa.add_child(PanelesDia.evento(ev, _siguiente_evento, 50))


func _abrir_panel(cual: String) -> void:
	for h in _zona_panel.get_children():
		h.queue_free()
	if cual == "mapa":
		_zona_panel.visible = false
		return
	_zona_panel.visible = true
	var contenido: Control
	match cual:
		"comite":
			contenido = PanelesDia.comite(motor, _aprobar)
		"congreso":
			contenido = PanelesDia.congreso(motor)
		_:
			contenido = PanelesDia.gabinete(motor, _ministro, _elegir_ministro)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 14)
	m.add_child(contenido)
	_zona_panel.add_child(m)


func _aprobar(pid: String, variante: String) -> void:
	var r := motor.aprobar_propuesta(pid, variante, _region)
	if bool(r["ok"]):
		_avisar("Obra aprobada: %d días de construcción." % int(r["dias"]))
		accion_hecha.emit()
		_refrescar()
		_abrir_panel("congreso")
	else:
		_avisar("No se pudo aprobar la propuesta.")


func _elegir_ministro(id: String) -> void:
	_ministro = id
	_abrir_panel("mapa")
	_refrescar()
