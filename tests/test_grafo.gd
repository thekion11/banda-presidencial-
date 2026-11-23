extends SceneTree
## Comité nivel 2 y 3: Dijkstra sobre el grafo de calles, trazado propio con sliders y reproducción por guardado.

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
	var datos := Datos.cargar_todo()
	var g := GrafoTrazado.new()
	g.cargar(datos["grafo"])
	_check(g.listo() and g.orden.size() == 64, "el grafo debe tener 64 nodos")
	_check(g.ruta("n00", "n00").size() == 1, "ruta de un nodo a sí mismo")
	var d := _floyd(g)
	for par in [["n00", "n77"], ["n03", "n74"], ["n70", "n07"], ["n34", "n43"]]:
		var r := g.ruta(par[0], par[1])
		_check(absf(_peso_ruta(g, r) - float(d[par[0] + "|" + par[1]])) < 1e-6, "Dijkstra no es óptimo entre %s y %s" % [par[0], par[1]])
		_check(g.ruta(par[0], par[1]) == r, "Dijkstra debe ser determinista")
		_check(absf(_peso_ruta(g, g.ruta(par[1], par[0])) - _peso_ruta(g, r)) < 1e-6, "el grafo no es simétrico")
	var corto := g.evaluar(["n00", "n22"])
	var largo := g.evaluar(["n00", "n22", "n77"])
	_check(float(largo["longitud"]) > float(corto["longitud"]) and float(largo["indice"]) > float(corto["indice"]), "más trazado debe costar más")
	var cruce := g.evaluar(["n20", "n27"])
	_check(int(cruce["rios"]) >= 1, "cruzar la banda del río debe contarse")
	var prop: Dictionary = datos["propuestas"][0]
	var base: Dictionary = prop["variantes"][0]
	var ests := g.estaciones_de(base["trazado"])
	var igual := g.variante_modificada(base, ests, 0.0, 0.0)
	_check(absf(float(igual["costo_musd"]) - float(base["costo_musd"])) <= 10.0, "sin cambios el costo debe coincidir con la base")
	var rapido := g.variante_modificada(base, ests, 1.0, 0.0)
	_check(float(rapido["costo_musd"]) > float(igual["costo_musd"]) and float(rapido["plazo_anios"]) < float(igual["plazo_anios"]), "ritmo alto: más caro y más corto")
	var ancho := g.variante_modificada(base, ests, 0.0, 1.0)
	_check(int(ancho["poblacion_miles"]) > int(igual["poblacion_miles"]) and int(ancho["expropiaciones"]) > int(igual["expropiaciones"]), "cobertura alta: más población y más expropiaciones")
	_check(not g.advertencias(rapido, prop).is_empty(), "el Corrector siempre responde algo")
	_check(not g.estaciones_validas(["n00", "n01"]), "se exigen al menos 3 estaciones")
	# En partida: aprobar un trazado propio y reproducirlo desde el guardado.
	var resp: Array[Dictionary] = [datos["ideologia"]["preguntas"][0]["opciones"][1]]
	var partido := GeneradorPartido.construir_partido("Test", "TST", "metropolitana", resp, datos["ideologia"])
	var m := Partida.crear(datos, 99, partido)
	m.estado.etapa = "gobierno"
	m.estado.propuestas_abiertas.append(String(prop["id"]))
	m.estado.pa_actual = 8
	var custom := {"base": "B", "estaciones": ["n11", "n33", "n55", "n77"], "ritmo": 0.5, "cobertura": 0.25}
	var r := m.aprobar_propuesta(String(prop["id"]), "B", "", custom)
	_check(bool(r["ok"]), "no se pudo aprobar el trazado propio: %s" % r)
	_check(m.estado.obras_en_curso.size() == 1 and String(m.estado.obras_en_curso[0]["variante"]) == "M", "debe iniciarse una obra con la variante propia")
	var malo := m.aprobar_propuesta(String(prop["id"]), "B", "", {"base": "B", "estaciones": ["n11"]})
	_check(not bool(malo["ok"]), "un trazado inválido debe rechazarse")
	# El guardado serializa el trazado propio como JSON: un estado idéntico debe dar la misma obra y la misma huella.
	var custom_json: Dictionary = JSON.parse_string(JSON.stringify(custom))
	var m2 := Partida.crear(datos, 99, partido)
	m2.estado.etapa = "gobierno"
	m2.estado.propuestas_abiertas.append(String(prop["id"]))
	m2.estado.pa_actual = 8
	m2.aprobar_propuesta(String(prop["id"]), "B", "", custom_json)
	_check(m2.estado.obras_en_curso[0]["dias_totales"] == m.estado.obras_en_curso[0]["dias_totales"], "el trazado serializado debe dar la misma obra")
	m2.aprobar_propuesta(String(prop["id"]), "B", "", {"base": "B", "estaciones": ["n11"]})
	_check(m2.estado.calcular_huella() == m.estado.calcular_huella(), "misma entrada, misma huella")
	if _fallos == 0:
		print("GRAFO OK (Dijkstra óptimo, sliders y trazado propio reproducible)")
	quit(0 if _fallos == 0 else 1)
