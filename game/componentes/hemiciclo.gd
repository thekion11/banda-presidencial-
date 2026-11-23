class_name Hemiciclo
extends Control
## Hemiciclo del Senado: un punto por senador (a favor / abstención / en contra).

var a_favor: int = 0
var en_contra: int = 0
var total: int = 50


func configurar(p_total: int, favor: int, contra: int) -> void:
	total = p_total
	a_favor = favor
	en_contra = contra
	queue_redraw()


func _draw() -> void:
	var centro := Vector2(size.x * 0.5, size.y - 8.0)
	var filas := 4
	var radios: Array[float] = []
	for f in range(filas):
		radios.append(size.x * 0.20 + float(f) * (size.x * 0.075))
	var suma := 0.0
	for r in radios:
		suma += r
	var puntos: Array[Vector3] = []  # x, y, ángulo
	for f in range(filas):
		var cuantos := roundi(float(total) * radios[f] / suma)
		if f == filas - 1:
			cuantos = total - puntos.size()
		for k in range(cuantos):
			var ang := PI + PI * (float(k) + 0.5) / float(cuantos)
			puntos.append(Vector3(centro.x + cos(ang) * radios[f], centro.y + sin(ang) * radios[f], ang))
	puntos.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z < b.z)
	for i in range(puntos.size()):
		var col := Tema.SUBE if i < a_favor else (Tema.BAJA if i >= puntos.size() - en_contra else Color("#9AA9B8"))
		draw_circle(Vector2(puntos[i].x, puntos[i].y), 4.6, col)
