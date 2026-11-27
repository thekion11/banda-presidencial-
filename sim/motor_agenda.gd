class_name MotorAgenda
extends RefCounted
## Agenda legislativa (BM): el gobierno presenta un proyecto de ley por su cuenta (mensaje del Ejecutivo) y se tramita por etapas con semanas reales:
## primer trámite, segundo trámite, comisión mixta (si hay diferencias), Tribunal Constitucional (si hay recurso) y promulgación.
## Las cifras (urgencias, límites, plazos) viven en data/leyes.json › agenda. Las cartas jugadas desde la mano siguen con su votación única (MotorCartas).

const ETAPAS_VOTO := ["primer_tramite", "segundo_tramite"]
const NOMBRES_ETAPA := {"primer_tramite": "Primer trámite", "segundo_tramite": "Segundo trámite", "comision_mixta": "Comisión mixta",
		"tc": "Tribunal Constitucional", "promulgacion": "Promulgación"}

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


func _cfg() -> Dictionary:
	return m.catalogo_leyes["agenda"]


func urgencia(id: String) -> Dictionary:
	## Definición de una urgencia (simple, suma, inmediata); {} si no existe.
	for u in _cfg()["urgencias"]:
		if String(u["id"]) == id:
			return u
	return {}


func _en_agenda(carta_id: String) -> bool:
	return m.estado.agenda.any(func(p: Dictionary) -> bool: return String(p["carta_id"]) == carta_id)


func _semana_rechazo(carta_id: String) -> int:
	return int(m.estado.agenda_rechazos.get(carta_id, 0))


func _bloqueo_carta(carta: Dictionary) -> String:
	## Motivo por el que esta carta de ley no puede presentarse ahora ('' si puede): gabinete, ventana, ya promulgada, en trámite o en espera tras un rechazo.
	var _m := m
	if carta["requisitos"]["ley"] == null:
		return "no_es_ley"
	if _en_agenda(String(carta["id"])) or _m.estado.proyectos_ley.any(func(p: Dictionary) -> bool: return String(p["carta_id"]) == String(carta["id"])):
		return "ya_en_tramite"
	if _m.estado.cartas_ejecutadas.has(String(carta["id"])):
		return "ya_ejecutada"
	if _semana_rechazo(String(carta["id"])) > _m.eventos.semana_abs():
		return "en_espera_tras_rechazo"
	if not _m.carta_disponible(carta):
		return "carta_no_habilitada"
	return ""


func _lleno() -> bool:
	return m.estado.agenda.size() + m.estado.proyectos_ley.size() >= int(_cfg()["max_simultaneos"])


func estado_agenda() -> Dictionary:
	## Salida para la UI: {en_tramite, maximo, puede_presentar, razon}.
	var _m := m
	var razon := ""
	if _m.estado.etapa != "gobierno":
		razon = "solo_en_gobierno"
	elif _lleno():
		razon = "agenda_llena"
	return {"en_tramite": _m.estado.agenda.size() + _m.estado.proyectos_ley.size(), "maximo": int(_cfg()["max_simultaneos"]), "puede_presentar": razon == "", "razon": razon}


func _recargo(urg: Dictionary) -> float:
	return float(urg.get("recargo_votos", 0.0))


func _prob_tc(tipo_id: String) -> float:
	var t := m.legal.tipo(tipo_id)
	if t.is_empty() or not bool(t.get("puede_ir_tc", false)):
		return 1.0
	return 1.0 - float(t["prob_recurso_tc"]) * (1.0 - float(t["prob_exito_tc"]))


func prob_estimada(tipo_id: String, urg: Dictionary, desde: String = "primer_tramite") -> float:
	## Probabilidad estimada de aprobación (0 a 1) desde una etapa, con el apoyo de hoy (sin usar el azar). Salida de solo lectura para la UI.
	var _m := m
	var t := _m.legal.tipo(tipo_id)
	if t.is_empty():
		return 0.0
	var pr := _m.legal.prob_aprobacion(_m.estado, tipo_id, _recargo(urg))
	var p := 1.0
	if desde == "primer_tramite":
		p *= float(pr["senado"]) * float(pr["camara"]) if bool(t.get("requiere_votacion", true)) else 1.0
	elif desde == "segundo_tramite":
		p *= float(pr["senado"]) if bool(t.get("requiere_votacion", true)) else 1.0
	if desde == "primer_tramite" or desde == "segundo_tramite" or desde == "comision_mixta":
		var pm := float(_cfg()["prob_comision_mixta"]) if desde != "comision_mixta" else 1.0
		p *= (1.0 - pm) + pm * float(pr["senado"]) * float(pr["camara"])
		p *= _prob_tc(tipo_id)
	return clampf(p, 0.0, 1.0)


func _dias_etapa(etapa: String, p: Dictionary) -> int:
	var u := urgencia(String(p["urgencia"]))
	match etapa:
		"primer_tramite", "segundo_tramite":
			return int(u["dias"])
		"comision_mixta":
			return maxi(1, roundi(float(u["dias"]) * float(_cfg()["dias_mixta_frac"])))
		"tc":
			return int(_cfg()["dias_tc"])
	var t := m.legal.tipo(String(p["tipo_ley"]))
	return int(_cfg()["dias_promulgacion"]) if bool(t.get("requiere_votacion", true)) else int(t["dias_tramitacion_base"])


func _entrar(p: Dictionary, etapa: String) -> void:
	## Pasa el proyecto a una etapa: su plazo corre desde el fin de la anterior.
	var base := int(p["dia_etapa_fin"]) if p["etapa"] != "" else int(p["dia_ingreso"])
	p["etapa"] = etapa
	p["dia_etapa_fin"] = base + _dias_etapa(etapa, p)


func _camara_de(p: Dictionary) -> String:
	## Cámara que vota en este trámite ("camara" o "senado"): el primero es la de origen del proyecto.
	var origen := String(p["origen"])
	return origen if p["etapa"] == "primer_tramite" else ("senado" if origen == "camara" else "camara")


func abrir(carta: Dictionary, escala: float, region_id: String, urgencia_id: String, delegada: bool) -> Dictionary:
	## Ingresa el proyecto a la agenda (lo llama MotorCartas al ejecutar una presentación) y lo deja en su primera etapa.
	var _m := m
	var ley := String(carta["requisitos"]["ley"])
	var p := {"carta_id": carta["id"], "tipo_ley": ley, "escala": escala, "region": region_id, "origen": String(carta.get("camara_origen", "camara")),
			"urgencia": urgencia_id, "dia_ingreso": _m.estado.dia_actual, "dia_etapa_fin": 0, "etapa": "", "delegada": delegada, "tc_cae": false, "tc_recurso": false}
	_entrar(p, "primer_tramite" if bool(_m.legal.tipo(ley).get("requiere_votacion", true)) else "promulgacion")
	_m.estado.agenda.append(p)
	return p


func _corrector(carta: Dictionary, urg_id: String, motivo: String) -> Dictionary:
	## Nunca un «no» seco: otra urgencia, versión por tramos o esperar a tener más apoyo.
	var _m := m
	var ley := String(carta["requisitos"]["ley"])
	var ops: Array[Dictionary] = []
	for u in _cfg()["urgencias"]:
		if String(u["id"]) != urg_id and _m.estado.ind("capital") >= float(u["costo_capital"]):
			ops.append({"tipo": "urgencia", "urgencia": u["id"], "prob": prob_estimada(ley, u), "texto": "Prueba con urgencia %s (%d %% de aprobación estimada)." % [String(u["nombre"]).to_lower(), roundi(prob_estimada(ley, u) * 100.0)]})
	var corr := _m.legal.corregir(carta, _m.estado)
	if bool(corr["aplica"]):
		ops.append({"tipo": "tramos", "ratio": corr["ratio"], "texto": String(corr["mensaje"])})
	ops.append({"tipo": "esperar", "texto": "Espera a tener más capital político y cohesión: el apoyo del Congreso sube con ambos."})
	return {"motivo": motivo, "opciones": ops}


func agenda_catalogo(categoria: String = "") -> Array[Dictionary]:
	## Catálogo de proyectos que el gobierno puede presentar ahora (gabinete, ventana, etapa y quórum), aunque no estén en la mano.
	## Cada entrada: {carta_id, titulo, categoria, tipo_ley, costo_mov, urgencias:[{id, nombre, dias, costo_capital, prob, semanas, alcanza}], corrector}. Solo lectura.
	var _m := m
	var res: Array[Dictionary] = []
	if _m.estado.etapa != "gobierno":
		return res
	var cache := {}
	for carta in _m.catalogo_cartas:
		if carta["requisitos"]["ley"] == null or (categoria != "" and String(carta["categoria"]) != categoria) or _bloqueo_carta(carta) != "":
			continue
		var ley := String(carta["requisitos"]["ley"])
		var urgs: Array[Dictionary] = []
		for u in _cfg()["urgencias"]:
			var k := "%s|%s" % [ley, u["id"]]
			if not cache.has(k):
				cache[k] = prob_estimada(ley, u)
			var dias := int(u["dias"]) * 2 + int(_cfg()["dias_promulgacion"])
			urgs.append({"id": u["id"], "nombre": u["nombre"], "dias": u["dias"], "costo_capital": u["costo_capital"], "prob": cache[k],
					"semanas": ceili(float(dias) / float(_m.estado.dias_por_turno)), "alcanza": _m.estado.ind("capital") >= float(u["costo_capital"])})
		var flojo := float(urgs[0]["prob"]) < float(_cfg()["prob_aviso"])
		res.append({"carta_id": carta["id"], "titulo": carta["titulo"], "categoria": carta["categoria"], "tipo_ley": ley, "costo_mov": _m.costo_carta(carta),
				"urgencias": urgs, "corrector": _corrector(carta, String(urgs[0]["id"]), "apoyo_bajo") if flojo else {}})
	return res


func en_tramite() -> Array[Dictionary]:
	## Proyectos de la agenda en trámite: {carta_id, titulo, tipo_ley, urgencia, etapa, etapa_nombre, camara, semanas_restantes, prob_aprobacion, delegada}. Solo lectura.
	var _m := m
	var res: Array[Dictionary] = []
	for p in _m.estado.agenda:
		var dias := maxi(0, int(p["dia_etapa_fin"]) - _m.estado.dia_actual)
		if p["etapa"] == "primer_tramite":
			dias += int(urgencia(String(p["urgencia"]))["dias"])
		if p["etapa"] == "primer_tramite" or p["etapa"] == "segundo_tramite" or p["etapa"] == "comision_mixta" or p["etapa"] == "tc":
			dias += int(_cfg()["dias_promulgacion"])
		var voto := ETAPAS_VOTO.has(p["etapa"])
		res.append({"carta_id": p["carta_id"], "titulo": _m._cartas_por_id[p["carta_id"]]["titulo"], "tipo_ley": p["tipo_ley"], "urgencia": p["urgencia"],
				"etapa": p["etapa"], "etapa_nombre": NOMBRES_ETAPA[p["etapa"]], "camara": _camara_de(p) if voto else "", "dia_etapa_fin": p["dia_etapa_fin"],
				"semanas_restantes": maxi(1, ceili(float(dias) / float(_m.estado.dias_por_turno))), "delegada": p["delegada"],
				"prob_aprobacion": prob_estimada(String(p["tipo_ley"]), urgencia(String(p["urgencia"])), String(p["etapa"]))})
	return res


func presentar(carta_id: String, urgencia_id: String = "simple", ministro_id: String = "", delegar: bool = false, region_id: String = "") -> Dictionary:
	## Mensaje del Ejecutivo: presenta una ley del catálogo (aunque no esté en la mano) con una urgencia. Cuesta los movimientos de la carta
	## (nada si se delega en un ministro, con su riesgo de fallo) más el capital de la urgencia. Devuelve {ok, razon, corrector, ...}.
	var _m := m
	if not _m._cartas_por_id.has(carta_id):
		return {"ok": false, "razon": "carta_inexistente"}
	var carta: Dictionary = _m._cartas_por_id[carta_id]
	var urg := urgencia(urgencia_id)
	if urg.is_empty():
		return {"ok": false, "razon": "urgencia_invalida"}
	var est := estado_agenda()
	if not bool(est["puede_presentar"]):
		return {"ok": false, "razon": est["razon"]}
	var bloqueo := _bloqueo_carta(carta)
	if bloqueo != "":
		return {"ok": false, "razon": bloqueo}
	if ministro_id != "" and (not _m.catalogo_ministros.has(ministro_id) or not _m.estado.gabinete.has(ministro_id)):
		return {"ok": false, "razon": "ministro_fuera_del_gabinete"}
	if region_id != "" and not _m.regiones.existe(region_id):
		return {"ok": false, "razon": "region_invalida"}
	if delegar:
		var v := _m.gabinete.validar_delegacion(ministro_id)
		if not bool(v["ok"]):
			return v
	var costo := 0 if delegar else _m.costo_carta(carta, ministro_id)
	if costo > _m.estado.pa_actual:
		return {"ok": false, "razon": "pa_insuficiente", "costo": costo}
	if _m.estado.ind("capital") < float(urg["costo_capital"]):
		return {"ok": false, "razon": "capital_insuficiente", "corrector": _corrector(carta, urgencia_id, "capital")}
	var prob := prob_estimada(String(carta["requisitos"]["ley"]), urg)
	if prob < float(_cfg()["prob_minima"]):
		return {"ok": false, "razon": "quorum_insuficiente", "prob": prob, "corrector": _corrector(carta, urgencia_id, "quorum")}
	_m.estado.registrar_entrada("presentar", {"carta": carta_id, "urgencia": urgencia_id, "ministro": ministro_id, "region": region_id, "delegar": delegar})
	_m.estado.pa_actual -= costo
	_m.estado.delegadas_turno += 1 if delegar else 0
	_m.fx.sumar_ind("capital", -float(urg["costo_capital"]), "urgencia legislativa")
	var res := _m.cartas._jugar_en_gobierno(carta, ministro_id, region_id, delegar, urgencia_id)
	_m.coalicion.carta_jugada(carta)
	res["ok"] = true
	res["costo"] = costo
	res["prob"] = prob
	_m.estado.registrar_accion("presentar", {"id": carta_id, "urgencia": urgencia_id, "costo": costo, "delegada": delegar, "ministro": ministro_id})
	return res


func avanzar() -> Array[Dictionary]:
	## Cierre de semana: resuelve las etapas cuyo plazo venció (puede ser más de una por semana con urgencia alta) y devuelve los resultados finales.
	var _m := m
	var limite := _m.estado.dia_actual + _m.estado.dias_por_turno
	var finales: Array[Dictionary] = []
	var vivos: Array[Dictionary] = []
	for p in _m.estado.agenda:
		var final := {}
		while final.is_empty() and int(p["dia_etapa_fin"]) < limite:
			final = _resolver_etapa(p)
		if final.is_empty():
			vivos.append(p)
		else:
			finales.append(final)
	_m.estado.agenda = vivos
	return finales


func _resolver_etapa(p: Dictionary) -> Dictionary:
	var _m := m
	var etapa := String(p["etapa"])
	match etapa:
		"primer_tramite", "segundo_tramite", "comision_mixta":
			var voto := _m.legal.votar(_m.estado, String(p["tipo_ley"]), -1, _recargo(urgencia(String(p["urgencia"]))))
			var cam := _camara_de(p) if etapa != "comision_mixta" else ""
			var ok: bool = bool(voto["aprobada"]) if cam == "" else (int(voto[cam]) >= int(voto["min_" + cam]))
			_m.estado.registrar_accion("tramite", {"carta": p["carta_id"], "etapa": etapa, "ok": ok, "senado": voto["senado"], "camara": voto["camara"]})
			p["ultimo_voto"] = voto
			if not ok:
				return _rechazar(p, voto, {"recurso": false, "cae": false})
			if etapa == "primer_tramite":
				_entrar(p, "segundo_tramite")
			elif etapa == "segundo_tramite" and _m.rng.randf() < float(_cfg()["prob_comision_mixta"]):
				_entrar(p, "comision_mixta")
			else:
				var tc := _m.legal.resolver_tc(String(p["tipo_ley"]))
				p["tc_recurso"] = bool(tc["recurso"])
				p["tc_cae"] = bool(tc["cae"])
				_entrar(p, "tc" if bool(tc["recurso"]) else "promulgacion")
		"tc":
			if bool(p["tc_cae"]):
				_m.fx.sumar_ind("capital", -float(_m.catalogo_leyes["tc"]["capital_perdido_si_cae"]), "el Tribunal Constitucional derribó una ley")
				return _rechazar(p, p.get("ultimo_voto", {}), {"recurso": true, "cae": true}, false)
			_entrar(p, "promulgacion")
		_:
			_m.cartas._ejecutar_carta(_m._cartas_por_id[p["carta_id"]], float(p["escala"]), String(p["region"]))
			_m.estado.registrar_accion("votacion", {"carta": p["carta_id"], "aprobada": true, "agenda": true, "tc": bool(p["tc_recurso"])})
			return _final(p, true, p.get("ultimo_voto", {}), {"recurso": bool(p["tc_recurso"]), "cae": false})
	return {}


func _final(p: Dictionary, aprobada: bool, voto: Dictionary, tc: Dictionary) -> Dictionary:
	return {"carta_id": p["carta_id"], "aprobada": aprobada, "voto": voto, "tc": tc, "origen": String(p["origen"]), "agenda": true, "etapa": p["etapa"], "urgencia": p["urgencia"]}


func _rechazar(p: Dictionary, voto: Dictionary, tc: Dictionary, penal: bool = true) -> Dictionary:
	## El proyecto cae: pierde capital (si lo rechazó el Congreso), queda en espera unas semanas y la carta puede volver a presentarse después.
	var _m := m
	if penal:
		_m.fx.sumar_ind("capital", -float(_m.catalogo_leyes["congreso"]["penal_capital_rechazo"]), "el Congreso rechazó un proyecto")
	_m.estado.agenda_rechazos[String(p["carta_id"])] = _m.eventos.semana_abs() + int(_cfg()["cooldown_rechazo_semanas"])
	_m.estado.cartas_ejecutadas.erase(String(p["carta_id"]))
	_m.estado.registrar_accion("votacion", {"carta": p["carta_id"], "aprobada": false, "agenda": true, "etapa": p["etapa"], "tc": bool(tc["recurso"])})
	return _final(p, false, voto, tc)
