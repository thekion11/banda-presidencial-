extends SceneTree
## Fuzzing del núcleo: acciones aleatorias (incluidas inválidas) sobre muchas semillas.
## Comprueba invariantes (indicadores finitos y acotados, PA >= 0, mano de 5) y que el guardado se reproduce idéntico.
## Uso: godot --headless --path . -s tests/fuzz_acciones.gd -- [partidas] [semilla_inicial]

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO FUZZ: ", msg)


func _invariantes(m: MotorTurno, ctx: String) -> void:
	var e := m.estado
	for k in e.indicadores:
		var v := float(e.indicadores[k])
		_check(is_finite(v), "%s: indicador %s no finito (%s)" % [ctx, k, v])
		if k != "viviendas_anio":
			_check(v >= -0.001 and v <= 100.001, "%s: indicador %s fuera de 0..100 (%s)" % [ctx, k, v])
	_check(e.pa_actual >= 0, "%s: PA negativos (%d)" % [ctx, e.pa_actual])
	var ingreso_max: int = e.pa_maximo + int(e.bono_mov.get("aprobacion", 0)) + int(e.bono_mov.get("asesores", 0))
	_check(e.pa_actual <= maxi(int(m.catalogo_leyes["mano"]["tope_ahorro"]), ingreso_max), "%s: movimientos %d sobre el tope de ahorro (BL)" % [ctx, e.pa_actual])
	_check(e.agenda.size() <= int(m.catalogo_leyes["agenda"]["max_simultaneos"]), "%s: más proyectos en la agenda (%d) que el máximo" % [ctx, e.agenda.size()])
	for p in e.agenda:
		_check(["primer_tramite", "segundo_tramite", "comision_mixta", "tc", "promulgacion"].has(String(p["etapa"])) and int(p["dia_etapa_fin"]) >= int(p["dia_ingreso"]), "%s: proyecto de la agenda con etapa o plazo inválido" % ctx)
	_check(e.delegadas_turno >= 0 and e.internos_actual >= 0, "%s: contadores negativos" % ctx)
	for r in e.aprobacion_regional:
		var v := float(e.aprobacion_regional[r])
		_check(is_finite(v) and v >= -0.001 and v <= 100.001, "%s: aprobación regional %s=%s" % [ctx, r, v])
	if e.etapa == "gobierno" or e.etapa == "campana":
		_check(e.mano.size() <= 5, "%s: mano de %d cartas" % [ctx, e.mano.size()])


func _accion_aleatoria(m: MotorTurno, rng: RandomNumberGenerator, datos: Dictionary) -> void:
	var e := m.estado
	var basura := ["", "xx", "no_existe", "-1", " "]
	match rng.randi_range(0, 16):
		0, 1, 2:
			m.jugar_carta(rng.randi_range(-2, 7), "", "")
		3:
			var reg := ""
			if not m.regiones.catalogo.is_empty() and rng.randf() < 0.7:
				reg = String(m.regiones.catalogo[rng.randi_range(0, m.regiones.catalogo.size() - 1)]["id"])
			m.jugar_carta(rng.randi_range(0, 4), "", reg)
		4:
			var mins: Array = e.gabinete if not e.gabinete.is_empty() and rng.randf() < 0.8 else basura
			m.delegar_carta(rng.randi_range(-1, 6), String(mins[rng.randi_range(0, mins.size() - 1)]))
		5:
			var metas := m.movimientos.metas_disponibles()
			if not metas.is_empty() and rng.randf() < 0.7:
				m.buscar_meta(String(metas[rng.randi_range(0, metas.size() - 1)]["id"]))
			else:
				m.buscar_meta(basura[rng.randi_range(0, 4)])
		6:
			var sectores: Array = e.indices_sector.keys() + basura
			m.ajustar_sector(String(sectores[rng.randi_range(0, sectores.size() - 1)]), rng.randi_range(-2, 2))
		7:
			m.reducir_errores()
		8:
			m.acelerar_proyecto(rng.randi_range(-1, 4))
		9:
			var ids: Array = m.equipo.asesores.keys() + basura
			var id := String(ids[rng.randi_range(0, ids.size() - 1)])
			if rng.randf() < 0.5:
				m.contratar_asesor(id)
			else:
				m.despedir_asesor(id)
		10:
			var ids: Array = m.coalicion.partidos.keys() + basura
			var id := String(ids[rng.randi_range(0, ids.size() - 1)])
			if rng.randf() < 0.6:
				m.unirse_coalicion(id)
			else:
				m.salir_coalicion(id)
		11:
			var ids: Array = m.coalicion.partidos.keys() + basura
			var id := String(ids[rng.randi_range(0, ids.size() - 1)])
			var tipos := ["ministro", "asesor", "xx"]
			var vals: Array = e.gabinete + basura
			var t := String(tipos[rng.randi_range(0, 2)])
			var v := String(vals[rng.randi_range(0, vals.size() - 1)])
			if rng.randf() < 0.5:
				m.asignar_cuota(id, t, v)
			else:
				m.quitar_cuota(id, t, v)
		12:
			if not e.propuestas_abiertas.is_empty():
				var vs := ["A", "B", "C", "Z"]
				m.aprobar_propuesta(String(e.propuestas_abiertas[0]), String(vs[rng.randi_range(0, 3)]))
			else:
				m.aprobar_propuesta("no_existe", "A")
		13:
			m.impulsar_proyecto(String(basura[rng.randi_range(0, 4)]))
		14:  # agenda legislativa (BM): presentar leyes del catálogo o basura, con cualquier urgencia, ministro y delegación
			var cat: Array = m.agenda.agenda_catalogo() if rng.randf() < 0.8 else []
			var cid := String(cat[rng.randi_range(0, cat.size() - 1)]["carta_id"]) if not cat.is_empty() else String(basura[rng.randi_range(0, 4)])
			var urgs := ["simple", "suma", "inmediata", "xx"]
			var mins2: Array = e.gabinete + basura
			m.agenda.presentar(cid, String(urgs[rng.randi_range(0, 3)]), String(mins2[rng.randi_range(0, mins2.size() - 1)]) if rng.randf() < 0.4 else "", rng.randf() < 0.3)
		16:  # presupuesto extra a ministerios (PR-18 mínimo): ministerios válidos y basura, niveles y prioridades inválidos
			var panel: Dictionary = m.presupuesto.panel() if rng.randf() < 0.7 else {"ministerios": []}
			var filas: Array = panel["ministerios"]
			var slot2 := String(filas[rng.randi_range(0, filas.size() - 1)]["slot"]) if not filas.is_empty() else String(basura[rng.randi_range(0, 4)])
			var niveles := ["pequeno", "medio", "grande", "xx", ""]
			var prios: Array = []
			if not filas.is_empty() and rng.randf() < 0.5:
				for c in (filas[rng.randi_range(0, filas.size() - 1)]["candidatos"] as Array).slice(0, rng.randi_range(0, 4)):
					prios.append(String(c["carta_id"]))
			if rng.randf() < 0.75:
				m.presupuesto.asignar(slot2, String(niveles[rng.randi_range(0, 4)]), prios)
			else:
				m.presupuesto.fijar_prioridades(slot2, prios)
		15:  # balas de plata (PR-17): ids válidos y basura, objetivos fuera de rango, versión reducida al azar
			var cat: Array = m.catalogo_leyes["balas_plata"]["catalogo"]
			var bid := String(cat[rng.randi_range(0, cat.size() - 1)]["id"]) if rng.randf() < 0.85 else String(basura[rng.randi_range(0, 4)])
			m.balas.usar(bid, rng.randi_range(-3, 4), rng.randf() < 0.5)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 20
	var s0 := int(args[1]) if args.size() > 1 else 1000
	var datos := Datos.cargar_todo()
	var h := Datos.huella(datos)
	var presentadas := 0  # entradas «presentar» aceptadas por el motor: prueba de que la acción 14 (agenda) sí se ejercita
	for i in range(n):
		var semilla := s0 + i
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla * 17 + 3
		var resp: Array[Dictionary] = []
		for p in datos["ideologia"]["preguntas"]:
			resp.append(p["opciones"][rng.randi_range(0, 2)])
		var partido := GeneradorPartido.construir_partido("P", "P", "metropolitana", resp, datos["ideologia"])
		var m := Partida.crear(datos, semilla, partido)
		var ctx := "semilla %d" % semilla
		if rng.randf() < 0.5:
			m.elegir_gabinete(AyudaV2.ministros_de(datos, ["salud", "transportes", "vivienda"], int(datos["leyes"]["gabinete"]["tamano"])))
		var guard := 0
		while (m.estado.etapa == "campana" or m.estado.etapa == "gobierno") and guard < 400:
			guard += 1
			for _a in range(rng.randi_range(0, 14)):
				_accion_aleatoria(m, rng, datos)
				_invariantes(m, ctx)
			if m.estado.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
				m.resolver_eleccion_presidencial()
				if m.estado.etapa == "campana" or m.estado.etapa == "gobierno":
					m.iniciar_turno()
				_invariantes(m, ctx + " tras elección")
				continue
			m.terminar_turno()
			_invariantes(m, ctx + " t%d" % m.estado.turno_actual)
		_check(guard < 400, ctx + ": la partida no termina (bucle)")
		presentadas += m.estado.entradas.filter(func(x: Dictionary) -> bool: return x["tipo"] == "presentar").size()
		var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(h)))
		var r := Partida.reproducir(datos, g)
		_check(r.estado.calcular_huella() == m.estado.calcular_huella(), ctx + ": el replay NO es idéntico (etapa %s, turno %d)" % [m.estado.etapa, m.estado.turno_actual])
	_check(n < 20 or presentadas >= n, "la agenda legislativa no se ejercitó: %d presentaciones aceptadas en %d partidas (¿error de script en la acción 14?)" % [presentadas, n])
	print("FUZZ presentaciones de la agenda aceptadas: %d" % presentadas)
	print("FUZZ %s (%d partidas, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _fallos])
	quit(1 if _fallos > 0 else 0)
