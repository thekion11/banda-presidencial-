class_name MotorCoalicion
extends RefCounted
## Coalición (DISENO_V2 §10): partidos aliados ficticios con ideología propia que piden cuotas de poder (ministerios, asesores, cartas).
## Su satisfacción afecta la cohesión, los escaños que votan con el gobierno y los movimientos internos.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno
var partidos: Dictionary = {}  # id -> partido aliado posible (data/coalicion.json)


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


func cargar(lista: Array) -> void:
	partidos.clear()
	for p in lista:
		partidos[String(p["id"])] = p


func _cfg() -> Dictionary:
	return m.catalogo_leyes["coalicion"]


func afinidad(id: String) -> float:
	## 1 = misma ideología que el partido del jugador; 0 = distancia >= distancia_max (ejes eco/inst).
	var ide: Dictionary = partidos[id]["ideologia"]
	var dist := Vector2(float(ide["eco"]) - float(m.estado.partido.get("eje_eco", 0.0)), float(ide["inst"]) - float(m.estado.partido.get("eje_inst", 0.0))).length()
	return clampf(1.0 - dist / float(_cfg()["distancia_max"]), 0.0, 1.0)


func adoptar_partido_propio(id: String) -> void:
	## PR-01: quien entra a un partido existente lo lleva como aliado permanente que pide poder (sus ministerios) y castiga si se le ignora.
	if not partidos.has(id):
		return
	var pet: Dictionary = partidos[id]["peticion"]
	var mins: Array = []
	for mid in partidos[id]["ministerios_pedidos"]:
		if m.gabinete.tiene_ministerio(String(mid)) and mins.size() < int(pet["ministerios"]):
			mins.append(mid)  # las cuotas se guardan por ministerio (cargo), no por persona
	m.estado.coalicion[id] = {"satisfaccion": float(_cfg()["satisfaccion_inicial"]), "ministros": mins, "asesores": [], "propio": true}


func _n_aliados() -> int:
	return m.estado.coalicion.values().filter(func(c: Dictionary) -> bool: return not bool(c.get("propio", false))).size()


func unirse(id: String) -> Dictionary:
	var est := m.estado
	if est.etapa != "campana" and est.etapa != "gobierno" and est.etapa != "oposicion":
		return {"ok": false, "razon": "partida_terminada"}
	if not partidos.has(id):
		return {"ok": false, "razon": "partido_inexistente"}
	if est.coalicion.has(id):
		return {"ok": false, "razon": "ya_aliado"}
	if _n_aliados() >= int(_cfg()["max_aliados"]):
		return {"ok": false, "razon": "limite_aliados"}
	est.registrar_entrada("coalicion", {"accion": "unirse", "id": id})
	est.coalicion[id] = {"satisfaccion": float(_cfg()["satisfaccion_inicial"]), "ministros": [], "asesores": []}
	_recalcular_apoyo()
	est.registrar_accion("coalicion_unirse", {"id": id, "afinidad": snappedf(afinidad(id), 0.01)})
	return {"ok": true, "afinidad": afinidad(id)}


func salir(id: String, ruptura: bool = false) -> Dictionary:
	var est := m.estado
	if not est.coalicion.has(id):
		return {"ok": false, "razon": "no_aliado"}
	if not ruptura and bool(est.coalicion[id].get("propio", false)):
		return {"ok": false, "razon": "partido_propio"}  # tu partido no se abandona: se rompe solo si lo desatiendes
	if not ruptura:
		est.registrar_entrada("coalicion", {"accion": "salir", "id": id})
	est.coalicion.erase(id)
	_recalcular_apoyo()
	if est.etapa == "gobierno":  # romper un pacto cuesta cohesión y capital político
		m.fx.sumar_ind("cohesion", -float(_cfg()["penal_ruptura_cohesion"]))
		m.fx.sumar_ind("capital", -float(_cfg()["penal_ruptura_capital"]))
	est.registrar_accion("coalicion_ruptura" if ruptura else "coalicion_salida", {"id": id})
	return {"ok": true}


func asignar_cuota(id: String, tipo: String, valor: String, quitar: bool = false) -> Dictionary:
	## tipo "ministerio" (id de ministro del gabinete) o "asesor" (id de asesor contratado), entregado al partido aliado.
	var est := m.estado
	if not est.coalicion.has(id):
		return {"ok": false, "razon": "no_aliado"}
	if tipo != "ministerio" and tipo != "asesor":
		return {"ok": false, "razon": "tipo_invalido"}
	var clave := "ministros" if tipo == "ministerio" else "asesores"
	var lista: Array = est.coalicion[id][clave]
	if tipo == "ministerio":
		valor = m.gabinete.slot_de(valor)
	if quitar:
		if not lista.has(valor):
			return {"ok": false, "razon": "no_asignado"}
	else:
		if tipo == "ministerio":
			valor = m.gabinete.slot_de(valor)  # se acepta el id de un candidato: la cuota es del ministerio
		if not (m.gabinete.tiene_ministerio(valor) if tipo == "ministerio" else est.asesores.has(valor)):
			return {"ok": false, "razon": "fuera_del_gabinete" if tipo == "ministerio" else "asesor_no_contratado"}
		for otro in est.coalicion.values():
			if otro[clave].has(valor):
				return {"ok": false, "razon": "ya_asignado"}
	est.registrar_entrada("cuota", {"id": id, "clase": tipo, "valor": valor, "quitar": quitar})
	if quitar:
		lista.erase(valor)
	else:
		lista.append(valor)
	return {"ok": true, "cumplimiento": cumplimiento(id)}


func cumplimiento(id: String) -> float:
	## Fracción 0..1 de la petición del partido (ministerios y asesores asignados que siguen vigentes).
	var pet: Dictionary = partidos[id]["peticion"]
	var c: Dictionary = m.estado.coalicion[id]
	var vig_min: int = c["ministros"].filter(func(x: String) -> bool: return m.gabinete.tiene_ministerio(x)).size()
	var vig_ase: int = c["asesores"].filter(func(x: String) -> bool: return m.estado.asesores.has(x)).size()
	var demanda := int(pet["ministerios"]) + int(pet["asesores"])
	if demanda == 0:
		return 1.0
	return float(mini(vig_min, int(pet["ministerios"])) + mini(vig_ase, int(pet["asesores"]))) / float(demanda)


func objetivo(id: String) -> float:
	return 100.0 * cumplimiento(id) * (1.0 - float(_cfg()["peso_ideologia"]) * (1.0 - afinidad(id)))


func carta_jugada(carta: Dictionary) -> void:
	## Jugar cartas de las categorías que pide un aliado mejora su satisfacción.
	## Y las de una categoría que rechaza la empeoran.
	for id in m.estado.coalicion.keys():
		var c: Dictionary = m.estado.coalicion[id]
		if partidos[id]["categorias_pedidas"].has(carta["categoria"]):
			c["satisfaccion"] = minf(100.0, float(c["satisfaccion"]) + float(_cfg()["bono_carta_afin"]))
		elif partidos[id]["categorias_rechazadas"].has(carta["categoria"]):
			c["satisfaccion"] = maxf(0.0, float(c["satisfaccion"]) - float(_cfg()["penal_carta_rechazada"]))
	_recalcular_apoyo()


func mult_carta(carta: Dictionary) -> float:
	## Multiplicador del efecto de una carta de gobierno: un aliado satisfecho potencia las cartas de las categorías que pide;
	## uno descontento (bajo el umbral de malestar) frena las que rechaza. Sin aliados vale 1.
	var cfg := _cfg()
	var bono := 0.0
	for id in m.estado.coalicion.keys():
		var sat := float(m.estado.coalicion[id]["satisfaccion"])
		if sat >= float(cfg["umbral_satisfechos"]) and partidos[id]["categorias_pedidas"].has(carta["categoria"]):
			bono += float(cfg["bono_efecto_afin"])
		elif sat < float(cfg["umbral_malestar"]) and partidos[id]["categorias_rechazadas"].has(carta["categoria"]):
			bono -= float(cfg["penal_efecto_rechazada"])
	return 1.0 + clampf(bono, -float(cfg["tope_bono_efecto"]), float(cfg["tope_bono_efecto"]))


func amanecer() -> void:
	## Cada turno de gobierno: la satisfacción converge a su objetivo y se aplican cohesión, votos y movimientos internos.
	var est := m.estado
	var cfg := _cfg()
	var cohesion := 0.0
	var todos_satisfechos := not est.coalicion.is_empty()
	for id in est.coalicion.keys():
		var c: Dictionary = est.coalicion[id]
		c["satisfaccion"] = float(c["satisfaccion"]) + (objetivo(id) - float(c["satisfaccion"])) * float(cfg["convergencia"])
		cohesion += (float(c["satisfaccion"]) - 50.0) / 50.0 * float(cfg["cohesion_por_aliado"])
		todos_satisfechos = todos_satisfechos and float(c["satisfaccion"]) >= float(cfg["umbral_satisfechos"])
	if cohesion != 0.0:
		m.fx.sumar_ind("cohesion", cohesion)
	for id in est.coalicion.keys():  # un aliado muy insatisfecho rompe el pacto
		if float(est.coalicion[id]["satisfaccion"]) < float(cfg["umbral_ruptura"]):
			salir(id, true)
	var malestar := est.coalicion.values().any(func(c: Dictionary) -> bool: return float(c["satisfaccion"]) < float(cfg["umbral_malestar"]))
	if malestar:
		est.internos_actual = maxi(0, est.internos_actual - int(cfg["penal_internos_malestar"]))
	elif todos_satisfechos:
		est.internos_actual += int(cfg["bono_internos_satisfechos"])
	_recalcular_apoyo()


func _recalcular_apoyo() -> void:
	var sen := 0.0
	var cam := 0.0
	for id in m.estado.coalicion.keys():
		if bool(m.estado.coalicion[id].get("propio", false)):
			continue  # sus escaños ya son «propios» (partido de origen)
		var f := float(m.estado.coalicion[id]["satisfaccion"]) / 100.0
		sen += float(partidos[id]["escanos_senado"]) * f
		cam += float(partidos[id]["escanos_camara"]) * f
	m.estado.apoyo_coalicion = {"senado": roundi(sen), "camara": roundi(cam)}
