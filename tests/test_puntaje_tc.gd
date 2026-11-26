extends SceneTree
## Pruebas unitarias directas: MotorMandato.calcular_puntaje, MotorLegal.resolver_tc y MotorLegal.corregir.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Puntaje", "PUN", "metropolitana", resp, datos["ideologia"])
	var m := Partida.crear(datos, 5, partido)
	var pt: Dictionary = datos["leyes"]["puntaje"]
	# puntaje: fórmula exacta con los pesos de data/leyes.json
	m.estado.indicadores["aprobacion"] = 50.0
	m.estado.indicadores["fiscal"] = 40.0
	m.estado.indicadores["capital"] = 30.0
	m.estado.promesas_campana.clear()
	var base := roundi(50.0 * float(pt["peso_aprobacion"]) + 40.0 * float(pt["peso_fiscal"]) + 30.0 * float(pt["peso_capital"]))
	_check(m.mandato.calcular_puntaje() == base, "sin promesas ni obras: %d (esperado %d)" % [m.mandato.calcular_puntaje(), base])
	m.estado.obras_terminadas = [{"id": "a"}, {"id": "b"}]
	_check(m.mandato.calcular_puntaje() == base + roundi(2.0 * float(pt["peso_obras"])), "cada obra terminada suma peso_obras")
	m.estado.indicadores["aprobacion"] = 51.0
	_check(m.mandato.calcular_puntaje() == base + roundi(2.0 * float(pt["peso_obras"])) + roundi(float(pt["peso_aprobacion"])), "un punto de aprobación suma peso_aprobacion")
	m.estado.indicadores["aprobacion"] = 0.0
	m.estado.indicadores["fiscal"] = 0.0
	m.estado.indicadores["capital"] = 0.0
	m.estado.obras_terminadas = []
	_check(m.mandato.calcular_puntaje() == 0, "todo en cero da puntaje 0")
	# tribunal constitucional
	var lg := m.legal
	_check(not lg.resolver_tc("tipo_que_no_existe")["recurso"], "tipo desconocido: sin recurso")
	for t in datos["leyes"]["tipos_ley"]:
		var id := String(t["id"])
		if not bool(t.get("puede_ir_tc", false)):
			_check(not lg.resolver_tc(id)["recurso"] and not lg.resolver_tc(id, 1.0)["recurso"], "%s no puede ir al TC" % id)
			continue
		var r1 := lg.resolver_tc(id, 1.0)
		_check(bool(r1["recurso"]) and not bool(r1["cae"]), "%s: con éxito 1,0 el TC nunca la tumba" % id)
		var r0 := lg.resolver_tc(id, 0.0)
		_check(bool(r0["recurso"]) and bool(r0["cae"]), "%s: con éxito 0,0 el TC siempre la tumba" % id)
		var rec := 0
		for _i in range(400):
			if bool(lg.resolver_tc(id)["recurso"]):
				rec += 1
		var esperado := float(t["prob_recurso_tc"])
		_check(absf(float(rec) / 400.0 - esperado) < 0.12, "%s: frecuencia de recurso %.2f lejos de %.2f" % [id, float(rec) / 400.0, esperado])
	# corrector de realismo: sin corrector no aplica; con capacidad menor que la meta ofrece versión viable
	_check(not lg.corregir({"id": "x"}, m.estado)["aplica"], "carta sin corrector: no aplica")
	var carta := {"corrector": {"meta": 100.0, "capacidad": 40.0, "modo": "por_tramos", "unidad": "km"}}
	var c := lg.corregir(carta, m.estado)
	_check(bool(c["aplica"]) and absf(float(c["ratio"]) - 0.4) < 0.001 and String(c["mensaje"]).contains("por tramos"), "capacidad 40 de 100: ratio 0,4 por tramos")
	carta["corrector"]["capacidad"] = 100.0
	_check(not lg.corregir(carta, m.estado)["aplica"], "capacidad igual a la meta: no aplica")
	carta["corrector"]["capacidad"] = 1.0
	_check(float(lg.corregir(carta, m.estado)["ratio"]) >= float(datos["leyes"]["dinamica"]["ratio_obra_min"]), "el ratio nunca baja de ratio_obra_min")
	print("test_puntaje_tc: ", "OK" if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
