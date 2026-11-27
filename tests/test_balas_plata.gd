extends SceneTree
## PR-17: balas de plata (reserva aparte de la mano): usos por mandato, costo en capital, condiciones por tipo, corrector, enfriamiento,
## determinismo y guardado por eventos.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _proyecto(m: MotorTurno, tipo: String, dias: int) -> void:
	## Agrega un proyecto de ley en trámite (de la primera carta con ley del catálogo) con esa distancia a su votación.
	var carta: Dictionary = {}
	for c in m.catalogo_cartas:
		if c["requisitos"]["ley"] != null:
			carta = c
			break
	m.estado.proyectos_ley.append({"carta_id": carta["id"], "tipo_ley": tipo, "escala": 1.0, "region": "", "origen": "camara",
			"dia_ingreso": m.estado.dia_actual, "dia_votacion": m.estado.dia_actual + dias})


func _gobierno(datos: Dictionary, semilla: int, turno: int = 1) -> MotorTurno:
	var m := AyudaV2.gobierno(datos, semilla)
	m.estado.turno_actual = turno
	m.estado.dia_actual = 1 + (turno - 1) * m.estado.dias_por_turno
	return m


func _init() -> void:
	var datos := Datos.cargar_todo()
	var cfg: Dictionary = datos["leyes"]["balas_plata"]
	_check((cfg["catalogo"] as Array).size() == 7, "el catálogo tiene 7 tipos de bala")
	_check(not datos["cartas"].any(func(c: Dictionary) -> bool: return String(c["id"]).begins_with("bala_")), "las balas ya no circulan en el mazo general")
	# reserva y baúl
	var m := _gobierno(datos, 31)
	var b := m.balas.baul()
	_check((b["items"] as Array).size() == 7 and int(b["usos_max"]) == int(cfg["usos_max"]), "el baúl lista los 7 tipos y el máximo del mandato")
	_check(int(b["usos_restantes"]) == int(cfg["usos_iniciales"]), "al empezar hay %d usos disponibles" % int(cfg["usos_iniciales"]))
	for it in b["items"]:
		_check(not bool(it["disponible"]) or String(it["razon"]) == "", "%s: disponible implica sin razón de rechazo" % it["id"])
		_check(float(it["riesgo_estimado"]) > 0.0 and float(it["riesgo_estimado"]) < 1.0 and float(it["costo_capital"]) > 0.0, "%s: costo y riesgo informados" % it["id"])
		_check(bool(it["disponible"]) or (String(it["mensaje"]) != "" and String(it["alternativa"]) != ""), "%s: si no se puede, dice por qué y qué hacer (nunca un no seco)" % it["id"])
	_check(String(m.balas.usar("bala_inexistente")["razon"]) == "bala_desconocida", "bala desconocida")
	var r0 := m.balas.usar("bala_urgencia")
	_check(not bool(r0["ok"]) and String(r0["razon"]) == "condicion" and String(r0["alternativa"]) != "", "urgencia sin proyecto en trámite: corrector con alternativa")
	# urgencia: adelanta la votación del proyecto más lejano y cuesta capital
	_proyecto(m, "ley_simple", 14)
	_proyecto(m, "ley_simple", 35)
	var cap := m.estado.ind("capital")
	var pa := m.estado.pa_actual
	var u := m.balas.usar("bala_urgencia")
	_check(bool(u["ok"]) and int(u["objetivo"]) == 1, "la urgencia elige por defecto el proyecto más lejano de votarse")
	_check(int(m.estado.proyectos_ley[1]["dia_votacion"]) == m.estado.dia_actual, "se vota esta semana")
	_check(m.estado.ind("capital") < cap - float(cfg["catalogo"][0]["costo_capital"]) + 1.0 and m.estado.pa_actual == pa, "cuesta capital y no movimientos")
	_check(String(m.balas.usar("bala_urgencia")["razon"]) == "ya_usada", "una bala se usa una sola vez por mandato")
	_check(m.estado.registro_acciones.any(func(a: Dictionary) -> bool: return a["tipo"] == "bala"), "queda en el registro de acciones")
	# enfriamiento entre usos
	_proyecto(m, "ley_simple", 40)
	var ce := m.balas.usar("bala_dfl")
	_check(String(ce["razon"]) == "enfriamiento" and int(ce["semanas"]) > 0 and String(ce["alternativa"]).contains("semana"), "enfriamiento: dice cuántas semanas esperar")
	_check(int(m.balas.baul()["semanas_espera"]) == int(ce["semanas"]), "el baúl informa la espera")
	# usos por mandato: en el año 1 solo los iniciales; en el año 3 se habilita el resto
	var m2 := _gobierno(datos, 32)
	var usadas := 0
	for i in range(int(cfg["usos_iniciales"])):
		m2.estado.turno_actual += int(cfg["enfriamiento_semanas"])  # se mantiene dentro del año 1
		m2.estado.indicadores["cohesion"] = 90.0
		m2.estado.indicadores["capital"] = 90.0
		_proyecto(m2, "ley_simple", 30)
		if bool(m2.balas.usar("bala_urgencia" if i == 0 else ("bala_dfl" if i == 1 else "bala_veto"))["ok"]):
			usadas += 1
		else:
			m2.balas.usar("bala_nombramiento")
	var antes_sin := m2.balas.usos_restantes()
	_check(antes_sin <= int(cfg["usos_iniciales"]), "nunca se superan los usos habilitados")
	var m3 := _gobierno(datos, 33, 3 * 52)
	_check(m3.balas.usos_habilitados() == int(cfg["usos_max"]), "desde el año %d se habilita toda la reserva" % int(cfg["anio_uso_extra"]))
	# DFL: no vale para materias vedadas
	var m4 := _gobierno(datos, 34, 60)
	m4.estado.indicadores["capital"] = 90.0
	_proyecto(m4, "quorum_calificado", 30)
	var d1 := m4.balas.usar("bala_dfl")
	_check(not bool(d1["ok"]) and String(d1["razon"]) == "condicion" and String(d1["mensaje"]).contains("vedadas"), "DFL vedado para leyes de quórum especial")
	_proyecto(m4, "ley_simple", 30)
	var objs: Array = m4.balas.objetivos(m4.balas.definicion("bala_dfl"))
	_check(objs.size() == 1 and String(objs[0]["tipo_ley"]) == "ley_simple", "el DFL solo ofrece los proyectos permitidos")
	var antes_n := m4.estado.proyectos_ley.size()
	var d2 := m4.balas.usar("bala_dfl")
	_check(bool(d2["ok"]) and m4.estado.proyectos_ley.size() == antes_n - 1, "el DFL saca el proyecto del Congreso (se ejecuta o lo frena el control)")
	# DFL en el primer año: no
	var m5 := _gobierno(datos, 35)
	_proyecto(m5, "ley_simple", 30)
	_check(String(m5.balas.usar("bala_dfl")["razon"]) == "condicion", "el DFL exige haber avanzado el mandato")
	# insistencia: evento de la Contraloría reciente + la firma de todos los ministros
	var m6 := _gobierno(datos, 36)
	m6.estado.indicadores["capital"] = 90.0
	_check(String(m6.balas.usar("bala_insistencia")["razon"]) == "condicion", "insistencia sin objeción de la Contraloría")
	m6.estado.eventos_ocurridos["evt_contraloria_objeta"] = m6.estado.turno_actual
	_check(bool(m6.balas.baul()["items"][5]["disponible"]), "insistencia disponible con la Contraloría y ministros leales")
	var slot := m6.gabinete.slot_de(String(m6.estado.gabinete[0]))
	m6.estado.decisiones["evt_pet_ignorada"] = 0
	var rel_antes := m6.eventos.relacion_actor(slot)
	for evt in m6.catalogo_eventos:  # ignorar dos veces las peticiones de ese ministerio le quita la firma
		if evt.has("actor") and String(evt["actor"]["id"]) == slot and evt.has("opciones"):
			for k in range((evt["opciones"] as Array).size()):
				if int(evt["opciones"][k].get("relacion", 0)) < 0:
					m6.estado.decisiones[String(evt["id"])] = k
	var sin_firma := m6.balas.usar("bala_insistencia")
	if m6.eventos.relacion_actor(slot) < rel_antes:
		_check(not bool(sin_firma["ok"]) and String(sin_firma["condicion"]) == "ministros_firman", "un ministro sin lealtad no firma la insistencia")
	# capital insuficiente: versión reducida (nunca un no seco)
	var m7 := _gobierno(datos, 37, 60)
	m7.estado.indicadores["cohesion"] = 80.0
	var costo_pleb := float(m7.balas.definicion("bala_nombramiento")["costo_capital"])
	m7.estado.indicadores["capital"] = costo_pleb * 0.75
	var ci := m7.balas.usar("bala_nombramiento")
	_check(not bool(ci["ok"]) and String(ci["razon"]) == "capital_insuficiente" and not (ci["viable"] as Dictionary).is_empty(), "sin capital completo ofrece versión reducida")
	_check(bool(m7.balas.usar("bala_nombramiento", -1, true)["ok"]), "la versión reducida se puede usar")
	var m8 := _gobierno(datos, 38, 60)
	m8.estado.indicadores["capital"] = 1.0
	var cm := m8.balas.usar("bala_nombramiento")
	_check(String(cm["razon"]) == "capital_insuficiente" and (cm["viable"] as Dictionary).is_empty() and String(cm["alternativa"]) != "", "con muy poco capital explica cuánto falta")
	# determinismo: misma semilla y mismas entradas = mismo resultado
	var h1 := _secuencia(datos, 41)
	var h2 := _secuencia(datos, 41)
	_check(h1 == h2 and h1 != "", "misma semilla y mismas balas dan la misma huella")
	# guardado por eventos y replay
	var mg := AyudaTardio.crear(datos, 2026, 60, "completo", "facil")
	if mg == null:
		print("FALLO: no se pudo armar una partida de prueba")
		_fallos += 1
	else:
		var guarda := 0
		while mg.estado.ind("capital") < 8.0 and guarda < 12 and mg.estado.etapa == "gobierno":
			guarda += 1
			mg.terminar_turno()  # sin jugar cartas el capital se recupera solo (todo queda en el historial)
		_check(bool(mg.balas.usar("bala_nombramiento")["ok"]), "nombramiento orgánico en el año 2")
		for _i in range(int(cfg["enfriamiento_semanas"]) + 1):
			mg.terminar_turno()
		var rp := mg.balas.usar("bala_plebiscito")
		_check(bool(rp["ok"]) or String(rp["mensaje"]) != "", "el plebiscito da un resultado o explica por qué no")
		var g: Dictionary = JSON.parse_string(JSON.stringify(mg.estado.exportar_guardado(Datos.huella(datos))))
		_check(g["entradas"].any(func(e: Dictionary) -> bool: return e["tipo"] == "bala"), "la bala queda en el guardado")
		_check(ValidarGuardado.guardado_valido(g), "el guardado con balas es válido")
		var bad: Dictionary = g.duplicate(true)
		bad["entradas"].append({"tipo": "bala", "id": 5, "objetivo": 0, "reducida": false})
		_check(not ValidarGuardado.guardado_valido(bad), "una entrada bala con tipos erróneos se descarta")
		_check(mg.estado.balas.get("usadas", {}).has("bala_nombramiento"), "el estado guarda las balas usadas")
		var mi := Partida.reproducir(datos, g)
		_check(mi != null and mi.estado.balas == mg.estado.balas, "el replay reproduce las balas usadas")
		_check(mi != null and mi.estado.calcular_huella() == mg.estado.calcular_huella(), "el replay da la misma huella")
	print("BALAS DE PLATA OK" if _fallos == 0 else "BALAS DE PLATA FALLÓ")
	quit(1 if _fallos > 0 else 0)


func _secuencia(datos: Dictionary, semilla: int) -> String:
	var m := _gobierno(datos, semilla, 60)
	m.estado.indicadores["capital"] = 90.0
	_proyecto(m, "ley_simple", 30)
	m.balas.usar("bala_urgencia")
	m.estado.turno_actual += 7
	m.balas.usar("bala_nombramiento")
	return m.estado.calcular_huella()
