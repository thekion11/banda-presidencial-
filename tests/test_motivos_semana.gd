extends SceneTree
## motivos_semana: hasta 3 cambios con causa, ordenados por |delta|, solo salida (no altera guardado ni huella).

func _init() -> void:
	var fallos := 0
	var datos := Datos.cargar_todo()
	var m := AyudaV2.gobierno(datos, 7, [])
	m.terminar_turno()
	var mot: Array[Dictionary] = m.motivos_semana()
	if mot.is_empty() or mot.size() > 3:
		fallos += 1; print("FALLO tamaño ", mot.size())
	var previo := 1e9
	for f in mot:
		if not (["cohesion", "riesgo_ejecucion", "capital", "fiscal", "aprobacion"].has(f["ind"])) or String(f["causa"]).length() > 60 or String(f["causa"]) == "":
			fallos += 1; print("FALLO fila ", f)
		if absf(f["delta"]) > previo:
			fallos += 1; print("FALLO orden")
		previo = absf(f["delta"])
	# solo salida: la misma partida sin consultar motivos da el mismo guardado
	var m2 := AyudaV2.gobierno(datos, 7, [])
	m2.terminar_turno()
	if m.estado.exportar_json("") != m2.estado.exportar_json(""):
		fallos += 1; print("FALLO guardado distinto")
	print("test_motivos_semana: ", "OK" if fallos == 0 else "FALLOS %d" % fallos, " ", mot)
	quit(1 if fallos > 0 else 0)
