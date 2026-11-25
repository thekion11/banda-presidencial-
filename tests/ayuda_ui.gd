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
