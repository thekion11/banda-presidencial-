extends SceneTree
## Fuzz de las 16 cartas `plan_*` (Plan Estratégico, 27-nov-2026): en una copia de los datos (data/ está congelado: nunca se toca el original) se dejan
## las plan_* como únicas cartas de sus 6 categorías para que circulen a menudo, y cada partida usa una variante: 0 valores reales, 1 efectos extremos (±1e9),
## 2 riesgo seguro (prob 1) con efectos extremos, 3 diferido en 0, 1 o 5000 semanas con efectos extremos, 4 igual que 0 pero jugando siempre delegada, 5 costo 0/1/99, riesgo 0/1/2 y diferido −5/0/1/52 semanas.
## Cada semana de gobierno, toda plan_* en la mano se juega (normal, delegada o con región) o se intenta repetir (única ya ejecutada). Invariantes del estado
## (AyudaInvariantes) en cada semana, guardado válido y replay idéntico (huella) al final y a mitad de partida. Cuenta jugadas, votaciones, riesgos y diferidos.
## Uso: godot --headless --path . -s tests/fuzz_plan_cartas.gd -- [partidas=10] [semilla_inicial=6100] [semanas=70]

const CATS := ["hacienda", "economia", "energia", "obras", "medioambiente", "transportes"]
var _fallos := 0
var _jugadas := 0
var _delegadas := 0
var _votadas := 0
var _aprobadas := 0
var _malas := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ PLAN: ", msg)


func _extremo(efectos: Array, rng: RandomNumberGenerator) -> void:
	for e in efectos:
		var g := 1.0e9 if String(e["ind"]) != "viviendas_anio" else 1.0e9
		e["delta"] = [g, -g, 0.0][rng.randi_range(0, 2)]


func _variante(datos: Dictionary, v: int, rng: RandomNumberGenerator) -> void:
	var cartas: Array = datos["cartas"].filter(func(c: Dictionary) -> bool: return String(c["id"]).begins_with("plan_") or not CATS.has(String(c["categoria"])))
	datos["cartas"] = cartas
	for c in cartas:
		if not String(c["id"]).begins_with("plan_"):
			continue
		match v:
			1:
				_extremo(c["efectos"], rng)
			2:
				c["riesgo"]["prob"] = 1.0
				_extremo(c["riesgo"]["efectos"], rng)
				_extremo(c["efectos"], rng)
			3:
				c["diferido"]["semanas"] = [0, 1, 5000][rng.randi_range(0, 2)]
				_extremo(c["diferido"]["efectos"], rng)
			5:  # campos fuera de rango (los rechaza validate_data.py: aquí se comprueba que el motor no se caiga ni rompa invariantes)
				c["costo_pa"] = [0, 1, 99][rng.randi_range(0, 2)]
				c["riesgo"]["prob"] = [0.0, 1.0, 2.0][rng.randi_range(0, 2)]
				c["diferido"]["semanas"] = [-5, 0, 1, 52][rng.randi_range(0, 3)]


func _partido(datos: Dictionary) -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	return GeneradorPartido.construir_partido("Plan", "PLN", "metropolitana", resp, datos["ideologia"])


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 10
	var s0 := int(args[1]) if args.size() > 1 else 6100
	var semanas := int(args[2]) if args.size() > 2 else 70
	for i in range(n):
		_partida(s0 + i, i % 6, semanas)
	print("FUZZ PLAN %s (%d partidas; %d plan_* jugadas, %d delegadas, %d votadas, %d aprobadas, %d salieron mal; %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _jugadas, _delegadas, _votadas, _aprobadas, _malas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _partida(semilla: int, variante: int, semanas: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var datos := Datos.cargar_todo()
	_variante(datos, variante, rng)
	var ctx := "semilla %d variante %d" % [semilla, variante]
	var m := Partida.crear(datos, semilla, _partido(datos))
	for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	if not Bots.elegir(m, datos, "codicioso", rng):
		return
	var h := Datos.huella(datos)
	var mitad: Dictionary = {}
	for w in range(semanas):
		if not MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa):
			break
		for i in range(m.estado.mano.size() - 1, -1, -1):
			if i >= m.estado.mano.size() or not String(m.estado.mano[i]["id"]).begins_with("plan_"):
				continue
			var r: Dictionary
			if variante == 4 or rng.randf() < 0.35:
				var mins: Array = m.estado.gabinete
				r = m.delegar_carta(i, String(mins[rng.randi_range(0, mins.size() - 1)]) if not mins.is_empty() else "", "")
				_delegadas += 1 if bool(r.get("ok", false)) else 0
			else:
				r = m.jugar_carta(i, "", "" if rng.randf() < 0.7 else String(m.regiones.catalogo[rng.randi_range(0, m.regiones.catalogo.size() - 1)]["id"]))
			if bool(r.get("ok", false)):
				_jugadas += 1
				_malas += 1 if bool(r.get("salio_mal", false)) else 0
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
		for f in AyudaInvariantes.revisar(m, "%s semana %d" % [ctx, w]):
			_check(false, "%s semana %d: invariante: %s" % [ctx, w, f])
		if w == semanas / 2:
			mitad = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(h)))
			var rep := Partida.reproducir(datos, mitad)
			_check(rep != null and rep.estado.calcular_huella() == m.estado.calcular_huella(), "%s: replay a mitad de partida no es idéntico" % ctx)
	for a in m.estado.registro_acciones:
		if a["tipo"] == "votacion" and String(a["detalle"].get("carta", "")).begins_with("plan_"):
			_votadas += 1
			_aprobadas += 1 if bool(a["detalle"].get("aprobada", false)) else 0
	var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(h)))
	_check(ValidarGuardado.guardado_valido(g), ctx + ": el guardado final no es válido")
	var r2 := Partida.reproducir(datos, g)
	_check(r2 != null and r2.estado.calcular_huella() == m.estado.calcular_huella(), "%s: el replay final no es idéntico" % ctx)
