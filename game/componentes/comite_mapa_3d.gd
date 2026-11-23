class_name ComiteMapa3D
extends SubViewportContainer
## Vista 3D real del Comité: manzanas con altura, río, trazado (elevado o a nivel) y cámara orbitable.
## Presupuesto móvil: una sola MultiMesh para los edificios, sin sombras, materiales sin texturas.

const CELDAS := 9
const LADO := 10.0

var semilla: int = 7
var _vp: SubViewport
var _raiz: Node3D
var _cam: Camera3D
var _trazado_nodo: Node3D
var _angulo: float = 0.7
var _elevacion: float = 0.72
var _distancia: float = 19.0
var _arrastrando: bool = false
var _auto: bool = true


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_vp = SubViewport.new()
	_vp.msaa_3d = Viewport.MSAA_2X
	_vp.transparent_bg = false
	add_child(_vp)
	_raiz = Node3D.new()
	_vp.add_child(_raiz)
	_cam = Camera3D.new()
	_cam.fov = 38.0
	_vp.add_child(_cam)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#A9D2E8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#BFD3E6")
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-52.0, -35.0, 0.0)
	sol.light_energy = 1.05
	sol.light_color = Color("#FFE8C2")
	_vp.add_child(sol)
	_trazado_nodo = Node3D.new()
	_raiz.add_child(_trazado_nodo)
	_construir_ciudad()
	_actualizar_camara()


func _h(i: int, j: int) -> int:
	return absi(hash("%d:%d:%d" % [semilla, i, j])) % 100


func _material(color: Color, emision: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if emision > 0.0:
		m.no_depth_test = true  # el trazado se ve siempre, aunque sea subterráneo o quede tras un edificio
		m.render_priority = 5
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emision
	return m


func _construir_ciudad() -> void:
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(LADO * 1.25, LADO * 1.25)
	suelo.mesh = pm
	suelo.material_override = _material(Color("#2F8A5E"))
	suelo.position = Vector3(0, -0.02, 0)
	_raiz.add_child(suelo)
	var rio := MeshInstance3D.new()
	var rm := PlaneMesh.new()
	rm.size = Vector2(LADO * 1.25, LADO * 0.09)
	rio.mesh = rm
	rio.material_override = _material(Color("#8CC4E8"))
	rio.position = Vector3(0, 0.0, (0.625 - 0.5) * LADO)
	_raiz.add_child(rio)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var caja := BoxMesh.new()
	caja.size = Vector3(1, 1, 1)
	mm.mesh = caja
	var transformaciones: Array[Transform3D] = []
	var colores: Array[Color] = []
	var c := LADO / float(CELDAS)
	for j in range(CELDAS):
		for i in range(CELDAS):
			var cz := (float(j) + 0.5) * c - LADO * 0.5
			if absf(cz - (0.625 - 0.5) * LADO) < LADO * 0.07:
				continue  # el río corta la trama
			var dist := Vector2(float(i) - 4.0, float(j) - 4.0).length()
			var alto := (0.18 + float(_h(i, j)) * 0.010) * clampf(1.5 - dist * 0.16, 0.25, 1.5)
			var color := Color("#F2EEE4") if _h(i, j) % 3 != 0 else Color("#E8D9A8")
			if dist > 4.2:
				color = Color("#C9E4D2")
				alto *= 0.4
			var t := Transform3D(Basis().scaled(Vector3(c * 0.76, alto, c * 0.76)), Vector3((float(i) + 0.5) * c - LADO * 0.5, alto * 0.5, cz))
			transformaciones.append(t)
			colores.append(color)
	mm.instance_count = transformaciones.size()
	for k in range(transformaciones.size()):
		mm.set_instance_transform(k, transformaciones[k])
		mm.set_instance_color(k, colores[k])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := _material(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	mi.material_override = mat
	_raiz.add_child(mi)


func _mundo(p: Array, y: float = 0.0) -> Vector3:
	return Vector3((float(p[0]) - 0.5) * LADO, y, (float(p[1]) - 0.5) * LADO)


func poner_trazado(trazado: Array, elevada: bool) -> void:
	for h in _trazado_nodo.get_children():
		h.queue_free()
	if trazado.size() < 2:
		return
	var alto := 0.9 if elevada else 0.12
	var rojo := _material(Tema.ROJO, 0.35)
	for k in range(trazado.size() - 1):
		var a := _mundo(trazado[k], alto)
		var b := _mundo(trazado[k + 1], alto)
		var seg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.22, 0.12, a.distance_to(b) + 0.22)
		seg.mesh = bm
		seg.material_override = rojo
		_trazado_nodo.add_child(seg)
		seg.position = (a + b) * 0.5
		seg.look_at_from_position((a + b) * 0.5, b, Vector3.UP)
	var blanco := _material(Color("#FBF7EC"))
	for k in range(trazado.size()):
		var e := _mundo(trazado[k], alto)
		var cil := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.24
		cm.bottom_radius = 0.24
		cm.height = 0.2
		cil.mesh = cm
		cil.material_override = blanco
		_trazado_nodo.add_child(cil)
		cil.position = e + Vector3(0, 0.08, 0)
		if elevada:
			var pilar := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.14, alto, 0.14)
			pilar.mesh = pm
			pilar.material_override = _material(Color("#8C99A6"))
			_trazado_nodo.add_child(pilar)
			pilar.position = Vector3(e.x, alto * 0.5, e.z)
	_trazado_nodo.scale = Vector3(1, 0.01, 1)  # crece desde el suelo
	create_tween().tween_property(_trazado_nodo, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _actualizar_camara() -> void:
	var y := sin(_elevacion) * _distancia
	var r := cos(_elevacion) * _distancia
	_cam.position = Vector3(sin(_angulo) * r, y, cos(_angulo) * r)
	_cam.look_at_from_position(_cam.position, Vector3(0, 0.3, 0), Vector3.UP)


func _process(delta: float) -> void:
	if _auto and not _arrastrando and is_visible_in_tree():
		_angulo += delta * 0.18
		_actualizar_camara()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_arrastrando = event.pressed
		_auto = false
	elif event is InputEventMouseMotion and _arrastrando:
		_angulo -= event.relative.x * 0.01
		_elevacion = clampf(_elevacion + event.relative.y * 0.006, 0.25, 1.15)
		_actualizar_camara()
