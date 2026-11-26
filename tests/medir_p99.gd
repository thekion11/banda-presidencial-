extends SceneTree
## Percentiles de tiempo: turno (terminar_turno + iniciar_turno) y carga de un guardado (con instantánea y reproduciendo el historial) en 10 mandatos completos.
## Uso: godot --headless --path . -s tests/medir_p99.gd

func _pct(v: Array, p: float) -> float:
	var s := v.duplicate()
	s.sort()
	return float(s[mini(s.size() - 1, int(float(s.size()) * p))])


func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("P99", "P99", "metropolitana", resp, datos["ideologia"])
	var turnos: Array[float] = []
	var cargas: Array[float] = []
	var repl: Array[float] = []
	for semilla in range(10):
		var m := Partida.crear(datos, 12000 + semilla, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = 12000 + semilla
		var guard := 0
		while guard < 400 and MotorTurno.ETAPAS_JUEGO.has(m.estado.etapa):
			guard += 1
			if m.estado.etapa == "campana" and m.estado.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
				if not Bots.elegir(m, datos, "codicioso", rng):
					break
				continue
			Bots.jugar_turno(m, "codicioso", rng)
			var t := Time.get_ticks_usec()
			m.terminar_turno()
			turnos.append((Time.get_ticks_usec() - t) / 1000.0)
		var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado("h")))
		var sha := "abc%d" % semilla
		var snap := Instantanea.leer(Instantanea.tomar(m, "h", sha))
		var t1 := Time.get_ticks_usec()
		var c := Partida.cargar(datos, g, snap, "h", sha)
		cargas.append((Time.get_ticks_usec() - t1) / 1000.0)
		var t2 := Time.get_ticks_usec()
		var r := Partida.reproducir(datos, g)
		repl.append((Time.get_ticks_usec() - t2) / 1000.0)
		if c == null or r == null:
			print("FALLO: carga nula")
	print("P99 turnos=%d · turno p50 %.2f ms p99 %.2f ms máx %.2f ms · carga con instantánea p50 %.1f ms p99 %.1f ms máx %.1f ms · replay p50 %.0f ms p99 %.0f ms máx %.0f ms" % [
			turnos.size(), _pct(turnos, 0.5), _pct(turnos, 0.99), turnos.max(), _pct(cargas, 0.5), _pct(cargas, 0.99), cargas.max(), _pct(repl, 0.5), _pct(repl, 0.99), repl.max()])
	quit()
