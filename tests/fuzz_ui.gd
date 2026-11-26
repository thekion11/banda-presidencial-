extends SceneTree
## Fuzz de UI: juega cartas, toca regiones, delega, abre paneles y termina semanas muy seguidos (a veces sin esperar ningún cuadro)
## con las animaciones encendidas (Movimiento.forzado = 1). Cubre carreras como «dos cartas seguidas dejan la onda del mapa sin pos».
## Las fallas de script salen como «SCRIPT ERROR» en la salida: ejecutarlo con `| grep -E "FUZZ UI|SCRIPT ERROR"`.
## Uso: godot --headless --path . -s tests/fuzz_ui.gd -- [partidas] [semilla_inicial] [modo]
## modo: normal (por defecto) | reducir (Ajustes.reducir) | grande (Ajustes.texto_grande) | todo (reducir + texto grande + daltónico).
## Además avisa («AVISO UI») de los textos visibles que se salen del ancho de la pantalla (390 px). Son avisos, no fallos. OJO: en headless la ventana mide 64x64 y el diseño se descuadra
## (falsos avisos); para medir desbordes usa xvfb: xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/fuzz_ui.gd -- 6 400 todo

var _fallos: int = 0
var _avisos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO FUZZ UI: ", msg)


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 6
	var s0 := int(args[1]) if args.size() > 1 else 400
	var modo := String(args[2]) if args.size() > 2 else "normal"
	Ajustes.reducir = modo == "reducir" or modo == "todo"
	Ajustes.texto_grande = modo == "grande" or modo == "todo"
	Ajustes.daltonico = modo == "todo"
	Tutorial.ruta = "user://preferencias_fuzz.json"
	Movimiento.forzado = 1
	for i in range(n):
		await _una(s0 + i)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	Movimiento.forzado = -1
	Ajustes.reducir = false
	Ajustes.texto_grande = false
	Ajustes.daltonico = false
	print("FUZZ UI %s (modo %s, %d partidas, %d avisos de desborde, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", modo, n, _avisos, _fallos])
	quit(0 if _fallos == 0 else 1)


func _esperar(rng: RandomNumberGenerator) -> void:
	for _k in range(rng.randi_range(0, 2)):  # 0 cuadros = acciones pegadas
		await process_frame


func _una(semilla: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.mostrar_partido()
	await process_frame
	var pp: Node = main._pantalla
	for p in pp._preguntas():
		pp._responder(p["opciones"][rng.randi_range(0, 2)])
	for _k in range(3):
		await process_frame
	pp._fundar()
	await process_frame
	var partido: Dictionary = main.motor.estado.partido.duplicate(true)
	partido["indicadores_iniciales"]["aprobacion"] = 90.0
	main.motor = Partida.crear(main.datos, semilla, partido)
	main.mostrar_gabinete()
	await process_frame
	var conf: Array = main._pantalla.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with("Comenzar campaña"))
	_check(conf.size() == 1, "semilla %d: falta el botón de comenzar campaña" % semilla)
	if conf.size() != 1:
		main.queue_free()
		return
	conf[0].pressed.emit()
	await process_frame
	var dia: Node = main._pantalla
	_check(dia is PantallaDia, "semilla %d: no se llegó a la pantalla de día" % semilla)
	if not (dia is PantallaDia):
		main.queue_free()
		return
	for t in dia._capa.find_children("*", "Tutorial", true, false):
		t.queue_free()
	await process_frame
	var regiones: Array = main.motor.regiones.catalogo.map(func(r: Dictionary) -> String: return String(r["id"]))
	var paneles := ["comite", "congreso", "gabinete", "mapa"]
	for semana in range(rng.randi_range(6, 14)):
		if not is_instance_valid(dia) or main._pantalla != dia:
			break
		var est: EstadoSimulacion = main.motor.estado
		for _a in range(rng.randi_range(4, 14)):
			if not is_instance_valid(dia) or main._pantalla != dia:
				break
			match rng.randi_range(0, 6):
				0:
					dia._on_region(regiones[rng.randi_range(0, regiones.size() - 1)])
				1, 2:
					dia._on_carta(rng.randi_range(0, 4))
					dia._on_carta(dia._sel)  # el segundo toque a la misma carta la juega
				3:
					dia._jugar()
				4:
					dia._delegar()
				5:
					dia._abrir_panel(paneles[rng.randi_range(0, 3)])
				6:
					dia._cola_eventos.clear()
			await _esperar(rng)
		if not is_instance_valid(dia) or main._pantalla != dia:
			break
		dia._cola_eventos.clear()
		if est.eleccion_pendiente(int(main.datos["leyes"]["hemiciclo"]["semanas_campana"])):
			dia._resolver_eleccion()
		else:
			dia._terminar_turno()
		for _k in range(rng.randi_range(0, 3)):
			await process_frame
	for _k in range(5):
		await process_frame  # deja correr las animaciones pendientes: una onda sin «pos» falla en el _draw
	await create_timer(1.2).timeout  # que terminen las animaciones de entrada antes de medir
	_desbordes(dia, semilla)
	main.queue_free()
	await process_frame


func _visible_recortado(c: Control) -> Rect2:
	## Rectángulo del control ya recortado por los contenedores que cortan su contenido (ScrollContainer o clip_contents).
	var r := c.get_global_rect()
	var p := c.get_parent()
	while p is Control:
		var pc := p as Control
		if pc is ScrollContainer or pc.clip_contents:
			r = r.intersection(pc.get_global_rect())
		p = p.get_parent()
	return r


func _desbordes(dia: Node, semilla: int) -> void:
	if not is_instance_valid(dia):
		return
	var ancho := float(root.get_visible_rect().size.x)
	for l in dia.find_children("*", "Label", true, false):
		var c := l as Label
		if c.text == "" or not c.is_visible_in_tree():
			continue
		var r := _visible_recortado(c)
		if r.size.x > 1.0 and (r.end.x > ancho + 1.0 or r.position.x < -1.0):
			_avisos += 1
			if _avisos <= 6:
				print("AVISO UI: semilla %d, texto «%s» fuera del ancho (%s)" % [semilla, c.text.left(40), str(r)])
