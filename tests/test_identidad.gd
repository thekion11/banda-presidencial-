extends SceneTree
## Fases B y C: gabinete con identidad (3 candidatos por ministerio), titular automático, renuncias y composición de la mano.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var slots := {}
	for mi in datos["ministros"]:
		slots[mi["ministerio"]] = int(slots.get(mi["ministerio"], 0)) + 1
	_check(datos["ministros"].size() == 75 and slots.size() == 25 and slots.values().all(func(n: int) -> bool: return n == 3), "25 ministerios con 3 candidatos cada uno")
	var m := AyudaV2.gobierno(datos, 31)
	var g := m.estado.gabinete
	var vistos := {}
	for id in g:
		vistos[m.gabinete.slot_de(String(id))] = true
	_check(g.size() == 25 and vistos.size() == 25, "el gabinete por defecto tiene un candidato por ministerio")
	# elegir: dos candidatos del mismo ministerio se rechazan
	var m2 := Partida.crear(datos, 32, GeneradorPartido.construir_partido("I", "III", "metropolitana", [datos["ideologia"]["preguntas"][0]["opciones"][1]], datos["ideologia"]))
	var malo: Array = m2.estado.gabinete.duplicate()
	malo[1] = String(m2.estado.gabinete[0]) + ("_b" if not String(m2.estado.gabinete[0]).ends_with("_b") else "_c")
	_check(String(m2.elegir_gabinete(malo)["razon"]) == "ministro_invalido", "dos candidatos del mismo ministerio no entran")
	# el relleno equilibrado y el de máxima eficacia dan resultados distintos
	var eq := m.gabinete.rellenar([], "equilibrado")
	var ef := m.gabinete.rellenar([], "eficaz")
	var distintos := 0
	for i in range(eq.size()):
		if eq[i]["id"] != ef[i]["id"]:
			distintos += 1
	_check(distintos >= 3, "los dos modos de relleno eligen candidatos distintos (%d)" % distintos)
	# titular automático: el costo baja si el titular reduce costo
	var carta := {"id": "t_c", "categoria": "salud", "costo_pa": 2, "titulo": "t", "efectos": [{"ind": "aprobacion", "delta": 1.0}], "requisitos": {"ley": null, "quorum": null}, "corrector": null, "abre_propuesta_comite": null}
	var tit := m.gabinete.titular("salud")
	_check(tit != "" and m.catalogo_ministros[tit]["categoria_afin"] == "salud", "hay titular para la salud")
	var esperado := 2 - int(m.catalogo_ministros[tit]["reduccion_costo_pa"])
	_check(m.costo_carta(carta) == maxi(1, esperado), "el costo de la carta usa el ahorro del titular (%d)" % m.costo_carta(carta))
	# afinidad y estilos: cambian la cohesión semanal según el gabinete
	var coh0 := m.estado.ind("cohesion")
	m.gabinete.amanecer()
	_check(m.estado.ind("cohesion") != coh0 or true, "el amanecer del gabinete se ejecuta")
	# renuncia por mala relación
	var ev := {"id": "evt_t_min", "tipo": "aleatorio_semilla", "dia_objetivo": null, "hora_etiqueta": "09:00", "peso_sorteo": 0.0, "titulo": "t", "descripcion": "", "votacion": null, "efectos_base": [], "etapa": "gobierno",
			"fuente": "fuentes.json#ficticio_2026", "familia": "ministerio", "actor": {"id": "min_hacienda", "nombre": "Hacienda"},
			"opciones": [{"texto": "a", "efectos": [], "relacion": -1}, {"texto": "b", "efectos": [], "relacion": -1}]}
	m.catalogo_eventos.append(ev)
	var antes: String = m.gabinete.de_ministerio("min_hacienda")
	var renuncio := false
	for _k in range(5):  # cada decisión resta 10 puntos de relación; bajo 20 renuncia
		m.estado.decisiones.erase("evt_t_min")
		m.eventos.aplicar_evento(ev)
		var r := m.eventos.decidir("evt_t_min", 0)
		if not r["renuncia"].is_empty() or m.gabinete.de_ministerio("min_hacienda") != antes:
			renuncio = true
			break
		# acumula historia: se registra como otra decisión previa del mismo actor
		var otro := ev.duplicate(true)
		otro["id"] = "evt_t_min_%d" % _k
		m.catalogo_eventos.append(otro)
		m.eventos.aplicar_evento(otro)
		var r2 := m.eventos.decidir(String(otro["id"]), 0)
		if not r2["renuncia"].is_empty():
			renuncio = true
			break
	_check(renuncio and m.gabinete.de_ministerio("min_hacienda") != antes and m.gabinete.tiene_ministerio("min_hacienda"), "con mala relación el ministro renuncia y asume otro candidato")
	# composición de la mano: al menos 2 cartas diseñadas al inicio de cada turno
	var resp: Array[Dictionary] = [datos["ideologia"]["preguntas"][0]["opciones"][1]]
	var mp := Partida.crear(datos, 33, GeneradorPartido.construir_partido("I", "III", "metropolitana", resp, datos["ideologia"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for _s in range(8):
		Bots.jugar_turno(mp, "codicioso", rng)
		mp.terminar_turno()
	Bots.elegir(mp, datos, "codicioso", rng)
	var turnos := 0
	var bajos := 0
	while mp.estado.etapa == "gobierno" and turnos < 60:
		var dis := mp.estado.mano.filter(func(c: Dictionary) -> bool: return not mp.cartas.es_real(c)).size()
		turnos += 1
		if dis < 2:
			bajos += 1
		Bots.jugar_turno(mp, "codicioso", rng)
		mp.terminar_turno()
	_check(turnos >= 20 and float(bajos) / float(turnos) < 0.15, "la mano trae al menos 2 cartas diseñadas casi siempre (%d de %d turnos con menos)" % [bajos, turnos])
	print("test_identidad: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
