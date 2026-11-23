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
	## Gabinete inicial determinista: el primer ministro de cada categoría, en el orden de data/ministros.json, hasta completar el tamaño.
	var res: Array[String] = []
	var vistas := {}
	for id in m.catalogo_ministros.keys():
		var cat := String(m.catalogo_ministros[id]["categoria_afin"])
		if res.size() < int(_cfg()["tamano"]) and not vistas.has(cat):
			vistas[cat] = true
			res.append(String(id))
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


func disponible(carta: Dictionary) -> bool:
	if not categoria_activa(String(carta["categoria"])):
		return false
	var d: Variant = carta.get("disponibilidad", null)
	if d == null:
		return true
	var anio := anio_gobierno()
	if d.get("anio_desde", null) != null and anio < int(d["anio_desde"]):
		return false
	if d.get("anio_hasta", null) != null and anio > int(d["anio_hasta"]):
		return false
	if d.get("evento", null) != null and not m.estado.eventos_ocurridos.has(String(d["evento"])):
		return false
	if d.get("fiscal_min", null) != null and m.estado.ind("fiscal") < float(d["fiscal_min"]):
		return false
	if d.get("meta", null) != null and not m.estado.metas_cumplidas.has(String(d["meta"])):
		return false
	return true


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
	var res := {"fallo": false, "escandalo": false, "prob_fallo": p, "escala": 1.0}
	if mi["categoria_afin"] == carta["categoria"]:
		res["escala"] = 1.0 + float(mi["bono_ejecucion"])
	if m.rng.randf() < p:
		res["fallo"] = true
		res["escala"] = float(res["escala"]) * float(d["escala_si_falla"])
		if m.rng.randf() < float(d["prob_escandalo_si_falla"]):
			res["escandalo"] = true
			var esc: Dictionary = m.catalogo_leyes["escandalo"]
			m.fx.delta_aprobacion(-float(esc["penal_aprobacion"]), "")
			m.fx.sumar_ind("capital", -float(esc["penal_capital"]))
			m.estado.registrar_accion("escandalo_ministro", {"ministro": ministro_id})
	return res
