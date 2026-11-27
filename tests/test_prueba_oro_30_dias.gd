extends SceneTree
## Prueba de oro del Documento Maestro: 30 días con 5 cartas dan siempre el mismo resultado.
## Incluye delegación en ministros (cubre el camino de escándalo con la semilla).

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO: ", msg)


const ORO := "73f7ffd723c1063cc35d9df00cc8d0f57bc6f694c2e8e3f05745c2609f32ca3d"  # idéntica en Godot 4.3 y 4.7.2; si el cambio es intencional, actualízala


func _init() -> void:
	var datos := Datos.cargar_todo()
	var a := _simular(datos, 20260415)
	var b := _simular(datos, 20260415)
	var c := _simular(datos, 31415926)
	_check(a == b, "misma semilla dio distinto resultado en 30 días")
	_check(a != c, "semilla distinta dio igual resultado en 30 días")
	_check(a == ORO, "la huella ya no es la de referencia (%s); si el cambio es intencional, actualiza ORO" % a)
	if _fallos == 0:
		print("PRUEBA DE ORO 30 DÍAS SUPERADA")
		print("Huella: ", a)
	quit(0 if _fallos == 0 else 1)


func _simular(datos: Dictionary, semilla: int) -> String:
	var estado := EstadoSimulacion.new()
	estado.configurar(semilla, int(datos["leyes"]["hemiciclo"]["dias_por_turno"]), datos["leyes"])
	estado.etapa = "gobierno"
	var motor := MotorTurno.new()
	motor.inicializar(estado, datos["cartas"], datos["eventos"], datos["leyes"], datos["ministros"],
			{"regiones": datos["regiones"], "propuestas": datos["propuestas"]})
	motor.regiones.inicializar(estado, estado.ind("aprobacion"), "", 0.0)
	var ministros: Array = datos["ministros"]
	while estado.dia_actual <= 30:
		motor.ejecutar_amanecer()
		motor.procesar_eventos_semana()
		motor.robar_mano(5)
		for i in range(5):
			if estado.mano.is_empty():
				break
			var delegado: String = String(ministros[i % ministros.size()]["id"]) if i % 2 == 0 else ""
			var r := motor.jugar_carta(0, delegado)
			if not bool(r["ok"]) and delegado != "":
				motor.jugar_carta(0)
		motor.cerrar_turno()
	return estado.calcular_huella()
