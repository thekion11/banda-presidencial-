class_name MotorEventos
extends RefCounted
## Paso 2 del turno: eventos programados y sorteados con la semilla, con votación bicameral opcional.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


func semana_abs() -> int:
	## Semana absoluta de la carrera (los periodos reinician el turno, no esta cuenta).
	return m.estado.dias_carrera / m.estado.dias_por_turno + m.estado.turno_actual


func procesar_semana() -> Array[Dictionary]:
	var dia_inicio := m.estado.dia_actual
	var dia_fin := m.estado.dia_actual + m.estado.dias_por_turno - 1
	var ocurridos: Array[Dictionary] = _cumplir_pendientes()
	var aleatorios: Array[Dictionary] = []
	for evt in m.catalogo_eventos:
		if String(evt.get("etapa", "gobierno")) != m.estado.etapa:
			continue
		if m.estado.ciclo > 1 and evt.has("meta") and evt["meta"].has("fecha_real"):
			continue  # los hitos con fecha real ocurren una sola vez (primer periodo)
		if evt["tipo"] == "programado":
			var d_obj := int(evt["dia_objetivo"])
			if d_obj >= dia_inicio and d_obj <= dia_fin:
				ocurridos.append(aplicar_evento(evt))
		elif evt["tipo"] == "aleatorio_semilla":
			aleatorios.append(evt)
	var elegido := _director(aleatorios)
	if not elegido.is_empty():
		ocurridos.append(aplicar_evento(elegido))
	return ocurridos


func _cumple_requisitos(evt: Dictionary) -> bool:
	## Memoria de las decisiones: un evento puede exigir haber elegido cierta opción antes (`requiere.decision`) o una relación mínima/máxima con un actor.
	var rq: Variant = evt.get("requiere", null)
	if rq == null:
		return true
	if rq.has("decision") and int(m.estado.decisiones.get(String(rq["decision"]["evento"]), -1)) != int(rq["decision"]["idx"]):
		return false
	if rq.has("relacion"):
		var rel := relacion_actor(String(rq["relacion"]["actor"]))
		if rq["relacion"].has("max") and rel > float(rq["relacion"]["max"]):
			return false
		if rq["relacion"].has("min") and rel < float(rq["relacion"]["min"]):
			return false
	return true


func _cumplir_pendientes() -> Array[Dictionary]:
	## Consecuencias programadas por decisiones anteriores: efectos diferidos y eventos en cadena que ya tocan esta semana.
	var res: Array[Dictionary] = []
	var quedan: Array[Dictionary] = []
	var ahora := semana_abs()
	for p in m.estado.pendientes:
		if int(p["semana"]) > ahora:
			quedan.append(p)
			continue
		if String(p["tipo"]) == "efecto":
			for ef in p["efectos"]:
				m.fx.aplicar_efecto(ef, 1.0, "")
			res.append({"id": "dif_" + String(p["origen"]), "titulo": "Consecuencia de tu decisión", "descripcion": String(p.get("texto", "")), "hora": "09:00", "votacion": null, "efectos": p["efectos"], "menor": bool(p.get("carta", false))})
			m.estado.registrar_accion("consecuencia", {"origen": p["origen"]})
		else:
			for evt in m.catalogo_eventos:
				if String(evt["id"]) == String(p["evento"]):
					m.estado.decisiones.erase(String(evt["id"]))  # un seguimiento puede repetirse en otro periodo
					res.append(aplicar_evento(evt))
	m.estado.pendientes = quedan
	return res


func relacion_actor(id: String) -> float:
	for a in relaciones_actores():
		if String(a["id"]) == id:
			return float(a["relacion"])
	return float(m.catalogo_leyes["actores"]["base"])


func _en_cooldown(evt: Dictionary, cfg: Dictionary, ahora: int) -> bool:
	var oc: Dictionary = m.estado.eventos_ocurridos
	if oc.has(String(evt["id"])) and ahora - int(oc[String(evt["id"])]) < int(cfg["cooldown_evento"]):
		return true
	for otro in m.catalogo_eventos:  # familia y decisiones: se mira la última ocurrencia de cada evento
		if not oc.has(String(otro["id"])):
			continue
		var hace := ahora - int(oc[String(otro["id"])])
		if String(otro.get("familia", "")) == String(evt.get("familia", "?")) and hace < int(cfg["cooldown_familia"]):
			return true
		if evt.has("opciones") and otro.has("opciones") and hace < int(cfg["cooldown_decision"]):
			return true
	return false


func mes_actual() -> int:
	## Mes del calendario (1 a 12) de la semana en curso: desde el ciclo 2 hay un solo reloj; en el ciclo 1 la campaña y el gobierno tienen su fecha base.
	var cal: Dictionary = m.catalogo_leyes["calendario"]
	var e := m.estado
	var base := String(cal["fecha_inicio_mandato"] if (e.etapa == "gobierno" or e.ciclo > 1) else cal["fecha_inicio_campana"])
	var dias := (e.dia_actual - 1) if e.etapa == "gobierno" else (e.turno_actual - 1) * e.dias_por_turno
	var t := Time.get_unix_time_from_datetime_string(base + "T00:00:00") + (dias + (e.dias_carrera if e.ciclo > 1 else 0)) * 86400
	return int(Time.get_datetime_dict_from_unix_time(t)["month"])


func _peso_efectivo(evt: Dictionary, cfg: Dictionary, mes: int) -> float:
	## Peso relativo ajustado por estación (`meses`) y por contexto (`contexto`: indicador bajo o alto → multiplicador).
	var w := float(evt.get("peso_sorteo", 0.0))
	if evt.has("meses"):
		w *= float(cfg["estacion_en"]) if (evt["meses"] as Array).has(mes) else float(cfg["estacion_fuera"])
	for c in evt.get("contexto", []):
		var v := m.estado.ind(String(c["ind"]))
		if (c.has("bajo") and v < float(c["bajo"])) or (c.has("alto") and v > float(c["alto"])):
			w *= float(c["mult"])
	return w


func _silencio(ahora: int) -> int:
	var ultima := -1000
	for id in m.estado.eventos_ocurridos.keys():
		ultima = maxi(ultima, int(m.estado.eventos_ocurridos[id]))
	return ahora - ultima


func _decisiones_ultimo_anio(ahora: int) -> int:
	var n := 0
	for e in m.catalogo_eventos:
		if e.has("opciones") and e["tipo"] == "aleatorio_semilla" and m.estado.eventos_ocurridos.has(String(e["id"])) and ahora - int(m.estado.eventos_ocurridos[String(e["id"])]) < 52:
			n += 1
	return n


func _director(pool: Array[Dictionary]) -> Dictionary:
	## Director v2 (data/leyes.json «director_eventos»): a lo sumo un evento aleatorio por semana, con probabilidad que sube con el silencio,
	## decisiones entre un mínimo y un máximo por año, estaciones y contexto. Determinista con la semilla.
	var cfg: Dictionary = m.catalogo_leyes["director_eventos"]
	var ahora := semana_abs()
	var p := minf(float(cfg["prob_max"]), float(cfg["prob_semana"]) + float(cfg["ajuste_silencio"]) * float(maxi(0, _silencio(ahora) - int(cfg["silencio_libre"]))))
	if m.rng.randf() >= p:
		return {}
	var dec_anio := _decisiones_ultimo_anio(ahora)
	var p_dec := float(cfg["prob_decision"])
	if dec_anio < int(cfg["decisiones_min_anio"]):
		p_dec = 1.0 if m.estado.etapa == "gobierno" else p_dec  # bajo el mínimo anual, se piden decisiones
	elif dec_anio >= int(cfg["decisiones_max_anio"]):
		p_dec = 0.0
	var quiere_decision := m.rng.randf() < p_dec
	var mes := mes_actual()
	for tipo in [quiere_decision, not quiere_decision]:  # si no hay del tipo pedido, se prueba el otro
		var cand: Array[Dictionary] = []
		var total := 0.0
		for evt in pool:
			if evt.has("opciones") == tipo and not _en_cooldown(evt, cfg, ahora) and _cumple_requisitos(evt):
				cand.append(evt)
				total += _peso_efectivo(evt, cfg, mes)
		if cand.is_empty() or total <= 0.0:
			continue
		var r := m.rng.randf() * total
		for evt in cand:
			r -= _peso_efectivo(evt, cfg, mes)
			if r <= 0.0:
				return evt
		return cand[cand.size() - 1]
	return {}


func aplicar_evento(evt: Dictionary) -> Dictionary:
	var res := {"id": evt["id"], "titulo": evt["titulo"], "descripcion": evt["descripcion"], "hora": evt["hora_etiqueta"], "votacion": null, "efectos": evt["efectos_base"]}
	var aplicar := true
	var abs_ef := 0.0
	for ef in evt["efectos_base"]:
		abs_ef += absf(float(ef["delta"]))
	res["menor"] = evt["tipo"] == "aleatorio_semilla" and not evt.has("opciones") and evt["votacion"] == null and abs_ef <= float(m.catalogo_leyes["director_eventos"]["umbral_menor"])  # aviso breve, no pantalla completa
	var opciones: Variant = evt.get("opciones", null)
	if opciones != null:  # evento con decisión (PR-07/PR-08): los efectos dependen de la respuesta del jugador (decidir)
		res["opciones"] = opciones
		res["efectos"] = []
		aplicar = false
	var v: Variant = evt.get("votacion", null)
	if v != null:
		var voto := m.legal.votar(m.estado, String(v["tipo_ley"]), int(v["votos_firmes_base"]) if v.get("votos_firmes_base", null) != null else -1)
		var tc := m.legal.resolver_tc(String(v["tipo_ley"]), float(v.get("prob_exito_tc", -1.0)))
		aplicar = bool(voto["aprobada"]) and not bool(tc["cae"])
		res["votacion"] = {"voto": voto, "tc": tc, "aprobada": aplicar, "origen": String(v.get("origen", "camara"))}
		if not bool(voto["aprobada"]):
			m.fx.sumar_ind("capital", -float(m.catalogo_leyes["congreso"]["penal_capital_rechazo"]))
		elif bool(tc["cae"]):
			m.fx.sumar_ind("capital", -float(m.catalogo_leyes["tc"]["capital_perdido_si_cae"]))
	if aplicar and opciones == null:
		for ef in evt["efectos_base"]:
			m.fx.aplicar_efecto(ef, 1.0, "")
	m.estado.registrar_accion("evento", {"id": evt["id"], "aplicado": aplicar})
	m.estado.eventos_ocurridos[String(evt["id"])] = semana_abs()
	m.mazo.incorporar(m.mazo.ids_con_disponibilidad("evento", String(evt["id"])))  # desbloquea cartas ligadas a este evento
	return res


func relacion_exterior(iso: String, base: float) -> float:
	## Relación con un país vecino: valor base (data/vecinos.json) + efecto de los eventos «vecino» ya ocurridos en la partida (sin estado nuevo).
	var rel := base
	for evt in m.catalogo_eventos:
		if String(evt.get("pais", "")) == iso and m.estado.eventos_ocurridos.has(String(evt["id"])):
			rel += float(evt.get("relacion_delta", 0.0))
	return clampf(rel, 0.0, 100.0)


func decidir(evento_id: String, idx: int) -> Dictionary:
	## Responde a un evento con opciones (no gasta movimientos): aplica los efectos de la opción y queda registrado para el replay.
	var evt: Dictionary = {}
	for e in m.catalogo_eventos:
		if String(e["id"]) == evento_id:
			evt = e
	if evt.is_empty() or not evt.has("opciones") or not m.estado.eventos_ocurridos.has(evento_id):
		return {"ok": false, "razon": "evento_sin_decision"}
	if m.estado.decisiones.has(evento_id):
		return {"ok": false, "razon": "ya_decidido"}
	var ops: Array = evt["opciones"]
	if idx < 0 or idx >= ops.size():
		return {"ok": false, "razon": "opcion_invalida"}
	var op: Dictionary = ops[idx]
	for ef in op["efectos"]:
		m.fx.aplicar_efecto(ef, 1.0, "")
	var salio_mal := false
	if op.has("riesgo") and m.rng.randf() < float(op["riesgo"]["prob"]):  # opción arriesgada: puede salir mal
		salio_mal = true
		for ef in op["riesgo"]["efectos"]:
			m.fx.aplicar_efecto(ef, 1.0, "")
	var ahora := semana_abs()
	var futuro := 0
	if op.has("diferido"):
		futuro = int(op["diferido"]["semanas"])
		m.estado.pendientes.append({"tipo": "efecto", "semana": ahora + futuro, "origen": evento_id, "efectos": op["diferido"]["efectos"], "texto": String(op["diferido"].get("texto", ""))})
	if op.has("cadena"):
		futuro = maxi(futuro, int(op["cadena"]["semanas"]))
		m.estado.pendientes.append({"tipo": "evento", "semana": ahora + int(op["cadena"]["semanas"]), "origen": evento_id, "evento": String(op["cadena"]["evento"])})
	m.estado.decisiones[evento_id] = idx
	m.estado.registrar_entrada("decision", {"evento": evento_id, "idx": idx})
	m.estado.registrar_accion("decision", {"evento": evento_id, "idx": idx, "mal": salio_mal})
	var renuncia := m.gabinete.revisar_renuncia(String(evt["actor"]["id"])) if evt.has("actor") else {}
	return {"ok": true, "renuncia": renuncia, "efectos": op["efectos"], "salio_mal": salio_mal, "efectos_riesgo": op.get("riesgo", {}).get("efectos", []) if salio_mal else [], "futuro": futuro}


func relaciones_actores() -> Array[Dictionary]:
	## Marco de actores (PR-24): [{id, nombre, relacion}] solo de los actores con quienes ya decidiste algo; derivado de estado.decisiones.
	var cfg: Dictionary = m.catalogo_leyes["actores"]
	var suma := {}
	var nombres := {}
	for evt in m.catalogo_eventos:
		var eid := String(evt["id"])
		if not evt.has("actor") or not m.estado.decisiones.has(eid):
			continue
		var a: Dictionary = evt["actor"]
		suma[a["id"]] = float(suma.get(a["id"], 0.0)) + float(evt["opciones"][int(m.estado.decisiones[eid])].get("relacion", 0))
		nombres[a["id"]] = String(a["nombre"])
	var res: Array[Dictionary] = []
	for id in suma.keys():
		res.append({"id": id, "nombre": nombres[id], "relacion": clampf(float(cfg["base"]) + float(cfg["paso"]) * float(suma[id]), 0.0, 100.0)})
	res.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["relacion"]) > float(y["relacion"]))
	return res
