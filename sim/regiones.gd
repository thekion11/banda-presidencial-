class_name Regiones
extends RefCounted
## Aprobación regional y su promedio nacional ponderado por población.

var catalogo: Array[Dictionary] = []
var pesos: Dictionary = {}


func cargar(p_regiones: Array) -> void:
	catalogo.clear()
	pesos.clear()
	var total: float = 0.0
	for r in p_regiones:
		catalogo.append(r)
		total += float(r["poblacion_miles"])
	for r in catalogo:
		pesos[r["id"]] = float(r["poblacion_miles"]) / total if total > 0.0 else 0.0


func existe(id: String) -> bool:
	return pesos.has(id)


func inicializar(estado: EstadoSimulacion, aprobacion: float, bastion: String, bono_bastion: float, variacion: float = 0.0) -> void:
	estado.aprobacion_regional.clear()
	for r in catalogo:
		# Variación territorial determinista (semilla + id de región); ilustrativa, no representa encuestas reales.
		var h := hash("%d:%s" % [estado.semilla, r["id"]])
		var u := float(absi(h) % 10001) / 10000.0 * 2.0 - 1.0
		var v := aprobacion + (bono_bastion if r["id"] == bastion else 0.0) + u * variacion
		estado.aprobacion_regional[r["id"]] = clampf(v, 0.0, 100.0)
	estado.aprobacion_base = estado.aprobacion_regional.duplicate()
	recalcular(estado)


func promedio(estado: EstadoSimulacion) -> float:
	var s: float = 0.0
	for id in pesos.keys():
		s += float(estado.aprobacion_regional.get(id, 0.0)) * float(pesos[id])
	return s


func recalcular(estado: EstadoSimulacion) -> void:
	if not pesos.is_empty():
		estado.indicadores["aprobacion"] = clampf(promedio(estado), 0.0, 100.0)


func aplicar_delta(estado: EstadoSimulacion, delta: float, region: String, derrame: float) -> void:
	## Si hay región objetivo, recibe el delta completo y el resto un derrame; si no, todas por igual.
	for id in pesos.keys():
		var f := 1.0
		if region != "":
			f = 1.0 if id == region else derrame
		estado.aprobacion_regional[id] = clampf(float(estado.aprobacion_regional[id]) + delta * f, 0.0, 100.0)
	recalcular(estado)


func revertir(estado: EstadoSimulacion, ancla: float, tasa: float) -> void:
	for id in pesos.keys():
		var a := float(estado.aprobacion_regional[id])
		estado.aprobacion_regional[id] = clampf(a + (ancla - a) * tasa, 0.0, 100.0)
	recalcular(estado)


func revertir_a_base(estado: EstadoSimulacion, tasa: float) -> void:
	for id in pesos.keys():
		var a := float(estado.aprobacion_regional[id])
		var b := float(estado.aprobacion_base.get(id, a))
		estado.aprobacion_regional[id] = clampf(a + (b - a) * tasa, 0.0, 100.0)
	recalcular(estado)
