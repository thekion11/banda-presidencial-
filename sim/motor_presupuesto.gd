class_name MotorPresupuesto
extends RefCounted
## Presupuesto extra a un ministerio (PR-18 mínimo, pedido del usuario del 27-nov-2026): el jugador le asigna fiscal (y algo de capital) por una temporada y el
## ministerio ejecuta más rápido los proyectos de su sector, con prioridad en las propuestas que el jugador marcó, PERO con autonomía: la fracción que va a
## tus prioridades depende de su lealtad, su afinidad ideológica y su competencia; el resto la usa en su propia agenda y puede traer conflictos.
## Todos los números en data/leyes.json › presupuesto_ministerial. Estado: estado.presupuesto = {activos: {slot: {...}}, gasto: {"ciclo:anio": fiscal}, libre: {slot: turno}}.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


func _cfg() -> Dictionary:
	return m.catalogo_leyes["presupuesto_ministerial"]


func _activos() -> Dictionary:
	return m.estado.presupuesto.get("activos", {})


func _clave_anio() -> String:
	return "%d:%d" % [m.estado.ciclo, m.gabinete.anio_gobierno()]


func gastado_anio() -> float:
	## Fiscal ya comprometido en extras este año de gobierno (se compara con el tope anual de la regla fiscal).
	return float(m.estado.presupuesto.get("gasto", {}).get(_clave_anio(), 0.0))


func semanas_libre(slot: String) -> int:
	## Semanas que faltan para poder volver a asignar extra a ese ministerio (0 si puede).
	return maxi(0, int(m.estado.presupuesto.get("libre", {}).get(slot, 0)) - m.estado.turno_actual)


func fraccion_alineada(slot: String) -> float:
	## Fracción esperada del extra que el ministro dedica a TUS prioridades: lealtad, afinidad ideológica y competencia, acotada.
	var id := m.gabinete.de_ministerio(slot)
	if id == "":
		return 0.0
	var a: Dictionary = _cfg()["autonomia"]
	var lealtad := clampf(m.eventos.relacion_actor(slot) / 100.0, 0.0, 1.0)
	var comp := clampf(float(m.catalogo_ministros[id]["bono_ejecucion"]) / float(a["competencia_ref"]), 0.0, 1.0)
	var f := float(a["peso_lealtad"]) * lealtad + float(a["peso_afinidad"]) * m.gabinete.afinidad(id) + float(a["peso_competencia"]) * comp
	return clampf(f, float(a["fraccion_min"]), float(a["fraccion_max"]))


func _sector(slot: String) -> Array[Dictionary]:
	## Proyectos tuyos del sector de ese ministerio: obras en curso, leyes en trámite y promesas de campaña pendientes (las cartas que lleva su titular).
	var res: Array[Dictionary] = []
	var e := m.estado
	var vistos := {}
	var fuentes := [["obra", e.obras_en_curso], ["ley", e.proyectos_ley]]
	for par in fuentes:
		for x in par[1]:
			var cid := String(x["carta_id"])
			if cid != "" and _es_del_sector(cid, slot) and not vistos.has(cid):
				vistos[cid] = true
				res.append({"carta_id": cid, "titulo": _titulo(cid, x), "tipo": String(par[0])})
	for p in e.promesas_pendientes():
		var cid := String(p["carta_id"])
		if _es_del_sector(cid, slot) and not vistos.has(cid):
			vistos[cid] = true
			res.append({"carta_id": cid, "titulo": String(p.get("titulo", cid)), "tipo": "promesa"})
	return res


func _titulo(cid: String, x: Dictionary) -> String:
	var c: Dictionary = m._cartas_por_id.get(cid, {})
	return String(c.get("titulo", x.get("nombre", cid)))


func _es_del_sector(carta_id: String, slot: String) -> bool:
	var c: Dictionary = m._cartas_por_id.get(carta_id, {})
	if c.is_empty():
		return false
	var tit := m.gabinete.titular(String(c["categoria"]))
	return tit != "" and m.gabinete.slot_de(tit) == slot


func _prioritarios(slot: String, a: Dictionary) -> Array:
	## Ids de las propuestas prioritarias: las que marcó el jugador (y siguen vivas) o, si no marcó ninguna, las primeras del sector hasta el máximo.
	var vivos: Array = _sector(slot).map(func(x: Dictionary) -> String: return String(x["carta_id"]))
	var elegidas: Array = (a["prio"] as Array).filter(func(id: String) -> bool: return vivos.has(id))
	return elegidas if not (a["prio"] as Array).is_empty() else vivos.slice(0, int(_cfg()["max_prioridades"]))


func _efecto(nivel: String, f: float) -> Dictionary:
	## Efecto semanal esperado del extra: días de avance de obras y de trámite de leyes (a prioridades y a su agenda propia) y baja de riesgo de ejecución.
	var ef: Dictionary = _cfg()["efecto_semanal"]
	var k := float(_cfg()["niveles"][nivel]["intensidad"])
	return {"dias_obra_prioridad": roundi(float(ef["dias_obra"]) * k * f), "dias_obra_propia": roundi(float(ef["dias_obra"]) * k * (1.0 - f)),
			"dias_ley_prioridad": roundi(float(ef["dias_ley"]) * k * f), "dias_ley_propia": roundi(float(ef["dias_ley"]) * k * (1.0 - f)),
			"riesgo_ejecucion": -float(ef["riesgo_ejecucion"]) * k * f}


func _verificar(slot: String, nivel: String, prio: Array) -> Dictionary:
	## Todas las comprobaciones sin cambiar nada; si falla: {ok:false, razon, mensaje, alternativa} (nunca un «no» seco).
	var c := _cfg()
	var e := m.estado
	if e.etapa != "gobierno":
		return {"ok": false, "razon": "solo_en_gobierno", "mensaje": "El presupuesto extra a ministerios solo existe en el gobierno.", "alternativa": "Gana la elección para disponer del presupuesto."}
	if not c["niveles"].has(nivel):
		return {"ok": false, "razon": "nivel_desconocido", "mensaje": "Ese nivel de presupuesto no existe.", "alternativa": "Elige pequeño, medio o grande."}
	if m.gabinete.de_ministerio(slot) == "":
		return {"ok": false, "razon": "ministerio_vacio", "mensaje": "Ese ministerio no tiene ministro.", "alternativa": "Nombra a un ministro en el gabinete primero."}
	if _activos().has(slot):
		return {"ok": false, "razon": "ya_activo", "mensaje": "Ese ministerio ya tiene presupuesto extra en curso.", "alternativa": "Espera a que termine la temporada."}
	var espera := semanas_libre(slot)
	if espera > 0:
		return {"ok": false, "razon": "enfriamiento_presupuesto", "mensaje": "Ese ministerio acaba de ejecutar un extra y debe rendir cuentas.", "alternativa": "Podrás darle otro en %d semana(s)." % espera, "semanas": espera}
	if _activos().size() >= int(c["max_simultaneos"]):
		return {"ok": false, "razon": "max_simultaneos", "mensaje": "Ya hay %d ministerios con presupuesto extra: más sería descontrol." % int(c["max_simultaneos"]), "alternativa": "Espera a que termine la temporada de alguno."}
	var items := _sector(slot)
	if items.is_empty():
		return {"ok": false, "razon": "sin_proyectos", "mensaje": "Ese ministerio no tiene proyectos tuyos en marcha: el dinero no tendría en qué usarse.", "alternativa": "Lanza una obra, una ley o una promesa de su sector y vuelve."}
	var vivos: Array = items.map(func(x: Dictionary) -> String: return String(x["carta_id"]))
	if prio.size() > int(c["max_prioridades"]) or not prio.all(func(id: String) -> bool: return vivos.has(id)):
		return {"ok": false, "razon": "prioridad_invalida", "mensaje": "Solo puedes priorizar hasta %d proyectos de ese sector." % int(c["max_prioridades"]), "alternativa": "Elige entre los proyectos del sector que aparecen en la ficha."}
	var n: Dictionary = c["niveles"][nivel]
	var fiscal := float(n["fiscal"])
	if gastado_anio() + fiscal > float(c["tope_anual_fiscal"]):
		var viable := _nivel_viable(slot)
		return {"ok": false, "razon": "tope_anual", "mensaje": "La regla fiscal limita los extras a %d puntos de fiscal por año y ya llevas %d." % [roundi(float(c["tope_anual_fiscal"])), roundi(gastado_anio())],
				"alternativa": ("Con un nivel «%s» sí alcanza." % viable) if viable != "" else "Espera al próximo año de gobierno.", "nivel_viable": viable}
	if e.ind("fiscal") - fiscal < float(c["piso_fiscal"]):
		var viable2 := _nivel_viable(slot)
		return {"ok": false, "razon": "piso_fiscal", "mensaje": "Las arcas no resisten: el fiscal quedaría bajo %d." % roundi(float(c["piso_fiscal"])),
				"alternativa": ("Con un nivel «%s» sí alcanza." % viable2) if viable2 != "" else "Recupera el fiscal antes de gastar más.", "nivel_viable": viable2}
	if e.ind("capital") < float(n["capital"]):
		return {"ok": false, "razon": "capital_insuficiente", "mensaje": "Te faltan %d puntos de capital político para negociar el extra." % ceili(float(n["capital"]) - e.ind("capital")), "alternativa": "Recupera capital o elige un nivel menor."}
	return {"ok": true}


func _nivel_barato() -> String:
	## El nivel de menor costo en fiscal (el que mejor explica por qué no se puede asignar nada).
	var mejor := ""
	for id in _cfg()["niveles"].keys():
		if mejor == "" or float(_cfg()["niveles"][id]["fiscal"]) < float(_cfg()["niveles"][mejor]["fiscal"]):
			mejor = String(id)
	return mejor


func _nivel_viable(slot: String) -> String:
	## El nivel más alto que sí cabría hoy (fiscal, tope anual y capital); '' si ninguno.
	var c := _cfg()
	var mejor := ""
	var mejor_k := -1.0
	for id in c["niveles"].keys():
		var n: Dictionary = c["niveles"][id]
		if gastado_anio() + float(n["fiscal"]) <= float(c["tope_anual_fiscal"]) and m.estado.ind("fiscal") - float(n["fiscal"]) >= float(c["piso_fiscal"]) \
				and m.estado.ind("capital") >= float(n["capital"]) and float(n["intensidad"]) > mejor_k:
			mejor = String(id)
			mejor_k = float(n["intensidad"])
	return mejor


func niveles_posibles(slot: String) -> Array[String]:
	## Niveles de extra que se podrían asignar hoy a ese ministerio (de menor a mayor costo en fiscal); vacío si ninguno.
	var ord: Array = _cfg()["niveles"].keys()
	ord.sort_custom(func(a: String, b: String) -> bool: return float(_cfg()["niveles"][a]["fiscal"]) < float(_cfg()["niveles"][b]["fiscal"]))
	var res: Array[String] = []
	for id in ord:
		if bool(_verificar(slot, String(id), [])["ok"]):
			res.append(String(id))
	return res


func panel() -> Dictionary:
	## Solo lectura para la pestaña Gabinete: topes globales y, por ministerio con ministro, extra asignado, fracción alineada esperada, riesgo y efecto semanal.
	var c := _cfg()
	var filas: Array[Dictionary] = []
	var e := m.estado
	var ids: Array = e.gabinete.duplicate()
	for id in ids:
		var slot := m.gabinete.slot_de(id)
		var mi: Dictionary = m.catalogo_ministros[id]
		var act: Dictionary = _activos().get(slot, {})
		var f := fraccion_alineada(slot)
		var niv := String(act.get("nivel", "medio"))
		var items := _sector(slot)
		var posibles := niveles_posibles(slot)
		var v := _verificar(slot, String(posibles[0]) if not posibles.is_empty() else _nivel_barato(), [])
		filas.append({"slot": slot, "ministro_id": String(id), "alias": String(mi.get("alias", id)), "cartera": String(mi.get("cartera", slot)), "sector": String(mi["categoria_afin"]),
				"activo": not act.is_empty(), "nivel": String(act.get("nivel", "")), "semanas_restantes": maxi(0, int(act.get("hasta", 0)) - e.turno_actual) if not act.is_empty() else 0,
				"fraccion_alineada": f, "lealtad": m.eventos.relacion_actor(slot), "afinidad": m.gabinete.afinidad(id), "competencia": clampf(float(mi["bono_ejecucion"]) / float(c["autonomia"]["competencia_ref"]), 0.0, 1.0),
				"riesgo_desvio": (1.0 - f) * float(c["desvio"]["prob_base"]), "efecto_semanal": _efecto(niv, f),
				"prioridades": _prioritarios(slot, act) if not act.is_empty() else [], "candidatos": items, "puede_asignar": bool(v["ok"]), "niveles_posibles": posibles,
				"razon": String(v.get("razon", "")), "mensaje": String(v.get("mensaje", "")), "alternativa": String(v.get("alternativa", "")), "libre_en": semanas_libre(slot)})
	return {"niveles": c["niveles"].duplicate(true), "tope_anual": float(c["tope_anual_fiscal"]), "gastado_anio": gastado_anio(), "piso_fiscal": float(c["piso_fiscal"]),
			"simultaneos": _activos().size(), "max_simultaneos": int(c["max_simultaneos"]), "max_prioridades": int(c["max_prioridades"]), "duracion_semanas": int(c["duracion_semanas"]),
			"fiscal": e.ind("fiscal"), "ministerios": filas}


func asignar(slot: String, nivel: String, prioridades: Array = []) -> Dictionary:
	## Asigna presupuesto extra a un ministerio por una temporada. prioridades: ids de cartas (obras, leyes o promesas de su sector; vacío = automático).
	var v := _verificar(slot, nivel, prioridades)
	if not bool(v["ok"]):
		return v
	var e := m.estado
	var c := _cfg()
	var n: Dictionary = c["niveles"][nivel]
	e.registrar_entrada("presupuesto", {"accion": "asignar", "slot": slot, "nivel": nivel, "prio": prioridades.duplicate()})
	m.fx.sumar_ind("fiscal", -float(n["fiscal"]), "presupuesto extra a un ministerio")
	if float(n["capital"]) > 0.0:
		m.fx.sumar_ind("capital", -float(n["capital"]), "negociar el presupuesto extra")
	var p: Dictionary = e.presupuesto
	var act: Dictionary = p.get("activos", {})
	act[slot] = {"nivel": nivel, "desde": e.turno_actual, "hasta": e.turno_actual + int(c["duracion_semanas"]), "prio": prioridades.duplicate()}
	p["activos"] = act
	var gasto: Dictionary = p.get("gasto", {})
	gasto[_clave_anio()] = gastado_anio() + float(n["fiscal"])
	p["gasto"] = gasto
	e.presupuesto = p
	e.registrar_accion("presupuesto_asignado", {"slot": slot, "nivel": nivel})
	return {"ok": true, "slot": slot, "nivel": nivel, "fraccion_alineada": fraccion_alineada(slot), "hasta": int(act[slot]["hasta"])}


func fijar_prioridades(slot: String, prioridades: Array) -> Dictionary:
	## Cambia las prioridades de un ministerio con extra en curso (mismo máximo).
	var act := _activos()
	if not act.has(slot):
		return {"ok": false, "razon": "sin_extra_activo", "mensaje": "Ese ministerio no tiene presupuesto extra en curso.", "alternativa": "Asígnale uno primero."}
	var vivos: Array = _sector(slot).map(func(x: Dictionary) -> String: return String(x["carta_id"]))
	if prioridades.size() > int(_cfg()["max_prioridades"]) or not prioridades.all(func(id: String) -> bool: return vivos.has(id)):
		return {"ok": false, "razon": "prioridad_invalida", "mensaje": "Solo puedes priorizar hasta %d proyectos de ese sector." % int(_cfg()["max_prioridades"]), "alternativa": "Elige entre los proyectos del sector que aparecen en la ficha."}
	m.estado.registrar_entrada("presupuesto", {"accion": "prioridades", "slot": slot, "nivel": "", "prio": prioridades.duplicate()})
	act[slot]["prio"] = prioridades.duplicate()
	return {"ok": true}


func amanecer() -> void:
	## Cada semana de gobierno: cada ministerio con extra acelera obras y leyes de su sector (más las prioritarias, menos su agenda propia) y baja el riesgo de ejecución;
	## con probabilidad (1 - fracción alineada) hay un incidente (pide más, discrepa, filtra, desvía o renuncia). Al terminar la temporada queda en enfriamiento.
	var e := m.estado
	if e.etapa != "gobierno" or _activos().is_empty():
		return
	var c := _cfg()
	var slots: Array = _activos().keys()
	slots.sort()
	for slot in slots:
		var act: Dictionary = _activos()[slot]
		if e.turno_actual >= int(act["hasta"]) or m.gabinete.de_ministerio(String(slot)) == "":
			_terminar(String(slot))
			continue
		var f := fraccion_alineada(String(slot))
		var ef := _efecto(String(act["nivel"]), f)
		var prio := _prioritarios(String(slot), act)
		for obra in e.obras_en_curso:
			if _es_del_sector(String(obra["carta_id"]), String(slot)):
				var d: int = int(ef["dias_obra_prioridad"]) if prio.has(String(obra["carta_id"])) else int(ef["dias_obra_propia"])
				obra["dias_avanzados"] = mini(int(obra["dias_totales"]), int(obra["dias_avanzados"]) + d)
		for p in e.proyectos_ley:
			if _es_del_sector(String(p["carta_id"]), String(slot)):
				var dl: int = int(ef["dias_ley_prioridad"]) if prio.has(String(p["carta_id"])) else int(ef["dias_ley_propia"])
				p["dia_votacion"] = maxi(e.dia_actual, int(p["dia_votacion"]) - dl)
		m.fx.sumar_ind("riesgo_ejecucion", float(ef["riesgo_ejecucion"]), "presupuesto extra bien dirigido")
		if m.rng.randf() < (1.0 - f) * float(c["desvio"]["prob_base"]):
			_incidente(String(slot), f)


func _incidente(slot: String, f: float) -> void:
	## El ministro usa parte del extra en su propia agenda y eso trae un incidente (pesos y efectos en data; la renuncia solo si la fracción alineada es muy baja).
	var d: Dictionary = _cfg()["desvio"]
	var opciones: Array = (d["eventos"] as Array).filter(func(x: Dictionary) -> bool: return not x.has("fraccion_max") or f <= float(x["fraccion_max"]))
	var total := 0.0
	for x in opciones:
		total += float(x["peso"])
	var r := m.rng.randf() * total
	var elegido: Dictionary = opciones[opciones.size() - 1]
	for x in opciones:
		r -= float(x["peso"])
		if r <= 0.0:
			elegido = x
			break
	for ef in elegido["efectos"]:
		m.fx.aplicar_efecto(ef, 1.0, "")
	m.estado.registrar_accion("presupuesto_incidente", {"slot": slot, "evento": String(elegido["id"])})
	if bool(elegido.get("renuncia", false)):
		m.gabinete.revisar_renuncia(slot, true)
		_terminar(slot)


func _terminar(slot: String) -> void:
	var p: Dictionary = m.estado.presupuesto
	var act: Dictionary = p.get("activos", {})
	act.erase(slot)
	p["activos"] = act
	var libre: Dictionary = p.get("libre", {})
	libre[slot] = m.estado.turno_actual + int(_cfg()["enfriamiento_semanas"])
	p["libre"] = libre
	m.estado.presupuesto = p
	m.estado.registrar_accion("presupuesto_terminado", {"slot": slot})
