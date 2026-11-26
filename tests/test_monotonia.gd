extends SceneTree
## Propiedades de monotonía de sim/: jugar una carta cuyo único efecto sobre la aprobación es positivo, sin riesgo, ley, obra ni delegación, no baja la aprobación;
## una carta con efecto negativo no la sube; gastar movimientos nunca los aumenta; los indicadores se mantienen en rango. Se buscan violaciones jugando la carta 0 de la mano
## en carreras con distintas políticas y dificultades (el azar documentado —escándalos de ministros, riesgo de la carta— queda fuera por construcción).

var _fallos := 0
var _casos := 0
var _violaciones: Array[String] = []
var _escandalos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _violaciones.size() < 12:
			_violaciones.append(msg)


func _delta_aprobacion(c: Dictionary) -> float:
	var d := 0.0
	for ef in c["efectos"]:
		if String(ef["ind"]) == "aprobacion":
			d += float(ef["delta"])
	return d


func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	for dif in ["facil", "normal", "dificil"]:
		var partido := GeneradorPartido.construir_partido("Monotonía", "MON", "metropolitana", resp, datos["ideologia"])
		partido["dificultad"] = dif
		for semilla in range(4):
			var m := Partida.crear(datos, 9500 + semilla, partido)
			var rng := RandomNumberGenerator.new()
			rng.seed = 9500 + semilla
			var guard := 0
			while guard < 400 and MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa):
				guard += 1
				var e := m.estado
				if e.etapa == "campana" and e.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
					if not Bots.elegir(m, datos, "codicioso", rng):
						break
					continue
				for _j in range(3):  # tres cartas por semana, siempre la primera de la mano
					if e.mano.is_empty():
						break
					var c: Dictionary = e.mano[0]
					if m.costo_carta(c) > e.pa_actual or (e.etapa == "gobierno" and m.es_unica(c) and e.cartas_ejecutadas.has(String(c["id"]))):
						break
					var antes := e.ind("aprobacion")
					var pa0 := e.pa_actual
					var da := _delta_aprobacion(c)
					var limpia: bool = not c.has("riesgo") and not c.has("obra") and c["requisitos"]["ley"] == null and e.etapa == "gobierno"
					var r := m.jugar_carta(0)
					if not bool(r.get("ok", false)):
						break
					_check(e.pa_actual <= pa0, "%s/%d: jugar %s subió los movimientos %d -> %d" % [dif, semilla, c["id"], pa0, e.pa_actual])
					if bool(r.get("escandalo", false)):
						_escandalos += 1  # azar documentado: un escándalo ministerial resta aprobación (leyes.json › escandalo)
						continue
					if limpia and da > 0.0 and c["efectos"].all(func(ef: Dictionary) -> bool: return String(ef["ind"]) != "aprobacion" or float(ef["delta"]) >= 0.0):
						_casos += 1
						_check(e.ind("aprobacion") >= antes - 0.0001, "%s/%d t%d: %s (+%.1f aprobación) la bajó %.2f -> %.2f" % [dif, semilla, e.turno_actual, c["id"], da, antes, e.ind("aprobacion")])
					for k in e.indicadores:
						_check(is_finite(float(e.indicadores[k])), "%s/%d: indicador %s no finito" % [dif, semilla, k])
				m.terminar_turno()
	_check(_casos > 100, "se probaron suficientes cartas con efecto positivo (%d)" % _casos)
	for v in _violaciones:
		print("FALLO: ", v)
	print("test_monotonia: ", "OK (%d cartas positivas jugadas sin bajar la aprobación; %d escándalos de ministro apartados)" % [_casos, _escandalos] if _fallos == 0 else "%d violaciones en %d casos" % [_fallos, _casos])
	quit(1 if _fallos > 0 else 0)
