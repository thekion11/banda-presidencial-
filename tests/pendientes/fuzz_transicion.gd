extends SceneTree
## Fuzz de la transición presidencial (MotorGabinete.pendiente_confirmar, PR #12): recién ganada la elección el gabinete está «por confirmar» hasta que se nombra uno
## (también el preseleccionado). En partidas ganadas por el bot se aplican, antes de confirmar, acciones en orden aleatorio: nombramientos INVÁLIDOS (vacío, repetidos, ids falsos,
## dos ministros del mismo cargo, de más), rellenos parciales, jugar cartas, guardar y reproducir, instantánea y restauración. Invariantes: un nombramiento inválido no cambia nada
## (misma huella) y la transición sigue pendiente; uno válido (25 únicos, uno por cargo) la cierra y deja exactamente 25 en el estado; el estado «pendiente» sobrevive al
## replay y a la instantánea; terminar la semana sin confirmar cierra la transición sola (turno 2) y nunca vuelve; en campaña, en el turno 2+ y fuera de gobierno no hay
## transición; tras la reelección (nuevo gobierno) la transición vuelve a abrirse.
## Uso: godot --headless --path . -s tests/fuzz_transicion.gd -- [partidas=12] [semilla=1800]

var _fallos := 0
var _ganadas := 0
var _invalidos := 0
var _validos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		_fallos += 1
		if _fallos <= 25:
			print("FALLO FUZZ TRANSICION: ", msg)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 12
	var s0 := int(args[1]) if args.size() > 1 else 1800
	var d := Datos.cargar_todo()
	for i in range(n):
		_partida(d, s0 + i)
	print("FUZZ TRANSICION %s (%d partidas, %d ganadas, %d nombramientos inválidos rechazados, %d válidos, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", n, _ganadas, _invalidos, _validos, _fallos])
	quit(1 if _fallos > 0 else 0)


func _partido(d: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var resp: Array[Dictionary] = []
	for p in d["ideologia"]["preguntas"]:
		resp.append(p["opciones"][rng.randi_range(0, 2)])
	return GeneradorPartido.construir_partido("Trans", "TRA", "metropolitana", resp, d["ideologia"])


func _partida(d: Dictionary, semilla: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var h := Datos.huella(d)
	var m := Partida.crear(d, semilla, _partido(d, rng))
	var ctx := "semilla %d" % semilla
	_check(not m.gabinete.pendiente_confirmar(), ctx + ": en campaña no hay transición")
	for _s in range(int(d["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
		_check(not m.gabinete.pendiente_confirmar(), ctx + ": durante la campaña no hay transición")
	if not Bots.elegir(m, d, "codicioso", rng):
		return
	_ganadas += 1
	var e := m.estado
	_check(e.etapa == "gobierno" and e.turno_actual == 1 and m.gabinete.pendiente_confirmar(), ctx + ": recién ganada la elección la transición está pendiente")
	var ids: Array = m.catalogo_ministros.keys()
	var por_cargo := {}
	for id in ids:
		var s := m.gabinete.slot_de(String(id))
		if not por_cargo.has(s):
			por_cargo[s] = []
		por_cargo[s].append(String(id))
	var confirmado := false
	for k in range(rng.randi_range(4, 12)):
		var op := rng.randi_range(0, 6)
		var hu0 := e.calcular_huella()
		var n_ent0 := e.entradas.size()
		match op:
			0, 1:  # nombramiento inválido
				var malo: Array = []
				match rng.randi_range(0, 5):
					0:
						malo = []
					1:
						malo = e.gabinete.duplicate()
						malo.append(String(malo[0]))  # repetido
					2:
						malo = e.gabinete.duplicate()
						malo[rng.randi_range(0, malo.size() - 1)] = "ministro_falso"
					3:
						malo = e.gabinete.duplicate()
						var otro: Array = por_cargo[m.gabinete.slot_de(String(malo[0]))]  # dos candidatos del mismo cargo
						for c in otro:
							if not malo.has(c):
								malo.append(c)
								break
					4:
						malo = e.gabinete.slice(0, 10)  # incompleto
					5:
						malo = e.gabinete.duplicate()
						malo.append_array(ids.slice(0, 5))  # de más
				var r := m.elegir_gabinete(malo)
				if bool(r.get("ok", false)):
					# algunos «inválidos» pueden ser válidos (p. ej. incompleto que el motor rellena): entonces la transición se cierra
					confirmado = true
					_validos += 1
				else:
					_invalidos += 1
					_check(e.calcular_huella() == hu0 and e.entradas.size() == n_ent0, "%s: un nombramiento inválido cambió el estado (%s)" % [ctx, str(r.get("razon", "?"))])
					_check(m.gabinete.pendiente_confirmar() == (not confirmado), "%s: un nombramiento inválido alteró la transición (pendiente=%s, confirmado=%s)" % [ctx, str(m.gabinete.pendiente_confirmar()), str(confirmado)])
			2:  # relleno parcial (no cambia el estado: solo propone)
				var parcial: Array = e.gabinete.slice(0, rng.randi_range(0, 25))
				m.gabinete.rellenar(parcial, ["eficaz", "equilibrado", ""][rng.randi_range(0, 2)])
				_check(e.calcular_huella() == hu0, ctx + ": rellenar cambió el estado (debe ser solo una propuesta)")
			3:  # jugar cartas antes de confirmar (el motor no lo impide; la interfaz sí)
				m.jugar_carta(rng.randi_range(0, 4))
			4:  # guardar y reproducir: el estado «pendiente» sobrevive
				var g: Dictionary = JSON.parse_string(JSON.stringify(e.exportar_guardado(h)))
				var rep := Partida.reproducir(d, g)
				_check(rep != null and rep.gabinete.pendiente_confirmar() == m.gabinete.pendiente_confirmar() and rep.estado.calcular_huella() == e.calcular_huella(), "%s: el replay no conserva la transición (%s)" % [ctx, str(m.gabinete.pendiente_confirmar())])
			5:  # instantánea y restauración
				var sha := "x"
				var bytes := Instantanea.tomar(m, h, sha)
				var snap := Instantanea.leer(bytes)
				if Instantanea.vale_para(snap, h, sha):
					var g2: Dictionary = JSON.parse_string(JSON.stringify(e.exportar_guardado(h)))
					var rest := Partida.cargar(d, g2, snap, h, sha)
					_check(rest != null and rest.gabinete.pendiente_confirmar() == m.gabinete.pendiente_confirmar(), "%s: la instantánea no conserva la transición" % ctx)
			6:  # confirmar con 25 válidos (el preseleccionado o uno nuevo)
				var elegidos: Array = []
				for slot in por_cargo.keys():
					elegidos.append(String(por_cargo[slot][rng.randi_range(0, por_cargo[slot].size() - 1)]))
				var r2 := m.elegir_gabinete(elegidos)
				_check(bool(r2.get("ok", false)), "%s: 25 candidatos válidos (uno por cargo) fueron rechazados (%s)" % [ctx, str(r2.get("razon", "?"))])
				if bool(r2.get("ok", false)):
					confirmado = true
					_validos += 1
					_check(e.gabinete.size() == 25 and _unicos(e.gabinete) == 25, "%s: el gabinete confirmado no tiene 25 únicos (%d, %d)" % [ctx, e.gabinete.size(), _unicos(e.gabinete)])
		_check(m.gabinete.pendiente_confirmar() == (not confirmado), "%s op %d: pendiente=%s pero confirmado=%s" % [ctx, k, str(m.gabinete.pendiente_confirmar()), str(confirmado)])
	# terminar la semana sin confirmar: la transición se cierra sola (turno 2) y no vuelve
	m.terminar_turno()
	if m.estado.etapa == "gobierno":
		_check(not m.gabinete.pendiente_confirmar(), ctx + ": en el turno 2 no hay transición")
		for _s in range(6):
			m.terminar_turno()
			if m.estado.etapa != "gobierno":
				break
			_check(not m.gabinete.pendiente_confirmar(), ctx + ": la transición volvió a abrirse en pleno gobierno")


func _unicos(a: Array) -> int:
	var d := {}
	for x in a:
		d[x] = true
	return d.size()
