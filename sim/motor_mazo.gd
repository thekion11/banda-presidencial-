class_name MotorMazo
extends RefCounted
## Mazo y mano continua (DISENO_V2 §3): la mano se rellena al instante y solo reparte cartas disponibles (gabinete, ventanas, eventos, metas).

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


func robar(n: int) -> void:
	## Roba cartas disponibles hasta completar la mano, rearmando el mazo desde el descarte si hace falta.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var e := _m.estado
	var intentos := e.mazo.size() + e.descarte.size() + _m.catalogo_cartas.size()  # tope: si nada está disponible, no se cuelga
	var por_id: Dictionary = _m._cartas_por_id
	var gab := _m.gabinete
	while e.mano.size() < n and intentos > 0:
		intentos -= 1
		if e.mazo.is_empty() and not reponer():
			return
		var id: String = e.mazo.pop_back()
		if e.cartas_ejecutadas.has(id):
			continue  # carta única ya ejecutada: sale del mazo
		var carta: Dictionary = por_id[id]
		if not gab.disponible(carta):
			e.descarte.append(id)  # no disponible ahora: vuelve al descarte y se reevalúa en la próxima reposición
			continue
		e.mano.append(carta)
	_asegurar_disenadas()


func _asegurar_disenadas() -> void:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Composición de la mano (Fase B): al menos `mano.min_disenadas` cartas diseñadas a mano (no generadas de proyectos reales).
	## Si faltan, una carta real de la mano vuelve al fondo del mazo y entra una diseñada disponible.
	var e := _m.estado
	var minimo := int(_m.catalogo_leyes["mano"].get("min_disenadas", 0))
	var n_dis := 0
	var esr: Dictionary = _m.indices.es_real
	for c in e.mano:
		var id: String = c["id"]
		if not (esr[id] if esr.has(id) else _m.cartas.es_real(c)):
			n_dis += 1
	if n_dis >= minimo:
		return
	_m.gabinete.abrir_contexto()  # puede revisar muchas cartas del mazo: el contexto de disponibilidad se calcula una vez
	_completar_disenadas(n_dis, minimo)
	_m.gabinete.cerrar_contexto()


func _completar_disenadas(n_dis: int, minimo: int) -> void:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var e := _m.estado
	while n_dis < minimo:
		var ia := -1
		for i in range(e.mazo.size() - 1, -1, -1):
			var c: Dictionary = _m._cartas_por_id[e.mazo[i]]
			if not _m.cartas.es_real(c) and not e.cartas_ejecutadas.has(String(c["id"])) and _m.gabinete.disponible(c):
				ia = i
				break
		var ir := -1
		for j in range(e.mano.size() - 1, -1, -1):
			if _m.cartas.es_real(e.mano[j]):
				ir = j
				break
		if ia < 0 or ir < 0:
			return
		var real: Dictionary = e.mano[ir]
		e.mano[ir] = _m._cartas_por_id[e.mazo[ia]]
		e.mazo.remove_at(ia)
		e.mazo.insert(0, String(real["id"]))
		n_dis += 1


func reponer() -> bool:
	## Devuelve al mazo las cartas del descarte que vuelven a estar disponibles; true si pudo reponer.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var e := _m.estado
	var presentes := {}
	for c in e.mano:
		presentes[String(c["id"])] = true
	var restos: Array[String] = []
	_m.gabinete.abrir_contexto()
	for id in e.descarte:
		if _m.gabinete.disponible(_m._cartas_por_id[id]):
			e.mazo.append(id)
		else:
			restos.append(id)
	e.descarte.assign(restos)
	for id in e.mazo:
		presentes[id] = true
	for id in e.descarte:
		presentes[id] = true
	for c in _m.cartas.no_reales():  # cartas nuevas que nunca entraron al mazo (filtradas antes, p. ej. por gabinete)
		var id := String(c["id"])
		if not presentes.has(id) and not e.cartas_ejecutadas.has(id) and _m.gabinete.disponible(c):
			e.mazo.append(id)
	_m.gabinete.cerrar_contexto()
	e.mazo.append_array(_m.cartas.reales_para_mazo())
	for i in range(e.mazo.size() - 1, 0, -1):  # Fisher-Yates con la semilla de la partida
		var j := _m.rng.randi_range(0, i)
		var tmp: String = e.mazo[i]
		e.mazo[i] = e.mazo[j]
		e.mazo[j] = tmp
	return not e.mazo.is_empty()


func refiltrar_mano() -> void:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Tras cambiar el gabinete: las cartas que dejaron de estar disponibles vuelven al descarte y entran otras.
	var e := _m.estado
	var quedan: Array[Dictionary] = []
	for c in e.mano:
		if _m.gabinete.disponible(c):
			quedan.append(c)
		else:
			e.descarte.append(String(c["id"]))
	e.mano = quedan
	robar(int(_m.catalogo_leyes["mano"]["tamano"]))


func incorporar(ids: Array) -> Array[String]:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Desbloqueo (meta, evento o ventana): las cartas disponibles pasan al tope del mazo para robarse pronto.
	var e := _m.estado
	var nuevas: Array[String] = []
	for id in ids:
		var sid := String(id)
		if not _m._cartas_por_id.has(sid) or e.cartas_ejecutadas.has(sid) or not _m.gabinete.disponible(_m._cartas_por_id[sid]):
			continue
		if e.mano.any(func(c: Dictionary) -> bool: return c["id"] == sid):
			continue
		e.mazo.erase(sid)
		e.descarte.erase(sid)
		e.mazo.append(sid)
		nuevas.append(sid)
	return nuevas


func ids_con_disponibilidad(clave: String, valor: Variant, solo_no_reales: bool = false) -> Array[String]:
	## Cartas ligadas a una condición (evento, año...): índice precalculado con los datos (antes recorría las ~2.000 cartas por cada evento).
	var res: Array[String] = []
	for c in m.indices.disp.get(clave, {}).get(IndicesCartas.clave(valor), []):
		if not (solo_no_reales and m.cartas.es_real(c)):
			res.append(String(c["id"]))
	return res


func reposicion() -> Array[String]:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## DISENO_V2 §12: si la mano quedó vacía y quedan movimientos, entran más cartas disponibles (incluidas las que
	## el sorteo del mazo dejó fuera). Registra la acción `reposicion` con los ids nuevos para que la UI la anime.
	var e := _m.estado
	var nuevas: Array[String] = []
	if not e.mano.is_empty() or (e.pa_actual <= 0 and e.delegadas_turno >= int(_m.catalogo_leyes["delegacion"]["max_por_turno"])):
		return nuevas
	var cand: Array[String] = []
	_m.gabinete.abrir_contexto()
	for c in _m.catalogo_cartas:
		var id: String = c["id"]
		if not e.cartas_ejecutadas.has(id) and _m.gabinete.disponible(c):
			cand.append(id)
	_m.gabinete.cerrar_contexto()
	for i in range(cand.size() - 1, 0, -1):
		var j := _m.rng.randi_range(0, i)
		var tmp := cand[i]
		cand[i] = cand[j]
		cand[j] = tmp
	for id in cand.slice(0, int(_m.catalogo_leyes["mano"]["reposicion_cartas"])):
		e.mazo.erase(id)
		e.descarte.erase(id)
		e.mano.append(_m._cartas_por_id[id])
		nuevas.append(id)
	if not nuevas.is_empty():
		e.registrar_accion("reposicion", {"ids": nuevas})
	return nuevas
