extends SceneTree
## Finales variados: cada motivo tiene epílogo y los distintos estados dan distintos epílogos.

func _init() -> void:
	var datos := Datos.cargar_todo()
	var fallos := 0
	var ids := {}
	for semilla in range(40, 52):
		for pol in ["codicioso>codicioso", "codicioso>pasivo", "azar"]:
			var m := Bots.partida_completa(datos, semilla, pol)
			var e := m.mandato.epilogo()
			if String(e["id"]) == "" and m.estado.etapa in ["fin_mandato", "crisis", "derrota_electoral"]:
				print("FALLO: sin epílogo para ", m.estado.etapa); fallos += 1
			ids[String(e["id"])] = true
			if m.estado.etapa == "fin_mandato" and m.mandato.hitos().is_empty():
				print("FALLO: un mandato completo debe tener hitos"); fallos += 1
	print("epílogos vistos: ", ids.keys())
	if ids.size() < 3:
		print("FALLO: muy poca variedad de finales"); fallos += 1
	print("test_finales: ", "OK" if fallos == 0 else "FALLO")
	quit(1 if fallos > 0 else 0)
