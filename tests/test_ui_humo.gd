extends SceneTree
## Humo de UI en modo headless: recorre menú -> test -> campaña -> elección -> gobierno sin errores de script.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO UI: ", msg)


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.mostrar_partido()
	await process_frame
	var pp: Node = main._pantalla
	for p in main.datos["ideologia"]["preguntas"]:
		pp._responder(p["opciones"][1])
	await process_frame
	pp._fundar()
	await process_frame
	var dia: Node = main._pantalla
	_check(dia is PantallaDia, "no se llegó a la pantalla de día")
	for sem in range(8):
		dia._cola_eventos.clear()
		dia._on_region("metropolitana")
		for _k in range(4):
			if not main.motor.estado.mano.is_empty():
				dia._jugar()
		dia._terminar_turno()
		await process_frame
	_check(main.motor.estado.eleccion_pendiente(8), "debería haber elección pendiente")
	dia._resolver_eleccion()
	await process_frame
	for panel in ["comite", "congreso", "gabinete", "mapa"]:
		dia._abrir_panel(panel)
		await process_frame
	_check(not main.motor.estado.partido.is_empty(), "partido vacío")
	var guardado: Dictionary = main.motor.estado.exportar_guardado()
	var rep: MotorTurno = Partida.reproducir(main.datos, guardado)
	_check(rep.estado.calcular_huella() == main.motor.estado.calcular_huella(), "guardado no reproduce la partida de la UI")
	if _fallos == 0:
		print("HUMO DE UI OK")
	quit(0 if _fallos == 0 else 1)
