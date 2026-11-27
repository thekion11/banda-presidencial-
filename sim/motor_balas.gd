class_name MotorBalas
extends RefCounted
## Balas de plata (PR-17): reserva aparte de la mano con recursos extraordinarios de un solo uso por mandato (urgencia, veto, DFL, plebiscito,
## excepción, insistencia, nombramiento). Cuestan capital político, tienen condiciones de disponibilidad por tipo y un riesgo propio.
## Catálogo, topes, costos y riesgos en data/leyes.json › balas_plata. Estado: estado.balas = {usadas: {id: [ciclo, turno]}}.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


func _cfg() -> Dictionary:
	return m.catalogo_leyes["balas_plata"]


func definicion(id: String) -> Dictionary:
	## Definición de una bala del catálogo; {} si no existe.
	for b in _cfg()["catalogo"]:
		if String(b["id"]) == id:
			return b
	return {}


func _usadas_del_ciclo() -> Dictionary:
	## id -> turno de las balas usadas en el periodo actual (cada periodo de gobierno tiene su propia reserva).
	var res := {}
	var todas: Dictionary = m.estado.balas.get("usadas", {})
	for id in todas.keys():
		if int(todas[id][0]) == m.estado.ciclo:
			res[id] = int(todas[id][1])
	return res


func usos_habilitados() -> int:
	## Balas que se pueden haber usado hasta ahora: las iniciales, y todo el cupo desde el año `anio_uso_extra`.
	var c := _cfg()
	return int(c["usos_max"]) if m.gabinete.anio_gobierno() >= int(c["anio_uso_extra"]) else int(c["usos_iniciales"])


func usos_restantes() -> int:
	## Balas que aún puedes usar ahora (habilitadas menos usadas).
	return maxi(0, usos_habilitados() - _usadas_del_ciclo().size())


func semanas_de_espera() -> int:
	## Semanas que faltan para poder usar otra bala (0 si no hay enfriamiento).
	var ultimo := 0
	var hay := false
	for t in _usadas_del_ciclo().values():
		ultimo = maxi(ultimo, int(t))
		hay = true
	return maxi(0, ultimo + int(_cfg()["enfriamiento_semanas"]) - m.estado.turno_actual) if hay else 0


func objetivos(def: Dictionary) -> Array[Dictionary]:
	## Proyectos de ley en trámite sobre los que la bala puede actuar ({idx, carta_id, titulo, tipo_ley, dias}); vacío si la bala no necesita objetivo.
	var res: Array[Dictionary] = []
	var accion := String(def["accion"])
	if accion != "adelantar_votacion" and accion != "saltar_congreso":
		return res
	var e := m.estado
	var vedados: Array = def.get("tipos_vedados", [])
	for i in range(e.proyectos_ley.size()):
		var p: Dictionary = e.proyectos_ley[i]
		if vedados.has(String(p["tipo_ley"])):
			continue  # materia vedada por la Constitución para el DFL
		if accion == "adelantar_votacion" and int(p["dia_votacion"]) < e.dia_actual + e.dias_por_turno:
			continue  # ya se vota esta semana: la urgencia no cambia nada
		var carta: Dictionary = m._cartas_por_id.get(String(p["carta_id"]), {})
		res.append({"idx": i, "carta_id": String(p["carta_id"]), "titulo": String(carta.get("titulo", p["carta_id"])), "tipo_ley": String(p["tipo_ley"]),
				"dias": maxi(0, int(p["dia_votacion"]) - e.dia_actual)})
	return res


func _cumple(cond: Dictionary, def: Dictionary) -> bool:
	var e := m.estado
	match String(cond["tipo"]):
		"proyecto_en_tramite":
			return not objetivos(def).is_empty()
		"anio_min":
			return m.gabinete.anio_gobierno() >= int(cond["valor"])
		"indicador_min":
			return e.ind(String(cond["ind"])) >= float(cond["valor"])
		"indicador_max":
			return e.ind(String(cond["ind"])) <= float(cond["valor"])
		"evento_reciente":
			for id in cond["ids"]:
				if e.eventos_ocurridos.has(String(id)) and e.turno_actual - int(e.eventos_ocurridos[String(id)]) <= int(_cfg()["semanas_reciente"]):
					return true
			return false
		"oposicion_mayoritaria":
			for camara in [true, false]:
				var c := m.legal.composicion(e, camara)
				if int(c["oposicion"]) * 2 > int(c["total"]):
					return true
			return false
		"ministros_firman":
			return _ministros_sin_firma(float(cond["relacion_min"])).is_empty()
		"alguna":
			return (cond["condiciones"] as Array).any(func(c: Dictionary) -> bool: return _cumple(c, def))
	return false


func _ministros_sin_firma(minimo: float) -> Array[String]:
	## Alias de los ministros del gabinete cuya relación contigo está bajo el mínimo (no firmarían un decreto de insistencia).
	var res: Array[String] = []
	for id in m.estado.gabinete:
		if m.eventos.relacion_actor(m.gabinete.slot_de(id)) < minimo:
			res.append(String(m.catalogo_ministros[id].get("alias", id)))
	return res


func riesgo_estimado(def: Dictionary) -> float:
	## Probabilidad (0 a 1) de que la bala salga mal ahora: base + peso x (centro - indicador), acotada.
	var r: Dictionary = def["riesgo"]
	var p := float(r["prob_base"]) + float(r["peso"]) * (float(r["centro"]) - m.estado.ind(String(r["ind"])))
	return clampf(p, float(r["min"]), float(r["max"]))


func _verificar(def: Dictionary, objetivo: int, reducida: bool) -> Dictionary:
	## Todas las comprobaciones sin cambiar nada; si algo falla devuelve {ok:false, razon, mensaje, alternativa} (nunca un «no» seco).
	var e := m.estado
	var c := _cfg()
	if e.etapa != "gobierno":
		return {"ok": false, "razon": "solo_en_gobierno", "mensaje": "Las balas de plata son recursos del gobierno.", "alternativa": "Gana la elección para tener acceso a la reserva."}
	if _usadas_del_ciclo().has(String(def["id"])):
		return {"ok": false, "razon": "ya_usada", "mensaje": "Esa bala ya se usó en este mandato.", "alternativa": "Elige otra de la reserva."}
	if usos_restantes() <= 0:
		var extra: String = "En el año %d se habilita el resto de la reserva." % int(c["anio_uso_extra"]) if usos_habilitados() < int(c["usos_max"]) else "Se usaron todas las balas del mandato."
		return {"ok": false, "razon": "sin_usos", "mensaje": "No te quedan balas de plata disponibles por ahora.", "alternativa": extra}
	var espera := semanas_de_espera()
	if espera > 0:
		return {"ok": false, "razon": "enfriamiento", "mensaje": "Usaste una bala hace poco: el país necesita respirar.", "alternativa": "Podrás usar otra en %d semana(s)." % espera, "semanas": espera}
	for cond in def["requiere"]:
		if not _cumple(cond, def):
			var msg := String(cond["falla"])
			if String(cond["tipo"]) == "ministros_firman":
				msg += " (%s)" % ", ".join(_ministros_sin_firma(float(cond["relacion_min"])))
			return {"ok": false, "razon": "condicion", "condicion": String(cond["tipo"]), "mensaje": msg, "alternativa": String(cond["alternativa"])}
	var objs := objetivos(def)
	if objetivo >= 0 and not objs.any(func(o: Dictionary) -> bool: return int(o["idx"]) == objetivo):
		return {"ok": false, "razon": "objetivo_invalido", "mensaje": "Ese proyecto no sirve para esta bala.", "alternativa": "Elige uno de los proyectos válidos o deja que se escoja solo."}
	var costo := float(def["costo_capital"])
	var capital := e.ind("capital")
	if capital < costo:
		var ratio := capital / costo
		var viable := {"ratio": ratio, "costo_capital": capital}
		if ratio < float(c["ratio_reducida_min"]):
			return {"ok": false, "razon": "capital_insuficiente", "mensaje": "Te faltan %d puntos de capital político." % ceili(costo - capital), "alternativa": "Recupera capital (cumple promesas, negocia) hasta tener al menos %d." % ceili(costo * float(c["ratio_reducida_min"])), "viable": {}}
		if not reducida:
			return {"ok": false, "razon": "capital_insuficiente", "mensaje": "Te faltan %d puntos de capital: no alcanza para la versión completa." % ceili(costo - capital), "alternativa": "Puedes usar una versión reducida al %d %% de sus efectos." % roundi(ratio * 100.0), "viable": viable}
		return {"ok": true, "escala": ratio, "costo": capital, "objetivos": objs}
	return {"ok": true, "escala": 1.0, "costo": costo, "objetivos": objs}


func baul() -> Dictionary:
	## Solo lectura para la interfaz: reserva, usos, enfriamiento y, por bala, costo, riesgo, condición cumplida o no y por qué.
	var usadas := _usadas_del_ciclo()
	var items: Array[Dictionary] = []
	for def in _cfg()["catalogo"]:
		var v := _verificar(def, -1, false)
		var viable: bool = bool(v["ok"]) or (String(v.get("razon", "")) == "capital_insuficiente" and not (v["viable"] as Dictionary).is_empty())
		items.append({"id": String(def["id"]), "titulo": String(def["titulo"]), "texto": String(def["texto"]), "costo_capital": float(def["costo_capital"]),
				"riesgo_estimado": riesgo_estimado(def), "riesgo_texto": String(def["riesgo"]["texto"]), "efectos": def["efectos"].duplicate(true),
				"usada": usadas.has(String(def["id"])), "turno_uso": int(usadas.get(String(def["id"]), 0)),
				"disponible": bool(v["ok"]), "viable_reducida": viable and not bool(v["ok"]),
				"razon": String(v.get("razon", "")), "mensaje": String(v.get("mensaje", "")), "alternativa": String(v.get("alternativa", "")),
				"objetivos": objetivos(def)})
	return {"usos_max": int(_cfg()["usos_max"]), "usos_habilitados": usos_habilitados(), "usos_restantes": usos_restantes(),
			"semanas_espera": semanas_de_espera(), "items": items}


func usar(id: String, objetivo: int = -1, reducida: bool = false) -> Dictionary:
	## Usa una bala de la reserva. objetivo: índice en estado.proyectos_ley (-1 = el proyecto más lejano de votarse). reducida: acepta la versión con menos
	## capital. Devuelve {ok, ...resultado} o {ok:false, razon, mensaje, alternativa}. Una sola tirada de azar (el riesgo).
	var e := m.estado
	var def := definicion(id)
	if def.is_empty():
		return {"ok": false, "razon": "bala_desconocida", "mensaje": "Esa bala no existe.", "alternativa": "Elige una de la reserva."}
	var v := _verificar(def, objetivo, reducida)
	if not bool(v["ok"]):
		return v
	e.registrar_entrada("bala", {"id": id, "objetivo": objetivo, "reducida": reducida})
	var escala := float(v["escala"])
	var elegido := -1
	var objs: Array = v["objetivos"]
	if not objs.is_empty():
		elegido = objetivo
		if elegido < 0:
			var mejor: Dictionary = objs[0]
			for o in objs:
				if int(o["dias"]) > int(mejor["dias"]):
					mejor = o
			elegido = int(mejor["idx"])
	var prob := riesgo_estimado(def)
	var mal := m.rng.randf() < prob
	m.fx.sumar_ind("capital", -float(v["costo"]), "bala de plata: " + String(def["titulo"]))
	var resultado := {"ok": true, "id": id, "titulo": String(def["titulo"]), "salio_mal": mal, "riesgo": prob, "escala": escala, "costo_capital": float(v["costo"]), "objetivo": elegido}
	var anula: bool = mal and bool(def["riesgo"]["anula_efectos"])
	match String(def["accion"]):
		"adelantar_votacion":
			e.proyectos_ley[elegido]["dia_votacion"] = e.dia_actual
		"saltar_congreso":
			var p: Dictionary = e.proyectos_ley[elegido]
			e.proyectos_ley.remove_at(elegido)
			if not mal:
				m.cartas._ejecutar_carta(m._cartas_por_id[String(p["carta_id"])], float(p["escala"]), String(p["region"]))
		"anular_pendiente_negativo":
			resultado["anulado"] = _anular_pendiente_negativo()
	if not anula:
		for ef in def["efectos"]:
			m.fx.aplicar_efecto(ef, escala, "")
	if mal:
		resultado["texto_riesgo"] = String(def["riesgo"]["texto"])
		for ef in def["riesgo"]["efectos"]:
			m.fx.aplicar_efecto(ef, 1.0, "")
	var usadas: Dictionary = e.balas.get("usadas", {})
	usadas[id] = [e.ciclo, e.turno_actual]
	e.balas["usadas"] = usadas
	e.registrar_accion("bala", {"id": id, "mal": mal, "objetivo": elegido, "escala": escala})
	return resultado


func _anular_pendiente_negativo() -> String:
	## Quita de las consecuencias programadas la de efecto neto más negativo; devuelve su origen ('' si no había).
	var peor := -1
	var peor_suma := 0.0
	var lista := m.estado.pendientes
	for i in range(lista.size()):
		if String(lista[i].get("tipo", "")) != "efecto":
			continue
		var suma := 0.0
		for ef in lista[i].get("efectos", []):
			suma += float(ef["delta"])
		if suma < peor_suma:
			peor_suma = suma
			peor = i
	if peor < 0:
		return ""
	var origen := String(lista[peor].get("origen", ""))
	lista.remove_at(peor)
	return origen
