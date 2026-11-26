class_name Encuestas
extends RefCounted
## Encuestas semanales de campaña y oposición (PR-10; análisis de profundidad H7). Solo lee el estado y escribe `estado.encuestas`.
## El error de muestreo sale de un hash de (semilla, semana, etapa), no del azar de la partida: no cambia ninguna otra secuencia aleatoria y
## se rehace igual al reproducir un guardado. Cifras ilustrativas (no son encuestas reales).


static func registrar(m: MotorTurno) -> void:
	## Anota la encuesta de la semana (intención de voto, margen, umbral, rival, regiones débiles) sin usar el azar de la partida.
	var e := m.estado
	var cfg: Dictionary = m.catalogo_leyes["encuestas"]
	var h: Dictionary = m.catalogo_leyes["hemiciclo"]
	var camp: Dictionary = m.catalogo_leyes["campana"]
	var opo: Dictionary = m.catalogo_leyes["oposicion"]
	var semana := m.eventos.semana_abs()
	var sem_camp := int(h["semanas_campana"])
	var avance := clampf(float(e.turno_actual - 1) / float(maxi(1, sem_camp - 1)), 0.0, 1.0) if e.etapa == "campana" else clampf(float(e.turno_actual - 1) / float(maxi(1, int(opo["semanas"]) - 1)), 0.0, 1.0)
	var margen := lerpf(float(cfg["margen_inicial"]), float(cfg["margen_final"]), avance)
	var base := e.ind("aprobacion")
	var umbral: Variant = null
	var rival: Variant = null
	if e.etapa == "campana":
		if e.promesas_campana.size() < int(camp["min_promesas"]):
			base -= float(camp["penal_sin_promesas"])  # sin compromisos serías «intrascendente»: la encuesta ya lo refleja
		if e.ciclo > 1:
			base += float(opo["peso_rival_voto"]) * (float(opo["rival_neutro"]) - e.ind("rival"))
			rival = snappedf(e.ind("rival"), 0.1)
		umbral = snappedf(float(h["umbral_victoria_presidencial"]) + float(m.mandato.nivel()["umbral_delta"]), 0.1)
	else:
		rival = snappedf(e.ind("rival"), 0.1)
	var u := float(Huella.fnv32("%d:%d:%s" % [e.semilla, semana, e.etapa]) % 10001) / 10000.0 * 2.0 - 1.0
	var regs: Array[Dictionary] = []
	for id in e.aprobacion_regional.keys():
		regs.append({"id": String(id), "valor": snappedf(float(e.aprobacion_regional[id]), 0.1)})
	regs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["valor"]) < float(b["valor"]) or (float(a["valor"]) == float(b["valor"]) and String(a["id"]) < String(b["id"])))
	if not e.encuestas.is_empty() and int(e.encuestas.back()["semana"]) == semana and String(e.encuestas.back()["etapa"]) == e.etapa:
		e.encuestas.pop_back()  # una encuesta por semana: la del amanecer de la 2ª vuelta reemplaza a la de «antes de votar» de esa misma semana
	e.encuestas.append({"semana": semana, "turno": e.turno_actual, "etapa": e.etapa, "intencion": snappedf(clampf(base + u * margen, 0.0, 100.0), 0.1),
			"margen": snappedf(margen, 0.1), "umbral": umbral, "rival": rival, "regiones": regs.slice(0, int(cfg["regiones_mostradas"]))})
	while e.encuestas.size() > int(cfg["historial_max"]):
		e.encuestas.pop_front()
