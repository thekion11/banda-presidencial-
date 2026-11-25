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
	var ocurridos: Array[Dictionary] = []
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


func _director(pool: Array[Dictionary]) -> Dictionary:
	## Como máximo un evento aleatorio por semana, sin repeticiones cercanas (data/leyes.json «director_eventos»). Determinista con la semilla.
	var cfg: Dictionary = m.catalogo_leyes["director_eventos"]
	if m.rng.randf() >= float(cfg["prob_semana"]):
		return {}
	var quiere_decision := m.rng.randf() < float(cfg["prob_decision"])
	var ahora := semana_abs()
	for tipo in [quiere_decision, not quiere_decision]:  # si no hay del tipo pedido, se prueba el otro
		var cand: Array[Dictionary] = []
		var total := 0.0
		for evt in pool:
			if evt.has("opciones") == tipo and not _en_cooldown(evt, cfg, ahora):
				cand.append(evt)
				total += float(evt.get("peso_sorteo", 0.0))
		if cand.is_empty() or total <= 0.0:
			continue
		var r := m.rng.randf() * total
		for evt in cand:
			r -= float(evt.get("peso_sorteo", 0.0))
			if r <= 0.0:
				return evt
		return cand[cand.size() - 1]
	return {}


func aplicar_evento(evt: Dictionary) -> Dictionary:
	var res := {"id": evt["id"], "titulo": evt["titulo"], "descripcion": evt["descripcion"], "hora": evt["hora_etiqueta"], "votacion": null, "efectos": evt["efectos_base"]}
	var aplicar := true
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
	for ef in ops[idx]["efectos"]:
		m.fx.aplicar_efecto(ef, 1.0, "")
	m.estado.decisiones[evento_id] = idx
	m.estado.registrar_entrada("decision", {"evento": evento_id, "idx": idx})
	m.estado.registrar_accion("decision", {"evento": evento_id, "idx": idx})
	return {"ok": true, "efectos": ops[idx]["efectos"]}


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
