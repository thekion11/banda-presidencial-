extends SceneTree
## El formato del guardado no puede cambiar sin subir su versión: la firma (claves del archivo y claves/tipos de cada entrada) se compara con la de tests/oro/formato_guardado.json.
## Si cambia a propósito: subir `version` en EstadoSimulacion.exportar_guardado, migrar o descartar los guardados viejos y regenerar con `-- --regenerar`.

const RUTA := "res://tests/oro/formato_guardado.json"


func _firma(g: Dictionary) -> String:
	var tabla := {}
	for k in ValidarGuardado.ENTRADAS.keys():
		var req: Dictionary = ValidarGuardado.ENTRADAS[k]
		var claves := {}
		for c in req.keys():
			claves[c] = int(req[c])
		tabla[k] = claves
	var claves_g: Array = g.keys()
	claves_g.sort()
	return JSON.stringify({"archivo": claves_g, "entradas": tabla}, "", true).sha256_text()


func _init() -> void:
	var datos := Datos.cargar_todo()
	var m := Bots.partida_completa(datos, 21, "codicioso")
	var g: Dictionary = m.estado.exportar_guardado()
	var actual := {"version": int(g["version"]), "firma": _firma(g)}
	if "--regenerar" in OS.get_cmdline_user_args():
		var f := FileAccess.open(RUTA, FileAccess.WRITE)
		f.store_string(JSON.stringify(actual, "  ", true) + "\n")
		print("Formato regenerado: ", actual)
		quit(0)
		return
	var esperado: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	var fallos := 0
	if int(esperado["version"]) != int(actual["version"]):
		print("FALLO: la versión del guardado cambió (%d -> %d) sin regenerar tests/oro/formato_guardado.json" % [int(esperado["version"]), int(actual["version"])])
		fallos += 1
	elif String(esperado["firma"]) != String(actual["firma"]):
		print("FALLO: el formato del guardado cambió sin subir la versión (%d). Sube `version` en exportar_guardado y regenera con -- --regenerar" % int(actual["version"]))
		fallos += 1
	# el guardado real debe pasar su propia validación estructural
	var json: Dictionary = JSON.parse_string(JSON.stringify(g))
	if not ValidarGuardado.guardado_valido(json):
		print("FALLO: un guardado recién exportado no pasa ValidarGuardado")
		fallos += 1
	print("test_formato_guardado: ", "OK (versión %d)" % int(actual["version"]) if fallos == 0 else "%d fallos" % fallos)
	quit(1 if fallos > 0 else 0)
