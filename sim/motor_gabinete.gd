class_name MotorGabinete
extends RefCounted
## Gabinete (ministros nombrados), disponibilidad de cartas y delegación en ministros (DISENO_V2 §1, §2 y §5).

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


func _cfg() -> Dictionary:
	return m.catalogo_leyes["gabinete"]


func por_defecto() -> Array[String]:
	## Gabinete inicial determinista: el relleno automático equilibrado sobre un gabinete vacío (con tamaño 25, todos los ministerios).
	var res: Array[String] = []
	for n in rellenar([], ""):
		res.append(String(n["id"]))
	return res


func slot_de(id: String) -> String:
	## Ministerio (cargo) que ocupa un candidato: cada ministerio tiene 3 candidatos con perfil propio (Fase C).
	return String(m.catalogo_ministros[id].get("ministerio", id)) if m.catalogo_ministros.has(id) else id


func tiene_ministerio(slot: String) -> bool:
	return m.estado.gabinete.any(func(id: String) -> bool: return slot_de(id) == slot)


func de_ministerio(slot: String) -> String:
	for id in m.estado.gabinete:
		if slot_de(id) == slot:
			return id
	return ""


func afinidad(id: String) -> float:
	## 1 = el ministro piensa como tu partido; 0 = distancia ideológica máxima (ejes eco/inst).
	var pf: Dictionary = m.catalogo_ministros[id].get("perfil", {"eco": 0.0, "inst": 0.0})
	var d := Vector2(float(pf["eco"]) - float(m.estado.partido.get("eje_eco", 0.0)), float(pf["inst"]) - float(m.estado.partido.get("eje_inst", 0.0))).length()
	return clampf(1.0 - d / float(_cfg()["identidad"]["distancia_max"]), 0.0, 1.0)


func titular(categoria: String) -> String:
	## Ministro del gabinete que lleva las cartas de una categoría: el de mejor rendimiento (ahorro de costo y bono de ejecución) entre los de esa área.
	var mejor := ""
	var mejor_p := -INF
	for id in m.estado.gabinete:
		var mi: Dictionary = m.catalogo_ministros[id]
		if String(mi["categoria_afin"]) != String(m.catalogo_leyes["gabinete"]["categorias_alias"].get(categoria, categoria)) and String(mi["categoria_afin"]) != categoria:
			continue
		var pts := float(mi["bono_ejecucion"]) + 0.1 * float(mi["reduccion_costo_pa"]) - 0.1 * float(mi["riesgo_escandalo"])
		if pts > mejor_p or (is_equal_approx(pts, mejor_p) and id < mejor):
			mejor_p = pts
			mejor = id
	return mejor


func _puntaje(id: String, w: Dictionary, cubierta: bool) -> float:
	var mi: Dictionary = m.catalogo_ministros[id]
	return (0.0 if cubierta else float(w["cobertura"])) + float(w["ejecucion"]) * float(mi["bono_ejecucion"]) + float(w["ahorro"]) * float(mi["reduccion_costo_pa"]) \
			- float(w["escandalo"]) * float(mi["riesgo_escandalo"]) + float(w.get("afinidad", 0.0)) * afinidad(id)


func rellenar(elegidos: Array, modo: String = "") -> Array[Dictionary]:
	## PR-05: completa el gabinete sin tocar lo ya escogido, un candidato por ministerio. Determinista (puntaje, desempate por id).
	## No cambia el estado: devuelve [{id, motivo}] solo de los añadidos, para mostrarlos y poder deshacerlos.
	var cfg: Dictionary = _cfg()["relleno"]
	var w: Dictionary = cfg["modos"].get(modo if modo != "" else String(cfg["defecto"]), cfg["modos"][cfg["defecto"]])
	var tam := int(_cfg()["tamano"])
	var actuales: Array[String] = []
	var slots := {}
	var cubiertas := {}
	for id in elegidos:
		if m.catalogo_ministros.has(String(id)) and not slots.has(slot_de(String(id))):
			actuales.append(String(id))
			slots[slot_de(String(id))] = true
			cubiertas[String(m.catalogo_ministros[String(id)]["categoria_afin"])] = true
	var res: Array[Dictionary] = []
	while actuales.size() < tam:
		var mejor := ""
		var mejor_p := -INF
		for id in m.catalogo_ministros.keys():
			if slots.has(slot_de(String(id))):
				continue
			var pts := _puntaje(String(id), w, cubiertas.has(String(m.catalogo_ministros[id]["categoria_afin"])))
			if pts > mejor_p or (is_equal_approx(pts, mejor_p) and String(id) < mejor):
				mejor_p = pts
				mejor = String(id)
		if mejor == "":
			break
		var mm: Dictionary = m.catalogo_ministros[mejor]
		var nueva_cat := not cubiertas.has(String(mm["categoria_afin"]))
		actuales.append(mejor)
		slots[slot_de(mejor)] = true
		cubiertas[String(mm["categoria_afin"])] = true
		res.append({"id": mejor, "motivo": "%s: %s (%s)" % [mm["cartera"], String(mm.get("rasgo", "mejor rendimiento disponible")), "cubre un área sin ministro" if nueva_cat else "mejor puntaje"]})
	return res


func elegir(ids: Array) -> Dictionary:
	## Nombra el gabinete. Se puede cambiar en campaña o en la primera semana de gobierno (antes de gobernar).
	var est := m.estado
	if est.etapa != "campana" and not (est.etapa == "gobierno" and est.turno_actual == 1):
		return {"ok": false, "razon": "gabinete_cerrado"}
	if ids.size() != int(_cfg()["tamano"]):
		return {"ok": false, "razon": "tamano_invalido", "tamano": int(_cfg()["tamano"])}
	var nuevo: Array[String] = []
	var slots := {}
	for id in ids:
		if not m.catalogo_ministros.has(String(id)) or nuevo.has(String(id)) or slots.has(slot_de(String(id))):
			return {"ok": false, "razon": "ministro_invalido"}  # inexistente, repetido o dos candidatos del mismo ministerio
		nuevo.append(String(id))
		slots[slot_de(String(id))] = true
	est.registrar_entrada("gabinete", {"ids": nuevo})
	est.gabinete = nuevo
	est.registrar_accion("gabinete", {"ids": nuevo})
	m.mazo.refiltrar_mano()
	return {"ok": true, "categorias": categorias_activas().keys()}


func categorias_activas() -> Dictionary:
	var cats := {}
	for c in _cfg()["categorias_siempre"]:
		cats[String(c)] = true
	for id in m.estado.gabinete:
		cats[String(m.catalogo_ministros[id]["categoria_afin"])] = true
	return cats


func categoria_activa(cat: String) -> bool:
	return categorias_activas().has(String(_cfg()["categorias_alias"].get(cat, cat)))


func anio_gobierno() -> int:
	## Año de mandato 1..N (en campaña cuenta como año 1).
	if m.estado.etapa != "gobierno":
		return 1
	var dias_anio := int(m._h("duracion_mandato_dias")) / int(_cfg()["anios_mandato"])
	return clampi(1 + (m.estado.turno_actual - 1) * m.estado.dias_por_turno / dias_anio, 1, int(_cfg()["anios_mandato"]))


func bloqueo(carta: Dictionary) -> Dictionary:
	## Única regla de disponibilidad: {} si la carta circula; si no, {"codigo": gabinete|anio_desde|anio_hasta|evento|fiscal|meta, "valor": ...}.
	var cat := String(carta["categoria"])
	var oposicion := m.estado.etapa == "oposicion"
	if oposicion != (cat == "oposicion"):  # en oposición solo circulan sus cartas; en campaña y gobierno, nunca
		return {"codigo": "etapa", "valor": "oposicion" if cat == "oposicion" else "gobierno"}
	if oposicion:
		return {}
	if not categoria_activa(cat):
		return {"codigo": "gabinete", "valor": cat}
	var d: Variant = carta.get("disponibilidad", null)
	if d == null:
		return {}
	var anio := anio_gobierno()
	if d.get("anio_desde", null) != null and anio < int(d["anio_desde"]):
		return {"codigo": "anio_desde", "valor": int(d["anio_desde"])}
	if d.get("anio_hasta", null) != null and anio > int(d["anio_hasta"]):
		return {"codigo": "anio_hasta", "valor": int(d["anio_hasta"])}
	if d.get("evento", null) != null and not m.estado.eventos_ocurridos.has(String(d["evento"])):
		return {"codigo": "evento", "valor": String(d["evento"])}
	if d.get("fiscal_min", null) != null and m.estado.ind("fiscal") < float(d["fiscal_min"]):
		return {"codigo": "fiscal", "valor": float(d["fiscal_min"])}
	if d.get("meta", null) != null and not m.estado.metas_cumplidas.has(String(d["meta"])):
		return {"codigo": "meta", "valor": String(d["meta"])}
	return {}


func disponible(carta: Dictionary) -> bool:
	return bloqueo(carta).is_empty()


# ---------------------------------------------------------------- Identidad (Fase C)
func amanecer() -> void:
	## Efectos semanales del gabinete: el estilo de cada ministro y la afinidad ideológica media con tu partido (leyes.json › gabinete.identidad).
	if m.estado.etapa != "gobierno" or m.estado.gabinete.is_empty():
		return
	var cfg: Dictionary = _cfg()["identidad"]
	var suma := {}
	var afin := 0.0
	for id in m.estado.gabinete:
		var est: Dictionary = cfg["estilos"].get(String(m.catalogo_ministros[id].get("estilo", "")), {})
		for ind in est.keys():
			suma[ind] = float(suma.get(ind, 0.0)) + float(est[ind])
		afin += afinidad(id)
	for ind in suma.keys():
		m.fx.sumar_ind(String(ind), float(suma[ind]))
	m.fx.sumar_ind("cohesion", float(cfg["peso_afinidad"]) * (afin / float(m.estado.gabinete.size()) - 0.5))


func revisar_renuncia(actor_id: String) -> Dictionary:
	## Si tu relación con el ministro de ese ministerio cae bajo el umbral, renuncia y asume el mejor candidato restante (la relación parte de cero).
	var cfg: Dictionary = _cfg()["identidad"]
	var actual := de_ministerio(actor_id)
	if actual == "" or m.eventos.relacion_actor(actor_id) > float(cfg["renuncia_bajo"]):
		return {}
	var w: Dictionary = _cfg()["relleno"]["modos"][_cfg()["relleno"]["defecto"]]
	var mejor := ""
	var mejor_p := -INF
	for id in m.catalogo_ministros.keys():
		if slot_de(String(id)) == actor_id and String(id) != actual:
			var pts := _puntaje(String(id), w, true)
			if pts > mejor_p or (is_equal_approx(pts, mejor_p) and String(id) < mejor):
				mejor_p = pts
				mejor = String(id)
	if mejor == "":
		return {}
	m.estado.gabinete[m.estado.gabinete.find(actual)] = mejor
	for evt in m.catalogo_eventos:  # el nuevo ministro empieza sin historia contigo
		if evt.has("actor") and String(evt["actor"]["id"]) == actor_id:
			m.estado.decisiones.erase(String(evt["id"]))
	m.estado.registrar_accion("renuncia", {"ministro": actual, "nuevo": mejor})
	return {"ministro": String(m.catalogo_ministros[actual]["alias"]), "nuevo": String(m.catalogo_ministros[mejor]["alias"])}


# ---------------------------------------------------------------- Delegación
func validar_delegacion(ministro_id: String) -> Dictionary:
	if m.estado.etapa != "gobierno":
		return {"ok": false, "razon": "ministro_no_disponible"}
	if not m.estado.gabinete.has(ministro_id):
		return {"ok": false, "razon": "ministro_fuera_del_gabinete"}
	if m.estado.delegadas_turno >= int(m.catalogo_leyes["delegacion"]["max_por_turno"]):
		return {"ok": false, "razon": "limite_delegaciones"}
	return {"ok": true}


func prob_fallo(carta: Dictionary, ministro_id: String) -> float:
	var d: Dictionary = m.catalogo_leyes["delegacion"]
	var mi: Dictionary = m.catalogo_ministros[ministro_id]
	var p := float(d["prob_fallo_base"]) + float(mi["riesgo_escandalo"]) * float(d["peso_riesgo_escandalo"]) \
			+ m.estado.ind("riesgo_ejecucion") / 100.0 * float(d["peso_riesgo_ejecucion"])
	if mi["categoria_afin"] == carta["categoria"]:
		p -= float(mi["bono_ejecucion"]) * float(d["peso_bono_ejecucion"])
	else:
		p += float(d["recargo_fuera_de_area"])
	return clampf(p, float(d["prob_fallo_min"]), float(d["prob_fallo_max"]))


func resolver_delegacion(carta: Dictionary, ministro_id: String) -> Dictionary:
	## Sortea con la semilla si el ministro lo hace bien. Si falla: efecto reducido y posible escándalo.
	var d: Dictionary = m.catalogo_leyes["delegacion"]
	var mi: Dictionary = m.catalogo_ministros[ministro_id]
	var p := prob_fallo(carta, ministro_id)
	var res := {"fallo": false, "escandalo": false, "anulada": false, "prob_fallo": p, "escala": 1.0}
	if mi["categoria_afin"] == carta["categoria"]:
		res["escala"] = 1.0 + float(mi["bono_ejecucion"])
	if m.rng.randf() < p:
		res["fallo"] = true
		res["escala"] = float(res["escala"]) * float(d["escala_si_falla"])
		res["anulada"] = m.rng.randf() < float(d["prob_anula_si_falla"])  # el ministro la deja sin hacer: la carta se pierde
		if m.rng.randf() < float(d["prob_escandalo_si_falla"]):
			res["escandalo"] = true
			var esc: Dictionary = m.catalogo_leyes["escandalo"]
			m.fx.delta_aprobacion(-float(esc["penal_aprobacion"]), "")
			m.fx.sumar_ind("capital", -float(esc["penal_capital"]))
			m.estado.registrar_accion("escandalo_ministro", {"ministro": ministro_id})
	return res
