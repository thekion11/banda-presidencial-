extends SceneTree
## Fuzz del grafo de trazados del Comité (Fase 3) sobre el grafo real de Gran Santiago: entradas inválidas y valores extremos en Dijkstra, evaluar,
## variante_modificada y advertencias. Propiedades:
##  (1) ruta(a, b) empieza en a y termina en b, sin repetir nodos, y cada par consecutivo es una arista real;
##  (2) el coste de la ruta es simétrico (a->b y b->a) y cumple la desigualdad triangular;
##  (3) evaluar y variante_modificada dan números finitos y no negativos (también con estaciones repetidas, ids inexistentes, 0 o 1 estación, muchas estaciones);
##  (4) variante_modificada recorta ritmo y cobertura a [0, 1] (valores fuera de rango, negativos o enormes dan lo mismo que el extremo);
##  (5) más ritmo nunca baja el costo y mueve el plazo en el sentido de sliders.ritmo.plazo_max (hoy negativo: acorta el plazo); más cobertura nunca baja la
##      población ni las expropiaciones;
##  (6) advertencias siempre responde algo (nunca un «no» seco) y nodo_cercano devuelve un nodo existente para cualquier punto.
## Uso: godot --headless --path . -s tests/fuzz_grafo.gd -- [iteraciones] [semilla]

var _fallos: int = 0
var _datos: Dictionary
var _g: GrafoTrazado


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ GRAFO: ", msg)


func _peso(camino: Array) -> float:
	var s := 0.0
	for i in range(camino.size() - 1):
		var e := _g._arista(String(camino[i]), String(camino[i + 1]))
		_check(not e.is_empty(), "la ruta usa una arista inexistente (%s -> %s)" % [camino[i], camino[i + 1]])
		if not e.is_empty():
			s += float(e["peso"])
	return s


func _finitos(v: Dictionary, ctx: String) -> void:
	for k in ["costo_musd", "plazo_anios", "poblacion_miles", "expropiaciones"]:
		var x := float(v[k])
		_check(is_finite(x) and x >= 0.0, "%s: %s no es finito y no negativo (%s)" % [ctx, k, str(x)])
	for ef in v["efectos"]:
		_check(is_finite(float(ef["delta"])), "%s: efecto %s no finito" % [ctx, ef["ind"]])


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 40
	var semilla := int(args[1]) if args.size() > 1 else 4
	_datos = Datos.cargar_todo()
	_g = GrafoTrazado.new()
	_g.cargar(_datos["grafo"])
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var ids: Array = _g.orden.duplicate()
	var prop: Dictionary = _datos["propuestas"][0]
	var base: Dictionary = prop["variantes"][0]
	for it in range(n):
		# (1) y (2): rutas
		var a := String(ids[rng.randi_range(0, ids.size() - 1)])
		var b := String(ids[rng.randi_range(0, ids.size() - 1)])
		var c := String(ids[rng.randi_range(0, ids.size() - 1)])
		var rab: Array[String] = _g.ruta(a, b)
		var rba: Array[String] = _g.ruta(b, a)
		var rbc: Array[String] = _g.ruta(b, c)
		var rac: Array[String] = _g.ruta(a, c)
		if not rab.is_empty():
			_check(rab[0] == a and rab[rab.size() - 1] == b, "ruta %s->%s no empieza y termina en sus extremos" % [a, b])
			var vistos := {}
			for x in rab:
				_check(not vistos.has(x), "ruta %s->%s repite el nodo %s" % [a, b, x])
				vistos[x] = true
			var pab := _peso(rab)
			_check(absf(pab - _peso(rba)) < 0.0001 * maxf(1.0, pab), "el coste de %s->%s no es simétrico (%s contra %s)" % [a, b, str(pab), str(_peso(rba))])
			if not rbc.is_empty() and not rac.is_empty():
				_check(_peso(rac) <= pab + _peso(rbc) + 0.0001 * maxf(1.0, pab), "desigualdad triangular rota para %s, %s, %s" % [a, b, c])
		# (3), (4), (5): variantes con estaciones de todo tipo
		var ests: Array = []
		var tipo := rng.randi_range(0, 5)
		match tipo:
			0:
				ests = []
			1:
				ests = [a]
			2:
				ests = [a, a, b]  # repetidas
			3:
				ests = [a, "no_existe", b]
			4:
				for _k in range(rng.randi_range(8, 14)):
					ests.append(ids[rng.randi_range(0, ids.size() - 1)])
			5:
				for _k in range(rng.randi_range(3, 7)):
					ests.append(ids[rng.randi_range(0, ids.size() - 1)])
		var ctx := "iteración %d (tipo %d)" % [it, tipo]
		var r0 := rng.randf()
		var c0 := rng.randf()
		var v := _g.variante_modificada(base, ests, r0, c0)
		_finitos(v, ctx)
		var v_ext := _g.variante_modificada(base, ests, 1.0, 1.0)
		var v_fuera := _g.variante_modificada(base, ests, rng.randf_range(1.0, 1000.0), rng.randf_range(1.0, 1000.0))
		_check(v_ext["costo_musd"] == v_fuera["costo_musd"] and v_ext["poblacion_miles"] == v_fuera["poblacion_miles"], "%s: valores de slider por encima de 1 no se recortan" % ctx)
		var v_neg := _g.variante_modificada(base, ests, -rng.randf_range(0.1, 1000.0), -rng.randf_range(0.1, 1000.0))
		var v_cero := _g.variante_modificada(base, ests, 0.0, 0.0)
		_check(v_neg["costo_musd"] == v_cero["costo_musd"] and v_neg["expropiaciones"] == v_cero["expropiaciones"], "%s: sliders negativos no se recortan a 0" % ctx)
		var v_r := _g.variante_modificada(base, ests, 1.0, c0)
		var v_r0 := _g.variante_modificada(base, ests, 0.0, c0)
		var sl_ritmo: Dictionary = _g.params["sliders"]["ritmo"]
		_check(float(v_r["costo_musd"]) >= float(v_r0["costo_musd"]), "%s: más ritmo bajó el costo (%s contra %s)" % [ctx, str(v_r["costo_musd"]), str(v_r0["costo_musd"])])
		if float(sl_ritmo["plazo_max"]) <= 0.0:
			_check(float(v_r["plazo_anios"]) <= float(v_r0["plazo_anios"]), "%s: más ritmo alargó el plazo (%s contra %s) con plazo_max <= 0" % [ctx, str(v_r["plazo_anios"]), str(v_r0["plazo_anios"])])
		else:
			_check(float(v_r["plazo_anios"]) >= float(v_r0["plazo_anios"]), "%s: más ritmo acortó el plazo con plazo_max > 0" % ctx)
		var v_c := _g.variante_modificada(base, ests, r0, 1.0)
		var v_c0 := _g.variante_modificada(base, ests, r0, 0.0)
		_check(float(v_c["poblacion_miles"]) >= float(v_c0["poblacion_miles"]) and float(v_c["expropiaciones"]) >= float(v_c0["expropiaciones"]), "%s: más cobertura bajó la población o las expropiaciones" % ctx)
		# (6)
		_check(not _g.advertencias(v, prop).is_empty(), "%s: el Corrector no respondió nada" % ctx)
		var p := Vector2(rng.randf_range(-2.0, 3.0), rng.randf_range(-2.0, 3.0))
		_check(_g.pos.has(_g.nodo_cercano(p)), "%s: nodo_cercano(%s) no es un nodo existente" % [ctx, str(p)])
		_g.estaciones_validas(ests)  # no debe fallar con ninguna lista
	print("FUZZ GRAFO %s (%d iteraciones, %d nodos, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, ids.size(), _fallos])
	quit(1 if _fallos > 0 else 0)
