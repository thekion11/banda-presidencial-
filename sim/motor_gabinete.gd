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
	## true si el gabinete tiene un ministro en ese cargo (ministerio).
	return m.estado.gabinete.any(func(id: String) -> bool: return slot_de(id) == slot)


func de_ministerio(slot: String) -> String:
	## Id del ministro que ocupa un cargo ('' si está vacío).
	for id in m.estado.gabinete:
		if slot_de(id) == slot:
			return id
	return ""


func afinidad(id: String) -> float:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## 1 = el ministro piensa como tu partido; 0 = distancia ideológica máxima (ejes eco/inst).
	var pf: Dictionary = _m.catalogo_ministros[id].get("perfil", {"eco": 0.0, "inst": 0.0})
	var d := Vector2(float(pf["eco"]) - float(_m.estado.partido.get("eje_eco", 0.0)), float(pf["inst"]) - float(_m.estado.partido.get("eje_inst", 0.0))).length()
	return clampf(1.0 - d / float(_cfg()["identidad"]["distancia_max"]), 0.0, 1.0)


var _firma_tit: int = -1
var _titulares: Dictionary = {}  # categoría -> ministro titular, válido mientras no cambie el gabinete (se consulta en cada carta jugada)


func titular(categoria: String) -> String:
	## Ministro del gabinete que lleva las cartas de una categoría: el de mejor rendimiento (ahorro de costo y bono de ejecución) entre los de esa área.
	var firma := m.estado.gabinete.hash()
	if firma != _firma_tit:
		_titulares.clear()
		_firma_tit = firma
	if not _titulares.has(categoria):
		_titulares[categoria] = _calcular_titular(categoria)
	return _titulares[categoria]


func _calcular_titular(categoria: String) -> String:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var mejor := ""
	var mejor_p := -INF
	for id in _m.estado.gabinete:
		var mi: Dictionary = _m.catalogo_ministros[id]
		if String(mi["categoria_afin"]) != String(_m.catalogo_leyes["gabinete"]["categorias_alias"].get(categoria, categoria)) and String(mi["categoria_afin"]) != categoria:
			continue
		var w: Dictionary = _m.catalogo_leyes["gabinete"]["titular"]
		var pts := float(mi["bono_ejecucion"]) + float(w["peso_reduccion_costo"]) * float(mi["reduccion_costo_pa"]) - float(w["peso_riesgo_escandalo"]) * float(mi["riesgo_escandalo"])
		if pts > mejor_p or (is_equal_approx(pts, mejor_p) and id < mejor):
			mejor_p = pts
			mejor = id
	return mejor


func _puntaje(id: String, w: Dictionary, cubierta: bool) -> float:
	var mi: Dictionary = m.catalogo_ministros[id]
	return (0.0 if cubierta else float(w["cobertura"])) + float(w["ejecucion"]) * float(mi["bono_ejecucion"]) + float(w["ahorro"]) * float(mi["reduccion_costo_pa"]) \
			- float(w["escandalo"]) * float(mi["riesgo_escandalo"]) + float(w.get("afinidad", 0.0)) * afinidad(id)


func rellenar(elegidos: Array, modo: String = "") -> Array[Dictionary]:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## PR-05: completa el gabinete sin tocar lo ya escogido, un candidato por ministerio. Determinista (puntaje, desempate por id).
	## No cambia el estado: devuelve [{id, motivo}] solo de los añadidos, para mostrarlos y poder deshacerlos.
	var cfg: Dictionary = _cfg()["relleno"]
	var w: Dictionary = cfg["modos"].get(modo if modo != "" else String(cfg["defecto"]), cfg["modos"][cfg["defecto"]])
	var tam := int(_cfg()["tamano"])
	var actuales: Array[String] = []
	var slots := {}
	var cubiertas := {}
	for id in elegidos:
		if _m.catalogo_ministros.has(String(id)) and not slots.has(slot_de(String(id))):
			actuales.append(String(id))
			slots[slot_de(String(id))] = true
			cubiertas[String(_m.catalogo_ministros[String(id)]["categoria_afin"])] = true
	var res: Array[Dictionary] = []
	# El puntaje de cada candidato (sin el término de cobertura) no cambia durante el relleno: se calcula una vez, no en cada vuelta.
	var claves: Array = _m.catalogo_ministros.keys()
	var base := PackedFloat64Array()
	var cats := PackedStringArray()
	var cargos := PackedStringArray()
	var w_cob := float(w["cobertura"])
	for id in claves:
		var mi: Dictionary = _m.catalogo_ministros[id]
		base.append(float(w["ejecucion"]) * float(mi["bono_ejecucion"]) + float(w["ahorro"]) * float(mi["reduccion_costo_pa"]) \
				- float(w["escandalo"]) * float(mi["riesgo_escandalo"]) + float(w.get("afinidad", 0.0)) * afinidad(String(id)))
		cats.append(String(mi["categoria_afin"]))
		cargos.append(slot_de(String(id)))
	while actuales.size() < tam:
		var mejor := ""
		var mejor_p := -INF
		for i in range(claves.size()):
			if slots.has(cargos[i]):
				continue
			var pts := base[i] + (0.0 if cubiertas.has(cats[i]) else w_cob)
			if pts > mejor_p or (is_equal_approx(pts, mejor_p) and String(claves[i]) < mejor):
				mejor_p = pts
				mejor = String(claves[i])
		if mejor == "":
			break
		var mm: Dictionary = _m.catalogo_ministros[mejor]
		var nueva_cat := not cubiertas.has(String(mm["categoria_afin"]))
		actuales.append(mejor)
		slots[slot_de(mejor)] = true
		cubiertas[String(mm["categoria_afin"])] = true
		res.append({"id": mejor, "motivo": "%s: %s (%s)" % [mm["cartera"], String(mm.get("rasgo", "mejor rendimiento disponible")), "cubre un área sin ministro" if nueva_cat else "mejor puntaje"]})
	return res


func elegir(ids: Array) -> Dictionary:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Nombra el gabinete. Se puede cambiar en campaña o en la primera semana de gobierno (antes de gobernar).
	var est := _m.estado
	if est.etapa != "campana" and not (est.etapa == "gobierno" and est.turno_actual == 1):
		return {"ok": false, "razon": "gabinete_cerrado"}
	if ids.size() != int(_cfg()["tamano"]):
		return {"ok": false, "razon": "tamano_invalido", "tamano": int(_cfg()["tamano"])}
	var nuevo: Array[String] = []
	var slots := {}
	for id in ids:
		if not _m.catalogo_ministros.has(String(id)) or nuevo.has(String(id)) or slots.has(slot_de(String(id))):
			return {"ok": false, "razon": "ministro_invalido"}  # inexistente, repetido o dos candidatos del mismo ministerio
		nuevo.append(String(id))
		slots[slot_de(String(id))] = true
	est.registrar_entrada("gabinete", {"ids": nuevo})
	est.gabinete = nuevo
	est.registrar_accion("gabinete", {"ids": nuevo})
	_m.mazo.refiltrar_mano()
	return {"ok": true, "categorias": categorias_activas().keys()}


var _cats_firma: int = -1  # firma del gabinete con que se calculó _cats (se consulta una vez por carta: ~4.000 veces al rearmar el mazo)
var _cats: Dictionary = {}


func categorias_activas() -> Dictionary:
	## Categorías de cartas habilitadas por el gabinete actual (con caché por firma del gabinete).
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var firma := _m.estado.gabinete.hash()
	if firma != _cats_firma:
		_cats = {}
		for c in _cfg()["categorias_siempre"]:
			_cats[String(c)] = true
		for id in _m.estado.gabinete:
			_cats[String(_m.catalogo_ministros[id]["categoria_afin"])] = true
		_cats_firma = firma
	return _cats


func categoria_activa(cat: String) -> bool:
	## true si la categoría de cartas está habilitada por el gabinete.
	return categorias_activas().has(String(_cfg()["categorias_alias"].get(cat, cat)))


func anio_gobierno() -> int:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Año de mandato 1..N (en campaña cuenta como año 1).
	if _m.estado.etapa != "gobierno":
		return 1
	var dias_anio := int(_m._h("duracion_mandato_dias")) / int(_cfg()["anios_mandato"])
	return clampi(1 + (_m.estado.turno_actual - 1) * _m.estado.dias_por_turno / dias_anio, 1, int(_cfg()["anios_mandato"]))


func bloqueo(carta: Dictionary) -> Dictionary:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Única regla de disponibilidad: {} si la carta circula; si no, {"codigo": gabinete|anio_desde|anio_hasta|evento|fiscal|meta, "valor": ...}.
	var cat := String(carta["categoria"])
	var oposicion := _m.estado.etapa == "oposicion"
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
	if d.get("evento", null) != null and not _m.estado.eventos_ocurridos.has(String(d["evento"])):
		return {"codigo": "evento", "valor": String(d["evento"])}
	if d.get("fiscal_min", null) != null and _m.estado.ind("fiscal") < float(d["fiscal_min"]):
		return {"codigo": "fiscal", "valor": float(d["fiscal_min"])}
	if d.get("meta", null) != null and not _m.estado.metas_cumplidas.has(String(d["meta"])):
		return {"codigo": "meta", "valor": String(d["meta"])}
	return {}


var _ctx: Dictionary = {}  # contexto de disponibilidad fijo mientras dura un recorrido largo del catálogo (ver abrir_contexto)


var _ctx_nivel: int = 0


func abrir_contexto() -> void:
	## Los recorridos de ~2.000 cartas (rearmar el mazo) consultan lo mismo una y otra vez: categorías activas, año y fiscal se calculan una vez.
	## Entre abrir y cerrar no debe cambiar el estado. Mismo resultado que `bloqueo`, sin crear diccionarios por carta.
	_ctx_nivel += 1
	if _ctx_nivel == 1:
		_ctx = {"cats": categorias_activas(), "alias": _cfg()["categorias_alias"], "anio": anio_gobierno(), "fiscal": m.estado.ind("fiscal"), "opo": m.estado.etapa == "oposicion"}


func cerrar_contexto() -> void:
	## Libera el contexto de consulta abierto con abrir_contexto().
	_ctx_nivel = maxi(0, _ctx_nivel - 1)
	if _ctx_nivel == 0:
		_ctx = {}


func categoria_circula(cat: String) -> bool:
	## ¿Circulan las cartas de esta categoría (sin condiciones propias)? Igual que las primeras reglas de `bloqueo`.
	var oposicion := m.estado.etapa == "oposicion"
	if oposicion != (cat == "oposicion"):
		return false
	return oposicion or categoria_activa(cat)


func disponible(carta: Dictionary) -> bool:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Misma regla que `bloqueo` (que además explica el motivo), sin crear diccionarios. Dentro de abrir/cerrar_contexto usa valores ya calculados.
	var cat: String = carta["categoria"]
	var opo: bool
	var cats: Dictionary
	var alias: Dictionary
	if _ctx.is_empty():
		opo = _m.estado.etapa == "oposicion"
		if opo != (cat == "oposicion"):
			return false
		if opo:
			return true
		cats = categorias_activas()
		alias = _cfg()["categorias_alias"]
	else:
		opo = _ctx["opo"]
		if opo != (cat == "oposicion"):
			return false
		if opo:
			return true
		cats = _ctx["cats"]
		alias = _ctx["alias"]
	if not cats.has(String(alias.get(cat, cat))):
		return false
	var d: Variant = carta.get("disponibilidad", null)
	if d == null:
		return true
	if d.get("anio_desde", null) != null or d.get("anio_hasta", null) != null:
		var anio: int = _ctx["anio"] if not _ctx.is_empty() else anio_gobierno()
		if d.get("anio_desde", null) != null and anio < int(d["anio_desde"]):
			return false
		if d.get("anio_hasta", null) != null and anio > int(d["anio_hasta"]):
			return false
	if d.get("evento", null) != null and not _m.estado.eventos_ocurridos.has(String(d["evento"])):
		return false
	if d.get("fiscal_min", null) != null and (_ctx["fiscal"] if not _ctx.is_empty() else _m.estado.ind("fiscal")) < float(d["fiscal_min"]):
		return false
	if d.get("meta", null) != null and not _m.estado.metas_cumplidas.has(String(d["meta"])):
		return false
	return true


# ---------------------------------------------------------------- Identidad (Fase C)
var _firma_ident: int = -1
var _ident_suma: Dictionary = {}
var _ident_afin: float = 0.0


func amanecer() -> void:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Efectos semanales del gabinete: el estilo de cada ministro y la afinidad ideológica media con tu partido (leyes.json › gabinete.identidad).
	## Sin cambios en el gabinete ni en tu ideología el resultado es el mismo cada semana: se calcula una vez.
	if _m.estado.etapa != "gobierno" or _m.estado.gabinete.is_empty():
		return
	var cfg: Dictionary = _cfg()["identidad"]
	var firma := [_m.estado.gabinete.hash(), _m.estado.partido.get("eje_eco", 0.0), _m.estado.partido.get("eje_inst", 0.0)].hash()
	if firma != _firma_ident:
		_firma_ident = firma
		_ident_suma = {}
		_ident_afin = 0.0
		for id in _m.estado.gabinete:
			var est: Dictionary = cfg["estilos"].get(String(_m.catalogo_ministros[id].get("estilo", "")), {})
			for ind in est.keys():
				_ident_suma[ind] = float(_ident_suma.get(ind, 0.0)) + float(est[ind])
			_ident_afin += afinidad(id)
	for ind in _ident_suma.keys():
		_m.fx.sumar_ind(String(ind), float(_ident_suma[ind]), "estilo de tu gabinete")
	_m.fx.sumar_ind("cohesion", float(cfg["peso_afinidad"]) * (_ident_afin / float(_m.estado.gabinete.size()) - 0.5), "afinidad del gabinete con tu ideología")


func efecto_semanal_de(ids: Array) -> Dictionary:
	## Solo salida (no cambia el estado): efecto semanal que daría este gabinete por estilos y afinidad, {indicador: delta}; lo mismo que aplica `amanecer`.
	var cfg: Dictionary = _cfg()["identidad"]
	var res := {}
	var afin := 0.0
	for id in ids:
		var est: Dictionary = cfg["estilos"].get(String(m.catalogo_ministros[id].get("estilo", "")), {})
		for ind in est.keys():
			res[ind] = float(res.get(ind, 0.0)) + float(est[ind])
		afin += afinidad(String(id))
	if not ids.is_empty():
		res["cohesion"] = float(res.get("cohesion", 0.0)) + float(cfg["peso_afinidad"]) * (afin / float(ids.size()) - 0.5)
	return res


func ficha_candidato(id: String) -> Dictionary:
	## Solo salida: lo que el motor sabe de un candidato para mostrarlo (alias, cartera, estilo, afinidad 0 a 1 con tu partido, ahorro y bono, riesgo de escándalo).
	var mi: Dictionary = m.catalogo_ministros[id]
	return {"id": id, "alias": mi["alias"], "cartera": mi["cartera"], "ministerio": mi["ministerio"], "estilo": mi.get("estilo", ""), "rasgo": mi.get("rasgo", ""),
			"categoria_afin": mi["categoria_afin"], "afinidad": afinidad(id), "reduccion_costo_pa": int(mi["reduccion_costo_pa"]),
			"bono_ejecucion": float(mi["bono_ejecucion"]), "riesgo_escandalo": float(mi["riesgo_escandalo"])}


func efecto_de_nombrar(id: String) -> Dictionary:
	## Solo salida: cómo cambiaría el efecto semanal del gabinete si nombraras a `id` (reemplaza al que ocupe su ministerio, o se suma si está vacío): {indicador: diferencia por semana}.
	var nuevo: Array = []
	for x in m.estado.gabinete:
		if slot_de(String(x)) != slot_de(id):
			nuevo.append(x)
	nuevo.append(id)
	var antes := efecto_semanal_de(m.estado.gabinete)
	var despues := efecto_semanal_de(nuevo)
	var dif := {}
	for k in despues.keys() + antes.keys():
		var d := float(despues.get(k, 0.0)) - float(antes.get(k, 0.0))
		if not is_zero_approx(d):
			dif[k] = d
	return dif


func revisar_renuncia(actor_id: String) -> Dictionary:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Si tu relación con el ministro de ese ministerio cae bajo el umbral, renuncia y asume el mejor candidato restante (la relación parte de cero).
	var cfg: Dictionary = _cfg()["identidad"]
	var actual := de_ministerio(actor_id)
	if actual == "" or _m.eventos.relacion_actor(actor_id) > float(cfg["renuncia_bajo"]):
		return {}
	var w: Dictionary = _cfg()["relleno"]["modos"][_cfg()["relleno"]["defecto"]]
	var mejor := ""
	var mejor_p := -INF
	for id in _m.catalogo_ministros.keys():
		if slot_de(String(id)) == actor_id and String(id) != actual:
			var pts := _puntaje(String(id), w, true)
			if pts > mejor_p or (is_equal_approx(pts, mejor_p) and String(id) < mejor):
				mejor_p = pts
				mejor = String(id)
	if mejor == "":
		return {}
	_m.estado.gabinete[_m.estado.gabinete.find(actual)] = mejor
	for evt in _m.catalogo_eventos:  # el nuevo ministro empieza sin historia contigo
		if evt.has("actor") and String(evt["actor"]["id"]) == actor_id:
			_m.estado.decisiones.erase(String(evt["id"]))
	_m.estado.registrar_accion("renuncia", {"ministro": actual, "nuevo": mejor})
	return {"ministro": String(_m.catalogo_ministros[actual]["alias"]), "nuevo": String(_m.catalogo_ministros[mejor]["alias"])}


# ---------------------------------------------------------------- Delegación
func validar_delegacion(ministro_id: String) -> Dictionary:
	## Comprueba que se puede delegar en ese ministro (en gobierno, en el gabinete y bajo el tope por turno); devuelve {ok, razon}.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	if _m.estado.etapa != "gobierno":
		return {"ok": false, "razon": "ministro_no_disponible"}
	if not _m.estado.gabinete.has(ministro_id):
		return {"ok": false, "razon": "ministro_fuera_del_gabinete"}
	if _m.estado.delegadas_turno >= int(_m.catalogo_leyes["delegacion"]["max_por_turno"]):
		return {"ok": false, "razon": "limite_delegaciones"}
	return {"ok": true}


func prob_fallo(carta: Dictionary, ministro_id: String) -> float:
	## Probabilidad de que el ministro falle al ejecutar la carta delegada.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var d: Dictionary = _m.catalogo_leyes["delegacion"]
	var mi: Dictionary = _m.catalogo_ministros[ministro_id]
	var p := float(d["prob_fallo_base"]) + float(mi["riesgo_escandalo"]) * float(d["peso_riesgo_escandalo"]) \
			+ _m.estado.ind("riesgo_ejecucion") / 100.0 * float(d["peso_riesgo_ejecucion"])
	if mi["categoria_afin"] == carta["categoria"]:
		p -= float(mi["bono_ejecucion"]) * float(d["peso_bono_ejecucion"])
	else:
		p += float(d["recargo_fuera_de_area"])
	return clampf(p, float(d["prob_fallo_min"]), float(d["prob_fallo_max"]))


func resolver_delegacion(carta: Dictionary, ministro_id: String) -> Dictionary:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Sortea con la semilla si el ministro lo hace bien. Si falla: efecto reducido y posible escándalo.
	var d: Dictionary = _m.catalogo_leyes["delegacion"]
	var mi: Dictionary = _m.catalogo_ministros[ministro_id]
	var p := prob_fallo(carta, ministro_id)
	var res := {"fallo": false, "escandalo": false, "anulada": false, "prob_fallo": p, "escala": 1.0}
	if mi["categoria_afin"] == carta["categoria"]:
		res["escala"] = 1.0 + float(mi["bono_ejecucion"])
	if _m.rng.randf() < p:
		res["fallo"] = true
		res["escala"] = float(res["escala"]) * float(d["escala_si_falla"])
		res["anulada"] = _m.rng.randf() < float(d["prob_anula_si_falla"])  # el ministro la deja sin hacer: la carta se pierde
		if _m.rng.randf() < float(d["prob_escandalo_si_falla"]):
			res["escandalo"] = true
			var esc: Dictionary = _m.catalogo_leyes["escandalo"]
			_m.fx.delta_aprobacion(-float(esc["penal_aprobacion"]), "")
			_m.fx.sumar_ind("capital", -float(esc["penal_capital"]))
			_m.estado.registrar_accion("escandalo_ministro", {"ministro": ministro_id})
	return res

