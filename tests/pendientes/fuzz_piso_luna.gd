extends SceneTree
## Fuzz del piso ideológico y la luna de miel (D-BN, sim/piso_ideologico.gd, sim/luna_de_miel.gd): 
## A) luna de miel: intensidad ((13−(s−1))/13)^exponente × mult_dificultad en cada semana y dificultad: 1·mult en la semana 1, (1/13)^exp·mult en la 13, 0 en la 14, siempre 0 fuera
##    de gobierno, monótona decreciente; vista() coherente.
## B) piso: en partidas completas (campaña → gobierno) con acciones del bot y golpes extremos a la aprobación (−1e9, regiones sueltas) la aprobación de cada región nunca
##    baja de su piso y la nacional nunca baja del piso nacional; el piso nacional ≤ tope_nacional < umbral_crisis; los pisos están en 0..tope_region.
## C) voto regional: voto de cada región ≥ su piso y voto_duro + voto_blando = voto; voto_duro_nacional ≤ voto nacional.
## D) determinismo: guardar a mitad de la luna de miel y reproducir da la misma huella (no hay estado nuevo).
## Uso: godot --headless --path . -s tests/fuzz_piso_luna.gd -- [partidas=8] [semilla=4400] [semanas=40]

var _fallos := 0
var _semanas_luna := 0
var _golpes := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ PISO/LUNA: ", msg)


func _partido(d: Dictionary, rng: RandomNumberGenerator, dif: String) -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][rng.randi_range(0, 2)])
	var base := GeneradorPartido.construir_partido("Piso", "PIS", "metropolitana", resp, d["ideologia"])
	base["dificultad"] = dif
	return base


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 8
	var s0 := int(args[1]) if args.size() > 1 else 4400
	var semanas := int(args[2]) if args.size() > 2 else 40
	var d := Datos.cargar_todo()
	_luna(d)
	_voto_y_reversion(d, RandomNumberGenerator.new(), s0)
	for i in range(n):
		_partida(d, s0 + i, ["facil", "normal", "dificil"][i % 3], semanas)
	print("FUZZ PISO/LUNA %s (%d partidas, %d semanas de luna de miel comprobadas, %d golpes extremos, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _semanas_luna, _golpes, _fallos])
	quit(1 if _fallos > 0 else 0)


func _luna(d: Dictionary) -> void:
	var m := AyudaV2.gobierno(d, 61)
	var leyes := m.catalogo_leyes
	var c: Dictionary = leyes["luna_de_miel"]
	var nsem := int(c["semanas"])
	for dif in ["facil", "normal", "dificil"]:
		m.estado.partido["dificultad"] = dif
		var mult := float(c["mult_dificultad"].get(dif, 1.0))
		var prev := 1e9
		for s in range(1, nsem + 6):
			m.estado.etapa = "gobierno"
			m.estado.turno_actual = s
			var i := LunaDeMiel.intensidad(m.estado, leyes)
			var esperado := 0.0 if s > nsem else pow(float(nsem - (s - 1)) / float(nsem), float(c["exponente"])) * mult
			_check(absf(i - esperado) < 1e-9, "luna %s semana %d: intensidad %.6f ≠ %.6f" % [dif, s, i, esperado])
			_check(i <= prev + 1e-12, "luna %s semana %d: la intensidad sube (%.4f → %.4f)" % [dif, s, prev, i])
			prev = i
			var v := LunaDeMiel.vista(m.estado, leyes)
			_check(bool(v["activa"]) == (s <= nsem) and bool(v["termina_ahora"]) == (s == nsem + 1) and int(v["semanas_restantes"]) == (nsem - s + 1 if s <= nsem else 0), "luna %s semana %d: vista incoherente %s" % [dif, s, str(v)])
		_check(is_equal_approx(LunaDeMiel.intensidad(_en(m, 1), leyes), mult), "luna %s: la semana 1 vale %.3f (mult)" % [dif, mult])
		_check(LunaDeMiel.intensidad(_en(m, nsem + 1), leyes) == 0.0, "luna %s: la semana %d vale 0" % [dif, nsem + 1])
		_check(LunaDeMiel.intensidad(_en(m, nsem), leyes) > 0.0, "luna %s: la semana %d aún es positiva" % [dif, nsem])
		for etapa in ["campana", "oposicion", "crisis", "fin_mandato", "derrota_electoral"]:
			m.estado.etapa = etapa
			m.estado.turno_actual = 1
			_check(LunaDeMiel.intensidad(m.estado, leyes) == 0.0, "luna %s: fuera de gobierno (%s) vale 0" % [dif, etapa])
	m.estado.etapa = "gobierno"


func _voto_y_reversion(d: Dictionary, rng: RandomNumberGenerator, semilla: int) -> void:
	## E) VotoRegional.calcular con pisos y aprobaciones/desplazamientos extremos; F) revertir_a_base y aplicar_delta nunca dejan una región bajo su piso.
	rng.seed = semilla
	var m := AyudaV2.gobierno(d, 62)
	m.estado.partido = _partido(d, rng, "normal")  # sin partido los pisos valen 0
	var pisos: Dictionary = m.piso.pisos()
	var positivos := 0
	for id in pisos.keys():
		positivos += 1 if float(pisos[id]) > 0.5 else 0
	_check(positivos > 3, "con partido hay pisos positivos (%d de %d)" % [positivos, pisos.size()])
	for k in range(200):
		var apr := {}
		for r in m.regiones.catalogo:
			apr[r["id"]] = rng.randf_range(0.0, 100.0) if rng.randf() < 0.8 else rng.randf_range(-100.0, 0.0)
		var desp := rng.randf_range(-100.0, 100.0)
		var det := VotoRegional.calcular(m.regiones, apr, desp, 0.0, 100.0, rng.randf_range(20.0, 80.0), rng.randf_range(0.0, 10.0), semilla + k, 1, 1, pisos)
		for f in det["regiones"]:
			var piso := minf(float(pisos.get(f["id"], 0.0)), 100.0)
			_check(float(f["voto"]) >= piso - 1e-9, "voto %s (%.2f) bajo su piso %.2f con desplazamiento %.1f" % [f["id"], float(f["voto"]), piso, desp])
			_check(absf(float(f["voto_duro"]) + float(f["voto_blando"]) - float(f["voto"])) < 1e-6 and float(f["voto_blando"]) >= -1e-9, "duro + blando ≠ voto en %s" % f["id"])
	for k in range(60):
		for r in m.regiones.catalogo:
			m.estado.aprobacion_regional[r["id"]] = rng.randf_range(0.0, 100.0)
			m.estado.aprobacion_base[r["id"]] = rng.randf_range(0.0, 100.0)
		if rng.randf() < 0.5:
			for r in m.regiones.catalogo:
				m.estado.aprobacion_base[r["id"]] = 0.0
		m.regiones.revertir_a_base(m.estado, rng.randf_range(0.0, 1.0))
		for r in m.regiones.catalogo:
			_check(float(m.estado.aprobacion_regional[r["id"]]) >= float(pisos.get(r["id"], 0.0)) - 1e-6, "revertir_a_base dejó %s (%.2f) bajo su piso %.2f" % [r["id"], float(m.estado.aprobacion_regional[r["id"]]), float(pisos.get(r["id"], 0.0))])
		m.regiones.aplicar_delta(m.estado, rng.randf_range(-100.0, 10.0), "" if rng.randf() < 0.5 else String(m.regiones.catalogo[rng.randi_range(0, m.regiones.catalogo.size() - 1)]["id"]), rng.randf_range(0.0, 1.0))
		for r in m.regiones.catalogo:
			_check(float(m.estado.aprobacion_regional[r["id"]]) >= float(pisos.get(r["id"], 0.0)) - 1e-6, "aplicar_delta dejó %s bajo su piso" % r["id"])


func _en(m: MotorTurno, semana: int) -> EstadoSimulacion:
	m.estado.etapa = "gobierno"
	m.estado.turno_actual = semana
	return m.estado


func _partida(d: Dictionary, semilla: int, dif: String, semanas: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var h := Datos.huella(d)
	var m := Partida.crear(d, semilla, _partido(d, rng, dif))
	var ctx := "semilla %d (%s)" % [semilla, dif]
	for _s in range(int(d["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
		_pisos(m, ctx + " campaña")
	if not Bots.elegir(m, d, "codicioso", rng):
		return
	# C) voto regional de la última elección: cada región ≥ su piso y duro + blando = voto
	var ue: Dictionary = m.estado.ultima_eleccion
	for f in ue.get("regiones", []):
		_check(float(f["voto"]) >= float(f.get("voto_duro", 0.0)) - 1e-9, "%s: el voto de %s (%.2f) bajó de su voto duro (%.2f)" % [ctx, f["id"], float(f["voto"]), float(f.get("voto_duro", 0.0))])
		_check(absf(float(f["voto_duro"]) + float(f["voto_blando"]) - float(f["voto"])) < 1e-6, "%s: duro + blando ≠ voto en %s" % [ctx, f["id"]])
	if ue.has("voto_duro_nacional"):
		_check(float(ue["voto_duro_nacional"]) <= float(ue["voto_nacional"]) + 1e-6, "%s: el voto duro nacional supera al voto nacional" % ctx)
	var pi: Dictionary = d["leyes"]["piso_ideologico"]
	var crisis := float(d["leyes"]["dinamica"]["umbral_crisis_aprobacion"])
	var nsem := int(d["leyes"]["luna_de_miel"]["semanas"])
	var golpeado := false  # los golpes tocan el estado a mano (no son entradas): después de uno el replay ya no puede coincidir
	for w in range(semanas):
		if m.estado.etapa != "gobierno":
			break
		if LunaDeMiel.intensidad(m.estado, m.catalogo_leyes) > 0.0:
			_semanas_luna += 1
		# golpe extremo a la aprobación (directo al estado: no es replayable, se hace después de comprobar el replay)
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
		_pisos(m, "%s semana %d" % [ctx, w])
		if m.estado.etapa == "gobierno" and w == nsem / 2 and not golpeado:  # guardar a mitad de la luna de miel: el replay coincide
			var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(h)))
			var rep := Partida.reproducir(d, g)
			_check(rep != null and rep.estado.calcular_huella() == m.estado.calcular_huella(), "%s semana %d: el replay a mitad de la luna de miel no es idéntico" % [ctx, w])
		if m.estado.etapa == "gobierno" and rng.randf() < 0.25:
			_golpes += 1
			golpeado = true
			var golpe: float = [-1.0e9, -50.0, -5.0][rng.randi_range(0, 2)]
			if rng.randf() < 0.5:
				m.regiones.aplicar_delta(m.estado, golpe, "", 0.0)
			else:
				m.fx.sumar_ind("aprobacion", golpe, "golpe extremo")
			_pisos(m, "%s semana %d tras golpe %.0f" % [ctx, w, golpe])
	# el piso nacional respeta sus topes
	var nac := m.piso.nacional()
	_check(nac <= float(pi["tope_nacional"]) + 1e-9 and float(pi["tope_nacional"]) < crisis, "%s: el piso nacional %.2f pasa del tope %.2f o el tope no es menor que el umbral de crisis %.2f" % [ctx, nac, float(pi["tope_nacional"]), crisis])


func _pisos(m: MotorTurno, ctx: String) -> void:
	var e := m.estado
	var piso: Dictionary = m.piso.pisos() if "piso" in m else {}
	if piso.is_empty():
		return
	var rg := m.regiones
	var nac_piso := 0.0
	for r in rg.catalogo:
		var id := String(r["id"])
		var p := float(piso.get(id, 0.0))
		nac_piso += p * float(rg.pesos[id])
		_check(p >= -1e-9 and p <= float(m.catalogo_leyes["piso_ideologico"]["tope_region"]) + 1e-9, "%s: piso de %s = %.2f fuera de 0..tope_region" % [ctx, id, p])
		_check(float(e.aprobacion_regional.get(id, 0.0)) >= p - 1e-6, "%s: la aprobación de %s (%.2f) bajó de su piso (%.2f)" % [ctx, id, float(e.aprobacion_regional.get(id, 0.0)), p])
	_check(e.ind("aprobacion") >= nac_piso - 1e-6, "%s: la aprobación nacional %.2f bajó del piso nacional %.2f" % [ctx, e.ind("aprobacion"), nac_piso])
