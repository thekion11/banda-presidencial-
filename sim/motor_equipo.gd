class_name MotorEquipo
extends RefCounted
## Asesores (DISENO_V2 §9): hasta 3, cada uno da movimientos extra y un efecto positivo y uno negativo.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno
var asesores: Dictionary = {}  # id -> asesor (data/asesores.json)


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


func cargar(lista: Array) -> void:
	asesores.clear()
	for a in lista:
		asesores[String(a["id"])] = a


func _cfg() -> Dictionary:
	return m.catalogo_leyes["asesores"]


func contratar(id: String) -> Dictionary:
	var est := m.estado
	if est.etapa != "campana" and est.etapa != "gobierno":
		return {"ok": false, "razon": "partida_terminada"}
	if not asesores.has(id):
		return {"ok": false, "razon": "asesor_inexistente"}
	if est.asesores.has(id):
		return {"ok": false, "razon": "ya_contratado"}
	if est.asesores.size() >= int(_cfg()["max"]):
		return {"ok": false, "razon": "limite_asesores"}
	est.registrar_entrada("asesor", {"accion": "contratar", "id": id})
	est.asesores.append(id)
	est.registrar_accion("asesor_contratado", {"id": id})
	return {"ok": true, "afinidad": afinidad(id)}


func despedir(id: String) -> Dictionary:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	if not _m.estado.asesores.has(id):
		return {"ok": false, "razon": "no_contratado"}
	_m.estado.registrar_entrada("asesor", {"accion": "despedir", "id": id})
	_m.estado.asesores.erase(id)
	_m.estado.registrar_accion("asesor_despedido", {"id": id})
	return {"ok": true}


func afinidad(id: String) -> float:
	## 1 = misma ideología que el partido; 0 = distancia mayor o igual a `distancia_max` (ejes eco/inst de data/ideologia.json).
	var ide: Dictionary = asesores[id]["ideologia"]
	var dist := Vector2(float(ide["eco"]) - float(m.estado.partido.get("eje_eco", 0.0)), float(ide["inst"]) - float(m.estado.partido.get("eje_inst", 0.0))).length()
	return clampf(1.0 - dist / float(_cfg()["distancia_max"]), 0.0, 1.0)


func _factor(id: String, ef: Dictionary, positivo: bool) -> float:
	## El efecto negativo se atenúa con la afinidad ideológica.
	return 1.0 if positivo else 1.0 - float(_cfg()["mitigacion_afin"]) * afinidad(id)


func movimientos_extra() -> int:
	return m.estado.asesores.size() * int(_cfg()["movimientos_extra"])


func mult_categoria(categoria: String) -> float:
	var mult := 1.0
	for id in m.estado.asesores:
		for clave in ["efecto_positivo", "efecto_negativo"]:
			var ef: Dictionary = asesores[id][clave]
			if ef["tipo"] == "categoria" and ef["categoria"] == categoria:
				mult += float(ef["mult"]) * _factor(id, ef, clave == "efecto_positivo")
	return maxf(0.0, mult)


func efectos_amanecer() -> void:
	## Efectos de indicador de los asesores, una vez por turno de gobierno.
	for id in m.estado.asesores:
		for clave in ["efecto_positivo", "efecto_negativo"]:
			var ef: Dictionary = asesores[id][clave]
			if ef["tipo"] == "indicador":
				m.fx.aplicar_efecto(ef, _factor(id, ef, clave == "efecto_positivo"), "")
