class_name AyudaInvariantes
extends RefCounted
## Invariantes del EstadoSimulacion (mano, mazo y descarte con ids reales; gabinete, asesores y coalición acotados y sin repetidos; obras, propuestas, calendario,
## decisiones, etapa y resultado final coherentes). Es la lógica de tests/test_invariantes_estado.gd como ayudante estático para que la usen también los fuzz
## de acciones aleatorias e inválidas: `AyudaInvariantes.revisar(motor, contexto)` devuelve los mensajes de lo que falla.

const ETAPAS := ["campana", "gobierno", "oposicion", "crisis", "fin_mandato", "derrota_electoral"]
const FINALES := ["crisis", "fin_mandato", "derrota_electoral"]


static func _chk(fallos: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		fallos.append(msg)


static func _unicos(a: Array) -> bool:
	var vistos := {}
	for x in a:
		var k := str(x)
		if vistos.has(k):
			return false
		vistos[k] = true
	return true


static func revisar(m: MotorTurno, ctx: String) -> Array[String]:
	## Devuelve los mensajes de los invariantes que NO se cumplen (vacío si el estado es coherente).
	var fallos: Array[String] = []
	var e := m.estado
	var L: Dictionary = m.catalogo_leyes
	var ids: Dictionary = m._cartas_por_id
	_chk(fallos, ETAPAS.has(e.etapa), "%s: etapa desconocida %s" % [ctx, e.etapa])
	_chk(fallos, e.turno_actual >= 1 and e.ciclo >= 1 and e.dia_actual >= 1, "%s: calendario no positivo" % ctx)
	_chk(fallos, e.ronda_electoral == 1 or e.ronda_electoral == 2, "%s: ronda electoral %d" % [ctx, e.ronda_electoral])
	if e.etapa == "gobierno":
		_chk(fallos, e.dia_actual == 1 + (e.turno_actual - 1) * e.dias_por_turno, "%s: día %d no coincide con el turno %d" % [ctx, e.dia_actual, e.turno_actual])
	_chk(fallos, FINALES.has(e.etapa) == not e.resultado_final.is_empty(), "%s: resultado final y etapa incoherentes (%s)" % [ctx, e.etapa])
	var bono := int(e.bono_mov.get("aprobacion", 0)) + int(e.bono_mov.get("asesores", 0))
	var tope := maxi(int(m.catalogo_leyes["mano"]["tope_ahorro"]), e.pa_maximo + bono)  # ahorro (BL): lo que sobra pasa a la semana siguiente con tope
	_chk(fallos, e.pa_actual >= 0 and e.pa_actual <= tope, "%s: movimientos %d fuera de 0..%d (ingreso %d + bono %d, tope de ahorro)" % [ctx, e.pa_actual, tope, e.pa_maximo, bono])
	for c in e.mano:
		_chk(fallos, ids.has(String(c["id"])), "%s: carta de la mano fuera del catálogo" % ctx)
	_chk(fallos, _unicos(e.mano.map(func(c: Dictionary) -> String: return String(c["id"]))), "%s: carta repetida en la mano" % ctx)
	for lista in [e.mazo, e.descarte]:
		for id in lista:
			_chk(fallos, ids.has(String(id)), "%s: id %s de mazo o descarte fuera del catálogo" % [ctx, id])
	_chk(fallos, _unicos(e.mazo), "%s: carta repetida en el mazo" % ctx)
	var gab_n := int(L["gabinete"]["tamano"])
	_chk(fallos, e.gabinete.is_empty() or e.gabinete.size() == gab_n, "%s: gabinete de %d cargos" % [ctx, e.gabinete.size()])
	_chk(fallos, _unicos(e.gabinete) and _unicos(e.gabinete.map(func(i: String) -> String: return m.gabinete.slot_de(i))), "%s: gabinete con repetidos o dos del mismo ministerio" % ctx)
	for id in e.gabinete:
		_chk(fallos, m.catalogo_ministros.has(id), "%s: ministro %s inexistente" % [ctx, id])
	_chk(fallos, e.asesores.size() <= int(L["asesores"]["max"]) and _unicos(e.asesores), "%s: asesores %d" % [ctx, e.asesores.size()])
	_chk(fallos, e.coalicion.size() <= int(L["coalicion"]["max_aliados"]), "%s: coalición de %d aliados" % [ctx, e.coalicion.size()])
	for id in e.coalicion.keys():
		var s := float(e.coalicion[id]["satisfaccion"])
		_chk(fallos, s >= -0.001 and s <= 100.001, "%s: satisfacción %s" % [ctx, s])
	_chk(fallos, int(e.apoyo_coalicion["senado"]) >= 0 and int(e.apoyo_coalicion["camara"]) >= 0, "%s: apoyo de coalición negativo" % ctx)
	for o in e.obras_en_curso:
		_chk(fallos, int(o["dias_avanzados"]) >= 0 and int(o["dias_avanzados"]) <= int(o["dias_totales"]), "%s: obra con días %d de %d" % [ctx, int(o["dias_avanzados"]), int(o["dias_totales"])])
		_chk(fallos, int(o["fase"]) >= 1 and int(o["fase"]) <= 5, "%s: fase de obra %d" % [ctx, int(o["fase"])])
	_chk(fallos, _unicos(e.obras_terminadas.map(func(o: Dictionary) -> String: return String(o["id"]))), "%s: obra terminada repetida" % ctx)
	for p in e.proyectos_ley:
		_chk(fallos, ids.has(String(p["carta_id"])) and int(p["dia_votacion"]) >= 0, "%s: proyecto de ley mal formado" % ctx)
	for p in e.propuestas_abiertas:
		_chk(fallos, not e.propuestas_aprobadas.has(p), "%s: propuesta %s abierta y aprobada a la vez" % [ctx, p])
	_chk(fallos, _unicos(e.propuestas_abiertas) and _unicos(e.propuestas_aprobadas), "%s: propuestas repetidas" % ctx)
	_chk(fallos, e.semanas_en_crisis >= 0 and (e.etapa == "crisis" or e.semanas_en_crisis < int(L["dinamica"]["semanas_crisis_para_caida"])), "%s: semanas en crisis %d" % [ctx, e.semanas_en_crisis])
	_chk(fallos, e.encuestas.size() <= int(L["encuestas"]["historial_max"]), "%s: historial de encuestas de %d" % [ctx, e.encuestas.size()])
	for q in e.encuestas:
		_chk(fallos, float(q["intencion"]) >= 0.0 and float(q["intencion"]) <= 100.0, "%s: intención %s" % [ctx, q["intencion"]])
	for id in e.cartas_ejecutadas.keys():
		_chk(fallos, ids.has(String(id)), "%s: carta ejecutada %s fuera del catálogo" % [ctx, id])
	_chk(fallos, _unicos(e.legado_evaluado), "%s: legado evaluado repetido" % ctx)
	for k in e.decisiones.keys():
		_chk(fallos, int(e.decisiones[k]) >= 0, "%s: decisión negativa" % ctx)
	_chk(fallos, e.delegadas_turno <= int(L["delegacion"]["max_por_turno"]), "%s: %d delegaciones en el turno" % [ctx, e.delegadas_turno])
	return fallos
