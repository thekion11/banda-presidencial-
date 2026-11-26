extends SceneTree
## Candados contra los mutantes que sobrevivían en la pasada de tools/mutar.py (26-nov-2026): montículo del grafo, ventana de 52 semanas de decisiones,
## primera ley única en los hitos, propuesta con movimientos exactos y días de la carrera al continuar tras una crisis o un fin de mandato.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _partido(datos: Dictionary) -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	return GeneradorPartido.construir_partido("Mutantes2", "MU2", "metropolitana", resp, datos["ideologia"])


func _gobierno(datos: Dictionary) -> MotorTurno:
	for semilla in range(1300, 1360):
		var m := Partida.crear(datos, semilla, _partido(datos))
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		if Bots.elegir(m, datos, "codicioso", rng):
			return m
	return null


func _init() -> void:
	var datos := Datos.cargar_todo()
	# 1) montículo del grafo: lo que entra sale ordenado (con empates por orden de llegada), sea cual sea el número de hijos
	var g := GrafoTrazado.new()
	var cola: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in range(300):
		g._push(cola, [float(rng.randi_range(0, 40)), i, "n%d" % i])
	var previo := -1.0
	var prev_seq := -1
	var ordenado := true
	while not cola.is_empty():
		var it: Array = g._pop(cola)
		if float(it[0]) < previo or (float(it[0]) == previo and int(it[1]) < prev_seq):
			ordenado = false
		previo = float(it[0])
		prev_seq = int(it[1])
	_check(ordenado, "el montículo del grafo devuelve los elementos en orden")
	var m := _gobierno(datos)
	_check(m != null, "se llegó al gobierno")
	if m == null:
		quit(1)
		return
	var est := m.estado
	# 2) decisiones del último año: la de hace 51 semanas cuenta, la de hace exactamente 52 no
	var ahora := m.eventos.semana_abs()
	m.eventos.director._dec_sem = {"a": ahora - 51, "b": ahora - 52, "c": ahora - 10}
	_check(m.eventos.director._decisiones_ultimo_anio(ahora) == 2, "ventana de 52 semanas: cuentan las de hace 51 y 10, no la de hace 52 (%d)" % m.eventos.director._decisiones_ultimo_anio(ahora))
	# 3) los hitos nombran la primera ley aprobada una sola vez, aunque haya varias aprobadas
	est.registro_acciones.append({"turno": 1, "dia": 1, "etapa": "gobierno", "tipo": "votacion", "detalle": {"aprobada": false, "carta": "x"}})
	est.registro_acciones.append({"turno": 2, "dia": 8, "etapa": "gobierno", "tipo": "votacion", "detalle": {"aprobada": true, "carta": "x"}})
	est.registro_acciones.append({"turno": 3, "dia": 15, "etapa": "gobierno", "tipo": "votacion", "detalle": {"aprobada": true, "carta": "y"}})
	est.registro_acciones.append({"turno": 4, "dia": 22, "etapa": "gobierno", "tipo": "votacion", "detalle": {"aprobada": false, "carta": "z"}})
	var primeras := 0
	for h in m.mandato.hitos(50):
		if String(h["texto"]).begins_with("Primera ley aprobada"):
			primeras += 1
	_check(primeras == 1, "los hitos mencionan «Primera ley aprobada» una sola vez (%d)" % primeras)
	# 4) una propuesta cuyo costo es exactamente los movimientos disponibles se puede aprobar
	var pid := String(datos["propuestas"][0]["id"])
	est.propuestas_abiertas.append(pid)
	est.pa_actual = int(datos["propuestas"][0]["costo_pa"])
	var r := m.aprobar_propuesta(pid, "A")
	_check(String(r.get("razon", "")) != "pa_insuficiente", "con los movimientos justos la propuesta no se rechaza por falta de ellos (%s)" % str(r))
	# 5) al continuar tras una crisis o un fin de mandato, los días de la carrera suman los turnos efectivamente jugados
	var dpt := m.estado.dias_por_turno
	var g1 := _gobierno(datos)
	g1.estado.turno_actual = 10
	g1.estado.etapa = "fin_mandato"
	g1.estado.resultado_final = {"motivo": "fin_mandato", "puntaje": 0}
	var base1 := g1.estado.dias_carrera
	g1.mandato.continuar_carrera()
	_check(g1.estado.dias_carrera == base1 + 9 * dpt, "fin de mandato en el turno 10: suma 9 semanas (%d)" % (g1.estado.dias_carrera - base1))
	var g2 := _gobierno(datos)
	g2.estado.turno_actual = 10
	g2.estado.etapa = "crisis"
	g2.estado.resultado_final = {"motivo": "crisis", "puntaje": 0}
	var base2 := g2.estado.dias_carrera
	g2.mandato.continuar_carrera()
	_check(g2.estado.dias_carrera == base2 + 10 * dpt, "crisis en el turno 10: suma 10 semanas, la del turno en que cae también (%d)" % (g2.estado.dias_carrera - base2))
	print("test_mutantes_2: ", "OK" if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
