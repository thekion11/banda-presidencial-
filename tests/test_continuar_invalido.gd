extends SceneTree
## «Continuar» con un guardado de huella correcta pero estructura inválida (por ejemplo una entrada sin sus claves, de otra versión del juego): el archivo se descarta
## (guardado_descartado.json), el juego vuelve al menú con el aviso y «Continuar» no vuelve a fallar. Lo mismo con un guardado de otra versión de los datos (huella
## distinta), del que además se conserva una copia íntegra. Un guardado válido, en cambio, sí continúa.
## (Hallazgo del mutation testing: sin ValidarGuardado en continuar_guardado el juego se quedaba sin motor y ninguna prueba lo notaba.)

const ARCHIVOS := ["guardado.json", "guardado.cache", "guardado_descartado.json"]
var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _textos(nodo: Node) -> String:
	var t := ""
	if nodo is Label:
		t += (nodo as Label).text + " "
	for h in nodo.get_children():
		t += _textos(h)
	return t


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	for a in ARCHIVOS:
		if FileAccess.file_exists("user://" + a):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a), ProjectSettings.globalize_path("user://" + a + ".bak_ci"))
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var datos: Dictionary = main.datos
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var m := Partida.crear(datos, 11, GeneradorPartido.construir_partido("C", "CCC", "metropolitana", resp, datos["ideologia"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for _t in range(3):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	var base: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(main._huella_datos)))
	# 1) guardado inválido con huella correcta: se descarta con aviso
	var roto: Dictionary = base.duplicate(true)
	var j := 0
	for i in range(roto["entradas"].size()):
		if String(roto["entradas"][i]["tipo"]) == "jugar":
			j = i
			break
	roto["entradas"][j].erase("idx")  # una entrada «jugar» sin su índice
	var f := FileAccess.open("user://guardado.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(roto))
	f.close()
	main.continuar_guardado()
	for _k in range(2):
		await process_frame
	_check(not FileAccess.file_exists("user://guardado.json"), "el guardado inválido debe quitarse para que «Continuar» no vuelva a fallar")
	_check(FileAccess.file_exists("user://guardado_descartado.json"), "se conserva una copia del guardado descartado")
	var menu: Node = main._pantalla
	_check(menu is PantallaMenu and (menu as PantallaMenu).aviso != "" and _textos(menu).contains("dañado"), "el menú debe avisar que el guardado estaba dañado")
	_check(main.motor == null or main.motor.estado.turno_actual >= 1, "no debe quedar un motor a medio construir")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://guardado_descartado.json"))
	# 1b) guardado de una versión anterior de los datos (huella distinta): se descarta con aviso y se CONSERVA una copia, no se borra
	var antiguo: Dictionary = base.duplicate(true)
	antiguo["huella_datos"] = "0".repeat(64)
	var fa := FileAccess.open("user://guardado.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(antiguo))
	fa.close()
	main.continuar_guardado()
	for _k in range(2):
		await process_frame
	_check(not FileAccess.file_exists("user://guardado.json"), "huella antigua: el guardado debe quitarse de su sitio para que «Continuar» no vuelva a fallar")
	_check(FileAccess.file_exists("user://guardado_descartado.json"), "huella antigua: debe conservarse una copia (no borrar la partida del jugador sin rastro)")
	var copia: Variant = Datos.leer_json("user://guardado_descartado.json")
	_check(copia is Dictionary and copia.get("huella_datos") == antiguo["huella_datos"] and (copia.get("entradas", []) as Array).size() == (antiguo["entradas"] as Array).size(), "huella antigua: la copia conservada es el guardado original, íntegro")
	var menu2: Node = main._pantalla
	_check(menu2 is PantallaMenu and (menu2 as PantallaMenu).aviso != "" and _textos(menu2).contains("versión"), "huella antigua: el menú debe avisar que es de otra versión del juego")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://guardado_descartado.json"))
	# 2) el guardado válido sí continúa
	var g := FileAccess.open("user://guardado.json", FileAccess.WRITE)
	g.store_string(JSON.stringify(base))
	g.close()
	main.continuar_guardado()
	for _k in range(2):
		await process_frame
	_check(main._pantalla is PantallaDia and main.motor != null, "un guardado válido debe continuar en la pantalla del día")
	if main.motor != null:
		_check(main.motor.estado.calcular_huella() == m.estado.calcular_huella(), "el guardado válido se reproduce con la misma huella")
	main.queue_free()
	await process_frame
	for a in ARCHIVOS:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + a))
		if FileAccess.file_exists("user://" + a + ".bak_ci"):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a + ".bak_ci"), ProjectSettings.globalize_path("user://" + a))
	print("test_continuar_invalido: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
