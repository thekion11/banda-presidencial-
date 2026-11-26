class_name MotorMovimientos
extends RefCounted
## Movimientos internos de la coalición (DISENO_V2 §6): buscar metas, ajustar sectores, reducir errores y acelerar proyectos.
## Solo en gobierno; presupuesto propio por turno (leyes.json › movimientos_internos.por_turno), aparte de los movimientos de cartas.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno
var metas: Dictionary = {}  # id -> meta (data/metas.json)


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


func cargar(lista: Array) -> void:
	## Carga el catálogo de metas y movimientos internos.
	metas.clear()
	for meta in lista:
		metas[String(meta["id"])] = meta


func amanecer() -> void:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Paso 1 del turno: renueva delegaciones y movimientos internos, y abre las cartas cuya ventana de año comienza.
	var e := _m.estado
	e.delegadas_turno = 0
	e.internos_actual = int(_m.catalogo_leyes["movimientos_internos"]["por_turno"]) if e.etapa == "gobierno" else 0
	if e.etapa == "gobierno" and _m.gabinete.anio_gobierno() > 1:
		var dias_anio := int(_m._h("duracion_mandato_dias")) / int(_m.catalogo_leyes["gabinete"]["anios_mandato"])
		if (e.turno_actual - 1) * e.dias_por_turno % dias_anio < e.dias_por_turno:
			_m.mazo.incorporar(_m.mazo.ids_con_disponibilidad("anio_desde", _m.gabinete.anio_gobierno(), true))


func bono_aprobacion() -> int:
	## DISENO_V2 §11: movimientos extra por cada umbral de aprobación superado (tramos en leyes.json › bono_movimientos).
	var total := 0
	var apr := m.estado.ind("aprobacion")
	for t in m.catalogo_leyes["bono_movimientos"]["tramos"]:
		var u := float(t["desde"])
		while u <= float(t["hasta"]) + 0.0001:
			if apr >= u:
				total += int(t["mov"])
			u += float(t["paso"])
	return total


func fijar_movimientos() -> void:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Fin del amanecer: movimientos del turno = base + bono por aprobación (solo gobierno) + asesores; y efectos de asesores.
	var e := _m.estado
	e.bono_mov = {"aprobacion": bono_aprobacion() if e.etapa == "gobierno" else 0, "asesores": _m.equipo.movimientos_extra()}
	e.pa_actual = e.pa_maximo + int(e.bono_mov["aprobacion"]) + int(e.bono_mov["asesores"])
	if e.etapa == "gobierno":
		_m.equipo.efectos_amanecer()
		_m.coalicion.amanecer()
	else:
		Encuestas.registrar(_m)  # campaña y oposición: encuesta de la semana


func _cobrar(costo: int) -> Dictionary:
	if m.estado.etapa != "gobierno":
		return {"ok": false, "razon": "solo_en_gobierno"}
	if costo > m.estado.internos_actual:
		return {"ok": false, "razon": "movimientos_insuficientes", "costo": costo}
	return {"ok": true}


func metas_disponibles() -> Array[Dictionary]:
	## Metas que el jugador puede intentar ahora (sector con ministro, requisito previo cumplido, sin cumplir).
	var res: Array[Dictionary] = []
	for id in metas.keys():
		if _motivo_meta(metas[id]) == "":
			res.append(metas[id])
	return res


func _motivo_meta(meta: Dictionary) -> String:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	if _m.estado.metas_cumplidas.has(String(meta["id"])):
		return "meta_cumplida"
	if not _m.gabinete.categoria_activa(String(meta["sector"])):
		return "sector_sin_ministro"
	if meta["requiere"] != null and not _m.estado.metas_cumplidas.has(String(meta["requiere"])):
		return "requiere_meta_previa"
	return ""


func buscar_meta(meta_id: String) -> Dictionary:
	## Movimiento interno: cumple una meta (aplica sus efectos y desbloquea cartas); devuelve {ok, razon}.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	if not metas.has(meta_id):
		return {"ok": false, "razon": "meta_inexistente"}
	var meta: Dictionary = metas[meta_id]
	var motivo := _motivo_meta(meta)
	if motivo != "":
		return {"ok": false, "razon": motivo}
	var cobro := _cobrar(int(meta["costo_mov"]))
	if not bool(cobro["ok"]):
		return cobro
	_m.estado.registrar_entrada("meta", {"meta": meta_id})
	_m.estado.internos_actual -= int(meta["costo_mov"])
	for ef in meta["efectos"]:
		_m.fx.aplicar_efecto(ef, 1.0, "")
	_m.estado.metas_cumplidas[meta_id] = _m.estado.turno_actual
	var ids: Array = Array(meta["desbloquea"]) + _m.mazo.ids_con_disponibilidad("meta", meta_id)
	var nuevas := _m.mazo.incorporar(ids)
	_m.estado.registrar_accion("meta", {"meta": meta_id, "desbloquea": nuevas})
	return {"ok": true, "meta": meta_id, "desbloqueadas": nuevas}


func ajustar_sector(sector: String, direccion: int) -> Dictionary:
	## Movimiento interno: sube o baja el énfasis de un sector (dirección ±1); devuelve {ok, razon}.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var cfg: Dictionary = _m.catalogo_leyes["movimientos_internos"]["ajustar_sector"]
	if direccion != 1 and direccion != -1:
		return {"ok": false, "razon": "direccion_invalida"}
	if not _m.gabinete.categoria_activa(sector):
		return {"ok": false, "razon": "sector_sin_ministro"}
	var cobro := _cobrar(int(cfg["costo"]))
	if not bool(cobro["ok"]):
		return cobro
	var actual := float(_m.estado.indices_sector.get(sector, cfg["inicial"]))
	var nuevo := clampf(actual + float(direccion) * float(cfg["paso"]), float(cfg["min"]), float(cfg["max"]))
	if is_equal_approx(nuevo, actual):
		return {"ok": false, "razon": "sin_efecto"}
	_m.estado.registrar_entrada("sector", {"sector": sector, "dir": direccion})
	_m.estado.internos_actual -= int(cfg["costo"])
	_m.estado.indices_sector[sector] = nuevo
	for ef in cfg["efectos_subir" if direccion > 0 else "efectos_bajar"]:
		_m.fx.aplicar_efecto(ef, 1.0, "")
	_m.estado.registrar_accion("sector", {"sector": sector, "indice": nuevo})
	return {"ok": true, "indice": nuevo}


func reducir_errores() -> Dictionary:
	## Movimiento interno: baja el riesgo de ejecución; devuelve {ok, razon}.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var cfg: Dictionary = _m.catalogo_leyes["movimientos_internos"]["reducir_errores"]
	var cobro := _cobrar(int(cfg["costo"]))
	if not bool(cobro["ok"]):
		return cobro
	if _m.estado.ind("riesgo_ejecucion") <= float(_m.catalogo_leyes["limites_indicadores"]["min"]):
		return {"ok": false, "razon": "sin_efecto"}
	_m.estado.registrar_entrada("errores", {})
	_m.estado.internos_actual -= int(cfg["costo"])
	_m.fx.sumar_ind("riesgo_ejecucion", float(cfg["delta_riesgo"]))
	_m.estado.registrar_accion("reducir_errores", {"riesgo": snappedf(_m.estado.ind("riesgo_ejecucion"), 0.01)})
	return {"ok": true, "riesgo": _m.estado.ind("riesgo_ejecucion")}


func acelerar_proyecto(idx: int) -> Dictionary:
	## Movimiento interno: adelanta la obra en curso indicada; devuelve {ok, razon}.
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	var cfg: Dictionary = _m.catalogo_leyes["movimientos_internos"]["acelerar_proyecto"]
	if idx < 0 or idx >= _m.estado.obras_en_curso.size():
		return {"ok": false, "razon": "indice_invalido"}
	var cobro := _cobrar(int(cfg["costo"]))
	if not bool(cobro["ok"]):
		return cobro
	var obra: Dictionary = _m.estado.obras_en_curso[idx]
	if int(obra["dias_avanzados"]) >= int(obra["dias_totales"]):
		return {"ok": false, "razon": "sin_efecto"}
	_m.estado.registrar_entrada("acelerar", {"idx": idx})
	_m.estado.internos_actual -= int(cfg["costo"])
	obra["dias_avanzados"] = mini(int(obra["dias_avanzados"]) + int(cfg["dias"]), int(obra["dias_totales"]))
	obra["fase"] = MotorObras.fase_de(obra)
	_m.estado.registrar_accion("acelerar_proyecto", {"obra": obra["id"], "dias_avanzados": obra["dias_avanzados"]})
	return {"ok": true, "obra": obra["id"], "dias_avanzados": obra["dias_avanzados"]}
