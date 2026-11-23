extends SceneTree
## Presupuesto técnico (CLAUDE.md §5): RAM ≤ 800 MB con las escenas 3D abiertas y paquete de datos pequeño.
## En headless mide la memoria estática del proceso; la prueba en teléfono real sigue pendiente.

const LIMITE_MB := 800.0
var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO PRESUPUESTO: ", msg)


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	var inicio := OS.get_static_memory_usage() / 1048576.0
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var resp: Array[Dictionary] = []
	for p in main.datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("P", "P", "metropolitana", resp, main.datos["ideologia"])
	main.motor = Partida.crear(main.datos, 5, partido)
	main.motor.estado.etapa = "gobierno"
	main.motor.estado.propuestas_abiertas.append("prop_metro_suroriente")
	main.mostrar_dia()
	await process_frame
	var dia: Node = main._pantalla
	dia._abrir_panel("comite")
	await process_frame
	dia._zona_panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return b.text == "3D")[0].pressed.emit()
	await process_frame
	dia._abrir_hito({"nombre": "Obra", "dias_totales": 400, "dias_avanzados": 200, "retrasos": 0, "carta_id": "", "region": "metropolitana", "efectos_final": []})
	for _i in range(5):
		await process_frame
	var usado := OS.get_static_memory_usage() / 1048576.0
	print("Memoria estática: %.1f MB (inicio %.1f MB)" % [usado, inicio])
	_check(usado < LIMITE_MB, "supera %d MB" % int(LIMITE_MB))
	var bytes := 0
	for carpeta in ["res://data/", "res://game/arte/cartas/"]:
		var d := DirAccess.open(carpeta)
		for f in d.get_files():
			if f.ends_with(".json") or f.ends_with(".jpg"):
				bytes += FileAccess.get_file_as_bytes(carpeta + f).size()
	print("Datos + arte de cartas: %.1f MB" % (bytes / 1048576.0))
	_check(bytes < 20.0 * 1048576.0, "los datos base pesan demasiado")
	if _fallos == 0:
		print("PRESUPUESTO OK")
	quit(0 if _fallos == 0 else 1)
