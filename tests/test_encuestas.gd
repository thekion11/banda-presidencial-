extends SceneTree
## Encuestas semanales de campaña y oposición: una por semana, error de muestreo acotado que baja con el tiempo, sin usar el azar de la partida y reproducibles.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var cfg: Dictionary = datos["leyes"]["encuestas"]
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("E", "EEE", "metropolitana", resp, datos["ideologia"])
	var m := Partida.crear(datos, 41, partido)
	var e := m.estado
	_check(e.encuestas.size() == 1, "la primera semana de campaña ya tiene su encuesta")
	var rng_antes := m.rng.state
	for t in range(7):
		m.terminar_turno()
	_check(e.encuestas.size() == 8, "una encuesta por semana de campaña (%d)" % e.encuestas.size())
	var prev_margen := 99.0
	for q in e.encuestas:
		_check(q["etapa"] == "campana" and float(q["margen"]) <= prev_margen + 0.0001, "el margen no sube con el tiempo")
		prev_margen = float(q["margen"])
		_check(float(q["margen"]) >= float(cfg["margen_final"]) - 0.06 and float(q["margen"]) <= float(cfg["margen_inicial"]) + 0.06, "margen dentro de los límites")
		_check(q["umbral"] != null and (q["regiones"] as Array).size() == int(cfg["regiones_mostradas"]), "trae umbral y las regiones más débiles")
		_check(float(q["regiones"][0]["valor"]) <= float(q["regiones"][1]["valor"]), "regiones ordenadas de menor a mayor")
	_check(is_equal_approx(float(e.encuestas.back()["margen"]), float(cfg["margen_final"])), "la última encuesta de campaña tiene el margen mínimo")
	# FORMA FIJA (la presentación en game/ depende de ella): claves, tipos y rangos
	for q in e.encuestas:
		var claves: Array = q.keys()
		claves.sort()
		_check(claves == ["etapa", "intencion", "margen", "regiones", "rival", "semana", "turno", "umbral"], "claves de la encuesta: %s" % str(claves))
		_check(typeof(q["semana"]) == TYPE_INT and typeof(q["turno"]) == TYPE_INT and typeof(q["etapa"]) == TYPE_STRING, "tipos: semana y turno enteros, etapa texto")
		_check(typeof(q["intencion"]) == TYPE_FLOAT and float(q["intencion"]) >= 0.0 and float(q["intencion"]) <= 100.0, "intención: número entre 0 y 100")
		_check(typeof(q["margen"]) == TYPE_FLOAT and float(q["margen"]) > 0.0 and float(q["margen"]) <= 4.1, "margen: número positivo hasta margen_inicial")
		_check(q["umbral"] == null or (typeof(q["umbral"]) == TYPE_FLOAT and float(q["umbral"]) > 0.0 and float(q["umbral"]) <= 100.0), "umbral: nulo o número entre 0 y 100")
		_check(q["rival"] == null or typeof(q["rival"]) == TYPE_FLOAT, "rival: nulo o número")
		for r in q["regiones"]:
			_check(typeof(r["id"]) == TYPE_STRING and typeof(r["valor"]) == TYPE_FLOAT and float(r["valor"]) >= 0.0 and float(r["valor"]) <= 100.0, "región: id texto y valor entre 0 y 100")
		_check(abs(float(q["intencion"]) - snappedf(float(q["intencion"]), 0.1)) < 0.0001, "intención con un decimal")
	_check(e.encuestas[0]["semana"] < e.encuestas[1]["semana"], "las semanas crecen")
	# no consume el azar de la partida: dos partidas iguales, una leyendo encuestas y otra no, quedan con el mismo estado del generador
	var m2 := Partida.crear(datos, 41, partido)
	for t in range(7):
		m2.terminar_turno()
	_check(m2.rng.state == m.rng.state, "las encuestas no usan el azar de la partida")
	_check(rng_antes != 0, "el generador existe")
	# la intención refleja la aprobación (dentro del margen) y la penalización por no comprometerte
	var q0: Dictionary = e.encuestas[0]
	_check(float(q0["intencion"]) <= 100.0 and float(q0["intencion"]) >= 0.0, "intención entre 0 y 100")
	# historial acotado
	_check(e.encuestas.size() <= int(cfg["historial_max"]), "el historial está acotado")
	# oposición: trae al rival y no trae umbral; una derrota lleva ahí
	var d: MotorTurno
	for semilla in range(41, 90):
		d = Partida.crear(datos, semilla, partido)
		for _i in range(8):
			d.terminar_turno()
		d.resolver_eleccion_presidencial()
		if d.estado.etapa == "derrota_electoral":
			break
	d.continuar_carrera()
	d.iniciar_turno()
	_check(d.estado.etapa == "oposicion" and d.estado.encuestas.size() == 1 and d.estado.encuestas[0]["etapa"] == "oposicion", "al empezar la oposición el historial parte limpio con su primera encuesta")
	var qo: Dictionary = d.estado.encuestas.back()
	_check(qo["etapa"] == "oposicion" and qo["umbral"] == null and qo["rival"] != null, "la encuesta de oposición trae al rival y no trae umbral")
	# reproducir da las mismas encuestas
	var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(Datos.huella(datos))))
	var re := Partida.reproducir(datos, g)
	_check(Huella.texto(re.estado.encuestas) == Huella.texto(m.estado.encuestas), "reproducir el guardado rehace las mismas encuestas")
	print("test_encuestas: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
