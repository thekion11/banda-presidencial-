extends SceneTree
## Casos límite del cierre de partida: empate exacto con el umbral de elección, aprobación justo en el umbral de crisis, crisis en la última semana y fin de mandato exacto.
## Se fuerza el estado (sin comprobar replay): lo que se prueba es la regla, no el guardado.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _partido(datos: Dictionary) -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	return GeneradorPartido.construir_partido("Limite", "LIM", "metropolitana", resp, datos["ideologia"])


func _fin_campana(datos: Dictionary, semilla: int) -> MotorTurno:
	var m := Partida.crear(datos, semilla, _partido(datos))
	m.catalogo_leyes["campana"]["ruido_eleccion"] = 0.0  # sin ruido: el resultado es exactamente la aprobación
	m.catalogo_leyes["campana"]["ruido_eleccion_regional"] = 0.0  # y sin ruido regional (27-nov-2026): el umbral exacto sigue siendo exacto
	for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		m.terminar_turno()
	return m


func _gobierno(datos: Dictionary) -> MotorTurno:
	for semilla in range(1200, 1260):
		var m := Partida.crear(datos, semilla, _partido(datos))
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		if Bots.elegir(m, datos, "codicioso", rng):
			return m
	return null


func _aprobacion(m: MotorTurno, v: float) -> void:
	for id in m.estado.aprobacion_regional.keys():  # el promedio regional manda: se fija en cada región para que ningún recálculo lo mueva
		m.estado.aprobacion_regional[id] = v
	m.estado.indicadores["aprobacion"] = v


func _init() -> void:
	var datos := Datos.cargar_todo()
	var h: Dictionary = datos["leyes"]["hemiciclo"]
	var camp: Dictionary = datos["leyes"]["campana"]
	# 1) empate exacto con el umbral: gana (>=); una milésima menos, no
	var m := _fin_campana(datos, 5)
	var umbral := float(h["umbral_victoria_presidencial"]) + float(m.mandato.nivel()["umbral_delta"])
	for _i in range(int(camp["min_promesas"])):
		m.estado.promesas_campana.append({"carta_id": "x%d" % _i, "cumplida": false})
	m.estado.indicadores["aprobacion"] = umbral
	var r := m.resolver_eleccion_presidencial()
	_check(bool(r["electo"]) and absf(float(r["voto_final"]) - umbral) < 0.0001, "con el voto exactamente en el umbral se gana (%s)" % str(r))
	var m2 := _fin_campana(datos, 5)
	for _i in range(int(camp["min_promesas"])):
		m2.estado.promesas_campana.append({"carta_id": "x%d" % _i, "cumplida": false})
	m2.estado.indicadores["aprobacion"] = umbral - 0.001
	var r2 := m2.resolver_eleccion_presidencial()
	_check(not bool(r2["electo"]) and bool(r2["balotaje"]), "una milésima bajo el umbral pasa a segunda vuelta (%s)" % str(r2))
	var m3 := _fin_campana(datos, 5)
	for _i in range(int(camp["min_promesas"])):
		m3.estado.promesas_campana.append({"carta_id": "x%d" % _i, "cumplida": false})
	m3.estado.indicadores["aprobacion"] = float(h["umbral_pasa_balotaje"]) - 0.001
	var r3 := m3.resolver_eleccion_presidencial()
	_check(not bool(r3["electo"]) and not bool(r3["balotaje"]) and m3.estado.etapa == "derrota_electoral" and int(m3.estado.resultado_final["puntaje"]) == 0, "bajo el piso de balotaje se pierde con puntaje 0")
	# 2) aprobación justo en el umbral de crisis: no cuenta; justo debajo, sí
	var g := _gobierno(datos)
	_check(g != null, "se llegó al gobierno")
	if g == null:
		quit(1)
		return
	var d: Dictionary = datos["leyes"]["dinamica"]
	var umbral_c := float(d["umbral_crisis_aprobacion"])
	var semanas_c := int(d["semanas_crisis_para_caida"])
	g.estado.semanas_en_crisis = semanas_c - 1
	g.estado.indicadores["aprobacion"] = umbral_c
	g.mandato.evaluar_crisis()
	_check(g.estado.etapa == "gobierno" and g.estado.semanas_en_crisis == 0, "aprobación exactamente en el umbral de crisis no suma semanas de crisis")
	g.estado.semanas_en_crisis = semanas_c - 1
	g.estado.indicadores["aprobacion"] = umbral_c - 0.01
	g.mandato.evaluar_crisis()
	_check(g.estado.etapa == "crisis", "la semana que completa la racha bajo el umbral cae el gobierno")
	_check(int(g.estado.resultado_final["puntaje"]) == g.mandato.calcular_puntaje() and String(g.mandato.epilogo()["id"]) != "", "la crisis tiene puntaje coherente y epílogo")
	# 3) crisis en la última semana del mandato: gana la crisis, no el fin de mandato
	var g2 := _gobierno(datos)
	g2.estado.turno_actual = g2.turnos_mandato()
	g2.estado.dia_actual = (g2.turnos_mandato() - 1) * g2.estado.dias_por_turno + 1
	g2.estado.semanas_en_crisis = semanas_c - 1
	_aprobacion(g2, umbral_c - 0.01)
	g2.terminar_turno()
	_check(g2.estado.etapa == "crisis", "caer en la última semana es crisis y no fin de mandato (%s)" % g2.estado.etapa)
	_check(String(g2.estado.resultado_final["motivo"]) == "crisis" and g2.mandato.sucesion() == "", "el final por crisis no tiene sucesión")
	# 4) fin de mandato exacto en la última semana con aprobación sana
	var g3 := _gobierno(datos)
	g3.estado.turno_actual = g3.turnos_mandato()
	g3.estado.dia_actual = (g3.turnos_mandato() - 1) * g3.estado.dias_por_turno + 1
	g3.estado.semanas_en_crisis = 0
	_aprobacion(g3, 60.0)
	g3.terminar_turno()
	_check(g3.estado.etapa == "fin_mandato", "tras la última semana el mandato termina (%s)" % g3.estado.etapa)
	_check(int(g3.estado.resultado_final["puntaje"]) == g3.mandato.calcular_puntaje() and int(g3.estado.resultado_final["puntaje"]) >= 0, "puntaje del fin de mandato coherente y no negativo")
	_check(String(g3.mandato.epilogo()["id"]) != "" and g3.mandato.sucesion() != "", "fin de mandato con epílogo y sucesión")
	_check(not bool(g3.continuar_carrera().is_empty()), "después del final la carrera continúa")
	print("test_finales_limite: ", "OK" if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
