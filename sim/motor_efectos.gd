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
var _motivos: Dictionary = {}  # «indicador|causa» -> cambio acumulado en la semana; solo salida para la UI (fuera del guardado y de la huella)


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


func sumar_ind(nombre: String, delta: float, causa: String = "") -> void:
	## Suma al indicador respetando sus mínimos y máximos; con `causa` (frase corta para el jugador) anota el cambio real en los motivos de la semana.
	var ind: Dictionary = estado.indicadores
	var antes := float(ind.get(nombre, 0.0))
	ind[nombre] = clampf(antes + delta, _min, _max_viv if nombre == "viviendas_anio" else _max)
	if nombre == "aprobacion" and regiones.proveedor_pisos.is_valid():  # el piso ideológico también frena la aprobación nacional
		regiones.refrescar_pisos()
		if float(ind[nombre]) < regiones.piso_nacional:
			regiones.piso_frenado += regiones.piso_nacional - float(ind[nombre]) if delta < 0.0 else 0.0
			ind[nombre] = regiones.piso_nacional
	if causa != "":
		var k := nombre + "|" + causa
		_motivos[k] = float(_motivos.get(k, 0.0)) + float(ind[nombre]) - antes


func reiniciar_motivos() -> void:
	## Vacía los motivos de la semana (se llama al cerrar el turno; el amanecer siguiente sigue sumando).
	_motivos = {}
	regiones.piso_frenado = 0.0


func anotar(nombre: String, causa: String, delta: float) -> void:
	## Anota en los motivos de la semana un cambio ya explicado (solo salida para la UI; no toca indicadores).
	var k := nombre + "|" + causa
	_motivos[k] = float(_motivos.get(k, 0.0)) + delta


func motivos_semana() -> Array[Dictionary]:
	## Hasta 3 cambios de la semana con causa conocida, de mayor a menor |delta|: {ind, delta, causa}. Solo salida: no entra al guardado ni a la huella.
	var filas: Array[Dictionary] = []
	for k in _motivos.keys():
		var d := float(_motivos[k])
		if absf(d) >= float(leyes["dinamica"]["motivo_delta_minimo"]):
			var partes: PackedStringArray = String(k).split("|")
			filas.append({"ind": partes[0], "delta": d, "causa": partes[1]})
	var pf: Dictionary = leyes["piso_ideologico"]
	if regiones.piso_frenado >= float(pf["motivo_minimo"]):  # el piso evitó una caída: se explica con la causa del núcleo duro
		filas.append({"ind": "aprobacion", "delta": regiones.piso_frenado, "causa": String(pf["texto_motivo"])})
	filas.sort_custom(func(a, b): return absf(a["delta"]) > absf(b["delta"]) or (absf(a["delta"]) == absf(b["delta"]) and a["ind"] + a["causa"] < b["ind"] + b["causa"]))
	return filas.slice(0, 3)


func marcar_cumplida(carta_id: String) -> void:
	## Marca como cumplida la primera promesa de campaña pendiente de esa carta.
	for p in estado.promesas_campana:
		if p["carta_id"] == carta_id and not bool(p["cumplida"]):
			p["cumplida"] = true
			return
