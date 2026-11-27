class_name GraficoMandato
extends Control
## Tu aprobación semana a semana en la pantalla de fin (pedido del usuario del 27-nov-2026: «Gráfico del mandato en el
## fin»). Lee el registro de acciones del motor (`cierre_turno` guarda la aprobación de cada semana) del periodo actual:
## curva con el color de la escala de aprobación, línea dorada del umbral, separación campaña / gobierno y un punto en
## cada hito. La curva se traza de izquierda a derecha; sin movimiento aparece completa.

var puntos: Array[Dictionary] = []  # {etapa, turno, aprobacion}
var hitos_turnos: Array = []  # [etapa, turno] de cada hito
var umbral := 50.0
var _avance := 1.0


static func crear(motor: MotorTurno) -> GraficoMandato:
	var g := GraficoMandato.new()
	var reg: Array = motor.estado.registro_acciones
	var desde := 0
	for i in range(reg.size()):
		if String(reg[i]["tipo"]) == "periodo_nuevo":
			desde = i + 1  # solo el periodo que termina
	for i in range(desde, reg.size()):
		var a: Dictionary = reg[i]
		if String(a["tipo"]) == "cierre_turno":
			g.puntos.append({"etapa": String(a["etapa"]), "turno": int(a["turno"]), "aprobacion": float(a["detalle"].get("aprobacion", 0.0))})
	for h in motor.mandato.hitos(12):
		g.hitos_turnos.append(int(h["turno"]))
	g.umbral = float(motor.catalogo_leyes["hemiciclo"]["umbral_victoria_presidencial"])
	g.custom_minimum_size = Vector2(0, 170)
	return g


func _ready() -> void:
	if Movimiento.activo() and puntos.size() > 1:
		_avance = 0.0
		var tw := create_tween()
		tw.tween_method(func(x: float) -> void:
			_avance = x
			queue_redraw(), 0.0, 1.0, 1.4).set_delay(0.3).set_trans(Tween.TRANS_SINE)


func _y(v: float, r: Rect2) -> float:
	return r.end.y - clampf(v / 100.0, 0.0, 1.0) * r.size.y


func _draw() -> void:
	draw_style_box(Tema.caja(Tema.PANEL, 12), Rect2(Vector2.ZERO, size))
	var r := Rect2(Vector2(30, 12), size - Vector2(42, 34))
	var f := Tema.fuente_texto(400)
	for v in [25, 50, 75]:  # guías con su porcentaje
		var y := _y(float(v), r)
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(1, 1, 1, 0.08), 1.0)
		draw_string(f, Vector2(4, y + 4), "%d %%" % v, HORIZONTAL_ALIGNMENT_LEFT, 26, 10, Tema.TEXTO_SUAVE)
	var yu := _y(umbral, r)
	draw_dashed_line(Vector2(r.position.x, yu), Vector2(r.end.x, yu), Color(Tema.ORO, 0.8), 1.5, 5.0)
	if puntos.size() < 2:
		draw_string(f, r.position + Vector2(8, r.size.y * 0.5), "Sin semanas registradas en este periodo.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Tema.TEXTO_SUAVE)
		return
	var n := puntos.size()
	var paso := r.size.x / float(n - 1)
	var corte := -1  # primera semana de gobierno: línea vertical
	for i in range(n):
		if corte < 0 and puntos[i]["etapa"] == "gobierno":
			corte = i
	if corte > 0:
		var x := r.position.x + paso * float(corte)
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(1, 1, 1, 0.18), 1.0)
		draw_string(f, Vector2(r.position.x + 2, r.end.y + 16), "Campaña", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TEXTO_SUAVE)
		var w_camp := f.get_string_size("Campaña", HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(f, Vector2(maxf(x + 4.0, r.position.x + w_camp + 12.0), r.end.y + 16), "Gobierno", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Tema.TEXTO_SUAVE)
	var hasta := maxi(1, int(ceil(_avance * float(n - 1))))
	for i in range(hasta):
		var a := Vector2(r.position.x + paso * float(i), _y(float(puntos[i]["aprobacion"]), r))
		var b := Vector2(r.position.x + paso * float(i + 1), _y(float(puntos[i + 1]["aprobacion"]), r))
		draw_line(a, b, Tema.color_aprobacion(float(puntos[i + 1]["aprobacion"])), 2.5, true)
	for i in range(hasta + 1):
		var p: Dictionary = puntos[i]
		if p["etapa"] == "gobierno" and hitos_turnos.has(int(p["turno"])):  # hito de tu mandato en esa semana
			draw_circle(Vector2(r.position.x + paso * float(i), _y(float(p["aprobacion"]), r)), 4.0, Tema.ORO)
	var ult: Dictionary = puntos[hasta]
	draw_circle(Vector2(r.position.x + paso * float(hasta), _y(float(ult["aprobacion"]), r)), 3.5, Tema.CREMA)
