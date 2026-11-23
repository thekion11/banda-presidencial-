extends SceneTree
## Capturas de pantalla para comparar con la maqueta. Requiere ventana (xvfb) y renderer GL.
## Uso: xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/captura.gd -- <carpeta>

var _dir: String = "/tmp"


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_dir = a[0]
	_correr.call_deferred()


func _guardar(nombre: String) -> void:
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	root.get_texture().get_image().save_png("%s/%s.png" % [_dir, nombre])
	print("captura ", nombre)


func _correr() -> void:
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await _guardar("01_menu")
	main.mostrar_partido()
	await _guardar("02_test")
	var pp: Node = main._pantalla
	pp._responder(main.datos["ideologia"]["preguntas"][0]["opciones"][1])
	pp._responder(main.datos["ideologia"]["preguntas"][1]["opciones"][0])
	await _guardar("03_test_pregunta3")
	for i in range(2, 8):
		pp._responder(main.datos["ideologia"]["preguntas"][i]["opciones"][1])
	await _guardar("04_fundacion")
	var est_dummy: Dictionary = {}
	main.motor = Partida.crear(main.datos, 7, GeneradorPartido.construir_partido("Movimiento Cívico Austral", "MCA", "metropolitana", [main.datos["ideologia"]["preguntas"][0]["opciones"][1]], main.datos["ideologia"]))
	main.motor.estado.etapa = "fin_mandato"
	main.motor.estado.resultado_final = {"motivo": "fin_mandato", "puntaje": 812, "aprobacion": 47.3, "obras": 6, "promesas_pendientes": 2}
	main.mostrar_fin()
	await _guardar("05_fin")
	quit(0)
