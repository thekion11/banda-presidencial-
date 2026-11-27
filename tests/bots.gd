class_name Bots
extends RefCounted
## Políticas automáticas para balancear con Monte Carlo. Usan solo la API pública del motor.

static var usar_presupuesto: bool = false  # solo la medición (tests/informe_balas.gd): asigna el mayor extra posible a cada ministerio con proyectos
static var usar_balas: bool = false  # solo la medición de balance (tests/informe_balas.gd): el bot usa las balas de plata «siempre que puede»
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
	if carta.has("riesgo"):  # valor esperado de que salga mal
		for ef in carta["riesgo"]["efectos"]:
			v += float(carta["riesgo"]["prob"]) * float(PESOS.get(ef["ind"], 0.0)) * float(ef["delta"])
	if carta.has("diferido"):  # consecuencia futura, algo descontada
		for ef in carta["diferido"]["efectos"]:
			v += 0.8 * float(PESOS.get(ef["ind"], 0.0)) * float(ef["delta"])
	v /= float(carta["costo_pa"])
	if carta["requisitos"]["ley"] != null:
		v *= 0.8
	if carta.has("obra"):
		v *= 0.5  # la aprobación de una obra llega tarde (a su inauguración)
	return v


static func _valor_opcion(op: Dictionary) -> float:
	## Valor esperado de una opción de evento: efectos + riesgo (por su probabilidad) + efecto a futuro (algo descontado) + relación con el actor.
	var v := 0.0
	for ef in op["efectos"]:
		v += float(PESOS.get(ef["ind"], 0.0)) * float(ef["delta"])
	if op.has("riesgo"):
		for ef in op["riesgo"]["efectos"]:
			v += float(op["riesgo"]["prob"]) * float(PESOS.get(ef["ind"], 0.0)) * float(ef["delta"])
	if op.has("diferido"):
		for ef in op["diferido"]["efectos"]:
			v += 0.8 * float(PESOS.get(ef["ind"], 0.0)) * float(ef["delta"])
	return v + 0.3 * float(op.get("relacion", 0.0))


static func _opcion(ev: Dictionary, politica: String, rng: RandomNumberGenerator) -> int:
	## Cómo decide cada política ante un evento con opciones: azar elige al azar, humano acierta ~70 % de las veces, el resto maximiza el valor esperado.
	var ops: Array = ev["opciones"]
	if politica == "azar" or (politica == "humano" and rng.randf() < 0.3):
		return rng.randi_range(0, ops.size() - 1)
	if politica == "pasivo":
		return 0
	var mejor := 0
	var mejor_v := -1.0e9
	for i in range(ops.size()):
		var v := _valor_opcion(ops[i])
		if v > mejor_v:
			mejor_v = v
			mejor = i
	return mejor


static func _legislar(motor: MotorTurno) -> void:
	var mejor := ""
	var mejor_v := 0.0
	for e in motor.agenda.agenda_catalogo():
		var v := _valor(motor._cartas_por_id[e["carta_id"]], motor.estado)
		if v > mejor_v and int(e["costo_mov"]) <= motor.estado.pa_actual:
			mejor_v = v
			mejor = String(e["carta_id"])
	if mejor != "":
		motor.agenda.presentar(mejor, "suma")


static func _estrat_presupuesto(motor: MotorTurno) -> void:
	## Presupuesto extra: si el fiscal está sano y hay cupo, al ministerio con más proyectos de su sector, con el nivel más barato posible.
	var pan := motor.presupuesto.panel()
	if motor.estado.ind("fiscal") < 55.0 or int(pan["simultaneos"]) >= int(pan["max_simultaneos"]):
		return
	var mejor: Dictionary = {}
	for f in pan["ministerios"]:
		if bool(f["puede_asignar"]) and not bool(f["activo"]) and (mejor.is_empty() or (f["candidatos"] as Array).size() > (mejor["candidatos"] as Array).size()):
			mejor = f
	if not mejor.is_empty() and not (mejor["candidatos"] as Array).is_empty():
		motor.presupuesto.asignar(String(mejor["slot"]), String(mejor["niveles_posibles"][0]))


static func _estrat_balas(motor: MotorTurno) -> void:
	## Balas de plata: usa la primera disponible (versión completa) cuando quedan usos y no hay enfriamiento.
	if motor.balas.usos_restantes() <= 0 or motor.balas.semanas_de_espera() > 0:
		return
	for it in motor.balas.baul()["items"]:
		if bool(it["disponible"]) and not bool(it["usada"]):
			motor.balas.usar(String(it["id"]))
			return


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


static func _cuotas(motor: MotorTurno) -> void:
	## Entrega a cada aliado los ministerios y asesores que pide (lo que haría una persona atenta); se revisa cada turno por si hubo renuncias.
	var est := motor.estado
	for id in est.coalicion.keys():
		var pet: Dictionary = motor.coalicion.partidos[id]["peticion"]
		var c: Dictionary = est.coalicion[id]
		for mid in est.gabinete:
			if c["ministros"].size() >= int(pet["ministerios"]):
				break
			motor.asignar_cuota(String(id), "ministerio", String(mid))
		for aid in est.asesores:
			if c["asesores"].size() >= int(pet["asesores"]):
				break
			motor.asignar_cuota(String(id), "asesor", String(aid))


static func _balas(motor: MotorTurno) -> void:
	## Medición de dominancia: usa toda bala disponible apenas se puede (el peor caso de «usar siempre»).
	for it in motor.balas.baul()["items"]:
		if bool(it["disponible"]):
			motor.balas.usar(String(it["id"]))
			return


static func _presupuesto(motor: MotorTurno) -> void:
	for f in motor.presupuesto.panel()["ministerios"]:
		if not bool(f["activo"]) and not (f["niveles_posibles"] as Array).is_empty():
			motor.presupuesto.asignar(String(f["slot"]), String((f["niveles_posibles"] as Array).back()))


static func _extras(motor: MotorTurno) -> void:
	## Política "completo": además de jugar cartas como el codicioso usa asesores, coalición, delegación y movimientos internos.
	var est := motor.estado
	if usar_balas:
		_balas(motor)
	if usar_presupuesto and est.etapa == "gobierno":
		_presupuesto(motor)
	if est.turno_actual == 1:
		var ids: Array = motor.equipo.asesores.keys()
		ids.sort()
		for id in ids.slice(0, 3):
			motor.contratar_asesor(String(id))
		var pids: Array = motor.coalicion.partidos.keys()
		pids.sort_custom(func(a: String, b: String) -> bool: return motor.coalicion.afinidad(a) > motor.coalicion.afinidad(b))
		for id in pids.slice(0, 2):
			motor.unirse_coalicion(String(id))
	_cuotas(motor)
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
	for ev in motor.ultimos_eventos:  # decisiones de eventos con opciones: el bot elige la primera (azar: una al azar)
		if ev.has("opciones") and not est.decisiones.has(String(ev["id"])):
			motor.eventos.decidir(String(ev["id"]), _opcion(ev, politica, rng))
	var max_jugadas := 12
	if politica == "humano":  # jugador casual: a veces no juega la semana y rara vez usa más de 3 cartas ni las mecánicas avanzadas
		if rng.randf() < 0.2:
			return
		politica = "codicioso"
		max_jugadas = 3
	elif politica == "ahorrador":  # BL: en gobierno juega solo las semanas pares (guarda los movimientos) y gasta todo de golpe
		if est.etapa == "gobierno" and est.turno_actual % 2 == 1:
			return
		politica = "codicioso"
		max_jugadas = 24
	elif politica == "legislador":  # BM: además de jugar sus cartas, presenta la mejor ley del catálogo con urgencia suma cada semana
		politica = "codicioso"
		if est.etapa == "gobierno":
			_legislar(motor)
	elif politica == "estratega":  # BM + balas + presupuesto: usa a la vez la agenda legislativa, las balas de plata y el presupuesto extra a ministerios
		politica = "codicioso"
		if est.etapa == "gobierno":
			_legislar(motor)
			_estrat_presupuesto(motor)
			_estrat_balas(motor)
	elif politica == "estratega_max":  # peor caso: agenda + todas las balas apenas se puede + el mayor extra a todos los ministerios
		politica = "codicioso"
		if est.etapa == "gobierno":
			_legislar(motor)
			_presupuesto(motor)
			_balas(motor)
	elif politica == "completo" or politica == "experto":
		if politica == "experto" and est.etapa == "campana" and est.turno_actual == 1 and est.ciclo == 1:
			motor.elegir_gabinete(Array(motor.gabinete.rellenar([], "eficaz").map(func(n: Dictionary) -> String: return String(n["id"]))))  # gabinete de máxima eficacia
		politica = "codicioso"
		if est.etapa == "gobierno":
			_extras(motor)
	if est.etapa == "gobierno" and politica != "azar" and politica != "pasivo":
		_internos(motor)
		_delegar(motor)
	var guard := 0
	while guard < max_jugadas and not est.mano.is_empty():
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
		if est.etapa == "gobierno" and politica != "azar" and mejor_v <= 0.0:
			break  # un jugador competente no juega cartas que le hacen daño: guarda los movimientos
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
