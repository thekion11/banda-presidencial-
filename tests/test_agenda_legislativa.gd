extends SceneTree
## Agenda legislativa (BM): catálogo, costos, urgencias, etapas con semanas reales, quórum, delegación, límites, corrector, determinismo y guardado a mitad de trámite.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO AGENDA: ", msg)


func _gobierno(datos: Dictionary, semilla: int) -> MotorTurno:
	## Partida real (campaña con el bot «codicioso», elección) hasta el primer turno de gobierno; null si pierde.
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla * 31 + 7
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][rng.randi_range(0, 2)])
	var partido := GeneradorPartido.construir_partido("Partido Prueba", "PRU", "metropolitana", resp, datos["ideologia"])
	partido["dificultad"] = "facil"
	var m := Partida.crear(datos, semilla, partido)
	for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	return m if Bots.elegir(m, datos, "codicioso", rng) else null


func _distintas(m: MotorTurno, n: int) -> Array[String]:
	var ids: Array[String] = []
	for e in m.agenda.agenda_catalogo():
		if ids.size() < n and not m.estado.cartas_ejecutadas.has(String(e["carta_id"])):
			ids.append(String(e["carta_id"]))
	return ids


func _init() -> void:
	var datos := Datos.cargar_todo()
	var cfg: Dictionary = datos["leyes"]["agenda"]
	_check(int(cfg["max_simultaneos"]) == 3 and cfg["urgencias"].size() == 3, "tres urgencias y máximo de 3 proyectos")
	var dias := {}
	for u in cfg["urgencias"]:
		dias[u["id"]] = int(u["dias"])
	_check(dias == {"simple": 30, "suma": 15, "inmediata": 6}, "urgencias reales: 30, 15 y 6 días")
	var m: MotorTurno = null
	for s in range(1, 12):
		m = _gobierno(datos, s)
		if m != null:
			break
	_check(m != null and m.estado.etapa == "gobierno", "se llegó al gobierno")
	if m == null:
		quit(1)
		return
	var est := m.estado
	var ag := m.agenda
	# --- catálogo
	var cat := ag.agenda_catalogo()
	_check(cat.size() > 20, "el catálogo ofrece leyes aunque no estén en la mano (%d)" % cat.size())
	var e0: Dictionary = cat[0]
	for k in ["carta_id", "titulo", "tipo_ley", "costo_mov", "urgencias", "corrector"]:
		_check(e0.has(k), "entrada del catálogo con «%s»" % k)
	_check(e0["urgencias"].size() == 3 and float(e0["urgencias"][0]["costo_capital"]) == 0.0 and float(e0["urgencias"][2]["costo_capital"]) > float(e0["urgencias"][1]["costo_capital"]), "costos de capital crecientes por urgencia")
	_check(int(e0["urgencias"][2]["semanas"]) < int(e0["urgencias"][0]["semanas"]), "la discusión inmediata acorta la tramitación")
	_check(float(e0["urgencias"][2]["prob"]) <= float(e0["urgencias"][0]["prob"]) + 0.0001, "la urgencia sube el riesgo (no mejora la probabilidad)")
	var plan := cat.filter(func(e: Dictionary) -> bool: return String(e["carta_id"]).begins_with("plan_"))
	print("cartas plan_* presentables: ", plan.size())
	_check(ag.agenda_catalogo("no_existe").is_empty(), "filtro por categoría")
	_check(not bool(ag.estado_agenda().is_empty()) and bool(ag.estado_agenda()["puede_presentar"]), "se puede presentar")
	# --- rechazos
	_check(String(ag.presentar("no_existe")["razon"]) == "carta_inexistente", "carta inexistente")
	_check(String(ag.presentar(String(e0["carta_id"]), "ultra")["razon"]) == "urgencia_invalida", "urgencia inválida")
	var sin_ley := String(m.catalogo_cartas.filter(func(c: Dictionary) -> bool: return c["requisitos"]["ley"] == null)[0]["id"])
	_check(String(ag.presentar(sin_ley)["razon"]) == "no_es_ley", "una carta sin ley no se presenta")
	# --- presentar: costo en movimientos, capital por urgencia, estado
	est.pa_actual = 10
	est.indicadores["capital"] = 50.0
	var ids := _distintas(m, 5)
	var carta: Dictionary = m._cartas_por_id[ids[0]]
	var costo := m.costo_carta(carta)
	var r := ag.presentar(ids[0], "suma")
	_check(bool(r["ok"]) and est.pa_actual == 10 - costo, "presentar cuesta los movimientos de la carta (%d)" % costo)
	_check(is_equal_approx(est.ind("capital"), 50.0 - float(cfg["urgencias"][1]["costo_capital"])) or est.ind("capital") < 50.0, "la urgencia suma cobra capital político")
	_check(est.agenda.size() == 1 and est.agenda[0]["etapa"] == "primer_tramite" and est.cartas_ejecutadas.has(ids[0]), "el proyecto queda en primer trámite")
	_check(String(ag.presentar(ids[0])["razon"]) == "ya_en_tramite", "no se presenta dos veces")
	var tr := ag.en_tramite()
	_check(tr.size() == 1 and tr[0].has("semanas_restantes") and tr[0].has("prob_aprobacion") and tr[0]["etapa_nombre"] == "Primer trámite", "en_tramite entrega etapa, semanas y probabilidad")
	# --- capital insuficiente con corrector (nunca un «no» seco)
	est.indicadores["capital"] = 1.0
	var rc := ag.presentar(ids[1], "inmediata")
	_check(String(rc["razon"]) == "capital_insuficiente" and rc["corrector"]["opciones"].size() >= 2, "sin capital: razón y opciones del corrector")
	_check(rc["corrector"]["opciones"].any(func(o: Dictionary) -> bool: return o["tipo"] == "urgencia" and o["urgencia"] == "simple"), "el corrector ofrece otra urgencia")
	est.indicadores["capital"] = 50.0
	# --- delegación: sin gastar movimientos, con tope de 2 por turno
	var pa := est.pa_actual
	var mins: Array = est.gabinete
	var rd := ag.presentar(ids[1], "simple", String(mins[0]), true)
	_check(bool(rd["ok"]) and est.pa_actual == pa and est.delegadas_turno == 1, "delegar no gasta movimientos")
	# --- límite de proyectos simultáneos
	if est.agenda.size() == 1:  # la delegación puede fallar o anularse según el azar de la semilla: se presenta a mano para llegar a dos
		ag.presentar(ids[1], "simple")
	var rl := ag.presentar(ids[2], "simple")
	_check(bool(rl["ok"]) and est.agenda.size() == 3, "tres proyectos simultáneos")
	_check(String(ag.presentar(ids[3])["razon"]) == "agenda_llena" and not bool(ag.estado_agenda()["puede_presentar"]), "el cuarto choca con el máximo de la agenda")
	# --- etapas con semanas reales: la urgencia inmediata es mucho más corta que la simple
	var semanas := {}
	for p in est.agenda.duplicate():
		semanas[String(p["carta_id"])] = 0
	var vistos: Array[String] = []
	for i in range(40):
		var antes := est.agenda.size()
		m.terminar_turno()
		for f in m.votaciones_semana:
			if bool(f.get("agenda", false)):
				vistos.append("%s:%s" % [f["carta_id"], f["aprobada"]])
		if est.agenda.is_empty():
			print("agenda resuelta en %d semanas: %s" % [i + 1, vistos])
			break
		_check(est.agenda.size() <= antes, "la agenda no crece sola")
	_check(est.agenda.is_empty() and vistos.size() == 3, "los tres proyectos se resolvieron (%s)" % str(vistos))
	for v in vistos:
		var id := v.split(":")[0]
		if v.ends_with("true"):
			_check(est.cartas_ejecutadas.has(id), "promulgado: la carta queda ejecutada")
		else:
			_check(not est.cartas_ejecutadas.has(id) and est.agenda_rechazos.has(id), "rechazado: entra en espera y puede volver a presentarse")
			est.pa_actual = 10
			_check(String(ag.presentar(id)["razon"]) == "en_espera_tras_rechazo", "cooldown tras un rechazo")
	# --- quórum: la reforma constitucional exige más que una ley simple
	var ps := m.legal.prob_aprobacion(est, "ley_simple")
	var pr := m.legal.prob_aprobacion(est, "reforma_constitucional")
	_check(float(pr["senado"]) <= float(ps["senado"]) and float(pr["camara"]) <= float(ps["camara"]), "reforma constitucional (4/7) no es más probable que ley simple")
	_check(float(m.legal.prob_aprobacion(est, "decreto_supremo")["senado"]) == 1.0, "un decreto no necesita votación")
	est.indicadores["capital"] = 0.0
	est.indicadores["cohesion"] = 0.0
	var reforma := m.catalogo_cartas.filter(func(c: Dictionary) -> bool: return c["requisitos"]["ley"] == "reforma_constitucional" and m.carta_disponible(c) and not est.cartas_ejecutadas.has(String(c["id"])))
	if not reforma.is_empty():
		est.pa_actual = 10
		var rq := ag.presentar(String(reforma[0]["id"]))
		_check(String(rq.get("razon", "")) == "quorum_insuficiente" and rq["corrector"]["opciones"].any(func(o: Dictionary) -> bool: return o["tipo"] == "esperar"), "sin apoyo: quórum insuficiente con corrector que ofrece esperar")
	# --- semanas reales por urgencia: discusión inmediata en pocas semanas, simple en muchas
	est.indicadores["capital"] = 90.0
	est.indicadores["cohesion"] = 90.0
	est.pa_actual = 10
	var j := _distintas(m, 8).filter(func(id: String) -> bool: return not est.agenda_rechazos.has(id))
	_check(bool(ag.presentar(j[0], "inmediata")["ok"]) and bool(ag.presentar(j[1], "simple")["ok"]), "una inmediata y una simple")
	var fin := {}
	for i in range(40):
		m.terminar_turno()
		for f in m.votaciones_semana:
			if bool(f.get("agenda", false)):
				fin[String(f["carta_id"])] = i + 1
		if est.agenda.is_empty():
			break
	_check(int(fin.get(j[0], 99)) <= 6 and int(fin.get(j[1], 0)) >= 8 and int(fin.get(j[0], 99)) < int(fin.get(j[1], 0)), "inmediata en %s semanas y simple en %s (real: 6 y 30 días por cámara)" % [fin.get(j[0]), fin.get(j[1])])
	# --- discusión inmediata sobre un proyecto en trámite (para las balas) y salida del ahorro
	est.pa_actual = 10
	var k := _distintas(m, 1)
	if not k.is_empty() and bool(ag.presentar(k[0], "simple")["ok"]):
		var fin0 := int(est.agenda[0]["dia_etapa_fin"])
		var di := ag.poner_en_discusion_inmediata(k[0])
		_check(bool(di["ok"]) and int(est.agenda[0]["dia_etapa_fin"]) < fin0 and est.agenda[0]["urgencia"] == "inmediata", "discusión inmediata acorta la etapa")
		_check(String(ag.poner_en_discusion_inmediata(k[0])["razon"]) == "ya_inmediata" and String(ag.poner_en_discusion_inmediata("xx")["razon"]) == "proyecto_no_en_tramite", "razones de la discusión inmediata")
	var ah := m.movimientos.ahorro_movimientos()
	_check(int(ah["disponibles"]) == est.pa_actual and int(ah["tope"]) == 10 and int(ah["se_guardan"]) + int(ah["se_pierden"]) == est.pa_actual, "ahorro_movimientos coherente")
	# --- determinismo y guardado a mitad de trámite (solo juego legítimo, sin tocar el estado a mano)
	var m2 := _gobierno(datos, int(est.semilla))
	_check(m2 != null, "segunda partida para el replay")
	if m2 != null:
		var i2 := m2.agenda.agenda_catalogo().filter(func(e: Dictionary) -> bool: return int(e["costo_mov"]) <= 2).map(func(e: Dictionary) -> String: return String(e["carta_id"]))
		_check(bool(m2.agenda.presentar(i2[0], "simple")["ok"]) and bool(m2.agenda.presentar(i2[1], "suma")["ok"]), "replay: presentar dos proyectos")
		for _k in range(3):
			m2.terminar_turno()
		var g: Dictionary = JSON.parse_string(JSON.stringify(m2.estado.exportar_guardado(Datos.huella(datos))))
		_check(g["entradas"].any(func(x: Dictionary) -> bool: return x["tipo"] == "presentar") and int(g["version"]) == ValidarGuardado.VERSION, "el guardado registra «presentar»")
		var rep := Partida.reproducir(datos, g)
		_check(rep != null and rep.estado.calcular_huella() == m2.estado.calcular_huella() and rep.estado.agenda.size() == 2, "replay a mitad de trámite idéntico")
		for _k in range(12):
			m2.terminar_turno()
			rep.terminar_turno()
		_check(rep.estado.calcular_huella() == m2.estado.calcular_huella(), "misma semilla + mismas entradas = mismo resultado al terminar la tramitación")
	print("AGENDA LEGISLATIVA OK" if _fallos == 0 else "AGENDA LEGISLATIVA FALLÓ")
	quit(1 if _fallos > 0 else 0)
