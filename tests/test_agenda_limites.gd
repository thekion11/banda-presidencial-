extends SceneTree
## Bordes de la agenda legislativa que el fuzz no alcanza (mata A03, A06, A07, A09 y A10): no se presenta una ley que ya espera votación desde la mano; presentar delegado cuenta
## como delegación del turno (y se agota el cupo); una etapa vence cuando su plazo es MENOR que el cierre de la semana (no igual); con recurso al TC seguro el proyecto pasa
## por «tc» y sin recurso va directo a promulgación; la comisión mixta dura «dias_mixta_frac» del plazo de la urgencia.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _motor(datos: Dictionary, semilla: int) -> MotorTurno:
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var m := Partida.crear(datos, semilla, GeneradorPartido.construir_partido("Lim", "LIM", "metropolitana", resp, datos["ideologia"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	return m if Bots.elegir(m, datos, "codicioso", rng) else null


func _carta_ley(m: MotorTurno) -> String:
	for c in m.agenda.agenda_catalogo():
		if String(c["tipo_ley"]) == "ley_simple":
			return String(c["carta_id"])
	return ""


func _init() -> void:
	var datos := Datos.cargar_todo()
	var m: MotorTurno = null
	for sd in range(2100, 2130):
		m = _motor(datos, sd)
		if m != null and _carta_ley(m) != "":
			break
	_check(m != null, "hay una partida de gobierno para probar")
	if m == null:
		quit(1)
		return
	var cfg: Dictionary = m.catalogo_leyes["agenda"]
	var id := _carta_ley(m)
	m.estado.pa_actual = 10
	m.estado.indicadores["capital"] = 90.0
	# A03: una ley que espera votación desde la mano no se puede presentar
	m.estado.proyectos_ley.append({"carta_id": id, "tipo_ley": "ley_simple", "escala": 1.0, "region": "", "origen": "camara", "dia_ingreso": m.estado.dia_actual, "dia_votacion": m.estado.dia_actual + 28})
	var r := m.agenda.presentar(id, "simple")
	_check(not bool(r.get("ok", false)) and String(r.get("razon", "")) == "ya_en_tramite", "una ley ya en votación desde la mano no se presenta (%s)" % str(r))
	m.estado.proyectos_ley.clear()
	# A10: presentar delegado cuenta como delegación del turno y se agota el cupo
	var maximo := int(m.catalogo_leyes["delegacion"]["max_por_turno"])
	var cat := m.agenda.agenda_catalogo()
	var presentados := 0
	var ministro := String(m.estado.gabinete[0])
	for c in cat:
		if presentados >= maximo + 1 or m.estado.agenda.size() >= int(cfg["max_simultaneos"]):
			break
		var d0 := m.estado.delegadas_turno
		var rr := m.agenda.presentar(String(c["carta_id"]), "simple", ministro, true)
		if bool(rr.get("ok", false)):
			presentados += 1
			_check(m.estado.delegadas_turno == d0 + 1, "presentar delegado suma una delegación del turno (%d → %d)" % [d0, m.estado.delegadas_turno])
		elif String(rr.get("razon", "")) == "limite_delegaciones":
			_check(m.estado.delegadas_turno >= maximo, "«limite_delegaciones» solo con el cupo agotado (%d de %d)" % [m.estado.delegadas_turno, maximo])
	_check(presentados <= maximo, "no se presentan más delegados que el cupo (%d de %d)" % [presentados, maximo])
	# A06: el plazo vence cuando es MENOR que el cierre de la semana
	var m2: MotorTurno = null
	for sd in range(2200, 2230):
		m2 = _motor(datos, sd)
		if m2 != null and _carta_ley(m2) != "":
			break
	m2.estado.pa_actual = 10
	var id2 := _carta_ley(m2)
	var ok2 := m2.agenda.presentar(id2, "simple")
	_check(bool(ok2.get("ok", false)), "se presenta una ley simple (%s)" % str(ok2))
	var p: Dictionary = m2.estado.agenda[0]
	var limite := m2.estado.dia_actual + m2.estado.dias_por_turno
	p["dia_etapa_fin"] = limite
	m2.agenda.avanzar()
	_check(not m2.estado.agenda.is_empty() and String(m2.estado.agenda[0]["etapa"]) == "primer_tramite", "una etapa con plazo igual al cierre de la semana NO se resuelve todavía")
	m2.estado.agenda[0]["dia_etapa_fin"] = limite - 1
	m2.agenda.avanzar()
	_check(m2.estado.agenda.is_empty() or String(m2.estado.agenda[0]["etapa"]) != "primer_tramite", "una etapa con plazo menor que el cierre de la semana SÍ se resuelve")
	# poner_en_discusion_inmediata (A11, A12): acorta el plazo (nunca lo alarga), no cobra, respeta la etapa y no se repite
	var m4: MotorTurno = null
	for sd in range(2400, 2430):
		m4 = _motor(datos, sd)
		if m4 != null and _carta_ley(m4) != "":
			break
	m4.estado.pa_actual = 10
	var id4 := _carta_ley(m4)
	_check(bool(m4.agenda.presentar(id4, "simple").get("ok", false)), "se presenta para la discusión inmediata")
	var p4: Dictionary = m4.estado.agenda[0]
	var pa4 := m4.estado.pa_actual
	var cap4 := m4.estado.ind("capital")
	var largo := int(p4["dia_etapa_fin"])
	var tope_inm := m4.estado.dia_actual + int(m4.agenda.urgencia("inmediata")["dias"])
	var di := m4.agenda.poner_en_discusion_inmediata(id4)
	_check(bool(di["ok"]) and String(p4["urgencia"]) == "inmediata" and int(p4["dia_etapa_fin"]) == mini(largo, tope_inm), "la discusión inmediata acorta el plazo a min(actual, hoy + días de la urgencia): %s" % str(di))
	_check(m4.estado.pa_actual == pa4 and is_equal_approx(m4.estado.ind("capital"), cap4), "la discusión inmediata no cobra movimientos ni capital (lo cobra quien llama)")
	_check(String(m4.agenda.poner_en_discusion_inmediata(id4)["razon"]) == "ya_inmediata", "no se puede subir dos veces")
	var m5: MotorTurno = null
	for sd in range(2500, 2530):
		m5 = _motor(datos, sd)
		if m5 != null and _carta_ley(m5) != "":
			break
	m5.estado.pa_actual = 10
	var id5 := _carta_ley(m5)
	m5.agenda.presentar(id5, "simple")
	var p5: Dictionary = m5.estado.agenda[0]
	p5["dia_etapa_fin"] = m5.estado.dia_actual + 2  # plazo ya más corto que el de la urgencia inmediata: no se alarga
	m5.agenda.poner_en_discusion_inmediata(id5)
	_check(int(p5["dia_etapa_fin"]) == m5.estado.dia_actual + 2, "un plazo ya más corto no se alarga (%d)" % int(p5["dia_etapa_fin"]))
	var m6: MotorTurno = null
	for sd in range(2600, 2630):
		m6 = _motor(datos, sd)
		if m6 != null and _carta_ley(m6) != "":
			break
	m6.estado.pa_actual = 10
	var id6 := _carta_ley(m6)
	m6.agenda.presentar(id6, "simple")
	m6.estado.agenda[0]["etapa"] = "tc"
	_check(String(m6.agenda.poner_en_discusion_inmediata(id6).get("razon", "")) == "etapa_sin_urgencia" and String(m6.estado.agenda[0]["urgencia"]) == "simple", "en el TC no se puede subir la urgencia")
	# A09: la comisión mixta dura dias_mixta_frac del plazo de la urgencia
	var u := m2.agenda.urgencia("simple")
	var pm := {"urgencia": "simple", "tipo_ley": "ley_simple", "etapa": "", "dia_etapa_fin": 0, "dia_ingreso": 0}
	_check(m2.agenda._dias_etapa("comision_mixta", pm) == maxi(1, roundi(float(u["dias"]) * float(cfg["dias_mixta_frac"]))), "la comisión mixta dura %d días (%d)" % [maxi(1, roundi(float(u["dias"]) * float(cfg["dias_mixta_frac"]))), m2.agenda._dias_etapa("comision_mixta", pm)])
	_check(m2.agenda._dias_etapa("primer_tramite", pm) == int(u["dias"]), "el primer trámite dura el plazo de la urgencia")
	# A07: con recurso al TC seguro el proyecto pasa por «tc»; sin recurso, directo a promulgación
	for recurso in [1.0, 0.0]:
		var visto := ""
		for sd in range(2300, 2340):
			var m3 := _motor(datos, sd)
			if m3 == null or _carta_ley(m3) == "":
				continue
			m3.catalogo_leyes["agenda"]["prob_comision_mixta"] = 0.0
			for t in m3.catalogo_leyes["tipos_ley"]:
				t["prob_recurso_tc"] = recurso
				t["puede_ir_tc"] = true
			m3.estado.pa_actual = 10
			m3.estado.indicadores["capital"] = 95.0
			if not bool(m3.agenda.presentar(_carta_ley(m3), "inmediata").get("ok", false)):
				continue
			for _k in range(6):  # semanas: primer trámite, segundo y lo que siga
				if m3.estado.agenda.is_empty():
					break
				if String(m3.estado.agenda[0]["etapa"]) in ["tc", "promulgacion"]:
					visto = String(m3.estado.agenda[0]["etapa"])
					break
				m3.terminar_turno()
			if visto != "":
				break
		_check(visto == ("tc" if recurso == 1.0 else "promulgacion"), "con recurso al TC %.0f el proyecto aprobado va a «%s» (fue a «%s»)" % [recurso, "tc" if recurso == 1.0 else "promulgacion", visto])
	if _fallos == 0:
		print("test_agenda_limites: OK")
	quit(1 if _fallos > 0 else 0)
