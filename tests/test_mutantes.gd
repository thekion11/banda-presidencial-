extends SceneTree
## Candados contra mutantes que sobrevivían a la suite (hallazgos de «Búsqueda infinita de fallas», 26-nov-2026):
## votación con el Senado exactamente en el mínimo, rango de la intención de voto en los extremos, malestar de la coalición con una penalización mayor que los movimientos internos
## y tope del apoyo del Congreso con datos alterados.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _partida(datos: Dictionary, semilla: int) -> MotorTurno:
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	return Partida.crear(datos, semilla, GeneradorPartido.construir_partido("Mutantes", "MUT", "metropolitana", resp, datos["ideologia"]))


func _init() -> void:
	var datos := Datos.cargar_todo()
	# 1) Senado exactamente en el mínimo aprueba (>=); un voto menos, no. La Cámara se asegura con una bancada enorme.
	var m := _partida(datos, 11)
	m.estado.partido["escanos_propios"] = 50
	for tipo in ["ley_simple", "quorum_calificado", "ley_organica_constitucional", "reforma_constitucional"]:
		var base := m.legal.votar(m.estado, tipo)
		if bool(base.get("sin_votacion", false)):
			continue
		var min_sen := int(base["min_senado"])
		var v := m.legal.votar(m.estado, tipo, min_sen)
		_check(int(v["senado"]) == min_sen and int(v["camara"]) >= int(v["min_camara"]) and bool(v["aprobada"]), "%s: con el Senado en el mínimo (%d) la ley se aprueba %s" % [tipo, min_sen, str(v)])
		var w := m.legal.votar(m.estado, tipo, min_sen - 1)
		_check(not bool(w["aprobada"]), "%s: un voto menos que el mínimo del Senado no aprueba" % tipo)
	# 2) la intención de voto nunca sale de 0..100, ni con aprobación casi nula o casi total
	for ap in [0.5, 1.0, 99.0, 99.5]:
		var me := _partida(datos, 12)
		me.estado.etapa = "campana"
		for t in range(1, 9):
			me.estado.turno_actual = t
			me.estado.indicadores["aprobacion"] = ap
			Encuestas.registrar(me)
			var q: Dictionary = me.estado.encuestas.back()
			_check(float(q["intencion"]) >= 0.0 and float(q["intencion"]) <= 100.0, "aprobación %.1f turno %d: intención %.1f fuera de 0..100" % [ap, t, float(q["intencion"])])
	# 3) el malestar de la coalición no deja los movimientos internos bajo cero aunque la penalización sea mayor
	var mc := _partida(datos, 13)
	mc.catalogo_leyes["coalicion"]["penal_internos_malestar"] = 10
	var ids: Array = mc.coalicion.partidos.keys()
	ids.sort()
	mc.estado.etapa = "gobierno"
	mc.coalicion.unirse(String(ids[0]))
	for id in mc.estado.coalicion.keys():
		mc.estado.coalicion[id]["satisfaccion"] = float(datos["leyes"]["coalicion"]["umbral_malestar"]) - 1.0
	mc.estado.internos_actual = 3
	mc.coalicion.amanecer()
	_check(mc.estado.internos_actual >= 0, "la penalización por malestar no deja internos negativos (%d)" % mc.estado.internos_actual)
	# 4) el apoyo del Congreso no pasa de 1 aunque los datos lo pidan: los bloques nunca suman más que la cámara
	var ma := _partida(datos, 14)
	ma.catalogo_leyes["congreso"]["apoyo_base"] = 0.6
	ma.estado.indicadores["capital"] = 100.0
	ma.estado.indicadores["cohesion"] = 100.0
	for camara in [false, true]:
		var comp := ma.legal.composicion(ma.estado, camara)
		_check(int(comp["propios"]) + int(comp["aliados"]) <= int(comp["total"]), "apoyo topado en 1: propios + aliados <= total (%s)" % str(comp))
	for tipo in ["ley_simple", "reforma_constitucional"]:
		var vv := ma.legal.votar(ma.estado, tipo)
		if not bool(vv.get("sin_votacion", false)):
			_check(int(vv["senado"]) <= int(vv["total_senado"]) and int(vv["camara"]) <= int(vv["total_camara"]), "con apoyo máximo los votos no superan el total")
	# con el tope en 1 la votación conserva su ruido hacia abajo; sin tope (apoyo > 1) el Senado quedaría siempre en el total
	var menor := 1000
	for _i in range(80):
		var vs := ma.legal.votar(ma.estado, "ley_simple")
		menor = mini(menor, int(vs["senado"]))
	_check(menor < int(ma.catalogo_leyes["hemiciclo"]["total_senadores"]), "el apoyo máximo es 1: el ruido todavía puede bajar los votos del Senado (mínimo visto %d)" % menor)
	print("test_mutantes: ", "OK" if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
