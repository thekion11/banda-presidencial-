class_name MotorLegal
extends RefCounted
## Validación legal: votaciones bicamerales, Tribunal Constitucional y Corrector de Realismo.

var leyes: Dictionary = {}
var rng: RandomNumberGenerator


func configurar(p_leyes: Dictionary, p_rng: RandomNumberGenerator) -> void:
	## Enlaza las leyes y el generador de azar de la partida.
	leyes = p_leyes
	rng = p_rng
	var h: Dictionary = leyes.get("hemiciclo", {})
	for t in leyes.get("tipos_ley", []):  # los mínimos se derivan de la regla del tipo (leyes.json), no se fijan a mano
		t["votos_minimos"] = umbral(t, int(h.get("total_senadores", 50)))
		t["votos_minimos_camara"] = umbral(t, int(h.get("total_diputados", 155)))


func umbral(t: Dictionary, total: int) -> int:
	## Votos mínimos en una cámara de `total` miembros: base "en_ejercicio" (todos) o "presentes" (asistencia supuesta);
	## regla "mayoria" (más de la mitad de la base) o "fraccion" (num/den de la base, redondeada hacia arriba).
	var regla := String(t.get("regla", "mayoria"))
	if regla == "ninguna":
		return 1
	var base := total
	if String(t.get("base_quorum", "en_ejercicio")) == "presentes":
		base = ceili(float(total) * float(leyes["congreso"]["asistencia_presentes"]) - 0.000001)
	if regla == "fraccion":
		var f: Dictionary = t["fraccion"]
		return (base * int(f["num"]) + int(f["den"]) - 1) / int(f["den"])
	return base / 2 + 1


func tipo(id: String) -> Dictionary:
	## Definición de un tipo de ley (quórum, trámite, TC); {} si no existe.
	for t in leyes.get("tipos_ley", []):
		if t["id"] == id:
			return t
	return {}


func _votos_camara(propios: int, total: int, apoyo: float) -> int:
	return propios + roundi(float(total - propios) * apoyo)


func apoyo_base(estado: EstadoSimulacion) -> float:
	## Apoyo 0..1 de los parlamentarios que no son de tu bancada: base + capital + cohesión + el impulso de la luna de miel (D-BQ, solo en las primeras semanas de gobierno).
	var c: Dictionary = leyes["congreso"]
	return clampf(float(c["apoyo_base"]) + float(c["peso_capital"]) * estado.ind("capital") + float(c["peso_cohesion"]) * estado.ind("cohesion")
			+ LunaDeMiel.valor(leyes, LunaDeMiel.intensidad(estado, leyes), "bono_apoyo"), 0.0, 1.0)


func _bases(estado: EstadoSimulacion) -> Dictionary:
	## Votos esperados de cada cámara según el apoyo de hoy (capital, cohesión, escaños propios y coalición), sin ruido.
	var h: Dictionary = leyes["hemiciclo"]
	var c: Dictionary = leyes["congreso"]
	var apoyo := apoyo_base(estado)
	var n_sen := int(h["total_senadores"])
	var n_dip := int(h.get("total_diputados", 155))
	var propios_sen := int(estado.partido.get("escanos_propios", leyes["congreso"]["escanos_propios_defecto"]))
	var propios_dip := roundi(float(propios_sen) * float(n_dip) / float(n_sen)) + int(estado.apoyo_coalicion["camara"])
	propios_sen += int(estado.apoyo_coalicion["senado"])  # partidos aliados satisfechos (MotorCoalicion)
	return {"n_sen": n_sen, "n_dip": n_dip, "ruido": int(c["ruido_votos"]), "sen": _votos_camara(propios_sen, n_sen, apoyo), "dip": _votos_camara(propios_dip, n_dip, apoyo)}


func prob_aprobacion(estado: EstadoSimulacion, tipo_id: String, recargo: float = 0.0) -> Dictionary:
	## Probabilidad (0 a 1) de que cada cámara alcance el quórum del tipo de ley con el apoyo de hoy, sin usar el azar: {senado, camara}. Solo lectura.
	var t := tipo(tipo_id)
	if t.is_empty():
		return {"senado": 0.0, "camara": 0.0}
	if not bool(t.get("requiere_votacion", true)):
		return {"senado": 1.0, "camara": 1.0}
	var b := _bases(estado)
	return {"senado": _p_quorum(int(b["sen"]) - roundi(float(b["n_sen"]) * recargo), int(b["ruido"]), int(t["votos_minimos"]), int(b["n_sen"])),
			"camara": _p_quorum(int(b["dip"]) - roundi(float(b["n_dip"]) * recargo), int(b["ruido"]) * 3, int(t["votos_minimos_camara"]), int(b["n_dip"]))}


func _p_quorum(base: int, ruido: int, minimo: int, total: int) -> float:
	var ok := 0
	for d in range(-ruido, ruido + 1):
		if clampi(base + d, 0, total) >= minimo:
			ok += 1
	return float(ok) / float(2 * ruido + 1)


func votar(estado: EstadoSimulacion, tipo_id: String, votos_firmes_senado: int = -1, recargo: float = 0.0) -> Dictionary:
	## Simula la votación de un tipo de ley en el Senado y la Cámara; devuelve votos, quórums y si fue aprobada (usa el azar).
	## `recargo` (0 a 1): fracción de cada cámara que se pierde por tramitar con urgencia (agenda legislativa).
	var t := tipo(tipo_id)
	if t.is_empty():
		return {"aprobada": false, "razon": "tipo_desconocido"}
	var h: Dictionary = leyes["hemiciclo"]
	var min_sen := int(t["votos_minimos"])
	var min_cam := int(t.get("votos_minimos_camara", min_sen))
	if not bool(t.get("requiere_votacion", true)):
		return {"aprobada": true, "senado": 0, "camara": 0, "min_senado": 0, "min_camara": 0, "sin_votacion": true}
	var c: Dictionary = leyes["congreso"]
	var b := _bases(estado)
	var n_sen := int(b["n_sen"])
	var n_dip := int(b["n_dip"])
	var ruido := int(b["ruido"])
	var sen: int
	if votos_firmes_senado >= 0:
		sen = votos_firmes_senado
	else:
		sen = clampi(int(b["sen"]) + rng.randi_range(-ruido, ruido) - roundi(float(n_sen) * recargo), 0, n_sen)
	var dip := clampi(int(b["dip"]) + rng.randi_range(-ruido * 3, ruido * 3) - roundi(float(n_dip) * recargo), 0, n_dip)
	var fr := float(c["fraccion_abstencion"])  # presentación: parte de los no-favorables se abstiene
	var abst_sen := roundi(fr * float(n_sen - sen))
	var abst_dip := roundi(fr * float(n_dip - dip))
	return {
		"aprobada": sen >= min_sen and dip >= min_cam,
		"senado": sen, "camara": dip, "min_senado": min_sen, "min_camara": min_cam,
		"total_senado": n_sen, "total_camara": n_dip,
		"abst_senado": abst_sen, "abst_camara": abst_dip,
		"contra_senado": n_sen - sen - abst_sen, "contra_camara": n_dip - dip - abst_dip,
		"en_contra_senado": n_sen - sen, "sin_votacion": false
	}


func composicion(estado: EstadoSimulacion, camara: bool) -> Dictionary:
	## Bloques esperados de una cámara: bancada propia, aliados que suelen apoyar y oposición.
	var h: Dictionary = leyes["hemiciclo"]
	var c: Dictionary = leyes["congreso"]
	var total := int(h["total_diputados"]) if camara else int(h["total_senadores"])
	var propios := int(estado.partido.get("escanos_propios", leyes["congreso"]["escanos_propios_defecto"]))
	if camara:
		propios = roundi(float(propios) * float(total) / float(h["total_senadores"]))
	var apoyo := apoyo_base(estado)
	var coalicion := int(estado.apoyo_coalicion["camara" if camara else "senado"])
	var aliados := roundi(float(maxi(0, total - propios - coalicion)) * apoyo) + coalicion  # como votar(): los escaños de la coalición salen del resto antes de aplicar el apoyo
	return {"total": total, "propios": propios, "aliados": aliados, "oposicion": maxi(0, total - propios - aliados)}


func resolver_tc(tipo_id: String, prob_exito_override: float = -1.0) -> Dictionary:
	## recurso: la oposición acude al TC. cae: el TC declara inconstitucional (el gobierno pierde).
	var t := tipo(tipo_id)
	if t.is_empty() or not bool(t.get("puede_ir_tc", false)):
		return {"recurso": false, "cae": false}
	var recurso := prob_exito_override >= 0.0 or rng.randf() < float(t["prob_recurso_tc"])
	if not recurso:
		return {"recurso": false, "cae": false}
	var p_exito := prob_exito_override if prob_exito_override >= 0.0 else float(t["prob_exito_tc"])
	return {"recurso": true, "cae": rng.randf() >= p_exito, "prob_exito": p_exito}


static func fmt_cifra(n: float, unidad: String) -> String:
	## Formatea una cifra para los mensajes del corrector («12 mil km»).
	var txt: String
	if absf(n) >= 10000.0:
		txt = "%d mil" % roundi(n / 1000.0)
	else:
		txt = "%d" % roundi(n)
	return txt if unidad == "" else "%s %s" % [txt, unidad]


func corregir(carta: Dictionary, estado: EstadoSimulacion) -> Dictionary:
	## Nunca responde con un "no" seco: ofrece una versión viable o por tramos.
	var corr: Variant = carta.get("corrector", null)
	if corr == null:
		return {"aplica": false, "ratio": 1.0, "mensaje": ""}
	var meta := float(corr["meta"])
	var cap := float(corr["capacidad"])
	if corr.has("capacidad_ind"):
		cap = estado.ind(String(corr["capacidad_ind"]))
	if cap >= meta:
		return {"aplica": false, "ratio": 1.0, "mensaje": ""}
	var ratio := clampf(cap / meta, float(leyes["dinamica"]["ratio_obra_min"]), 1.0)
	var u := String(corr.get("unidad", ""))
	var msg := "La meta pide %s y la capacidad actual es ~%s. " % [fmt_cifra(meta, u), fmt_cifra(cap, u)]
	if corr["modo"] == "por_tramos":
		msg += "Te ofrezco construirla por tramos: el primero cubre el %d %%." % roundi(ratio * 100.0)
	else:
		msg += "Te propongo una versión viable (%d %% de la meta)." % roundi(ratio * 100.0)
	return {"aplica": true, "ratio": ratio, "mensaje": msg, "modo": corr["modo"]}
