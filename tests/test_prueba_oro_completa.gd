extends SceneTree
## Prueba de oro integral: Partido -> Campaña -> Gobierno completo, determinista y reproducible por guardado.

## Huella de referencia: es idéntica en Godot 4.3 y 4.7.2 (Huella escribe los números igual en todas las versiones). Si un cambio de reglas o de datos
## es intencional, actualízala con el valor que imprime el fallo.
const ORO := "9cf8a968ac7b1a4bfbbad711ba3fc3f6b2666ea896f6febe59377f712d735803"

var _fallos: int = 0


func _init() -> void:
	var datos := Datos.cargar_todo()
	var m1 := _correr(datos, 20260415)
	var m2 := _correr(datos, 20260415)
	var m3 := _correr(datos, 777)
	_check(m1.estado.calcular_huella() == m2.estado.calcular_huella(), "Determinismo roto en campaña + gobierno")
	_check(m1.estado.calcular_huella() != m3.estado.calcular_huella(), "Semillas distintas dieron igual resultado")
	var rep := Partida.reproducir(datos, m1.estado.exportar_guardado())
	_check(rep.estado.calcular_huella() == m1.estado.calcular_huella(), "La reproducción desde guardado difiere")
	_check(m1.estado.registro_acciones.size() > 100, "El registro de acciones es demasiado corto")
	_check(m1.estado.etapa in ["fin_mandato", "crisis"], "La partida debe llegar a gobernar y terminar (fin de mandato o crisis): " + m1.estado.etapa)
	_check(m1.estado.calcular_huella() == ORO, "La huella ya no es la de referencia (%s); si el cambio es intencional, actualiza ORO" % m1.estado.calcular_huella())
	_check(not m1.estado.resultado_final.is_empty(), "Sin resultado final")
	print("Etapa final: %s | turno %d | resultado %s" % [m1.estado.etapa, m1.estado.turno_actual, m1.estado.resultado_final])
	if _fallos == 0:
		print("PRUEBA DE ORO INTEGRAL SUPERADA (Partido -> Campaña -> Gobierno)")
		print("Huella final: ", m1.estado.calcular_huella())
	quit(0 if _fallos == 0 else 1)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO: ", msg)


func _correr(datos: Dictionary, semilla: int) -> MotorTurno:
	var respuestas: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		respuestas.append(p["opciones"][1])
	var partido := GeneradorPartido.construir_partido(
			"Movimiento Cívico Austral", "MCA", "metropolitana", respuestas, datos["ideologia"])
	var motor := Partida.crear(datos, semilla, partido)
	var est := motor.estado
	for _s in range(int(datos["leyes"]["hemiciclo"]["semanas_campana"])):
		_jugar_todo(motor)
		motor.terminar_turno()
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	if not Bots.elegir(motor, datos, "azar", rng):
		return motor
	while est.etapa == "gobierno":
		_jugar_todo(motor)
		motor.terminar_turno()
	return motor


func _jugar_todo(motor: MotorTurno) -> void:
	var est := motor.estado
	var guard := 0
	while guard < 10 and not est.mano.is_empty():
		guard += 1
		var jugada := false
		for i in range(est.mano.size()):
			if motor.costo_carta(est.mano[i]) <= est.pa_actual:
				motor.jugar_carta(i)
				jugada = true
				break
		if not jugada:
			break
	for pid in est.propuestas_abiertas.duplicate():
		motor.aprobar_propuesta(pid, "B")
