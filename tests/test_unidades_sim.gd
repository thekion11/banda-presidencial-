extends SceneTree
## Pruebas unitarias directas de Regiones, MotorEfectos, IndicesCartas, MotorCartas.descartar_mano y MotorCartas.resolver_proyectos.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _cerca(a: float, b: float, tol: float = 0.0001) -> bool:
	return absf(a - b) <= tol


func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("Unidades", "UNI", "metropolitana", resp, datos["ideologia"])
	var m := Partida.crear(datos, 8, partido)
	var est := m.estado
	_regiones(m, datos)
	_efectos(m, datos)
	_indices(datos)
	_mano(m, datos)
	_check(_proyectos(datos, partido), "la prueba de proyectos de ley llegó al gobierno y encontró una ley simple")
	print("test_unidades_sim: ", "OK" if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)


func _regiones(m: MotorTurno, datos: Dictionary) -> void:
	var r: Regiones = m.regiones
	var est := m.estado
	var total := 0.0
	for id in r.pesos:
		total += float(r.pesos[id])
	_check(_cerca(total, 1.0), "los pesos regionales suman 1 (%f)" % total)
	_check(r.existe(String(datos["regiones"][0]["id"])) and not r.existe("no_existe"), "existe()")
	var vacio := Regiones.new()
	vacio.cargar([])
	_check(vacio.pesos.is_empty(), "sin regiones no hay pesos")
	# inicializar: bastión suma el bono y todo queda en 0..100; el promedio es el ponderado
	r.inicializar(est, 50.0, "metropolitana", 10.0, 0.0)
	_check(_cerca(float(est.aprobacion_regional["metropolitana"]), 60.0), "bastión: +bono")
	_check(est.aprobacion_regional.values().all(func(v: float) -> bool: return v >= 0.0 and v <= 100.0), "aprobación regional dentro de 0..100")
	var prom := 0.0
	for id in r.pesos:
		prom += float(est.aprobacion_regional[id]) * float(r.pesos[id])
	_check(_cerca(r.promedio(est), prom) and _cerca(est.ind("aprobacion"), prom), "el promedio es el ponderado por población")
	# aplicar_delta con región: ella recibe todo, las demás el derrame
	r.inicializar(est, 50.0, "", 0.0, 0.0)
	var otra := String(datos["regiones"][1]["id"])
	var obj := String(datos["regiones"][0]["id"])
	r.aplicar_delta(est, 10.0, obj, 0.25)
	_check(_cerca(float(est.aprobacion_regional[obj]), 60.0) and _cerca(float(est.aprobacion_regional[otra]), 52.5), "delta completo en la región objetivo y derrame en el resto")
	r.aplicar_delta(est, 1000.0, "", 0.0)
	_check(_cerca(est.ind("aprobacion"), 100.0), "tope 100 por región y en el promedio")
	r.aplicar_delta(est, -1000.0, "", 0.0)
	_check(_cerca(est.ind("aprobacion"), m.piso.nacional()), "la aprobación cae solo hasta el piso ideológico (0 sin partido)")
	# revertir tira hacia el ancla; revertir_a_base hacia la base
	r.inicializar(est, 80.0, "", 0.0, 0.0)
	r.revertir(est, 40.0, 0.5)
	_check(_cerca(est.ind("aprobacion"), 60.0), "revertir con tasa 0,5 hacia el ancla (%f)" % est.ind("aprobacion"))
	r.revertir_a_base(est, 1.0)
	_check(_cerca(est.ind("aprobacion"), 80.0), "revertir_a_base con tasa 1 vuelve a la base")


func _efectos(m: MotorTurno, datos: Dictionary) -> void:
	var fx: MotorEfectos = m.fx
	var est := m.estado
	var lim: Dictionary = datos["leyes"]["limites_indicadores"]
	est.indicadores["capital"] = 50.0
	fx.sumar_ind("capital", 1000.0)
	_check(_cerca(est.ind("capital"), float(lim["max"])), "sumar_ind respeta el máximo")
	fx.sumar_ind("capital", -1000.0)
	_check(_cerca(est.ind("capital"), float(lim["min"])), "sumar_ind respeta el mínimo")
	fx.sumar_ind("viviendas_anio", 1.0e7)
	_check(_cerca(est.ind("viviendas_anio"), float(lim["viviendas_anio_max"])), "viviendas_anio tiene su propio máximo")
	m.regiones.inicializar(est, 30.0, "", 0.0, 0.0)
	fx.delta_aprobacion(10.0, "", true)
	var ganancia := est.ind("aprobacion") - 30.0
	m.regiones.inicializar(est, 80.0, "", 0.0, 0.0)
	fx.delta_aprobacion(10.0, "", true)
	_check(ganancia > est.ind("aprobacion") - 80.0 and est.ind("aprobacion") - 80.0 > 0.0, "rendimientos decrecientes: subir con aprobación alta rinde menos pero sube")
	m.regiones.inicializar(est, 80.0, "", 0.0, 0.0)
	fx.delta_aprobacion(-10.0, "", true)
	_check(_cerca(est.ind("aprobacion"), 70.0), "las caídas no tienen rendimiento decreciente")
	est.indicadores["fiscal"] = 50.0
	fx.aplicar_efecto({"ind": "fiscal", "delta": 8.0}, 0.5, "")
	_check(_cerca(est.ind("fiscal"), 54.0), "aplicar_efecto escala el delta")
	est.promesas_campana = [{"carta_id": "x", "cumplida": false}, {"carta_id": "x", "cumplida": false}]
	fx.marcar_cumplida("x")
	_check(est.promesas_campana[0]["cumplida"] and not est.promesas_campana[1]["cumplida"], "marcar_cumplida marca solo una promesa pendiente")


func _indices(datos: Dictionary) -> void:
	var cartas: Array = datos["cartas"]
	var x := IndicesCartas.construir(cartas)
	_check(x.n == cartas.size() and x.por_id.size() == cartas.size(), "índice por id completo")
	_check(x.reales.size() + x.no_reales.size() == cartas.size(), "reales + no reales = total")
	_check(x.r_ids.size() == x.reales.size() and x.r_cat.size() == x.reales.size() and x.r_cond.size() == x.reales.size(), "arrays paralelos de reales del mismo largo")
	for c in x.reales:
		_check(x.es_real[c["id"]] and IndicesCartas.tipo_real(c), "carta real marcada")
		break
	_check(IndicesCartas.clave(3.0) == "3" and IndicesCartas.clave(3) == "3" and IndicesCartas.clave(2.5) == "2.5" and IndicesCartas.clave("a") == "a", "clave normaliza enteros float")
	_check(not IndicesCartas.tipo_real({"id": "z"}) and not IndicesCartas.tipo_real({"meta": {"tipo": "otro"}}), "tipo_real falso sin meta o con otro tipo")
	var rep := IndicesCartas.construir(cartas)
	_check(rep.n == x.n and rep.reales.size() == x.reales.size(), "construir es determinista")


func _mano(m: MotorTurno, datos: Dictionary) -> void:
	var est := m.estado
	var por_turno := int(datos["leyes"]["mano"].get("descartes_por_turno", 0))
	var antes := est.mano.size()
	var primera := String(est.mano[0]["id"])
	var d0 := est.descarte.size()
	m.cartas.descartar_mano()
	var n := mini(por_turno, antes)
	_check(est.mano.size() == antes - n and est.descarte.size() == d0 + n, "descartar_mano quita las %d más antiguas" % n)
	if n > 0:
		_check(est.descarte[d0] == primera, "la más antigua va primero al descarte")


func _proyectos(datos: Dictionary, partido: Dictionary) -> bool:
	# una ley en trámite aún no vota; vencido su día, se vota y sale de la lista con su registro
	var m: MotorTurno = null
	for semilla in range(9, 30):
		m = Partida.crear(datos, semilla, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		if Bots.elegir(m, datos, "codicioso", rng):
			break
	if m.estado.etapa != "gobierno":
		return false
	var est := m.estado
	var carta: Dictionary = {}
	for c in datos["cartas"]:
		if c["requisitos"]["ley"] == "ley_simple":
			carta = c
			break
	if carta.is_empty():
		return false
	var tipo := String(carta["requisitos"]["ley"])
	est.proyectos_ley = [{"carta_id": carta["id"], "tipo_ley": tipo, "dia_votacion": est.dia_actual + 1000, "escala": 1.0, "region": ""}]
	_check(m.cartas.resolver_proyectos().is_empty() and est.proyectos_ley.size() == 1, "un proyecto con votación lejana sigue pendiente")
	est.proyectos_ley = [{"carta_id": carta["id"], "tipo_ley": tipo, "dia_votacion": est.dia_actual, "escala": 1.0, "region": ""}]
	var votadas := m.cartas.resolver_proyectos()
	_check(votadas.size() == 1 and est.proyectos_ley.is_empty(), "un proyecto vencido se vota y sale de la lista")
	_check(votadas[0].has("aprobada") and votadas[0].has("voto") and votadas[0].has("tc"), "el resultado trae voto y TC")
	_check(est.registro_acciones.back()["tipo"] == "votacion", "la votación queda en el registro")
	return true
