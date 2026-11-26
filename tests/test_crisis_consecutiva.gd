extends SceneTree
## Caída del gobierno por crisis: cuenta semanas CONSECUTIVAS con la aprobación bajo el umbral. Una semana buena reinicia el contador: tras
## (semanas_crisis_para_caida - 1) semanas malas, una buena y (semanas_crisis_para_caida - 1) malas más, el gobierno sigue; con una semana mala más cae.
## (Hallazgo del mutation testing: si el contador nunca se reiniciaba, ninguna prueba lo notaba.)

var _fallos := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _semana(m: MotorTurno, aprobacion: float) -> void:
	m.estado.indicadores["aprobacion"] = aprobacion
	m.terminar_turno()


func _init() -> void:
	var datos := Datos.cargar_todo()
	var din: Dictionary = datos["leyes"]["dinamica"]
	var caida := int(din["semanas_crisis_para_caida"])
	var mala := maxf(0.0, float(din["umbral_crisis_aprobacion"]) - 10.0)
	var buena := minf(100.0, float(din["umbral_crisis_aprobacion"]) + 40.0)
	var m := AyudaV2.gobierno(datos, 8)
	var e := m.estado
	_check(e.etapa == "gobierno" and e.semanas_en_crisis == 0, "se parte de un gobierno sin semanas en crisis")
	for k in range(caida - 1):
		_semana(m, mala)
		_check(e.etapa == "gobierno" and e.semanas_en_crisis == k + 1, "semana mala %d: el contador debe valer %d (vale %d) y el gobierno sigue (%s)" % [k + 1, k + 1, e.semanas_en_crisis, e.etapa])
	_semana(m, buena)
	_check(e.semanas_en_crisis == 0 and e.etapa == "gobierno", "una semana buena reinicia el contador (vale %d)" % e.semanas_en_crisis)
	for k in range(caida - 1):
		_semana(m, mala)
		_check(e.etapa == "gobierno" and e.semanas_en_crisis == k + 1, "tras el reinicio, la semana mala %d no debe tumbar al gobierno (contador %d, %s)" % [k + 1, e.semanas_en_crisis, e.etapa])
	_semana(m, mala)
	_check(e.etapa == "crisis" and e.semanas_en_crisis >= caida, "con %d semanas malas seguidas el gobierno cae (%s, contador %d)" % [caida, e.etapa, e.semanas_en_crisis])
	print("test_crisis_consecutiva: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
