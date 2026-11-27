class_name PantallaDia
extends Control
## Día de campaña/gobierno: mapa + mano + PA, con Comité, Congreso y Gabinete como paneles.

signal accion_hecha
signal terminado
signal transicion  # ganaste: falta nombrar el gabinete antes de la primera semana de gobierno

var motor: MotorTurno
var datos: Dictionary = {}
var geo: Dictionary = {}

var _sel: int = 0
var _raiz: VBoxContainer
var _nav: Control
var _nuevas: Array = []  # ids de cartas que entraron por reposición (se animan al pintar la mano)
var _lbl_mov: Label
var _riel: RielRegiones
var _badge: Label
var _region: String = ""
var _r: Dictionary = {}  # referencias de Barras
var _mapa: MapaChile
var _mano: ManoUI
var _lbl_corrector: RichTextLabel
var _btn_jugar: Button
var _confirmar_fin: bool = false
var _mano_tocada: bool = false  # ya hay una carta elegida por toque (el siguiente toque sobre ella la juega)
var _btn_deleg: Button
var _zona_panel: Control
var _capa: Control
var _toast: Toast
var _cola_eventos: Array[Dictionary] = []
var _panel_actual := "mapa"  # pestaña abierta: se reconstruye al terminar la semana para no mostrar datos viejos


func _ready() -> void:
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 0)
	add_child(raiz)
	raiz.add_child(Barras.cabecera(_r))
	(_r["baul"] as Button).pressed.connect(_abrir_baul)
	raiz.add_child(CuerpoDia.construir(self))  # mapa, mano, Corrector, botones y zona de paneles (cuerpo_dia.gd)
	(_r["ev_cab"] as Control).gui_input.connect(func(ev: InputEvent) -> void:  # el evento del día, completo
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and String(_r["ev_cab"].text) != "":
			_avisar("%s · %s. %s" % [String(_r["ev_hora"].text).replace("• ", ""), _r["ev_titulo"].text, _r["ev_sub"].text]))
	var pastilla := (_r["pa"] as Control).get_parent().get_parent() as Control  # tocar el rayo explica qué es
	pastilla.mouse_filter = Control.MOUSE_FILTER_STOP
	pastilla.tooltip_text = ManoUI.AYUDA_MOVIMIENTOS
	pastilla.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_avisar(ManoUI.AYUDA_MOVIMIENTOS))
	_raiz = raiz
	_nav = Barras.nav(_abrir_panel, false, "", Callable(), "Coalición" if motor.estado.etapa == "oposicion" else "Gabinete")
	raiz.add_child(_nav)
	_capa = Control.new()
	_capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_capa)
	_toast = Toast.new()
	_capa.add_child(_toast)
	_cola_eventos = motor.ultimos_eventos.duplicate()
	_refrescar()
	_siguiente_evento()
	if Tutorial.debe_mostrar() and motor.estado.etapa == "campana" and motor.estado.turno_actual == 1:
		var tut := Tutorial.new()
		tut.leyes = motor.catalogo_leyes
		tut.objetivos = [_mano, _r["pa"], _btn_deleg, _nav, _btn_jugar]
		_capa.add_child(tut)
	elif Tutorial.debe_mostrar("ayuda_gobierno") and motor.estado.etapa == "gobierno" and motor.estado.turno_actual == 1 and motor.estado.ciclo == 1:
		var ayuda := Tutorial.new()  # primer día de gobierno: delegar, agenda legislativa y ahorro (una sola vez)
		ayuda.pasos = Tutorial.PASOS_GOBIERNO
		ayuda.clave = "ayuda_gobierno"
		ayuda.leyes = motor.catalogo_leyes
		ayuda.objetivos = [_btn_deleg, _nav, _r["pa"]]
		_capa.add_child(ayuda)


# ------------------------------------------------------------------ estado -> UI
func _refrescar() -> void:
	var est := motor.estado
	var sem_camp := int(datos["leyes"]["hemiciclo"]["semanas_campana"])
	if est.etapa == "campana":
		_r["dia"].text = "Campaña · Sem. %d/%d" % [mini(est.turno_actual, sem_camp), sem_camp]
	elif est.etapa == "oposicion":
		_r["dia"].text = "Oposición · Sem. %d/%d" % [est.turno_actual, int(datos["leyes"]["oposicion"]["semanas"])]
	else:
		_r["dia"].text = "Día %d" % est.dia_actual
	_r["fecha"].text = Barras.fecha_texto(datos["leyes"], est.etapa, est.turno_actual, est.dia_actual, est.ciclo, est.dias_carrera)
	var cri := Barras.crisis(est, datos["leyes"]["dinamica"])  # la cuenta regresiva reemplaza la fecha, en coral
	if not cri.is_empty():
		_r["fecha"].text = String(cri["corto"])
	_r["fecha"].add_theme_color_override("font_color", Tema.mal() if not cri.is_empty() else Tema.TEXTO_SUAVE)
	var pa_txt := ManoUI.texto_pastilla(est, int(motor.movimientos.ahorro_movimientos()["tope_efectivo"]))
	Movimiento.movimientos((_r["pa"] as Control).get_parent().get_parent(), _btn_jugar, est.pa_actual, _r["pa"].text != "" and _r["pa"].text != pa_txt)
	_r["pa"].text = pa_txt
	_lbl_mov.text = ManoUI.texto_movimientos(est)
	Barras.pintar_chips(_r, est)
	_r["baul"].visible = est.etapa == "gobierno"  # las balas de plata solo existen en el gobierno
	if est.etapa == "gobierno":
		_r["baul_n"].text = str(motor.balas.usos_restantes())
	var obras: Dictionary = {}
	for o in est.obras_en_curso:
		obras[o["region"]] = int(obras.get(o["region"], 0)) + 1
	_mapa.bastion = String(est.partido.get("region_bastion", ""))
	var props: Dictionary = {}
	for pid in est.propuestas_abiertas:
		props[String(motor.catalogo_propuestas[pid].get("region", ""))] = true
	_mapa.actualizar(est.aprobacion_regional, obras, props)
	Barras.actualizar_evento(_r, motor)
	_r["ev_cab"].text = "" if String(_r["ev_hora"].text).contains("SIN EVENTOS") else "· " + String(_r["ev_titulo"].text)  # tocarlo muestra el evento completo
	_actualizar_region()
	_pintar_mano()
	_actualizar_botones()


func _actualizar_region() -> void:
	PanelesDia.pintar_region(_r, motor, datos, _region); _mapa.seleccion = _region  # contorno y línea siguen a la región elegida
	_riel.pintar(motor.estado.aprobacion_regional, _region)
	_mapa.enlace = _riel.boton(_region)  # línea punteada región → su fila del riel


func _pintar_mano() -> void:
	var est := motor.estado
	var n := est.mano.size()
	_sel = clampi(_sel, 0, maxi(0, n - 1))
	_mano.pintar(motor, _sel, "", _nuevas)  # la delegación va por PanelDelegar: aquí siempre sin ministro
	_nuevas = []
	if n == 0:
		_lbl_corrector.text = "[b]Sin cartas:[/b] antes de terminar la semana puedes revisar el Comité, el Congreso o tu gabinete."
		return
	var v := motor.vista_carta(_sel, "")
	var c: Dictionary = est.mano[_sel]
	var tit := String(c["titulo"])
	var cabeza := "[b]%s[/b] · cuesta %d · %s\n" % [tit if tit.length() <= 22 else tit.substr(0, 21) + "…", motor.costo_carta(c, ""), FichaCarta.linea(c, datos["leyes"])]
	if est.pa_actual == 0:  # sin movimientos: qué se puede hacer todavía
		var delega := est.etapa == "gobierno" and est.delegadas_turno < int(motor.catalogo_leyes["delegacion"]["max_por_turno"])
		_lbl_corrector.text = cabeza + "[b]Sin movimientos:[/b] " + ("delega esta carta en un ministro (no gasta movimientos) o termina la semana." if delega else "termina la semana; se renuevan al empezar la próxima.")
	elif est.etapa == "campana":
		_lbl_corrector.text = cabeza + "[b]Campaña:[/b] cada carta es una promesa: sube la aprobación de la región elegida y queda como meta de legado."
	elif v["corrector"]["aplica"]:
		_lbl_corrector.text = cabeza + "[b]Corrector:[/b] " + FichaCarta.caber(String(v["corrector"]["mensaje"]))
	else:
		_lbl_corrector.text = cabeza + "[b]Corrector:[/b] sin observaciones; la meta es viable."


func _actualizar_botones() -> void:
	var est := motor.estado
	var n := est.mano.size()
	var elec := est.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"]))
	_btn_jugar.text = "Ir a las urnas" if elec else ("Terminar semana" if est.pa_actual > 0 else "Siguiente semana")  # los disponibles se ven en la pastilla
	_btn_jugar.disabled = false
	var max_deleg := int(motor.catalogo_leyes["delegacion"]["max_por_turno"])
	_btn_deleg.disabled = est.etapa != "gobierno" or n == 0 or est.delegadas_turno >= max_deleg
	_btn_deleg.tooltip_text = "Delegar la carta elegida en un ministro (suelta la carta aquí)"
	_badge.text = str(max_deleg - est.delegadas_turno) if est.etapa == "gobierno" else ""


# ------------------------------------------------------------------ interacción
func _gesto_mano(pos: Vector2) -> void:
	if _btn_deleg.get_global_rect().has_point(pos):
		_delegar()
	elif pos.y <= _mano.get_global_rect().end.y:  # soltar hacia el mapa juega; soltar más abajo (fuera del ícono) cancela
		_jugar()


func _avanzar() -> void:
	## Botón del medio. Lo que no gastes se guarda hasta el tope (pedido del usuario del 27-nov-2026: «Los movimientos deben
	## poder guardar si no los use»), así que solo pide confirmar si alguno se perdería por el tope, o si vas a votar con pocas promesas (U3).
	var est := motor.estado
	var urnas := est.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"]))
	var minimo := int(datos["leyes"]["campana"]["min_promesas"])
	var ah := motor.movimientos.ahorro_movimientos()
	if not _confirmar_fin and ((urnas and est.promesas_campana.size() < minimo) or (not urnas and int(ah["se_pierden"]) > 0)):
		_confirmar_fin = true
		_avisar("Con menos de %d promesas serás intrascendente y perderás votos. Pulsa de nuevo para votar igual." % minimo if urnas else
			"Llegaste al tope de %d: se guardan %d y se pierden %d. Pulsa de nuevo para terminar la semana." % [int(ah["tope_efectivo"]), int(ah["se_guardan"]), int(ah["se_pierden"])])
		return
	_confirmar_fin = false
	_terminar_turno()
	if not urnas and int(ah["se_guardan"]) > 0 and not Movimiento.activo():  # con animaciones lo dice el telón
		_avisar("Se guardan %d %s para la próxima semana." % [int(ah["se_guardan"]), "movimiento" if int(ah["se_guardan"]) == 1 else "movimientos"])


func _on_carta(i: int) -> void:
	Feedback.sonar("toque")
	if i == _sel and _mano_tocada:  # tocar de nuevo la carta elegida la juega (respaldo del gesto de deslizar)
		_jugar()
		return
	_mano_tocada = true
	_sel = i
	_pintar_mano()
	_actualizar_botones()


func _on_region(id: String) -> void:
	_region = id
	_actualizar_region()


func _jugar() -> void:
	var n_reg := motor.estado.registro_acciones.size()
	var antes := motor.estado.indicadores.duplicate()
	var vuelo := ManoVuelo.datos(motor, _sel, _mano)  # la carta elegida (y dónde está) antes de que salga de la mano
	_mano_tocada = false
	var r := motor.jugar_carta(_sel, "", _region)
	if not bool(r["ok"]):
		Feedback.sonar("error")
		_avisar(Razones.texto(r))
		return
	_leer_reposicion(n_reg)
	var msg := "Carta jugada."
	if r.get("promesa", false):
		var donde := "nacional"  # sin región elegida la promesa reparte por igual entre todas
		for rg in datos["regiones"]:
			if rg["id"] == _region:
				donde = "en " + String(rg["nombre"])
		msg = "Promesa %s: +%s de aprobación%s" % [donde, Tema.dec(float(r["delta_aprobacion"])), ". Toca el mapa para dirigir la próxima" if donde == "nacional" else ""]
	elif r.get("escandalo", false):
		msg = "Polémica ministerial: pierdes aprobación y capital."
	elif r.get("propuesta") != null:
		msg = "Propuesta abierta en el Comité de Planificación."
		_abrir_panel("comite")
	elif r.get("proyecto") != null:
		msg = "Proyecto ingresado al Congreso."
	elif r["corrector"].get("aplica", false):
		msg = "Versión viable aplicada (%d %%)." % roundi(float(r["corrector"]["ratio"]) * 100.0)
	var cambios := Barras.resumen_cambios(antes, motor.estado.indicadores)  # consecuencia visible de la carta
	_avisar((msg if cambios == "" else msg + " " + cambios) + Barras.sufijo_carta(r))
	var color := Tema.mal() if bool(r.get("salio_mal", false)) or bool(r.get("escandalo", false)) else Tema.bien()
	ManoVuelo.lanzar(_capa, vuelo, _mapa, _region, color, func(destino: Vector2) -> void:
		Feedback.tras_jugar(_capa, r, cambios, _capa.get_global_transform().affine_inverse() * destino + Vector2(-40, -30))
		if bool(r.get("escandalo", false)):  # escándalo con peso: destello rojo, titular y chips que tiemblan
			GolpePrensa.mostrar(_capa, GolpePrensa.ministro_del_escandalo(motor, n_reg), [_r["chips"]["aprobacion"].get_parent().get_parent(), _r["chips"]["capital"].get_parent().get_parent()]))
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
		_avisar("Polémica ministerial: pierdes aprobación y capital." if r["escandalo"] else ("El ministro falló: efecto reducido." if r["fallo"] else "Delegada: el ministro la ejecutó sin gastar movimientos."))
		accion_hecha.emit()
		_refrescar()))


func _avisar(txt: String) -> void:
	_toast.mostrar(txt)


func _terminar_turno() -> void:
	Feedback.sonar("turno")
	var est := motor.estado
	var sem := int(datos["leyes"]["hemiciclo"]["semanas_campana"])
	if est.eleccion_pendiente(sem):
		_resolver_eleccion()
		return
	var antes := [String(_r["dia"].text), String(_r["fecha"].text)]
	var ind_antes := est.indicadores.duplicate()
	var guardados := int(motor.movimientos.ahorro_movimientos()["se_guardan"])
	var nuevos := motor.terminar_turno()
	accion_hecha.emit()
	if _panel_actual != "mapa":
		_abrir_panel(_panel_actual)  # la pestaña abierta (Congreso, Comité…) se rehace con el estado de la semana nueva
	if est.eleccion_pendiente(sem):
		_avisar("Termina la campaña: toca el botón de avanzar para ir a las urnas.")
	elif not MotorTurno.ETAPAS_JUEGO.has(est.etapa):
		terminado.emit()
		return
	_cola_eventos = OverlaysDia.eventos_de_votaciones(motor)
	var cri := Barras.crisis(est, datos["leyes"]["dinamica"])
	var corte := Barras.legado(est, datos["leyes"]["legado"])
	if not cri.is_empty():
		_avisar(String(cri["largo"]))
	elif not corte.is_empty() and int(corte["faltan"]) <= 4:  # se acerca el corte de legado: cuánto costarán las promesas pendientes
		_avisar(String(corte["texto"]))
	_cola_eventos.append_array(nuevos)
	_refrescar()
	TelonSemana.mostrar(_capa, antes, [String(_r["dia"].text), String(_r["fecha"].text)], ind_antes, est.indicadores, est.etapa == "oposicion", _siguiente_evento, est.encuestas if est.etapa in ["campana", "oposicion"] else [], datos["regiones"], sem, motor.motivos_semana(),
			"Guardaste %d %s: esta semana tienes %d." % [guardados, "movimiento" if guardados == 1 else "movimientos", est.pa_actual] if guardados > 0 else "")


func _resolver_eleccion() -> void:
	var regional := motor.estado.aprobacion_regional.duplicate()  # el desglose es el de la jornada, antes del amanecer de gobierno
	var res := motor.resolver_eleccion_presidencial()
	if res["electo"] or res["balotaje"]:
		motor.iniciar_turno()  # mismo orden que la reproducción desde guardado
	accion_hecha.emit()
	_capa.add_child(PantallaEleccion.crear(motor, datos["regiones"], regional, res, func() -> void:
		if res["electo"] or res["balotaje"]:
			_cola_eventos = motor.ultimos_eventos.duplicate()
			_refrescar()
			var e := motor.estado  # cambio de mando al ganar: banda presidencial antes del primer día
			var seguir := func() -> void:
				if PanelGabinete.transicion_pendiente(motor):
					transicion.emit()
				else:
					_siguiente_evento()
			if res["electo"]: CambioMando.mostrar(_capa, Barras.fecha_texto(datos["leyes"], e.etapa, e.turno_actual, e.dia_actual, e.ciclo, e.dias_carrera).substr(4), String(e.partido.get("nombre", "")), seguir)
			else: _siguiente_evento()
		else:
			terminado.emit(), geo))


func _siguiente_evento() -> void:
	if _cola_eventos.is_empty():
		return
	var ev: Dictionary = _cola_eventos.pop_front()
	if ev.get("menor", false):  # consecuencia de una carta: un aviso, no una pantalla completa
		_avisar(Barras.texto_consecuencia(ev))
		_siguiente_evento()
		return
	Feedback.sonar("evento")
	_capa.add_child(OverlaysDia.evento(ev, _siguiente_evento, motor.catalogo_leyes["congreso"]["nombres"], motor.estado.dia_actual,
			func(i: int) -> void:
				var a := motor.estado.indicadores.duplicate()
				Feedback.sonar("decision")
				_avisar(Barras.texto_decision(motor.eventos.decidir(String(ev["id"]), i), a, motor.estado.indicadores))
				_refrescar()))


func retomar_decisiones() -> void:
	## Si Android cerró la app con un evento con decisión en pantalla, el motor lo deja pendiente (ocurrió, sin decisión):
	## al continuar se vuelve a mostrar, para que el jugador elija y lleguen sus consecuencias.
	var ahora := motor.eventos.semana_abs()
	for evt in motor.catalogo_eventos:
		var id := String(evt["id"])
		if evt.has("opciones") and int(motor.estado.eventos_ocurridos.get(id, -1)) == ahora and not motor.estado.decisiones.has(id):
			_cola_eventos.append({"id": id, "titulo": evt["titulo"], "descripcion": evt["descripcion"], "hora": evt["hora_etiqueta"], "votacion": null, "efectos": [], "opciones": evt["opciones"]})
	_siguiente_evento()


func _poner_nav(nacion: bool, activo: String = "mapa") -> void:
	var nuevo := Barras.nav(_abrir_panel, nacion, "Día %d" % (motor.estado.dia_actual + motor.estado.dias_por_turno), func() -> void:
		_abrir_panel("mapa")
		_terminar_turno(), "Coalición" if motor.estado.etapa == "oposicion" else "Gabinete", activo)
	_raiz.add_child(nuevo)
	_raiz.move_child(nuevo, _nav.get_index())
	_nav.queue_free()
	_nav = nuevo


func _abrir_panel(cual: String) -> void:
	_panel_actual = cual
	_poner_nav(cual == "nacion", cual)
	for h in _zona_panel.get_children():
		h.queue_free()
	_zona_panel.visible = cual != "mapa"
	_mapa.get_parent().visible = cual in ["mapa", "gabinete"]  # el panel opaco tapa la vista: no se dibuja debajo (Gabinete deja ver la fila de botones)
	if cual == "mapa":
		return
	_zona_panel.offset_bottom = -66.0 if cual == "gabinete" else 0.0  # con Gabinete, la fila de Jugar/avanzar queda en su sitio
	var contenido: Control
	match cual:
		"comite":
			contenido = PanelComite.crear(motor, _aprobar, _region, func(pid: String) -> void:
					motor.impulsar_proyecto(pid)
					_refrescar()
					_abrir_panel("comite"))
		"nacion":
			contenido = PanelNacionCompleto.crear(motor, geo, datos["regiones"], "%s · %s" % [_r["ev_hora"].text.replace("• ", ""), _r["ev_titulo"].text],
					func() -> void:
						_abrir_panel("mapa")
						_terminar_turno())
		"congreso":
			contenido = PanelesDia.congreso(motor, _abrir_hito, _abrir_cartera, func(msg: String) -> void:
					_avisar(msg)
					accion_hecha.emit()
					_refrescar()
					_abrir_panel("congreso"), String(motor.estado.mano[_sel]["id"]) if _mano_tocada and _sel < motor.estado.mano.size() else "")
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
	Movimiento.aparecer(m)  # la hoja se funde y se asienta al abrirse


func _aprobar(pid: String, variante: String, custom: Dictionary = {}, nombres: Dictionary = {}) -> void:
	var r := motor.aprobar_propuesta(pid, variante, _region, custom, nombres)
	if bool(r["ok"]):
		_avisar("Obra aprobada: %d días de construcción." % int(r["dias"]))
		accion_hecha.emit()
		_refrescar()
		_abrir_panel("congreso")
	else:
		_avisar(Razones.texto(r))  # el motivo y la salida, no un «no» seco (CLAUDE.md §4, Corrector)


func _abrir_cartera() -> void:
	_capa.add_child(PantallaCartera.crear(datos, motor))


func _abrir_hito(obra: Dictionary) -> void:
	_capa.add_child(PantallaHito.crear(obra, datos["leyes"]["fases_obra"], func() -> void: pass, _abrir_urbano, motor.estado.lineas_jugador))


func _abrir_urbano() -> void:
	_capa.add_child(PantallaUrbano.crear(motor, UrbanoBase.datos(), func() -> void: pass, _abrir_hito))


func _abrir_baul() -> void:
	Feedback.sonar("toque")
	_capa.add_child(PanelBalas.crear(motor, func(msg: String) -> void:
		_avisar(msg)
		accion_hecha.emit()
		_refrescar()))
