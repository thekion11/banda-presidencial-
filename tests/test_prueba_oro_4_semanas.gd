extends SceneTree
## Prueba de oro de Fase 0: misma semilla + mismas jugadas = misma huella SHA-256.


const ORO := "a59c7b7c45c9cda777497a941d91bef0f65ad316a8d0b3f10d0c2d71494a7588"  # idéntica en Godot 4.3 y 4.7.2; si el cambio es intencional, actualízala


func _init() -> void:
	var datos := Datos.cargar_todo()
	var a := _simular_4_semanas(datos, 20260415)
	var b := _simular_4_semanas(datos, 20260415)
	var c := _simular_4_semanas(datos, 99999999)
	var ok := true
	ok = _check(a == b, "Misma semilla dio distinto resultado") and ok
	ok = _check(a != c, "Distinta semilla dio igual resultado") and ok
	ok = _check(a == ORO, "La huella ya no es la de referencia (%s); si el cambio es intencional, actualiza ORO" % a) and ok
	if ok:
		print("PRUEBA DE ORO SUPERADA (4 semanas / 28 días)")
		print("Huella determinista: ", a)
	quit(0 if ok else 1)


func _check(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("FALLO: " + msg)
		print("FALLO: ", msg)
	return cond


func _simular_4_semanas(datos: Dictionary, semilla: int) -> String:
	var estado := EstadoSimulacion.new()
	estado.configurar(semilla, int(datos["leyes"]["hemiciclo"]["dias_por_turno"]), datos["leyes"])
	estado.etapa = "gobierno"
	var motor := MotorTurno.new()
	motor.inicializar(estado, datos["cartas"], datos["eventos"], datos["leyes"], datos["ministros"],
			{"regiones": datos["regiones"], "propuestas": datos["propuestas"]})
	motor.regiones.inicializar(estado, estado.ind("aprobacion"), "", 0.0)
	for _semana in range(4):
		motor.ejecutar_amanecer()
		motor.procesar_eventos_semana()
		motor.robar_mano(5)
		if not estado.mano.is_empty():
			motor.jugar_carta(0, "min_vivienda")
		motor.cerrar_turno()
	return estado.calcular_huella()
