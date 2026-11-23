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


func _escena(arte: Rect2, base: Color) -> void:
	var c := arte.get_center()
	var cat := String(carta.get("categoria", ""))
	draw_circle(arte.position + Vector2(arte.size.x * 0.78, arte.size.y * 0.28), arte.size.y * 0.16, Color(1, 0.86, 0.5, 0.55))
	draw_rect(Rect2(arte.position.x, arte.end.y - 12, arte.size.x, 12), base.darkened(0.45))
	if cat == "vivienda":
		var casas := [[0.12, 0.52, Color("#D9A441")], [0.38, 0.38, Color("#F2EEE4")], [0.66, 0.52, Color("#3FA39B")]]
		for k in casas:
			var x := arte.position.x + arte.size.x * float(k[0])
			var w := arte.size.x * 0.24
			var top := arte.position.y + arte.size.y * float(k[1])
			var base_y := arte.end.y - 8
			draw_rect(Rect2(x, top + 8, w, base_y - top - 8), k[2])
			draw_colored_polygon(PackedVector2Array([Vector2(x - 3, top + 9), Vector2(x + w * 0.5, top - 4), Vector2(x + w + 3, top + 9)]), Color("#B5473A"))
			draw_rect(Rect2(x + w * 0.38, base_y - 12, w * 0.24, 12), Color(0, 0, 0, 0.35))
	else:
		_icono(c + Vector2(0, 2), Tema.CREMA)


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
	var arte := Rect2(5, 5, w - 10, h * 0.43)
	draw_style_box(Tema.caja(base.lightened(0.1), 9), arte)
	draw_style_box(Tema.caja(Color(0.04, 0.12, 0.2, 0.28), 9), Rect2(arte.position.x, arte.position.y + arte.size.y * 0.5, arte.size.x, arte.size.y * 0.5))
	_escena(arte, base)
	var cat: String = NOMBRES_CAT.get(String(carta["categoria"]), String(carta["categoria"]).to_upper())
	var cinta := Rect2(w - 68.0, 9, 62, 16)
	draw_style_box(Tema.caja(Tema.ROJO if elegida else base.darkened(0.35), 4), cinta)
	draw_string(Tema.fuente_texto(800), cinta.position + Vector2(0, 11.5), cat, HORIZONTAL_ALIGNMENT_CENTER, 62, 9, Tema.CREMA)
	_gema(Vector2(21, 21), 14.0)
	draw_multiline_string(Tema.fuente_titulo(), Vector2(8, arte.end.y + 17), String(carta["titulo"]),
			HORIZONTAL_ALIGNMENT_LEFT, w - 14, 12 if elegida else 11, 2, Tema.TEXTO)
	var y := h - 42.0
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
