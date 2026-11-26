class_name MotorEventos
extends RefCounted
## Paso 2 del turno: eventos programados y sorteados con la semilla, con votación bicameral opcional.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


var _por_id: Dictionary = {}  # índice del catálogo (se arma una vez; evita recorrer ~150 eventos en cada consulta)
var _por_etapa: Dictionary = {}  # etapa -> {"prog": [...], "alea": [...]}, en el orden del catálogo
var _decisiones_alea: Array[String] = []  # ids de eventos aleatorios con opciones
var _con_actor: Array[Dictionary] = []  # eventos que mueven la relación con un actor
var _n_catalogo: int = -1


func _indice() -> void:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	if _n_catalogo == _m.catalogo_eventos.size():
		return
	_n_catalogo = _m.catalogo_eventos.size()
	_por_id.clear()
	_por_etapa.clear()
	_decisiones_alea.clear()
	_con_actor.clear()
	for evt in _m.catalogo_eventos:
		_por_id[String(evt["id"])] = evt
		if evt.has("actor"):
			_con_actor.append(evt)
		var et := String(evt.get("etapa", "gobierno"))
		if not _por_etapa.has(et):
			var prog: Array[Dictionary] = []
			var con: Array[Dictionary] = []
			var sin: Array[Dictionary] = []
			_por_etapa[et] = {"prog": prog, "alea_dec": con, "alea_sin": sin}
		if evt["tipo"] == "programado":
			_por_etapa[et]["prog"].append(evt)
		elif evt["tipo"] == "aleatorio_semilla":
			if evt.has("opciones"):
				_por_etapa[et]["alea_dec"].append(evt)
				_decisiones_alea.append(String(evt["id"]))
			else:
				_por_etapa[et]["alea_sin"].append(evt)
	for et in _por_etapa.keys():
		var dias := PackedInt32Array()
		for evt in _por_etapa[et]["prog"]:
			dias.append(int(evt["dia_objetivo"]))
		_por_etapa[et]["dias"] = dias
		_por_etapa[et]["reg_dec"] = _registros(_por_etapa[et]["alea_dec"])
		_por_etapa[et]["reg_sin"] = _registros(_por_etapa[et]["alea_sin"])


func _registros(pool: Array) -> Dictionary:
	## Datos fijos de cada evento de un pool, en arrays paralelos (se arman una vez con el índice): id, familia, peso y banderas
	## (1: tiene requisitos; 2: su peso depende de la estación o del contexto).
	var ids := PackedStringArray()
	var fams := PackedStringArray()
	var pesos := PackedFloat64Array()
	var flags := PackedInt32Array()
	for evt in pool:
		ids.append(String(evt["id"]))
		fams.append(String(evt.get("familia", "?")))
		pesos.append(float(evt.get("peso_sorteo", 0.0)))
		flags.append((1 if evt.get("requiere", null) != null else 0) | (2 if (evt.has("meses") or evt.has("contexto")) else 0))
	return {"ids": ids, "fams": fams, "pesos": pesos, "flags": flags}


func semana_abs() -> int:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Semana absoluta de la carrera (los periodos reinician el turno, no esta cuenta).
	return _m.estado.dias_carrera / _m.estado.dias_por_turno + _m.estado.turno_actual


func procesar_semana() -> Array[Dictionary]:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var dia_inicio := _m.estado.dia_actual
	var dia_fin := _m.estado.dia_actual + _m.estado.dias_por_turno - 1
	var ocurridos: Array[Dictionary] = _cumplir_pendientes()
	_indice()
	var grupo: Dictionary = _por_etapa.get(_m.estado.etapa, {})
	var dias: PackedInt32Array = grupo.get("dias", PackedInt32Array())
	for i in range(dias.size()):
		if dias[i] < dia_inicio or dias[i] > dia_fin:
			continue
		var evt: Dictionary = grupo["prog"][i]
		if _m.estado.ciclo > 1 and evt.has("meta") and evt["meta"].has("fecha_real"):
			continue  # los hitos con fecha real ocurren una sola vez (primer periodo)
		ocurridos.append(aplicar_evento(evt))
	var elegido := _director(grupo)
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
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Consecuencias programadas por decisiones anteriores: efectos diferidos y eventos en cadena que ya tocan esta semana.
	var res: Array[Dictionary] = []
	var quedan: Array[Dictionary] = []
	var ahora := semana_abs()
	for p in _m.estado.pendientes:
		if int(p["semana"]) > ahora:
			quedan.append(p)
			continue
		if String(p["tipo"]) == "efecto":
			for ef in p["efectos"]:
				_m.fx.aplicar_efecto(ef, 1.0, "")
			res.append({"id": "dif_" + String(p["origen"]), "titulo": "Consecuencia de tu decisión", "descripcion": String(p.get("texto", "")), "hora": "09:00", "votacion": null, "efectos": p["efectos"], "menor": bool(p.get("carta", false))})
			_m.estado.registrar_accion("consecuencia", {"origen": p["origen"]})
		else:
			_indice()
			if _por_id.has(String(p["evento"])):
				var evt: Dictionary = _por_id[String(p["evento"])]
				_m.estado.decisiones.erase(String(evt["id"]))  # un seguimiento puede repetirse en otro periodo
				res.append(aplicar_evento(evt))
	_m.estado.pendientes = quedan
	return res


var _rel_firma: int = -1
var _rel_mapa: Dictionary = {}  # actor -> relación, válido mientras no cambien las decisiones (se consulta en cada carta jugada)


func relacion_actor(id: String) -> float:
	var firma := m.estado.decisiones.hash()
	if firma != _rel_firma:
		_rel_firma = firma
		_rel_mapa.clear()
		for a in relaciones_actores():
			_rel_mapa[String(a["id"])] = float(a["relacion"])
	return float(_rel_mapa.get(id, m.catalogo_leyes["actores"]["base"]))


var _ult_fam: Dictionary = {}  # familia -> semana del último evento de esa familia (se actualiza en aplicar_evento; antes se recorría todo lo ocurrido)
var _ult_dec: int = -1000  # semana de la última decisión
var _dec_sem: Dictionary = {}  # id de decisión aleatoria -> semana en que ocurrió por última vez
var _n_visto: int = 0
var _cd_decision: bool = false  # hubo una decisión hace menos de cooldown_decision (se fija al empezar a elegir)


func reconstruir() -> void:
	## Tras restaurar una instantánea: rehace el historial incremental del director a partir de lo ocurrido (es lo mismo que fue acumulando aplicar_evento).
	_indice()
	_ult_fam.clear()
	_ult_dec = -1000
	_dec_sem.clear()
	_ultima = -1000
	var oc: Dictionary = m.estado.eventos_ocurridos
	for id in oc.keys():
		var evt: Dictionary = _por_id.get(String(id), {})
		if evt.is_empty():
			continue
		var sem := int(oc[id])
		_ultima = maxi(_ultima, sem)
		_ult_fam[String(evt.get("familia", ""))] = maxi(int(_ult_fam.get(String(evt.get("familia", "")), -1000)), sem)
		if evt.has("opciones"):
			_ult_dec = maxi(_ult_dec, sem)
			if evt["tipo"] == "aleatorio_semilla":
				_dec_sem[String(id)] = sem
	_n_visto = oc.size()


func _sincronizar() -> void:
	## Si lo ocurrido se reinició (nuevo periodo de la carrera), el historial incremental también.
	if m.estado.eventos_ocurridos.size() < _n_visto:
		_ult_fam.clear()
		_ult_dec = -1000
		_dec_sem.clear()
		_ultima = -1000
	_n_visto = m.estado.eventos_ocurridos.size()


func _preparar_cooldowns(cfg: Dictionary, ahora: int) -> void:
	_indice()
	_sincronizar()
	_cd_decision = ahora - _ult_dec < int(cfg["cooldown_decision"])


func _en_cooldown(evt: Dictionary, cfg: Dictionary, ahora: int) -> bool:
	var oc: Dictionary = m.estado.eventos_ocurridos
	if oc.has(String(evt["id"])) and ahora - int(oc[String(evt["id"])]) < int(cfg["cooldown_evento"]):
		return true
	if _ult_fam.has(String(evt.get("familia", "?"))) and ahora - int(_ult_fam[String(evt.get("familia", "?"))]) < int(cfg["cooldown_familia"]):
		return true
	return evt.has("opciones") and _cd_decision


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


var _ultima: int = -1000  # semana del último evento ocurrido (se actualiza en aplicar_evento; con lo ocurrido vacío no vale)


func _silencio(ahora: int) -> int:
	return ahora + 1000 if m.estado.eventos_ocurridos.is_empty() else ahora - _ultima


func _decisiones_ultimo_anio(ahora: int) -> int:
	var n := 0
	for id in _dec_sem:
		if ahora - int(_dec_sem[id]) < 52:
			n += 1
	return n


func _director(grupo: Dictionary) -> Dictionary:
	if grupo.is_empty():
		return {}
	return _elegir(grupo)


func _elegir(grupo: Dictionary) -> Dictionary:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Director v2 (data/leyes.json «director_eventos»): a lo sumo un evento aleatorio por semana, con probabilidad que sube con el silencio,
	## decisiones entre un mínimo y un máximo por año, estaciones y contexto. Determinista con la semilla.
	var cfg: Dictionary = _m.catalogo_leyes["director_eventos"]
	var ahora := semana_abs()
	var silencio := _silencio(ahora)
	var p := minf(float(cfg["prob_max"]), float(cfg["prob_semana"]) + float(cfg["ajuste_silencio"]) * float(maxi(0, silencio - int(cfg["silencio_libre"]))))
	if silencio < int(cfg["silencio_max"]) and _m.rng.randf() >= p:
		return {}  # la mayoría de las semanas no pasa nada: se sale antes de preparar nada (pasada la espera máxima, el evento es seguro)
	_preparar_cooldowns(cfg, ahora)
	var dec_anio := _decisiones_ultimo_anio(ahora)
	var p_dec := float(cfg["prob_decision"])
	if dec_anio < int(cfg["decisiones_min_anio"]):
		p_dec = 1.0 if _m.estado.etapa == "gobierno" else p_dec  # bajo el mínimo anual, se piden decisiones
	elif dec_anio >= int(cfg["decisiones_max_anio"]):
		p_dec = 0.0
	var quiere_decision := _m.rng.randf() < p_dec
	var mes := 0  # se calcula solo si algún candidato depende de la estación
	var dec := ["alea_dec", "reg_dec", true]
	var sin := ["alea_sin", "reg_sin", false]
	var orden := [dec, sin] if quiere_decision else [sin, dec]  # si no hay del tipo pedido, se prueba el otro
	var oc: Dictionary = _m.estado.eventos_ocurridos
	var cd_evento := int(cfg["cooldown_evento"])
	var cd_familia := int(cfg["cooldown_familia"])
	for par in orden:
		var pool: Array = grupo[par[0]]
		if par[2] and _cd_decision:
			continue  # una decisión reciente: ninguna decisión esta semana
		var rg: Dictionary = grupo[par[1]]
		var ids: PackedStringArray = rg["ids"]
		var fams: PackedStringArray = rg["fams"]
		var base: PackedFloat64Array = rg["pesos"]
		var flags: PackedInt32Array = rg["flags"]
		var cand: PackedInt32Array = []
		var pesos: PackedFloat64Array = []
		var total := 0.0
		for i in range(ids.size()):
			var id := ids[i]
			if oc.has(id) and ahora - int(oc[id]) < cd_evento:
				continue
			if _ult_fam.has(fams[i]) and ahora - int(_ult_fam[fams[i]]) < cd_familia:
				continue
			var f := flags[i]
			if f & 1 and not _cumple_requisitos(pool[i]):
				continue
			var w := base[i]
			if f & 2:
				if mes == 0 and (pool[i] as Dictionary).has("meses"):
					mes = mes_actual()
				w = _peso_efectivo(pool[i], cfg, mes)
			cand.append(i)
			pesos.append(w)
			total += w
		if cand.is_empty() or total <= 0.0:
			continue
		var r := _m.rng.randf() * total
		for j in range(cand.size()):
			r -= pesos[j]
			if r <= 0.0:
				return pool[cand[j]]
		return pool[cand[cand.size() - 1]]
	return {}


func aplicar_evento(evt: Dictionary) -> Dictionary:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var res := {"id": evt["id"], "titulo": evt["titulo"], "descripcion": evt["descripcion"], "hora": evt["hora_etiqueta"], "votacion": null, "efectos": evt["efectos_base"]}
	if evt.has("opciones") and (evt["opciones"] as Array).any(func(o: Dictionary) -> bool: return o.has("congreso")):
		res["descripcion"] = "%s Con tu bancada y tus aliados, tu postura prospera con un %d %% de probabilidad." % [String(evt["descripcion"]), roundi(100.0 * prob_bloqueo())]
	if evt.has("escena"):
		res["escena"] = evt["escena"]  # debate o entrevista de varias rondas: la interfaz muestra el avance
	var aplicar := true
	var abs_ef := 0.0
	for ef in evt["efectos_base"]:
		abs_ef += absf(float(ef["delta"]))
	res["menor"] = evt["tipo"] == "aleatorio_semilla" and not evt.has("opciones") and evt["votacion"] == null and abs_ef <= float(_m.catalogo_leyes["director_eventos"]["umbral_menor"])  # aviso breve, no pantalla completa
	var opciones: Variant = evt.get("opciones", null)
	if opciones != null:  # evento con decisión (PR-07/PR-08): los efectos dependen de la respuesta del jugador (decidir)
		res["opciones"] = opciones
		res["efectos"] = []
		aplicar = false
	var v: Variant = evt.get("votacion", null)
	if v != null:
		var voto := _m.legal.votar(_m.estado, String(v["tipo_ley"]), int(v["votos_firmes_base"]) if v.get("votos_firmes_base", null) != null else -1)
		var tc := _m.legal.resolver_tc(String(v["tipo_ley"]), float(v.get("prob_exito_tc", -1.0)))
		aplicar = bool(voto["aprobada"]) and not bool(tc["cae"])
		res["votacion"] = {"voto": voto, "tc": tc, "aprobada": aplicar, "origen": String(v.get("origen", "camara"))}
		if not bool(voto["aprobada"]):
			_m.fx.sumar_ind("capital", -float(_m.catalogo_leyes["congreso"]["penal_capital_rechazo"]))
		elif bool(tc["cae"]):
			_m.fx.sumar_ind("capital", -float(_m.catalogo_leyes["tc"]["capital_perdido_si_cae"]))
	if aplicar and opciones == null:
		for ef in evt["efectos_base"]:
			_m.fx.aplicar_efecto(ef, 1.0, "")
	_m.estado.registrar_accion("evento", {"id": evt["id"], "aplicado": aplicar})
	_indice()
	_sincronizar()
	var ahora := semana_abs()
	_m.estado.eventos_ocurridos[String(evt["id"])] = ahora
	_n_visto = _m.estado.eventos_ocurridos.size()
	_ultima = ahora
	_ult_fam[String(evt.get("familia", ""))] = ahora
	if evt.has("opciones"):
		_ult_dec = ahora
		if evt["tipo"] == "aleatorio_semilla":
			_dec_sem[String(evt["id"])] = ahora
	_m.mazo.incorporar(_m.mazo.ids_con_disponibilidad("evento", String(evt["id"])))  # desbloquea cartas ligadas a este evento
	return res


func relacion_exterior(iso: String, base: float) -> float:
	## Relación con un país vecino: valor base (data/vecinos.json) + efecto de los eventos «vecino» ya ocurridos en la partida (sin estado nuevo).
	var rel := base
	for evt in m.catalogo_eventos:
		if String(evt.get("pais", "")) == iso and m.estado.eventos_ocurridos.has(String(evt["id"])):
			rel += float(evt.get("relacion_delta", 0.0))
	return clampf(rel, 0.0, 100.0)


func decidir(evento_id: String, idx: int) -> Dictionary:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Responde a un evento con opciones (no gasta movimientos): aplica los efectos de la opción y queda registrado para el replay.
	_indice()
	var evt: Dictionary = _por_id.get(evento_id, {})
	if evt.is_empty() or not evt.has("opciones") or not _m.estado.eventos_ocurridos.has(evento_id):
		return {"ok": false, "razon": "evento_sin_decision"}
	if _m.estado.decisiones.has(evento_id):
		return {"ok": false, "razon": "ya_decidido"}
	var ops: Array = evt["opciones"]
	if idx < 0 or idx >= ops.size():
		return {"ok": false, "razon": "opcion_invalida"}
	var op: Dictionary = ops[idx]
	for ef in op["efectos"]:
		_m.fx.aplicar_efecto(ef, 1.0, "")
	var salio_mal := false
	var exito: Array = []
	if op.has("congreso"):  # votación del gobierno rival: tu bancada decide si la postura prospera
		var pb := prob_bloqueo()
		salio_mal = _m.rng.randf() >= pb
		exito = op["congreso"]["exito"] if not salio_mal else []
		for ef in exito:
			_m.fx.aplicar_efecto(ef, 1.0, "")
		if salio_mal:
			for ef in op["congreso"]["derrota"]:
				_m.fx.aplicar_efecto(ef, 1.0, "")
	elif op.has("riesgo") and _m.rng.randf() < float(op["riesgo"]["prob"]):  # opción arriesgada: puede salir mal
		salio_mal = true
		for ef in op["riesgo"]["efectos"]:
			_m.fx.aplicar_efecto(ef, 1.0, "")
	var ahora := semana_abs()
	var futuro := 0
	if op.has("diferido"):
		futuro = int(op["diferido"]["semanas"])
		_m.estado.pendientes.append({"tipo": "efecto", "semana": ahora + futuro, "origen": evento_id, "efectos": op["diferido"]["efectos"], "texto": String(op["diferido"].get("texto", ""))})
	if op.has("cadena"):
		futuro = maxi(futuro, int(op["cadena"]["semanas"]))
		_m.estado.pendientes.append({"tipo": "evento", "semana": ahora + int(op["cadena"]["semanas"]), "origen": evento_id, "evento": String(op["cadena"]["evento"])})
	_m.estado.decisiones[evento_id] = idx
	_m.estado.registrar_entrada("decision", {"evento": evento_id, "idx": idx})
	_m.estado.registrar_accion("decision", {"evento": evento_id, "idx": idx, "mal": salio_mal})
	var renuncia := _m.gabinete.revisar_renuncia(String(evt["actor"]["id"])) if evt.has("actor") else {}
	return {"ok": true, "renuncia": renuncia, "efectos": op["efectos"] + exito, "salio_mal": salio_mal, "efectos_riesgo": op.get("riesgo", {}).get("efectos", op.get("congreso", {}).get("derrota", [])) if salio_mal else [], "futuro": futuro, "congreso": op.has("congreso")}


func prob_bloqueo() -> float:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Probabilidad de que tu postura prospere en el Congreso (oposición): bancada propia y aliados del Senado más la cohesión del partido.
	var c: Dictionary = _m.catalogo_leyes["oposicion"]["congreso"]
	var propios := float(_m.estado.partido.get("escanos_propios", _m.catalogo_leyes["congreso"]["escanos_propios_defecto"])) + float(_m.estado.apoyo_coalicion["senado"])
	var p := float(c["base"]) + float(c["peso_escanos"]) * propios / float(_m.catalogo_leyes["hemiciclo"]["total_senadores"]) + float(c["peso_cohesion"]) * (_m.estado.ind("cohesion") - 50.0)
	return clampf(p, float(c["min"]), float(c["max"]))


func relaciones_actores() -> Array[Dictionary]:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Marco de actores (PR-24): [{id, nombre, relacion}] solo de los actores con quienes ya decidiste algo; derivado de estado.decisiones.
	var cfg: Dictionary = _m.catalogo_leyes["actores"]
	var suma := {}
	var nombres := {}
	_indice()
	for evt in _con_actor:
		var eid := String(evt["id"])
		if not _m.estado.decisiones.has(eid):
			continue
		var a: Dictionary = evt["actor"]
		suma[a["id"]] = float(suma.get(a["id"], 0.0)) + float(evt["opciones"][int(_m.estado.decisiones[eid])].get("relacion", 0))
		nombres[a["id"]] = String(a["nombre"])
	var res: Array[Dictionary] = []
	for id in suma.keys():
		res.append({"id": id, "nombre": nombres[id], "relacion": clampf(float(cfg["base"]) + float(cfg["paso"]) * float(suma[id]), 0.0, 100.0)})
	res.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["relacion"]) > float(y["relacion"]))
	return res
