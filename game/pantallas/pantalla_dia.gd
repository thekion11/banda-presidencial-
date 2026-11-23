class_name PantallaDia
extends Control
## Día de campaña/gobierno: mapa + mano + PA, con Comité, Congreso y Gabinete como paneles.

signal accion_hecha
signal terminado

var motor: MotorTurno
var datos: Dictionary = {}
var geo: Dictionary = {}

var _sel: int = 0
var _raiz: VBoxContainer
var _nav: Control
var _nuevas: Array = []  # ids de cartas que entraron por reposición (se animan al pintar la mano)
var _lbl_mov: Label
var _badge: Label
var _ministro: String = ""
var _region: String = ""
var _r: Dictionary = {}  # referencias de Barras
var _mapa: MapaChile
var _mano: ManoUI
var _lbl_corrector: RichTextLabel
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
	_raiz = raiz
	_nav = _construir_nav()
	raiz.add_child(_nav)
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
	return Barras.cabecera(_r)


func _construir_cuerpo() -> Control:
	var cuerpo := Control.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vista := VBoxContainer.new()
	vista.set_anchors_preset(Control.PRESET_FULL_RECT)
	vista.add_theme_constant_override("separation", 0)
	cuerpo.add_child(vista)
	_mapa = MapaChile.new()
	_mapa.custom_minimum_size = Vector2(0, 290)
	_mapa.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mapa.cargar_geo(geo)
	_mapa.region_tocada.connect(_on_region)
	vista.add_child(_mapa)
	_mapa.x_centro_rel = 0.3
	var col_tarjetas := VBoxContainer.new()
	col_tarjetas.add_theme_constant_override("separation", 10)
	col_tarjetas.position = Vector2(196, 10)
	col_tarjetas.custom_minimum_size = Vector2(186, 0)
	col_tarjetas.size = Vector2(186, 10)
	col_tarjetas.add_child(Barras.tarjeta_evento(_r))
	var tr := Barras.tarjeta_region(_r)
	tr.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			if _region == "metropolitana":
				_abrir_urbano()
			else:
				_abrir_panel("nacion"))
	col_tarjetas.add_child(tr)
	_mapa.add_child(col_tarjetas)
	var cab_mano := HBoxContainer.new()
	var mm := MarginContainer.new()
	mm.add_theme_constant_override("margin_left", 14)
	mm.add_theme_constant_override("margin_right", 14)
	mm.add_child(cab_mano)
	cab_mano.add_child(Tema.etiqueta_corta("Tu mano", 13, Tema.TEXTO, true))
	_lbl_mov = Tema.etiqueta_corta("", 11, Tema.TEXTO_SUAVE)
	_lbl_mov.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_mov.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cab_mano.add_child(_lbl_mov)
	vista.add_child(mm)
	_mano = ManoUI.new()
	_mano.custom_minimum_size = Vector2(0, 218)
	_mano.clip_contents = false
	_mano.tocada.connect(_on_carta)
	vista.add_child(_mano)
	var corr := PanelContainer.new()
	corr.add_theme_stylebox_override("panel", Tema.caja(Tema.CREMA, 10, Color("#E8D9A8"), 1))
	_lbl_corrector = RichTextLabel.new()
	_lbl_corrector.bbcode_enabled = true
	_lbl_corrector.fit_content = true
	_lbl_corrector.scroll_active = false
	_lbl_corrector.custom_minimum_size = Vector2(330, 0)
	_lbl_corrector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_corrector.add_theme_color_override("default_color", Tema.TINTA)
	_lbl_corrector.add_theme_font_override("normal_font", Tema.fuente_texto(400))
	_lbl_corrector.add_theme_font_override("bold_font", Tema.fuente_texto(800))
	_lbl_corrector.add_theme_font_size_override("normal_font_size", 11)
	_lbl_corrector.add_theme_font_size_override("bold_font_size", 11)
	corr.custom_minimum_size = Vector2(0, 62)  # alto fijo: el botón principal no se mueve
	corr.add_child(_lbl_corrector)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 12)
	mc.add_theme_constant_override("margin_right", 12)
	mc.add_child(corr)
	vista.add_child(mc)
	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 8)
	_btn_deleg = Barras.boton_redondo("person")
	_btn_deleg.pressed.connect(_delegar)
	_badge = Tema.etiqueta_corta("", 10, Tema.ORO, true)
	_badge.position = Vector2(36, 34)
	_btn_deleg.add_child(_badge)
	_btn_jugar = Barras.boton_jugar()
	_btn_jugar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_jugar.pressed.connect(_jugar)
	_btn_fin = Barras.boton_redondo("play")
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
	return Barras.nav(_abrir_panel)


# ------------------------------------------------------------------ estado -> UI
func _refrescar() -> void:
	var est := motor.estado
	var sem_camp := int(datos["leyes"]["hemiciclo"]["semanas_campana"])
	if est.etapa == "campana":
		_r["dia"].text = "Campaña · Semana %d de %d" % [mini(est.turno_actual, sem_camp), sem_camp]
	else:
		_r["dia"].text = "Día %d" % est.dia_actual
	_r["fecha"].text = Barras.fecha_texto(datos["leyes"], est.etapa, est.turno_actual, est.dia_actual)
	_r["pa"].text = ManoUI.texto_pastilla(est)
	_lbl_mov.text = ManoUI.texto_movimientos(est)
	for k in _r["chips"].keys():
		var l: Label = _r["chips"][k]
		l.text = str(roundi(est.ind(k)))
		l.add_theme_color_override("font_color", Tema.SUBE if (k == "aprobacion" and est.ind(k) >= 50.0) else Tema.TEXTO)
	var obras: Dictionary = {}
	for o in est.obras_en_curso:
		obras[o["region"]] = int(obras.get(o["region"], 0)) + 1
	_mapa.bastion = String(est.partido.get("region_bastion", ""))
	var props: Dictionary = {}
	for pid in est.propuestas_abiertas:
		props[String(motor.catalogo_propuestas[pid].get("region", ""))] = true
	_mapa.actualizar(est.aprobacion_regional, obras, props)
	Barras.actualizar_evento(_r, motor)
	_actualizar_region()
	_pintar_mano()
	_actualizar_botones()


func _actualizar_region() -> void:
	var est := motor.estado
	if _region == "" or not est.aprobacion_regional.has(_region):
		_r["rg_nombre"].text = "Elige una región"
		_r["rg_valor"].text = ""
		_r["rg_sub"].text = "Toca el mapa para %s." % ("dirigir tu promesa de campaña" if est.etapa == "campana" else "ver su aprobación")
		_r["rg_barra"].value = 0
		return
	var nombre := _region
	for r in datos["regiones"]:
		if r["id"] == _region:
			nombre = String(r["nombre"]).replace(" de Santiago", "")
	var n_obras := 0
	for o in est.obras_en_curso:
		if o["region"] == _region:
			n_obras += 1
	var v := float(est.aprobacion_regional[_region])
	_r["rg_nombre"].text = nombre
	_r["rg_valor"].text = Tema.pct(v)
	_r["rg_valor"].add_theme_color_override("font_color", Tema.color_aprobacion(v + 12.0))
	_r["rg_sub"].text = "%d obra(s) en curso%s" % [n_obras, " · 1 propuesta nueva" if est.propuestas_abiertas.size() > 0 and _region == "metropolitana" else ""]
	_r["rg_barra"].value = v
	_r["rg_barra"].add_theme_stylebox_override("fill", Tema.caja(Tema.color_aprobacion(v + 12.0), 4))


func _pintar_mano() -> void:
	var est := motor.estado
	var n := est.mano.size()
	_sel = clampi(_sel, 0, maxi(0, n - 1))
	_mano.pintar(motor, _sel, _ministro, _nuevas)
	_nuevas = []
	if n == 0:
		_lbl_corrector.text = "[b]Sin cartas[/b] en la mano. Termina el turno para robar más."
		return
	var v := motor.vista_carta(_sel, _ministro)
	var c: Dictionary = est.mano[_sel]
	var cabeza := "[b]%s[/b] · %s · %d mov\n" % [c["titulo"], BloqueoCarta.nombre_cat(String(c["categoria"])), motor.costo_carta(c, _ministro)]
	if est.etapa == "campana":
		_lbl_corrector.text = cabeza + "[b]Campaña:[/b] cada carta es una promesa: sube la aprobación de la región elegida y queda como meta de legado."
	elif v["corrector"]["aplica"]:
		_lbl_corrector.text = cabeza + "[b]Corrector de realismo:[/b] " + String(v["corrector"]["mensaje"])
	else:
		_lbl_corrector.text = cabeza + "[b]Corrector de realismo:[/b] sin observaciones; la meta es viable."


func _actualizar_botones() -> void:
	var est := motor.estado
	var n := est.mano.size()
	if n > 0:
		var costo := motor.costo_carta(est.mano[_sel], _ministro)
		_btn_jugar.text = "Jugar · %d mov" % costo
		_btn_jugar.disabled = costo > est.pa_actual
	else:
		_btn_jugar.text = "Sin cartas"
		_btn_jugar.disabled = true
	var max_deleg := int(motor.catalogo_leyes["delegacion"]["max_por_turno"])
	_btn_deleg.disabled = est.etapa != "gobierno" or n == 0 or est.delegadas_turno >= max_deleg
	_btn_deleg.tooltip_text = "Delegar la carta elegida en un ministro"
	_badge.text = str(max_deleg - est.delegadas_turno) if est.etapa == "gobierno" else ""
	var elec := est.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"]))
	_btn_fin.tooltip_text = "Urnas" if elec else "Terminar turno"
	_btn_jugar.disabled = _btn_jugar.disabled or elec


# ------------------------------------------------------------------ interacción
func _on_carta(i: int) -> void:
	_sel = i
	_pintar_mano()
	_actualizar_botones()


func _on_region(id: String) -> void:
	_region = id
	_actualizar_region()


func _jugar() -> void:
	var n_reg := motor.estado.registro_acciones.size()
	var r := motor.jugar_carta(_sel, _ministro, _region)
	if not bool(r["ok"]):
		_avisar(Razones.texto(r))
		return
	_leer_reposicion(n_reg)
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


func _leer_reposicion(desde: int) -> void:
	## Si el motor repuso cartas (registro `reposicion`), la mano las anima al pintarse.
	for a in motor.estado.registro_acciones.slice(desde):
		if a["tipo"] == "reposicion":
			_nuevas = a["detalle"]["ids"]


func _delegar() -> void:
	if motor.estado.mano.is_empty():
		return
	var n_reg := motor.estado.registro_acciones.size()
	_capa.add_child(PanelDelegar.crear(motor, _sel, _region, func(r: Dictionary) -> void:
		if not bool(r["ok"]):
			_avisar(Razones.texto(r))
			return
		_leer_reposicion(n_reg)
		_avisar("Escándalo ministerial: pierdes aprobación y capital." if r["escandalo"] else ("El ministro falló: efecto reducido." if r["fallo"] else "Delegada: el ministro la ejecutó sin gastar movimientos."))
		accion_hecha.emit()
		_refrescar()))


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
		_avisar("Termina la campaña: toca el botón de avanzar para ir a las urnas.")
	elif est.etapa != "campana" and est.etapa != "gobierno":
		terminado.emit()
		return
	_cola_eventos = OverlaysDia.eventos_de_votaciones(motor)
	_cola_eventos.append_array(nuevos)
	_refrescar()
	_siguiente_evento()


func _resolver_eleccion() -> void:
	var res := motor.resolver_eleccion_presidencial()
	if res["electo"] or res["balotaje"]:
		motor.iniciar_turno()  # mismo orden que la reproducción desde guardado
	accion_hecha.emit()
	var ev := {"titulo": "Elección presidencial", "hora": "20:00", "votacion": null,
		"descripcion": "Obtuviste %.1f %% de los votos con un umbral de %.0f %%. %s" % [float(res["voto_final"]), float(res["umbral"]),
			"¡Eres el nuevo Presidente de Chile! Asumes el gobierno con tus promesas como metas de legado." if res["electo"] else ("Pasas a segunda vuelta: tienes 4 semanas más de campaña." if res["balotaje"] else "No alcanzaste la presidencia.")]}
	_capa.add_child(OverlaysDia.evento(ev, func() -> void:
		if res["electo"] or res["balotaje"]:
			_cola_eventos = motor.ultimos_eventos.duplicate()
			_refrescar()
			_siguiente_evento()
		else:
			terminado.emit(), motor.catalogo_leyes["congreso"]["nombres"]))


func _siguiente_evento() -> void:
	if _cola_eventos.is_empty():
		return
	var ev: Dictionary = _cola_eventos.pop_front()
	_capa.add_child(OverlaysDia.evento(ev, _siguiente_evento, motor.catalogo_leyes["congreso"]["nombres"], motor.estado.dia_actual))


func _poner_nav(nacion: bool) -> void:
	var nuevo := Barras.nav(_abrir_panel, nacion, "Día %d" % (motor.estado.dia_actual + motor.estado.dias_por_turno), func() -> void:
		_abrir_panel("mapa")
		_terminar_turno())
	_raiz.add_child(nuevo)
	_raiz.move_child(nuevo, _nav.get_index())
	_nav.queue_free()
	_nav = nuevo


func _abrir_panel(cual: String) -> void:
	_poner_nav(cual == "nacion")
	for h in _zona_panel.get_children():
		h.queue_free()
	if cual == "mapa":
		_zona_panel.visible = false
		return
	_zona_panel.visible = true
	_zona_panel.offset_bottom = -66.0 if cual == "gabinete" else 0.0  # con Gabinete, la fila de Jugar/avanzar queda en su sitio
	var contenido: Control
	match cual:
		"comite":
			contenido = PanelComite.crear(motor, _aprobar, _region, func(pid: String) -> void:
					motor.impulsar_proyecto(pid)
					_refrescar()
					_abrir_panel("comite"))
		"nacion":
			contenido = PanelNacionCompleto.crear(motor, geo, datos["regiones"], "%s · %s" % [_r["ev_hora"].text.replace("● ", ""), _r["ev_titulo"].text],
					func() -> void:
						_abrir_panel("mapa")
						_terminar_turno())
		"congreso":
			contenido = PanelesDia.congreso(motor, _abrir_hito)
		_:
			contenido = PanelGestion.crear(motor, _avisar, func() -> void:
					accion_hecha.emit()
					_refrescar())
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 14)
	if cual == "nacion":
		m.add_theme_constant_override("margin_left", 0)
		m.add_theme_constant_override("margin_right", 0)
		m.add_theme_constant_override("margin_top", 0)
	m.add_child(contenido)
	_zona_panel.add_child(m)


func _aprobar(pid: String, variante: String, custom: Dictionary = {}) -> void:
	var r := motor.aprobar_propuesta(pid, variante, _region, custom)
	if bool(r["ok"]):
		_avisar("Obra aprobada: %d días de construcción." % int(r["dias"]))
		accion_hecha.emit()
		_refrescar()
		_abrir_panel("congreso")
	else:
		_avisar("No se pudo aprobar la propuesta.")


func _abrir_hito(obra: Dictionary) -> void:
	_capa.add_child(PantallaHito.crear(obra, datos["leyes"]["fases_obra"], func() -> void: pass, _abrir_urbano))


func _abrir_urbano() -> void:
	_capa.add_child(PantallaUrbano.crear(motor, UrbanoBase.datos(), func() -> void: pass, _abrir_hito))
