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
	# Quórums (CPR art. 66 y 127, texto en data/bcn/normas.json): presentes vs en ejercicio vs 4/7
	var asist := float(datos["leyes"]["congreso"]["asistencia_presentes"])
	var esperado := {
		"ley_simple": [ceili(50.0 * asist - 0.000001) / 2 + 1, ceili(155.0 * asist - 0.000001) / 2 + 1],
		"quorum_calificado": [26, 78], "ley_organica_constitucional": [26, 78], "reforma_constitucional": [29, 89], "ley_interpretativa": [29, 89], "decreto_supremo": [1, 1]}
	for id in esperado.keys():
		var t := motor.legal.tipo(id)
		_check(int(t["votos_minimos"]) == int(esperado[id][0]) and int(t["votos_minimos_camara"]) == int(esperado[id][1]), "umbral de %s: %d/%d (esperado %s)" % [id, int(t["votos_minimos"]), int(t["votos_minimos_camara"]), esperado[id]])
		_check(String(t["cita_regla"]) != "", "%s cita su artículo" % id)
	_check(int(motor.legal.tipo("ley_simple")["votos_minimos"]) < int(motor.legal.tipo("quorum_calificado")["votos_minimos"]), "ley simple (presentes) exige menos que quórum calificado (en ejercicio)")
	_check(int(motor.legal.tipo("reforma_constitucional")["votos_minimos"]) > int(motor.legal.tipo("quorum_calificado")["votos_minimos"]), "la reforma (4/7) exige más que el quórum calificado")
	_check(datos["cartas"].any(func(c: Dictionary) -> bool: return c["requisitos"]["ley"] == "ley_interpretativa"), "existe una carta que exige la ley interpretativa")
	var alterno: Dictionary = Datos.cargar_todo()["leyes"].duplicate(true)
	alterno["congreso"]["asistencia_presentes"] = 1.0
	var legal2 := MotorLegal.new()
	legal2.configurar(alterno, RandomNumberGenerator.new())
	_check(int(legal2.tipo("ley_simple")["votos_minimos"]) == 26 and int(legal2.tipo("ley_simple")["votos_minimos_camara"]) == 78, "con asistencia total, presentes = en ejercicio (26/78)")
	if _fallos == 0:
		print("CONGRESO OK (%d votaciones bicamerales en el mandato)" % votaciones)
	quit(0 if _fallos == 0 else 1)
