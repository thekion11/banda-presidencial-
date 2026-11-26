extends SceneTree
## Respaldo del guardado (guardado.bak): (1) principal dañado + respaldo válido: se recupera; (2) ambos dañados: aviso y partida nueva, sin SCRIPT ERROR; (3) un respaldo dañado
## nunca reemplaza a un guardado bueno; (4) guardar() deja siempre el último guardado bueno como respaldo y ningún .tmp; (5) un respaldo de otra versión de los datos no se usa.

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


func _escribir(ruta: String, texto: String) -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(texto)
	f.close()


func _borrar(ruta: String) -> void:
	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _correr() -> void:
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_respaldo.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var resp: Array[Dictionary] = []
	for p in main.datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(main.datos, 21, GeneradorPartido.construir_partido("R", "R", "metropolitana", resp, main.datos["ideologia"]))
	main.mostrar_dia()
	await _cuadros(2)
	var G: String = main.RUTA_GUARDADO
	var B: String = main.RUTA_RESPALDO
	for r in [G, B, G + ".tmp", "user://guardado_descartado.json"]:
		_borrar(r)
	# (4) guardar() deja el último guardado bueno como respaldo y ningún .tmp
	main.guardar()
	var primero := FileAccess.get_file_as_string(G)
	main.motor.terminar_turno()  # agrega una entrada: el guardado cambia
	main.guardar()
	var segundo := FileAccess.get_file_as_string(G)
	_check(FileAccess.get_file_as_string(B) == primero and primero != segundo, "tras el segundo guardado el respaldo es el primero")
	_check(not FileAccess.file_exists(G + ".tmp"), "no queda ningún .tmp")
	# (1) principal dañado con respaldo válido: se recupera y el principal vuelve a ser válido
	_escribir(G, "{\"semilla\": 21, \"entradas\"")
	main.continuar_guardado()
	await _cuadros(2)
	_check(main._pantalla is PantallaDia and main.motor != null, "principal dañado + respaldo válido: se recupera la partida")
	_check(ValidarGuardado.guardado_valido(Datos.leer_json(G)), "después de recuperar, el guardado principal vuelve a ser válido")
	# (2) ambos dañados: aviso y menú, sin partida a medias
	_escribir(G, "no es json")
	_escribir(B, "{\"semilla\": 1, \"entradas\": \"roto\"}")
	main.continuar_guardado()
	await _cuadros(2)
	_check(main._pantalla is PantallaMenu and _textos(main._pantalla).contains("Empieza una partida nueva"), "ambos dañados: el menú avisa y ofrece partida nueva")
	_check(not FileAccess.file_exists(G), "ambos dañados: «Continuar» no reaparece fallando")
	# (3) un respaldo dañado no reemplaza a un guardado bueno: con el principal válido, continuar no toca el principal ni usa el respaldo
	main.motor = Partida.crear(main.datos, 22, GeneradorPartido.construir_partido("R", "R", "metropolitana", resp, main.datos["ideologia"]))
	for r in [G, B]:
		_borrar(r)
	main.guardar()
	var bueno := FileAccess.get_file_as_string(G)
	_escribir(B, "basura")
	main.continuar_guardado()
	await _cuadros(2)
	_check(main._pantalla is PantallaDia and FileAccess.get_file_as_string(G) == bueno, "con el principal bueno, un respaldo dañado no lo reemplaza")
	# (5) respaldo de otra versión de los datos: no se usa
	_escribir(G, "roto")
	var viejo: Dictionary = JSON.parse_string(bueno)
	viejo["huella_datos"] = "otra_huella"
	_escribir(B, JSON.stringify(viejo))
	main.continuar_guardado()
	await _cuadros(2)
	_check(main._pantalla is PantallaMenu, "un respaldo de otra versión de los datos no se recupera")
	for r in [G, B, G + ".tmp", "user://guardado_descartado.json", "user://preferencias_respaldo.json"]:
		_borrar(r)
	print("test_respaldo_guardado: ", "OK" if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)


func _textos(n: Node) -> String:
	var t: PackedStringArray = []
	for l in n.find_children("*", "Label", true, false):
		t.append((l as Label).text)
	for l in n.find_children("*", "RichTextLabel", true, false):
		t.append((l as RichTextLabel).get_parsed_text())
	return "\n".join(t)
