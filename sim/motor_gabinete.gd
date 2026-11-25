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


func rellenar(elegidos: Array, modo: String = "") -> Array[Dictionary]:
	## PR-05: completa el gabinete sin tocar lo ya escogido. Determinista (puntaje, desempate por id). No cambia el estado:
	## devuelve [{id, motivo}] solo de los ministros añadidos, para mostrarlos y poder deshacerlos.
	var cfg: Dictionary = _cfg()["relleno"]
	var w: Dictionary = cfg["modos"].get(modo if modo != "" else String(cfg["defecto"]), cfg["modos"][cfg["defecto"]])
	var tam := int(_cfg()["tamano"])
	var actuales: Array[String] = []
	var cubiertas := {}
	for id in elegidos:
		if m.catalogo_ministros.has(String(id)) and not actuales.has(String(id)):
			actuales.append(String(id))
			cubiertas[String(m.catalogo_ministros[String(id)]["categoria_afin"])] = true
	var res: Array[Dictionary] = []
	while actuales.size() < tam:
		var mejor := ""
		var mejor_p := -INF
		for id in m.catalogo_ministros.keys():
			if actuales.has(String(id)):
				continue
			var mi: Dictionary = m.catalogo_ministros[id]
			var nueva := not cubiertas.has(String(mi["categoria_afin"]))
			var pts := (float(w["cobertura"]) if nueva else 0.0) + float(w["ejecucion"]) * float(mi["bono_ejecucion"]) \
					+ float(w["ahorro"]) * float(mi["reduccion_costo_pa"]) - float(w["escandalo"]) * float(mi["riesgo_escandalo"])
			if pts > mejor_p or (is_equal_approx(pts, mejor_p) and String(id) < mejor):
				mejor_p = pts
				mejor = String(id)
		if mejor == "":
			break
		var mm: Dictionary = m.catalogo_ministros[mejor]
		var nueva_cat := not cubiertas.has(String(mm["categoria_afin"]))
		actuales.append(mejor)
		cubiertas[String(mm["categoria_afin"])] = true
		res.append({"id": mejor, "motivo": "%s: %s" % [mm["cartera"], "cubre un área sin ministro" if nueva_cat else "mejor rendimiento disponible"]})
	return res


func elegir(ids: Array) -> Dictionary:
	## Nombra el gabinete. Se puede cambiar en campaña o en la primera semana de gobierno (antes de gobernar).
	var est := m.estado
	if est.etapa != "campana" and not (est.etapa == "gobierno" and est.turno_actual == 1):
		return {"ok": false, "razon": "gabinete_cerrado"}
	if ids.size() != int(_cfg()["tamano"]):
		return {"ok": false, "razon": "tamano_invalido", "tamano": int(_cfg()["tamano"])}
	var nuevo: Array[String] = []
	for id in ids:
		if not m.catalogo_ministros.has(String(id)) or nuevo.has(String(id)):
			return {"ok": false, "razon": "ministro_invalido"}
		nuevo.append(String(id))
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
