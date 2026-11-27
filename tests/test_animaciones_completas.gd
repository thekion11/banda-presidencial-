extends SceneTree
## Animaciones a medias (idea de «Búsqueda infinita de fallas»): con el movimiento encendido se cambia de pantalla y de
## panel cada cuadro, se pausa y reanuda la app en medio de una transición, y tras esperar a que todo termine no
## quedan tweens finitos vivos ni nodos visibles con transparencia o escala de una entrada que no terminó.

const ESPERA := 3.5  # más que la entrada más larga (el mapa del día tarda ~3 s en asentarse)

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


func _esperar() -> void:
	await create_timer(ESPERA).timeout
	await _cuadros(3)


func _quieto(main: Node, donde: String) -> void:
	var vivos := get_processed_tweens().filter(func(t: Tween) -> bool: return t.is_valid() and t.is_running() and t.get_loops_left() != -1)
	_check(vivos.is_empty(), "%s: quedan %d tweens finitos sin terminar" % [donde, vivos.size()])
	var raros: Array[String] = []
	for n in main.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or c is Particulas or c.get_parent().has_meta("_halo"):  # el halo respira a propósito
			continue
		if c.modulate.a < 0.99 or not c.scale.is_equal_approx(Vector2.ONE) and c.get_parent() is Container:
			raros.append("%s (%s) a=%.2f escala=%s" % [c.name, c.get_class(), c.modulate.a, c.scale])
	_check(raros.is_empty(), "%s: %d nodos quedaron a medias: %s" % [donde, raros.size(), ", ".join(raros.slice(0, 5))])


func _correr() -> void:
	Movimiento.forzado = 1
	Tutorial.ruta = "user://preferencias_anim.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await _cuadros(2)
	var d: Dictionary = main.datos
	# 1) cambiar de pantalla cada cuadro: menú → afiliación → partido → menú → afiliación
	for paso in ["afiliacion", "partido", "menu", "afiliacion"]:
		match paso:
			"afiliacion": main.mostrar_afiliacion()
			"partido": main.mostrar_partido("propio")
			"menu": main.mostrar_menu()
		await process_frame
	await _esperar()
	_quieto(main, "cambios rápidos de pantalla")
	# 2) el día con los paneles abiertos y cerrados cada cuadro
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(d, 29, GeneradorPartido.construir_partido("A", "A", "metropolitana", resp, d["ideologia"]))
	main.mostrar_dia()
	await process_frame
	var dia: PantallaDia = main._pantalla
	for panel in ["comite", "congreso", "gabinete", "nacion", "mapa", "congreso", "mapa"]:
		dia._abrir_panel(panel)
		await process_frame
	await _esperar()
	_quieto(main, "paneles abiertos y cerrados cada cuadro")
	# 3) jugar una carta y cambiar de panel durante el vuelo
	dia._sel = 0
	dia._jugar()
	await _cuadros(2)
	dia._abrir_panel("comite")
	await process_frame
	dia._abrir_panel("mapa")
	await _esperar()
	await _esperar()  # el vuelo de la carta y los números flotantes duran más
	_quieto(main, "carta jugada y panel cambiado en pleno vuelo")
	# 4) la app se va a segundo plano en medio de la entrada de una pantalla y vuelve
	main.mostrar_afiliacion()
	await process_frame
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await _cuadros(2)
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _esperar()
	_quieto(main, "pausa y vuelta en plena transición")
	Movimiento.forzado = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_GUARDADO))
	if _fallos == 0:
		print("ANIMACIONES COMPLETAS OK")
	quit(1 if _fallos > 0 else 0)
