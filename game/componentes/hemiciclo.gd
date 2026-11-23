class_name Hemiciclo
extends Control
## Hemiciclo parlamentario (Senado de 50 o Cámara de 155). Se dibuja por bloques de color de izquierda a derecha,
## con total central opcional y animación de llenado.

var bloques: Array = []  # [[cantidad, Color], ...] en orden de izquierda a derecha
var total: int = 50
var numero: int = -1  # número grande al centro (-1 = ninguno)
var texto_central: String = ""
var progreso: float = 1.0:
	set(v):
		progreso = v
		queue_redraw()


func configurar_votos(p_total: int, favor: int, abst: int, contra: int, mostrar_numero: bool = true) -> void:
	total = p_total
	bloques = [[favor, Tema.SUBE], [abst, Color("#9AA9C0")], [contra, Tema.BAJA]]
	numero = favor if mostrar_numero else -1
	texto_central = "votos a favor"
	queue_redraw()


func configurar_bloques(p_total: int, p_bloques: Array, p_numero: int = -1, p_texto: String = "") -> void:
	total = p_total
	bloques = p_bloques
	numero = p_numero
	texto_central = p_texto
	queue_redraw()


func animar(duracion: float = 1.3) -> void:
	progreso = 0.0
	create_tween().tween_property(self, "progreso", 1.0, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var grande := total <= 60
	var filas := 5 if grande else 8
	var centro := Vector2(size.x * 0.5, size.y - 14.0)
	var r_ext := minf(size.x * 0.46, size.y - 24.0)
	var r_int := r_ext * (0.46 if grande else 0.50)
	var radios: Array[float] = []
	var suma := 0.0
	for f in range(filas):
		var r := r_int + (r_ext - r_int) * float(f) / float(filas - 1)
		radios.append(r)
		suma += r
	var puntos: Array[Vector3] = []
	for f in range(filas):
		var cuantos := roundi(float(total) * radios[f] / suma)
		if f == filas - 1:
			cuantos = total - puntos.size()
		for k in range(cuantos):
			var ang := PI + PI * (float(k) + 0.5) / float(cuantos)
			puntos.append(Vector3(centro.x + cos(ang) * radios[f], centro.y + sin(ang) * radios[f], ang))
	puntos.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z < b.z)
	var radio_punto := 8.0 if grande else clampf((r_ext - r_int) / float(filas) * 0.40, 2.2, 3.8)
	var colores: Array[Color] = []
	for b in bloques:
		for _k in range(int(b[0])):
			colores.append(b[1])
	var visibles := roundi(float(puntos.size()) * progreso)
	for i in range(mini(visibles, puntos.size())):
		var col := colores[i] if i < colores.size() else Color("#9AA9C0")
		draw_circle(Vector2(puntos[i].x, puntos[i].y), radio_punto, col)
	if numero >= 0:
		draw_string(Tema.fuente_titulo(), Vector2(centro.x - 60.0, centro.y - 20.0), str(roundi(float(numero) * progreso)), HORIZONTAL_ALIGNMENT_CENTER, 120.0, 54 if grande else 36, Tema.TEXTO)
		draw_string(Tema.fuente_texto(500), Vector2(centro.x - 60.0, centro.y), texto_central, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 12, Tema.TEXTO_SUAVE)
