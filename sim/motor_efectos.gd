class_name MotorEfectos
extends RefCounted
## Aplicación de efectos sobre indicadores y aprobación regional (rendimientos decrecientes y límites desde data/).

var estado: EstadoSimulacion
var leyes: Dictionary = {}
var regiones: Regiones
var _min: float = 0.0
var _max: float = 100.0
var _max_viv: float = 100.0
var _piso: float = 0.0
var _rend: float = 1.0
var _derrame: float = 0.0


func configurar(p_estado: EstadoSimulacion, p_leyes: Dictionary, p_regiones: Regiones) -> void:
	## Enlaza el estado, las leyes y las regiones y fija los límites y parámetros de los efectos.
	estado = p_estado
	leyes = p_leyes
	regiones = p_regiones
	var lim: Dictionary = p_leyes["limites_indicadores"]  # límites y parámetros fijos: se leen una vez (se consultan decenas de veces por turno)
	_min = float(lim["min"])
	_max = float(lim["max"])
	_max_viv = float(lim["viviendas_anio_max"])
	var din: Dictionary = p_leyes["dinamica"]
	_piso = float(din["piso_rendimiento_decreciente"])
	_rend = float(din["rendimiento_decreciente"])
	_derrame = float(p_leyes["campana"]["derrame_regional"])


func aplicar_efecto(ef: Dictionary, escala: float, region: String) -> void:
	## Aplica un efecto de carta o evento ({ind, delta}) escalado a un indicador o a la aprobación regional.
	var delta := float(ef["delta"]) * escala
	if ef["ind"] == "aprobacion":
		delta_aprobacion(delta, region, true)
	else:
		sumar_ind(String(ef["ind"]), delta)


func delta_aprobacion(delta: float, region: String, decreciente: bool = false) -> void:
	## Cambia la aprobación (nacional o de una región) con rendimientos decrecientes al subir cuando es alta.
	if decreciente and delta > 0.0:
		delta *= maxf(_piso, 1.0 - estado.ind("aprobacion") / _rend)
	if regiones.pesos.is_empty():
		sumar_ind("aprobacion", delta)
	else:
		regiones.aplicar_delta(estado, delta, region, _derrame)


func sumar_ind(nombre: String, delta: float) -> void:
	## Suma al indicador respetando sus mínimos y máximos.
	var ind: Dictionary = estado.indicadores
	ind[nombre] = clampf(float(ind.get(nombre, 0.0)) + delta, _min, _max_viv if nombre == "viviendas_anio" else _max)


func marcar_cumplida(carta_id: String) -> void:
	## Marca como cumplida la primera promesa de campaña pendiente de esa carta.
	for p in estado.promesas_campana:
		if p["carta_id"] == carta_id and not bool(p["cumplida"]):
			p["cumplida"] = true
			return
