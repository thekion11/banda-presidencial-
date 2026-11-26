extends SceneTree
## Candados contra la tanda 2 de mutantes de «Búsqueda infinita de fallas» (26-nov-2026): tope del historial de encuestas, instantánea sin SHA, tipo de «delegada» en el guardado
## y piso de la probabilidad de fallo de la delegación.

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _partida(datos: Dictionary, semilla: int) -> MotorTurno:
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	return Partida.crear(datos, semilla, GeneradorPartido.construir_partido("Mutantes3", "MU3", "metropolitana", resp, datos["ideologia"]))


func _init() -> void:
	var datos := Datos.cargar_todo()
	# 1) el historial de encuestas guarda exactamente historial_max encuestas (no una menos)
	var m := _partida(datos, 21)
	m.catalogo_leyes["encuestas"]["historial_max"] = 3
	for _s in range(8):
		m.terminar_turno()
	_check(m.estado.encuestas.size() == 3, "con historial_max = 3 se guardan 3 encuestas (%d)" % m.estado.encuestas.size())
	# 2) una instantánea tomada sin SHA del guardado no vale para un guardado sin SHA
	var snap := Instantanea.leer(Instantanea.tomar(m, "h", ""))
	_check(not snap.is_empty(), "la instantánea se puede leer")
	_check(not Instantanea.vale_para(snap, "h", ""), "una instantánea con sha vacío no vale")
	var snap2 := Instantanea.leer(Instantanea.tomar(m, "h", "abc"))
	_check(Instantanea.vale_para(snap2, "h", "abc") and not Instantanea.vale_para(snap2, "h", "otro"), "con sha propio solo vale para ese guardado")
	# 3) «delegada» debe ser booleano en una entrada «jugar»
	_check(ValidarGuardado.entrada_valida({"tipo": "jugar", "idx": 0, "ministro": "", "region": "", "delegada": true}), "jugar con delegada booleana es válida")
	_check(not ValidarGuardado.entrada_valida({"tipo": "jugar", "idx": 0, "ministro": "", "region": "", "delegada": "si"}), "jugar con delegada de texto es inválida")
	# 4) la probabilidad de fallo de una delegación nunca baja de prob_fallo_min
	var g := _partida(datos, 22)
	g.catalogo_leyes["delegacion"]["prob_fallo_base"] = 0.0
	g.catalogo_leyes["delegacion"]["peso_bono_ejecucion"] = 100.0  # un ministro afín deja la probabilidad bajo cero antes del piso
	var minimo := float(g.catalogo_leyes["delegacion"]["prob_fallo_min"])
	g.estado.etapa = "gobierno"
	var menor := 1.0
	for id in g.estado.gabinete:
		for i in range(g.estado.mano.size()):
			menor = minf(menor, g.prob_fallo_delegacion(i, String(id)))
	_check(menor >= minimo - 0.000001, "la probabilidad de fallo no baja del mínimo configurado (%f < %f)" % [menor, minimo])
	_check(absf(menor - minimo) < 0.000001, "con base 0 y el mejor ministro afín la probabilidad queda exactamente en el mínimo (%f)" % menor)
	print("test_mutantes_3: ", "OK" if _fallos == 0 else "%d fallos" % _fallos)
	quit(1 if _fallos > 0 else 0)
