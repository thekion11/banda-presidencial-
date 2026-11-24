extends SceneTree
## PR-01: afiliación (propio / independiente / existente) desde datos: efectos, coalición y guardado.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var cfg: Dictionary = datos["leyes"]["afiliacion"]
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	var propio := GeneradorPartido.construir_partido_afiliado("propio", {}, "Mi Partido", "MPA", "metropolitana", resp, datos["ideologia"], cfg)
	var base: Dictionary = datos["coalicion"][0]
	var ind := GeneradorPartido.construir_partido_afiliado("independiente", {}, "Candidatura Independiente", "IND", "metropolitana", resp, datos["ideologia"], cfg)
	var exi := GeneradorPartido.construir_partido_afiliado("existente", base, String(base["nombre"]), String(base["sigla"]), "metropolitana", _tipado(resp.slice(0, 3)), datos["ideologia"], cfg)
	_check(float(ind["indicadores_iniciales"]["aprobacion"]) > float(propio["indicadores_iniciales"]["aprobacion"]), "el independiente parte con más aprobación")
	_check(int(ind["escanos_propios"]) <= int(propio["escanos_propios"]), "el independiente tiene bancada menor o igual")
	_check(float(exi["indicadores_iniciales"]["cohesion"]) > float(propio["indicadores_iniciales"]["cohesion"]) - 25.0, "el partido existente aporta cohesión")
	_check(String(exi["partido_base"]) == String(base["id"]) and exi["afiliacion"] == "existente", "el existente recuerda su partido")
	_check(absf(float(exi["eje_eco"]) - float(base["ideologia"]["eco"])) <= float(cfg["opciones"]["existente"]["peso_postura"]) * 3.0 + 0.001, "la ideología del existente parte de la del partido")
	var m := Partida.crear(datos, 11, exi)
	_check(not m.coalicion.partidos.has(String(base["id"])), "tu propio partido no es aliado")
	_check(m.coalicion.partidos.size() == datos["coalicion"].size() - 1, "los demás partidos siguen disponibles")
	var m2 := Partida.crear(datos, 11, ind)
	_check(m2.coalicion.partidos.size() == datos["coalicion"].size(), "el independiente puede aliarse con todos")
	for _s in range(3):
		m2.terminar_turno()
	var g: Dictionary = JSON.parse_string(JSON.stringify(m2.estado.exportar_guardado(Datos.huella(datos))))
	_check(Partida.reproducir(datos, g).estado.calcular_huella() == m2.estado.calcular_huella(), "guardado y replay idénticos con afiliación")
	# PR-06c: los eventos de vecinos mueven la relación exterior sin estado nuevo
	var m3 := Partida.crear(datos, 3, propio)
	var rel0 := m3.eventos.relacion_exterior("ARG", 62.0)
	m3.estado.eventos_ocurridos["evt_vecino_arg_crisis"] = 1
	_check(m3.eventos.relacion_exterior("ARG", 62.0) < rel0, "una crisis en Argentina baja la relación")
	_check(m3.eventos.relacion_exterior("BRA", 66.0) == 66.0, "otros países no cambian")
	print("test_afiliacion: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)


func _tipado(a: Array) -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for x in a:
		r.append(x)
	return r
