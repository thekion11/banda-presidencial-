extends SceneTree
## Texto que miente (idea de «Búsqueda infinita de fallas»): lo que la pantalla dice coincide con el motor. Un bot juega
## la campaña y semanas de gobierno; después de cada semana la cabecera (semana, fecha, movimientos y chips), el botón
## principal, el contador del gabinete, el riesgo de delegar y el puntaje del fin deben decir lo mismo que `estado`.
## Además ninguna cifra visible usa punto decimal («57.4 %»): en Chile es coma, y el punto queda para los miles.

var _fallos := 0
var _vistas := 0  # comprobaciones hechas (que la prueba no pase en vacío)
var _motivos_vistos := 0
var _decimal := RegEx.create_from_string("\\d\\.\\d(?!\\d)|\\d\\.\\d\\d(?!\\d)")


func _check(c: bool, msg: String) -> void:
	_vistas += 1
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


func _sin_punto_decimal(raiz: Node, donde: String) -> void:
	for n in raiz.find_children("*", "Control", true, false):
		if (n is Label or n is Button) and (n as Control).is_visible_in_tree():
			var t := String(n.get("text"))
			_check(_decimal.search(t) == null, "%s: «%s» usa punto decimal" % [donde, t.left(60)])


func _hay(raiz: Node, texto: String) -> bool:
	return raiz.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text.contains(texto) and not l.is_queued_for_deletion())


func _cabecera(dia: PantallaDia, donde: String) -> void:
	var est := dia.motor.estado
	_check(dia._r["pa"].text == ManoUI.texto_pastilla(est, int(dia.motor.movimientos.ahorro_movimientos()["tope_efectivo"])) and dia._r["pa"].text.begins_with(str(est.pa_actual)), "%s: la pastilla dice «%s» y quedan %d movimientos" % [donde, dia._r["pa"].text, est.pa_actual])
	var b := String(dia._btn_jugar.text)
	_check(b == "Ir a las urnas" or (b == "Terminar semana" if est.pa_actual > 0 else b == "Siguiente semana"), "%s: el botón dice «%s» con %d movimientos" % [donde, b, est.pa_actual])
	var sem := int(dia.datos["leyes"]["hemiciclo"]["semanas_campana"])
	var esperado := ("Campaña · Sem. %d/%d" % [mini(est.turno_actual, sem), sem]) if est.etapa == "campana" else ("Día %d" % est.dia_actual)
	_check(est.etapa == "oposicion" or dia._r["dia"].text == esperado, "%s: la cabecera dice «%s» y el motor está en «%s»" % [donde, dia._r["dia"].text, esperado])
	for k in dia._r["chips"].keys():
		var ind := "rival" if est.etapa == "oposicion" and k == "fiscal" else String(k)
		_check(dia._r["chips"][k].text == str(roundi(est.ind(ind))), "%s: el chip %s dice %s y el motor %s" % [donde, k, dia._r["chips"][k].text, Tema.dec(est.ind(ind))])
	_sin_punto_decimal(dia, donde)


func _correr() -> void:
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_veracidad.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _cuadros(2)
	var d: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var rng := RandomNumberGenerator.new()
	var motor: MotorTurno = null
	for semilla in [41, 43, 47, 53]:  # una partida que gane la elección, para ver también el gobierno
		rng.seed = semilla
		motor = Partida.crear(d, semilla, GeneradorPartido.construir_partido("Verdad", "VER", "metropolitana", resp, d["ideologia"]))
		main.motor = motor
		main.mostrar_dia()
		await _cuadros(2)
		for s in range(int(d["leyes"]["hemiciclo"]["semanas_campana"])):
			Bots.jugar_turno(motor, "experto", rng)
			main._pantalla._refrescar()
			await _cuadros(1)
			_cabecera(main._pantalla, "campaña sem. %d" % (s + 1))
			motor.terminar_turno()
		if Bots.elegir(motor, d, "experto", rng) and motor.estado.etapa == "gobierno":
			break
	_check(motor.estado.etapa == "gobierno", "algún bot llega al gobierno")
	main.mostrar_dia()
	await _cuadros(2)
	var dia: PantallaDia = main._pantalla
	for s in range(6):
		Bots.jugar_turno(motor, "experto", rng)
		dia._refrescar()
		await _cuadros(1)
		_cabecera(dia, "gobierno sem. %d" % (s + 1))
		motor.terminar_turno()
		var mv := motor.motivos_semana()  # el telón explica los cambios con estas filas
		var lineas := TelonSemana.lineas_motivos(mv)
		_check(lineas.size() == mv.size() and mv.size() <= 3, "el telón muestra una línea por motivo (%d de %d)" % [lineas.size(), mv.size()])
		for k in range(lineas.size()):
			_check(lineas[k].ends_with(": " + String(mv[k]["causa"])) and lineas[k].contains("−" if float(mv[k]["delta"]) < 0.0 else "+") and _decimal.search(lineas[k]) == null, "motivo bien escrito: «%s»" % lineas[k])
		_motivos_vistos += mv.size()
		dia._refrescar()
		await _cuadros(1)
		_cabecera(dia, "gobierno, inicio de la sem. %d" % (s + 2))
	# gabinete: el contador dice cuántos ministros hay de verdad
	dia._abrir_panel("gabinete")
	await _cuadros(2)
	var cont: Array = dia._zona_panel.find_children("*", "Label", true, false).filter(func(l: Label) -> bool: return l.text.begins_with("Gabinete: "))
	_check(not cont.is_empty() and cont[0].text == "Gabinete: %d de %d ministros" % [motor.estado.gabinete.size(), int(motor.catalogo_leyes["gabinete"]["tamano"])], "el contador del gabinete coincide (%s)" % (cont[0].text if not cont.is_empty() else "no está"))
	_sin_punto_decimal(dia, "panel gabinete")
	for panel in ["comite", "congreso", "nacion"]:
		dia._abrir_panel(panel)
		await _cuadros(2)
		_sin_punto_decimal(dia, "panel " + panel)
	# agenda legislativa (pestaña Congreso): el contador y la lista dicen lo del motor, y presentar desde la pantalla la agrega
	dia._abrir_panel("congreso")
	await _cuadros(2)
	var ea := motor.agenda.estado_agenda()
	_check(_hay(dia._zona_panel, "Agenda del gobierno · %d de %d en trámite" % [int(ea["en_tramite"]), int(ea["maximo"])]), "agenda: el contador coincide con el motor")
	var cat := motor.agenda.agenda_catalogo()
	if bool(ea["puede_presentar"]) and not cat.is_empty():
		var titulo := String(cat[0]["titulo"])
		var cabs: Array = dia._zona_panel.find_children("*", "Label", true, false).filter(func(l: Label) -> bool: return l.text == titulo)
		_check(not cabs.is_empty(), "agenda: el catálogo muestra «%s»" % titulo)
		if not cabs.is_empty():
			var cab: Node = cabs[0]
			while cab != null and not (cab is Button):
				cab = cab.get_parent()
			(cab as Button).pressed.emit()  # abre sus urgencias
			await _cuadros(2)
			var urg: Array = dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with(String(cat[0]["urgencias"][0]["nombre"]) + " · ") and not b.disabled)
			var antes := motor.agenda.en_tramite().size()
			if not urg.is_empty():
				(urg[0] as Button).pressed.emit()
				await _cuadros(3)
				var ahora := motor.agenda.en_tramite()
				_check(ahora.size() == antes + 1 or _hay(dia._zona_panel, "Elige la urgencia"), "agenda: presentar desde la pantalla lo deja en trámite (o el Corrector responde)")
				if ahora.size() == antes + 1:
					_check(_hay(dia._zona_panel, String(ahora.back()["etapa_nombre"])) and _hay(dia._zona_panel, "aprobación %d %%" % roundi(float(ahora.back()["prob_aprobacion"]) * 100.0)), "agenda: el proyecto en trámite muestra su etapa y su probabilidad del motor")
		_sin_punto_decimal(dia, "agenda legislativa")
	dia._abrir_panel("mapa")
	await _cuadros(1)
	# delegar: cada fila dice la probabilidad real de fallo de ese ministro con la carta elegida
	var puede := motor.estado.delegadas_turno < int(motor.catalogo_leyes["delegacion"]["max_por_turno"]) and not motor.estado.mano.is_empty()
	_check(puede, "al empezar la semana se puede delegar (para revisar la hoja)")
	if puede:
		dia._delegar()
		await _cuadros(2)
		var filas: Array = dia._capa.find_children("*", "Label", true, false).filter(func(l: Label) -> bool: return l.text.begins_with("Probabilidad de fallo: "))
		_check(filas.size() == motor.estado.gabinete.size(), "la hoja de delegar lista a todo el gabinete (%d de %d)" % [filas.size(), motor.estado.gabinete.size()])
		var esperadas: Array = motor.estado.gabinete.map(func(id: String) -> String: return "Probabilidad de fallo: %d %%" % roundi(motor.prob_fallo_delegacion(dia._sel, id) * 100.0))
		_check(not filas.is_empty(), "la hoja de delegar muestra probabilidades")
		for l in filas:
			_check(esperadas.has(l.text), "delegar: «%s» no es la probabilidad de ningún ministro" % l.text)
		_sin_punto_decimal(dia, "hoja de delegar")
		for h in dia._capa.get_children():
			if h is Control and h != dia._toast:
				h.queue_free()
		await _cuadros(1)
	_check(_motivos_vistos > 0, "en 6 semanas de gobierno hubo algún cambio con causa para el telón")
	# telón con encuesta y 3 motivos en el teléfono bajo: todo en pantalla
	Movimiento.forzado = 1
	root.content_scale_size = Vector2i(390, 693)
	var capa := Control.new()
	capa.size = Vector2(390, 693)
	root.add_child(capa)
	var tres := [{"ind": "cohesion", "delta": -1.85, "causa": "desgaste del gobierno"}, {"ind": "riesgo_ejecucion", "delta": 2.0, "causa": "obras atrasadas en regiones"}, {"ind": "capital", "delta": -1.0, "causa": "rechazo del Congreso a tu proyecto de ley"}]
	TelonSemana.mostrar(capa, ["Semana 3", ""], ["Semana 4", "Dom 12 oct 2025"], {"aprobacion": 40.0, "capital": 50.0, "cohesion": 80.0, "fiscal": 50.0}, {"aprobacion": 41.0, "capital": 49.0, "cohesion": 78.15, "fiscal": 50.0}, false, func() -> void: pass,
		[{"intencion": 40.0, "margen": 3.0}, {"etapa": "campana", "turno": 4, "intencion": 41.5, "margen": 2.8, "umbral": 51.0, "rival": null, "regiones": [{"id": "aysen", "valor": 31.0}]}], d["regiones"], 8, tres)
	await create_timer(0.8).timeout
	var tl: Array = capa.find_children("*", "Label", true, false)
	_check(tl.any(func(l: Label) -> bool: return l.text == "Cohesión −1,9: desgaste del gobierno"), "el telón dice por qué bajó la cohesión")
	for l: Label in tl:
		_check(l.get_global_rect().end.y <= 693.5, "telón en 390×693: «%s» se sale por abajo (%s)" % [l.text.left(30), l.get_global_rect()])
	capa.queue_free()
	Movimiento.forzado = 0
	root.content_scale_size = Vector2i(390, 844)
	await _cuadros(1)
	# fin del mandato: el puntaje en pantalla es el del motor y los hitos no usan punto decimal
	for h in motor.mandato.hitos(1000):
		_check(_decimal.search(String(h["texto"])) == null, "hito con punto decimal: «%s»" % String(h["texto"]))
	motor.mandato.finalizar("fin_mandato")
	main.mostrar_fin()
	await _cuadros(3)
	var pts := str(int(motor.estado.resultado_final.get("puntaje", -1)))
	var hay: bool = main._pantalla.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text == pts)
	_check(hay, "la pantalla de fin muestra el puntaje del motor (%s)" % pts)
	_sin_punto_decimal(main._pantalla, "fin")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_GUARDADO))
	_check(_vistas > 400, "la prueba hizo muchas comprobaciones (%d)" % _vistas)
	if _fallos == 0:
		print("VERACIDAD OK (%d comprobaciones)" % _vistas)
	quit(1 if _fallos > 0 else 0)
