extends SceneTree
## Invariantes del EstadoSimulacion que ningún otro test revisaba (fuzz_acciones solo mira indicadores 0..100, movimientos, contadores, regiones y mano ≤ 5):
## mano, mazo y descarte con ids reales; gabinete y asesores sin repetidos ni más de lo permitido; coalición acotada; obras coherentes; propuestas abiertas y aprobadas disjuntas;
## calendario consistente; decisiones dentro de sus opciones; etapa y resultado final coherentes. Se revisan después de cada acción de partidas con bots.

var _fallos := 0
const ETAPAS := ["campana", "gobierno", "oposicion", "crisis", "fin_mandato", "derrota_electoral"]
const FINALES := ["crisis", "fin_mandato", "derrota_electoral"]


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO: ", msg)


func _unicos(a: Array) -> bool:
	var vistos := {}
	for x in a:
		var k := str(x)
		if vistos.has(k):
			return false
		vistos[k] = true
	return true


func revisar(m: MotorTurno, ctx: String) -> void:
	var e := m.estado
	var L: Dictionary = m.catalogo_leyes
	var ids: Dictionary = m._cartas_por_id
	_check(ETAPAS.has(e.etapa), "%s: etapa desconocida %s" % [ctx, e.etapa])
	_check(e.turno_actual >= 1 and e.ciclo >= 1 and e.dia_actual >= 1, "%s: calendario no positivo" % ctx)
	_check(e.ronda_electoral == 1 or e.ronda_electoral == 2, "%s: ronda electoral %d" % [ctx, e.ronda_electoral])
	if e.etapa == "gobierno":
		_check(e.dia_actual == 1 + (e.turno_actual - 1) * e.dias_por_turno, "%s: día %d no coincide con el turno %d" % [ctx, e.dia_actual, e.turno_actual])
	_check(FINALES.has(e.etapa) == not e.resultado_final.is_empty(), "%s: resultado final y etapa incoherentes (%s)" % [ctx, e.etapa])
	var bono := int(e.bono_mov.get("aprobacion", 0)) + int(e.bono_mov.get("asesores", 0))
	_check(e.pa_actual <= e.pa_maximo + bono, "%s: movimientos %d sobre el máximo %d + bono %d" % [ctx, e.pa_actual, e.pa_maximo, bono])
	for c in e.mano:
		_check(ids.has(String(c["id"])), "%s: carta de la mano fuera del catálogo" % ctx)
	_check(_unicos(e.mano.map(func(c: Dictionary) -> String: return String(c["id"]))), "%s: carta repetida en la mano" % ctx)
	for lista in [e.mazo, e.descarte]:
		for id in lista:
			_check(ids.has(String(id)), "%s: id %s de mazo o descarte fuera del catálogo" % [ctx, id])
	_check(_unicos(e.mazo), "%s: carta repetida en el mazo" % ctx)
	var gab_n := int(L["gabinete"]["tamano"])
	_check(e.gabinete.is_empty() or e.gabinete.size() == gab_n, "%s: gabinete de %d cargos" % [ctx, e.gabinete.size()])
	_check(_unicos(e.gabinete) and _unicos(e.gabinete.map(func(i: String) -> String: return m.gabinete.slot_de(i))), "%s: gabinete con repetidos o dos del mismo ministerio" % ctx)
	for id in e.gabinete:
		_check(m.catalogo_ministros.has(id), "%s: ministro %s inexistente" % [ctx, id])
	_check(e.asesores.size() <= int(L["asesores"]["max"]) and _unicos(e.asesores), "%s: asesores %d" % [ctx, e.asesores.size()])
	_check(e.coalicion.size() <= int(L["coalicion"]["max_aliados"]), "%s: coalición de %d aliados" % [ctx, e.coalicion.size()])
	for id in e.coalicion.keys():
		var s := float(e.coalicion[id]["satisfaccion"])
		_check(s >= -0.001 and s <= 100.001, "%s: satisfacción %s" % [ctx, s])
	_check(int(e.apoyo_coalicion["senado"]) >= 0 and int(e.apoyo_coalicion["camara"]) >= 0, "%s: apoyo de coalición negativo" % ctx)
	for o in e.obras_en_curso:
		_check(int(o["dias_avanzados"]) >= 0 and int(o["dias_avanzados"]) <= int(o["dias_totales"]), "%s: obra con días %d de %d" % [ctx, int(o["dias_avanzados"]), int(o["dias_totales"])])
		_check(int(o["fase"]) >= 1 and int(o["fase"]) <= 5, "%s: fase de obra %d" % [ctx, int(o["fase"])])
	_check(_unicos(e.obras_terminadas.map(func(o: Dictionary) -> String: return String(o["id"]))), "%s: obra terminada repetida" % ctx)
	for p in e.proyectos_ley:
		_check(ids.has(String(p["carta_id"])) and int(p["dia_votacion"]) >= 0, "%s: proyecto de ley mal formado" % ctx)
	for p in e.propuestas_abiertas:
		_check(not e.propuestas_aprobadas.has(p), "%s: propuesta %s abierta y aprobada a la vez" % [ctx, p])
	_check(_unicos(e.propuestas_abiertas) and _unicos(e.propuestas_aprobadas), "%s: propuestas repetidas" % ctx)
	_check(e.semanas_en_crisis >= 0 and (e.etapa == "crisis" or e.semanas_en_crisis < int(L["dinamica"]["semanas_crisis_para_caida"])), "%s: semanas en crisis %d" % [ctx, e.semanas_en_crisis])
	_check(e.encuestas.size() <= int(L["encuestas"]["historial_max"]), "%s: historial de encuestas de %d" % [ctx, e.encuestas.size()])
	for q in e.encuestas:
		_check(float(q["intencion"]) >= 0.0 and float(q["intencion"]) <= 100.0, "%s: intención %s" % [ctx, q["intencion"]])
	for id in e.cartas_ejecutadas.keys():
		_check(ids.has(String(id)), "%s: carta ejecutada %s fuera del catálogo" % [ctx, id])
	_check(_unicos(e.legado_evaluado), "%s: legado evaluado repetido" % ctx)
	for k in e.decisiones.keys():
		_check(int(e.decisiones[k]) >= 0, "%s: decisión negativa" % ctx)
	_check(e.delegadas_turno <= int(L["delegacion"]["max_por_turno"]), "%s: %d delegaciones en el turno" % [ctx, e.delegadas_turno])


func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Invariantes", "INV", "metropolitana", resp, datos["ideologia"])
	var revisiones := 0
	for pol in ["humano", "completo", "azar", "codicioso"]:
		for semilla in range(3):
			var m := Partida.crear(datos, 9100 + semilla, partido)
			var rng := RandomNumberGenerator.new()
			rng.seed = 9100 + semilla
			var guard := 0
			while guard < 700:
				guard += 1
				revisar(m, "%s/%d t%d %s" % [pol, semilla, m.estado.turno_actual, m.estado.etapa])
				revisiones += 1
				if m.estado.etapa == "campana" and m.estado.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
					if not Bots.elegir(m, datos, pol, rng):
						revisar(m, "%s/%d tras la elección" % [pol, semilla])
						if m.continuar_carrera().get("ok", false):
							m.iniciar_turno()
						else:
							break
					continue
				if not MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa):
					revisar(m, "%s/%d final %s" % [pol, semilla, m.estado.etapa])
					if m.estado.ciclo >= 3 or not bool(m.continuar_carrera().get("ok", false)):
						break
					m.iniciar_turno()
					continue
				Bots.jugar_turno(m, pol, rng)
				revisar(m, "%s/%d tras jugar t%d" % [pol, semilla, m.estado.turno_actual])
				m.terminar_turno()
	_check(revisiones > 1500, "se revisaron suficientes estados (%d)" % revisiones)
	print("test_invariantes_estado: ", "OK (%d estados revisados)" % revisiones if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
