class_name ValidarGuardado
extends RefCounted
## Validación estructural previa a reproducir un guardado por eventos (GDScript no captura errores en ejecución): semilla, partido y entradas con las claves y tipos
## que usa Partida.reproducir. La tabla ENTRADAS documenta además el formato del guardado. Un guardado que no pasa se descarta antes de tocar el motor.

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
	"aprobar_propuesta": {"prop": S, "variante": S, "region": S}, "sectra": {"pid": S}, "continuar": {}, "decision": {"evento": S, "idx": I}, "cerrar": {}, "eleccion": {},
}


static func _es(v: Variant, tipo: int) -> bool:
	if tipo == I:
		return (v is int) or ((v is float) and v == floorf(v))
	return typeof(v) == tipo


static func _numero(v: Variant) -> bool:
	return (v is int) or (v is float)


static func partido_valido(p: Variant) -> bool:
	if not (p is Dictionary) or not (p.get("indicadores_iniciales") is Dictionary):
		return false
	for k in INDICADORES:
		if not _numero(p["indicadores_iniciales"].get(k)):
			return false
	for k in ["eje_eco", "eje_inst", "escanos_propios"]:
		if p.has(k) and not _numero(p[k]):
			return false
	for k in ["region_bastion", "partido_base", "dificultad"]:
		if p.has(k) and not (p[k] is String):
			return false
	return true


static func entrada_valida(e: Variant) -> bool:
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
	if e["tipo"] == "jugar" and e.has("delegada") and not (e["delegada"] is bool):
		return false
	return true


static func guardado_valido(g: Variant) -> bool:
	if not (g is Dictionary) or not _es(g.get("semilla"), I) or not partido_valido(g.get("partido")) or not (g.get("entradas") is Array):
		return false
	for e in g["entradas"]:
		if not entrada_valida(e):
			return false
	return true
