class_name Bots
extends RefCounted
## Políticas automáticas para balancear con Monte Carlo. Usan solo la API pública del motor.

const PESOS := {"aprobacion": 1.0, "capital": 0.5, "cohesion": 0.4, "fiscal": 0.6, "riesgo_ejecucion": -0.5, "viviendas_anio": 0.0002}


static func _valor(carta: Dictionary, estado: EstadoSimulacion) -> float:
	var v := 0.0
	for ef in carta["efectos"]:
		var w: float = PESOS.get(ef["ind"], 0.0)
		if ef["ind"] == "fiscal" and estado.ind("fiscal") < 45.0:
			w *= 2.5
		if ef["ind"] == "capital" and estado.ind("capital") < 30.0:
			w *= 2.0
		v += w * float(ef["delta"])
	v /= float(carta["costo_pa"])
	if carta["requisitos"]["ley"] != null:
		v *= 0.8
	if carta.has("obra"):
		v *= 0.5  # la aprobación de una obra llega tarde (a su inauguración)
	return v


static func _delegar(motor: MotorTurno) -> void:
	## Delega las mejores cartas en el ministro afín del gabinete (sin gastar movimientos; puede salir mal).
	var est := motor.estado
	for _n in range(int(motor.catalogo_leyes["delegacion"]["max_por_turno"])):
		var mejor := -1
		var ministro := ""
		var mejor_v := 0.0
		for i in range(est.mano.size()):
			var c: Dictionary = est.mano[i]
			if motor.es_unica(c) and est.cartas_ejecutadas.has(String(c["id"])) or c.has("obra"):
				continue
			for id in est.gabinete:
				if motor.catalogo_ministros[id]["categoria_afin"] == c["categoria"] and _valor(c, est) > mejor_v:
					mejor_v = _valor(c, est)
					mejor = i
					ministro = String(id)
		if mejor < 0:
			return
		motor.delegar_carta(mejor, ministro)


static func _internos(motor: MotorTurno) -> void:
	## Movimientos internos: bajar errores si el riesgo es alto, cumplir la meta más barata y acelerar la obra más avanzada.
	var est := motor.estado
	if est.ind("riesgo_ejecucion") > 30.0:
		motor.reducir_errores()
	var metas := motor.movimientos.metas_disponibles()
	metas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["costo_mov"]) < int(b["costo_mov"]))
	if not metas.is_empty():
		motor.buscar_meta(String(metas[0]["id"]))
	if not est.obras_en_curso.is_empty():
		motor.acelerar_proyecto(0)
	if est.ind("riesgo_ejecucion") > 30.0:
		motor.reducir_errores()


static func _extras(motor: MotorTurno) -> void:
	## Política "completo": además de jugar cartas como el codicioso usa asesores, coalición, delegación y movimientos internos.
	var est := motor.estado
	if est.turno_actual == 1:
		var ids: Array = motor.equipo.asesores.keys()
		ids.sort()
		for id in ids.slice(0, 3):
			motor.contratar_asesor(String(id))
		var pids: Array = motor.coalicion.partidos.keys()
		pids.sort_custom(func(a: String, b: String) -> bool: return motor.coalicion.afinidad(a) > motor.coalicion.afinidad(b))
		for id in pids.slice(0, 2):
			motor.unirse_coalicion(String(id))
	for _d in range(2):  # delegar las cartas más baratas en el ministro con menor probabilidad de fallo
		if est.mano.is_empty() or est.gabinete.is_empty():
			break
		var mejor_m := ""
		var mejor_p := 2.0
		for mid in est.gabinete:
			var pf := motor.prob_fallo_delegacion(0, String(mid))
			if pf < mejor_p:
				mejor_p = pf
				mejor_m = String(mid)
		if not bool(motor.delegar_carta(0, mejor_m)["ok"]):
			break
	if est.ind("riesgo_ejecucion") > 25.0:
		motor.reducir_errores()
	if not est.obras_en_curso.is_empty():
		motor.acelerar_proyecto(0)
	var metas := motor.movimientos.metas_disponibles()
	if not metas.is_empty():
		motor.buscar_meta(String(metas[0]["id"]))


static func jugar_turno(motor: MotorTurno, politica: String, rng: RandomNumberGenerator) -> void:
	var est := motor.estado
	if politica == "completo":
		politica = "codicioso"
		if est.etapa == "gobierno":
			_extras(motor)
	if est.etapa == "gobierno" and politica != "azar" and politica != "pasivo":
		_internos(motor)
		_delegar(motor)
	var guard := 0
	while guard < 12 and not est.mano.is_empty():
		guard += 1
		var mejor := -1
		var mejor_v := -1.0e9
		for i in range(est.mano.size()):
			if motor.costo_carta(est.mano[i]) > est.pa_actual:
				continue
			var c: Dictionary = est.mano[i]
			if est.etapa == "gobierno" and motor.es_unica(c) and est.cartas_ejecutadas.has(String(c["id"])):
				continue
			if c.has("obra") and est.etapa == "gobierno" and politica != "azar" and est.obras_en_curso.size() >= int(motor.catalogo_leyes["dinamica"]["max_obras_concurrentes"]):
				continue  # el jugador competente no satura la capacidad de ejecución con obras simultáneas
			var v := rng.randf() if politica == "azar" else _valor(c, est)
			if v > mejor_v:
				mejor_v = v
				mejor = i
		if mejor < 0 or politica == "pasivo":
			break
		var region := ""
		if est.etapa == "campana" and not motor.regiones.catalogo.is_empty():
			region = String(motor.regiones.catalogo[rng.randi_range(0, motor.regiones.catalogo.size() - 1)]["id"]) if politica == "azar" else _region_objetivo(motor)
		motor.jugar_carta(mejor, "", region)
	for pid in est.propuestas_abiertas.duplicate():
		if est.etapa == "gobierno" and politica != "azar" and est.obras_en_curso.size() >= int(motor.catalogo_leyes["dinamica"]["max_obras_concurrentes"]):
			break
		var vs := ["A", "B", "C"]
		motor.aprobar_propuesta(pid, vs[rng.randi_range(0, 2)] if politica == "azar" else "C")


static func _region_objetivo(motor: MotorTurno) -> String:
	## Estrategia electoral: reforzar la región más poblada con menor aprobación relativa.
	var mejor := ""
	var mejor_v := -1.0
	for r in motor.regiones.catalogo:
		var v := float(motor.regiones.pesos[r["id"]]) * (100.0 - float(motor.estado.aprobacion_regional[r["id"]]))
		if v > mejor_v:
			mejor_v = v
			mejor = String(r["id"])
	return mejor


static func partida_completa(datos: Dictionary, semilla: int, politica: String, dificultad: String = "") -> MotorTurno:
	## politica = "campaña" o "campaña>gobierno" (p. ej. "codicioso>pasivo").
	var partes := politica.split(">")
	var pol_camp := partes[0]
	var pol_gob := partes[partes.size() - 1]
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla * 31 + 7
	var respuestas: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		respuestas.append(p["opciones"][rng.randi_range(0, 2)])
	var partido := GeneradorPartido.construir_partido("Partido Prueba", "PRU", "metropolitana", respuestas, datos["ideologia"])
	if dificultad != "":
		partido["dificultad"] = dificultad
	var motor := Partida.crear(datos, semilla, partido)
	var est := motor.estado
	for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		jugar_turno(motor, pol_camp, rng)
		motor.terminar_turno()
	if elegir(motor, datos, pol_camp, rng):
		while est.etapa == "gobierno":
			jugar_turno(motor, pol_gob, rng)
			motor.terminar_turno()
	return motor


static func elegir(motor: MotorTurno, datos: Dictionary, politica: String, rng: RandomNumberGenerator) -> bool:
	## Resuelve la elección con su posible segunda vuelta (4 semanas más de campaña). true si llega al gobierno.
	var r := motor.resolver_eleccion_presidencial()
	if bool(r["balotaje"]):
		motor.iniciar_turno()
		for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_balotaje"])):
			jugar_turno(motor, politica, rng)
			motor.terminar_turno()
		r = motor.resolver_eleccion_presidencial()
	if bool(r["electo"]):
		motor.iniciar_turno()
	return bool(r["electo"])
