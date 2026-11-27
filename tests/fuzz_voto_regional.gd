extends SceneTree
## Fuzz de la elección con población (sim/voto_regional.gd, VotoRegional.calcular, y MotorMandato.resolver_eleccion):
## A) propiedades de VotoRegional con aprobaciones regionales extremas (−1e9…1e9), regiones ausentes, desplazamientos −300…300, topes y umbrales al azar:
##    voto por región dentro de los topes, voto nacional dentro de los topes e igual a Σ peso·voto, pesos que suman 1, «gana» ⇔ voto ≥ umbral, regiones_ganadas coherente,
##    habitantes y votos estimados coherentes, monotonía (más aprobación nunca baja el voto nacional ni las regiones ganadas) y determinismo.
## B) Elección real en campaña con aprobaciones regionales forzadas a valores extremos, 1ª y 2ª vuelta: filas por región, Σ peso·voto ≈ voto_final salvo topes
##    (y exacto cuando ninguna región toca un tope), replay idéntico de la partida (huella y salida de la elección).
## Uso: godot --headless --path . -s tests/fuzz_voto_regional.gd -- [casos_A=400] [partidas_B=24] [semilla=8800]

var _fallos := 0
var _datos: Dictionary


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ VOTO REGIONAL: ", msg)


func _extremo(rng: RandomNumberGenerator) -> float:
	match rng.randi_range(0, 5):
		0:
			return 0.0
		1:
			return 100.0
		2:
			return rng.randf_range(-1.0e9, 1.0e9)
		3:
			return rng.randf_range(-50.0, 150.0)
		_:
			return rng.randf_range(0.0, 100.0)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var na := int(args[0]) if args.size() > 0 else 400
	var nb := int(args[1]) if args.size() > 1 else 24
	var s0 := int(args[2]) if args.size() > 2 else 8800
	_datos = Datos.cargar_todo()
	var rng := RandomNumberGenerator.new()
	rng.seed = s0
	_parte_a(na, rng)
	_parte_b(nb, s0)
	print("FUZZ VOTO REGIONAL %s (%d casos A, %d partidas B, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", na, nb, _fallos])
	quit(1 if _fallos > 0 else 0)


func _parte_a(n: int, rng: RandomNumberGenerator) -> void:
	var m := AyudaV2.gobierno(_datos, 52, [])
	var reg: Regiones = m.regiones
	var suma_pesos := 0.0
	var total := 0.0
	for r in reg.catalogo:
		suma_pesos += float(reg.pesos[r["id"]])
		total += float(r["poblacion_miles"])
	_check(absf(suma_pesos - 1.0) < 1e-9, "los pesos suman %f" % suma_pesos)
	_borde(reg, rng)
	for i in range(n):
		var apr := {}
		for r in reg.catalogo:
			if rng.randf() < 0.9:  # a veces falta una región
				apr[r["id"]] = _extremo(rng)
		var desp := rng.randf_range(-300.0, 300.0) if rng.randf() < 0.8 else 0.0
		var lo := 0.0
		var hi := 100.0
		var umbral := rng.randf_range(0.0, 100.0)
		var det := VotoRegional.calcular(reg, apr, desp, lo, hi, umbral)
		var ctx := "caso %d" % i
		var nac := float(det["voto_nacional"])
		_check(is_finite(nac) and nac >= lo - 1e-9 and nac <= hi + 1e-9, "%s: voto nacional %.4f fuera de topes" % [ctx, nac])
		var sp := 0.0
		var gan := 0
		var hab := 0.0
		var vot := 0.0
		_check(det["regiones"].size() == reg.catalogo.size(), ctx + ": faltan filas de región")
		for f in det["regiones"]:
			var v := float(f["voto"])
			_check(v >= lo - 1e-9 and v <= hi + 1e-9 and is_finite(v), "%s: voto %s = %.3f fuera de topes" % [ctx, f["id"], v])
			_check(bool(f["gana_gobierno"]) == (v >= umbral), "%s: gana_gobierno incoherente en %s (voto %.3f, umbral %.3f)" % [ctx, f["id"], v, umbral])
			sp += float(f["peso"]) * v
			gan += 1 if bool(f["gana_gobierno"]) else 0
			hab += float(f["habitantes_miles"])
			vot += float(f["votos_estimados_miles"])
			_check(float(f["votos_estimados_miles"]) <= float(f["habitantes_miles"]) + 1e-6, "%s: más votos estimados que habitantes en %s" % [ctx, f["id"]])
		_check(absf(sp - nac) < 1e-6, "%s: Σ peso·voto %.6f ≠ voto nacional %.6f" % [ctx, sp, nac])
		_check(gan == int(det["regiones_ganadas"]), ctx + ": regiones_ganadas incoherente")
		_check(absf(hab - total) < 1e-6 and absf(float(det["total_habitantes_miles"]) - total) < 1e-6, ctx + ": total de habitantes incoherente")
		_check(absf(vot - float(det["votos_estimados_miles"])) < 1e-6, ctx + ": votos estimados incoherentes")
		# determinismo y monotonía
		var det2 := VotoRegional.calcular(reg, apr, desp, lo, hi, umbral)
		_check(JSON.stringify(det) == JSON.stringify(det2), ctx + ": no determinista")
		var mas := apr.duplicate()
		for k in mas.keys():
			mas[k] = float(mas[k]) + rng.randf_range(0.0, 30.0)
		var det3 := VotoRegional.calcular(reg, mas, desp, lo, hi, umbral)
		_check(float(det3["voto_nacional"]) >= nac - 1e-9 and int(det3["regiones_ganadas"]) >= gan, ctx + ": más aprobación bajó el voto nacional o las regiones ganadas")


func _borde(reg: Regiones, rng: RandomNumberGenerator) -> void:
	## Empate exacto: una región con voto == umbral gana (el umbral es inclusivo); con 0,001 menos no gana.
	for i in range(30):
		var umbral := float(rng.randi_range(5, 95))
		var apr := {}
		for r in reg.catalogo:
			apr[r["id"]] = 0.0
		var id := String(reg.catalogo[rng.randi_range(0, reg.catalogo.size() - 1)]["id"])
		apr[id] = umbral
		var det := VotoRegional.calcular(reg, apr, 0.0, 0.0, 100.0, umbral)
		var fila: Dictionary = det["regiones"].filter(func(f: Dictionary) -> bool: return f["id"] == id)[0]
		_check(bool(fila["gana_gobierno"]) and int(det["regiones_ganadas"]) >= 1, "borde: voto %.1f == umbral %.1f debe ganar" % [float(fila["voto"]), umbral])
		apr[id] = umbral - 0.001
		det = VotoRegional.calcular(reg, apr, 0.0, 0.0, 100.0, umbral)
		fila = det["regiones"].filter(func(f: Dictionary) -> bool: return f["id"] == id)[0]
		_check(not bool(fila["gana_gobierno"]), "borde: voto %.3f < umbral %.1f no debe ganar" % [float(fila["voto"]), umbral])


func _partido() -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in _datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	return GeneradorPartido.construir_partido("Voto", "VOT", "metropolitana", resp, _datos["ideologia"])


func _parte_b(n: int, s0: int) -> void:
	var h := Datos.huella(_datos)
	for i in range(n):
		var rng := RandomNumberGenerator.new()
		rng.seed = s0 + i
		var sd := s0 + 100 + i
		var m := Partida.crear(_datos, sd, _partido())
		var ctx := "partida %d (semilla %d)" % [i, sd]
		var toco_estado := false  # si se forzó el estado regional a mano, el replay (que parte de las entradas) ya no puede reproducirlo
		for _s in range(int(_datos["leyes"]["hemiciclo"]["semanas_campana"])):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		for ronda in range(2):
			if not m.estado.eleccion_pendiente(int(_datos["leyes"]["hemiciclo"]["semanas_campana"])):
				break
			var extremo := rng.randf() < 0.6
			toco_estado = toco_estado or extremo
			if extremo:  # aprobaciones regionales extremas (fuera de rango) justo antes de votar
				for id in m.estado.aprobacion_regional.keys():
					m.estado.aprobacion_regional[id] = _extremo(rng)
			var res := m.resolver_eleccion_presidencial()
			var det: Dictionary = m.estado.ultima_eleccion
			_check(bool(res.get("ok", false)), ctx + ": la elección no se resolvió")
			if det.is_empty():
				continue
			_check(det["regiones"].size() == m.regiones.catalogo.size(), "%s ronda %d: faltan filas" % [ctx, ronda + 1])
			var sp := 0.0
			var toca_tope := false
			for f in det["regiones"]:
				sp += float(f["peso"]) * float(f["voto"])
				toca_tope = toca_tope or float(f["voto"]) <= 0.0 + 1e-9 or float(f["voto"]) >= 100.0 - 1e-9
			var vf := float(det["voto_final"])
			if not toca_tope and not extremo:
				_check(absf(sp - vf) < 1e-6, "%s ronda %d: Σ peso·voto %.6f ≠ voto final %.6f sin topes" % [ctx, ronda + 1, sp, vf])
			_check(is_finite(vf) and vf >= 0.0 and vf <= 100.0, "%s ronda %d: voto final %.3f fuera de [0, 100]" % [ctx, ronda + 1, vf])
			_check(int(det["ronda"]) == ronda + 1, "%s: la ronda de la salida no coincide" % ctx)
			if not res.get("balotaje", false):
				if bool(res.get("electo", false)):
					m.iniciar_turno()
				break
			m.iniciar_turno()
			for _s in range(int(_datos["leyes"]["hemiciclo"]["semanas_balotaje"])):
				Bots.jugar_turno(m, "codicioso", rng)
				m.terminar_turno()
		# replay idéntico (la elección se reproduce desde las entradas, no desde la salida)
		if toco_estado:
			continue
		var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(h)))
		var rep := Partida.reproducir(_datos, g)
		_check(rep != null and rep.estado.calcular_huella() == m.estado.calcular_huella(), "%s: el replay no es idéntico (difiere en %s; etapa %s, ronda %d, entradas %d)" % [ctx, str(AyudaFuzz.diferencias(rep, m)) if rep != null else "rep nulo", m.estado.etapa, m.estado.ronda_electoral, m.estado.entradas.size()])
		_check(rep != null and JSON.stringify(rep.estado.ultima_eleccion) == JSON.stringify(m.estado.ultima_eleccion), ctx + ": la salida de la elección no se recalcula igual al reproducir")
