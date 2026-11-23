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
	print("GUARDADO OK" if _fallos == 0 else "GUARDADO FALLÓ")
	quit(1 if _fallos > 0 else 0)
