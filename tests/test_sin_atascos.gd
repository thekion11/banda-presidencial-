extends SceneTree
## Sin atascos: al empezar cada turno (campaña, gobierno u oposición) hay mano, movimientos y al menos una carta que se pueda jugar, y la partida siempre avanza.

var _fallos := 0
var _turnos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _revisar(m: MotorTurno, donde: String) -> void:
	var e := m.estado
	_turnos += 1
	_check(not e.mano.is_empty(), "%s: mano vacía (etapa %s, turno %d)" % [donde, e.etapa, e.turno_actual])
	_check(e.pa_actual >= 1, "%s: sin movimientos al empezar el turno (%d)" % [donde, e.pa_actual])
	var jugable := false
	for i in range(e.mano.size()):
		if m.costo_carta(e.mano[i]) <= e.pa_actual and not (m.es_unica(e.mano[i]) and e.cartas_ejecutadas.has(String(e.mano[i]["id"]))):
			jugable = true
			break
	_check(jugable, "%s: ninguna carta de la mano se puede jugar (etapa %s, turno %d)" % [donde, e.etapa, e.turno_actual])


func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var etapas := {}
	var cfg_af: Dictionary = datos["leyes"]["afiliacion"]
	var combos := 0
	for dif in ["facil", "normal", "dificil"]:
		for afil in ["propio", "independiente", "existente"]:
			for rep in range(2):
				var sd := 200 + combos * 2 + rep
				combos += 1
				var politica: String = ["pasivo", "azar", "codicioso", "completo"][sd % 4]
				var base: Dictionary = datos["coalicion"][sd % datos["coalicion"].size()] if afil == "existente" else {}
				var rr: Array[Dictionary] = resp.slice(0, 3) if afil == "existente" else resp
				var partido := GeneradorPartido.construir_partido_afiliado(afil, base, "S", "SSS", "metropolitana", rr, datos["ideologia"], cfg_af)
				partido["dificultad"] = dif
				var etiqueta := "%s/%s/%s semilla %d" % [dif, afil, politica, sd]
				var m := Partida.crear(datos, sd, partido)
				var rng := RandomNumberGenerator.new()
				rng.seed = sd
				var tope := 1500
				while tope > 0 and m.estado.ciclo <= 3 and MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa):  # hasta 3 periodos de la carrera
					tope -= 1
					etapas[m.estado.etapa] = true
					if m.estado.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
						var r := m.resolver_eleccion_presidencial()
						if bool(r["electo"]) or bool(r["balotaje"]):
							m.iniciar_turno()
						continue
					_revisar(m, etiqueta)
					Bots.jugar_turno(m, politica, rng)
					m.terminar_turno()
					if not MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa) and m.estado.etapa != "campana":
						if bool(m.continuar_carrera().get("ok", false)):  # la carrera sigue: oposición o campaña nueva
							m.iniciar_turno()
				_check(tope > 0, "%s: la partida no avanza (se agotó el tope de turnos, ciclo %d)" % [etiqueta, m.estado.ciclo])
	_check(etapas.has("campana") and etapas.has("gobierno") and etapas.has("oposicion"), "se recorrieron campaña, gobierno y oposición (%s)" % str(etapas.keys()))
	print("test_sin_atascos: %d turnos revisados" % _turnos)
	print("test_sin_atascos: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
