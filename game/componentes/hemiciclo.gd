class_name Hemiciclo
extends Control
## Hemiciclo: un punto por parlamentario (a favor / abstención / en contra) y el total a favor al centro.

var a_favor: int = 0
var abstencion: int = 0
var en_contra: int = 0
var total: int = 50
var numero_central: bool = false
var progreso: float = 1.0:
	set(v):
		progreso = v
		queue_redraw()


func configurar(p_total: int, favor: int, contra: int, abst: int = 0, mostrar_numero: bool = false) -> void:
	total = p_total
	a_favor = favor
	en_contra = contra
	abstencion = abst
	numero_central = mostrar_numero
	queue_redraw()


func animar(duracion: float = 1.3) -> void:
	progreso = 0.0
	create_tween().tween_property(self, "progreso", 1.0, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var centro := Vector2(size.x * 0.5, size.y - 14.0)
	var filas := 4
	var r0 := size.x * 0.24
	var paso := size.x * 0.072
	var radios: Array[float] = []
	var suma := 0.0
	for f in range(filas):
		radios.append(r0 + float(f) * paso)
		suma += radios[f]
	var puntos: Array[Vector3] = []
	for f in range(filas):
		var cuantos := roundi(float(total) * radios[f] / suma)
		if f == filas - 1:
			cuantos = total - puntos.size()
		for k in range(cuantos):
			var ang := PI + PI * (float(k) + 0.5) / float(cuantos)
			puntos.append(Vector3(centro.x + cos(ang) * radios[f], centro.y + sin(ang) * radios[f], ang))
	puntos.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z < b.z)
	var visibles := roundi(float(puntos.size()) * progreso)
	for i in range(mini(visibles, puntos.size())):
		var col := Color("#9AA9C0")
		if i < a_favor:
			col = Tema.SUBE
		elif i >= puntos.size() - en_contra:
			col = Tema.BAJA
		draw_circle(Vector2(puntos[i].x, puntos[i].y), 5.2, col)
	if numero_central:
		draw_string(Tema.fuente_titulo(), Vector2(centro.x - 60.0, centro.y - 22.0), str(roundi(float(a_favor) * progreso)), HORIZONTAL_ALIGNMENT_CENTER, 120.0, 54, Tema.TEXTO)
		draw_string(Tema.fuente_texto(500), Vector2(centro.x - 60.0, centro.y - 2.0), "votos a favor", HORIZONTAL_ALIGNMENT_CENTER, 120.0, 12, Tema.TEXTO_SUAVE)
