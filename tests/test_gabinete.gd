extends SceneTree
## Gabinete, disponibilidad de cartas y mano continua (DISENO_V2 §1-4).

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO GABINETE: ", msg)


func _init() -> void:
	var datos := Datos.cargar_todo()
	var tam := int(datos["leyes"]["gabinete"]["tamano"])
	var motor := AyudaV2.gobierno(datos, 11)
	var est := motor.estado
	_check(est.gabinete.size() == tam, "gabinete por defecto con el tamaño de leyes.json")
	_check(est.mano.size() == int(datos["leyes"]["mano"]["tamano"]) and est.mano.size() == 5, "mano inicial de 5 cartas")
	_check(est.pa_maximo == 5 and est.pa_actual == 5 + int(est.bono_mov["aprobacion"]), "5 movimientos base por turno (más el bono por aprobación)")
	_check(est.mano.all(func(c: Dictionary) -> bool: return motor.carta_disponible(c)), "la mano solo tiene cartas disponibles")
	for c in datos["cartas"]:
		var costo := motor.costo_carta(c)
		_check(costo >= 1 and costo <= 3, "costo 1..3: %s" % c["id"])
	# elegir gabinete: tamaño, ministros inválidos y límite de cambio
	_check(not bool(motor.elegir_gabinete(["min_salud"])["ok"]), "gabinete de tamaño incorrecto rechazado")
	var malo := AyudaV2.ministros_de(datos, ["salud"], tam)
	malo[1] = malo[0]
	_check(String(motor.elegir_gabinete(malo)["razon"]) == "ministro_invalido", "ministros repetidos rechazados")
	var cats_gab := {}
	var ids := AyudaV2.ministros_de(datos, ["salud", "social"], tam)
	_check(ids.size() == tam, "ayuda de prueba arma el gabinete completo")
	var r := motor.elegir_gabinete(ids)
	_check(bool(r["ok"]), "gabinete válido aceptado")
	for id in est.gabinete:
		cats_gab[String(motor.catalogo_ministros[id]["categoria_afin"])] = true
	_check(est.mano.size() == 5, "la mano se rellena tras cambiar el gabinete")
	for c in est.mano:
		var cat := String(c["categoria"])
		_check(cats_gab.has(cat) or cat in ["politica", "comite", "estado"] or cat == "descentralizacion", "carta %s solo si hay ministro afín" % c["id"])
	# disponibilidad: categoría, año, evento, fiscal_min y meta
	var sinteticas: Array = [
		AyudaV2.carta_sintetica("t_anio2", "politica", {"anio_desde": 2, "anio_hasta": 3}),
		AyudaV2.carta_sintetica("t_evento", "politica", {"evento": "evt_x"}),
		AyudaV2.carta_sintetica("t_fiscal", "politica", {"fiscal_min": 80.0}),
		AyudaV2.carta_sintetica("t_meta", "politica", {"meta": "meta_politica_1"}),
		AyudaV2.carta_sintetica("t_nogab", "vivienda", {}),
	]
	var m2 := AyudaV2.gobierno(datos, 12, sinteticas)
	var e2 := m2.estado
	e2.gabinete.assign(["min_interior"])
	var c_anio: Dictionary = m2._cartas_por_id["t_anio2"]
	_check(not m2.carta_disponible(c_anio), "año 1: carta desde año 2 no disponible")
	e2.turno_actual = 1 + 365 / e2.dias_por_turno + 1
	_check(m2.gabinete.anio_gobierno() == 2 and m2.carta_disponible(c_anio), "año 2: carta disponible")
	e2.turno_actual = 1 + 3 * 365 / e2.dias_por_turno + 1
	_check(m2.gabinete.anio_gobierno() == 4 and not m2.carta_disponible(c_anio), "año 4: pasó anio_hasta")
	e2.turno_actual = 1
	_check(not m2.carta_disponible(m2._cartas_por_id["t_evento"]), "evento sin ocurrir: no disponible")
	e2.eventos_ocurridos["evt_x"] = 1
	_check(m2.carta_disponible(m2._cartas_por_id["t_evento"]), "evento ocurrido: disponible")
	e2.indicadores["fiscal"] = 50.0
	_check(not m2.carta_disponible(m2._cartas_por_id["t_fiscal"]), "fiscal bajo: no disponible")
	e2.indicadores["fiscal"] = 85.0
	_check(m2.carta_disponible(m2._cartas_por_id["t_fiscal"]), "fiscal sobre el mínimo: disponible")
	_check(not m2.carta_disponible(m2._cartas_por_id["t_meta"]), "meta sin cumplir: no disponible")
	e2.metas_cumplidas["meta_politica_1"] = 1
	_check(m2.carta_disponible(m2._cartas_por_id["t_meta"]), "meta cumplida: disponible")
	_check(not m2.carta_disponible(m2._cartas_por_id["t_nogab"]), "sin ministro de vivienda: carta no disponible")
	# el mazo no reparte cartas no disponibles a lo largo de un mandato
	var m3 := AyudaV2.gobierno(datos, 13, sinteticas)
	m3.estado.gabinete.assign(AyudaV2.ministros_de(datos, ["salud", "transportes", "obras"], tam))
	m3.mazo.refiltrar_mano()  # igual que gabinete.elegir: la mano se ajusta al cambiar el gabinete
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var malas := 0
	for _t in range(60):
		Bots.jugar_turno(m3, "codicioso", rng)
		for c in m3.estado.mano:
			if not m3.carta_disponible(c):
				malas += 1
		m3.terminar_turno()
	_check(malas == 0, "el mazo solo reparte cartas disponibles (%d inválidas)" % malas)
	# mano continua: jugar una carta rellena la mano al instante
	var m4 := AyudaV2.gobierno(datos, 14)
	var antes := m4.estado.mano.size()
	var jugada := false
	for i in range(m4.estado.mano.size()):
		if bool(m4.jugar_carta(i)["ok"]):
			jugada = true
			break
	_check(jugada and m4.estado.mano.size() == antes, "mano continua: entra otra carta al jugar")
	# PR-05: rellenar no pisa lo escogido, completa el tamaño, es determinista y no repite
	var m5 := AyudaV2.gobierno(datos, 15)
	var ids5: Array = m5.catalogo_ministros.keys()
	var elegidos5: Array = [ids5[3], ids5[7]]
	for modo in ["equilibrado", "eficaz"]:
		var r1 := m5.gabinete.rellenar(elegidos5, modo)
		var r2 := m5.gabinete.rellenar(elegidos5, modo)
		var todos: Array = elegidos5.duplicate()
		for n in r1:
			todos.append(String(n["id"]))
		_check(todos.size() == tam and _sin_repetidos(todos), "rellenar (%s) completa %d sin repetir" % [modo, tam])
		_check(r1 == r2, "rellenar (%s) es determinista" % modo)
		_check(bool(m5.gabinete.elegir(todos)["ok"]), "el gabinete rellenado es válido")
	_check(m5.gabinete.rellenar(elegidos5.duplicate() + ids5.filter(func(i: String) -> bool: return not elegidos5.has(i)).slice(0, tam - 2)).is_empty(), "gabinete completo: nada que rellenar")
	print("GABINETE OK (gabinete %d ministros, mano continua, disponibilidad)" % tam if _fallos == 0 else "GABINETE FALLÓ")
	quit(1 if _fallos > 0 else 0)


func _sin_repetidos(a: Array) -> bool:
	var vistos := {}
	for x in a:
		if vistos.has(x):
			return false
		vistos[x] = true
	return true
