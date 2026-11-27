class_name ValidarGuardado
extends RefCounted
## Validación estructural previa a reproducir un guardado por eventos (GDScript no captura errores en ejecución): semilla, partido y entradas con las claves y tipos
## que usa Partida.reproducir. La tabla ENTRADAS documenta además el formato del guardado. Un guardado que no pasa se descarta antes de tocar el motor.

const VERSION := 4  # versión del formato del guardado: subirla al cambiar claves del archivo o de las entradas (tests/test_formato_guardado.gd lo exige)
const INDICADORES := ["aprobacion", "capital", "cohesion", "fiscal", "riesgo_ejecucion", "viviendas_anio"]
const S := TYPE_STRING
const I := TYPE_INT
const B := TYPE_BOOL
const D := TYPE_DICTIONARY
const A := TYPE_ARRAY
## tipo de entrada -> {clave: tipo} obligatorias (los números JSON llegan como float: cuentan como entero si no tienen decimales)
const ENTRADAS := {
	"jugar": {"idx": I, "ministro": S, "region": S}, "gabinete": {"ids": A}, "asesor": {"accion": S, "id": S}, "coalicion": {"accion": S, "id": S},
	"cuota": {"id": S, "clase": S, "valor": S, "quitar": B}, "meta": {"meta": S}, "sector": {"sector": S, "dir": I}, "errores": {}, "acelerar": {"idx": I},
	"aprobar_propuesta": {"prop": S, "variante": S, "region": S}, "sectra": {"pid": S}, "continuar": {}, "decision": {"evento": S, "idx": I}, "presentar": {"carta": S, "urgencia": S, "ministro": S, "region": S, "delegar": B}, "cerrar": {}, "eleccion": {}, "bala": {"id": S, "objetivo": I, "reducida": B}, "presupuesto": {"accion": S, "slot": S, "nivel": S, "prio": A},
}


static func _es(v: Variant, tipo: int) -> bool:
	if tipo == I:
		return (v is int) or ((v is float) and v == floorf(v))
	return typeof(v) == tipo


static func _numero(v: Variant) -> bool:
	return (v is int) or (v is float)


static func partido_valido(p: Variant) -> bool:
	## true si el partido guardado tiene los indicadores y los tipos que usa el motor.
	if not (p is Dictionary) or not (p.get("indicadores_iniciales") is Dictionary):
		return false
	for k in INDICADORES:
		var v: Variant = p["indicadores_iniciales"].get(k)
		if not _numero(v) or not is_finite(float(v)) or float(v) < 0.0 or (k != "viviendas_anio" and float(v) > 100.0):
			return false  # un número válido pero absurdo (fiscal = 1.000.000) tampoco entra al estado
	for k in ["eje_eco", "eje_inst"]:
		if p.has(k) and (not _numero(p[k]) or absf(float(p[k])) > 1.0):
			return false
	if p.has("escanos_propios") and (not _numero(p["escanos_propios"]) or float(p["escanos_propios"]) < 0.0):
		return false
	for k in ["region_bastion", "partido_base", "dificultad"]:
		if p.has(k) and not (p[k] is String):
			return false
	return true


static func entrada_valida(e: Variant) -> bool:
	## true si la entrada tiene un tipo conocido y las claves obligatorias de ese tipo con su tipo.
	if not (e is Dictionary) or not (e.get("tipo") is String) or not ENTRADAS.has(e["tipo"]):
		return false
	var req: Dictionary = ENTRADAS[e["tipo"]]
	for k in req:
		if not e.has(k) or not _es(e[k], req[k]):
			return false
	if e["tipo"] == "gabinete":
		return (e["ids"] as Array).all(func(x: Variant) -> bool: return x is String)
	if e["tipo"] == "aprobar_propuesta" and ((e.has("custom") and not (e["custom"] is Dictionary)) or (e.has("nombres") and not (e["nombres"] is Dictionary))):
		return false
	if e["tipo"] == "presupuesto" and not (e["prio"] as Array).all(func(x: Variant) -> bool: return x is String):
		return false
	if e["tipo"] == "jugar" and e.has("delegada") and not (e["delegada"] is bool):
		return false
	return true


static func guardado_valido(g: Variant) -> bool:
	## true si el guardado completo (versión, semilla, partido y entradas) tiene la forma esperada; se usa antes de reproducir.
	if not (g is Dictionary) or not _es(g.get("version"), I) or int(g["version"]) > VERSION or not _es(g.get("semilla"), I) or not partido_valido(g.get("partido")) or not (g.get("entradas") is Array):
		return false
	for e in g["entradas"]:
		if not entrada_valida(e):
			return false
	return true
