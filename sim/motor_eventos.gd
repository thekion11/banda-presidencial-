class_name MotorEventos
extends RefCounted
## Paso 2 del turno: eventos programados y sorteados con la semilla, con votación bicameral opcional.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


func procesar_semana() -> Array[Dictionary]:
	var dia_inicio := m.estado.dia_actual
	var dia_fin := m.estado.dia_actual + m.estado.dias_por_turno - 1
	var ocurridos: Array[Dictionary] = []
	for evt in m.catalogo_eventos:
		if String(evt.get("etapa", "gobierno")) != m.estado.etapa:
			continue
		var ocurre := false
		if evt["tipo"] == "programado":
			var d_obj := int(evt["dia_objetivo"])
			ocurre = d_obj >= dia_inicio and d_obj <= dia_fin
		elif evt["tipo"] == "aleatorio_semilla":
			ocurre = m.rng.randf() < float(evt.get("peso_sorteo", 0.0))
		if ocurre:
			ocurridos.append(aplicar_evento(evt))
	return ocurridos


func aplicar_evento(evt: Dictionary) -> Dictionary:
	var res := {"id": evt["id"], "titulo": evt["titulo"], "descripcion": evt["descripcion"], "hora": evt["hora_etiqueta"], "votacion": null, "efectos": evt["efectos_base"]}
	var aplicar := true
	var v: Variant = evt.get("votacion", null)
	if v != null:
		var voto := m.legal.votar(m.estado, String(v["tipo_ley"]), int(v["votos_firmes_base"]) if v.get("votos_firmes_base", null) != null else -1)
		var tc := m.legal.resolver_tc(String(v["tipo_ley"]), float(v.get("prob_exito_tc", -1.0)))
		aplicar = bool(voto["aprobada"]) and not bool(tc["cae"])
		res["votacion"] = {"voto": voto, "tc": tc, "aprobada": aplicar, "origen": String(v.get("origen", "camara"))}
		if not bool(voto["aprobada"]):
			m.fx.sumar_ind("capital", -float(m.catalogo_leyes["congreso"]["penal_capital_rechazo"]))
		elif bool(tc["cae"]):
			m.fx.sumar_ind("capital", -float(m.catalogo_leyes["tc"]["capital_perdido_si_cae"]))
	if aplicar:
		for ef in evt["efectos_base"]:
			m.fx.aplicar_efecto(ef, 1.0, "")
	m.estado.registrar_accion("evento", {"id": evt["id"], "aplicado": aplicar})
	m.estado.eventos_ocurridos[String(evt["id"])] = m.estado.turno_actual
	m.mazo.incorporar(m.mazo.ids_con_disponibilidad("evento", String(evt["id"])))  # desbloquea cartas ligadas a este evento
	return res
