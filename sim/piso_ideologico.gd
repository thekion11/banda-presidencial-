class_name PisoIdeologico
extends RefCounted
## Piso ideológico (D-BQ): el núcleo duro de tu ideología y tu coalición. La aprobación de cada región, la nacional y el voto de cada región no bajan de su piso.
## Solo cálculo sobre el estado (sin estado propio): el mismo estado da siempre los mismos pisos, así que replay e instantánea coinciden. Cifras en data/leyes.json › piso_ideologico.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno
var _lean: Dictionary = {}  # id de región -> inclinación ilustrativa -1..1 (depende solo de la semilla)
var _clave: Array = []  # entradas del último cálculo; si no cambian, se reutiliza el resultado (solo es una caché: no cambia ningún valor)
var _cache: Dictionary = {}


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


func inclinacion(id: String) -> float:
	## Inclinación ilustrativa de la región en el eje económico (-1 izquierda … 1 derecha), determinista por semilla. No representa datos reales.
	if not _lean.has(id):
		var h := Huella.fnv32("%d:ideologia:%s" % [m.estado.semilla, id])
		_lean[id] = float(h % 10001) / 10000.0 * 2.0 - 1.0
	return float(_lean[id])


func afinidad(id: String) -> float:
	## 0..1: qué tan cerca está la inclinación de la región del eje económico del partido (1 = misma posición).
	return clampf(1.0 - absf(inclinacion(id) - float(m.estado.partido.get("eje_eco", 0.0))) / 2.0, 0.0, 1.0)


func _fuerza_coalicion() -> float:
	## Satisfacción media de la coalición (0..1) por la cohesión del gobierno (0..1); sin coalición vale 0.
	var est := m.estado
	if est.coalicion.is_empty():
		return 0.0
	var s := 0.0
	for c in est.coalicion.values():
		s += float(c["satisfaccion"]) / 100.0
	return s / float(est.coalicion.size()) * clampf(est.ind("cohesion") / 100.0, 0.0, 1.0)


func pisos() -> Dictionary:
	## Piso de aprobación y de voto por región (id -> puntos 0..100); sin partido o sin regiones, todos 0. El diccionario es de solo lectura (se reutiliza mientras no cambien sus entradas).
	var rg := m.regiones
	var est := m.estado
	var p0 := est.partido
	var clave := [_fuerza_coalicion(), p0.get("eje_eco", 0.0), p0.get("eje_inst", 0.0), p0.get("escanos_propios", 0), p0.get("region_bastion", ""), rg.pesos.size(), est.semilla]
	if clave == _clave:
		return _cache
	var res := _calcular()
	_clave = clave
	_cache = res
	return res


func _calcular() -> Dictionary:
	var res := {}
	var rg := m.regiones
	var est := m.estado
	if rg.pesos.is_empty() or est.partido.is_empty():
		for id in rg.pesos.keys():
			res[id] = 0.0
		return res
	var c: Dictionary = m.catalogo_leyes["piso_ideologico"]
	var p := est.partido
	var dist := Vector2(float(p.get("eje_eco", 0.0)), float(p.get("eje_inst", 0.0))).length()
	var comun := float(c["base"]) + float(c["peso_distancia"]) * clampf(dist / float(c["distancia_max"]), 0.0, 1.0) \
			+ float(c["peso_escanos"]) * clampf(float(p.get("escanos_propios", 0)) / float(c["escanos_ref"]), 0.0, 1.0) \
			+ float(c["peso_coalicion"]) * _fuerza_coalicion()
	var bastion := String(p.get("region_bastion", ""))
	var nacional := 0.0
	for r in rg.catalogo:
		var id := String(r["id"])
		var v := comun + float(c["peso_afinidad"]) * afinidad(id) + (float(c["bono_bastion"]) if id == bastion else 0.0)
		v = clampf(v, 0.0, float(c["tope_region"]))
		res[id] = v
		nacional += v * float(rg.pesos[id])
	if nacional > float(c["tope_nacional"]):  # el piso nacional queda bajo el umbral de crisis: la caída del gobierno sigue siendo posible
		var f := float(c["tope_nacional"]) / nacional
		for id in res.keys():
			res[id] = float(res[id]) * f
	return res


func nacional() -> float:
	## Piso nacional: promedio de los pisos regionales ponderado por población.
	var rg := m.regiones
	var pi := pisos()
	var s := 0.0
	for id in pi.keys():
		s += float(pi[id]) * float(rg.pesos[id])
	return s


func umbral_crisis(base: float) -> float:
	## Umbral de aprobación bajo el cual cuenta una semana de crisis: el de siempre, o `crisis_margen_sobre_piso` puntos sobre el piso nacional si eso es más (con un piso alto la aprobación no baja del piso, así que la crisis se mide sobre lo que hay encima).
	return maxf(base, nacional() + float(m.catalogo_leyes["piso_ideologico"]["crisis_margen_sobre_piso"]))


func resumen() -> Dictionary:
	## Solo lectura para la interfaz: {nacional, voto_duro (= nacional), por_region: [{id, piso, afinidad}], frenado} (frenado = puntos de aprobación nacional que el piso evitó perder esta semana).
	var pi := pisos()
	var filas: Array[Dictionary] = []
	var nac := 0.0
	for r in m.regiones.catalogo:
		var id := String(r["id"])
		nac += float(pi.get(id, 0.0)) * float(m.regiones.pesos[id])
		filas.append({"id": id, "piso": float(pi.get(id, 0.0)), "afinidad": afinidad(id)})
	return {"nacional": nac, "voto_duro": nac, "por_region": filas, "frenado": m.regiones.piso_frenado}
