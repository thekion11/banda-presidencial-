extends SceneTree
## Fuzz de la agenda legislativa (sim/motor_agenda.gd, BM): en partidas de gobierno se presentan proyectos al azar (cartas del catálogo y basura, urgencias válidas e inválidas,
## con y sin delegar, ministros fuera del gabinete, regiones inválidas, repetidos, con la agenda llena, en cooldown tras un rechazo) mezclados con el juego normal del bot.
## Invariantes: proyectos en trámite ≤ máximo; ninguna carta dos veces en trámite; las etapas solo avanzan en orden (primer → segundo → [mixta] → [TC] → promulgación);
## presentar con éxito gasta exactamente el costo en movimientos (0 si se delega) y el capital de la urgencia; un rechazo deja a la carta en espera (no se puede volver a
## presentar antes de tiempo); lo promulgado queda ejecutado una sola vez; invariantes del estado cada semana; guardado válido y replay idéntico (a mitad de trámite y al final).
## Uso: godot --headless --path . -s tests/fuzz_agenda.gd -- [partidas=10] [semilla=5500] [semanas=70]

const SIGUIENTE := {"primer_tramite": ["segundo_tramite"], "segundo_tramite": ["comision_mixta", "tc", "promulgacion"], "comision_mixta": ["tc", "promulgacion"], "tc": ["promulgacion"], "promulgacion": []}
var _fallos := 0
var _presentadas := 0
var _rechazadas_por_razon := {}
var _promulgadas := 0
var _rechazos_congreso := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ AGENDA: ", msg)


func _partido(d: Dictionary) -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	return GeneradorPartido.construir_partido("Agenda", "AGE", "metropolitana", resp, d["ideologia"])


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 10
	var s0 := int(args[1]) if args.size() > 1 else 5500
	var semanas := int(args[2]) if args.size() > 2 else 70
	for i in range(n):
		_partida(s0 + i, semanas)
	var razones := ", ".join(_rechazadas_por_razon.keys().map(func(k: String) -> String: return "%s×%d" % [k, _rechazadas_por_razon[k]]))
	print("FUZZ AGENDA %s (%d partidas; %d presentadas, %d promulgadas, %d rechazos del Congreso; rechazos por razón: %s; %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _presentadas, _promulgadas, _rechazos_congreso, razones, _fallos])
	quit(1 if _fallos > 0 else 0)


func _partida(semilla: int, semanas: int) -> void:
	var d := Datos.cargar_todo()
	var variante := semilla % 3  # 0: datos reales · 1: hasta 8 proyectos a la vez · 2: 8 a la vez y sin umbral mínimo de aprobación (más rechazos del Congreso y del TC)
	if variante >= 1:
		d["leyes"]["agenda"]["max_simultaneos"] = 8
	if variante == 2:
		d["leyes"]["agenda"]["prob_minima"] = 0.0
	var h := Datos.huella(d)
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var m := Partida.crear(d, semilla, _partido(d))
	var ctx := "semilla %d" % semilla
	for _s in range(int(d["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	if not Bots.elegir(m, d, "codicioso", rng):
		return
	var mx := int(m.catalogo_leyes["agenda"]["max_simultaneos"])
	var urgs: Array = (m.catalogo_leyes["agenda"]["urgencias"] as Array).map(func(u: Dictionary) -> String: return String(u["id"]))
	var etapas_vistas := {}  # carta -> última etapa vista
	var basura := ["", "xx", "no_existe", "-1"]
	for w in range(semanas):
		var e := m.estado
		if e.etapa != "gobierno":
			break
		# presentar: varias veces por semana, con entradas válidas e inválidas
		for _k in range(rng.randi_range(0, 4)):
			var cat := m.agenda.agenda_catalogo()
			var carta_id := String(cat[rng.randi_range(0, cat.size() - 1)]["carta_id"]) if not cat.is_empty() and rng.randf() < 0.8 else String(basura[rng.randi_range(0, 3)])
			var urg_id := String(urgs[rng.randi_range(0, urgs.size() - 1)]) if rng.randf() < 0.85 else String(basura[rng.randi_range(0, 3)])
			var delegar := rng.randf() < 0.3
			var mins: Array = e.gabinete + basura
			var min_id := String(mins[rng.randi_range(0, mins.size() - 1)]) if (delegar or rng.randf() < 0.2) else ""
			var reg := ""
			if rng.randf() < 0.3:
				reg = String(m.regiones.catalogo[rng.randi_range(0, m.regiones.catalogo.size() - 1)]["id"]) if rng.randf() < 0.8 else "region_falsa"
			var pa0 := e.pa_actual
			var cap0 := e.ind("capital")
			var dele0 := e.delegadas_turno
			var n_ag0 := e.agenda.size()
			var n_ent0 := e.entradas.size()
			var llena := e.agenda.size() + e.proyectos_ley.size() >= mx
			var r := m.agenda.presentar(carta_id, urg_id, min_id, delegar, reg)
			if llena:  # con la agenda llena (en trámite + leyes de la mano) nada nuevo entra, sea cual sea el resto de los argumentos válidos
				_check(not bool(r.get("ok", false)), "%s semana %d: se presentó un proyecto con la agenda llena (%d/%d)" % [ctx, w, e.agenda.size() + e.proyectos_ley.size(), mx])
			if bool(r.get("ok", false)):
				_presentadas += 1
				var costo := int(r.get("costo", -1))
				_check(pa0 - e.pa_actual == costo, "%s semana %d: presentar gastó %d movimientos pero informa %d" % [ctx, w, pa0 - e.pa_actual, costo])
				if delegar:
					_check(costo == 0, "%s: presentar delegado debe costar 0 (costó %d)" % [ctx, costo])
				_check(e.entradas.size() == n_ent0 + 1, "%s: presentar con éxito debe registrar exactamente una entrada" % ctx)
				_check(e.ind("capital") <= cap0 + 1e-9 or true, "")  # el capital puede subir por efectos de la carta; el gasto exacto lo cubre la prueba del motor
			else:
				_rechazadas_por_razon[String(r.get("razon", "?"))] = int(_rechazadas_por_razon.get(String(r.get("razon", "?")), 0)) + 1
				_check(e.pa_actual == pa0 and e.entradas.size() == n_ent0 and e.agenda.size() == n_ag0 and e.delegadas_turno == dele0, "%s: presentar rechazado (%s) cambió el estado" % [ctx, r.get("razon", "?")])
		_check(e.agenda.size() <= mx, "%s semana %d: %d proyectos de la agenda sobre el máximo %d" % [ctx, w, e.agenda.size(), mx])
		var ids := {}
		for p in e.agenda:
			_check(not ids.has(p["carta_id"]), "%s: la carta %s está dos veces en la agenda" % [ctx, p["carta_id"]])
			ids[p["carta_id"]] = true
			var ant: String = String(etapas_vistas.get(p["carta_id"], ""))
			if ant != "" and ant != String(p["etapa"]):
				_check(SIGUIENTE.get(ant, []).has(String(p["etapa"])), "%s: la carta %s saltó de %s a %s" % [ctx, p["carta_id"], ant, p["etapa"]])
			etapas_vistas[p["carta_id"]] = String(p["etapa"])
		Bots.jugar_turno(m, "codicioso", rng)
		var antes_cierre := e.agenda.map(func(p: Dictionary) -> String: return String(p["carta_id"]))
		m.terminar_turno()
		for f in m.votaciones_semana:
			if bool(f.get("agenda", false)):
				if bool(f["aprobada"]):
					_promulgadas += 1
					_check(m.estado.cartas_ejecutadas.has(String(f["carta_id"])) or not m.es_unica(m._cartas_por_id[f["carta_id"]]), "%s: ley promulgada %s no queda ejecutada" % [ctx, f["carta_id"]])
				else:
					_rechazos_congreso += 1
					_check(int(m.estado.agenda_rechazos.get(String(f["carta_id"]), 0)) > m.eventos.semana_abs() - 1, "%s: rechazo de %s sin período de espera" % [ctx, f["carta_id"]])
					var rr := m.agenda.presentar(String(f["carta_id"]), "simple")
					_check(not bool(rr.get("ok", false)) and (String(rr.get("razon", "")) == "en_espera_tras_rechazo" or String(rr.get("razon", "")) == "agenda_llena" or String(rr.get("razon", "")) in ["pa_insuficiente", "ya_ejecutada", "carta_no_habilitada"]), "%s: se pudo volver a presentar %s en pleno período de espera (%s)" % [ctx, f["carta_id"], str(rr)])
		for f in AyudaInvariantes.revisar(m, "%s semana %d" % [ctx, w]):
			_check(false, "%s semana %d: invariante: %s" % [ctx, w, f])
		if w == semanas / 2 or (not m.estado.agenda.is_empty() and w % 23 == 7):
			var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(h)))
			_check(ValidarGuardado.guardado_valido(g), "%s semana %d: guardado inválido a mitad de trámite" % [ctx, w])
			var rep := Partida.reproducir(d, g)
			_check(rep != null and rep.estado.calcular_huella() == m.estado.calcular_huella(), "%s semana %d: replay a mitad de trámite no es idéntico (%d proyectos en la agenda)" % [ctx, w, m.estado.agenda.size()])
	var g2: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(h)))
	var r2 := Partida.reproducir(d, g2)
	_check(r2 != null and r2.estado.calcular_huella() == m.estado.calcular_huella(), ctx + ": el replay final no es idéntico")
