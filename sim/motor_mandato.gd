class_name MotorMandato
extends RefCounted
## Fin de mandato: legado (promesas de campaña), crisis y puntaje. Delegado de MotorTurno.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> mandato
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)

func evaluar_legado() -> void:
	## En los turnos de evaluación del legado, penaliza capital y aprobación por cada promesa de campaña pendiente.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var lg: Dictionary = _m.catalogo_leyes["legado"]
	var toca := false
	for t in lg["turnos_evaluacion"]:
		toca = toca or int(t) == _m.estado.turno_actual
	if not toca or _m.estado.legado_evaluado.has(_m.estado.turno_actual):
		return
	_m.estado.legado_evaluado.append(_m.estado.turno_actual)
	var pend := _m.estado.promesas_pendientes().size()
	if pend > 0:
		_m.fx.sumar_ind("capital", -float(lg["penal_capital"]) * pend, "metas de legado sin cumplir")
		_m.fx.delta_aprobacion(-float(lg["penal_aprobacion"]) * pend, "")
	_m.estado.registrar_accion("legado_evaluado", {"pendientes": pend})


func evaluar_crisis() -> void:
	## Cuenta las semanas con aprobación bajo el umbral y termina el gobierno por crisis al completar la racha.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var d: Dictionary = _m.catalogo_leyes["dinamica"]
	if _m.estado.ind("aprobacion") < float(d["umbral_crisis_aprobacion"]):
		_m.estado.semanas_en_crisis += 1
	else:
		_m.estado.semanas_en_crisis = 0
	if _m.estado.semanas_en_crisis >= int(d["semanas_crisis_para_caida"]):
		finalizar("crisis")


func calcular_puntaje() -> int:
	## Puntaje del mandato: aprobación, legado, obras, fiscal y capital con los pesos de leyes.json.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var p: Dictionary = _m.catalogo_leyes["puntaje"]
	var total := _m.estado.promesas_campana.size()
	var cumplidas := total - _m.estado.promesas_pendientes().size()
	var legado := float(cumplidas) / float(total) if total > 0 else 0.0  # sin promesas no hay legado (U3: intrascendente)
	return roundi(_m.estado.ind("aprobacion") * float(p["peso_aprobacion"]) + legado * float(p["peso_legado"])
			+ float(_m.estado.obras_terminadas.size()) * float(p["peso_obras"])
			+ _m.estado.ind("fiscal") * float(p["peso_fiscal"]) + _m.estado.ind("capital") * float(p["peso_capital"]))


func finalizar(motivo: String) -> void:
	## Cierra el periodo con un motivo (fin de mandato o crisis), fija el resultado y el puntaje.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	_m.estado.etapa = motivo
	_m.estado.resultado_final = {"motivo": motivo, "puntaje": calcular_puntaje(), "turnos": _m.estado.turno_actual,
			"aprobacion": snappedf(_m.estado.ind("aprobacion"), 0.01), "obras": _m.estado.obras_terminadas.size(),
			"promesas_pendientes": _m.estado.promesas_pendientes().size()}
	_m.estado.registrar_accion("fin", _m.estado.resultado_final)



func hitos(maximo: int = 8) -> Array[Dictionary]:
	## Resumen de sesión: hitos del registro de acciones (solo lectura): [{turno, texto}] en orden cronológico, los más recientes si hay muchos.
	var res: Array[Dictionary] = []
	var primera_ley := false
	for a in m.estado.registro_acciones:
		var d: Dictionary = a["detalle"]
		var texto := ""
		match String(a["tipo"]):
			"eleccion_presidencial":
				texto = "Ganaste la elección con %s %% de apoyo." % _dec(d["voto_final"]) if bool(d["electo"]) else ("Pasaste a segunda vuelta con %s %%." % _dec(d["voto_final"]) if bool(d["balotaje"]) else "Perdiste la elección con %s %% de apoyo." % _dec(d["voto_final"]))
			"votacion":
				if bool(d["aprobada"]) and not primera_ley:
					primera_ley = true
					texto = "Primera ley aprobada en el Congreso."
			"obra_terminada":
				texto = "Se inauguró: %s." % String(d["nombre"])
			"coalicion_ruptura":
				texto = "Un partido aliado rompió con tu gobierno."
			"escandalo_ministro":
				texto = "Escándalo ministerial."
			"meta":
				texto = "Cumpliste una meta interna."
		if texto != "":
			res.append({"turno": int(a["turno"]), "texto": texto})
	return res.slice(maxi(0, res.size() - maximo)) if res.size() > maximo else res


func sucesion() -> String:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Texto de la sucesión presidencial (solo mandato completo): depende de la aprobación final; umbrales en data/leyes.json «sucesion».
	if _m.estado.etapa != "fin_mandato":
		return ""
	var c: Dictionary = _m.catalogo_leyes["sucesion"]
	var ap := _m.estado.ind("aprobacion")
	return String(c["textos"]["gana" if ap >= float(c["umbral_gana"]) else ("renida" if ap >= float(c["umbral_renida"]) else "pierde")])


func epilogo() -> Dictionary:
	## Final variado (solo texto, no toca el estado): primer epílogo de data/leyes.json «finales» cuyas condiciones se cumplen.
	var e := m.estado
	var total := e.promesas_campana.size()
	var legado := float(total - e.promesas_pendientes().size()) / float(total) if total > 0 else 0.0
	for f in m.catalogo_leyes["finales"]["lista"]:
		if String(f["motivo"]) != e.etapa:
			continue
		if f.has("carta_ejecutada") and not e.cartas_ejecutadas.has(String(f["carta_ejecutada"])):
			continue
		if f.has("promesas_max") and total > int(f["promesas_max"]):
			continue
		if f.has("aprobacion_min") and e.ind("aprobacion") < float(f["aprobacion_min"]):
			continue
		if f.has("aprobacion_max") and e.ind("aprobacion") > float(f["aprobacion_max"]):
			continue
		if f.has("obras_min") and e.obras_terminadas.size() < int(f["obras_min"]):
			continue
		if f.has("legado_min") and legado < float(f["legado_min"]):
			continue
		if f.has("fiscal_min") and e.ind("fiscal") < float(f["fiscal_min"]):
			continue
		if f.has("fiscal_max") and e.ind("fiscal") > float(f["fiscal_max"]):
			continue
		return f
	return {"id": "", "titulo": "Fin de partida", "texto": ""}


func continuar_carrera() -> Dictionary:
	## Tras un fin de periodo (mandato completo, caída del gobierno o derrota electoral) la carrera sigue: oposición, o campaña de reelección
	## si la Constitución se reformó durante el gobierno. Se registra para el replay; el llamador inicia el turno (iniciar_turno).
	var e := m.estado
	if not (e.etapa in ["fin_mandato", "crisis", "derrota_electoral"]):
		return {"ok": false, "razon": "periodo_en_curso"}
	var previa := e.etapa
	e.registrar_entrada("continuar", {})
	e.carrera.append({"ciclo": e.ciclo, "resultado": previa, "puntaje": int(e.resultado_final.get("puntaje", 0)),
			"aprobacion": snappedf(e.ind("aprobacion"), 0.01), "turnos": e.turno_actual})
	var turnos_jugados := e.turno_actual if previa == "crisis" else e.turno_actual - 1  # al caer por crisis el turno no avanzó: esa semana también se jugó
	var dias := 0 if previa == "derrota_electoral" else turnos_jugados * e.dias_por_turno
	_abrir_periodo("campana" if previa == "fin_mandato" and e.cartas_ejecutadas.has("reforma_reeleccion") else "oposicion", dias)
	return {"ok": true, "etapa": e.etapa}


func amanecer_oposicion() -> void:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Cada semana de oposición: el gobierno rival se mueve (camino aleatorio hacia su media) y tu aprobación converge a un ancla que sube si el rival lo hace mal.
	var o: Dictionary = _m.catalogo_leyes["oposicion"]
	var rival := _m.estado.ind("rival")
	_m.fx.sumar_ind("rival", (float(o["rival_media"]) - rival) * float(o["rival_reversion"]) + _m.rng.randf_range(-float(o["rival_ruido"]), float(o["rival_ruido"])))
	var ancla := float(o["ancla_base"]) + float(o["peso_rival"]) * (50.0 - _m.estado.ind("rival"))
	_m.fx.sumar_ind("aprobacion", (ancla - _m.estado.ind("aprobacion")) * float(o["reversion_aprobacion"]))


func cerrar_oposicion() -> void:
	## Terminadas las semanas de oposición empieza la campaña siguiente (cierre automático dentro de cerrar_turno).
	_abrir_periodo("campana", e_dias_oposicion())


func e_dias_oposicion() -> int:
	## Días jugados en el periodo actual (turnos jugados por días por turno).
	return (m.estado.turno_actual - 1) * m.estado.dias_por_turno


func _abrir_periodo(etapa: String, dias_cerrados: int) -> void:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var e := _m.estado
	e.dias_carrera += dias_cerrados
	e.ciclo += 1
	e.etapa = etapa
	e.turno_actual = 1
	e.dia_actual = 1
	e.resultado_final = {}
	e.encuestas.clear()  # cada periodo parte con su propio historial de encuestas
	e.ronda_electoral = 1
	e.promesas_campana.clear()
	e.decisiones.clear()
	e.semanas_en_crisis = 0
	e.legado_evaluado.clear()
	if etapa == "campana":  # el ahorro de movimientos se conserva al cambiar de periodo (BL)  # nueva campaña: la aprobación vuelve a la base del partido, con parte de lo ganado antes
		var base := float(e.partido["indicadores_iniciales"]["aprobacion"]) + float(nivel()["aprobacion_inicial"])
		e.indicadores["aprobacion"] = clampf(base + float(_m.catalogo_leyes["oposicion"]["herencia_campana"]) * (e.ind("aprobacion") - base), 0.0, 100.0)
		for k in ["capital", "cohesion", "fiscal", "riesgo_ejecucion"]:  # el resto de los indicadores también vuelve a su punto de partida
			e.indicadores[k] = float(e.partido["indicadores_iniciales"][k])
		var camp: Dictionary = _m.catalogo_leyes["campana"]
		_m.regiones.inicializar(e, e.ind("aprobacion"), String(e.partido.get("region_bastion", "")), float(camp.get("bono_bastion", 0.0)), float(camp.get("variacion_regional_inicial", 0.0)))
	if etapa == "oposicion":
		e.indicadores["rival"] = float(_m.catalogo_leyes["oposicion"]["rival_inicial"])  # el nuevo gobierno parte con luna de miel
	e.registrar_accion("periodo_nuevo", {"etapa": etapa, "ciclo": e.ciclo})


func nivel() -> Dictionary:
	## Preset de dificultad de la partida (PR-01): fácil, normal o difícil, según estado.partido["dificultad"]; sin dato usa el defecto.
	var d: Dictionary = m.catalogo_leyes["dificultad"]
	return d["niveles"].get(String(m.estado.partido.get("dificultad", d["defecto"])), d["niveles"][d["defecto"]])


func resolver_eleccion() -> Dictionary:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## 1ª vuelta: gana quien supera el umbral; si no, pasa a la 2ª vuelta (semanas_balotaje más de campaña) con el piso configurado.
	var h: Dictionary = _m.catalogo_leyes["hemiciclo"]
	var umbral := float(h["umbral_victoria_presidencial"]) + float(nivel()["umbral_delta"])
	if not _m.estado.eleccion_pendiente(int(h["semanas_campana"])):  # solo se vota cuando la campaña terminó (nada se registra ni cambia)
		return {"ok": false, "electo": false, "balotaje": false, "ronda": _m.estado.ronda_electoral, "voto_final": 0.0, "umbral": umbral}
	var ruido := float(_m.catalogo_leyes["campana"]["ruido_eleccion"])
	var camp: Dictionary = _m.catalogo_leyes["campana"]
	var sin_prom := float(camp["penal_sin_promesas"]) if _m.estado.promesas_campana.size() < int(camp["min_promesas"]) else 0.0  # U3: sin compromisos pierdes votos
	var opo: Dictionary = _m.catalogo_leyes["oposicion"]
	var efecto_rival := float(opo["peso_rival_voto"]) * (float(opo["rival_neutro"]) - _m.estado.ind("rival")) if _m.estado.ciclo > 1 else 0.0  # un rival débil te ayuda
	var lim: Dictionary = _m.catalogo_leyes["limites_indicadores"]
	var desplaza := _m.rng.randf_range(-ruido, ruido) - sin_prom + efecto_rival  # choque nacional (una sola tirada) − penalización + rival: igual en todas las regiones
	var pisos: Dictionary = _m.piso.pisos()  # voto duro (D-BN): ninguna región vota por debajo de su piso ideológico
	var voto_final := clampf(maxf(_m.estado.ind("aprobacion") + desplaza, _m.piso.nacional()), float(lim["min"]), float(lim["max"]))
	var detalle := {}
	if not _m.regiones.pesos.is_empty():  # desglose por región (peso = población); el voto nacional decide igual que antes: aprobación nacional + desplazamiento (= Σ peso · voto salvo topes por región)
		var ajuste_nacional := _m.estado.ind("aprobacion") - _m.regiones.promedio(_m.estado)  # lo que la aprobación nacional se aparte del promedio regional (en juego normal es 0) se reparte por igual
		detalle = VotoRegional.calcular(_m.regiones, _m.estado.aprobacion_regional, desplaza + ajuste_nacional, float(lim["min"]), float(lim["max"]), umbral, pisos)
	var ronda := _m.estado.ronda_electoral
	var electo := voto_final >= umbral
	detalle["voto_final"] = voto_final
	detalle["voto_duro_nacional"] = minf(_m.piso.nacional(), voto_final)  # núcleo duro: el piso nacional; el resto del voto es blando
	detalle["voto_blando_nacional"] = voto_final - float(detalle["voto_duro_nacional"])
	detalle["umbral"] = umbral
	detalle["ronda"] = ronda
	_m.estado.ultima_eleccion = detalle  # solo salida para la pantalla de la elección
	var balotaje := ronda == 1 and not electo and voto_final >= float(h["umbral_pasa_balotaje"])
	_m.estado.registrar_accion("eleccion_presidencial", {"voto_final": voto_final, "umbral": umbral, "electo": electo,
			"ronda": ronda, "balotaje": balotaje, "promesas_registradas": _m.estado.promesas_campana.size()})
	_m.estado.registrar_entrada("eleccion", {})
	if balotaje:
		_m.estado.ronda_electoral = 2
	elif electo:
		if _m.estado.ciclo > 1:  # reloj único: las semanas de campaña ya jugadas cuentan antes de que parta el gobierno
			_m.estado.dias_carrera += e_dias_oposicion()
		_m.estado.etapa = "gobierno"
		_m.estado.turno_actual = 1
		_m.estado.dia_actual = 1
	else:
		_m.estado.etapa = "derrota_electoral"
		_m.estado.resultado_final = {"motivo": "derrota_electoral", "voto_final": voto_final, "puntaje": 0}
	return {"ok": true, "electo": electo, "balotaje": balotaje, "ronda": ronda, "voto_final": voto_final, "umbral": umbral, "regiones": detalle.get("regiones", []), "regiones_ganadas": int(detalle.get("regiones_ganadas", 0)), "total_habitantes_miles": float(detalle.get("total_habitantes_miles", 0.0)), "votos_estimados_miles": float(detalle.get("votos_estimados_miles", 0.0))}


func _dec(v) -> String:
	## Un decimal con coma (formato chileno) para los textos que ve el jugador.
	return ("%.1f" % float(v)).replace(".", ",")
