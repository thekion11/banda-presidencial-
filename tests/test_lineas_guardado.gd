extends SceneTree
## Guardado de las líneas del jugador en una partida real: el bot juega campaña y gobierno hasta abrirse una propuesta del Comité, se aprueba con
## nombres, se guarda como JSON y se reproduce: la línea, sus nombres y la huella deben ser idénticos.
var fallos := 0
func chk(c: bool, m: String) -> void:
	if not c:
		fallos += 1
		print("FALLO LINEAS GUARDADO: ", m)
func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("P", "P", "metropolitana", resp, datos["ideologia"])
	var abierta := false
	for semilla in range(1, 6):
		var m := Partida.crear(datos, semilla, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = semilla
		var turnos := 0
		var hem: Dictionary = datos["leyes"]["hemiciclo"]
		for ronda in range(2):  # campaña, elección y (si hay) segunda vuelta, en el mismo orden que la interfaz y la reproducción
			var k := 0
			while (ronda == 0 and not m.estado.eleccion_pendiente(int(hem["semanas_campana"]))) or (ronda == 1 and k < int(hem["semanas_balotaje"])):
				Bots.jugar_turno(m, "codicioso", rng)
				m.terminar_turno()
				k += 1
				turnos += 1
				if turnos > 60:
					break
			var r := m.resolver_eleccion_presidencial()
			if bool(r["electo"]):
				m.iniciar_turno()
				break
			if bool(r["balotaje"]):
				m.iniciar_turno()
				continue
			break
		if m.estado.etapa != "gobierno":
			continue
		var aprobada := false
		for _i in range(40):
			if not m.estado.propuestas_abiertas.is_empty():
				var pid: String = m.estado.propuestas_abiertas[0]
				if m.estado.pa_actual >= int(m.catalogo_propuestas[pid]["costo_pa"]):  # sin tocar el estado a mano: solo juego legítimo
					var r2 := m.aprobar_propuesta(pid, "A", "", {}, {"linea": "Línea Prueba", "estaciones": ["Uno", "Dos"]})
					chk(bool(r2["ok"]), "no se aprobó: %s" % r2)
					aprobada = true
					break
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		if not aprobada:
			continue
		abierta = true
		for _j in range(6):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		var h := Datos.huella(datos)
		var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(h)))
		var rep := Partida.reproducir(datos, g)
		chk(rep.estado.lineas_jugador.size() == m.estado.lineas_jugador.size() and m.estado.lineas_jugador.size() == 1, "la línea no sobrevive al reproducir el guardado")
		chk(rep.estado.lineas_jugador[0]["nombre"] == "Línea Prueba" and rep.estado.lineas_jugador[0]["nombres_estaciones"][0] == "Uno" and rep.estado.lineas_jugador[0]["nombres_estaciones"][1] == "Dos", "los nombres no sobreviven al reproducir")
		chk(rep.estado.calcular_huella() == m.estado.calcular_huella(), "la huella difiere tras reproducir")
		print("semilla %d: línea %s estado %s (turno %d) -> reproducción OK=%s" % [semilla, rep.estado.lineas_jugador[0]["nombre"], rep.estado.lineas_jugador[0]["estado"], m.estado.turno_actual, str(rep.estado.calcular_huella() == m.estado.calcular_huella())])
		break
	chk(abierta, "ninguna semilla abrió una propuesta del Comité en el recorrido del bot")
	print("LINEAS GUARDADO ", "OK" if fallos == 0 else "CON FALLOS")
	quit(0 if fallos == 0 else 1)
