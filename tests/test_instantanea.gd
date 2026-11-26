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
	# una instantánea con huella y SHA válidos pero sin sus partes se ignora (y Partida.cargar reproduce el historial)
	var incompleta := d.duplicate(true)
	incompleta.erase("rng_state")
	_check(not Instantanea.vale_para(incompleta, huella, "abc"), "sin rng_state no vale")
	var sin_estado := d.duplicate(true)
	sin_estado["estado"] = {"semilla": 1}
	_check(not Instantanea.vale_para(sin_estado, huella, "abc"), "con el estado recortado no vale")
	var sin_clave := d.duplicate(true)
	sin_clave.erase("estado")
	var estado_int := d.duplicate(true)
	estado_int["estado"] = 5
	var sin_seed := d.duplicate(true)
	sin_seed.erase("rng_seed")
	var estado_vacio := d.duplicate(true)
	estado_vacio["estado"] = {}
	var indic_vacios := d.duplicate(true)
	indic_vacios["estado"]["indicadores"] = {}
	# versión anterior del juego: a la caché le falta un campo que el estado ganó después (p. ej. «encuestas»), o trae uno de otro tipo
	var sin_campo := d.duplicate(true)
	sin_campo["estado"].erase("encuestas")
	var campo_tipo := d.duplicate(true)
	campo_tipo["estado"]["etapa"] = []
	var campo_extra := d.duplicate(true)
	campo_extra["estado"]["campo_de_otra_version"] = 1
	var seed_texto := d.duplicate(true)
	seed_texto["rng_state"] = "x"
	var huella_arreglo := d.duplicate(true)
	huella_arreglo["huella_datos"] = []
	var sha_nulo := d.duplicate(true)
	sha_nulo["sha_guardado"] = null
	for caso in [sin_clave, estado_int, sin_seed, estado_vacio, indic_vacios, sin_campo, campo_tipo, campo_extra, seed_texto, huella_arreglo, sha_nulo]:
		_check(not Instantanea.vale_para(caso, huella, "abc"), "una instantánea fabricada o recortada no vale")
	var m3 := Partida.crear(datos, 12, GeneradorPartido.construir_partido("I", "III", "metropolitana", resp, datos["ideologia"]))
	var r3 := RandomNumberGenerator.new()
	r3.seed = 12
	for _i in range(3):
		Bots.jugar_turno(m3, "completo", r3)
		m3.terminar_turno()
	var inc2 := Instantanea.leer(Instantanea.tomar(m3, huella, "abc"))
	inc2["estado"] = {}  # el caso más grave: partida en blanco en silencio
	var g3: Dictionary = JSON.parse_string(JSON.stringify(m3.estado.exportar_guardado(huella)))
	var rec := Partida.cargar(datos, g3, inc2, huella, "abc")
	_check(rec.estado.calcular_huella() == m3.estado.calcular_huella(), "una instantánea incompleta cae al historial y da el mismo estado")
	_check(Instantanea.leer(PackedByteArray([1, 2, 3])).is_empty() and Instantanea.leer(bytes.slice(0, 20)).is_empty(), "una instantánea dañada se descarta")
	print("test_instantanea: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)


func _probar(datos: Dictionary, huella: String, m: MotorTurno, nombre: String) -> void:
	var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(huella)))
	var repro := Partida.reproducir(datos, g)
	var snap := Instantanea.leer(Instantanea.tomar(m, huella, "sha"))
	_check(Instantanea.vale_para(snap, huella, "sha"), nombre + ": una instantánea legítima pasa la validación (si no, nunca se usaría)")
	var rest := Partida.cargar(datos, g, snap, huella, "sha")
	_iguales(rest, repro, nombre + " (restaurada contra reproducida)")
	for pr in rest.estado.get_property_list():  # los arreglos tipados siguen tipados tras restaurar
		if int(pr["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var a: Variant = rest.estado.get(pr["name"])
			var b: Variant = repro.estado.get(pr["name"])
			if a is Array and b is Array:
				_check((a as Array).is_typed() == (b as Array).is_typed() and (a as Array).get_typed_builtin() == (b as Array).get_typed_builtin(), "%s: el arreglo %s conserva su tipo" % [nombre, pr["name"]])
			_check(typeof(a) == typeof(b), "%s: %s conserva su tipo de dato" % [nombre, pr["name"]])
	_check(rest.estado.ciclo == repro.estado.ciclo and rest.estado.dias_carrera == repro.estado.dias_carrera, nombre + ": ciclo y días de carrera iguales")
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
	_check(rest.estado.ciclo >= repro.estado.ciclo and rest.estado.dias_carrera >= 0, nombre + ": ciclo y días de carrera no retroceden")
