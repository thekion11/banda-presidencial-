extends SceneTree
## Fuzz de las balas de plata (sim/motor_balas.gd) y del presupuesto extra a ministerios (sim/motor_presupuesto.gd) con la API pública y argumentos válidos e inválidos
## (ids falsos, objetivos fuera de rango, ministerios vacíos, prioridades ajenas, niveles inexistentes), mezclados con el juego normal del bot y con variantes de datos
## copiadas (enfriamiento 0, usos desde el año 1, tope anual enorme). Invariantes: una bala jamás se usa dos veces en el mismo mandato y los usos ≤ usos_max y ≤ habilitados;
## un uso rechazado no cambia NADA (misma huella); capital y fiscal dentro de 0..100; el DFL nunca actúa sobre materias vedadas; presupuestos activos ≤ máximo, gasto anual
## ≤ tope; asignar nunca sube el fiscal; baul() y panel() nunca fallan; el guardado es válido y el replay (a mitad y al final) idéntico.
## Uso: godot --headless --path . -s tests/fuzz_balas_presupuesto.gd -- [partidas=9] [semilla=3700] [semanas=80]

var _fallos := 0
var _usos := 0
var _usos_malos := 0
var _asignaciones := 0
var _rechazos := {}


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ BALAS/PRESUPUESTO: ", msg)


func _partido(d: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][rng.randi_range(0, 2)])
	return GeneradorPartido.construir_partido("BP", "BPL", "metropolitana", resp, d["ideologia"])


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 9
	var s0 := int(args[1]) if args.size() > 1 else 3700
	var semanas := int(args[2]) if args.size() > 2 else 80
	for i in range(n):
		_partida(s0 + i, i % 3, semanas)
	var razones := ", ".join(_rechazos.keys().map(func(k: String) -> String: return "%s×%d" % [k, _rechazos[k]]))
	print("FUZZ BALAS/PRESUPUESTO %s (%d partidas; %d balas usadas (%d salieron mal), %d presupuestos asignados; rechazos: %s; %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _usos, _usos_malos, _asignaciones, razones, _fallos])
	quit(1 if _fallos > 0 else 0)


func _sumar(r: Dictionary) -> void:
	var k := String(r.get("razon", "?"))
	_rechazos[k] = int(_rechazos.get(k, 0)) + 1


func _partida(semilla: int, variante: int, semanas: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var d := Datos.cargar_todo()
	if variante >= 1:
		d["leyes"]["balas_plata"]["enfriamiento_semanas"] = 0
		d["leyes"]["balas_plata"]["anio_uso_extra"] = 1
		d["leyes"]["balas_plata"]["usos_iniciales"] = d["leyes"]["balas_plata"]["usos_max"]
		for b in d["leyes"]["balas_plata"]["catalogo"]:
			if String(b["accion"]) == "nada":
				b["requiere"] = []  # sin condiciones de disponibilidad: así se usan más y se prueba el resto de la mecánica
	if variante == 2:
		d["leyes"]["presupuesto_ministerial"]["tope_anual_fiscal"] = 1000.0
		d["leyes"]["presupuesto_ministerial"]["enfriamiento_semanas"] = 0
	var h := Datos.huella(d)
	var m := Partida.crear(d, semilla, _partido(d, rng))
	var ctx := "semilla %d v%d" % [semilla, variante]
	for _s in range(int(d["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	if not Bots.elegir(m, d, "codicioso", rng):
		return
	var ids_balas: Array = (m.catalogo_leyes["balas_plata"]["catalogo"] as Array).map(func(b: Dictionary) -> String: return String(b["id"]))
	var niveles: Array = m.catalogo_leyes["presupuesto_ministerial"]["niveles"].keys()
	var basura := ["", "xx", "no_existe", "-1"]
	for w in range(semanas):
		var e := m.estado
		if e.etapa != "gobierno":
			break
		# --- balas
		for _k in range(rng.randi_range(0, 2)):
			var id := String(ids_balas[rng.randi_range(0, ids_balas.size() - 1)]) if rng.randf() < 0.85 else String(basura[rng.randi_range(0, 3)])
			var objetivo := rng.randi_range(-3, 6) if rng.randf() < 0.7 else -1
			var reducida := rng.randf() < 0.5
			var hu0 := e.calcular_huella()
			var ya_usada := (e.balas.get("usadas", {}) as Dictionary).has(id) and int(e.balas["usadas"][id][0]) == e.ciclo
			var ant_usadas := (e.balas.get("usadas", {}) as Dictionary).size()
			var r := m.balas.usar(id, objetivo, reducida)
			if bool(r.get("ok", false)):
				_usos += 1
				_usos_malos += 1 if bool(r.get("salio_mal", false)) else 0
				_check(not ya_usada, "%s semana %d: se usó dos veces la bala %s en el mismo mandato" % [ctx, w, id])
				_check(m.balas._usadas_del_ciclo().size() <= int(m.catalogo_leyes["balas_plata"]["usos_max"]), "%s: más usos (%d) que usos_max" % [ctx, m.balas._usadas_del_ciclo().size()])
				_check(m.balas._usadas_del_ciclo().size() <= m.balas.usos_habilitados(), "%s semana %d: más usos que los habilitados" % [ctx, w])
			else:
				_sumar(r)
				_check(e.calcular_huella() == hu0, "%s semana %d: la bala %s rechazada (%s) cambió el estado" % [ctx, w, id, r.get("razon", "?")])
				if ya_usada and m.catalogo_leyes["balas_plata"]["catalogo"].any(func(b: Dictionary) -> bool: return String(b["id"]) == id):
					_check(String(r.get("razon", "")) in ["ya_usada", "solo_en_gobierno"], "%s: reusar %s dio «%s» y no «ya_usada»" % [ctx, id, r.get("razon", "?")])
		for def in m.catalogo_leyes["balas_plata"]["catalogo"]:
			for o in m.balas.objetivos(def):
				_check(not (def.get("tipos_vedados", []) as Array).has(String(o["tipo_ley"])), "%s: la bala %s ofrece como objetivo una materia vedada (%s)" % [ctx, def["id"], o["tipo_ley"]])
		var baul := m.balas.baul()  # nunca falla
		_check(baul["items"].size() == ids_balas.size() and int(baul["usos_restantes"]) >= 0, "%s: baul() incoherente" % ctx)
		# --- presupuesto
		for _k in range(rng.randi_range(0, 2)):
			var slots: Array = e.gabinete.map(func(i: String) -> String: return m.gabinete.slot_de(i))
			var slot := String(slots[rng.randi_range(0, slots.size() - 1)]) if rng.randf() < 0.85 and not slots.is_empty() else String(basura[rng.randi_range(0, 3)])
			var nivel := String(niveles[rng.randi_range(0, niveles.size() - 1)]) if rng.randf() < 0.9 else "xx"
			var prio: Array = []
			if rng.randf() < 0.5:
				var items: Array = m.presupuesto._sector(slot) if m.gabinete.de_ministerio(slot) != "" else []
				for it in items:
					if rng.randf() < 0.5 and prio.size() < 5:
						prio.append(String(it["carta_id"]))
				if rng.randf() < 0.15:
					prio.append("carta_ajena")
			var fis0 := e.ind("fiscal")
			var hu1 := e.calcular_huella()
			var activos0: int = (e.presupuesto.get("activos", {}) as Dictionary).size()
			var ra := m.presupuesto.asignar(slot, nivel, prio)
			if bool(ra.get("ok", false)):
				_asignaciones += 1
				_check(e.ind("fiscal") <= fis0 + 1e-9, "%s semana %d: asignar presupuesto SUBIÓ el fiscal (%.2f → %.2f)" % [ctx, w, fis0, e.ind("fiscal")])
				_check((e.presupuesto["activos"] as Dictionary).size() == activos0 + 1, "%s: asignar no dejó un activo más" % ctx)
			else:
				_sumar(ra)
				_check(e.calcular_huella() == hu1, "%s semana %d: asignar rechazado (%s) cambió el estado" % [ctx, w, ra.get("razon", "?")])
			if rng.randf() < 0.2:
				m.presupuesto.fijar_prioridades(slot, prio)
		var pa: Dictionary = m.presupuesto.panel()  # nunca falla
		_check((e.presupuesto.get("activos", {}) as Dictionary).size() <= int(m.catalogo_leyes["presupuesto_ministerial"]["max_simultaneos"]), "%s semana %d: más presupuestos activos que el máximo" % [ctx, w])
		_check(m.presupuesto.gastado_anio() <= float(m.catalogo_leyes["presupuesto_ministerial"]["tope_anual_fiscal"]) + 1e-9, "%s semana %d: gasto anual %.1f sobre el tope" % [ctx, w, m.presupuesto.gastado_anio()])
		_check(pa["ministerios"].size() == e.gabinete.size(), "%s: panel() sin una fila por ministro" % ctx)
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
		for ind in ["capital", "fiscal", "aprobacion", "cohesion", "riesgo_ejecucion"]:
			_check(e.ind(ind) >= -1e-9 and e.ind(ind) <= 100.0 + 1e-9, "%s semana %d: %s = %.3f fuera de 0..100" % [ctx, w, ind, e.ind(ind)])
		for f in AyudaInvariantes.revisar(m, "%s semana %d" % [ctx, w]):
			_check(false, "%s semana %d: invariante: %s" % [ctx, w, f])
		if w == semanas / 2:
			var g: Dictionary = JSON.parse_string(JSON.stringify(e.exportar_guardado(h)))
			_check(ValidarGuardado.guardado_valido(g), "%s semana %d: guardado inválido a mitad" % [ctx, w])
			var rep := Partida.reproducir(d, g)
			_check(rep != null and rep.estado.calcular_huella() == e.calcular_huella(), "%s semana %d: replay a mitad no idéntico (%d balas, %d presupuestos activos)" % [ctx, w, m.balas._usadas_del_ciclo().size(), (e.presupuesto.get("activos", {}) as Dictionary).size()])
	var g2: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(h)))
	var r2 := Partida.reproducir(d, g2)
	_check(r2 != null and r2.estado.calcular_huella() == m.estado.calcular_huella(), ctx + ": el replay final no es idéntico")
