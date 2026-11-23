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


func _draw() -> void:
	if carta.is_empty():
		return
	var w := size.x
	var h := size.y
	var base: Color = COLORES_CATEGORIA.get(String(carta["categoria"]), Tema.PANEL)
	var fondo := Tema.CREMA if not atenuada else Tema.CREMA.darkened(0.45)
	draw_style_box(Tema.caja(fondo, 12, Tema.ORO if elegida else Color(0, 0, 0, 0.35), 3 if elegida else 1), Rect2(Vector2.ZERO, size))
	var arte := Rect2(5, 5, w - 10, h * 0.30)
	draw_style_box(Tema.caja(base.darkened(0.25) if atenuada else base, 9), arte)
	_icono(arte.get_center(), Tema.CREMA)
	var cat: String = NOMBRES_CAT.get(String(carta["categoria"]), String(carta["categoria"]).to_upper())
	var cinta := Rect2(w - 64.0, 10, 58, 15)
	draw_style_box(Tema.caja(Tema.ROJO, 4), cinta)
	draw_string(Tema.fuente_texto(700), cinta.position + Vector2(4, 11), cat, HORIZONTAL_ALIGNMENT_LEFT, 52, 8, Tema.CREMA)
	draw_circle(Vector2(22, 22), 15.0, Tema.OCEANO)
	draw_circle(Vector2(22, 22), 13.0, Tema.ORO)
	draw_string(Tema.fuente_titulo(), Vector2(15, 30), str(costo), HORIZONTAL_ALIGNMENT_CENTER, 14, 17, Tema.TINTA)
	var tam_titulo := 11 if elegida else 10
	draw_multiline_string(Tema.fuente_titulo(), Vector2(8, arte.end.y + 15), String(carta["titulo"]),
			HORIZONTAL_ALIGNMENT_LEFT, w - 14, tam_titulo, 3, Tema.TINTA)
	var y := h - 41.0
	var n := 0
	for ef in carta["efectos"]:
		if n >= 2:
			break
		var delta := float(ef["delta"])
		var txt := "%s %s" % [Tema.signo(delta) if absf(delta) < 1000.0 else "+%dk" % roundi(delta / 1000.0), _nombre_ind(String(ef["ind"]))]
		var col := Tema.SUBE.darkened(0.25) if delta >= 0.0 else Tema.ROJO
		var chip := Rect2(6, y + float(n) * 19.0, w - 12, 17)
		draw_style_box(Tema.caja(col, 8), chip)
		var flecha := ""
		draw_string(Tema.fuente_texto(600), chip.position + Vector2(5, 12), flecha + txt, HORIZONTAL_ALIGNMENT_LEFT, w - 18, 10, Tema.TEXTO)
		n += 1


static func _nombre_ind(ind: String) -> String:
	return {"aprobacion": "Aprob.", "capital": "Capital", "cohesion": "Cohes.", "fiscal": "Fiscal",
			"riesgo_ejecucion": "Riesgo", "viviendas_anio": "viv./año"}.get(ind, ind)
