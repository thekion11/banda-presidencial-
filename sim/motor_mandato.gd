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
	var legado := float(cumplidas) / float(total) if total > 0 else 1.0
	return roundi(m.estado.ind("aprobacion") * float(p["peso_aprobacion"]) + legado * float(p["peso_legado"])
			+ float(m.estado.obras_terminadas.size()) * float(p["peso_obras"])
			+ m.estado.ind("fiscal") * float(p["peso_fiscal"]) + m.estado.ind("capital") * float(p["peso_capital"]))


func finalizar(motivo: String) -> void:
	m.estado.etapa = motivo
	m.estado.resultado_final = {"motivo": motivo, "puntaje": calcular_puntaje(), "turnos": m.estado.turno_actual,
			"aprobacion": snappedf(m.estado.ind("aprobacion"), 0.01), "obras": m.estado.obras_terminadas.size(),
			"promesas_pendientes": m.estado.promesas_pendientes().size()}
	m.estado.registrar_accion("fin", m.estado.resultado_final)



func resolver_eleccion() -> Dictionary:
	## 1ª vuelta: gana quien supera el umbral; si no, pasa a la 2ª vuelta (semanas_balotaje más de campaña) con el piso configurado.
	var h: Dictionary = m.catalogo_leyes["hemiciclo"]
	var umbral := float(h["umbral_victoria_presidencial"])
	var ruido := float(m.catalogo_leyes["campana"]["ruido_eleccion"])
	var voto_final := clampf(m.estado.ind("aprobacion") + m.rng.randf_range(-ruido, ruido), 0.0, 100.0)
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
	return {"electo": electo, "balotaje": balotaje, "ronda": ronda, "voto_final": voto_final, "umbral": umbral}
