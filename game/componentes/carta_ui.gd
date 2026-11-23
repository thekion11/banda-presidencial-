class_name CartaUI
extends Control
## Carta de la mano: ilustración arriba, gema de PA, cinta de categoría, título y chips de efectos.

signal tocada(carta: CartaUI)

const COLORES_CATEGORIA := {
	"vivienda": Color("#3D7EA6"), "comite": Color("#5B6FB5"), "energia": Color("#D9A441"), "hacienda": Color("#4F8F6B"),
	"salud": Color("#B5544F"), "educacion": Color("#7E6BB0"), "seguridad": Color("#556B7F"), "transportes": Color("#3F8E91"),
	"economia": Color("#A67C3D"), "social": Color("#B0607E"), "medioambiente": Color("#5E9A4C"), "politica": Color("#7A5D9A"),
	"descentralizacion": Color("#4C7FA0"), "obras": Color("#9A7A4C"),
}
const NOMBRES_CAT := {"comite": "COMITÉ", "medioambiente": "AMBIENTE", "descentralizacion": "REGIONES", "transportes": "TRANSPORTE"}

var carta: Dictionary = {}
var costo: int = 0
var elegida: bool = false
var atenuada: bool = false


func configurar(p_carta: Dictionary, p_costo: int) -> void:
	carta = p_carta
	costo = p_costo
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed):
		tocada.emit(self)


func _cielo(arte: Rect2, base: Color) -> void:
	## Cielo con degradado en 3 franjas redondeadas y suelo con esquinas inferiores redondeadas.
	var arriba := base.lightened(0.28)
	var medio := base.lightened(0.08).lerp(Color("#F0B27A"), 0.10)
	var abajo := base.darkened(0.10).lerp(Color("#F0B27A"), 0.22)
	draw_style_box(Tema.caja(arriba, 9), arte)
	draw_style_box(Tema.caja(medio, 0), Rect2(arte.position.x, arte.position.y + arte.size.y * 0.34, arte.size.x, arte.size.y * 0.33))
	var bajo := Tema.caja(abajo, 0)
	bajo.corner_radius_bottom_left = 9
	bajo.corner_radius_bottom_right = 9
	draw_style_box(bajo, Rect2(arte.position.x, arte.position.y + arte.size.y * 0.67, arte.size.x, arte.size.y * 0.33))
	draw_circle(arte.position + Vector2(arte.size.x * 0.8, arte.size.y * 0.27), arte.size.y * 0.15, Color(1, 0.88, 0.55, 0.75))
	var suelo := Tema.caja(base.darkened(0.55), 0)
	suelo.corner_radius_bottom_left = 9
	suelo.corner_radius_bottom_right = 9
	draw_style_box(suelo, Rect2(arte.position.x, arte.end.y - 10, arte.size.x, 10))


func _escena(arte: Rect2, base: Color) -> void:
	_cielo(arte, base)
	var o := arte.position
	var w := arte.size.x
	var h := arte.size.y
	var suelo := arte.end.y - 10.0
	var claro := Tema.CREMA
	match String(carta.get("categoria", "")):
		"vivienda":
			for k in [[0.10, 0.50, Color("#D9A441")], [0.36, 0.34, Color("#F2EEE4")], [0.64, 0.50, Color("#3FA39B")]]:
				var x := o.x + w * float(k[0])
				var an := w * 0.26
				var top := o.y + h * float(k[1])
				draw_rect(Rect2(x, top + 8, an, suelo - top - 8), k[2])
				draw_colored_polygon(PackedVector2Array([Vector2(x - 3, top + 9), Vector2(x + an * 0.5, top - 5), Vector2(x + an + 3, top + 9)]), Color("#B5473A"))
				draw_rect(Rect2(x + an * 0.36, suelo - 12, an * 0.28, 12), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(x + an * 0.12, top + 16, 6, 6), Color(1, 0.95, 0.7, 0.9))
		"transportes":
			for k in range(3):
				draw_line(Vector2(o.x + w * (0.2 + 0.3 * float(k)), suelo), Vector2(o.x + w * (0.42 + 0.08 * float(k)), o.y + h * 0.62), Color(0, 0, 0, 0.35), 1.5)
			var tx := o.x + w * 0.14
			draw_style_box(Tema.caja(claro, 5), Rect2(tx, o.y + h * 0.42, w * 0.72, h * 0.32))
			draw_rect(Rect2(tx, o.y + h * 0.62, w * 0.72, h * 0.04), Tema.ROJO)
			for k in range(4):
				draw_rect(Rect2(tx + 6 + float(k) * w * 0.17, o.y + h * 0.47, w * 0.12, h * 0.12), Color("#244B6B"))
		"comite":
			for g in range(1, 6):
				draw_line(Vector2(o.x, o.y + h * float(g) / 6.0), Vector2(arte.end.x, o.y + h * float(g) / 6.0), Color(1, 1, 1, 0.14), 1.0)
				draw_line(Vector2(o.x + w * float(g) / 6.0, o.y), Vector2(o.x + w * float(g) / 6.0, suelo), Color(1, 1, 1, 0.14), 1.0)
			var ruta := PackedVector2Array([Vector2(o.x + w * 0.1, o.y + h * 0.7), Vector2(o.x + w * 0.38, o.y + h * 0.4), Vector2(o.x + w * 0.6, o.y + h * 0.55), Vector2(o.x + w * 0.9, o.y + h * 0.2)])
			draw_polyline(ruta, Tema.ROJO, 3.5, true)
			for q in ruta:
				draw_circle(q, 4.5, claro)
				draw_circle(q, 2.5, Tema.ROJO)
		"energia":
			for k in range(3):
				var x := o.x + w * (0.12 + 0.28 * float(k))
				draw_colored_polygon(PackedVector2Array([Vector2(x, o.y + h * 0.52), Vector2(x + w * 0.26, o.y + h * 0.45), Vector2(x + w * 0.22, suelo - 6), Vector2(x - 0.04 * w, suelo - 4)]), Color("#2A5D8F"))
				draw_line(Vector2(x + w * 0.11, o.y + h * 0.5), Vector2(x + w * 0.09, suelo - 5), Color(1, 1, 1, 0.5), 1.0)
				draw_line(Vector2(x, o.y + h * 0.62), Vector2(x + w * 0.24, o.y + h * 0.56), Color(1, 1, 1, 0.5), 1.0)
		"hacienda", "economia":
			for k in range(4):
				var bx := o.x + w * (0.14 + 0.19 * float(k))
				var bh := h * (0.22 + 0.13 * float(k))
				draw_rect(Rect2(bx, suelo - bh, w * 0.13, bh), Tema.ORO if k % 2 == 0 else claro)
			draw_polyline(PackedVector2Array([Vector2(o.x + w * 0.1, o.y + h * 0.62), Vector2(o.x + w * 0.4, o.y + h * 0.46), Vector2(o.x + w * 0.6, o.y + h * 0.5), Vector2(o.x + w * 0.9, o.y + h * 0.2)]), Tema.ROJO, 2.5, true)
		"salud":
			draw_rect(Rect2(o.x + w * 0.2, o.y + h * 0.3, w * 0.6, suelo - o.y - h * 0.3), claro)
			draw_rect(Rect2(o.x + w * 0.46, o.y + h * 0.36, w * 0.08, h * 0.3), Tema.ROJO)
			draw_rect(Rect2(o.x + w * 0.37, o.y + h * 0.47, w * 0.26, h * 0.08), Tema.ROJO)
			for k in range(3):
				draw_rect(Rect2(o.x + w * (0.26 + 0.17 * float(k)), suelo - 14, 7, 14), Color("#8FB3CF"))
		"educacion":
			draw_rect(Rect2(o.x + w * 0.18, o.y + h * 0.42, w * 0.64, suelo - o.y - h * 0.42), Color("#E8C27A"))
			draw_colored_polygon(PackedVector2Array([Vector2(o.x + w * 0.12, o.y + h * 0.44), Vector2(o.x + w * 0.5, o.y + h * 0.18), Vector2(o.x + w * 0.88, o.y + h * 0.44)]), Color("#7E3B3B"))
			draw_circle(Vector2(o.x + w * 0.5, o.y + h * 0.36), 5.0, claro)
			for k in range(3):
				draw_rect(Rect2(o.x + w * (0.26 + 0.2 * float(k)), o.y + h * 0.56, 8, 12), Color("#244B6B"))
		"seguridad":
			var cx := o.x + w * 0.5
			draw_colored_polygon(PackedVector2Array([Vector2(cx - w * 0.2, o.y + h * 0.2), Vector2(cx + w * 0.2, o.y + h * 0.2), Vector2(cx + w * 0.2, o.y + h * 0.55), Vector2(cx, suelo - 2), Vector2(cx - w * 0.2, o.y + h * 0.55)]), Color("#2B4C6B"))
			draw_colored_polygon(PackedVector2Array([Vector2(cx - w * 0.15, o.y + h * 0.26), Vector2(cx + w * 0.15, o.y + h * 0.26), Vector2(cx + w * 0.15, o.y + h * 0.52), Vector2(cx, suelo - 10), Vector2(cx - w * 0.15, o.y + h * 0.52)]), Tema.ORO)
		"social":
			for k in range(3):
				var px := o.x + w * (0.25 + 0.25 * float(k))
				draw_circle(Vector2(px, o.y + h * 0.4), h * 0.09, claro)
				draw_style_box(Tema.caja([Tema.ROJO, Tema.SUBE, Tema.ORO][k], 10), Rect2(px - w * 0.08, o.y + h * 0.5, w * 0.16, suelo - o.y - h * 0.5))
		"politica":
			draw_style_box(Tema.caja(Color("#3A2A4F"), 4), Rect2(o.x + w * 0.3, o.y + h * 0.5, w * 0.4, suelo - o.y - h * 0.5))
			draw_line(Vector2(o.x + w * 0.5, o.y + h * 0.5), Vector2(o.x + w * 0.5, o.y + h * 0.16), claro, 2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(o.x + w * 0.5, o.y + h * 0.16), Vector2(o.x + w * 0.74, o.y + h * 0.26), Vector2(o.x + w * 0.5, o.y + h * 0.36)]), Tema.ROJO)
			draw_circle(Vector2(o.x + w * 0.5, o.y + h * 0.66), 5.0, Tema.ORO)
		"medioambiente":
			for k in range(4):
				var tx2 := o.x + w * (0.14 + 0.22 * float(k))
				draw_rect(Rect2(tx2 + 4, suelo - 14, 4, 14), Color("#5A3B2A"))
				draw_circle(Vector2(tx2 + 6, suelo - 24 - float(k % 2) * 6.0), 10.0, Color("#3E8E4D"))
		"descentralizacion":
			for k in [[0.25, 0.6], [0.5, 0.35], [0.75, 0.62]]:
				var c := Vector2(o.x + w * float(k[0]), o.y + h * float(k[1]))
				draw_circle(c, 8.0, claro)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-5, 3), c + Vector2(5, 3), c + Vector2(0, 14)]), claro)
				draw_circle(c, 3.5, Tema.ROJO)
		_:
			draw_arc(Vector2(o.x + w * 0.1, suelo), w * 0.4, PI * 1.1, PI * 1.9, 14, claro, 4.0)
			draw_line(Vector2(o.x + w * 0.74, suelo), Vector2(o.x + w * 0.74, o.y + h * 0.15), Tema.ORO, 3.0)
			draw_line(Vector2(o.x + w * 0.74, o.y + h * 0.15), Vector2(o.x + w * 0.48, o.y + h * 0.22), Tema.ORO, 3.0)


func _icono(c: Vector2, col: Color) -> void:
	var cat := String(carta.get("categoria", ""))
	match cat:
		"vivienda", "obras":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-22, 2), c + Vector2(0, -20), c + Vector2(22, 2)]), col)
			draw_rect(Rect2(c + Vector2(-16, 2), Vector2(32, 20)), col)
			draw_rect(Rect2(c + Vector2(-4, 8), Vector2(9, 14)), Color(0, 0, 0, 0.35))
		"comite", "transportes":
			draw_line(c + Vector2(-24, 14), c + Vector2(-6, -8), col, 4.0)
			draw_line(c + Vector2(-6, -8), c + Vector2(10, 8), col, 4.0)
			draw_line(c + Vector2(10, 8), c + Vector2(24, -14), col, 4.0)
			for p in [Vector2(-24, 14), Vector2(-6, -8), Vector2(10, 8), Vector2(24, -14)]:
				draw_circle(c + p, 5.0, col)
		"energia":
			draw_colored_polygon(PackedVector2Array([c + Vector2(4, -22), c + Vector2(-14, 4), c + Vector2(-1, 4), c + Vector2(-5, 22), c + Vector2(15, -6), c + Vector2(2, -6)]), col)
		"salud":
			draw_rect(Rect2(c + Vector2(-5, -20), Vector2(10, 40)), col)
			draw_rect(Rect2(c + Vector2(-20, -5), Vector2(40, 10)), col)
		"hacienda", "economia":
			draw_circle(c, 20.0, col)
			draw_circle(c, 14.0, Color(0, 0, 0, 0.25))
			draw_rect(Rect2(c + Vector2(-2, -10), Vector2(4, 20)), col)
		_:
			draw_circle(c + Vector2(0, -8), 9.0, col)
			draw_arc(c + Vector2(0, 22), 20.0, PI, TAU, 16, col, 6.0)


func _gema(c: Vector2, r: float) -> void:
	draw_circle(c, r + 2.0, Tema.OCEANO)
	draw_circle(c, r, Color("#C9921F"))
	draw_circle(c + Vector2(0, -0.8), r - 2.0, Tema.ORO)
	draw_arc(c, r - 3.5, PI * 1.1, PI * 1.7, 10, Color(1, 1, 1, 0.55), 2.0)
	draw_string(Tema.fuente_titulo(), c + Vector2(-r, r * 0.42), str(costo), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, int(r * 1.25), Tema.TINTA)


func _chip_efecto(r: Rect2, delta: float, texto: String) -> void:
	var bueno := delta >= 0.0
	draw_style_box(Tema.caja(Color("#2E9E6B") if bueno else Tema.ROJO, 9), r)
	var cx := r.position.x + 8.0
	var cy := r.position.y + r.size.y * 0.5
	if bueno:
		draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - 4.5), Vector2(cx + 4.5, cy + 1), Vector2(cx + 1.5, cy + 1), Vector2(cx + 1.5, cy + 4.5), Vector2(cx - 1.5, cy + 4.5), Vector2(cx - 1.5, cy + 1), Vector2(cx - 4.5, cy + 1)]), Tema.TEXTO)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(cx, cy + 4.5), Vector2(cx + 4.5, cy - 1), Vector2(cx + 1.5, cy - 1), Vector2(cx + 1.5, cy - 4.5), Vector2(cx - 1.5, cy - 4.5), Vector2(cx - 1.5, cy - 1), Vector2(cx - 4.5, cy - 1)]), Tema.TEXTO)
	draw_string(Tema.fuente_texto(700), Vector2(r.position.x + 16.0, r.position.y + r.size.y - 4.5), texto, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 18.0, 10, Tema.TEXTO)


func _draw() -> void:
	if carta.is_empty():
		return
	var w := size.x
	var h := size.y
	var base: Color = COLORES_CATEGORIA.get(String(carta["categoria"]), Tema.PANEL)
	if elegida:
		for k in range(4):
			var g := 3.0 + float(k) * 3.0
			draw_style_box(Tema.caja(Color(Tema.ORO, 0.07), 16 + k * 2), Rect2(-g, -g, w + g * 2.0, h + g * 2.0))
	var borde := Tema.ORO if elegida else Color("#7C8EA0")
	draw_style_box(Tema.caja(Color("#0E2A44"), 13, borde, 3 if elegida else 2), Rect2(Vector2.ZERO, size))
	var arte := Rect2(5, 5, w - 10, h * 0.40)
	_escena(arte, base)
	var cat: String = NOMBRES_CAT.get(String(carta["categoria"]), String(carta["categoria"]).to_upper())
	var cinta := Rect2(w - 68.0, 9, 62, 16)
	draw_style_box(Tema.caja(Tema.ROJO if elegida else base.darkened(0.35), 4), cinta)
	draw_string(Tema.fuente_texto(800), cinta.position + Vector2(0, 11.5), cat, HORIZONTAL_ALIGNMENT_CENTER, 62, 9, Tema.CREMA)
	_gema(Vector2(21, 21), 14.0)
	draw_multiline_string(Tema.fuente_titulo(), Vector2(8, arte.end.y + 17), String(carta["titulo"]),
			HORIZONTAL_ALIGNMENT_LEFT, w - 14, 12 if elegida else 11, 2, Tema.TEXTO)
	var y := h - 41.0
	var n := 0
	for ef in carta["efectos"]:
		if n >= 2:
			break
		var delta := float(ef["delta"])
		var cifra := ("+%dk" % roundi(delta / 1000.0)) if absf(delta) >= 1000.0 else Tema.signo(delta)
		_chip_efecto(Rect2(6, y + float(n) * 19.0, w - 12, 17), delta, "%s %s" % [cifra, _nombre_ind(String(ef["ind"]))])
		n += 1
	if atenuada:
		draw_style_box(Tema.caja(Color(0.03, 0.09, 0.15, 0.22), 13), Rect2(Vector2.ZERO, size))


static func _nombre_ind(ind: String) -> String:
	return {"aprobacion": "Aprob.", "capital": "Capital", "cohesion": "Cohes.", "fiscal": "Fiscal",
			"riesgo_ejecucion": "Riesgo", "viviendas_anio": "viv./año"}.get(ind, ind)
