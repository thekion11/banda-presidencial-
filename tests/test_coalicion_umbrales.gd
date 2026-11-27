extends SceneTree
## Empates exactos de la coalición (mata T11 y T12): con la satisfacción de todos los partidos exactamente en «umbral_satisfechos» hay bono de movimientos
## internos, y con la de un partido exactamente en «umbral_ruptura» NO rompe el pacto (rompe solo por debajo). Sin convergencia, para que el amanecer deje
## la satisfacción intacta.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _motor(datos: Dictionary) -> MotorTurno:
	var m := AyudaV2.gobierno(datos, 41)
	m.catalogo_leyes["coalicion"]["convergencia"] = 0.0
	return m


func _init() -> void:
	var datos := Datos.cargar_todo()
	var ids: Array = Array(_motor(datos).coalicion.partidos.keys()).slice(0, 2)
	var cfg: Dictionary = datos["leyes"]["coalicion"]
	var sat := float(cfg["umbral_satisfechos"])
	var rup := float(cfg["umbral_ruptura"])
	# satisfechos: >= umbral
	for par in [[sat, true], [sat - 0.5, false]]:
		var m := _motor(datos)
		m.estado.coalicion.clear()
		for id in ids:
			m.estado.coalicion[id] = {"satisfaccion": par[0], "ministros": [], "asesores": []}
		m.estado.internos_actual = 0
		m.coalicion.amanecer()
		var bono := int(cfg["bono_internos_satisfechos"])
		_check(m.estado.internos_actual == (bono if par[1] else 0), "con satisfacción %.1f en todos los partidos el bono es %d (hay %d)" % [par[0], bono if par[1] else 0, m.estado.internos_actual])
	# ruptura: < umbral
	for par in [[rup, true], [rup - 0.5, false]]:
		var m := _motor(datos)
		m.estado.coalicion.clear()
		m.estado.coalicion[ids[0]] = {"satisfaccion": par[0], "ministros": [], "asesores": []}
		m.estado.coalicion[ids[1]] = {"satisfaccion": 60.0, "ministros": [], "asesores": []}
		m.coalicion.amanecer()
		_check(m.estado.coalicion.has(ids[0]) == par[1], "con satisfacción %.1f el partido %s en la coalición" % [par[0], "sigue" if par[1] else "rompe y sale de"])
	if _fallos == 0:
		print("test_coalicion_umbrales: OK")
	quit(1 if _fallos > 0 else 0)
