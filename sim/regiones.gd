class_name Regiones
extends RefCounted
## Aprobación regional y su promedio nacional ponderado por población.

var catalogo: Array[Dictionary] = []
var pesos: Dictionary = {}
var _ids: Array = []  # ids y pesos en arrays paralelos: los recorridos por región son lo más frecuente de la simulación
var _w := PackedFloat64Array()


func cargar(p_regiones: Array) -> void:
	catalogo.clear()
	pesos.clear()
	var total: float = 0.0
	for r in p_regiones:
		catalogo.append(r)
		total += float(r["poblacion_miles"])
	_ids.clear()
	_w = PackedFloat64Array()
	for r in catalogo:
		pesos[r["id"]] = float(r["poblacion_miles"]) / total if total > 0.0 else 0.0
		_ids.append(r["id"])
		_w.append(float(pesos[r["id"]]))


func existe(id: String) -> bool:
	return pesos.has(id)


func inicializar(estado: EstadoSimulacion, aprobacion: float, bastion: String, bono_bastion: float, variacion: float = 0.0) -> void:
	estado.aprobacion_regional.clear()
	for r in catalogo:
		# Variación territorial determinista (semilla + id de región); ilustrativa, no representa encuestas reales.
		var h := Huella.fnv32("%d:%s" % [estado.semilla, r["id"]])  # estable entre versiones de Godot
		var u := float(h % 10001) / 10000.0 * 2.0 - 1.0
		var v := aprobacion + (bono_bastion if r["id"] == bastion else 0.0) + u * variacion
		estado.aprobacion_regional[r["id"]] = clampf(v, 0.0, 100.0)
	estado.aprobacion_base = estado.aprobacion_regional.duplicate()
	recalcular(estado)


func promedio(estado: EstadoSimulacion) -> float:
	var s: float = 0.0
	var reg: Dictionary = estado.aprobacion_regional
	for i in range(_ids.size()):
		s += float(reg.get(_ids[i], 0.0)) * _w[i]
	return s


func recalcular(estado: EstadoSimulacion) -> void:
	if not pesos.is_empty():
		estado.indicadores["aprobacion"] = clampf(promedio(estado), 0.0, 100.0)


func aplicar_delta(estado: EstadoSimulacion, delta: float, region: String, derrame: float) -> void:
	## Si hay región objetivo, recibe el delta completo y el resto un derrame; si no, todas por igual. Actualiza y promedia en una sola pasada.
	var reg: Dictionary = estado.aprobacion_regional
	var s := 0.0
	for i in range(_ids.size()):
		var id: String = _ids[i]
		var f := 1.0
		if region != "":
			f = 1.0 if id == region else derrame
		var v := clampf(float(reg[id]) + delta * f, 0.0, 100.0)
		reg[id] = v
		s += v * _w[i]
	if not _ids.is_empty():
		estado.indicadores["aprobacion"] = clampf(s, 0.0, 100.0)


func revertir(estado: EstadoSimulacion, ancla: float, tasa: float, persistencia: float = 0.0) -> void:
	var reg: Dictionary = estado.aprobacion_regional
	var base: Dictionary = estado.aprobacion_base
	var media_base := 0.0
	for i in range(_ids.size()):
		media_base += float(base.get(_ids[i], 0.0)) * _w[i]
	for i in range(_ids.size()):
		var id: String = _ids[i]
		var a := float(reg[id])
		var sesgo := (float(base.get(id, media_base)) - media_base) * persistencia  # cada región conserva su carácter
		reg[id] = clampf(a + (ancla + sesgo - a) * tasa, 0.0, 100.0)
	recalcular(estado)


func revertir_a_base(estado: EstadoSimulacion, tasa: float) -> void:
	for id in pesos.keys():
		var a := float(estado.aprobacion_regional[id])
		var b := float(estado.aprobacion_base.get(id, a))
		estado.aprobacion_regional[id] = clampf(a + (b - a) * tasa, 0.0, 100.0)
	recalcular(estado)
