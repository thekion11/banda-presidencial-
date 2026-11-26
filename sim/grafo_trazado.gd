class_name GrafoTrazado
extends RefCounted
## Comité de Planificación, niveles 2 y 3: estaciones sobre un grafo de calles precalculado (Dijkstra) y sliders.
## Determinista y sin nodos de Godot. Los datos vienen de data/geo/grafo_urbano.json.

## El grafo (~570 KB) solo se necesita al planificar un trazado: `cargar` guarda la referencia. Los nodos (posiciones) se arman al consultarlos y las
## aristas (lo más pesado, ~20 ms) solo al calcular un camino (construirlas al crear la partida o al reproducir un guardado costaba ~25 ms cada vez).
var _crudo: Dictionary = {}
var _con_pos: bool = true
var _con_ady: bool = true
var _pos: Dictionary = {}
var _ady: Dictionary = {}
var _orden: Array[String] = []
var _params: Dictionary = {}
var pos: Dictionary:  # id -> Vector2
	get:
		_armar_pos()
		return _pos
var ady: Dictionary:  # id -> Array[Dictionary] {a, peso, longitud, costo_mult, expropiaciones, rio}
	get:
		_armar_ady()
		return _ady
var orden: Array[String]:  # orden estable de nodos (desempates deterministas)
	get:
		_armar_pos()
		return _orden
var params: Dictionary:
	get:
		_armar_pos()
		return _params


func cargar(d: Dictionary) -> void:
	## Carga el grafo urbano (nodos y aristas) y prepara posiciones y adyacencias.
	_crudo = d
	_con_pos = false
	_con_ady = false


func _armar_pos() -> void:
	if _con_pos:
		return
	_con_pos = true
	_pos.clear()
	_orden.clear()
	_params = _crudo.get("parametros", {})
	for n in _crudo.get("nodos", []):
		var id := String(n["id"])
		_pos[id] = Vector2(float(n["x"]), float(n["y"]))
		_orden.append(id)


func _armar_ady() -> void:
	if _con_ady:
		return
	_armar_pos()
	_con_ady = true
	_ady.clear()
	for id in _orden:
		_ady[id] = []
	var pe := float(_params.get("peso_expropiacion", 0.15))
	for a in _crudo.get("aristas", []):
		var peso := float(a["longitud"]) * float(a["costo_mult"]) + pe * float(a["expropiaciones"])
		var poly: Array = a.get("poly", [])
		var inversa: Array = poly.duplicate()
		inversa.reverse()
		for par in [[a["a"], a["b"], poly], [a["b"], a["a"], inversa]]:
			_ady[String(par[0])].append({"a": String(par[1]), "peso": peso, "longitud": float(a["longitud"]),
					"costo_mult": float(a["costo_mult"]), "expropiaciones": int(a["expropiaciones"]), "rio": bool(a["rio"]), "poly": par[2]})


func listo() -> bool:
	## true si el grafo tiene nodos cargados.
	return not (_crudo.get("nodos", []) as Array).is_empty()


func nodo_cercano(p: Vector2) -> String:
	## Id del nodo del grafo más cercano a un punto del mapa.
	var mejor := ""
	var mejor_d := 1.0e9
	for id in orden:
		var d := (pos[id] as Vector2).distance_squared_to(p)
		if d < mejor_d:
			mejor_d = d
			mejor = id
	return mejor


func _menor(x: Array, y: Array) -> bool:
	return float(x[0]) < float(y[0]) or (float(x[0]) == float(y[0]) and int(x[1]) < int(y[1]))


func _push(h: Array, item: Array) -> void:
	h.append(item)
	var i := h.size() - 1
	while i > 0:
		var p := (i - 1) / 2
		if _menor(h[i], h[p]):
			var t: Array = h[i]
			h[i] = h[p]
			h[p] = t
			i = p
		else:
			break


func _pop(h: Array) -> Array:
	var top: Array = h[0]
	var ultimo: Array = h.pop_back()
	if not h.is_empty():
		h[0] = ultimo
		var i := 0
		while true:
			var l := 2 * i + 1
			var r := l + 1
			var m := i
			if l < h.size() and _menor(h[l], h[m]):
				m = l
			if r < h.size() and _menor(h[r], h[m]):
				m = r
			if m == i:
				break
			var t: Array = h[i]
			h[i] = h[m]
			h[m] = t
			i = m
	return top


func ruta(origen: String, destino: String) -> Array[String]:
	## Camino de menor peso (longitud × costo + expropiaciones). Dijkstra con montículo binario; desempate determinista por orden de inserción.
	var camino: Array[String] = []
	if not pos.has(origen) or not pos.has(destino):
		return camino
	var dist: Dictionary = {origen: 0.0}
	var prev: Dictionary = {}
	var hecho: Dictionary = {}
	var cola: Array = []
	var seq := 0
	_push(cola, [0.0, seq, origen])
	while not cola.is_empty():
		var it := _pop(cola)
		var u: String = it[2]
		if hecho.has(u):
			continue
		hecho[u] = true
		if u == destino:
			break
		for e in ady[u]:
			var v: String = e["a"]
			var alt := float(dist[u]) + float(e["peso"])
			if alt < float(dist.get(v, INF)):
				dist[v] = alt
				prev[v] = u
				seq += 1
				_push(cola, [alt, seq, v])
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
	var puntos: Array = []
	for k in range(estaciones.size() - 1):
		var tramo := ruta(String(estaciones[k]), String(estaciones[k + 1]))
		for i in range(tramo.size()):
			if i == 0 and not nodos.is_empty():
				continue
			nodos.append(tramo[i])
		for i in range(tramo.size() - 1):
			var e := _arista(tramo[i], tramo[i + 1])
			var pl: Array = e.get("poly", [])
			puntos.append_array(pl if puntos.is_empty() else pl.slice(1))
			longitud += float(e["longitud"])
			indice += float(e["longitud"]) * float(e["costo_mult"])
			expro += int(e["expropiaciones"])
			rios += 1 if bool(e["rio"]) else 0
	return {"nodos": nodos, "puntos": puntos, "longitud": longitud, "indice": indice, "expropiaciones": expro, "rios": rios}


func estaciones_base(variante: Dictionary) -> Array:
	## Estaciones de una variante del Comité: las propias o las derivadas de su trazado.
	if variante.has("estaciones"):
		return variante["estaciones"]
	return estaciones_de(variante.get("trazado", []))


func estaciones_de(trazado: Array) -> Array[String]:
	## Ajusta (snap) los vértices de un trazado precalculado a los nodos más cercanos, sin repetir consecutivos.
	var res: Array[String] = []
	for p in trazado:
		var id := nodo_cercano(Vector2(float(p[0]), float(p[1])))
		if res.is_empty() or res[res.size() - 1] != id:
			res.append(id)
	return res


func estaciones_validas(estaciones: Array) -> bool:
	## true si las estaciones existen en el grafo, son consecutivas distintas y su número está en el rango permitido.
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
	var est_base := estaciones_base(base)
	var eb := evaluar(est_base)
	var en := evaluar(estaciones)
	var r_costo := float(en["indice"]) / maxf(0.001, float(eb["indice"]))
	var r_expro := float(en["expropiaciones"] + 1) / maxf(1.0, float(eb["expropiaciones"] + 1))
	var r_long := float(en["longitud"]) / maxf(0.001, float(eb["longitud"]))
	var extra := float(estaciones.size() - est_base.size())
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
	var tz: Array = en["puntos"]
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
