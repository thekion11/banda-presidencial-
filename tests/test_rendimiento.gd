extends SceneTree
## Rendimiento de la simulación: 10 partidas completas (semillas distintas) jugadas por el bot y reproducidas desde su guardado.
## Metas del usuario (26-nov-2026): un turno del motor (cartas + cierre + amanecer + eventos) en menos de 1 ms y cargar un guardado de mandato completo
## en menos de 100 ms (con la instantánea de carga; si no sirve, se reproduce el historial: se mide aparte). Los topes de la prueba tienen margen para el equipo de CI, que es más lento y variable; el informe imprime los valores reales.
## Además: las cachés no deben dar resultados viejos al cambiar el gabinete y el replay debe ser idéntico.

const PARTIDAS := 10
const TOPE_TURNO_MS := 1.0  # media de las partidas largas
const TOPE_TURNO_PEOR_MS := 2.0
const TOPE_CARGA_MS := 100.0  # media
const TOPE_CARGA_PEOR_MS := 160.0
const TOPE_REPRODUCIR_MS := 400.0  # sin instantánea: simular todo el historial de un mandato

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var turnos_ms: Array[float] = []
	var cargas_ms: Array[float] = []
	var repro_ms: Array[float] = []
	var huella_datos := Datos.huella(datos)
	for sd in range(PARTIDAS):
		var partido := GeneradorPartido.construir_partido("R", "RRR", "metropolitana", resp, datos["ideologia"])
		var m := Partida.crear(datos, 100 + sd, partido)
		var rng := RandomNumberGenerator.new()
		rng.seed = 100 + sd
		for _i in range(8):
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
		Bots.elegir(m, datos, "codicioso", rng)
		var turnos := 0
		while m.estado.etapa == "gobierno" and turnos < 208:
			Bots.jugar_turno(m, "codicioso", rng)
			m.terminar_turno()
			turnos += 1
		var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(Datos.huella(datos))))
		var t0 := Time.get_ticks_usec()
		var re := Partida.reproducir(datos, g)
		var ms := float(Time.get_ticks_usec() - t0) / 1000.0
		t0 = Time.get_ticks_usec()
		Partida.reproducir(datos, g)  # segunda pasada: se toma la mejor, para que un tropiezo del equipo (CI) no dé un falso rojo
		ms = minf(ms, float(Time.get_ticks_usec() - t0) / 1000.0)
		_check(re.estado.calcular_huella() == m.estado.calcular_huella(), "el replay de la partida %d es idéntico" % sd)
		# con instantánea (lo que hace el juego al continuar): leer + restaurar, incluida la creación del motor
		var bytes := Instantanea.tomar(m, huella_datos, "sha")  # se toma en el cierre de la semana; aquí solo se mide cargarla
		var t1 := Time.get_ticks_usec()
		var rapida := Partida.cargar(datos, g, Instantanea.leer(bytes), huella_datos, "sha")
		var ms_snap := float(Time.get_ticks_usec() - t1) / 1000.0
		t1 = Time.get_ticks_usec()
		Partida.cargar(datos, g, Instantanea.leer(bytes), huella_datos, "sha")
		ms_snap = minf(ms_snap, float(Time.get_ticks_usec() - t1) / 1000.0)
		_check(rapida.estado.calcular_huella() == m.estado.calcular_huella(), "la carga con instantánea de la partida %d es idéntica" % sd)
		if turnos >= 150:  # las partidas que caen en crisis a las pocas semanas no sirven para medir un mandato
			turnos_ms.append(ms / float(turnos + 8))
			cargas_ms.append(ms_snap)
			repro_ms.append(ms)
	_check(turnos_ms.size() >= 6, "al menos 6 de las %d partidas llegan a 150 turnos (%d)" % [PARTIDAS, turnos_ms.size()])
	var t_media := 0.0
	var c_media := 0.0
	for x in turnos_ms:
		t_media += x
	for x in cargas_ms:
		c_media += x
	t_media /= float(maxi(1, turnos_ms.size()))
	c_media /= float(maxi(1, cargas_ms.size()))
	var t_peor: float = turnos_ms.max() if not turnos_ms.is_empty() else 0.0
	var c_peor: float = cargas_ms.max() if not cargas_ms.is_empty() else 0.0
	var r_peor: float = repro_ms.max() if not repro_ms.is_empty() else 0.0
	print("%d partidas largas · turno medio %.2f ms, peor %.2f ms · cargar un guardado: medio %.0f ms, peor %.0f ms · reproducir el historial (sin instantánea), peor %.0f ms" % [turnos_ms.size(), t_media, t_peor, c_media, c_peor, r_peor])
	_check(r_peor < TOPE_REPRODUCIR_MS, "reproducir el historial < %.0f ms (%.0f)" % [TOPE_REPRODUCIR_MS, r_peor])
	_check(t_media < TOPE_TURNO_MS, "turno medio < %.1f ms (%.2f)" % [TOPE_TURNO_MS, t_media])
	_check(t_peor < TOPE_TURNO_PEOR_MS, "turno peor < %.1f ms (%.2f)" % [TOPE_TURNO_PEOR_MS, t_peor])
	_check(c_media < TOPE_CARGA_MS, "cargar un guardado < %.0f ms de media (%.0f)" % [TOPE_CARGA_MS, c_media])
	_check(c_peor < TOPE_CARGA_PEOR_MS, "cargar un guardado < %.0f ms en el peor caso (%.0f)" % [TOPE_CARGA_PEOR_MS, c_peor])
	# caché de categorías activas y de ministros titulares: cambiar el gabinete debe cambiar el resultado
	var m2 := AyudaV2.gobierno(datos, 9)
	var antes: Array = m2.gabinete.categorias_activas().keys()
	_check(antes == m2.gabinete.categorias_activas().keys(), "la caché devuelve lo mismo si el gabinete no cambia")
	var tit_antes := m2.gabinete.titular("salud")
	m2.estado.gabinete.clear()
	_check(m2.gabinete.categorias_activas().keys().size() < antes.size(), "al vaciar el gabinete la caché de categorías se invalida")
	_check(m2.gabinete.titular("salud") == "" and tit_antes != "", "al vaciar el gabinete la caché de titulares se invalida")
	print("test_rendimiento: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
