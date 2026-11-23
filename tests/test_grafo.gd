extends SceneTree
## Comité nivel 2 y 3 sobre el grafo real de Gran Santiago (OSM): Dijkstra, trazado propio, sliders y serialización.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO GRAFO: ", msg)


func _peso_ruta(g: GrafoTrazado, camino: Array) -> float:
	var s := 0.0
	for i in range(camino.size() - 1):
		var e := g._arista(String(camino[i]), String(camino[i + 1]))
		_check(not e.is_empty(), "el camino usa una arista inexistente")
		if not e.is_empty():
			s += float(e["peso"])
	return s


func _grilla(n: int) -> Dictionary:
	## Grafo sintético n×n con pesos variados para comparar contra Floyd-Warshall.
	var nodos: Array = []
	var aristas: Array = []
	for j in range(n):
		for i in range(n):
			nodos.append({"id": "g%d_%d" % [i, j], "x": float(i) / n, "y": float(j) / n})
			for d in [[1, 0], [0, 1]]:
				if i + d[0] < n and j + d[1] < n:
					aristas.append({"a": "g%d_%d" % [i, j], "b": "g%d_%d" % [i + d[0], j + d[1]], "longitud": 1.0 + float((i * 7 + j * 13) % 5) * 0.3,
							"costo_mult": 1.0 + float((i * 3 + j * 5) % 4) * 0.25, "expropiaciones": (i * 11 + j * 3) % 6, "rio": false})
	return {"parametros": {"peso_expropiacion": 0.15}, "nodos": nodos, "aristas": aristas}


func _floyd(g: GrafoTrazado) -> Dictionary:
	var d: Dictionary = {}
	for a in g.orden:
		for b in g.orden:
			d[a + "|" + b] = 0.0 if a == b else INF
	for a in g.orden:
		for e in g.ady[a]:
			d[a + "|" + e["a"]] = minf(float(d[a + "|" + e["a"]]), float(e["peso"]))
	for k in g.orden:
		for i in g.orden:
			for j in g.orden:
				var alt: float = float(d[i + "|" + k]) + float(d[k + "|" + j])
				if alt < float(d[i + "|" + j]):
					d[i + "|" + j] = alt
	return d


func _init() -> void:
	# 1) Dijkstra con montículo == Floyd-Warshall en un grafo sintético
	var gs := GrafoTrazado.new()
	gs.cargar(_grilla(9))
	var fw := _floyd(gs)
	for par in [["g0_0", "g8_8"], ["g0_8", "g8_0"], ["g3_4", "g5_1"], ["g2_2", "g2_7"]]:
		var r := gs.ruta(par[0], par[1])
		_check(absf(_peso_ruta(gs, r) - float(fw[par[0] + "|" + par[1]])) < 1e-6, "Dijkstra no es óptimo entre %s y %s" % par)
	_check(gs.ruta("g0_0", "g0_0").size() == 1, "ruta de un nodo a sí mismo")
	# 2) Grafo real de Gran Santiago
	var datos := Datos.cargar_todo()
	var g := GrafoTrazado.new()
	g.cargar(datos["grafo"])
	_check(g.listo() and g.orden.size() > 500, "el grafo real debe tener cientos de nodos")
	var n := g.orden.size()
	var ids := [g.orden[0], g.orden[n / 5], g.orden[n / 2], g.orden[(4 * n) / 5], g.orden[n - 1]]
	for k in range(ids.size() - 1):
		var a: String = ids[k]
		var b: String = ids[k + 1]
		var r := g.ruta(a, b)
		_check(r.size() >= 2 and r[0] == a and r[r.size() - 1] == b, "la ruta debe unir origen y destino")
		_check(g.ruta(a, b) == r, "Dijkstra debe ser determinista")
		_check(absf(_peso_ruta(g, g.ruta(b, a)) - _peso_ruta(g, r)) < 1e-6, "el grafo no es simétrico")
	var ab := _peso_ruta(g, g.ruta(ids[0], ids[2]))
	var bc := _peso_ruta(g, g.ruta(ids[2], ids[4]))
	var ac := _peso_ruta(g, g.ruta(ids[0], ids[4]))
	_check(ac <= ab + bc + 1e-6, "desigualdad triangular")
	var corto := g.evaluar([ids[0], ids[1]])
	var largo := g.evaluar([ids[0], ids[1], ids[3]])
	_check(float(largo["longitud"]) > float(corto["longitud"]) and float(largo["indice"]) > float(corto["indice"]), "más trazado debe costar más")
	_check(not (corto["puntos"] as Array).is_empty(), "el trazado debe traer su polilínea")
	# 3) Variantes reales de las propuestas
	var prop: Dictionary = datos["propuestas"][0]
	var base: Dictionary = prop["variantes"][0]
	var ests: Array = g.estaciones_base(base)
	_check(g.estaciones_validas(ests), "las estaciones base deben ser válidas")
	var igual := g.variante_modificada(base, ests, 0.0, 0.0)
	_check(absf(float(igual["costo_musd"]) - float(base["costo_musd"])) <= 10.0, "sin cambios el costo debe coincidir con la base")
	var rapido := g.variante_modificada(base, ests, 1.0, 0.0)
	_check(float(rapido["costo_musd"]) > float(igual["costo_musd"]) and float(rapido["plazo_anios"]) < float(igual["plazo_anios"]), "ritmo alto: más caro y más corto")
	var ancho := g.variante_modificada(base, ests, 0.0, 1.0)
	_check(int(ancho["poblacion_miles"]) > int(igual["poblacion_miles"]) and int(ancho["expropiaciones"]) >= int(igual["expropiaciones"]), "cobertura alta: más población y expropiaciones")
	_check(not g.advertencias(rapido, prop).is_empty(), "el Corrector siempre responde algo")
	_check(not g.estaciones_validas([ests[0], ests[1]]), "se exigen al menos 3 estaciones")
	# 4) En partida: trazado propio, JSON y huella
	var resp: Array[Dictionary] = [datos["ideologia"]["preguntas"][0]["opciones"][1]]
	var partido := GeneradorPartido.construir_partido("Test", "TST", "metropolitana", resp, datos["ideologia"])
	var custom := {"base": "A", "estaciones": [ests[0], ests[1], g.orden[n / 3], ests[ests.size() - 1]], "ritmo": 0.5, "cobertura": 0.25}
	var huellas: Array[String] = []
	for vuelta in range(2):
		var m := Partida.crear(datos, 99, partido)
		m.estado.etapa = "gobierno"
		m.estado.propuestas_abiertas.append(String(prop["id"]))
		m.estado.pa_actual = 8
		var c: Dictionary = custom if vuelta == 0 else JSON.parse_string(JSON.stringify(custom))
		var r := m.aprobar_propuesta(String(prop["id"]), "A", "", c)
		_check(bool(r["ok"]), "no se pudo aprobar el trazado propio: %s" % r)
		_check(m.estado.obras_en_curso.size() == 1 and String(m.estado.obras_en_curso[0]["variante"]) == "M", "debe iniciarse una obra con la variante propia")
		var malo := m.aprobar_propuesta(String(prop["id"]), "A", "", {"base": "A", "estaciones": [ests[0]]})
		_check(not bool(malo["ok"]), "un trazado inválido debe rechazarse")
		huellas.append(m.estado.calcular_huella())
	_check(huellas[0] == huellas[1], "el trazado serializado como JSON debe dar la misma huella")
	if _fallos == 0:
		print("GRAFO OK (%d nodos reales; Dijkstra óptimo, sliders y trazado propio reproducible)" % n)
	quit(0 if _fallos == 0 else 1)
