extends SceneTree
## Guardado versionado: la huella de datos cambia si cambia un dato de balance y el guardado se reproduce idéntico.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO GUARDADO: ", msg)


func _init() -> void:
	var datos := Datos.cargar_todo()
	var h := Datos.huella(datos)
	_check(h.length() == 64 and h == Datos.huella(Datos.cargar_todo()), "huella estable entre cargas")
	var otro := Datos.cargar_todo()
	otro["leyes"]["hemiciclo"]["umbral_victoria_presidencial"] = 77.0
	_check(Datos.huella(otro) != h, "la huella cambia al cambiar un número de balance")
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido("P", "P", "metropolitana", resp, datos["ideologia"])
	var m := Partida.crear(datos, 7, partido)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for _i in range(3):
		Bots.jugar_turno(m, "codicioso", rng)
		m.terminar_turno()
	var g: Dictionary = JSON.parse_string(JSON.stringify(m.estado.exportar_guardado(h)))
	_check(int(g["version"]) == 2 and g["huella_datos"] == h, "el guardado lleva versión y huella")
	_check(Partida.reproducir(datos, g).estado.calcular_huella() == m.estado.calcular_huella(), "replay idéntico")
	# v2: gabinete elegido por el jugador + mano continua se reproducen idénticos
	var m2 := Partida.crear(datos, 9, partido)
	var gab := AyudaV2.ministros_de(datos, ["salud", "transportes", "vivienda"], int(datos["leyes"]["gabinete"]["tamano"]))
	_check(bool(m2.elegir_gabinete(gab)["ok"]), "gabinete elegido en campaña")
	rng.seed = 9
	for _i in range(3):
		Bots.jugar_turno(m2, "codicioso", rng)
		m2.terminar_turno()
	var g2: Dictionary = JSON.parse_string(JSON.stringify(m2.estado.exportar_guardado(h)))
	_check(g2["entradas"].any(func(e: Dictionary) -> bool: return e["tipo"] == "gabinete"), "el guardado incluye la entrada gabinete")
	var r2 := Partida.reproducir(datos, g2)
	_check(r2.estado.gabinete == m2.estado.gabinete and r2.estado.calcular_huella() == m2.estado.calcular_huella(), "replay idéntico con gabinete")
	# v2: partida completa con delegación y movimientos internos (bot codicioso) se reproduce idéntica
	var mc := Bots.partida_completa(datos, 5000, "codicioso")
	for sem in range(5001, 5020):
		if mc.estado.etapa != "derrota_electoral":
			break
		mc = Bots.partida_completa(datos, sem, "codicioso")
	var gc: Dictionary = JSON.parse_string(JSON.stringify(mc.estado.exportar_guardado(h)))
	var tipos := {}
	for e in gc["entradas"]:
		tipos[e["tipo"]] = true
	_check(mc.estado.etapa != "derrota_electoral" and tipos.has("meta"), "la partida de prueba llegó a gobernar con movimientos internos")
	_check(gc["entradas"].any(func(e: Dictionary) -> bool: return e["tipo"] == "jugar" and bool(e.get("delegada", false))), "hay delegaciones en el historial")
	_check(Partida.reproducir(datos, gc).estado.calcular_huella() == mc.estado.calcular_huella(), "replay idéntico de una partida completa v2")
	print("GUARDADO OK" if _fallos == 0 else "GUARDADO FALLÓ")
	quit(1 if _fallos > 0 else 0)
