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
	print("test_voto_regional: ", "OK" if _fallos == 0 else "FALLOS %d" % _fallos)
	quit(1 if _fallos > 0 else 0)
