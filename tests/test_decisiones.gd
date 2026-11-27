extends SceneTree
## PR-07/PR-08: eventos con opciones: la respuesta aplica efectos, no gasta movimientos, no se repite y se reproduce.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var con_ops: Array = datos["eventos"].filter(func(e: Dictionary) -> bool: return e.has("opciones"))
	_check(con_ops.size() >= 45, "hay al menos 45 eventos con opciones (%d)" % con_ops.size())
	for e in con_ops:
		_check(e["opciones"].size() >= 2, "%s: al menos 2 opciones" % e["id"])
	var m := AyudaV2.gobierno(datos, 21)
	var evt: Dictionary = con_ops[0]
	var res := m.eventos.aplicar_evento(evt)
	_check(res.has("opciones") and res["efectos"].is_empty(), "el evento con opciones no aplica efectos por sí solo")
	var antes := m.estado.ind("aprobacion") + m.estado.ind("fiscal") + m.estado.ind("capital")
	var pa := m.estado.pa_actual
	var r := m.eventos.decidir(String(evt["id"]), 0)
	_check(bool(r["ok"]), "decidir la opción 0")
	_check(m.estado.pa_actual == pa, "decidir no gasta movimientos")
	_check(m.estado.ind("aprobacion") + m.estado.ind("fiscal") + m.estado.ind("capital") != antes, "la decisión cambia indicadores")
	_check(not bool(m.eventos.decidir(String(evt["id"]), 1)["ok"]), "no se puede decidir dos veces")
	_check(not bool(m.eventos.decidir("evt_inexistente", 0)["ok"]), "evento inexistente")
	var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(Datos.huella(datos))))
	_check(g["entradas"].any(func(e: Dictionary) -> bool: return e["tipo"] == "decision"), "la decisión queda en el guardado")
	# PR-17: las balas de plata ya no circulan en el mazo: viven en la reserva (tests/test_balas_plata.gd)
	# PR-24: relación con actores derivada de las decisiones
	var m3 := AyudaV2.gobierno(datos, 23)
	var ev_act: Dictionary = datos["eventos"].filter(func(e: Dictionary) -> bool: return e.has("actor"))[0]
	m3.eventos.aplicar_evento(ev_act)
	m3.eventos.decidir(String(ev_act["id"]), 0)
	var rel := m3.eventos.relaciones_actores()
	_check(rel.size() == 1 and float(rel[0]["relacion"]) > 50.0, "apoyar a un actor sube la relación")
	# Fase D: riesgo, efecto a futuro, cadena y memoria
	var m4 := AyudaV2.gobierno(datos, 24)
	var base_ev := {"tipo": "aleatorio_semilla", "dia_objetivo": null, "hora_etiqueta": "09:00", "peso_sorteo": 0.0, "descripcion": "", "votacion": null, "efectos_base": [], "etapa": "gobierno", "fuente": "fuentes.json#ficticio_2026", "familia": "prueba"}
	var origen := base_ev.duplicate()
	origen.merge({"id": "evt_t_origen", "titulo": "Origen", "opciones": [{"texto": "a", "efectos": [{"ind": "capital", "delta": 1}], "riesgo": {"prob": 0.999, "efectos": [{"ind": "aprobacion", "delta": -5}]},
			"diferido": {"semanas": 2, "efectos": [{"ind": "fiscal", "delta": 7}], "texto": "dif"}, "cadena": {"evento": "evt_t_seg", "semanas": 3}}, {"texto": "b", "efectos": []}]})
	var seguimiento := base_ev.duplicate()
	seguimiento.merge({"id": "evt_t_seg", "tipo": "cadena", "titulo": "Seguimiento", "opciones": [{"texto": "x", "efectos": []}]})
	var memoria := base_ev.duplicate()
	memoria.merge({"id": "evt_t_mem", "titulo": "Memoria", "peso_sorteo": 1.0, "opciones": [{"texto": "x", "efectos": []}], "requiere": {"decision": {"evento": "evt_t_origen", "idx": 0}}})
	m4.catalogo_eventos.append(origen)
	m4.catalogo_eventos.append(seguimiento)
	m4.catalogo_eventos.append(memoria)
	_check(not m4.eventos._cumple_requisitos(memoria), "la memoria exige haber decidido antes")
	m4.eventos.aplicar_evento(origen)
	var fiscal0 := m4.estado.ind("fiscal")
	var rd := m4.eventos.decidir("evt_t_origen", 0)
	_check(bool(rd["salio_mal"]) and m4.estado.pendientes.size() == 2 and int(rd["futuro"]) == 3, "la opción arriesgada sale mal, programa un efecto y una cadena")
	_check(m4.eventos._cumple_requisitos(memoria), "tras decidir, el evento con memoria queda disponible")
	var vio_seg := false
	var vio_dif := false
	for _w in range(5):
		m4.terminar_turno()
		for ev in m4.ultimos_eventos:
			vio_seg = vio_seg or String(ev["id"]) == "evt_t_seg"
			vio_dif = vio_dif or String(ev["id"]) == "dif_evt_t_origen"
	_check(vio_dif and vio_seg and m4.estado.pendientes.is_empty(), "el efecto diferido y la cadena ocurren a su semana (dif %s, cadena %s)" % [vio_dif, vio_seg])
	print("test_decisiones: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
