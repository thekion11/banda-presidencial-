extends SceneTree
## Elección con población: voto por región, voto nacional ponderado por habitantes, ganadores y salida para la pantalla.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		print("FALLO VOTO REGIONAL: ", msg)


func _init() -> void:
	var datos := Datos.cargar_todo()
	var m := AyudaV2.gobierno(datos, 52, [])
	var r := m.regiones
	var suma := 0.0
	for id in r.pesos.keys():
		suma += float(r.pesos[id])
	_check(absf(suma - 1.0) < 1e-9, "los pesos suman 1")
	var hab_rm := 0.0
	var total := 0.0
	for x in r.catalogo:
		total += float(x["poblacion_miles"])
		if x["id"] == "metropolitana":
			hab_rm = float(x["poblacion_miles"])
	_check(absf(float(r.pesos["metropolitana"]) - hab_rm / total) < 1e-9, "la RM pesa su población relativa")
	# voto nacional = suma ponderada (sin tope) y detalle por región
	var apr := {}
	var i := 0
	for x in r.catalogo:
		apr[x["id"]] = 30.0 + 2.0 * float(i)
		i += 1
	var det := VotoRegional.calcular(r, apr, 0.0, 0.0, 100.0, 50.0)
	var esperado := 0.0
	for x in r.catalogo:
		esperado += float(r.pesos[x["id"]]) * float(apr[x["id"]])
	_check(absf(float(det["voto_nacional"]) - esperado) < 1e-9, "voto nacional = suma ponderada")
	_check(det["regiones"].size() == r.catalogo.size() and absf(float(det["total_habitantes_miles"]) - total) < 1e-6, "una fila por región y total de habitantes")
	var ganadas := 0
	for f in det["regiones"]:
		ganadas += 1 if bool(f["gana_gobierno"]) else 0
		_check(bool(f["gana_gobierno"]) == (float(f["voto"]) >= 50.0), "gana si voto >= umbral (%s)" % f["id"])
	_check(ganadas == int(det["regiones_ganadas"]), "regiones ganadas coincide")
	# región grande gana, regiones pequeñas pierden: el voto nacional lo decide la población
	var gran := {}
	for x in r.catalogo:
		gran[x["id"]] = 70.0 if x["id"] == "metropolitana" else 20.0
	var d2 := VotoRegional.calcular(r, gran, 0.0, 0.0, 100.0, 50.0)
	_check(int(d2["regiones_ganadas"]) == 1, "gana solo una región (la grande)")
	_check(float(d2["voto_nacional"]) > 20.0 + 50.0 * float(r.pesos["metropolitana"]) - 1.0, "la RM arrastra el voto nacional en proporción a su peso")
	var peq := {}
	for x in r.catalogo:
		peq[x["id"]] = 20.0 if x["id"] == "metropolitana" else 70.0
	var d3 := VotoRegional.calcular(r, peq, 0.0, 0.0, 100.0, 50.0)
	_check(int(d3["regiones_ganadas"]) == r.catalogo.size() - 1, "gana en todas menos la grande")
	_check(float(d3["voto_nacional"]) < float(d3["regiones_ganadas"]) / float(r.catalogo.size()) * 70.0, "ganar en muchas regiones pequeñas no basta contra la población")
	# integración: resolver_eleccion devuelve el detalle y lo deja en el estado; determinista
	var salidas: Array[String] = []
	for k in range(2):
		var resp: Array[Dictionary] = []
		for p in datos["ideologia"]["preguntas"]:
			resp.append(p["opciones"][1])
		var partido := GeneradorPartido.construir_partido("Prueba", "PRU", "metropolitana", resp, datos["ideologia"])
		var mc := Partida.crear(datos, 52, partido)
		while not mc.estado.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
			mc.terminar_turno()
		var res := mc.resolver_eleccion_presidencial()
		_check(res["ok"] and res["regiones"].size() == mc.regiones.catalogo.size(), "la elección trae una fila por región")
		var pond := 0.0
		for f in res["regiones"]:
			pond += float(f["peso"]) * float(f["voto"])
		_check(absf(pond - float(res["voto_final"])) < 1e-6, "voto_final = Σ peso · voto (salvo topes por región)")
		_check(mc.estado.ultima_eleccion["regiones"].size() == res["regiones"].size(), "queda en estado.ultima_eleccion")
		salidas.append(JSON.stringify(res))
	_check(salidas[0] == salidas[1], "misma semilla y mismas entradas, mismo resultado")
	# ruido regional (modesto, determinista, fuera del RNG de la partida)
	var a0 := VotoRegional.calcular(r, gran, 0.0, 0.0, 100.0, 50.0)
	var a6 := VotoRegional.calcular(r, gran, 0.0, 0.0, 100.0, 50.0, 6.0, 52, 1, 1)
	var a6b := VotoRegional.calcular(r, gran, 0.0, 0.0, 100.0, 50.0, 6.0, 52, 1, 1)
	_check(JSON.stringify(a6) == JSON.stringify(a6b), "el ruido regional es determinista")
	var distintos := 0
	for f in a6["regiones"]:
		_check(absf(float(f["ruido"])) <= 6.0 + 1e-9, "|eps| <= r (%s)" % f["id"])
		distintos += 1 if absf(float(f["ruido"])) > 1e-9 else 0
	_check(distintos >= 12, "casi todas las regiones reciben ruido")
	_check(JSON.stringify(a0["regiones"][0]) == JSON.stringify(VotoRegional.calcular(r, gran, 0.0, 0.0, 100.0, 50.0, 0.0, 52, 1, 1)["regiones"][0]), "r = 0 no agrega ruido")
	var pondera := 0.0
	for f in a6["regiones"]:
		pondera += float(f["peso"]) * float(f["voto"])
	_check(absf(pondera - float(a6["voto_nacional"])) < 1e-9, "con ruido el voto nacional sigue siendo la suma ponderada")
	var a7 := VotoRegional.calcular(r, gran, 0.0, 0.0, 100.0, 50.0, 6.0, 53, 1, 1)
	_check(JSON.stringify(a6["regiones"]) != JSON.stringify(a7["regiones"]), "otra semilla, otro ruido")
	_check(["ambas", "solo_poblacion", "solo_regiones", "ninguna"].has(a6["gano_por"]), "gano_por válido")
	# región grande gana pero pierdes regiones: gana por población; mayoría de regiones pero pierdes: solo_regiones
	_check(String(VotoRegional.calcular(r, gran, 40.0, 0.0, 100.0, 50.0)["gano_por"]) in ["ninguna", "solo_poblacion", "ambas", "solo_regiones"], "caso grande")
	# integración con la fila del ruido en una copia de los datos (data/ no se toca)
	var d6 := datos.duplicate(true)
	d6["leyes"]["campana"]["ruido_eleccion_regional"] = 6.0
	var resp2: Array[Dictionary] = []
	for p in d6["ideologia"]["preguntas"]:
		resp2.append(p["opciones"][1])
	var part2 := GeneradorPartido.construir_partido("Prueba", "PRU", "metropolitana", resp2, d6["ideologia"])
	var mr := Partida.crear(d6, 52, part2)
	while not mr.estado.eleccion_pendiente(int(d6["leyes"]["hemiciclo"]["semanas_campana"])):
		mr.terminar_turno()
	var rr := mr.resolver_eleccion_presidencial()
	var pond2 := 0.0
	for f in rr["regiones"]:
		pond2 += float(f["peso"]) * float(f["voto"])
	_check(absf(pond2 - float(rr["voto_final"])) < 1e-9, "con ruido, voto_final = Σ peso · voto")
	_check(rr.has("gano_por"), "la elección informa si ganó por población o por regiones")
	print("test_voto_regional: ", "OK" if _fallos == 0 else "FALLOS %d" % _fallos)
	quit(1 if _fallos > 0 else 0)
