extends SceneTree
## La instantánea (caché de carga) debe dar exactamente la partida que da reproducir el historial, y seguir igual al jugar adelante.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _props(m: MotorTurno) -> Dictionary:
	var d := {}
	for pr in m.estado.get_property_list():
		if int(pr["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			d[pr["name"]] = Huella.texto(m.estado.get(pr["name"])).sha256_text()
	d["_rng"] = "%d:%d" % [m.rng.seed, m.rng.state]
	d["_ultimos"] = Huella.texto(m.ultimos_eventos).sha256_text()
	return d


func _iguales(a: MotorTurno, b: MotorTurno, msg: String) -> void:
	var pa := _props(a)
	var pb := _props(b)
	var dif: Array[String] = []
	for k in pa.keys():
		if pa[k] != pb.get(k, ""):
			dif.append(k)
	_check(dif.is_empty(), "%s: propiedades distintas %s" % [msg, str(dif)])


func _init() -> void:
	var datos := Datos.cargar_todo()
	var huella := Datos.huella(datos)
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var ms_restaurar := 0.0
	var n_rest := 0
	for sd in [3, 4, 5, 6]:
		var m := Partida.crear(datos, sd, GeneradorPartido.construir_partido("I", "III", "metropolitana", resp, datos["ideologia"]))
		var rng := RandomNumberGenerator.new()
		rng.seed = sd
		var momentos := {4: true, 8: true}  # turnos de campaña en que se toma la instantánea
		for t in range(8):
			Bots.jugar_turno(m, "completo", rng)
			if momentos.has(t + 1) or t == 3:
				_probar(datos, huella, m, "campaña turno %d (semilla %d)" % [t + 1, sd])
			m.terminar_turno()
		Bots.elegir(m, datos, "completo", rng)
		var n := 0
		while m.estado.etapa == "gobierno" and n < 208:
			Bots.jugar_turno(m, "completo", rng)
			if n == 20 or n == 90 or n == 170:
				var t0 := Time.get_ticks_usec()
				_probar(datos, huella, m, "gobierno turno %d (semilla %d)" % [n, sd])
				ms_restaurar += float(Time.get_ticks_usec() - t0) / 1000.0
				n_rest += 1
			m.terminar_turno()
			n += 1
	print("test_instantanea: %d pruebas de gobierno (incluyen reproducir, restaurar y jugar 12 turnos en ambos)" % n_rest)
	# validación contra el guardado
	var m2 := AyudaV2.gobierno(datos, 8)
	var bytes := Instantanea.tomar(m2, huella, "abc")
	var d := Instantanea.leer(bytes)
	_check(Instantanea.vale_para(d, huella, "abc"), "vale para su guardado")
	_check(not Instantanea.vale_para(d, huella, "otro"), "no vale si el guardado cambió")
	_check(not Instantanea.vale_para(d, "otra_huella", "abc"), "no vale si los datos cambiaron")
	_check(not Instantanea.vale_para({}, huella, "abc"), "una instantánea vacía no vale")
	_check(Instantanea.leer(PackedByteArray([1, 2, 3])).is_empty() and Instantanea.leer(bytes.slice(0, 20)).is_empty(), "una instantánea dañada se descarta")
	print("test_instantanea: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)


func _probar(datos: Dictionary, huella: String, m: MotorTurno, nombre: String) -> void:
	var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(huella)))
	var repro := Partida.reproducir(datos, g)
	var snap := Instantanea.leer(Instantanea.tomar(m, huella, "sha"))
	var rest := Partida.cargar(datos, g, snap, huella, "sha")
	_iguales(rest, repro, nombre + " (restaurada contra reproducida)")
	_check(rest.estado.calcular_huella() == m.estado.calcular_huella(), nombre + ": misma huella que la partida en vivo")
	# jugar adelante en ambas con el mismo azar del bot
	var r1 := RandomNumberGenerator.new()
	var r2 := RandomNumberGenerator.new()
	r1.seed = 99
	r2.seed = 99
	for _i in range(12):
		if not MotorTurno.ETAPAS_JUEGO.has(rest.estado.etapa) or rest.estado.eleccion_pendiente(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
			break
		Bots.jugar_turno(rest, "completo", r1)
		Bots.jugar_turno(repro, "completo", r2)
		rest.terminar_turno()
		repro.terminar_turno()
	_iguales(rest, repro, nombre + " (12 turnos después)")
