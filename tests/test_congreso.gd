extends SceneTree
## Congreso bicameral: composición de ambas cámaras, votos coherentes y votaciones registradas durante un mandato.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO CONGRESO: ", msg)


func _init() -> void:
	var datos := Datos.cargar_todo()
	_check(int(datos["leyes"]["hemiciclo"]["total_diputados"]) == 155, "la Cámara debe tener 155 diputados")
	_check(int(datos["leyes"]["hemiciclo"]["total_senadores"]) == 50, "el Senado debe tener 50 senadores")
	var motor := Bots.partida_completa(datos, 4242, "codicioso")
	var intento := 0
	while motor.estado.etapa == "derrota_electoral" and intento < 30:  # busca una partida que llegue a gobernar
		intento += 1
		motor = Bots.partida_completa(datos, 4242 + intento, "codicioso")
	var est := motor.estado
	for camara in [true, false]:
		var c := motor.legal.composicion(est, camara)
		_check(int(c["propios"]) + int(c["aliados"]) + int(c["oposicion"]) == int(c["total"]), "los bloques no suman el total (camara=%s)" % camara)
	var votaciones := 0
	for r in est.registro_acciones:
		if r["tipo"] == "votacion":
			votaciones += 1
			var d: Dictionary = r["detalle"]
			_check(d.has("senado") and d.has("camara"), "la votación no registra ambas cámaras")
	_check(votaciones > 0, "ninguna ley llegó a votación en el mandato")
	var v := motor.legal.votar(est, "quorum_calificado")
	_check(int(v["senado"]) + int(v["abst_senado"]) + int(v["contra_senado"]) == 50, "votos del Senado no suman 50")
	_check(int(v["camara"]) + int(v["abst_camara"]) + int(v["contra_camara"]) == 155, "votos de la Cámara no suman 155")
	_check(bool(v["aprobada"]) == (int(v["senado"]) >= int(v["min_senado"]) and int(v["camara"]) >= int(v["min_camara"])), "la aprobación debe exigir ambas cámaras")
	if _fallos == 0:
		print("CONGRESO OK (%d votaciones bicamerales en el mandato)" % votaciones)
	quit(0 if _fallos == 0 else 1)
