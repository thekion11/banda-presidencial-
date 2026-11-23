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
	return v


static func jugar_turno(motor: MotorTurno, politica: String, rng: RandomNumberGenerator) -> void:
	var est := motor.estado
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


static func partida_completa(datos: Dictionary, semilla: int, politica: String) -> MotorTurno:
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
	var motor := Partida.crear(datos, semilla, partido)
	var est := motor.estado
	for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		jugar_turno(motor, pol_camp, rng)
		motor.terminar_turno()
	if bool(motor.resolver_eleccion_presidencial()["electo"]):
		motor.iniciar_turno()
		while est.etapa == "gobierno":
			jugar_turno(motor, pol_gob, rng)
			motor.terminar_turno()
	return motor
