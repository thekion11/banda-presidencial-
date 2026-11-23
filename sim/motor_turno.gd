class_name MotorTurno
extends RefCounted
## Ciclo fijo de 8 pasos por turno semanal. Determinista: misma semilla + mismas entradas = mismo resultado.

var estado: EstadoSimulacion
var rng: RandomNumberGenerator
var catalogo_cartas: Array[Dictionary] = []
var catalogo_eventos: Array[Dictionary] = []
var catalogo_leyes: Dictionary = {}
var catalogo_ministros: Dictionary = {}
var catalogo_propuestas: Dictionary = {}
var legal := MotorLegal.new()
var regiones := Regiones.new()
var obras := MotorObras.new()
var mandato := MotorMandato.new(self)
var ultimos_eventos: Array[Dictionary] = []
var votaciones_semana: Array[Dictionary] = []  # votaciones de leyes resueltas al cerrar el turno (para la UI)
var _cartas_por_id: Dictionary = {}


func inicializar(p_estado: EstadoSimulacion, p_cartas: Array, p_eventos: Array, p_leyes: Dictionary,
		p_ministros: Array, p_extra: Dictionary = {}) -> void:
	estado = p_estado
	rng = RandomNumberGenerator.new()
	rng.seed = estado.semilla
	catalogo_cartas.assign(p_cartas)
	catalogo_eventos.assign(p_eventos)
	catalogo_leyes = p_leyes.duplicate(true)
	catalogo_ministros.clear()
	for m in p_ministros:
		catalogo_ministros[m["id"]] = m
	catalogo_propuestas.clear()
	for pr in p_extra.get("propuestas", []):
		catalogo_propuestas[pr["id"]] = pr
	_cartas_por_id.clear()
	for c in catalogo_cartas:
		_cartas_por_id[c["id"]] = c
	regiones.cargar(p_extra.get("regiones", []))
	legal.configurar(catalogo_leyes, rng)
	obras.configurar(catalogo_leyes, rng, regiones)
	if estado.indicadores.is_empty():
		estado.indicadores = EstadoSimulacion.IND_DEFECTO.duplicate()


func _h(clave: String) -> Variant:
	return catalogo_leyes["hemiciclo"][clave]


func turnos_mandato() -> int:
	return int(_h("duracion_mandato_dias")) / estado.dias_por_turno


func aplicar_partido_inicial(datos_partido: Dictionary) -> void:
	estado.partido = datos_partido.duplicate(true)
	estado.etapa = "campana"
	estado.promesas_campana.clear()
	var ind_ini: Dictionary = datos_partido["indicadores_iniciales"]
	for clave in ind_ini.keys():
		estado.indicadores[clave] = float(ind_ini[clave])
	var camp: Dictionary = catalogo_leyes.get("campana", {})
	regiones.inicializar(estado, estado.ind("aprobacion"), String(datos_partido.get("region_bastion", "")),
			float(camp.get("bono_bastion", 0.0)), float(camp.get("variacion_regional_inicial", 0.0)))


# ---------------------------------------------------------------- Flujo de alto nivel (UI, bots, replay)
func iniciar_turno() -> Array[Dictionary]:
	ejecutar_amanecer()
	var eventos := procesar_eventos_semana()
	robar_mano(int(catalogo_leyes["mano"]["tamano"]))
	ultimos_eventos = eventos
	return eventos


func terminar_turno() -> Array[Dictionary]:
	## Cierra el turno y, si la partida sigue y no toca elección, inicia el siguiente.
	cerrar_turno()
	if estado.eleccion_pendiente(int(_h("semanas_campana"))):
		return []
	if estado.etapa == "campana" or estado.etapa == "gobierno":
		return iniciar_turno()
	return []


# ---------------------------------------------------------------- Paso 1
func ejecutar_amanecer() -> void:
	estado.pa_actual = estado.pa_maximo
	if estado.etapa == "campana":
		regiones.revertir_a_base(estado, float(catalogo_leyes["campana"]["reversion_semanal"]))
	if estado.etapa != "gobierno":
		return
	var d: Dictionary = catalogo_leyes["dinamica"]
	var ancla := float(d["ancla_base"]) + float(d["ancla_peso_fiscal"]) * (estado.ind("fiscal") - 50.0) \
			+ float(d["ancla_peso_cohesion"]) * (estado.ind("cohesion") - 50.0) \
			+ float(d["ancla_peso_capital"]) * (estado.ind("capital") - 50.0)
	ancla -= maxf(0.0, float(d["fiscal_critico"]) - estado.ind("fiscal")) * float(d["penal_fiscal_critico"])
	if regiones.pesos.is_empty():
		_sumar_ind("aprobacion", (ancla - estado.ind("aprobacion")) * float(d["reversion_semanal"]))
	else:
		regiones.revertir(estado, ancla, float(d["reversion_semanal"]), float(d.get("sesgo_regional_persistente", 0.0)))
	_delta_aprobacion(-float(d["desgaste_aprobacion_semanal"]), "")
	_sumar_ind("fiscal", float(d["regen_fiscal_semanal"]))
	var extra := maxi(0, estado.obras_en_curso.size() - int(d["max_obras_concurrentes"]))
	_sumar_ind("riesgo_ejecucion", float(extra) * float(d["riesgo_por_obra_extra"]) - 0.5)
	if estado.ind("riesgo_ejecucion") > float(d["riesgo_umbral"]):
		_delta_aprobacion(-float(d["penal_aprobacion_riesgo"]), "")
	_sumar_ind("capital", float(d["regen_capital_semanal"]))
	_sumar_ind("cohesion", float(d["regen_cohesion_semanal"]))


# ---------------------------------------------------------------- Paso 2
func procesar_eventos_semana() -> Array[Dictionary]:
	var dia_inicio := estado.dia_actual
	var dia_fin := estado.dia_actual + estado.dias_por_turno - 1
	var ocurridos: Array[Dictionary] = []
	for evt in catalogo_eventos:
		if String(evt.get("etapa", "gobierno")) != estado.etapa:
			continue
		var ocurre := false
		if evt["tipo"] == "programado":
			var d_obj := int(evt["dia_objetivo"])
			ocurre = d_obj >= dia_inicio and d_obj <= dia_fin
		elif evt["tipo"] == "aleatorio_semilla":
			ocurre = rng.randf() < float(evt.get("peso_sorteo", 0.0))
		if ocurre:
			ocurridos.append(_aplicar_evento(evt))
	return ocurridos


func _aplicar_evento(evt: Dictionary) -> Dictionary:
	var res := {"id": evt["id"], "titulo": evt["titulo"], "descripcion": evt["descripcion"], "hora": evt["hora_etiqueta"], "votacion": null, "efectos": evt["efectos_base"]}
	var aplicar := true
	var v: Variant = evt.get("votacion", null)
	if v != null:
		var voto := legal.votar(estado, String(v["tipo_ley"]), int(v.get("votos_firmes_base", -1)))
		var tc := legal.resolver_tc(String(v["tipo_ley"]), float(v.get("prob_exito_tc", -1.0)))
		aplicar = bool(voto["aprobada"]) and not bool(tc["cae"])
		res["votacion"] = {"voto": voto, "tc": tc, "aprobada": aplicar, "origen": String(v.get("origen", "camara"))}
		if not bool(voto["aprobada"]):
			_sumar_ind("capital", -float(catalogo_leyes["congreso"]["penal_capital_rechazo"]))
		elif bool(tc["cae"]):
			_sumar_ind("capital", -float(catalogo_leyes["tc"]["capital_perdido_si_cae"]))
	if aplicar:
		for ef in evt["efectos_base"]:
			_aplicar_efecto(ef, 1.0, "")
	estado.registrar_accion("evento", {"id": evt["id"], "aplicado": aplicar})
	return res


# ---------------------------------------------------------------- Paso 3
func robar_mano(n: int = 5) -> void:
	while estado.mano.size() < n:
		if estado.mazo.is_empty() and not _reponer_mazo():
			return
		var id: String = estado.mazo.pop_back()
		if estado.cartas_ejecutadas.has(id):
			continue  # carta única ya ejecutada: sale del mazo
		estado.mano.append(_cartas_por_id[id])


func _reponer_mazo() -> bool:
	if not estado.descarte.is_empty():
		estado.mazo.assign(estado.descarte)
		estado.descarte.clear()
	else:
		for c in catalogo_cartas:
			if not estado.mano.any(func(m: Dictionary) -> bool: return m["id"] == c["id"]):
				estado.mazo.append(String(c["id"]))
	for i in range(estado.mazo.size() - 1, 0, -1):  # Fisher-Yates con la semilla de la partida
		var j := rng.randi_range(0, i)
		var tmp: String = estado.mazo[i]
		estado.mazo[i] = estado.mazo[j]
		estado.mazo[j] = tmp
	return not estado.mazo.is_empty()


# ---------------------------------------------------------------- Pasos 4-6
func costo_carta(carta: Dictionary, ministro_id: String = "") -> int:
	var costo := int(carta["costo_pa"])
	if ministro_id != "" and catalogo_ministros.has(ministro_id):
		var m: Dictionary = catalogo_ministros[ministro_id]
		if m["categoria_afin"] == carta["categoria"]:
			costo -= int(m["reduccion_costo_pa"])
	return maxi(1, costo)


func es_unica(carta: Dictionary) -> bool:
	return carta["requisitos"]["ley"] != null or carta.has("obra") or carta.get("abre_propuesta_comite", null) != null


func vista_carta(idx: int, ministro_id: String = "") -> Dictionary:
	var carta: Dictionary = estado.mano[idx]
	var corr := {"aplica": false, "ratio": 1.0, "mensaje": ""}
	if estado.etapa == "gobierno":
		corr = legal.corregir(carta, estado)
	return {"costo": costo_carta(carta, ministro_id), "corrector": corr,
			"alcanza": costo_carta(carta, ministro_id) <= estado.pa_actual}


func jugar_carta(idx: int, ministro_id: String = "", region_id: String = "") -> Dictionary:
	if estado.etapa != "campana" and estado.etapa != "gobierno":
		return {"ok": false, "razon": "partida_terminada"}
	if idx < 0 or idx >= estado.mano.size():
		return {"ok": false, "razon": "indice_invalido"}
	if ministro_id != "" and (estado.etapa == "campana" or not catalogo_ministros.has(ministro_id)):
		return {"ok": false, "razon": "ministro_no_disponible"}
	if region_id != "" and not regiones.existe(region_id):
		return {"ok": false, "razon": "region_invalida"}
	var carta: Dictionary = estado.mano[idx]
	var costo := costo_carta(carta, ministro_id)
	if costo > estado.pa_actual:
		return {"ok": false, "razon": "pa_insuficiente", "costo": costo}
	if estado.etapa == "gobierno" and es_unica(carta) and estado.cartas_ejecutadas.has(String(carta["id"])):
		return {"ok": false, "razon": "ya_ejecutada"}
	estado.registrar_entrada("jugar", {"idx": idx, "ministro": ministro_id, "region": region_id})
	estado.pa_actual -= costo
	estado.mano.remove_at(idx)
	estado.descarte.append(String(carta["id"]))
	var res: Dictionary
	if estado.etapa == "campana":
		res = _jugar_en_campana(carta, region_id)
	else:
		res = _jugar_en_gobierno(carta, ministro_id, region_id)
	res["ok"] = true
	res["costo"] = costo
	estado.registrar_accion("carta", {"id": carta["id"], "costo": costo, "ministro": ministro_id, "region": region_id})
	return res


func _jugar_en_campana(carta: Dictionary, region_id: String) -> Dictionary:
	var camp: Dictionary = catalogo_leyes["campana"]
	var ef_apr := 0.0
	for ef in carta["efectos"]:
		if ef["ind"] == "aprobacion":
			ef_apr += float(ef["delta"])
	var ya := estado.promesas_campana.any(func(p: Dictionary) -> bool: return p["carta_id"] == carta["id"])
	var delta := maxf(0.5, (float(camp["aprobacion_base_por_carta"]) + ef_apr) * float(_h("bono_aprobacion_promesa")))
	if ya:
		delta *= float(catalogo_leyes.get("repeticion_promesa", 0.5))
	else:
		estado.promesas_campana.append({"carta_id": carta["id"], "titulo": carta["titulo"],
				"turno": estado.turno_actual, "region": region_id, "cumplida": false})
	_delta_aprobacion(delta, region_id, true)
	return {"promesa": true, "delta_aprobacion": delta, "repetida": ya}


func _jugar_en_gobierno(carta: Dictionary, ministro_id: String, region_id: String) -> Dictionary:
	var res := {"escandalo": false, "corrector": {}, "proyecto": null, "propuesta": null}
	var corr := legal.corregir(carta, estado)
	res["corrector"] = corr
	var escala := float(corr["ratio"])
	if ministro_id != "":
		var m: Dictionary = catalogo_ministros[ministro_id]
		if m["categoria_afin"] == carta["categoria"]:
			escala *= 1.0 + float(m["bono_ejecucion"])
		if rng.randf() < float(m["riesgo_escandalo"]):
			res["escandalo"] = true
			var esc: Dictionary = catalogo_leyes["escandalo"]
			_delta_aprobacion(-float(esc["penal_aprobacion"]), "")
			_sumar_ind("capital", -float(esc["penal_capital"]))
			estado.registrar_accion("escandalo_ministro", {"ministro": ministro_id})
	if es_unica(carta):
		estado.cartas_ejecutadas[String(carta["id"])] = true
	var ley: Variant = carta["requisitos"]["ley"]
	var prop: Variant = carta.get("abre_propuesta_comite", null)
	if ley != null:
		var t := legal.tipo(String(ley))
		var proy := {"carta_id": carta["id"], "tipo_ley": ley, "escala": escala, "region": region_id,
				"origen": String(carta.get("camara_origen", "camara")), "dia_ingreso": estado.dia_actual,
				"dia_votacion": estado.dia_actual + int(t["dias_tramitacion_base"])}
		estado.proyectos_ley.append(proy)
		res["proyecto"] = proy
	elif prop != null:
		if not estado.propuestas_abiertas.has(String(prop)) and not estado.propuestas_aprobadas.has(String(prop)):
			estado.propuestas_abiertas.append(String(prop))
		res["propuesta"] = prop
	else:
		_ejecutar_carta(carta, escala, region_id)
	return res


func _ejecutar_carta(carta: Dictionary, escala: float, region_id: String) -> void:
	var obra: Variant = carta.get("obra", null)
	for ef in carta["efectos"]:
		if obra != null and ef["ind"] == "aprobacion":
			continue  # la aprobación de una obra llega con la inauguración
		_aplicar_efecto(ef, escala, region_id)
	if obra != null:
		var final: Array = []
		for ef in carta["efectos"]:
			if ef["ind"] == "aprobacion":
				final.append({"ind": "aprobacion", "delta": float(ef["delta"]) * escala})
		obras.iniciar(estado, String(obra["nombre"]), int(obra["dias_totales"]), region_id, String(carta["id"]), final)
	else:
		_marcar_cumplida(String(carta["id"]))


func aprobar_propuesta(prop_id: String, variante_id: String, region_id: String = "") -> Dictionary:
	if estado.etapa != "gobierno" or not estado.propuestas_abiertas.has(prop_id):
		return {"ok": false, "razon": "propuesta_no_disponible"}
	var prop: Dictionary = catalogo_propuestas[prop_id]
	var costo := int(prop["costo_pa"])
	if costo > estado.pa_actual:
		return {"ok": false, "razon": "pa_insuficiente", "costo": costo}
	var variante: Dictionary = {}
	for v in prop["variantes"]:
		if v["id"] == variante_id:
			variante = v
	if variante.is_empty():
		return {"ok": false, "razon": "variante_invalida"}
	estado.registrar_entrada("aprobar_propuesta", {"prop": prop_id, "variante": variante_id, "region": region_id})
	estado.pa_actual -= costo
	var ratio := clampf(float(prop["capacidad_musd"]) / float(variante["costo_musd"]), 0.1, 1.0)
	var region := region_id if region_id != "" else String(prop.get("region", ""))
	var final: Array = []
	for ef in variante["efectos"]:
		if ef["ind"] == "aprobacion":
			final.append({"ind": "aprobacion", "delta": float(ef["delta"]) * ratio})
		else:
			_aplicar_efecto(ef, ratio, "")
	var dias := roundi(float(variante["plazo_anios"]) * 365.0 * ratio)
	obras.iniciar(estado, "%s · %s" % [prop["titulo"], variante["nombre"]], dias, region, "", final, {"propuesta": prop_id, "variante": variante_id})
	estado.propuestas_abiertas.erase(prop_id)
	estado.propuestas_aprobadas.append(prop_id)
	for c in catalogo_cartas:
		if c.get("abre_propuesta_comite", null) == prop_id:
			_marcar_cumplida(String(c["id"]))
	estado.registrar_accion("propuesta_aprobada", {"prop": prop_id, "variante": variante_id, "ratio": ratio})
	return {"ok": true, "ratio": ratio, "dias": dias, "costo": costo}


# ---------------------------------------------------------------- Pasos 7-8
func cerrar_turno() -> void:
	if estado.etapa != "campana" and estado.etapa != "gobierno":
		return
	var resumen := {}
	votaciones_semana = []
	if estado.etapa == "gobierno":
		votaciones_semana = _resolver_proyectos()
		resumen["leyes"] = votaciones_semana
		resumen["obras_terminadas"] = obras.avanzar(estado, estado.dias_por_turno, _aplicar_efecto, _marcar_cumplida).size()
		mandato.evaluar_legado()
		mandato.evaluar_crisis()
	estado.registrar_accion("cierre_turno", {"aprobacion": snappedf(estado.ind("aprobacion"), 0.01), "resumen": resumen.size()})
	estado.registrar_entrada("cerrar", {})
	if estado.etapa != "gobierno" and estado.etapa != "campana":
		return
	estado.turno_actual += 1
	estado.dia_actual += estado.dias_por_turno
	if estado.etapa == "gobierno" and estado.turno_actual > turnos_mandato():
		mandato.finalizar("fin_mandato")


func _resolver_proyectos() -> Array[Dictionary]:
	var limite := estado.dia_actual + estado.dias_por_turno
	var pendientes: Array[Dictionary] = []
	var vistos: Array[Dictionary] = []
	for p in estado.proyectos_ley:
		if int(p["dia_votacion"]) >= limite:
			pendientes.append(p)
			continue
		var carta: Dictionary = _cartas_por_id[p["carta_id"]]
		var voto := legal.votar(estado, String(p["tipo_ley"]))
		var tc := {"recurso": false, "cae": false}
		var ok := bool(voto["aprobada"])
		if ok:
			tc = legal.resolver_tc(String(p["tipo_ley"]))
			ok = not bool(tc["cae"])
			if not ok:
				_sumar_ind("capital", -float(catalogo_leyes["tc"]["capital_perdido_si_cae"]))
		else:
			_sumar_ind("capital", -float(catalogo_leyes["congreso"]["penal_capital_rechazo"]))
		if ok:
			_ejecutar_carta(carta, float(p["escala"]), String(p["region"]))
		estado.registrar_accion("votacion", {"carta": carta["id"], "aprobada": ok, "senado": voto["senado"], "camara": voto["camara"], "tc": tc["recurso"]})
		vistos.append({"carta_id": carta["id"], "aprobada": ok, "voto": voto, "tc": tc, "origen": String(p.get("origen", "camara"))})
	estado.proyectos_ley = pendientes
	return vistos






func resolver_eleccion_presidencial() -> Dictionary:
	var umbral := float(_h("umbral_victoria_presidencial"))
	var ruido := float(catalogo_leyes["campana"]["ruido_eleccion"])
	var voto_final := clampf(estado.ind("aprobacion") + rng.randf_range(-ruido, ruido), 0.0, 100.0)
	var electo := voto_final >= umbral
	estado.registrar_accion("eleccion_presidencial", {
		"voto_final": voto_final, "umbral": umbral, "electo": electo,
		"promesas_registradas": estado.promesas_campana.size()
	})
	estado.registrar_entrada("eleccion", {})
	if electo:
		estado.etapa = "gobierno"
		estado.turno_actual = 1
		estado.dia_actual = 1
		estado.pa_actual = estado.pa_maximo
	else:
		estado.etapa = "derrota_electoral"
		estado.resultado_final = {"motivo": "derrota_electoral", "voto_final": voto_final, "puntaje": 0}
	return {"electo": electo, "voto_final": voto_final, "umbral": umbral}


# ---------------------------------------------------------------- Utilidades de efectos
func _aplicar_efecto(ef: Dictionary, escala: float, region: String) -> void:
	var delta := float(ef["delta"]) * escala
	if ef["ind"] == "aprobacion":
		_delta_aprobacion(delta, region, true)
	else:
		_sumar_ind(String(ef["ind"]), delta)


func _delta_aprobacion(delta: float, region: String, decreciente: bool = false) -> void:
	if decreciente and delta > 0.0:
		delta *= maxf(0.2, 1.0 - estado.ind("aprobacion") / float(catalogo_leyes["dinamica"]["rendimiento_decreciente"]))
	if regiones.pesos.is_empty():
		_sumar_ind("aprobacion", delta)
	else:
		regiones.aplicar_delta(estado, delta, region, float(catalogo_leyes["campana"]["derrame_regional"]))


func _sumar_ind(nombre: String, delta: float) -> void:
	var lim: Dictionary = catalogo_leyes["limites_indicadores"]
	var tope := float(lim["viviendas_anio_max"]) if nombre == "viviendas_anio" else float(lim["max"])
	estado.indicadores[nombre] = clampf(estado.ind(nombre) + delta, float(lim["min"]), tope)


func _marcar_cumplida(carta_id: String) -> void:
	for p in estado.promesas_campana:
		if p["carta_id"] == carta_id and not bool(p["cumplida"]):
			p["cumplida"] = true
			return


func calcular_puntaje() -> int:
	return mandato.calcular_puntaje()
