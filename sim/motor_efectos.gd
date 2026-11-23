class_name MotorEfectos
extends RefCounted
## Aplicación de efectos sobre indicadores y aprobación regional (rendimientos decrecientes y límites desde data/).

var estado: EstadoSimulacion
var leyes: Dictionary = {}
var regiones: Regiones


func configurar(p_estado: EstadoSimulacion, p_leyes: Dictionary, p_regiones: Regiones) -> void:
	estado = p_estado
	leyes = p_leyes
	regiones = p_regiones


func aplicar_efecto(ef: Dictionary, escala: float, region: String) -> void:
	var delta := float(ef["delta"]) * escala
	if ef["ind"] == "aprobacion":
		delta_aprobacion(delta, region, true)
	else:
		sumar_ind(String(ef["ind"]), delta)


func delta_aprobacion(delta: float, region: String, decreciente: bool = false) -> void:
	if decreciente and delta > 0.0:
		delta *= maxf(0.2, 1.0 - estado.ind("aprobacion") / float(leyes["dinamica"]["rendimiento_decreciente"]))
	if regiones.pesos.is_empty():
		sumar_ind("aprobacion", delta)
	else:
		regiones.aplicar_delta(estado, delta, region, float(leyes["campana"]["derrame_regional"]))


func sumar_ind(nombre: String, delta: float) -> void:
	var lim: Dictionary = leyes["limites_indicadores"]
	var tope := float(lim["viviendas_anio_max"]) if nombre == "viviendas_anio" else float(lim["max"])
	estado.indicadores[nombre] = clampf(estado.ind(nombre) + delta, float(lim["min"]), tope)


func marcar_cumplida(carta_id: String) -> void:
	for p in estado.promesas_campana:
		if p["carta_id"] == carta_id and not bool(p["cumplida"]):
			p["cumplida"] = true
			return
