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
	var mano: Dictionary = m.catalogo_leyes["mano"]
	return clampi(costo, int(mano["costo_min"]), int(mano["costo_max"]))  # DISENO_V2 §4: cada carta cuesta de 1 a 3 movimientos


func descartar_mano() -> void:
	## Cierre de turno: las cartas más antiguas sin jugar van al descarte para que la mano no se atasque con cartas imposibles de jugar.
	var n := mini(int(m.catalogo_leyes["mano"].get("descartes_por_turno", 0)), m.estado.mano.size())
	for _i in range(n):
		m.estado.descarte.append(String(m.estado.mano.pop_front()["id"]))


func es_real(carta: Dictionary) -> bool:
	return carta.get("meta", {}).get("tipo", "") in ["proyecto_publico", "proyecto_de_ley", "reforma_constitucional", "propuesta_constitucional"]


func reales_para_mazo() -> Array[String]:
	## Una carta por proyecto público real: en cada mazo circula un subconjunto sorteado con la semilla (leyes.json › mano.reales_en_mazo).
	var libres: Array[String] = []
	for c in m.catalogo_cartas:
		var id := String(c["id"])
		if es_real(c) and not m.estado.cartas_ejecutadas.has(id) and not m.estado.descarte.has(id) and m.gabinete.disponible(c) \
				and not m.estado.mano.any(func(x: Dictionary) -> bool: return x["id"] == id):
			libres.append(id)
	for i in range(libres.size() - 1, 0, -1):
		var j := m.rng.randi_range(0, i)
		var tmp := libres[i]
		libres[i] = libres[j]
		libres[j] = tmp
	var res: Array[String] = []
	res.assign(libres.slice(0, int(m.catalogo_leyes["mano"].get("reales_en_mazo", 15))))
	return res


func es_unica(carta: Dictionary) -> bool:
	return bool(carta.get("unica", false)) or carta["requisitos"]["ley"] != null or carta.has("obra") or es_real(carta) or carta.get("abre_propuesta_comite", null) != null


func vista_carta(idx: int, ministro_id: String = "") -> Dictionary:
	var carta: Dictionary = m.estado.mano[idx]
	var corr := {"aplica": false, "ratio": 1.0, "mensaje": ""}
	if m.estado.etapa == "gobierno":
		corr = m.legal.corregir(carta, m.estado)
	return {"costo": costo_carta(carta, ministro_id), "corrector": corr,
			"alcanza": costo_carta(carta, ministro_id) <= m.estado.pa_actual}


func jugar_carta(idx: int, ministro_id: String = "", region_id: String = "", delegada: bool = false) -> Dictionary:
	## `delegada`: la carta la ejecuta un ministro del gabinete sin gastar movimientos, pero puede salir mal (DISENO_V2 §5).
	if m.estado.etapa != "campana" and m.estado.etapa != "gobierno":
		return {"ok": false, "razon": "partida_terminada"}
	if idx < 0 or idx >= m.estado.mano.size():
		return {"ok": false, "razon": "indice_invalido"}
	if ministro_id != "" and (m.estado.etapa == "campana" or not m.catalogo_ministros.has(ministro_id)):
		return {"ok": false, "razon": "ministro_no_disponible"}
	if ministro_id != "" and not m.estado.gabinete.has(ministro_id):
		return {"ok": false, "razon": "ministro_fuera_del_gabinete"}  # solo el gabinete elegido da bonos y reduce costos
	if region_id != "" and not m.regiones.existe(region_id):
		return {"ok": false, "razon": "region_invalida"}
	if delegada:
		var v := m.gabinete.validar_delegacion(ministro_id)
		if not bool(v["ok"]):
			return v
	var carta: Dictionary = m.estado.mano[idx]
	var costo := 0 if delegada else costo_carta(carta, ministro_id)
	if costo > m.estado.pa_actual:
		return {"ok": false, "razon": "pa_insuficiente", "costo": costo}
	if m.estado.etapa == "gobierno" and es_unica(carta) and m.estado.cartas_ejecutadas.has(String(carta["id"])):
		return {"ok": false, "razon": "ya_ejecutada"}
	m.estado.registrar_entrada("jugar", {"idx": idx, "ministro": ministro_id, "region": region_id, "delegada": delegada})
	m.estado.pa_actual -= costo
	m.estado.delegadas_turno += 1 if delegada else 0
	m.estado.mano.remove_at(idx)
	m.estado.descarte.append(String(carta["id"]))
	var res: Dictionary
	if m.estado.etapa == "campana":
		res = _jugar_en_campana(carta, region_id)
	else:
		res = _jugar_en_gobierno(carta, ministro_id, region_id, delegada)
	m.coalicion.carta_jugada(carta)
	if bool(m.catalogo_leyes["mano"]["continua"]):
		m.robar_mano(int(m.catalogo_leyes["mano"]["tamano"]))  # mano continua: entra otra carta al instante
	m.mazo.reposicion()
	res["ok"] = true
	res["costo"] = costo
	m.estado.registrar_accion("carta", {"id": carta["id"], "costo": costo, "ministro": ministro_id, "region": region_id, "delegada": delegada})
	return res


func _jugar_en_campana(carta: Dictionary, region_id: String) -> Dictionary:
	var camp: Dictionary = m.catalogo_leyes["campana"]
	var ef_apr := 0.0
	for ef in carta["efectos"]:
		if ef["ind"] == "aprobacion":
			ef_apr += float(ef["delta"])
	var ya := m.estado.promesas_campana.any(func(p: Dictionary) -> bool: return p["carta_id"] == carta["id"])
	var delta := maxf(float(camp["piso_aprobacion_carta"]), (float(camp["aprobacion_base_por_carta"]) + ef_apr) * float(m._h("bono_aprobacion_promesa")))
	if ya:
		delta *= float(m.catalogo_leyes["repeticion_promesa"])
	else:
		m.estado.promesas_campana.append({"carta_id": carta["id"], "titulo": carta["titulo"],
				"turno": m.estado.turno_actual, "region": region_id, "cumplida": false})
	m.fx.delta_aprobacion(delta, region_id, true)
	return {"promesa": true, "delta_aprobacion": delta, "repetida": ya}


func _jugar_en_gobierno(carta: Dictionary, ministro_id: String, region_id: String, delegada: bool = false) -> Dictionary:
	var res := {"escandalo": false, "fallo": false, "corrector": {}, "proyecto": null, "propuesta": null}
	var corr := m.legal.corregir(carta, m.estado)
	res["corrector"] = corr
	var escala := float(corr["ratio"]) * m.equipo.mult_categoria(String(carta["categoria"]))  # asesores
	if delegada:
		var d := m.gabinete.resolver_delegacion(carta, ministro_id)
		escala *= float(d["escala"])
		res["fallo"] = d["fallo"]
		res["escandalo"] = d["escandalo"]
		res["prob_fallo"] = d["prob_fallo"]
		res["anulada"] = d["anulada"]
		if bool(d["anulada"]):
			m.estado.registrar_accion("delegacion_anulada", {"carta": carta["id"], "ministro": ministro_id})
			return res
	elif ministro_id != "":
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


func aprobar_propuesta(prop_id: String, variante_id: String, region_id: String = "", custom: Dictionary = {}, nombres: Dictionary = {}) -> Dictionary:
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
		custom = custom.duplicate()
		custom["ritmo"] = snappedf(float(custom.get("ritmo", 0.0)), 0.0001)  # los deslizadores se guardan con 4 decimales: el JSON no altera el cálculo
		custom["cobertura"] = snappedf(float(custom.get("cobertura", 0.0)), 0.0001)
		if not m.grafo.listo() or not m.grafo.estaciones_validas(custom.get("estaciones", [])):
			return {"ok": false, "razon": "trazado_invalido"}
		variante = m.grafo.variante_modificada(variante, custom["estaciones"], float(custom.get("ritmo", 0.0)), float(custom.get("cobertura", 0.0)))
		variante_id = "M"
	nombres = _nombres_limpios(nombres)
	var id_linea := "P%d" % (m.estado.lineas_jugador.size() + 1)
	m.estado.registrar_entrada("aprobar_propuesta", {"prop": prop_id, "variante": variante_id, "region": region_id, "custom": custom, "nombres": nombres})
	m.estado.pa_actual -= costo
	var ratio := clampf(float(prop["capacidad_musd"]) / float(variante["costo_musd"]), float(m.catalogo_leyes["dinamica"]["ratio_obra_min"]), 1.0)
	var region := region_id if region_id != "" else String(prop.get("region", ""))
	var final: Array = []
	for ef in variante["efectos"]:
		if ef["ind"] == "aprobacion":
			final.append({"ind": "aprobacion", "delta": float(ef["delta"]) * ratio})
		else:
			m.fx.aplicar_efecto(ef, ratio, "")
	var dias := roundi(float(variante["plazo_anios"]) * 365.0 * ratio)
	var titulo_obra := String(nombres.get("linea", "")) if String(nombres.get("linea", "")) != "" else String(prop["titulo"])
	m.obras.iniciar(m.estado, "%s · %s" % [titulo_obra, variante["nombre"]], dias, region, "", final, {"propuesta": prop_id, "variante": variante_id, "linea": id_linea})
	_registrar_linea(prop, prop_id, variante, variante_id, custom, nombres, id_linea)
	m.estado.propuestas_abiertas.erase(prop_id)
	m.estado.propuestas_aprobadas.append(prop_id)
	for c in m.catalogo_cartas:
		if c.get("abre_propuesta_comite", null) == prop_id:
			m.fx.marcar_cumplida(String(c["id"]))
	m.estado.registrar_accion("propuesta_aprobada", {"prop": prop_id, "variante": variante_id, "ratio": ratio})
	return {"ok": true, "ratio": ratio, "dias": dias, "costo": costo}




func _registrar_linea(prop: Dictionary, prop_id: String, variante: Dictionary, variante_id: String, custom: Dictionary, nombres: Dictionary, id_linea: String) -> void:
	## La línea aprobada (variante A/B/C o trazado propio) queda en el estado como línea del jugador: se dibuja en el mapa
	## en construcción y pasa a operativa al terminar su obra. Se reconstruye al reproducir el guardado (por eventos).
	var estaciones: Array = []
	if m.grafo.listo():
		var ids: Array = custom["estaciones"] if not custom.is_empty() else m.grafo.estaciones_base(variante)
		for id in ids:
			if m.grafo.pos.has(id):
				estaciones.append([snappedf(m.grafo.pos[id].x, 0.0001), snappedf(m.grafo.pos[id].y, 0.0001)])
	var trazado: Array = []
	for q in variante["trazado"]:
		trazado.append([snappedf(float(q[0]), 0.0001), snappedf(float(q[1]), 0.0001)])
	var nom_est: Array = []
	var dados: Array = nombres.get("estaciones", [])
	for i in range(estaciones.size()):
		var n := String(dados[i]) if i < dados.size() else ""
		nom_est.append(n if n != "" else "Estación %d" % (i + 1))
	var nombre_linea := String(nombres.get("linea", ""))
	m.estado.lineas_jugador.append({"id": id_linea, "nombre": nombre_linea if nombre_linea != "" else String(prop["titulo"]), "nombre_propio": nombre_linea != "",
			"prop": prop_id, "variante": variante_id, "trazado": trazado, "estaciones": estaciones, "nombres_estaciones": nom_est,
			"estado": "en_construccion", "dia_aprobacion": m.estado.dia_actual})


static func limpiar_nombre(texto: String, maximo: int) -> String:
	## Nombre elegido por el jugador: sin saltos ni caracteres de control, espacios colapsados y con largo máximo.
	var t := ""
	for i in range(texto.length()):
		var c := texto.unicode_at(i)
		t += " " if c < 32 or c == 127 else texto[i]
	return " ".join(t.strip_edges().split(" ", false)).left(maximo)


func _nombres_limpios(nombres: Dictionary) -> Dictionary:
	var est: Array = []
	for n in nombres.get("estaciones", []):
		est.append(limpiar_nombre(String(n), 26))
	return {"linea": limpiar_nombre(String(nombres.get("linea", "")), 30), "estaciones": est}


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
