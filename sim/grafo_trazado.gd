class_name GrafoTrazado
extends RefCounted
## Comité de Planificación, niveles 2 y 3: estaciones sobre un grafo de calles precalculado (Dijkstra) y sliders.
## Determinista y sin nodos de Godot. Los datos vienen de data/geo/grafo_urbano.json.

var pos: Dictionary = {}  # id -> Vector2
var ady: Dictionary = {}  # id -> Array[Dictionary] {a, peso, longitud, costo_mult, expropiaciones, rio}
var orden: Array[String] = []  # orden estable de nodos (desempates deterministas)
var params: Dictionary = {}


func cargar(d: Dictionary) -> void:
	pos.clear()
	ady.clear()
	orden.clear()
	params = d.get("parametros", {})
	for n in d.get("nodos", []):
		var id := String(n["id"])
		pos[id] = Vector2(float(n["x"]), float(n["y"]))
		ady[id] = []
		orden.append(id)
	var pe := float(params.get("peso_expropiacion", 0.15))
	for a in d.get("aristas", []):
		var peso := float(a["longitud"]) * float(a["costo_mult"]) + pe * float(a["expropiaciones"])
		for par in [[a["a"], a["b"]], [a["b"], a["a"]]]:
			ady[String(par[0])].append({"a": String(par[1]), "peso": peso, "longitud": float(a["longitud"]),
					"costo_mult": float(a["costo_mult"]), "expropiaciones": int(a["expropiaciones"]), "rio": bool(a["rio"])})


func listo() -> bool:
	return not pos.is_empty()


func nodo_cercano(p: Vector2) -> String:
	var mejor := ""
	var mejor_d := 1.0e9
	for id in orden:
		var d := (pos[id] as Vector2).distance_squared_to(p)
		if d < mejor_d:
			mejor_d = d
			mejor = id
	return mejor


func ruta(origen: String, destino: String) -> Array[String]:
	## Camino de menor peso (longitud × costo + expropiaciones). Dijkstra O(V²), suficiente para ~64 nodos.
	var dist: Dictionary = {}
	var prev: Dictionary = {}
	var hecho: Dictionary = {}
	for id in orden:
		dist[id] = INF
	if not pos.has(origen) or not pos.has(destino):
		return []
	dist[origen] = 0.0
	while true:
		var u := ""
		var mejor := INF
		for id in orden:  # desempate por orden de los datos
			if not hecho.has(id) and float(dist[id]) < mejor:
				mejor = float(dist[id])
				u = id
		if u == "" or u == destino:
			break
		hecho[u] = true
		for e in ady[u]:
			var v: String = e["a"]
			var alt := float(dist[u]) + float(e["peso"])
			if alt < float(dist[v]):
				dist[v] = alt
				prev[v] = u
	var camino: Array[String] = []
	if destino != origen and not prev.has(destino):
		return camino
	var cur := destino
	while true:
		camino.push_front(cur)
		if cur == origen:
			break
		cur = String(prev[cur])
	return camino


func _arista(a: String, b: String) -> Dictionary:
	for e in ady[a]:
		if e["a"] == b:
			return e
	return {}


func evaluar(estaciones: Array) -> Dictionary:
	## Métricas del trazado que une las estaciones en orden: longitud, índice de costo, expropiaciones, ríos y nodos recorridos.
	var nodos: Array[String] = []
	var longitud := 0.0
	var indice := 0.0
	var expro := 0
	var rios := 0
	for k in range(estaciones.size() - 1):
		var tramo := ruta(String(estaciones[k]), String(estaciones[k + 1]))
		for i in range(tramo.size()):
			if i == 0 and not nodos.is_empty():
				continue
			nodos.append(tramo[i])
		for i in range(tramo.size() - 1):
			var e := _arista(tramo[i], tramo[i + 1])
			longitud += float(e["longitud"])
			indice += float(e["longitud"]) * float(e["costo_mult"])
			expro += int(e["expropiaciones"])
			rios += 1 if bool(e["rio"]) else 0
	return {"nodos": nodos, "longitud": longitud, "indice": indice, "expropiaciones": expro, "rios": rios}


func estaciones_de(trazado: Array) -> Array[String]:
	## Ajusta (snap) los vértices de un trazado precalculado a los nodos más cercanos, sin repetir consecutivos.
	var res: Array[String] = []
	for p in trazado:
		var id := nodo_cercano(Vector2(float(p[0]), float(p[1])))
		if res.is_empty() or res[res.size() - 1] != id:
			res.append(id)
	return res


func estaciones_validas(estaciones: Array) -> bool:
	var mn := int(params.get("min_estaciones", 3))
	var mx := int(params.get("max_estaciones", 7))
	if estaciones.size() < mn or estaciones.size() > mx:
		return false
	for i in range(estaciones.size()):
		if not pos.has(String(estaciones[i])):
			return false
		if i > 0 and estaciones[i] == estaciones[i - 1]:
			return false
	return true


func variante_modificada(base: Dictionary, estaciones: Array, ritmo: float, cobertura: float) -> Dictionary:
	## Variante propia: métricas de la base escaladas por la razón entre el trazado nuevo y el de la base (mismo modo constructivo).
	var sl: Dictionary = params.get("sliders", {})
	ritmo = clampf(ritmo, 0.0, 1.0)
	cobertura = clampf(cobertura, 0.0, 1.0)
	var eb := evaluar(estaciones_de(base["trazado"]))
	var en := evaluar(estaciones)
	var r_costo := float(en["indice"]) / maxf(0.001, float(eb["indice"]))
	var r_expro := float(en["expropiaciones"] + 1) / maxf(1.0, float(eb["expropiaciones"] + 1))
	var r_long := float(en["longitud"]) / maxf(0.001, float(eb["longitud"]))
	var extra := float(estaciones.size() - estaciones_de(base["trazado"]).size())
	var ex: Dictionary = sl.get("estacion_extra", {})
	var costo := float(base["costo_musd"]) * r_costo * (1.0 + float(sl["ritmo"]["costo_max"]) * ritmo) * (1.0 + float(ex.get("costo", 0.0)) * extra)
	var plazo := float(base["plazo_anios"]) * r_long * (1.0 + float(sl["ritmo"]["plazo_max"]) * ritmo)
	var pobl := float(base["poblacion_miles"]) * sqrt(r_long) * (1.0 + float(sl["cobertura"]["poblacion_max"]) * cobertura) * (1.0 + float(ex.get("poblacion", 0.0)) * extra)
	var expro := float(base["expropiaciones"]) * r_expro * (1.0 + float(sl["cobertura"]["expropiaciones_max"]) * cobertura)
	var rz: Dictionary = params.get("rechazo", {})
	var rechazo := "Alto" if expro >= float(rz.get("alto", 200)) else ("Medio" if expro >= float(rz.get("medio", 120)) else "Bajo")
	var efectos: Array = []
	for ef in base["efectos"]:
		var f := 1.0
		match String(ef["ind"]):
			"aprobacion":
				f = pobl / maxf(1.0, float(base["poblacion_miles"]))
			"fiscal":
				f = costo / maxf(1.0, float(base["costo_musd"]))
			"riesgo_ejecucion":
				f = expro / maxf(1.0, float(base["expropiaciones"]))
		efectos.append({"ind": ef["ind"], "delta": snappedf(float(ef["delta"]) * f, 0.1)})
	var tz: Array = []
	var nodos: Array = en["nodos"]
	for id in nodos:
		tz.append([pos[id].x, pos[id].y])
	return {"id": "M", "nombre": "Trazado propio", "costo_musd": snappedf(costo, 10.0), "plazo_anios": snappedf(plazo, 0.1),
			"poblacion_miles": roundi(pobl), "expropiaciones": roundi(expro), "rechazo_vecinal": rechazo, "efectos": efectos,
			"trazado": tz, "estaciones": estaciones.duplicate(), "elevada": bool(base.get("elevada", false)),
			"rios": int(en["rios"]), "base": String(base["id"])}


func advertencias(v: Dictionary, prop: Dictionary) -> Array[String]:
	## Corrector de Realismo del trazado: nunca un "no" seco; propone por tramos o ceder plazo.
	var res: Array[String] = []
	var cap := float(prop["capacidad_musd"])
	if float(v["costo_musd"]) > cap:
		res.append("El costo (US$%d M) supera la capacidad fiscal (US$%d M): propongo construirlo por tramos; el primero cubre el %d %%." % [roundi(float(v["costo_musd"])), roundi(cap), roundi(100.0 * cap / float(v["costo_musd"]))])
	if int(v.get("expropiaciones", 0)) >= int(params.get("rechazo", {}).get("alto", 200)):
		res.append("%d expropiaciones casi aseguran judicialización: puedo bajar el riesgo si aceptas ceder plazo o mover una estación." % int(v["expropiaciones"]))
	if int(v.get("rios", 0)) > 0:
		res.append("El trazado cruza el río %d vez(veces): encarece la obra y alarga el plazo." % int(v["rios"]))
	if res.is_empty():
		res.append("El trazado es viable con la capacidad actual.")
	return res
