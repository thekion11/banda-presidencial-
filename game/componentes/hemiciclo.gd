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
var minimo: int = -1  # votación: línea del mínimo y contador sincronizado con los votos que caen (dirección visual v4)
var _cruzado: bool = false

const CAIDA := 4.0  # cuántos «puestos» tarda un voto en posarse


func configurar_votos(p_total: int, favor: int, abst: int, contra: int, mostrar_numero: bool = true) -> void:
	total = p_total
	bloques = [[favor, Tema.bien()], [abst, Color("#9AA9C0")], [contra, Tema.mal()]]
	numero = favor if mostrar_numero else -1
	texto_central = "votos a favor"
	_sucio = true
	queue_redraw()


func configurar_bloques(p_total: int, p_bloques: Array, p_numero: int = -1, p_texto: String = "") -> void:
	total = p_total
	bloques = p_bloques
	numero = p_numero
	texto_central = p_texto
	_sucio = true
	queue_redraw()


func animar_votacion(p_minimo: int, favor: int) -> float:
	## Votos que caen uno a uno de izquierda a derecha; si la votación es ajustada (±3 del mínimo), el tramo final
	## va lento para dar suspenso. Devuelve cuánto dura (el sello cae después). Sin animaciones, todo al instante.
	minimo = p_minimo
	_cruzado = false
	if not Movimiento.activo():
		progreso = 1.0
		_cruzado = favor >= minimo
		return 0.0
	progreso = 0.0
	var n := float(maxi(1, total)) + CAIDA
	var tw := create_tween()
	if absi(favor - minimo) <= 3 and minimo > 6:
		tw.tween_property(self, "progreso", float(minimo - 5) / n, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(self, "progreso", float(maxi(favor, minimo) + 2) / n, 1.5)
		tw.tween_property(self, "progreso", 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		return 2.75
	tw.tween_property(self, "progreso", 1.0, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return 1.3


func _contados() -> int:
	## Votos a favor ya posados (los a favor son los primeros de izquierda a derecha).
	var favor := int(bloques[0][0]) if not bloques.is_empty() else 0
	return clampi(int((float(total) + CAIDA) * progreso - CAIDA * 0.5), 0, favor)


func animar(duracion: float = 1.3) -> void:
	progreso = 0.0
	create_tween().tween_property(self, "progreso", 1.0, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


var _puntos: Array[Vector2] = []  # geometría precalculada: la animación solo redibuja círculos
var _colores: Array[Color] = []
var _radio_punto: float = 4.0
var _centro: Vector2 = Vector2.ZERO
var _grande: bool = false
var _sucio: bool = true
var _tam_prep: Vector2 = Vector2.ZERO
var _angulos: Array[float] = []
var _r_int: float = 0.0
var _r_ext: float = 0.0


func _preparar() -> void:
	_grande = total <= 60
	var filas := 5 if _grande else 8
	_centro = Vector2(size.x * 0.5, size.y - 14.0)
	var r_ext := minf(size.x * 0.46, size.y - 24.0)
	var r_int := r_ext * (0.46 if _grande else 0.50)
	var radios: Array[float] = []
	var suma := 0.0
	for f in range(filas):
		var r := r_int + (r_ext - r_int) * float(f) / float(filas - 1)
		radios.append(r)
		suma += r
	_r_int = r_int
	_r_ext = r_ext
	var puntos: Array[Vector3] = []
	for f in range(filas):
		var cuantos := roundi(float(total) * radios[f] / suma)
		if f == filas - 1:
			cuantos = total - puntos.size()
		for k in range(cuantos):
			var ang := PI + PI * (float(k) + 0.5) / float(cuantos)
			puntos.append(Vector3(_centro.x + cos(ang) * radios[f], _centro.y + sin(ang) * radios[f], ang))
	puntos.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z < b.z)
	_puntos.clear()
	_angulos.clear()
	for q in puntos:
		_puntos.append(Vector2(q.x, q.y))
		_angulos.append(q.z)
	_radio_punto = 8.0 if _grande else clampf((r_ext - r_int) / float(filas) * 0.40, 2.2, 3.8)
	_colores.clear()
	for b in bloques:
		for _k in range(int(b[0])):
			_colores.append(b[1])
	_sucio = false
	_tam_prep = size


func _draw() -> void:
	if _sucio or _tam_prep != size:
		_preparar()
	if minimo > 0:
		_dibujar_votacion()
		return
	var visibles := roundi(float(_puntos.size()) * progreso)
	for i in range(mini(visibles, _puntos.size())):
		draw_circle(_puntos[i], _radio_punto, _colores[i] if i < _colores.size() else Color("#9AA9C0"))
	if numero >= 0:
		draw_string(Tema.fuente_titulo(), Vector2(_centro.x - 60.0, _centro.y - 20.0), str(roundi(float(numero) * progreso)), HORIZONTAL_ALIGNMENT_CENTER, 120.0, 54 if _grande else 36, Tema.TEXTO)
		draw_string(Tema.fuente_texto(500), Vector2(_centro.x - 60.0, _centro.y), texto_central, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 12, Tema.TEXTO_SUAVE)


func _dibujar_votacion() -> void:
	## Cada voto cae desde arriba y se posa con un leve rebote; la línea dorada del mínimo se enciende al cruzarla.
	var vf := (float(total) + CAIDA) * progreso
	for i in range(_puntos.size()):
		var t := clampf((vf - float(i)) / CAIDA, 0.0, 1.0)
		if t <= 0.0:
			break
		var rebote := 1.0 + 0.35 * sin(t * PI) * (1.0 - t)
		var col: Color = _colores[i] if i < _colores.size() else Color("#9AA9C0")
		draw_circle(_puntos[i] + Vector2(0.0, -14.0 * (1.0 - t) * (1.0 - t)), _radio_punto * rebote * (0.35 + 0.65 * t), Color(col, t))
	var cuenta := _contados()
	var cruzo := cuenta >= minimo
	if cruzo and not _cruzado:
		_cruzado = true
		Feedback.sonar("toque")
		Feedback.vibrar(25)
	if minimo <= _angulos.size():
		var a := _angulos[minimo - 1] if minimo >= _angulos.size() else (_angulos[minimo - 1] + _angulos[minimo]) * 0.5
		var dir := Vector2(cos(a), sin(a))
		var p0 := _centro + dir * (_r_int - _radio_punto * 0.4)  # sin tocar la cifra central
		var p1 := _centro + dir * (_r_ext + _radio_punto + 6.0)
		if cruzo:
			draw_line(p0, p1, Color(Tema.ORO, 0.25), 9.0, true)
		draw_line(p0, p1, Color(Tema.ORO, 1.0 if cruzo else 0.5), 3.0 if cruzo else 2.0, true)
		var f := Tema.fuente_texto(600)
		var et := "mín. %d" % minimo
		var w := f.get_string_size(et, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		var pe := _centro + dir * (_r_ext + _radio_punto + 16.0)
		draw_string(f, pe - Vector2(w * 0.5, -4.0), et, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.ORO if cruzo else Tema.TEXTO_SUAVE)
	draw_string(Tema.fuente_titulo(), Vector2(_centro.x - 60.0, _centro.y - 20.0), str(cuenta), HORIZONTAL_ALIGNMENT_CENTER, 120.0, 54 if _grande else 36, Tema.bien() if cruzo else Tema.TEXTO)
	draw_string(Tema.fuente_texto(500), Vector2(_centro.x - 60.0, _centro.y), texto_central, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 12, Tema.TEXTO_SUAVE)
