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
