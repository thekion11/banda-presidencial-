extends SceneTree
## Bordes exactos de las balas de plata y del presupuesto extra que el fuzz no alcanza con azar (mata B01, B02, B03, B05, B06, B09, B10, B11, P02, P04 y P06): año mínimo y cupo extra
## justo en el año pedido, ventana de «evento reciente», empate de la oposición (no es mayoría), enfriamiento entre balas, riesgo creciente cuando el indicador empeora, uso registrado
## (y no repetible), capital igual al costo (versión completa, no reducida), piso fiscal exacto del presupuesto, fracción alineada acotada y enfriamiento tras terminar un extra.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _motor(datos: Dictionary) -> MotorTurno:
	var m := AyudaV2.gobierno(datos, 77)
	m.estado.indicadores["capital"] = 95.0
	m.estado.indicadores["fiscal"] = 80.0
	return m


func _turno_anio(m: MotorTurno, anio: int) -> int:
	## Primer turno de gobierno del año dado.
	m.estado.etapa = "gobierno"
	for t in range(1, 400):
		m.estado.turno_actual = t
		if m.gabinete.anio_gobierno() >= anio:
			return t
	return -1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var m := _motor(datos)
	var cfg: Dictionary = m.catalogo_leyes["balas_plata"]
	# --- año mínimo (B01) y cupo extra (B05)
	var plebis := m.balas.definicion("bala_plebiscito")
	var cond_anio := {"tipo": "anio_min", "valor": 2}
	for c in plebis["requiere"]:
		if String(c["tipo"]) == "anio_min":
			cond_anio = c
	var anio := int(cond_anio["valor"])
	var t_anio := _turno_anio(m, anio)
	m.estado.turno_actual = t_anio
	_check(m.balas._cumple(cond_anio, plebis), "en la primera semana del año %d la condición anio_min se cumple" % anio)
	m.estado.turno_actual = t_anio - 1
	_check(not m.balas._cumple(cond_anio, plebis), "la semana antes del año %d anio_min NO se cumple" % anio)
	var extra := int(cfg["anio_uso_extra"])
	var t_extra := _turno_anio(m, extra)
	m.estado.turno_actual = t_extra
	_check(m.balas.usos_habilitados() == int(cfg["usos_max"]), "en la primera semana del año %d se habilita todo el cupo (%d)" % [extra, m.balas.usos_habilitados()])
	m.estado.turno_actual = t_extra - 1
	_check(m.balas.usos_habilitados() == int(cfg["usos_iniciales"]), "la semana antes solo están los usos iniciales (%d)" % m.balas.usos_habilitados())
	# --- evento reciente (B02)
	var ins := m.balas.definicion("bala_insistencia")
	var cond_ev: Dictionary = {}
	for c in ins["requiere"]:
		if String(c["tipo"]) == "evento_reciente":
			cond_ev = c
	m.estado.turno_actual = 40
	var ev_id := String(cond_ev["ids"][0])
	var sem := int(cfg["semanas_reciente"])
	m.estado.eventos_ocurridos[ev_id] = 40 - sem
	_check(m.balas._cumple(cond_ev, ins), "un evento de hace exactamente %d semanas aún es reciente" % sem)
	m.estado.eventos_ocurridos[ev_id] = 40 - sem - 1
	_check(not m.balas._cumple(cond_ev, ins), "un evento de hace %d semanas ya no es reciente" % (sem + 1))
	m.estado.eventos_ocurridos.erase(ev_id)
	# --- oposición mayoritaria: el empate no es mayoría (B03)
	var veto := m.balas.definicion("bala_veto")
	var cond_op := {"tipo": "oposicion_mayoritaria"}
	m.estado.partido = {"escanos_propios": 0}
	var empates := 0
	for paso in range(0, 52 * 11):
		var propios := paso / 11
		m.estado.indicadores["capital"] = float(paso % 11) * 10.0
		m.estado.partido["escanos_propios"] = propios
		var hay := false
		for camara in [true, false]:
			var comp := m.legal.composicion(m.estado, camara)
			if int(comp["oposicion"]) * 2 == int(comp["total"]):
				empates += 1
			if int(comp["oposicion"]) * 2 > int(comp["total"]):
				hay = true
		_check(m.balas._cumple(cond_op, veto) == hay, "oposición mayoritaria con %d escaños propios: esperado %s" % [propios, str(hay)])
	_check(empates > 0, "el barrido encuentra al menos un empate exacto de la oposición (%d)" % empates)
	# --- enfriamiento (B06)
	var m2 := _motor(datos)
	m2.estado.turno_actual = 30
	var enf := int(cfg["enfriamiento_semanas"])
	m2.estado.balas = {"usadas": {"bala_urgencia": [m2.estado.ciclo, 30]}}
	m2.estado.turno_actual = 30 + enf - 1
	_check(m2.balas.semanas_de_espera() == 1, "a una semana del fin del enfriamiento faltan 1 semana (%d)" % m2.balas.semanas_de_espera())
	m2.estado.turno_actual = 30 + enf
	_check(m2.balas.semanas_de_espera() == 0, "al cumplirse el enfriamiento ya no hay espera (%d)" % m2.balas.semanas_de_espera())
	# --- riesgo creciente (B09)
	var urg := m2.balas.definicion("bala_urgencia")
	var ind := String(urg["riesgo"]["ind"])
	m2.estado.indicadores[ind] = 90.0
	var r_bien := m2.balas.riesgo_estimado(urg)
	m2.estado.indicadores[ind] = 20.0
	var r_mal := m2.balas.riesgo_estimado(urg)
	_check(r_mal > r_bien, "el riesgo de la bala sube cuando %s empeora (%.3f → %.3f)" % [ind, r_bien, r_mal])
	# --- uso registrado y no repetible (B10) y capital igual al costo (B11)
	var m3 := _motor(datos)
	_turno_anio(m3, 2)
	var nom := m3.balas.definicion("bala_nombramiento")
	m3.estado.indicadores["capital"] = float(nom["costo_capital"])
	var u := m3.balas.usar("bala_nombramiento", -1, false)
	_check(bool(u.get("ok", false)) and is_equal_approx(float(u.get("escala", 0.0)), 1.0), "con capital igual al costo la bala se usa completa, sin versión reducida (%s)" % str(u.get("razon", u.get("escala", "?"))))
	_check(m3.balas._usadas_del_ciclo().has("bala_nombramiento"), "el uso de la bala queda registrado en el mandato")
	m3.estado.indicadores["capital"] = 95.0
	_check(String(m3.balas.usar("bala_nombramiento")["razon"]) == "ya_usada", "la misma bala no se puede repetir en el mandato")
	var item := {}
	for it in m3.balas.baul()["items"]:
		if String(it["id"]) == "bala_nombramiento":
			item = it
	_check(bool(item.get("usada", false)), "el baúl marca la bala como usada")
	# --- presupuesto: piso fiscal exacto (P02), fracción acotada (P04), enfriamiento (P06)
	var m4 := _motor(datos)
	var pc: Dictionary = m4.catalogo_leyes["presupuesto_ministerial"]
	var id_min := String(m4.estado.gabinete[0])
	var slot := m4.gabinete.slot_de(id_min)
	var cat := String(m4.catalogo_ministros[id_min]["categoria_afin"])
	var carta_id := ""
	for k in m4._cartas_por_id.keys():
		if String(m4._cartas_por_id[k]["categoria"]) == cat and m4.presupuesto._es_del_sector(String(k), slot):
			carta_id = String(k)
			break
	_check(carta_id != "", "hay una carta del sector del primer ministro para armar un proyecto")
	m4.estado.obras_en_curso.append({"carta_id": carta_id, "nombre": "Obra de prueba", "dias_avanzados": 0, "dias_totales": 100})
	var nivel := String(pc["niveles"].keys()[0])
	var fis_n := float(pc["niveles"][nivel]["fiscal"])
	m4.estado.indicadores["fiscal"] = float(pc["piso_fiscal"]) + fis_n
	var a1 := m4.presupuesto.asignar(slot, nivel, [])
	_check(bool(a1.get("ok", false)), "con el fiscal justo en el piso (%.1f + %.1f) el extra se puede asignar (%s)" % [float(pc["piso_fiscal"]), fis_n, str(a1.get("razon", "?"))])
	var m5 := _motor(datos)
	m5.estado.obras_en_curso.append({"carta_id": carta_id, "nombre": "Obra de prueba", "dias_avanzados": 0, "dias_totales": 100})
	m5.estado.indicadores["fiscal"] = float(pc["piso_fiscal"]) + fis_n - 0.5
	var a2 := m5.presupuesto.asignar(slot, nivel, [])
	_check(not bool(a2.get("ok", false)) and String(a2.get("razon", "")) == "piso_fiscal", "con el fiscal medio punto bajo el piso el extra se rechaza por piso_fiscal (%s)" % str(a2.get("razon", "ok")))
	var m6 := _motor(datos)
	var a: Dictionary = m6.catalogo_leyes["presupuesto_ministerial"]["autonomia"]
	var slot6 := m6.gabinete.slot_de(String(m6.estado.gabinete[0]))
	a["peso_lealtad"] = 50.0
	_check(is_equal_approx(m6.presupuesto.fraccion_alineada(slot6), float(a["fraccion_max"])), "la fracción alineada no pasa de fraccion_max (%.3f)" % m6.presupuesto.fraccion_alineada(slot6))
	a["peso_lealtad"] = -50.0
	a["peso_afinidad"] = -50.0
	_check(is_equal_approx(m6.presupuesto.fraccion_alineada(slot6), float(a["fraccion_min"])), "la fracción alineada no baja de fraccion_min (%.3f)" % m6.presupuesto.fraccion_alineada(slot6))
	var m7 := _motor(datos)
	m7.estado.turno_actual = 20
	m7.presupuesto._terminar(slot)
	_check(m7.presupuesto.semanas_libre(slot) == int(pc["enfriamiento_semanas"]), "tras terminar un extra el ministerio queda %d semanas en enfriamiento (%d)" % [int(pc["enfriamiento_semanas"]), m7.presupuesto.semanas_libre(slot)])
	if _fallos == 0:
		print("test_balas_bordes: OK")
	quit(1 if _fallos > 0 else 0)
