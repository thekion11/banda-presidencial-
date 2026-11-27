extends SceneTree
## Contrato de las 16 cartas `plan_*` del Plan Estratégico (docs/PLAN_ESTRATEGICO_CARTAS.md; decisión del usuario del 27-nov-2026): esquema, tipo de ley
## coherente con su quórum, reformas constitucionales con la fracción 4/7, categorías con ministro, fuente registrada, cifras ilustrativas rotuladas,
## costos 2–3, efectos sobre indicadores válidos, y que NO sean trivialmente dominantes (su efecto inmediato esperado más el riesgo y el diferido no
## deja un beneficio neto desmedido) ni inalcanzables (se votan y aprueban con una coalición razonable; ver tests/analisis_plan.gd para la medición).

var _fallos := 0
const IND := ["aprobacion", "capital", "cohesion", "fiscal", "riesgo_ejecucion", "viviendas_anio"]


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _valor(efectos: Array) -> float:
	## Valor simple de un conjunto de efectos: suma de aprobación, fiscal, capital y cohesión (el riesgo de ejecución resta; las viviendas no cuentan).
	var v := 0.0
	for e in efectos:
		var d := float(e["delta"])
		match String(e["ind"]):
			"aprobacion", "fiscal", "capital", "cohesion":
				v += d
			"riesgo_ejecucion":
				v -= d
	return v


func _init() -> void:
	var datos := Datos.cargar_todo()
	var cartas: Array = datos["cartas"].filter(func(c: Dictionary) -> bool: return String(c["id"]).begins_with("plan_"))
	_check(cartas.size() == 16, "debe haber 16 cartas plan_* (hay %d)" % cartas.size())
	var tipos := {}
	for t in datos["leyes"]["tipos_ley"]:
		tipos[String(t["id"])] = t
	var cats := {}
	for m in datos["ministros"]:
		cats[String(m["categoria_afin"])] = true
	var fuentes := {}
	for f in datos["fuentes"]:
		fuentes[String(f["id"])] = true
	_check(fuentes.has("plan_usuario_2026"), "la fuente plan_usuario_2026 está en data/fuentes.json")
	var ids := {}
	for c in cartas:
		var id := String(c["id"])
		_check(not ids.has(id), id + ": id repetido")
		ids[id] = true
		var ley := String(c["requisitos"]["ley"])
		_check(tipos.has(ley), "%s: tipo de ley «%s» inexistente" % [id, ley])
		_check(String(c["requisitos"]["quorum"]) == ley, "%s: el quórum difiere de la ley" % id)
		if tipos.has(ley):
			if ley == "reforma_constitucional":
				var fr: Dictionary = tipos[ley].get("fraccion", {})
				_check(int(fr.get("num", 0)) == 4 and int(fr.get("den", 0)) == 7, "%s: la reforma constitucional exige 4/7" % id)
		_check(cats.has(String(c["categoria"])), "%s: categoría «%s» sin ministro" % [id, c["categoria"]])
		_check(int(c["costo_pa"]) >= 2 and int(c["costo_pa"]) <= 3, "%s: costo %d fuera de 2–3" % [id, int(c["costo_pa"])])
		_check(bool(c.get("cifras_ilustrativas", false)), id + ": sin rótulo de cifras ilustrativas")
		_check(String(c.get("fuente", "")).begins_with("fuentes.json#") and fuentes.has(String(c["fuente"]).get_slice("#", 1)), "%s: fuente no registrada (%s)" % [id, c.get("fuente", "")])
		_check(c["efectos"].size() >= 2, id + ": efectos inmediatos incompletos")
		for e in c["efectos"] + c["riesgo"]["efectos"] + c["diferido"]["efectos"]:
			_check(IND.has(String(e["ind"])), "%s: indicador «%s» inválido" % [id, e["ind"]])
			_check(absf(float(e["delta"])) <= (5000.0 if e["ind"] == "viviendas_anio" else 6.0), "%s: efecto %s %.1f desmedido" % [id, e["ind"], float(e["delta"])])
		var p := float(c["riesgo"]["prob"])
		_check(p >= 0.3 and p <= 0.6, "%s: riesgo %.2f fuera de 0,3–0,6" % [id, p])
		_check(int(c["diferido"]["semanas"]) >= 26 and int(c["diferido"]["semanas"]) <= 104, "%s: diferido a %d semanas" % [id, int(c["diferido"]["semanas"])])
		# no trivialmente dominante: valor neto esperado acotado (inmediato + p·riesgo + diferido)
		var neto := _valor(c["efectos"]) + p * _valor(c["riesgo"]["efectos"]) + _valor(c["diferido"]["efectos"])
		_check(neto <= 4.0, "%s: valor neto esperado %.1f demasiado alto (carta de «siempre jugar»)" % [id, neto])
		_check(neto >= -8.0, "%s: valor neto esperado %.1f demasiado bajo (carta que nunca conviene)" % [id, neto])
		_check(_valor(c["efectos"]) <= 1.0, "%s: el efecto inmediato no debe ser un beneficio neto (%.1f)" % [id, _valor(c["efectos"])])
	# los tipos de reforma constitucional del plan son exactamente los previstos
	var reformas := cartas.filter(func(c: Dictionary) -> bool: return String(c["requisitos"]["ley"]) == "reforma_constitucional").map(func(c: Dictionary) -> String: return String(c["id"]))
	reformas.sort()
	_check(reformas == ["plan_afp_estatal", "plan_coeva", "plan_fondo_regla"], "las reformas constitucionales del plan son afp_estatal, coeva y fondo_regla (hay %s)" % str(reformas))
	if _fallos == 0:
		print("test_plan_cartas: OK (%d cartas)" % cartas.size())
	quit(1 if _fallos > 0 else 0)
