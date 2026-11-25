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
	var lg: Dictionary = m.catalogo_leyes["legado"]
	var toca := false
	for t in lg["turnos_evaluacion"]:
		toca = toca or int(t) == m.estado.turno_actual
	if not toca or m.estado.legado_evaluado.has(m.estado.turno_actual):
		return
	m.estado.legado_evaluado.append(m.estado.turno_actual)
	var pend := m.estado.promesas_pendientes().size()
	if pend > 0:
		m.fx.sumar_ind("capital", -float(lg["penal_capital"]) * pend)
		m.fx.delta_aprobacion(-float(lg["penal_aprobacion"]) * pend, "")
	m.estado.registrar_accion("legado_evaluado", {"pendientes": pend})


func evaluar_crisis() -> void:
	var d: Dictionary = m.catalogo_leyes["dinamica"]
	if m.estado.ind("aprobacion") < float(d["umbral_crisis_aprobacion"]):
		m.estado.semanas_en_crisis += 1
	else:
		m.estado.semanas_en_crisis = 0
	if m.estado.semanas_en_crisis >= int(d["semanas_crisis_para_caida"]):
		finalizar("crisis")


func calcular_puntaje() -> int:
	var p: Dictionary = m.catalogo_leyes["puntaje"]
	var total := m.estado.promesas_campana.size()
	var cumplidas := total - m.estado.promesas_pendientes().size()
	var legado := float(cumplidas) / float(total) if total > 0 else 0.0  # sin promesas no hay legado (U3: intrascendente)
	return roundi(m.estado.ind("aprobacion") * float(p["peso_aprobacion"]) + legado * float(p["peso_legado"])
			+ float(m.estado.obras_terminadas.size()) * float(p["peso_obras"])
			+ m.estado.ind("fiscal") * float(p["peso_fiscal"]) + m.estado.ind("capital") * float(p["peso_capital"]))


func finalizar(motivo: String) -> void:
	m.estado.etapa = motivo
	m.estado.resultado_final = {"motivo": motivo, "puntaje": calcular_puntaje(), "turnos": m.estado.turno_actual,
			"aprobacion": snappedf(m.estado.ind("aprobacion"), 0.01), "obras": m.estado.obras_terminadas.size(),
			"promesas_pendientes": m.estado.promesas_pendientes().size()}
	m.estado.registrar_accion("fin", m.estado.resultado_final)



func hitos(maximo: int = 8) -> Array[Dictionary]:
	## Resumen de sesión: hitos del registro de acciones (solo lectura): [{turno, texto}] en orden cronológico, los más recientes si hay muchos.
	var res: Array[Dictionary] = []
	var primera_ley := false
	for a in m.estado.registro_acciones:
		var d: Dictionary = a["detalle"]
		var texto := ""
		match String(a["tipo"]):
			"eleccion_presidencial":
				texto = "Ganaste la elección con %.1f %% de apoyo." % float(d["voto_final"]) if bool(d["electo"]) else ("Pasaste a segunda vuelta con %.1f %%." % float(d["voto_final"]) if bool(d["balotaje"]) else "Perdiste la elección con %.1f %% de apoyo." % float(d["voto_final"]))
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
	## Texto de la sucesión presidencial (solo mandato completo): depende de la aprobación final; umbrales en data/leyes.json «sucesion».
	if m.estado.etapa != "fin_mandato":
		return ""
	var c: Dictionary = m.catalogo_leyes["sucesion"]
	var ap := m.estado.ind("aprobacion")
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
	var dias := 0 if previa == "derrota_electoral" else (e.turno_actual - 1) * e.dias_por_turno
	_abrir_periodo("campana" if previa == "fin_mandato" and e.cartas_ejecutadas.has("reforma_reeleccion") else "oposicion", dias)
	return {"ok": true, "etapa": e.etapa}


func cerrar_oposicion() -> void:
	## Terminadas las semanas de oposición empieza la campaña siguiente (cierre automático dentro de cerrar_turno).
	_abrir_periodo("campana", e_dias_oposicion())


func e_dias_oposicion() -> int:
	return (m.estado.turno_actual - 1) * m.estado.dias_por_turno


func _abrir_periodo(etapa: String, dias_cerrados: int) -> void:
	var e := m.estado
	e.dias_carrera += dias_cerrados
	e.ciclo += 1
	e.etapa = etapa
	e.turno_actual = 1
	e.dia_actual = 1
	e.resultado_final = {}
	e.ronda_electoral = 1
	e.promesas_campana.clear()
	e.decisiones.clear()
	e.semanas_en_crisis = 0
	e.legado_evaluado.clear()
	e.pa_actual = e.pa_maximo
	e.registrar_accion("periodo_nuevo", {"etapa": etapa, "ciclo": e.ciclo})


func nivel() -> Dictionary:
	## Preset de dificultad de la partida (PR-01): fácil, normal o difícil, según estado.partido["dificultad"]; sin dato usa el defecto.
	var d: Dictionary = m.catalogo_leyes["dificultad"]
	return d["niveles"].get(String(m.estado.partido.get("dificultad", d["defecto"])), d["niveles"][d["defecto"]])


func resolver_eleccion() -> Dictionary:
	## 1ª vuelta: gana quien supera el umbral; si no, pasa a la 2ª vuelta (semanas_balotaje más de campaña) con el piso configurado.
	var h: Dictionary = m.catalogo_leyes["hemiciclo"]
	var umbral := float(h["umbral_victoria_presidencial"]) + float(nivel()["umbral_delta"])
	if not m.estado.eleccion_pendiente(int(h["semanas_campana"])):  # solo se vota cuando la campaña terminó (nada se registra ni cambia)
		return {"ok": false, "electo": false, "balotaje": false, "ronda": m.estado.ronda_electoral, "voto_final": 0.0, "umbral": umbral}
	var ruido := float(m.catalogo_leyes["campana"]["ruido_eleccion"])
	var camp: Dictionary = m.catalogo_leyes["campana"]
	var sin_prom := float(camp["penal_sin_promesas"]) if m.estado.promesas_campana.size() < int(camp["min_promesas"]) else 0.0  # U3: sin compromisos pierdes votos
	var voto_final := clampf(m.estado.ind("aprobacion") + m.rng.randf_range(-ruido, ruido) - sin_prom, 0.0, 100.0)
	var ronda := m.estado.ronda_electoral
	var electo := voto_final >= umbral
	var balotaje := ronda == 1 and not electo and voto_final >= float(h["umbral_pasa_balotaje"])
	m.estado.registrar_accion("eleccion_presidencial", {"voto_final": voto_final, "umbral": umbral, "electo": electo,
			"ronda": ronda, "balotaje": balotaje, "promesas_registradas": m.estado.promesas_campana.size()})
	m.estado.registrar_entrada("eleccion", {})
	if balotaje:
		m.estado.ronda_electoral = 2
	elif electo:
		m.estado.etapa = "gobierno"
		m.estado.turno_actual = 1
		m.estado.dia_actual = 1
		m.estado.pa_actual = m.estado.pa_maximo
	else:
		m.estado.etapa = "derrota_electoral"
		m.estado.resultado_final = {"motivo": "derrota_electoral", "voto_final": voto_final, "puntaje": 0}
	return {"ok": true, "electo": electo, "balotaje": balotaje, "ronda": ronda, "voto_final": voto_final, "umbral": umbral}
