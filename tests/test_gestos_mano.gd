extends SceneTree
## Gestos de la mano en la pantalla del día (CLAUDE.md §4/§5): tocar una carta la ELIGE; tocar de nuevo la carta elegida la JUEGA; tras jugarla, el siguiente toque
## (aunque caiga sobre la misma posición, ocupada ahora por otra carta) solo elige. Tocar otra carta cambia la elección sin jugar.
## (Hallazgo del mutation testing: si la selección no se limpiaba tras jugar, ninguna prueba lo notaba.)

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	Tutorial.ruta = "user://preferencias_gestos.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var datos: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(datos, 11, GeneradorPartido.construir_partido("G", "GGG", "metropolitana", resp, datos["ideologia"]))
	main.mostrar_dia()
	await process_frame
	var dia: Node = main._pantalla
	_check(dia is PantallaDia, "se llegó a la pantalla del día")
	var est: EstadoSimulacion = main.motor.estado
	for t in dia._capa.find_children("*", "Tutorial", true, false):
		t.queue_free()
	await process_frame
	# 1) primer toque: elige, no juega
	var pa0 := est.pa_actual
	var acciones0 := est.entradas.size()
	dia._on_carta(0)
	_check(est.pa_actual == pa0 and est.entradas.size() == acciones0, "el primer toque solo elige la carta (PA %d -> %d)" % [pa0, est.pa_actual])
	# 2) tocar otra carta: cambia la elección, no juega
	dia._on_carta(1)
	_check(est.pa_actual == pa0 and est.entradas.size() == acciones0, "tocar otra carta cambia la elección sin jugar")
	# 3) tocar de nuevo la elegida: la juega
	dia._on_carta(1)
	_check(est.pa_actual < pa0, "el segundo toque sobre la carta elegida la juega (PA %d -> %d)" % [pa0, est.pa_actual])
	var pa1 := est.pa_actual
	var entradas1 := est.entradas.size()
	# 4) tras jugar, un toque sobre la misma posición solo elige
	dia._on_carta(1)
	_check(est.pa_actual == pa1 and est.entradas.size() == entradas1, "tras jugar, el siguiente toque solo elige (PA %d -> %d)" % [pa1, est.pa_actual])
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	print("test_gestos_mano: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
