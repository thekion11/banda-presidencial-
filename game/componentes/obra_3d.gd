class_name Obra3D
extends SubViewportContainer
## Hito de obra en 3D real con 5 fases (licitación, faena, estructura, terminación, inauguración). Fase continua para animar.

var fase: float = 1.0:
	set(v):
		fase = v
		_aplicar()
var _vp: SubViewport
var _cam: Camera3D
var _piezas: Dictionary = {}  # nombre -> {nodo, tam, z0, desde, hasta}
var _angulo: float = 0.8
var _arrastrando: bool = false
var _auto: bool = true


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_vp = SubViewport.new()
	_vp.msaa_3d = Viewport.MSAA_2X
	add_child(_vp)
	_cam = Camera3D.new()
	_cam.fov = 34.0
	_vp.add_child(_cam)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#D6E6EF")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#E6EEF5")
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	sol.light_energy = 1.0
	_vp.add_child(sol)
	_construir()
	_orbitar()
	_aplicar()


func _material(color: Color, alfa: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color, alfa)
	m.roughness = 0.9
	if alfa < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _pieza(nombre: String, tam: Vector3, pos: Vector2, z0: float, color: Color, desde: float, hasta: float, alfa: float = 1.0) -> void:
	## Caja que crece en altura entre las fases `desde` y `hasta` (pos = x,z en el suelo; z0 = altura de la base).
	var n := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	n.mesh = bm
	n.material_override = _material(color, alfa)
	_vp.add_child(n)
	_piezas[nombre] = {"nodo": n, "tam": tam, "pos": pos, "z0": z0, "desde": desde, "hasta": hasta}


func _construir() -> void:
	_pieza("terreno", Vector3(8.0, 0.25, 7.0), Vector2(0, 0), -0.25, Color("#DDD3BA"), 0.0, 0.5)
	_pieza("calle", Vector3(6.4, 0.06, 0.9), Vector2(0, 2.6), 0.0, Color("#BDB39A"), 0.0, 0.5)
	_pieza("cartel_poste", Vector3(0.18, 1.6, 0.18), Vector2(-3.2, -2.6), 0.0, Color("#8B5E3C"), 0.0, 0.5)
	_pieza("cartel", Vector3(1.4, 0.7, 0.1), Vector2(-3.2, -2.6), 1.2, Tema.ORO, 0.0, 0.5)
	_pieza("pozo", Vector3(4.6, 0.05, 3.0), Vector2(0, -0.2), 0.0, Color("#B8A98A"), 1.6, 2.6)
	_pieza("grua_mastil", Vector3(0.25, 4.4, 0.25), Vector2(3.1, -2.4), 0.0, Tema.ROJO, 1.7, 2.4)
	_pieza("grua_brazo", Vector3(3.4, 0.18, 0.18), Vector2(1.5, -2.4), 4.3, Tema.ROJO, 1.9, 2.5)
	_pieza("grua_contrapeso", Vector3(0.8, 0.5, 0.5), Vector2(3.6, -2.4), 3.9, Color("#8C99A6"), 1.9, 2.5)  # contrapeso: da lectura de grúa torre
	_pieza("grua_cable", Vector3(0.05, 1.4, 0.05), Vector2(0.4, -2.4), 2.9, Color("#3A4652"), 2.0, 2.5)
	for i in range(3):
		for j in range(2):
			_pieza("col_%d_%d" % [i, j], Vector3(0.34, 3.0, 0.34), Vector2(-1.8 + float(i) * 1.8, -1.1 + float(j) * 2.0), 0.0, Color("#C9BFA5"), 2.6, 3.6)
	_pieza("losa", Vector3(5.0, 0.3, 2.9), Vector2(0, 0.0), 3.0, Color("#D8CFB8"), 3.2, 3.9)
	_pieza("muro_fondo", Vector3(4.8, 2.8, 0.14), Vector2(0, -1.4), 0.0, Color("#9CC7DD"), 3.7, 4.6, 0.62)
	_pieza("muro_lado", Vector3(0.14, 2.8, 2.8), Vector2(-2.4, 0), 0.0, Color("#9CC7DD"), 3.8, 4.6, 0.62)
	_pieza("acceso", Vector3(1.6, 0.16, 0.8), Vector2(-0.8, 1.7), 0.0, Color("#EFEAD9"), 3.9, 4.6)
	_pieza("techo", Vector3(5.2, 0.4, 3.1), Vector2(0, 0), 3.3, Color("#F2EEE2"), 4.5, 5.0)
	_pieza("mastil", Vector3(0.08, 2.6, 0.08), Vector2(2.4, 1.5), 3.7, Color("#EEEEEE"), 4.5, 5.0)
	_pieza("bandera", Vector3(0.9, 0.5, 0.05), Vector2(2.9, 1.5), 5.8, Tema.ROJO, 4.7, 5.0)
	_pieza("cinta", Vector3(1.6, 0.06, 0.06), Vector2(-0.8, 2.4), 0.4, Tema.ROJO, 4.8, 5.0)


func _aplicar() -> void:
	for nombre in _piezas.keys():
		var d: Dictionary = _piezas[nombre]
		var f := clampf((fase - float(d["desde"])) / maxf(0.001, float(d["hasta"]) - float(d["desde"])), 0.0, 1.0)
		if nombre.begins_with("cartel"):
			f = 1.0 - clampf((fase - 1.6) / 0.6, 0.0, 1.0)  # el cartel se retira cuando empieza la faena
		var tam: Vector3 = d["tam"]
		var alto := maxf(0.001, tam.y * f)
		var n: MeshInstance3D = d["nodo"]
		n.scale = Vector3(tam.x, alto, tam.z)
		n.position = Vector3(d["pos"].x, float(d["z0"]) + alto * 0.5, d["pos"].y)
		n.visible = f > 0.01
	if _cam != null:
		_orbitar()


func ir_a(f: int) -> void:
	if not Movimiento.activo():  # sin animaciones, salta directo a la fase
		fase = float(f)
		return
	create_tween().tween_property(self, "fase", float(f), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func reproducir() -> void:
	fase = 1.0
	create_tween().tween_property(self, "fase", 5.0, 5.0).set_trans(Tween.TRANS_LINEAR)


func _orbitar() -> void:
	_cam.position = Vector3(sin(_angulo) * 15.5, 9.4, cos(_angulo) * 15.5)
	_cam.look_at_from_position(_cam.position, Vector3(0, 1.2, 0), Vector3.UP)


func _process(delta: float) -> void:
	if _auto and not _arrastrando and is_visible_in_tree():
		_angulo += delta * 0.22
		_orbitar()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_arrastrando = event.pressed
		_auto = false
	elif event is InputEventMouseMotion and _arrastrando:
		_angulo -= event.relative.x * 0.012
		_orbitar()
