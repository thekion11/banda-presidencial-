extends SceneTree
## Guardados de versiones anteriores del formato (tests/fixtures/guardado_v2.json y v3, generados con el código de cada versión) y de una versión futura: al «Continuar»
## el juego nunca se cae. Con otra huella de datos se descarta con mensaje claro (copia en guardado_descartado.json y sin el botón fallando de nuevo). Con la huella
## de datos vigente (datos sin cambios pero formato viejo) se carga y reproduce hasta el mismo punto, o se descarta con mensaje: nunca una partida a medias.
## Respalda y restaura los archivos de usuario. Uso: godot --headless --path . -s tests/test_guardados_antiguos.gd

const ARCHIVOS := ["guardado.json", "guardado.cache", "guardado.bak", "guardado_descartado.json"]
var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _borrar() -> void:
	for a in ARCHIVOS:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + a))


func _caso(nombre: String, g: Dictionary, esperar_carga: bool) -> void:
	_borrar()
	var f := FileAccess.open("user://guardado.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(g))
	f.close()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.continuar_guardado()
	await process_frame
	var ok_pantalla: bool = main._pantalla != null and is_instance_valid(main._pantalla)
	_check(ok_pantalla, "%s: tras continuar no hay pantalla válida" % nombre)
	if ok_pantalla:
		var cargo: bool = main.motor != null
		if esperar_carga:
			_check(cargo, "%s: con datos vigentes y formato viejo debía cargar (pantalla %s)" % [nombre, str(main._pantalla.get_script().get_global_name())])
			if cargo:
				var rep := Partida.reproducir(main.datos, g)
				_check(rep != null and rep.estado.calcular_huella() == main.motor.estado.calcular_huella(), "%s: el motor cargado no coincide con la reproducción del guardado" % nombre)
		else:
			_check(not cargo or main.motor == null, "%s: un guardado incompatible no debe dejar un motor cargado" % nombre)
			_check(main._pantalla is PantallaMenu, "%s: un guardado incompatible debe volver al menú (pantalla %s)" % [nombre, str(main._pantalla.get_script().get_global_name())])
			_check(FileAccess.file_exists("user://guardado_descartado.json"), "%s: debe quedar la copia en guardado_descartado.json" % nombre)
			_check(not FileAccess.file_exists("user://guardado.json"), "%s: el guardado incompatible debe retirarse (si no, el botón reaparece fallando)" % nombre)
			var textos: Array[String] = []
			for l in main._pantalla.find_children("*", "Label", true, false):
				textos.append((l as Label).text)
			_check("\n".join(textos).contains("No se pudo continuar"), "%s: debe explicar por qué no se pudo continuar" % nombre)
	main.queue_free()
	await process_frame


func _correr() -> void:
	var respaldo := {}
	for a in ARCHIVOS:
		if FileAccess.file_exists("user://" + a):
			respaldo[a] = FileAccess.get_file_as_bytes("user://" + a)
	var datos := Datos.cargar_todo()
	var huella := Datos.huella_rapida(datos)
	for v in [2, 3]:
		var g: Variant = Datos.leer_json("res://tests/fixtures/guardado_v%d.json" % v)
		_check(g is Dictionary and int(g["version"]) == v, "fixture v%d ilegible" % v)
		if not (g is Dictionary):
			continue
		await _caso("v%d con la huella de datos original" % v, g, false)
		var vig: Dictionary = g.duplicate(true)
		vig["huella_datos"] = huella
		await _caso("v%d con la huella de datos vigente" % v, vig, ValidarGuardado.guardado_valido(vig))
	var base: Dictionary = (Datos.leer_json("res://tests/fixtures/guardado_v3.json") as Dictionary).duplicate(true)
	base["huella_datos"] = huella
	for ver in [ValidarGuardado.VERSION + 1, 99]:  # (versión 0 o negativa hoy se acepta: ValidarGuardado solo rechaza las mayores; nunca se escribe, ver informe)
		var f: Dictionary = base.duplicate(true)
		f["version"] = ver
		await _caso("versión %d (futura)" % ver, f, false)
	var sin: Dictionary = base.duplicate(true)
	sin.erase("version")
	await _caso("sin clave version", sin, ValidarGuardado.guardado_valido(sin))
	_borrar()
	for a in respaldo:
		var fa := FileAccess.open("user://" + a, FileAccess.WRITE)
		fa.store_buffer(respaldo[a])
		fa.close()
	if _fallos == 0:
		print("test_guardados_antiguos: OK")
	quit(1 if _fallos > 0 else 0)
