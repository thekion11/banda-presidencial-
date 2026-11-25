class_name AyudaUI
extends RefCounted
## Utilidades de las pruebas de interfaz (mantiene test_ui_humo.gd bajo el límite de líneas).


static func deslizar_arriba(mano: Control) -> void:
	## Simula pulsar en el centro de la mano y soltar 120 px más arriba (gesto de jugar de PR-02).
	var c0: Vector2 = mano.get_global_rect().get_center()
	for par in [[true, c0], [false, c0 + Vector2(5, -120)]]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = par[0]
		ev.position = par[1]
		mano._input(ev)


static func oposicion(arbol: SceneTree) -> void:
	## PR-13: recorre las cuatro escenas del Modo Oposición y comprueba que llega al resultado final.
	var datos := Datos.cargar_todo()
	var o := PantallaOposicion.new()
	o.datos = datos
	arbol.root.add_child(o)
	await arbol.process_frame
	for _k in range(datos["leyes"]["oposicion"]["escenas"].size()):
		o.elegir(datos["leyes"]["oposicion"]["escenas"][o._i]["opciones"][0])
	await arbol.process_frame
	assert(o._i == datos["leyes"]["oposicion"]["escenas"].size())
	o.queue_free()


static func controles_dia(dia: Control) -> Array[String]:
	## PR-02: tocar dos veces la carta elegida la juega; el botón del medio pide confirmar si sobran movimientos. Devuelve los fallos.
	var fallos: Array[String] = []
	var est: EstadoSimulacion = dia.motor.estado
	if est.pa_actual > 0 and est.mano.size() > 0:
		var pa0: int = est.pa_actual
		dia._mano_tocada = false
		dia._on_carta(0)
		if est.pa_actual != pa0:
			fallos.append("el primer toque solo elige la carta")
		dia._on_carta(0)
		if est.pa_actual >= pa0:
			fallos.append("el segundo toque sobre la carta elegida debe jugarla")
	if est.pa_actual > 0:
		var turno0: int = est.turno_actual
		dia._confirmar_fin = false
		dia._avanzar()
		if est.turno_actual != turno0 or not dia._confirmar_fin:
			fallos.append("con movimientos sin usar, avanzar pide confirmación")
		dia._confirmar_fin = false
	return fallos
