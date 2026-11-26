class_name MotorCartas
extends RefCounted
## Pasos 4-6 y 7 (leyes): jugar cartas, delegar en ministros, Corrector de Realismo, propuestas del Comité y votación de proyectos.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


func _con_titular(carta: Dictionary, ministro_id: String) -> String:
	## Sin delegar, en gobierno, la carta la lleva el ministro titular de su área (Fase C): su ahorro de costo y su bono cuentan.
	if ministro_id != "" or m.estado.etapa != "gobierno":
		return ministro_id
	return m.gabinete.titular(String(carta["categoria"]))


func costo_carta(carta: Dictionary, ministro_id: String = "") -> int:
	## Costo en movimientos de una carta, con el descuento del ministro y los bonos del gabinete y los asesores.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	ministro_id = _con_titular(carta, ministro_id)
	var costo := int(carta["costo_pa"])
	if ministro_id != "" and _m.catalogo_ministros.has(ministro_id):
		var mi: Dictionary = _m.catalogo_ministros[ministro_id]
		if mi["categoria_afin"] == carta["categoria"]:
			costo -= int(mi["reduccion_costo_pa"])
	var mano: Dictionary = _m.catalogo_leyes["mano"]
	return clampi(costo, int(mano["costo_min"]), int(mano["costo_max"]))  # DISENO_V2 §4: cada carta cuesta de 1 a 3 movimientos


func descartar_mano() -> void:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Cierre de turno: las cartas más antiguas sin jugar van al descarte para que la mano no se atasque con cartas imposibles de jugar.
	var n := mini(int(_m.catalogo_leyes["mano"].get("descartes_por_turno", 0)), _m.estado.mano.size())
	for _i in range(n):
		_m.estado.descarte.append(String(_m.estado.mano.pop_front()["id"]))


func es_real(carta: Dictionary) -> bool:
	## true si la carta es de un proyecto real (usa el índice; cae a su tipo si no está en el catálogo).
	var id: String = carta["id"]
	var x: Dictionary = m.indices.es_real
	if not x.has(id):
		return IndicesCartas.tipo_real(carta)  # carta suelta que no está en el catálogo (pruebas)
	return x[id]


func no_reales() -> Array[Dictionary]:
	## Cartas diseñadas (no basadas en un proyecto real), del índice compartido.
	return m.indices.no_reales


func reales_para_mazo() -> Array[String]:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Una carta por proyecto público real: en cada mazo circula un subconjunto sorteado con la semilla (leyes.json › mano.reales_en_mazo).
	## Sorteo sin reposición entre las cartas elegibles (no ejecutadas, no apartadas, con su categoría y condiciones vigentes): se prueban cartas
	## al azar hasta juntar las necesarias (~30 pruebas) en vez de revisar y mezclar las ~1.700; si casi nada es elegible, se revisan todas.
	var ix := _m.indices
	var k := int(_m.catalogo_leyes["mano"].get("reales_en_mazo", 15))
	var n := ix.r_ids.size()
	var res: Array[String] = []
	if n == 0 or k <= 0:
		return res
	var apartadas := {}  # descarte y mano como conjunto
	for id in _m.estado.descarte:
		apartadas[id] = true
	for x in _m.estado.mano:
		apartadas[String(x["id"])] = true
	_m.gabinete.abrir_contexto()
	var cat_ok := PackedByteArray()
	for cat in ix.r_cats:
		cat_ok.append(1 if _m.gabinete.categoria_circula(cat) else 0)
	var ejec: Dictionary = _m.estado.cartas_ejecutadas
	var rng := _m.rng
	var vistas := {}
	var intentos := k * 40
	while res.size() < k and intentos > 0:
		intentos -= 1
		var i := rng.randi_range(0, n - 1)
		if vistas.has(i):
			continue
		vistas[i] = true
		var id := ix.r_ids[i]
		if ejec.has(id) or apartadas.has(id):
			continue
		if ix.r_cond[i] == 0:
			if cat_ok[ix.r_cat[i]] == 0:
				continue
		elif not _m.gabinete.disponible(ix.reales[i]):
			continue
		res.append(id)
	if res.size() < k:  # pocas elegibles: barrido completo (poco frecuente)
		var libres := PackedInt32Array()
		for i in range(n):
			var id := ix.r_ids[i]
			if ejec.has(id) or apartadas.has(id) or res.has(id):
				continue
			if (ix.r_cond[i] == 0 and cat_ok[ix.r_cat[i]] == 1) or (ix.r_cond[i] == 1 and _m.gabinete.disponible(ix.reales[i])):
				libres.append(i)
		for t in range(libres.size() - 1, 0, -1):
			var j := rng.randi_range(0, t)
			var tmp := libres[t]
			libres[t] = libres[j]
			libres[j] = tmp
		for t in range(mini(libres.size(), k - res.size())):
			res.append(ix.r_ids[libres[t]])
	_m.gabinete.cerrar_contexto()
	return res


func es_unica(carta: Dictionary) -> bool:
	## true si la carta solo puede ejecutarse una vez en el gobierno.
	return bool(carta.get("unica", false)) or carta["requisitos"]["ley"] != null or carta.has("obra") or es_real(carta) or carta.get("abre_propuesta_comite", null) != null


func vista_carta(idx: int, ministro_id: String = "") -> Dictionary:
	## Datos de una carta de la mano para la interfaz: costo, corrector de realismo y si alcanzan los movimientos.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var carta: Dictionary = _m.estado.mano[idx]
	var corr := {"aplica": false, "ratio": 1.0, "mensaje": ""}
	if _m.estado.etapa == "gobierno":
		corr = _m.legal.corregir(carta, _m.estado)
	return {"costo": costo_carta(carta, ministro_id), "corrector": corr,
			"alcanza": costo_carta(carta, ministro_id) <= _m.estado.pa_actual}


func jugar_carta(idx: int, ministro_id: String = "", region_id: String = "", delegada: bool = false) -> Dictionary:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## `delegada`: la carta la ejecuta un ministro del gabinete sin gastar movimientos, pero puede salir mal (DISENO_V2 §5).
	if not MotorTurno.ETAPAS_JUEGO.has(_m.estado.etapa):
		return {"ok": false, "razon": "partida_terminada"}
	if idx < 0 or idx >= _m.estado.mano.size():
		return {"ok": false, "razon": "indice_invalido"}
	if ministro_id != "" and (_m.estado.etapa != "gobierno" or not _m.catalogo_ministros.has(ministro_id)):
		return {"ok": false, "razon": "ministro_no_disponible"}
	if ministro_id != "" and not _m.estado.gabinete.has(ministro_id):
		return {"ok": false, "razon": "ministro_fuera_del_gabinete"}  # solo el gabinete elegido da bonos y reduce costos
	if region_id != "" and not _m.regiones.existe(region_id):
		return {"ok": false, "razon": "region_invalida"}
	if delegada:
		var v := _m.gabinete.validar_delegacion(ministro_id)
		if not bool(v["ok"]):
			return v
	var carta: Dictionary = _m.estado.mano[idx]
	var costo := 0 if delegada else costo_carta(carta, ministro_id)
	if costo > _m.estado.pa_actual:
		return {"ok": false, "razon": "pa_insuficiente", "costo": costo}
	if _m.estado.etapa == "gobierno" and es_unica(carta) and _m.estado.cartas_ejecutadas.has(String(carta["id"])):
		return {"ok": false, "razon": "ya_ejecutada"}
	_m.estado.registrar_entrada("jugar", {"idx": idx, "ministro": ministro_id, "region": region_id, "delegada": delegada})
	_m.estado.pa_actual -= costo
	_m.estado.delegadas_turno += 1 if delegada else 0
	_m.estado.mano.remove_at(idx)
	_m.estado.descarte.append(String(carta["id"]))
	var res: Dictionary
	if _m.estado.etapa == "campana":
		res = _jugar_en_campana(carta, region_id)
	else:
		res = _jugar_en_gobierno(carta, ministro_id, region_id, delegada)
	_m.coalicion.carta_jugada(carta)
	if bool(_m.catalogo_leyes["mano"]["continua"]):
		_m.robar_mano(int(_m.catalogo_leyes["mano"]["tamano"]))  # mano continua: entra otra carta al instante
	_m.mazo.reposicion()
	res["ok"] = true
	res["costo"] = costo
	_m.estado.registrar_accion("carta", {"id": carta["id"], "costo": costo, "ministro": ministro_id, "region": region_id, "delegada": delegada})
	return res


func _jugar_en_campana(carta: Dictionary, region_id: String) -> Dictionary:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var camp: Dictionary = _m.catalogo_leyes["campana"]
	var ef_apr := 0.0
	for ef in carta["efectos"]:
		if ef["ind"] == "aprobacion":
			ef_apr += float(ef["delta"])
	var ya := _m.estado.promesas_campana.any(func(p: Dictionary) -> bool: return p["carta_id"] == carta["id"])
	var delta := maxf(float(camp["piso_aprobacion_carta"]), (float(camp["aprobacion_base_por_carta"]) + ef_apr) * float(_m._h("bono_aprobacion_promesa")))
	if ya:
		delta *= float(_m.catalogo_leyes["repeticion_promesa"])
	else:
		_m.estado.promesas_campana.append({"carta_id": carta["id"], "titulo": carta["titulo"],
				"turno": _m.estado.turno_actual, "region": region_id, "cumplida": false})
	_m.fx.delta_aprobacion(delta, region_id, true)
	return {"promesa": true, "delta_aprobacion": delta, "repetida": ya}


func _jugar_en_gobierno(carta: Dictionary, ministro_id: String, region_id: String, delegada: bool = false) -> Dictionary:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var res := {"escandalo": false, "fallo": false, "corrector": {}, "proyecto": null, "propuesta": null}
	var corr := _m.legal.corregir(carta, _m.estado)
	res["corrector"] = corr
	var escala := float(corr["ratio"]) * _m.equipo.mult_categoria(String(carta["categoria"])) * _m.coalicion.mult_carta(carta)  # asesores y aliados
	if delegada:
		var d := _m.gabinete.resolver_delegacion(carta, ministro_id)
		escala *= float(d["escala"])
		res["fallo"] = d["fallo"]
		res["escandalo"] = d["escandalo"]
		res["prob_fallo"] = d["prob_fallo"]
		res["anulada"] = d["anulada"]
		if bool(d["anulada"]):
			_m.estado.registrar_accion("delegacion_anulada", {"carta": carta["id"], "ministro": ministro_id})
			return res
	elif _con_titular(carta, ministro_id) != "":
		var auto := ministro_id == ""  # titular automático: el riesgo de escándalo cuenta solo en parte
		var tid := _con_titular(carta, ministro_id)
		var mi: Dictionary = _m.catalogo_ministros[tid]
		var ident: Dictionary = _m.catalogo_leyes["gabinete"]["identidad"]
		if mi["categoria_afin"] == carta["categoria"] or auto:
			escala *= 1.0 + float(mi["bono_ejecucion"])
		if _m.eventos.relacion_actor(_m.gabinete.slot_de(tid)) >= float(ident["estrella_sobre"]):
			escala *= 1.0 + float(ident["estrella_bono"])  # ministro estrella: tu buena relación se nota
		if _m.rng.randf() < float(mi["riesgo_escandalo"]) * (float(ident["escala_riesgo_auto"]) if auto else 1.0):
			res["escandalo"] = true
			var esc: Dictionary = _m.catalogo_leyes["escandalo"]
			_m.fx.delta_aprobacion(-float(esc["penal_aprobacion"]), "")
			_m.fx.sumar_ind("capital", -float(esc["penal_capital"]))
			_m.estado.registrar_accion("escandalo_ministro", {"ministro": tid})
	if es_unica(carta):
		_m.estado.cartas_ejecutadas[String(carta["id"])] = true
	var ley: Variant = carta["requisitos"]["ley"]
	var prop: Variant = carta.get("abre_propuesta_comite", null)
	if ley != null:
		var t := _m.legal.tipo(String(ley))
		var proy := {"carta_id": carta["id"], "tipo_ley": ley, "escala": escala, "region": region_id,
				"origen": String(carta.get("camara_origen", "camara")), "dia_ingreso": _m.estado.dia_actual,
				"dia_votacion": _m.estado.dia_actual + int(t["dias_tramitacion_base"])}
		_m.estado.proyectos_ley.append(proy)
		res["proyecto"] = proy
	elif prop != null:
		if not _m.estado.propuestas_abiertas.has(String(prop)) and not _m.estado.propuestas_aprobadas.has(String(prop)):
			_m.estado.propuestas_abiertas.append(String(prop))
		res["propuesta"] = prop
	else:
		_ejecutar_carta(carta, escala, region_id)
	_consecuencias_carta(carta, res)
	return res


func _consecuencias_carta(carta: Dictionary, res: Dictionary) -> void:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Cartas con riesgo (puede salir mal) o efecto a futuro (consecuencia programada): mismo modelo que las decisiones de eventos.
	if carta.has("riesgo") and _m.rng.randf() < float(carta["riesgo"]["prob"]):
		res["salio_mal"] = true
		for ef in carta["riesgo"]["efectos"]:
			_m.fx.aplicar_efecto(ef, 1.0, "")
	if carta.has("diferido"):
		var d: Dictionary = carta["diferido"]
		res["futuro"] = int(d["semanas"])
		_m.estado.pendientes.append({"tipo": "efecto", "semana": _m.eventos.semana_abs() + int(d["semanas"]), "origen": String(carta["id"]), "efectos": d["efectos"], "texto": String(d.get("texto", "")), "carta": true})


func _ejecutar_carta(carta: Dictionary, escala: float, region_id: String) -> void:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var obra: Variant = carta.get("obra", null)
	for ef in carta["efectos"]:
		if obra != null and ef["ind"] == "aprobacion":
			continue  # la aprobación de una obra llega con la inauguración
		_m.fx.aplicar_efecto(ef, escala, region_id)
	if obra != null:
		var final: Array = []
		for ef in carta["efectos"]:
			if ef["ind"] == "aprobacion":
				final.append({"ind": "aprobacion", "delta": float(ef["delta"]) * escala})
		_m.obras.iniciar(_m.estado, String(obra["nombre"]), int(obra["dias_totales"]), region_id, String(carta["id"]), final)
	else:
		_m.fx.marcar_cumplida(String(carta["id"]))


func aprobar_propuesta(prop_id: String, variante_id: String, region_id: String = "", custom: Dictionary = {}, nombres: Dictionary = {}) -> Dictionary:
	## Aprueba una propuesta del Comité con una variante (A/B/C) o una personalizada y arranca su obra; registra la entrada.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	if _m.estado.etapa != "gobierno" or not _m.estado.propuestas_abiertas.has(prop_id):
		return {"ok": false, "razon": "propuesta_no_disponible"}
	var prop: Dictionary = _m.catalogo_propuestas[prop_id]
	var costo := int(prop["costo_pa"])
	if costo > _m.estado.pa_actual:
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
		if not _m.grafo.listo() or not _m.grafo.estaciones_validas(custom.get("estaciones", [])):
			return {"ok": false, "razon": "trazado_invalido"}
		variante = _m.grafo.variante_modificada(variante, custom["estaciones"], float(custom.get("ritmo", 0.0)), float(custom.get("cobertura", 0.0)))
		variante_id = "M"
	nombres = _nombres_limpios(nombres)
	var id_linea := "P%d" % (_m.estado.lineas_jugador.size() + 1)
	_m.estado.registrar_entrada("aprobar_propuesta", {"prop": prop_id, "variante": variante_id, "region": region_id, "custom": custom, "nombres": nombres})
	_m.estado.pa_actual -= costo
	var ratio := clampf(float(prop["capacidad_musd"]) / float(variante["costo_musd"]), float(_m.catalogo_leyes["dinamica"]["ratio_obra_min"]), 1.0)
	var region := region_id if region_id != "" else String(prop.get("region", ""))
	var final: Array = []
	for ef in variante["efectos"]:
		if ef["ind"] == "aprobacion":
			final.append({"ind": "aprobacion", "delta": float(ef["delta"]) * ratio})
		else:
			_m.fx.aplicar_efecto(ef, ratio, "")
	var dias := roundi(float(variante["plazo_anios"]) * 365.0 * ratio)
	var titulo_obra := String(nombres.get("linea", "")) if String(nombres.get("linea", "")) != "" else String(prop["titulo"])
	_m.obras.iniciar(_m.estado, "%s · %s" % [titulo_obra, variante["nombre"]], dias, region, "", final, {"propuesta": prop_id, "variante": variante_id, "linea": id_linea})
	_registrar_linea(prop, prop_id, variante, variante_id, custom, nombres, id_linea)
	_m.estado.propuestas_abiertas.erase(prop_id)
	_m.estado.propuestas_aprobadas.append(prop_id)
	for c in _m.catalogo_cartas:
		if c.get("abre_propuesta_comite", null) == prop_id:
			_m.fx.marcar_cumplida(String(c["id"]))
	_m.estado.registrar_accion("propuesta_aprobada", {"prop": prop_id, "variante": variante_id, "ratio": ratio})
	return {"ok": true, "ratio": ratio, "dias": dias, "costo": costo}




func _registrar_linea(prop: Dictionary, prop_id: String, variante: Dictionary, variante_id: String, custom: Dictionary, nombres: Dictionary, id_linea: String) -> void:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## La línea aprobada (variante A/B/C o trazado propio) queda en el estado como línea del jugador: se dibuja en el mapa
	## en construcción y pasa a operativa al terminar su obra. Se reconstruye al reproducir el guardado (por eventos).
	var estaciones: Array = []
	if _m.grafo.listo():
		var ids: Array = custom["estaciones"] if not custom.is_empty() else _m.grafo.estaciones_base(variante)
		for id in ids:
			if _m.grafo.pos.has(id):
				estaciones.append([snappedf(_m.grafo.pos[id].x, 0.0001), snappedf(_m.grafo.pos[id].y, 0.0001)])
	var trazado: Array = []
	for q in variante["trazado"]:
		trazado.append([snappedf(float(q[0]), 0.0001), snappedf(float(q[1]), 0.0001)])
	var nom_est: Array = []
	var dados: Array = nombres.get("estaciones", [])
	for i in range(estaciones.size()):
		var n := String(dados[i]) if i < dados.size() else ""
		nom_est.append(n if n != "" else "Estación %d" % (i + 1))
	var nombre_linea := String(nombres.get("linea", ""))
	_m.estado.lineas_jugador.append({"id": id_linea, "nombre": nombre_linea if nombre_linea != "" else String(prop["titulo"]), "nombre_propio": nombre_linea != "",
			"prop": prop_id, "variante": variante_id, "trazado": trazado, "estaciones": estaciones, "nombres_estaciones": nom_est,
			"estado": "en_construccion", "dia_aprobacion": _m.estado.dia_actual})


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
	## Vota los proyectos de ley cuyo plazo venció esta semana (Senado, Cámara y Tribunal Constitucional) y aplica sus efectos.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var limite := _m.estado.dia_actual + _m.estado.dias_por_turno
	var pendientes: Array[Dictionary] = []
	var vistos: Array[Dictionary] = []
	for p in _m.estado.proyectos_ley:
		if int(p["dia_votacion"]) >= limite:
			pendientes.append(p)
			continue
		var carta: Dictionary = _m._cartas_por_id[p["carta_id"]]
		var voto := _m.legal.votar(_m.estado, String(p["tipo_ley"]))
		var tc := {"recurso": false, "cae": false}
		var ok := bool(voto["aprobada"])
		if ok:
			tc = _m.legal.resolver_tc(String(p["tipo_ley"]))
			ok = not bool(tc["cae"])
			if not ok:
				_m.fx.sumar_ind("capital", -float(_m.catalogo_leyes["tc"]["capital_perdido_si_cae"]))
		else:
			_m.fx.sumar_ind("capital", -float(_m.catalogo_leyes["congreso"]["penal_capital_rechazo"]))
		if ok:
			_ejecutar_carta(carta, float(p["escala"]), String(p["region"]))
		_m.estado.registrar_accion("votacion", {"carta": carta["id"], "aprobada": ok, "senado": voto["senado"], "camara": voto["camara"], "tc": tc["recurso"]})
		vistos.append({"carta_id": carta["id"], "aprobada": ok, "voto": voto, "tc": tc, "origen": String(p.get("origen", "camara"))})
	_m.estado.proyectos_ley = pendientes
	return vistos
