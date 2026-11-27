extends SceneTree
## Ruido regional de la elección presidencial (sim/voto_regional.gd + resolver_eleccion en sim/motor_mandato.gd) con la fila `campana.ruido_eleccion_regional` en una COPIA de los
## datos (0, ausente, 3, 6 y 15; data/ no se toca). Propiedades por semilla: el ruido no consume el RNG de la partida (mismo estado del RNG tras la elección con cualquier r); r = 0
## y fila ausente dan el mismo resultado bit a bit; con r > 0 el voto final es la suma ponderada por población del detalle, |ruido regional| ≤ r y el voto de cada región queda
## dentro de los topes; la misma semilla y r repiten el resultado; el guardado reproduce la misma elección (huella) también tras la segunda vuelta; la elección no cambia nada
## antes de que termine la campaña.
## Uso: godot --headless --path . -s tests/fuzz_ruido_eleccion.gd -- [semillas=12] [semilla0=6600]

var _fallos := 0
var _casos := 0
var _cambian_resultado := 0
var _balotajes := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO RUIDO ELECCION: ", msg)


func _datos(r: Variant) -> Dictionary:
	var d := Datos.cargar_todo()
	if r == null:
		d["leyes"]["campana"].erase("ruido_eleccion_regional")
	else:
		d["leyes"]["campana"]["ruido_eleccion_regional"] = float(r)
	return d


func _correr(d: Dictionary, semilla: int, empuje: float = 0.0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][rng.randi_range(0, 2)])
	var m := Partida.crear(d, semilla, GeneradorPartido.construir_partido("RE", "RER", "metropolitana", resp, d["ideologia"]))
	var antes := m.resolver_eleccion_presidencial()  # a mitad de campaña no debe hacer nada
	_check(not bool(antes.get("electo", false)) and not bool(antes.get("balotaje", false)), "semilla %d: la elección resolvió antes de terminar la campaña" % semilla)
	for _s in range(int(d["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	if empuje != 0.0:
		m.estado.indicadores["aprobacion"] = clampf(m.estado.ind("aprobacion") + empuje, 5.0, 95.0)  # edición a mano: la aprobación nacional se aparta del promedio regional
	var hu_pre := m.estado.calcular_huella()
	var ronda_antes := m.estado.ronda_electoral
	var ciclo_antes := m.estado.ciclo
	var res := m.resolver_eleccion_presidencial()
	return {"ronda": ronda_antes, "ciclo": ciclo_antes, "m": m, "res": res, "rng_state": m.rng.state, "pre": hu_pre, "eleccion": m.estado.ultima_eleccion.duplicate(true)}


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var n := int(a[0]) if a.size() > 0 else 12
	var s0 := int(a[1]) if a.size() > 1 else 6600
	for i in range(n):
		var semilla := s0 + i
		var base := _correr(_datos(null), semilla)
		var cero := _correr(_datos(0.0), semilla)
		_check(JSON.stringify(base["eleccion"]) == JSON.stringify(cero["eleccion"]) and JSON.stringify(base["res"]) == JSON.stringify(cero["res"]), "semilla %d: r = 0 y fila ausente dan resultados distintos" % semilla)
		for emp in [8.0, -8.0]:  # la aprobación nacional se aparta del promedio regional: el desglose por región debe seguir sumando el voto final (ajuste nacional)
			var xe := _correr(_datos(0.0), semilla, emp)
			var det_e: Dictionary = xe["eleccion"]
			var ctx_e := "semilla %d aprobación %+.0f" % [semilla, emp]
			if det_e.has("regiones"):
				var libre := true
				var spe := 0.0
				for f in det_e["regiones"]:
					spe += float(f["peso"]) * float(f["voto"])
					libre = libre and float(f["voto"]) > 0.0 and float(f["voto"]) < 100.0
				if libre:
					_check(absf(spe - float(det_e["voto_final"])) < 0.05, "%s: Σ peso·voto %.3f no coincide con el voto final %.3f (ajuste nacional)" % [ctx_e, spe, float(det_e["voto_final"])])
		for r in [3.0, 6.0, 15.0]:
			var d := _datos(r)
			var x := _correr(d, semilla)
			var ctx := "semilla %d r=%.0f" % [semilla, r]
			_casos += 1
			_check(x["pre"] == base["pre"], ctx + ": el ruido regional cambió el estado ANTES de la elección")
			_check(x["rng_state"] == base["rng_state"], ctx + ": el ruido regional consumió el RNG de la partida")
			var det: Dictionary = x["eleccion"]
			if det.has("regiones"):
				var lim: Dictionary = d["leyes"]["limites_indicadores"]
				var sp := 0.0
				var movidas := 0
				for f in det["regiones"]:
					_check(absf(float(f["ruido"])) <= r + 1e-9, "%s: |ruido| %.3f > r en %s" % [ctx, absf(float(f["ruido"])), f["id"]])
					_check(float(f["voto"]) >= float(lim["min"]) - 1e-9 and float(f["voto"]) <= float(lim["max"]) + 1e-9, "%s: voto de %s fuera de topes" % [ctx, f["id"]])
					var r_cfg := float(d["leyes"]["campana"]["ruido_eleccion_regional"])
					_check(absf(float(f["ruido"]) - VotoRegional.ruido(semilla, int(x["ciclo"]), int(x["ronda"]), String(f["id"]), r_cfg)) < 1e-12, "%s: el ruido de %s no es el de (semilla, ciclo %d, vuelta %d, región)" % [ctx, f["id"], int(x["ciclo"]), int(x["ronda"])])
					var v0 := -1.0
					for f0 in base["eleccion"]["regiones"]:
						if f0["id"] == f["id"]:
							v0 = float(f0["voto"])
					if v0 > float(lim["min"]) + 1e-9 and v0 < float(lim["max"]) - 1e-9:
						_check(absf(float(f["voto"]) - clampf(v0 + float(f["ruido"]), float(lim["min"]), float(lim["max"]))) < 1e-9, "%s: el voto de %s no es el de r = 0 más su ruido" % [ctx, f["id"]])
					sp += float(f["peso"]) * float(f["voto"])
					movidas += 1 if absf(float(f["ruido"])) > 1e-9 else 0
				_check(movidas >= int((det["regiones"] as Array).size()) / 2, "%s: casi ninguna región recibió ruido (%d)" % [ctx, movidas])
				_check(absf(float(det["voto_final"]) - clampf(sp, float(lim["min"]), float(lim["max"]))) < 1e-6, "%s: voto final %.4f ≠ suma ponderada %.4f" % [ctx, float(det["voto_final"]), sp])
			else:
				_check(false, ctx + ": la elección no dejó detalle por región")
			if bool(x["res"].get("electo", false)) != bool(base["res"].get("electo", false)):
				_cambian_resultado += 1
			var y := _correr(d, semilla)
			_check(JSON.stringify(x["eleccion"]) == JSON.stringify(y["eleccion"]) and JSON.stringify(x["res"]) == JSON.stringify(y["res"]), ctx + ": la misma semilla da otra elección")
			# el guardado reproduce la misma elección, y la segunda vuelta si la hay
			var m: MotorTurno = x["m"]
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = semilla + 99
			var fin := bool(x["res"].get("electo", false))
			if bool(x["res"].get("balotaje", false)):
				m.iniciar_turno()
				for _s in range(int(d["leyes"]["hemiciclo"]["semanas_balotaje"])):
					Bots.jugar_turno(m, "codicioso", rng2)
					m.terminar_turno()
				var ronda2 := m.estado.ronda_electoral
				var ciclo2 := m.estado.ciclo
				fin = bool(m.resolver_eleccion_presidencial().get("electo", false))
				_balotajes += 1
				_check(ronda2 == 2, ctx + ": la segunda vuelta no está en la ronda 2 (%d)" % ronda2)
				for f2 in m.estado.ultima_eleccion.get("regiones", []):
					_check(absf(float(f2["ruido"]) - VotoRegional.ruido(semilla, ciclo2, ronda2, String(f2["id"]), r)) < 1e-12, "%s: el ruido de la 2ª vuelta en %s no usa la ronda 2" % [ctx, f2["id"]])
			if fin:
				m.iniciar_turno()  # como Bots.elegir: sin esto el replay no coincide (el turno 1 de gobierno se abre aparte)
			var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(Datos.huella(d))))
			_check(ValidarGuardado.guardado_valido(g), ctx + ": guardado inválido tras la elección")
			var rep := Partida.reproducir(d, g)
			_check(rep != null and rep.estado.calcular_huella() == m.estado.calcular_huella(), ctx + ": el replay tras la elección (fin=%s) no es idéntico" % str(fin))
	print("FUZZ RUIDO ELECCION %s (%d casos, %d segundas vueltas; el ruido cambió el ganador en %d; %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", _casos, _balotajes, _cambian_resultado, _fallos])
	quit(1 if _fallos > 0 else 0)
