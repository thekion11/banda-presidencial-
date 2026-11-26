class_name Instantanea
extends RefCounted
## Instantánea de una partida: una CACHÉ de carga, no la fuente de verdad. La partida sigue siendo semilla + partido + historial de entradas
## (el guardado por eventos); la instantánea solo evita volver a simular todo el historial al continuar (~170 ms de un mandato completo, varias veces
## más en un teléfono). Se valida contra el guardado (SHA-256 de su archivo) y contra la versión de los datos; ante cualquier diferencia se ignora y se
## reproduce el historial. `test_instantanea` comprueba que restaurar y reproducir dan el mismo estado y siguen igual de ahí en adelante.

const VERSION := 1


static func tomar(motor: MotorTurno, huella_datos: String, sha_guardado: String) -> PackedByteArray:
	## Estado completo del motor serializado y comprimido (~50 KB). Solo lee; no cambia la partida.
	var props := {}
	for pr in motor.estado.get_property_list():
		if int(pr["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			props[pr["name"]] = motor.estado.get(pr["name"])
	var d := {"v": VERSION, "huella_datos": huella_datos, "sha_guardado": sha_guardado, "estado": props,
			"rng_seed": motor.rng.seed, "rng_state": motor.rng.state, "ultimos_eventos": motor.ultimos_eventos, "votaciones": motor.votaciones_semana}
	var crudo := var_to_bytes(d)
	var res := PackedByteArray()
	res.resize(4)
	res.encode_u32(0, crudo.size())
	res.append_array(crudo.compress(FileAccess.COMPRESSION_ZSTD))
	return res


static func leer(bytes: PackedByteArray) -> Dictionary:
	## Instantánea decodificada, o {} si está vacía o dañada.
	if bytes.size() < 8:
		return {}
	var n := int(bytes.decode_u32(0))
	var crudo := bytes.slice(4).decompress(n, FileAccess.COMPRESSION_ZSTD)
	if crudo.size() != n:
		return {}
	var d: Variant = bytes_to_var(crudo)
	return d if d is Dictionary and int(d.get("v", 0)) == VERSION else {}


const CLAVES := ["estado", "rng_seed", "rng_state", "ultimos_eventos", "votaciones"]


static func es_completa(d: Dictionary) -> bool:
	## Estructura mínima para restaurar (una instantánea con huella y SHA válidos pero sin sus partes se ignora en vez de fallar).
	for k in CLAVES:
		if not d.has(k):
			return false
	if not (d["estado"] is Dictionary) or not (d["ultimos_eventos"] is Array) or not (d["votaciones"] is Array):
		return false
	if not (d["rng_seed"] is int) or not (d["rng_state"] is int):
		return false
	var e: Dictionary = d["estado"]
	for k in ["semilla", "etapa", "turno_actual", "indicadores", "mano", "mazo", "entradas"]:
		if not e.has(k):
			return false
	return (e["indicadores"] is Dictionary) and not (e["indicadores"] as Dictionary).is_empty() and (e["mano"] is Array) and (e["mazo"] is Array) and (e["entradas"] is Array) and e["etapa"] is String


static func vale_para(d: Dictionary, huella_datos: String, sha_guardado: String) -> bool:
	return not d.is_empty() and es_completa(d) and String(d.get("huella_datos", "")) == huella_datos and String(d.get("sha_guardado", "")) == sha_guardado and sha_guardado != ""


static func restaurar(datos: Dictionary, semilla: int, d: Dictionary) -> MotorTurno:
	## Mismo motor que daría reproducir el historial, sin simularlo.
	var motor := Partida.armar(datos, semilla)
	var estado := motor.estado
	var props: Dictionary = d["estado"]
	for nombre in props.keys():
		var actual: Variant = estado.get(nombre)
		if actual is Array and (actual as Array).is_typed():
			(actual as Array).assign(props[nombre])
		else:
			estado.set(nombre, props[nombre])
	motor.rng.seed = int(d["rng_seed"])
	motor.rng.state = int(d["rng_state"])
	motor.ultimos_eventos.assign(d["ultimos_eventos"])
	motor.votaciones_semana.assign(d["votaciones"])
	motor.eventos.reconstruir()
	return motor
