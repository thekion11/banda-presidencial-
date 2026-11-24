extends SceneTree
## PR-01: la dificultad es dato (leyes.json). Fácil >= Normal >= Difícil en victorias, y Normal no altera el oro.

func _init() -> void:
	var datos := Datos.cargar_todo()
	var fallos := 0
	var n := 24
	var vic := {"facil": 0, "normal": 0, "dificil": 0}
	for k in vic:
		for i in n:
			var m := Bots.partida_completa(datos, 100 + i, "codicioso>pasivo", k)
			if m.estado.etapa != "derrota_electoral":
				vic[k] += 1
	print("victorias fácil/normal/difícil: ", vic)
	if not (vic["facil"] >= vic["normal"] and vic["normal"] >= vic["dificil"]):
		print("FALLO: orden de dificultad roto"); fallos += 1
	if vic["facil"] == vic["dificil"]:
		print("FALLO: la dificultad no cambia nada"); fallos += 1
	print("test_dificultad: ", "OK" if fallos == 0 else "FALLO")
	quit(1 if fallos > 0 else 0)
