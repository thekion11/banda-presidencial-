class_name Regiones
extends RefCounted
## Aprobación regional y su promedio nacional ponderado por población.

var catalogo: Array[Dictionary] = []
var pesos: Dictionary = {}
var _ids: Array = []  # ids y pesos en arrays paralelos: los recorridos por región son lo más frecuente de la simulación
var _w := PackedFloat64Array()
var proveedor_pisos: Callable = Callable()  # () -> Dictionary id -> piso (PisoIdeologico.pisos); sin él no hay piso
var piso_nacional: float = 0.0  # promedio ponderado de los pisos regionales vigentes
var piso_frenado: float = 0.0  # puntos de aprobación nacional que el piso evitó perder en la semana (solo salida para la UI; se vacía al cerrar el turno)
var _p := PackedFloat64Array()  # pisos por región, en el orden de _ids


func cargar(p_regiones: Array) -> void:
	## Carga las regiones y calcula los pesos por población.
	catalogo.clear()
	pesos.clear()
	var total: float = 0.0
	for r in p_regiones:
		catalogo.append(r)
		total += float(r["poblacion_miles"])
	_ids.clear()
	_w = PackedFloat64Array()
	_p = PackedFloat64Array()
	for r in catalogo:
		pesos[r["id"]] = float(r["poblacion_miles"]) / total if total > 0.0 else 0.0
		_ids.append(r["id"])
		_w.append(float(pesos[r["id"]]))
		_p.append(0.0)


func existe(id: String) -> bool:
	## true si el id corresponde a una región.
	return pesos.has(id)


func refrescar_pisos() -> void:
	## Recalcula los pisos regionales y el nacional desde el estado actual (se llama antes de cada operación que los usa: así dependen solo del estado).
	piso_nacional = 0.0
	if not proveedor_pisos.is_valid():
		return
	var d: Dictionary = proveedor_pisos.call()
	for i in range(_ids.size()):
		_p[i] = float(d.get(_ids[i], 0.0))
		piso_nacional += _p[i] * _w[i]


func piso_de(id: String) -> float:
	## Piso vigente de una región (el último calculado); 0 si no existe.
	var i := _ids.find(id)
	return _p[i] if i >= 0 else 0.0


func inicializar(estado: EstadoSimulacion, aprobacion: float, bastion: String, bono_bastion: float, variacion: float = 0.0) -> void:
	## Fija la aprobación regional inicial (bastión y variación determinista por semilla) y recalcula la nacional.
	estado.aprobacion_regional.clear()
	refrescar_pisos()
	for r in catalogo:
		# Variación territorial determinista (semilla + id de región); ilustrativa, no representa encuestas reales.
		var h := Huella.fnv32("%d:%s" % [estado.semilla, r["id"]])  # estable entre versiones de Godot
		var u := float(h % 10001) / 10000.0 * 2.0 - 1.0
		var v := aprobacion + (bono_bastion if r["id"] == bastion else 0.0) + u * variacion
		estado.aprobacion_regional[r["id"]] = clampf(maxf(v, piso_de(String(r["id"]))), 0.0, 100.0)
	estado.aprobacion_base = estado.aprobacion_regional.duplicate()
	recalcular(estado)


func promedio(estado: EstadoSimulacion) -> float:
	## Aprobación nacional: promedio regional ponderado por población.
	var s: float = 0.0
	var reg: Dictionary = estado.aprobacion_regional
	for i in range(_ids.size()):
		s += float(reg.get(_ids[i], 0.0)) * _w[i]
	return s


func recalcular(estado: EstadoSimulacion) -> void:
	## Pone la aprobación nacional igual al promedio regional.
	if not pesos.is_empty():
		estado.indicadores["aprobacion"] = clampf(promedio(estado), 0.0, 100.0)


func aplicar_delta(estado: EstadoSimulacion, delta: float, region: String, derrame: float) -> void:
	## Si hay región objetivo, recibe el delta completo y el resto un derrame; si no, todas por igual. Actualiza y promedia en una sola pasada.
	refrescar_pisos()
	var reg: Dictionary = estado.aprobacion_regional
	var s := 0.0
	for i in range(_ids.size()):
		var id: String = _ids[i]
		var f := 1.0
		if region != "":
			f = 1.0 if id == region else derrame
		var v := clampf(float(reg[id]) + delta * f, 0.0, 100.0)
		if v < _p[i]:  # el piso ideológico frena la caída (y sube a quien ya estaba debajo)
			piso_frenado += (_p[i] - v) * _w[i] if delta < 0.0 else 0.0
			v = _p[i]
		reg[id] = v
		s += v * _w[i]
	if not _ids.is_empty():
		estado.indicadores["aprobacion"] = clampf(s, 0.0, 100.0)


func revertir(estado: EstadoSimulacion, ancla: float, tasa: float, persistencia: float = 0.0) -> void:
	## Acerca cada región hacia un ancla (conservando su carácter) y recalcula la nacional.
	refrescar_pisos()
	var reg: Dictionary = estado.aprobacion_regional
	var base: Dictionary = estado.aprobacion_base
	var media_base := 0.0
	for i in range(_ids.size()):
		media_base += float(base.get(_ids[i], 0.0)) * _w[i]
	for i in range(_ids.size()):
		var id: String = _ids[i]
		var a := float(reg[id])
		var sesgo := (float(base.get(id, media_base)) - media_base) * persistencia  # cada región conserva su carácter
		var nuevo := clampf(a + (ancla + sesgo - a) * tasa, 0.0, 100.0)
		if nuevo < _p[i]:
			piso_frenado += (_p[i] - nuevo) * _w[i] if nuevo < a else 0.0
			nuevo = _p[i]
		reg[id] = nuevo
	recalcular(estado)


func revertir_a_base(estado: EstadoSimulacion, tasa: float) -> void:
	## Acerca cada región a su aprobación base según la tasa dada.
	refrescar_pisos()
	for id in pesos.keys():
		var a := float(estado.aprobacion_regional[id])
		var b := float(estado.aprobacion_base.get(id, a))
		estado.aprobacion_regional[id] = clampf(maxf(a + (b - a) * tasa, piso_de(String(id))), 0.0, 100.0)
	recalcular(estado)
