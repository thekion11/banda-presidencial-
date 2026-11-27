extends SceneTree
## Ciclo de vida de Android (cola 8): en cada subestado la app pasa a segundo plano (NOTIFICATION_APPLICATION_PAUSED),
## el sistema la mata (Main se destruye sin más avisos) y se vuelve a abrir con «Continuar partida». Se retoma en la
## pantalla correcta y con el mismo estado del motor: nada se pierde ni queda a medias.

var _fallos := 0
var _datos: Dictionary


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


static func _foto(m: MotorTurno) -> Dictionary:
	var e := m.estado
	return {"etapa": e.etapa, "turno": e.turno_actual, "dia": e.dia_actual, "pa": e.pa_actual, "ind": str(e.indicadores), "mano": str(e.mano.map(func(c: Dictionary) -> String: return String(c["id"]))),
		"gabinete": str(e.gabinete), "entradas": e.entradas.size(), "decisiones": str(e.decisiones.keys())}


func _abrir() -> Node:
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _cuadros(2)
	return main


func _matar_y_volver(main: Node, caso: String) -> Node:
	## Pausa (Android guarda aquí), muerte sin más avisos y reapertura con «Continuar partida».
	var antes := _foto(main.motor) if main.motor != null else {}
	main.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	main.free()
	for f in root.find_children("*", "FichaAmpliada", true, false):  # la ficha cuelga de la raíz: con la app muerta no existe
		f.free()
	var nuevo: Node = await _abrir()
	_check(nuevo._pantalla is PantallaMenu and nuevo._pantalla.hay_guardado, "%s: al volver el menú ofrece «Continuar partida»" % caso)
	nuevo.continuar_guardado()
	await _cuadros(3)
	if not antes.is_empty():
		var despues := _foto(nuevo.motor)
		for k in antes.keys():
			_check(antes[k] == despues[k], "%s: %s cambió al volver (%s → %s)" % [caso, k, str(antes[k]).left(60), str(despues[k]).left(60)])
	return nuevo


func _correr() -> void:
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_ciclo.json"
	Tutorial.marcar_visto()
	for r in ["user://guardado.json", "user://guardado.bak", "user://guardado.cache"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(r))
	var main: Node = await _abrir()
	_datos = main.datos
	var resp: Array[Dictionary] = []
	for p in _datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	main._iniciar_campana(GeneradorPartido.construir_partido("Ciclo", "CIC", "metropolitana", resp, _datos["ideologia"]))
	await _cuadros(3)
	if not (main._pantalla is PantallaDia):
		main.mostrar_dia()
		await _cuadros(2)
	# 1) campaña, con una carta recién jugada
	var dia: PantallaDia = main._pantalla
	dia._sel = 0
	dia._jugar()
	await _cuadros(2)
	main = await _matar_y_volver(main, "campaña")
	_check(main._pantalla is PantallaDia and main.motor.estado.etapa == "campana", "campaña: vuelve al día de campaña")
	# 2) ficha ampliada abierta (cuelga de la raíz) y telón a medias: no dejan nada al volver
	root.add_child(FichaAmpliada.crear(main.motor.estado.mano[0], 1, main.motor.catalogo_leyes))
	main = await _matar_y_volver(main, "ficha abierta")
	_check(root.find_children("*", "FichaAmpliada", true, false).is_empty(), "ficha abierta: no queda una ficha flotando al volver")
	# 3) fin de la campaña con la elección pendiente: vuelve al día con «Ir a las urnas»
	var sem := int(_datos["leyes"]["hemiciclo"]["semanas_campana"])
	while not main.motor.estado.eleccion_pendiente(sem):
		Bots.jugar_turno(main.motor, "experto", rng)
		main.motor.terminar_turno()
	main.guardar()
	main = await _matar_y_volver(main, "elección pendiente")
	_check(main._pantalla is PantallaDia and main._pantalla._btn_jugar.text == "Ir a las urnas", "elección pendiente: el botón es «Ir a las urnas» (%s)" % main._pantalla._btn_jugar.text)
	# 4) gobierno (si el bot gana) con la hoja de delegación abierta
	if Bots.elegir(main.motor, _datos, "experto", rng) and main.motor.estado.etapa == "gobierno":
		main.guardar()
		main.mostrar_dia()
		await _cuadros(2)
		main._pantalla._delegar()
		await _cuadros(1)
		main = await _matar_y_volver(main, "gobierno con la hoja de delegar abierta")
		_check(main._pantalla is PantallaDia and main.motor.estado.etapa == "gobierno", "gobierno: vuelve al día de gobierno")
		var encima: Array = main._pantalla._capa.get_children().filter(func(h: Node) -> bool: return h != main._pantalla._toast)
		_check(encima.all(func(h: Node) -> bool: return not h.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text.begins_with("DELEGAR"))), "gobierno: la hoja de delegar no reaparece a medias")
		# 5) fin del mandato: vuelve a la pantalla de fin
		main.motor.mandato.finalizar("fin_mandato")
		main.mostrar_fin()
		await _cuadros(2)
		main = await _matar_y_volver(main, "fin del mandato")
		_check(main._pantalla is PantallaFin, "fin: vuelve a la pantalla de fin (%s)" % main._pantalla.get_class())
	else:
		_check(false, "el bot de la semilla 41 debía ganar la elección para probar el gobierno")
	main.queue_free()
	for r in [Tutorial.ruta, "user://guardado.json", "user://guardado.bak", "user://guardado.cache", "user://ultima_config.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(r))
	if _fallos == 0:
		print("CICLO DE VIDA OK")
	quit(1 if _fallos > 0 else 0)
