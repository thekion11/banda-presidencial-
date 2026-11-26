class_name Particulas
extends Control
## Partículas de ambiente (dirección visual v4): «motas» doradas y crema que suben lento en el fondo del menú,
## y «confeti» oro, rojo y crema al ganar la elección. Solo presentación: su azar no toca la semilla de la partida.
## Con Ajustes › Animaciones apagado o en modo headless no se dibuja ni procesa nada.

var modo: String = "motas"  # "motas" | "confeti"
var cantidad: int = 22
var duracion: float = 3.2  # confeti: segundos emitiendo; luego se apaga solo

var _p: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not Movimiento.intenso():
		visible = false
		set_process(false)
		return
	_rng.randomize()
	for i in range(cantidad):
		_p.append(_nueva(true))


func _nueva(inicial: bool) -> Dictionary:
	var w := maxf(size.x, Tema.ANCHO)
	var h := maxf(size.y, Tema.ALTO)
	if modo == "confeti":
		var col: Color = [Tema.ORO, Tema.ROJO, Tema.CREMA][_rng.randi_range(0, 2)]
		return {"pos": Vector2(_rng.randf_range(0.0, w), _rng.randf_range(-h * 0.3, -10.0) if inicial else -14.0),
			"vel": Vector2(_rng.randf_range(-30.0, 30.0), _rng.randf_range(160.0, 260.0)), "giro": _rng.randf_range(-6.0, 6.0),
			"ang": _rng.randf_range(0.0, TAU), "tam": Vector2(_rng.randf_range(5.0, 8.0), _rng.randf_range(9.0, 13.0)), "color": col}
	var c: Color = Tema.ORO if _rng.randf() < 0.6 else Tema.CREMA
	return {"pos": Vector2(_rng.randf_range(0.0, w), _rng.randf_range(h * 0.35, h) if inicial else h + 6.0),
		"vel": Vector2(_rng.randf_range(-6.0, 6.0), -_rng.randf_range(14.0, 34.0)), "fase": _rng.randf_range(0.0, TAU),
		"tam": _rng.randf_range(1.2, 2.6), "color": c}


func _process(delta: float) -> void:
	_t += delta
	var h := maxf(size.y, Tema.ALTO)
	var vivas: Array[Dictionary] = []
	for p in _p:
		p["pos"] += p["vel"] * delta
		if modo == "confeti":
			p["ang"] = float(p["ang"]) + float(p["giro"]) * delta
			p["vel"].x += sin(_t * 3.0 + float(p["ang"])) * 20.0 * delta
			if p["pos"].y < h + 20.0:
				vivas.append(p)
			elif _t < duracion:
				vivas.append(_nueva(false))
		else:
			p["fase"] = float(p["fase"]) + delta
			vivas.append(p if p["pos"].y > h * 0.2 else _nueva(false))
	_p = vivas
	if _p.is_empty():
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var h := maxf(size.y, Tema.ALTO)
	for p in _p:
		if modo == "confeti":
			draw_set_transform(p["pos"], float(p["ang"]), Vector2.ONE)
			var t: Vector2 = p["tam"]
			draw_rect(Rect2(-t * 0.5, t), p["color"])
		else:
			var y: float = p["pos"].y
			var vida := clampf((y - h * 0.2) / (h * 0.25), 0.0, 1.0) * clampf((h - y) / 60.0, 0.0, 1.0)
			var a := vida * (0.45 + 0.35 * sin(float(p["fase"]) * 2.2))
			var col: Color = p["color"]
			draw_circle(p["pos"], float(p["tam"]) * 2.2, Color(col, a * 0.18))
			draw_circle(p["pos"], float(p["tam"]), Color(col, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
