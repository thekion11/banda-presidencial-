class_name DirectorEventos
extends RefCounted
## Director de eventos v2 (data/leyes.json «director_eventos»): elige el evento aleatorio de la semana. A lo sumo uno por semana, con probabilidad que sube
## con el silencio, decisiones entre un mínimo y un máximo por año, estaciones y contexto, y descansos por evento, familia y decisión. Determinista con la semilla.
## Lleva un historial incremental (última semana por familia, última decisión...) que se actualiza en `registrar` y se rehace con `reconstruir`.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


var _ult_fam: Dictionary = {}  # familia -> semana del último evento de esa familia (se actualiza en aplicar_evento; antes se recorría todo lo ocurrido)
var _ult_dec: int = -1000  # semana de la última decisión
var _dec_sem: Dictionary = {}  # id de decisión aleatoria -> semana en que ocurrió por última vez
var _n_visto: int = 0
var _cd_decision: bool = false  # hubo una decisión hace menos de cooldown_decision (se fija al empezar a elegir)


func reconstruir() -> void:
	## Tras restaurar una instantánea: rehace el historial incremental del director a partir de lo ocurrido (es lo mismo que fue acumulando aplicar_evento).
	m.eventos._indice()
	_ult_fam.clear()
	_ult_dec = -1000
	_dec_sem.clear()
	_ultima = -1000
	var oc: Dictionary = m.estado.eventos_ocurridos
	for id in oc.keys():
		var evt: Dictionary = m.eventos._por_id.get(String(id), {})
		if evt.is_empty():
			continue
		var sem := int(oc[id])
		_ultima = maxi(_ultima, sem)
		_ult_fam[String(evt.get("familia", ""))] = maxi(int(_ult_fam.get(String(evt.get("familia", "")), -1000)), sem)
		if evt.has("opciones"):
			_ult_dec = maxi(_ult_dec, sem)
			if evt["tipo"] == "aleatorio_semilla":
				_dec_sem[String(id)] = sem
	_n_visto = oc.size()


func _sincronizar() -> void:
	## Si lo ocurrido se reinició (nuevo periodo de la carrera), el historial incremental también.
	if m.estado.eventos_ocurridos.size() < _n_visto:
		_ult_fam.clear()
		_ult_dec = -1000
		_dec_sem.clear()
		_ultima = -1000
	_n_visto = m.estado.eventos_ocurridos.size()


func _preparar_cooldowns(cfg: Dictionary, ahora: int) -> void:
	m.eventos._indice()
	_sincronizar()
	_cd_decision = ahora - _ult_dec < int(cfg["cooldown_decision"])


func _en_cooldown(evt: Dictionary, cfg: Dictionary, ahora: int) -> bool:
	var oc: Dictionary = m.estado.eventos_ocurridos
	if oc.has(String(evt["id"])) and ahora - int(oc[String(evt["id"])]) < int(cfg["cooldown_evento"]):
		return true
	if _ult_fam.has(String(evt.get("familia", "?"))) and ahora - int(_ult_fam[String(evt.get("familia", "?"))]) < int(cfg["cooldown_familia"]):
		return true
	return evt.has("opciones") and _cd_decision


func mes_actual() -> int:
	## Mes del calendario (1 a 12) de la semana en curso: desde el ciclo 2 hay un solo reloj; en el ciclo 1 la campaña y el gobierno tienen su fecha base.
	var cal: Dictionary = m.catalogo_leyes["calendario"]
	var e := m.estado
	var base := String(cal["fecha_inicio_mandato"] if (e.etapa == "gobierno" or e.ciclo > 1) else cal["fecha_inicio_campana"])
	var dias := (e.dia_actual - 1) if e.etapa == "gobierno" else (e.turno_actual - 1) * e.dias_por_turno
	var t := Time.get_unix_time_from_datetime_string(base + "T00:00:00") + (dias + (e.dias_carrera if e.ciclo > 1 else 0)) * 86400
	return int(Time.get_datetime_dict_from_unix_time(t)["month"])


func _peso_efectivo(evt: Dictionary, cfg: Dictionary, mes: int) -> float:
	## Peso relativo ajustado por estación (`meses`) y por contexto (`contexto`: indicador bajo o alto → multiplicador).
	var w := float(evt.get("peso_sorteo", 0.0))
	if evt.has("meses"):
		w *= float(cfg["estacion_en"]) if (evt["meses"] as Array).has(mes) else float(cfg["estacion_fuera"])
	for c in evt.get("contexto", []):
		var v := m.estado.ind(String(c["ind"]))
		if (c.has("bajo") and v < float(c["bajo"])) or (c.has("alto") and v > float(c["alto"])):
			w *= float(c["mult"])
	return w


var _ultima: int = -1000  # semana del último evento ocurrido (se actualiza en aplicar_evento; con lo ocurrido vacío no vale)


func _silencio(ahora: int) -> int:
	return ahora + 1000 if m.estado.eventos_ocurridos.is_empty() else ahora - _ultima


func _decisiones_ultimo_anio(ahora: int) -> int:
	var n := 0
	for id in _dec_sem:
		if ahora - int(_dec_sem[id]) < 52:
			n += 1
	return n


func elegir_evento(grupo: Dictionary) -> Dictionary:
	if grupo.is_empty():
		return {}
	return _elegir(grupo)


func _elegir(grupo: Dictionary) -> Dictionary:
	var _m := m  # una sola resolución de la referencia débil por llamada (cada acceso a `m` cuesta ~0,5 us)
	## Director v2 (data/leyes.json «director_eventos»): a lo sumo un evento aleatorio por semana, con probabilidad que sube con el silencio,
	## decisiones entre un mínimo y un máximo por año, estaciones y contexto. Determinista con la semilla.
	var cfg: Dictionary = _m.catalogo_leyes["director_eventos"]
	var ahora := m.eventos.semana_abs()
	var silencio := _silencio(ahora)
	var p := minf(float(cfg["prob_max"]), float(cfg["prob_semana"]) + float(cfg["ajuste_silencio"]) * float(maxi(0, silencio - int(cfg["silencio_libre"]))))
	if silencio < int(cfg["silencio_max"]) and _m.rng.randf() >= p:
		return {}  # la mayoría de las semanas no pasa nada: se sale antes de preparar nada (pasada la espera máxima, el evento es seguro)
	_preparar_cooldowns(cfg, ahora)
	var quiere_decision := _m.rng.randf() < _prob_decision(cfg, ahora)
	var dec := ["alea_dec", "reg_dec", true]
	var sin := ["alea_sin", "reg_sin", false]
	var orden := [dec, sin] if quiere_decision else [sin, dec]  # si no hay del tipo pedido, se prueba el otro
	for par in orden:
		if par[2] and _cd_decision:
			continue  # una decisión reciente: ninguna decisión esta semana
		var evt := _sortear(grupo, par, cfg, ahora)
		if not evt.is_empty():
			return evt
	return {}


func _prob_decision(cfg: Dictionary, ahora: int) -> float:
	## Probabilidad de que el evento de la semana sea una decisión: sube a 1 bajo el mínimo anual (en gobierno) y cae a 0 sobre el máximo.
	var dec_anio := _decisiones_ultimo_anio(ahora)
	var p_dec := float(cfg["prob_decision"])
	if dec_anio < int(cfg["decisiones_min_anio"]):
		return 1.0 if m.estado.etapa == "gobierno" else p_dec
	if dec_anio >= int(cfg["decisiones_max_anio"]):
		return 0.0
	return p_dec


func _sortear(grupo: Dictionary, par: Array, cfg: Dictionary, ahora: int) -> Dictionary:
	## Sortea un evento del grupo `par` entre los candidatos fuera de cooldown y con requisitos cumplidos, ponderados por su peso efectivo.
	var oc: Dictionary = m.estado.eventos_ocurridos
	var cd_evento := int(cfg["cooldown_evento"])
	var cd_familia := int(cfg["cooldown_familia"])
	var pool: Array = grupo[par[0]]
	var rg: Dictionary = grupo[par[1]]
	var ids: PackedStringArray = rg["ids"]
	var fams: PackedStringArray = rg["fams"]
	var base: PackedFloat64Array = rg["pesos"]
	var flags: PackedInt32Array = rg["flags"]
	var cand: PackedInt32Array = []
	var pesos: PackedFloat64Array = []
	var total := 0.0
	var mes := 0  # se calcula solo si algún candidato depende de la estación
	for i in range(ids.size()):
		var id := ids[i]
		if oc.has(id) and ahora - int(oc[id]) < cd_evento:
			continue
		if _ult_fam.has(fams[i]) and ahora - int(_ult_fam[fams[i]]) < cd_familia:
			continue
		var f := flags[i]
		if f & 1 and not m.eventos._cumple_requisitos(pool[i]):
			continue
		var w := base[i]
		if f & 2:
			if mes == 0 and (pool[i] as Dictionary).has("meses"):
				mes = mes_actual()
			w = _peso_efectivo(pool[i], cfg, mes)
		cand.append(i)
		pesos.append(w)
		total += w
	if cand.is_empty() or total <= 0.0:
		return {}
	var r := m.rng.randf() * total
	for j in range(cand.size()):
		r -= pesos[j]
		if r <= 0.0:
			return pool[cand[j]]
	return pool[cand[cand.size() - 1]]


func registrar(evt: Dictionary, ahora: int) -> void:
	## Llamado por aplicar_evento: deja constancia de que el evento ocurrió esta semana.
	m.eventos._indice()
	_sincronizar()
	m.estado.eventos_ocurridos[String(evt["id"])] = ahora
	_n_visto = m.estado.eventos_ocurridos.size()
	_ultima = ahora
	_ult_fam[String(evt.get("familia", ""))] = ahora
	if evt.has("opciones"):
		_ult_dec = ahora
		if evt["tipo"] == "aleatorio_semilla":
			_dec_sem[String(evt["id"])] = ahora
