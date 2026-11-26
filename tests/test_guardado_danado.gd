extends SceneTree
## Guardado: un archivo dañado se descarta con aviso visible (sin dejar «Continuar» fallando) y guardar() escribe completo y sin sobrantes.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO GUARDADO DAÑADO: ", msg)


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
	await _guardado_danado()
	if _fallos == 0:
		print("GUARDADO DAÑADO OK (descarte con aviso y guardado atómico)")
	quit(0 if _fallos == 0 else 1)


func _guardado_danado() -> void:
	## Un guardado dañado no deja el botón «Continuar» fallando: se descarta con aviso visible y el guardado nuevo se escribe completo.
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var ruta := ProjectSettings.globalize_path("user://guardado.json")
	var respaldo := ProjectSettings.globalize_path("user://guardado_respaldo_prueba.json")
	if FileAccess.file_exists("user://guardado.json"):  # si quien prueba tiene una partida guardada, se respeta
		DirAccess.rename_absolute(ruta, respaldo)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://guardado.bak"))  # sin respaldo (main.RUTA_RESPALDO): se prueba el descarte
	var f := FileAccess.open("user://guardado.json", FileAccess.WRITE)
	f.store_string("{esto no es un guardado")
	f.close()
	main.continuar_guardado()
	for _k in range(2):
		await process_frame
	_check(not FileAccess.file_exists("user://guardado.json"), "el guardado dañado debe quitarse para que «Continuar» no vuelva a fallar")
	_check(FileAccess.file_exists("user://guardado_descartado.json"), "se conserva una copia del guardado descartado")
	var menu: Node = main._pantalla
	_check(menu is PantallaMenu and (menu as PantallaMenu).aviso != "" and _textos(menu).contains("dañado"), "el menú debe avisar que el guardado estaba dañado")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://guardado_descartado.json"))
	# guardado normal: se escribe completo (sin archivo temporal sobrante)
	main.motor = Partida.crear(main.datos, 11, GeneradorPartido.construir_partido("P", "P", "metropolitana", [main.datos["ideologia"]["preguntas"][0]["opciones"][1]], main.datos["ideologia"]))
	main.guardar()
	_check(FileAccess.file_exists("user://guardado.json") and not FileAccess.file_exists("user://guardado.json" + ".tmp"), "guardar() deja el archivo final y ningún .tmp")
	var g: Variant = Datos.leer_json("user://guardado.json")
	_check(g is Dictionary and g.has("entradas") and g.has("semilla"), "el guardado escrito es un JSON completo")
	DirAccess.remove_absolute(ruta)
	if FileAccess.file_exists("user://guardado_respaldo_prueba.json"):
		DirAccess.rename_absolute(respaldo, ruta)
	main.queue_free()
