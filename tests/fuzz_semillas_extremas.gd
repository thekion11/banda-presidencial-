extends SceneTree
## Semillas extremas (0, negativas, 2^31 - 1, 2^31, 2^32, el entero más grande y el más pequeño): la misma semilla debe dar la misma partida (dos corridas idénticas y
## replay idéntico desde el guardado tras un ciclo JSON), y en mandatos completos (hasta 208 turnos) ningún evento aleatorio se repite antes de su descanso
## (director_eventos.cooldown_evento) ni queda más de un evento aleatorio por semana. También comprueba que la huella no depende del signo ni del tamaño de la semilla
## (semillas distintas dan huellas distintas).
## LÍMITE CONOCIDO: el guardado es JSON y sus números son decimales de doble precisión, así que una semilla de más de 2^53 (9.007e15) no sobrevive al guardado
## (p. ej. 2^63 - 1 vuelve como 9223372036854775808.0). El juego genera semillas menores que 2.000.000.000, así que no se alcanza; para esas semillas solo se comprueba
## el determinismo en vivo (dos corridas idénticas) y se cuenta el caso.
## Uso: godot --headless --path . -s tests/fuzz_semillas_extremas.gd

const SEMILLAS := [0, -1, 1, 2147483647, 2147483648, 4294967296, -2147483648, 9223372036854775807, -9223372036854775808, 20260415]

var _fallos := 0
var _datos: Dictionary
var _huella_datos: String


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO SEMILLAS: ", msg)
		_fallos += 1


func _jugar(semilla: int) -> MotorTurno:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345  # las decisiones del bot no dependen de la semilla de la partida: solo cambia el azar del motor
	var resp: Array[Dictionary] = []
	for p in _datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("S", "SSS", "metropolitana", resp, _datos["ideologia"])
	partido["indicadores_iniciales"]["aprobacion"] = 90.0
	var m := Partida.crear(_datos, semilla, partido)
	var e := m.estado
	for _s in range(int(_datos["leyes"]["hemiciclo"]["semanas_campana"])):
		Bots.jugar_turno(m, "completo", rng)
		m.terminar_turno()
	if Bots.elegir(m, _datos, "completo", rng):
		var guard := 0
		while e.etapa == "gobierno" and guard < 260:
			guard += 1
			Bots.jugar_turno(m, "completo", rng)
			m.terminar_turno()
	return m


func _init() -> void:
	_datos = Datos.cargar_todo()
	_huella_datos = Datos.huella(_datos)
	var cd := int(_datos["leyes"]["director_eventos"]["cooldown_evento"])
	var huellas := {}
	var turnos_total := 0
	var fuera_de_json := 0
	for sem in SEMILLAS:
		var a := _jugar(sem)
		var b := _jugar(sem)
		var h := a.estado.calcular_huella()
		_check(h == b.estado.calcular_huella(), "semilla %d: dos corridas idénticas dan huellas distintas" % sem)
		if absf(float(sem)) > 9007199254740992.0:
			fuera_de_json += 1  # no representable en el guardado JSON (límite conocido): solo determinismo en vivo
		else:
			var g: Dictionary = JSON.parse_string(JSON.stringify(a.estado.exportar_guardado(_huella_datos)))
			_check(Partida.reproducir(_datos, g).estado.calcular_huella() == h, "semilla %d: el replay no es idéntico (etapa %s)" % [sem, a.estado.etapa])
			_check(int(g["semilla"]) == sem, "semilla %d: el guardado perdió la semilla (%s)" % [sem, str(g["semilla"])])
		_check(not huellas.has(h), "semilla %d: misma huella que la semilla %s (la semilla no influye)" % [sem, str(huellas.get(h, "?"))])
		huellas[h] = sem
		turnos_total += a.estado.turno_actual
		# eventos aleatorios: descanso por evento y a lo sumo uno por semana (en el periodo de gobierno)
		var ultimo := {}
		var por_turno := {}
		for r in a.estado.registro_acciones:
			if r["tipo"] != "evento" or r["etapa"] != "gobierno":
				continue
			var d: Dictionary = r["detalle"]
			if not String(d.get("tipo", "")).begins_with("aleatorio"):
				continue
			var id := String(d["id"])
			var t := int(r["turno"])
			if ultimo.has(id):
				_check(t - int(ultimo[id]) >= cd, "semilla %d: el evento %s se repite tras %d semanas (descanso %d)" % [sem, id, t - int(ultimo[id]), cd])
			ultimo[id] = t
			por_turno[t] = int(por_turno.get(t, 0)) + 1
		for t in por_turno:
			_check(int(por_turno[t]) <= 1, "semilla %d: %d eventos aleatorios en el turno %d" % [sem, por_turno[t], t])
	print("FUZZ SEMILLAS EXTREMAS %s (%d semillas, %d turnos jugados, %d semillas fuera del rango exacto de JSON, %d fallos)" % ["OK" if _fallos == 0 else "CON FALLOS", SEMILLAS.size(), turnos_total, fuera_de_json, _fallos])
	quit(1 if _fallos > 0 else 0)
