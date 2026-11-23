class_name MotorCartas
extends RefCounted
## Pasos 4-6 y 7 (leyes): jugar cartas, delegar en ministros, Corrector de Realismo, propuestas del Comité y votación de proyectos.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


func costo_carta(carta: Dictionary, ministro_id: String = "") -> int:
	var costo := int(carta["costo_pa"])
	if ministro_id != "" and m.catalogo_ministros.has(ministro_id):
		var mi: Dictionary = m.catalogo_ministros[ministro_id]
		if mi["categoria_afin"] == carta["categoria"]:
			costo -= int(mi["reduccion_costo_pa"])
	return maxi(1, costo)


func descartar_mano() -> void:
	## Cierre de turno: las cartas más antiguas sin jugar van al descarte para que la mano no se atasque con cartas imposibles de jugar.
	var n := mini(int(m.catalogo_leyes["mano"].get("descartes_por_turno", 0)), m.estado.mano.size())
	for _i in range(n):
		m.estado.descarte.append(String(m.estado.mano.pop_front()["id"]))


func es_unica(carta: Dictionary) -> bool:
	return carta["requisitos"]["ley"] != null or carta.has("obra") or carta.get("abre_propuesta_comite", null) != null


func vista_carta(idx: int, ministro_id: String = "") -> Dictionary:
	var carta: Dictionary = m.estado.mano[idx]
	var corr := {"aplica": false, "ratio": 1.0, "mensaje": ""}
	if m.estado.etapa == "gobierno":
		corr = m.legal.corregir(carta, m.estado)
	return {"costo": costo_carta(carta, ministro_id), "corrector": corr,
			"alcanza": costo_carta(carta, ministro_id) <= m.estado.pa_actual}


func jugar_carta(idx: int, ministro_id: String = "", region_id: String = "") -> Dictionary:
	if m.estado.etapa != "campana" and m.estado.etapa != "gobierno":
		return {"ok": false, "razon": "partida_terminada"}
	if idx < 0 or idx >= m.estado.mano.size():
		return {"ok": false, "razon": "indice_invalido"}
	if ministro_id != "" and (m.estado.etapa == "campana" or not m.catalogo_ministros.has(ministro_id)):
		return {"ok": false, "razon": "ministro_no_disponible"}
	if region_id != "" and not m.regiones.existe(region_id):
		return {"ok": false, "razon": "region_invalida"}
	var carta: Dictionary = m.estado.mano[idx]
	var costo := costo_carta(carta, ministro_id)
	if costo > m.estado.pa_actual:
		return {"ok": false, "razon": "pa_insuficiente", "costo": costo}
	if m.estado.etapa == "gobierno" and es_unica(carta) and m.estado.cartas_ejecutadas.has(String(carta["id"])):
		return {"ok": false, "razon": "ya_ejecutada"}
	m.estado.registrar_entrada("jugar", {"idx": idx, "ministro": ministro_id, "region": region_id})
	m.estado.pa_actual -= costo
	m.estado.mano.remove_at(idx)
	m.estado.descarte.append(String(carta["id"]))
	var res: Dictionary
	if m.estado.etapa == "campana":
		res = _jugar_en_campana(carta, region_id)
	else:
		res = _jugar_en_gobierno(carta, ministro_id, region_id)
	res["ok"] = true
	res["costo"] = costo
	m.estado.registrar_accion("carta", {"id": carta["id"], "costo": costo, "ministro": ministro_id, "region": region_id})
	return res


func _jugar_en_campana(carta: Dictionary, region_id: String) -> Dictionary:
	var camp: Dictionary = m.catalogo_leyes["campana"]
	var ef_apr := 0.0
	for ef in carta["efectos"]:
		if ef["ind"] == "aprobacion":
			ef_apr += float(ef["delta"])
	var ya := m.estado.promesas_campana.any(func(p: Dictionary) -> bool: return p["carta_id"] == carta["id"])
	var delta := maxf(0.5, (float(camp["aprobacion_base_por_carta"]) + ef_apr) * float(m._h("bono_aprobacion_promesa")))
	if ya:
		delta *= float(m.catalogo_leyes.get("repeticion_promesa", 0.5))
	else:
		m.estado.promesas_campana.append({"carta_id": carta["id"], "titulo": carta["titulo"],
				"turno": m.estado.turno_actual, "region": region_id, "cumplida": false})
	m.fx.delta_aprobacion(delta, region_id, true)
	return {"promesa": true, "delta_aprobacion": delta, "repetida": ya}


func _jugar_en_gobierno(carta: Dictionary, ministro_id: String, region_id: String) -> Dictionary:
	var res := {"escandalo": false, "corrector": {}, "proyecto": null, "propuesta": null}
	var corr := m.legal.corregir(carta, m.estado)
	res["corrector"] = corr
	var escala := float(corr["ratio"])
	if ministro_id != "":
		var mi: Dictionary = m.catalogo_ministros[ministro_id]
		if mi["categoria_afin"] == carta["categoria"]:
			escala *= 1.0 + float(mi["bono_ejecucion"])
		if m.rng.randf() < float(mi["riesgo_escandalo"]):
			res["escandalo"] = true
			var esc: Dictionary = m.catalogo_leyes["escandalo"]
			m.fx.delta_aprobacion(-float(esc["penal_aprobacion"]), "")
			m.fx.sumar_ind("capital", -float(esc["penal_capital"]))
			m.estado.registrar_accion("escandalo_ministro", {"ministro": ministro_id})
	if es_unica(carta):
		m.estado.cartas_ejecutadas[String(carta["id"])] = true
	var ley: Variant = carta["requisitos"]["ley"]
	var prop: Variant = carta.get("abre_propuesta_comite", null)
	if ley != null:
		var t := m.legal.tipo(String(ley))
		var proy := {"carta_id": carta["id"], "tipo_ley": ley, "escala": escala, "region": region_id,
				"origen": String(carta.get("camara_origen", "camara")), "dia_ingreso": m.estado.dia_actual,
				"dia_votacion": m.estado.dia_actual + int(t["dias_tramitacion_base"])}
		m.estado.proyectos_ley.append(proy)
		res["proyecto"] = proy
	elif prop != null:
		if not m.estado.propuestas_abiertas.has(String(prop)) and not m.estado.propuestas_aprobadas.has(String(prop)):
			m.estado.propuestas_abiertas.append(String(prop))
		res["propuesta"] = prop
	else:
		_ejecutar_carta(carta, escala, region_id)
	return res


func _ejecutar_carta(carta: Dictionary, escala: float, region_id: String) -> void:
	var obra: Variant = carta.get("obra", null)
	for ef in carta["efectos"]:
		if obra != null and ef["ind"] == "aprobacion":
			continue  # la aprobación de una obra llega con la inauguración
		m.fx.aplicar_efecto(ef, escala, region_id)
	if obra != null:
		var final: Array = []
		for ef in carta["efectos"]:
			if ef["ind"] == "aprobacion":
				final.append({"ind": "aprobacion", "delta": float(ef["delta"]) * escala})
		m.obras.iniciar(m.estado, String(obra["nombre"]), int(obra["dias_totales"]), region_id, String(carta["id"]), final)
	else:
		m.fx.marcar_cumplida(String(carta["id"]))


func aprobar_propuesta(prop_id: String, variante_id: String, region_id: String = "", custom: Dictionary = {}) -> Dictionary:
	if m.estado.etapa != "gobierno" or not m.estado.propuestas_abiertas.has(prop_id):
		return {"ok": false, "razon": "propuesta_no_disponible"}
	var prop: Dictionary = m.catalogo_propuestas[prop_id]
	var costo := int(prop["costo_pa"])
	if costo > m.estado.pa_actual:
		return {"ok": false, "razon": "pa_insuficiente", "costo": costo}
	var variante: Dictionary = {}
	for v in prop["variantes"]:
		if v["id"] == variante_id or (not custom.is_empty() and v["id"] == String(custom.get("base", ""))):
			variante = v
	if variante.is_empty():
		return {"ok": false, "razon": "variante_invalida"}
	if not custom.is_empty():  # trazado propio: estaciones sobre el grafo + sliders
		if not m.grafo.listo() or not m.grafo.estaciones_validas(custom.get("estaciones", [])):
			return {"ok": false, "razon": "trazado_invalido"}
		variante = m.grafo.variante_modificada(variante, custom["estaciones"], float(custom.get("ritmo", 0.0)), float(custom.get("cobertura", 0.0)))
		variante_id = "M"
	m.estado.registrar_entrada("aprobar_propuesta", {"prop": prop_id, "variante": variante_id, "region": region_id, "custom": custom})
	m.estado.pa_actual -= costo
	var ratio := clampf(float(prop["capacidad_musd"]) / float(variante["costo_musd"]), 0.1, 1.0)
	var region := region_id if region_id != "" else String(prop.get("region", ""))
	var final: Array = []
	for ef in variante["efectos"]:
		if ef["ind"] == "aprobacion":
			final.append({"ind": "aprobacion", "delta": float(ef["delta"]) * ratio})
		else:
			m.fx.aplicar_efecto(ef, ratio, "")
	var dias := roundi(float(variante["plazo_anios"]) * 365.0 * ratio)
	m.obras.iniciar(m.estado, "%s · %s" % [prop["titulo"], variante["nombre"]], dias, region, "", final, {"propuesta": prop_id, "variante": variante_id})
	m.estado.propuestas_abiertas.erase(prop_id)
	m.estado.propuestas_aprobadas.append(prop_id)
	for c in m.catalogo_cartas:
		if c.get("abre_propuesta_comite", null) == prop_id:
			m.fx.marcar_cumplida(String(c["id"]))
	m.estado.registrar_accion("propuesta_aprobada", {"prop": prop_id, "variante": variante_id, "ratio": ratio})
	return {"ok": true, "ratio": ratio, "dias": dias, "costo": costo}




func resolver_proyectos() -> Array[Dictionary]:
	var limite := m.estado.dia_actual + m.estado.dias_por_turno
	var pendientes: Array[Dictionary] = []
	var vistos: Array[Dictionary] = []
	for p in m.estado.proyectos_ley:
		if int(p["dia_votacion"]) >= limite:
			pendientes.append(p)
			continue
		var carta: Dictionary = m._cartas_por_id[p["carta_id"]]
		var voto := m.legal.votar(m.estado, String(p["tipo_ley"]))
		var tc := {"recurso": false, "cae": false}
		var ok := bool(voto["aprobada"])
		if ok:
			tc = m.legal.resolver_tc(String(p["tipo_ley"]))
			ok = not bool(tc["cae"])
			if not ok:
				m.fx.sumar_ind("capital", -float(m.catalogo_leyes["tc"]["capital_perdido_si_cae"]))
		else:
			m.fx.sumar_ind("capital", -float(m.catalogo_leyes["congreso"]["penal_capital_rechazo"]))
		if ok:
			_ejecutar_carta(carta, float(p["escala"]), String(p["region"]))
		m.estado.registrar_accion("votacion", {"carta": carta["id"], "aprobada": ok, "senado": voto["senado"], "camara": voto["camara"], "tc": tc["recurso"]})
		vistos.append({"carta_id": carta["id"], "aprobada": ok, "voto": voto, "tc": tc, "origen": String(p.get("origen", "camara"))})
	m.estado.proyectos_ley = pendientes
	return vistos
