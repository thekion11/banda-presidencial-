extends SceneTree
## Presupuesto extra a ministerios con autonomía (PR-18 mínimo, pedido del usuario del 27-nov-2026): costo, topes, fracción alineada según lealtad,
## afinidad y competencia, prioridades, incidentes, duración, enfriamiento, determinismo y guardado.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _gobierno(datos: Dictionary, semilla: int) -> MotorTurno:
	var m := AyudaV2.gobierno(datos, semilla)
	m.estado.indicadores["fiscal"] = 80.0
	m.estado.indicadores["capital"] = 60.0
	return m


func _cartas_ley_de_sectores(m: MotorTurno, n: int) -> Array[Dictionary]:
	## n cartas con ley de sectores atendidos por ministerios distintos: {carta, slot}.
	var res: Array[Dictionary] = []
	var vistos := {}
	for c in m.catalogo_cartas:
		if c["requisitos"]["ley"] == null or res.size() >= n:
			continue
		var tit := m.gabinete.titular(String(c["categoria"]))
		if tit == "":
			continue
		var slot := m.gabinete.slot_de(tit)
		if not vistos.has(slot):
			vistos[slot] = true
			res.append({"carta": c, "slot": slot})
	return res


func _proyecto(m: MotorTurno, carta: Dictionary, dias: int) -> void:
	m.estado.proyectos_ley.append({"carta_id": carta["id"], "tipo_ley": carta["requisitos"]["ley"], "escala": 1.0, "region": "", "origen": "camara",
			"dia_ingreso": m.estado.dia_actual, "dia_votacion": m.estado.dia_actual + dias})


func _init() -> void:
	var datos := Datos.cargar_todo()
	var cfg: Dictionary = datos["leyes"]["presupuesto_ministerial"]
	var m := _gobierno(datos, 51)
	var sec := _cartas_ley_de_sectores(m, 4)
	_check(sec.size() == 4, "hay cartas con ley de 4 sectores distintos para probar (%d)" % sec.size())
	var p0 := m.presupuesto.panel()
	_check((p0["ministerios"] as Array).size() == m.estado.gabinete.size() and int(p0["max_simultaneos"]) == int(cfg["max_simultaneos"]), "el panel lista cada ministerio y los topes")
	for fila in p0["ministerios"]:
		_check(float(fila["fraccion_alineada"]) >= float(cfg["autonomia"]["fraccion_min"]) and float(fila["fraccion_alineada"]) <= float(cfg["autonomia"]["fraccion_max"]), "%s: fracción alineada dentro de los límites" % fila["slot"])
		_check(bool(fila["puede_asignar"]) or (String(fila["mensaje"]) != "" and String(fila["alternativa"]) != ""), "%s: si no se puede, dice por qué y qué hacer" % fila["slot"])
	# sin proyectos del sector no hay a dónde enviar el dinero (corrector)
	var s0: String = sec[0]["slot"]
	var r0 := m.presupuesto.asignar(s0, "medio")
	_check(not bool(r0["ok"]) and String(r0["razon"]) == "sin_proyectos" and String(r0["alternativa"]) != "", "sin proyectos del sector: corrector con alternativa")
	_check(String(m.presupuesto.asignar(s0, "gigante")["razon"]) == "nivel_desconocido", "nivel desconocido")
	_check(String(m.presupuesto.asignar("min_fantasma", "medio")["razon"]) == "ministerio_vacio", "ministerio inexistente")
	# asignar: cuesta fiscal y capital, no movimientos
	for s in sec:
		_proyecto(m, s["carta"], 56)
	var fisc := m.estado.ind("fiscal")
	var cap := m.estado.ind("capital")
	var pa := m.estado.pa_actual
	var rr := m.presupuesto.asignar(s0, "medio")
	var niv: Dictionary = cfg["niveles"]["medio"]
	_check(bool(rr["ok"]), "asignar un extra medio")
	_check(absf(m.estado.ind("fiscal") - (fisc - float(niv["fiscal"]))) < 0.01 and absf(m.estado.ind("capital") - (cap - float(niv["capital"]))) < 0.01 and m.estado.pa_actual == pa, "cuesta fiscal y capital, no movimientos")
	_check(String(m.presupuesto.asignar(s0, "pequeno")["razon"]) == "ya_activo", "un ministerio no recibe dos extras a la vez")
	_check(absf(m.presupuesto.gastado_anio() - float(niv["fiscal"])) < 0.01, "el gasto anual suma el extra")
	var pm := m.presupuesto.panel()
	var fila: Dictionary = (pm["ministerios"] as Array).filter(func(x: Dictionary) -> bool: return x["slot"] == s0)[0]
	_check(bool(fila["activo"]) and int(fila["semanas_restantes"]) == int(cfg["duracion_semanas"]) and not (fila["prioridades"] as Array).is_empty(), "el panel muestra el extra activo, su duración y las prioridades automáticas")
	# prioridades
	var mp := _gobierno(datos, 52)
	var sp := _cartas_ley_de_sectores(mp, 1)
	_proyecto(mp, sp[0]["carta"], 56)
	_check(String(mp.presupuesto.asignar(sp[0]["slot"], "pequeno", ["no_existe"])["razon"]) == "prioridad_invalida", "una prioridad que no es del sector se rechaza con corrector")
	_check(bool(mp.presupuesto.asignar(sp[0]["slot"], "pequeno", [String(sp[0]["carta"]["id"])])["ok"]), "asignar con prioridad explícita")
	_check(String(mp.presupuesto.fijar_prioridades("min_hacienda_x", [])["razon"]) == "sin_extra_activo", "cambiar prioridades sin extra activo")
	_check(bool(mp.presupuesto.fijar_prioridades(sp[0]["slot"], [])["ok"]), "volver a prioridades automáticas")
	# tope anual, piso fiscal, capital y simultáneos
	var mt := _gobierno(datos, 53)
	var st := _cartas_ley_de_sectores(mt, 4)
	for s in st:
		_proyecto(mt, s["carta"], 56)
	_check(bool(mt.presupuesto.asignar(st[0]["slot"], "grande")["ok"]), "extra grande")
	var tope := mt.presupuesto.asignar(st[1]["slot"], "grande")
	_check(String(tope["razon"]) == "tope_anual" and String(tope["nivel_viable"]) != "" and String(tope["alternativa"]).contains("alcanza"), "el tope anual (regla fiscal) se aplica y ofrece un nivel que sí cabe")
	_check(bool(mt.presupuesto.asignar(st[1]["slot"], String(tope["nivel_viable"]))["ok"]), "con el nivel viable sí se puede")
	mt.estado.presupuesto["gasto"] = {}
	mt.estado.indicadores["fiscal"] = float(cfg["piso_fiscal"]) + 1.0
	_check(String(mt.presupuesto.asignar(st[2]["slot"], "pequeno")["razon"]) == "piso_fiscal", "el fiscal no puede bajar del piso al gastar")
	mt.estado.indicadores["fiscal"] = 90.0
	mt.estado.presupuesto["gasto"] = {}
	mt.estado.indicadores["capital"] = 0.0
	_check(String(mt.presupuesto.asignar(st[2]["slot"], "medio")["razon"]) == "capital_insuficiente", "negociar el extra cuesta capital")
	mt.estado.indicadores["capital"] = 50.0
	_check(bool(mt.presupuesto.asignar(st[2]["slot"], "pequeno")["ok"]), "tercer ministerio con extra")
	_check(String(mt.presupuesto.asignar(st[3]["slot"], "pequeno")["razon"]) == "max_simultaneos", "máximo de ministerios con extra simultáneo")
	# fracción alineada: crece con la lealtad, la afinidad y la competencia
	var mf := _gobierno(datos, 54)
	var sf := _cartas_ley_de_sectores(mf, 1)
	var slot_f: String = sf[0]["slot"]
	var base_f := mf.presupuesto.fraccion_alineada(slot_f)
	mf.estado.decisiones["evt_" + slot_f] = 2  # ignorar su petición baja la relación a 40 (si ese ministerio tiene petición)
	var peticion := ""
	for evt in mf.catalogo_eventos:
		if evt.has("actor") and String(evt["actor"]["id"]) == slot_f and evt.has("opciones"):
			peticion = String(evt["id"])
	if peticion != "":
		mf.estado.decisiones[peticion] = 2
		var baja := mf.presupuesto.fraccion_alineada(slot_f)
		mf.estado.decisiones[peticion] = 0
		var alta := mf.presupuesto.fraccion_alineada(slot_f)
		_check(baja < base_f and alta > base_f, "la fracción alineada sube con la lealtad (%.2f < %.2f < %.2f)" % [baja, base_f, alta])
	var f_ref := mf.presupuesto.fraccion_alineada(slot_f)
	var antes_eje := float(mf.estado.partido.get("eje_eco", 0.0))
	mf.estado.partido["eje_eco"] = 1.0
	var f_a := mf.presupuesto.fraccion_alineada(slot_f)
	mf.estado.partido["eje_eco"] = -1.0
	var f_b := mf.presupuesto.fraccion_alineada(slot_f)
	mf.estado.partido["eje_eco"] = antes_eje
	_check(not is_equal_approx(f_a, f_b), "la afinidad ideológica mueve la fracción alineada (%.2f vs %.2f; base %.2f)" % [f_a, f_b, f_ref])
	# efecto semanal: el ministerio acelera sus obras y leyes, más las prioritarias
	var m1 := _gobierno(datos, 55)
	var m2 := _gobierno(datos, 55)
	var s1 := _cartas_ley_de_sectores(m1, 1)
	_proyecto(m1, s1[0]["carta"], 70)
	_proyecto(m2, s1[0]["carta"], 70)
	m1.presupuesto.asignar(s1[0]["slot"], "grande")
	var v0 := int(m1.estado.proyectos_ley[0]["dia_votacion"])
	m1.presupuesto.amanecer()
	m2.presupuesto.amanecer()
	_check(int(m1.estado.proyectos_ley[0]["dia_votacion"]) < v0 and int(m2.estado.proyectos_ley[0]["dia_votacion"]) == v0, "el extra adelanta la votación de la ley del sector (y sin extra no)")
	var obra_carta: Dictionary = {}
	for c in m1.catalogo_cartas:
		if c.has("obra") and m1.gabinete.titular(String(c["categoria"])) != "":
			obra_carta = c
			break
	var m3 := _gobierno(datos, 56)
	var slot_o := m3.gabinete.slot_de(m3.gabinete.titular(String(obra_carta["categoria"])))
	m3.obras.iniciar(m3.estado, "Obra de prueba", 200, "", String(obra_carta["id"]), [])
	m3.presupuesto.asignar(slot_o, "grande")
	var d0 := int(m3.estado.obras_en_curso[0]["dias_avanzados"])
	var riesgo0 := m3.estado.ind("riesgo_ejecucion")
	m3.presupuesto.amanecer()
	_check(int(m3.estado.obras_en_curso[0]["dias_avanzados"]) > d0 and m3.estado.ind("riesgo_ejecucion") < riesgo0, "el extra adelanta las obras del sector y baja el riesgo de ejecución")
	# duración y enfriamiento
	var duracion := int(cfg["duracion_semanas"])
	var m4 := _gobierno(datos, 57)
	var s4 := _cartas_ley_de_sectores(m4, 1)
	_proyecto(m4, s4[0]["carta"], 900)
	m4.presupuesto.asignar(s4[0]["slot"], "pequeno")
	m4.estado.turno_actual += duracion
	m4.presupuesto.amanecer()
	_check(not (m4.estado.presupuesto["activos"] as Dictionary).has(s4[0]["slot"]), "la temporada termina tras %d semanas" % duracion)
	var ee := m4.presupuesto.asignar(s4[0]["slot"], "pequeno")
	_check(String(ee["razon"]) == "enfriamiento_presupuesto" and int(ee["semanas"]) > 0 and String(ee["alternativa"]).contains("semana"), "enfriamiento tras la temporada, con las semanas que faltan")
	m4.estado.turno_actual += int(cfg["enfriamiento_semanas"])
	_check(bool(m4.presupuesto.asignar(s4[0]["slot"], "pequeno")["ok"]), "pasado el enfriamiento se puede volver a asignar")
	# autonomía: con poca fracción alineada hay más incidentes (misma semilla = mismos incidentes)
	var inc_alta := _incidentes(datos, 0.95)
	var inc_baja := _incidentes(datos, 0.25)
	_check(inc_baja > inc_alta, "más incidentes cuando el ministro responde menos a tus prioridades (%d vs %d)" % [inc_baja, inc_alta])
	_check(_incidentes(datos, 0.25) == inc_baja, "mismos incidentes con la misma semilla")
	# renuncia: con fracción muy baja el ministro puede renunciar y lo reemplaza otro
	var renuncio := false
	for sd in range(300, 420):
		var mr := _gobierno(datos, sd)
		var sr := _cartas_ley_de_sectores(mr, 1)
		_proyecto(mr, sr[0]["carta"], 900)
		mr.presupuesto.asignar(sr[0]["slot"], "pequeno")
		var antes := mr.gabinete.de_ministerio(sr[0]["slot"])
		mr.presupuesto._incidente(sr[0]["slot"], 0.2)
		if mr.estado.registro_acciones.any(func(a: Dictionary) -> bool: return a["tipo"] == "presupuesto_incidente" and String(a["detalle"]["evento"]) == "renuncia"):
			renuncio = true
			_check(mr.gabinete.de_ministerio(sr[0]["slot"]) != antes and not (mr.estado.presupuesto["activos"] as Dictionary).has(sr[0]["slot"]), "al renunciar entra otro ministro y se cancela el extra")
			break
	_check(renuncio, "con fracción baja el ministro puede renunciar")
	# guardado por eventos y replay
	var mg := AyudaTardio.crear(datos, 2026, 6, "completo", "facil")
	if mg == null:
		_check(false, "no se pudo armar una partida de prueba")
	else:
		var elegido := ""
		for f2 in mg.presupuesto.panel()["ministerios"]:
			if bool(f2["puede_asignar"]):
				elegido = String(f2["slot"])
				break
		_check(elegido != "", "hay un ministerio con proyectos donde asignar en una partida real")
		if elegido != "":
			_check(bool(mg.presupuesto.asignar(elegido, "pequeno")["ok"]), "asignar en una partida real")
			mg.presupuesto.fijar_prioridades(elegido, [])
			for _i in range(4):
				mg.terminar_turno()
			var g: Dictionary = JSON.parse_string(JSON.stringify(mg.estado.exportar_guardado(Datos.huella(datos))))
			_check(g["entradas"].any(func(e: Dictionary) -> bool: return e["tipo"] == "presupuesto"), "el extra queda en el guardado")
			_check(ValidarGuardado.guardado_valido(g), "el guardado con presupuesto es válido")
			var bad: Dictionary = g.duplicate(true)
			bad["entradas"].append({"tipo": "presupuesto", "accion": "asignar", "slot": "x", "nivel": "medio", "prio": [3]})
			_check(not ValidarGuardado.guardado_valido(bad), "una entrada de presupuesto con prioridades que no son texto se descarta")
			var mi := Partida.reproducir(datos, g)
			_check(mi != null and mi.estado.calcular_huella() == mg.estado.calcular_huella(), "el replay da la misma huella")
	print("PRESUPUESTO MINISTERIAL OK" if _fallos == 0 else "PRESUPUESTO MINISTERIAL FALLÓ")
	quit(1 if _fallos > 0 else 0)


func _incidentes(datos: Dictionary, f_objetivo: float) -> int:
	## Cuenta incidentes en 40 temporadas de un ministro forzado a esa fracción alineada (se prueba la probabilidad y el sorteo, no la lealtad real).
	var n := 0
	for sd in range(600, 640):
		var m := _gobierno(datos, sd)
		var s := _cartas_ley_de_sectores(m, 1)
		_proyecto(m, s[0]["carta"], 900)
		m.presupuesto.asignar(s[0]["slot"], "pequeno")
		var cfg: Dictionary = m.catalogo_leyes["presupuesto_ministerial"]
		var a: Dictionary = cfg["autonomia"]
		a["peso_lealtad"] = 0.0
		a["peso_afinidad"] = 0.0
		a["peso_competencia"] = 0.0
		a["fraccion_min"] = f_objetivo
		a["fraccion_max"] = f_objetivo
		for _w in range(int(cfg["duracion_semanas"]) - 1):
			m.estado.turno_actual += 1
			m.presupuesto.amanecer()
		n += m.estado.registro_acciones.filter(func(x: Dictionary) -> bool: return x["tipo"] == "presupuesto_incidente").size()
	return n
