class_name FuegosMapa
extends RefCounted
## Fuegos artificiales sobre la región de una obra terminada (dirección visual v4): tres cohetes que suben poco y
## estallan en 16 chispas con caída. Se dibujan en la capa viva del mapa de Chile; devuelve los que siguen vivos.


static func dibujar(v: Control, fuegos: Array[Dictionary], t: float, centro: Callable) -> Array[Dictionary]:
	if fuegos.is_empty():  # caso de casi todos los cuadros: sin arreglo nuevo
		return fuegos
	var vivos: Array[Dictionary] = []
	for f in fuegos:
		var l := t - float(f["inicio"])
		if l > 1.6:
			continue
		vivos.append(f)
		if l < 0.0:
			continue
		var base: Vector2 = centro.call(String(f["id"])) + Vector2(float(f["dx"]), 0.0)
		var col: Color = f["color"]
		if l < 0.4:  # sube el cohete
			var p := base + Vector2(0.0, -36.0 * (l / 0.4))
			v.draw_circle(p, 2.5, col)
			v.draw_line(p, p + Vector2(0.0, 10.0), Color(col, 0.5), 1.5)
			continue
		var k := (l - 0.4) / 1.2  # estalla en 16 chispas con caída
		var c := base + Vector2(0.0, -36.0)  # sube poco: el mapa es angosto y la explosión debe quedar sobre la región
		for i in range(16):
			var a := TAU * float(i) / 16.0
			var p2 := c + Vector2(cos(a), sin(a)) * 26.0 * sqrt(k) + Vector2(0.0, 16.0 * k * k)
			v.draw_circle(p2, 2.2 * (1.0 - k) + 0.6, Color(col, 1.0 - k))
	return vivos
