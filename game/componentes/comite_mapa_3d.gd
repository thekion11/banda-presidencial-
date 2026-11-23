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
var _distancia: float = 21.0
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


func _ancho() -> float:
	return LADO * UrbanoBase.aspecto()


func _mundo(p: Array, y: float = 0.0) -> Vector3:
	return Vector3((float(p[0]) - 0.5) * _ancho(), y, (float(p[1]) - 0.5) * LADO)


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


func _multi(transformaciones: Array[Transform3D], material: Material, colores: Array[Color] = []) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colores.is_empty()
	var caja := BoxMesh.new()
	caja.size = Vector3.ONE
	mm.mesh = caja
	mm.instance_count = transformaciones.size()
	for k in range(transformaciones.size()):
		mm.set_instance_transform(k, transformaciones[k])
		if not colores.is_empty():
			mm.set_instance_color(k, colores[k])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = material
	return mi


func _tramo(a: Vector3, b: Vector3, ancho: float, alto: float) -> Transform3D:
	var dir := b - a
	if dir.length() < 0.0005:
		return Transform3D(Basis().scaled(Vector3(0.0001, 0.0001, 0.0001)), a)  # tramo degenerado: invisible
	var basis := Basis.looking_at(dir.normalized(), Vector3.UP).scaled(Vector3(ancho, alto, dir.length()))
	return Transform3D(basis, (a + b) * 0.5)


func _construir_ciudad() -> void:
	var d := UrbanoBase.datos()
	var w := _ancho()
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(w * 1.15, LADO * 1.15)
	suelo.mesh = pm
	suelo.material_override = _material(Color("#E7E0CF"))
	suelo.position = Vector3(0, -0.02, 0)
	_raiz.add_child(suelo)
	if d.is_empty():
		return
	var ocupado: Dictionary = {}  # celdas de edificio bloqueadas por calles, río o parques
	var nx := 150  # rejilla fina de ocupación por calles; los edificios usan celdas de 2×2
	var nz := 122
	var marcar := func(a: Array, b: Array) -> void:
		var n := int(maxf(absf(float(b[0]) - float(a[0])) * nx, absf(float(b[1]) - float(a[1])) * nz)) + 1
		for k in range(n + 1):
			var t := float(k) / float(n)
			var cx := int((float(a[0]) + (float(b[0]) - float(a[0])) * t) * nx)
			var cz := int((float(a[1]) + (float(b[1]) - float(a[1])) * t) * nz)
			ocupado[Vector2i(cx, cz)] = true
	var calles: Array[Transform3D] = []
	var col_calles: Array[Color] = []
	var ancho_cl: Array[float] = [0.09, 0.09, 0.065, 0.04, 0.0]
	var color_cl: Array[Color] = [Color("#9C927C"), Color("#9C927C"), Color("#B3A98F"), Color("#C4BBA3"), Color("#D4CCB8")]
	for k in d["calles"]:
		var cl := int(k["c"])
		var pl: Array = k["p"]
		for i in range(pl.size() - 1):
			if cl <= 3:
				marcar.call(pl[i], pl[i + 1])
			if cl <= 3:
				calles.append(_tramo(_mundo(pl[i], 0.01), _mundo(pl[i + 1], 0.01), ancho_cl[cl], 0.02))
				col_calles.append(color_cl[cl])
	var mat_c := _material(Color.WHITE)
	mat_c.vertex_color_use_as_albedo = true
	_raiz.add_child(_multi(calles, mat_c, col_calles))
	var rio_t: Array[Transform3D] = []
	for pl in d["rio"]:
		for i in range(pl.size() - 1):
			marcar.call(pl[i], pl[i + 1])
			rio_t.append(_tramo(_mundo(pl[i], 0.015), _mundo(pl[i + 1], 0.015), 0.16, 0.03))
	_raiz.add_child(_multi(rio_t, _material(Color("#8CC4E8"))))
	var parques_t: Array[Transform3D] = []
	var parques_poly: Array[PackedVector2Array] = []
	for pk in d["parques"]:
		var poly := PackedVector2Array()
		var minp := Vector2(1, 1)
		var maxp := Vector2.ZERO
		for q in pk:
			poly.append(Vector2(q[0], q[1]))
			minp = minp.min(Vector2(q[0], q[1]))
			maxp = maxp.max(Vector2(q[0], q[1]))
		parques_poly.append(poly)
		var cc := (minp + maxp) * 0.5
		var tam := (maxp - minp) * Vector2(w, LADO)
		parques_t.append(Transform3D(Basis().scaled(Vector3(tam.x * 0.85, 0.03, tam.y * 0.85)), _mundo([cc.x, cc.y], 0.012)))
	_raiz.add_child(_multi(parques_t, _material(Color("#A9CF9A"))))
	# edificios: solo en celdas libres, más altos y densos hacia el centro
	var centro := Vector2(0.52, 0.43)
	var blds: Array[Transform3D] = []
	var col_b: Array[Color] = []
	for cz in range(0, nz - 1, 2):
		for cx in range(0, nx - 1, 2):
			var libres := 0
			for dz in range(2):
				for dx in range(2):
					if not ocupado.has(Vector2i(cx + dx, cz + dz)):
						libres += 1
			if libres < 3:
				continue
			var p := Vector2((float(cx) + 1.0) / nx, (float(cz) + 1.0) / nz)
			var dist := p.distance_to(centro)
			var h := absi(hash("%d:%d:%d" % [semilla, cx, cz])) % 100
			if float(h) / 100.0 > clampf(0.85 - dist * 1.1, 0.12, 0.85):
				continue
			var en_parque := false
			for poly in parques_poly:
				if Geometry2D.is_point_in_polygon(p, poly):
					en_parque = true
					break
			if en_parque:
				continue
			var alto := (0.10 + float(h % 13) * 0.025) * clampf(1.6 - dist * 2.2, 0.35, 1.6)
			var lado := w / float(nx) * 2.0 * 0.8
			blds.append(Transform3D(Basis().scaled(Vector3(lado, alto, lado * 1.05)), _mundo([p.x, p.y], alto * 0.5)))
			col_b.append(Color("#F2EEE4") if h % 3 != 0 else Color("#E8D9A8"))
	var mat_b := _material(Color.WHITE)
	mat_b.vertex_color_use_as_albedo = true
	_raiz.add_child(_multi(blds, mat_b, col_b))


func poner_trazado(trazado: Array, elevada: bool) -> void:
	for h in _trazado_nodo.get_children():
		h.queue_free()
	if trazado.size() < 2:
		return
	var alto := 0.7 if elevada else 0.08
	var tramos: Array[Transform3D] = []
	for k in range(trazado.size() - 1):
		tramos.append(_tramo(_mundo(trazado[k], alto), _mundo(trazado[k + 1], alto), 0.16, 0.1))
	_trazado_nodo.add_child(_multi(tramos, _material(Tema.ROJO, 0.35)))
	if elevada:
		var pilares: Array[Transform3D] = []
		for k in range(0, trazado.size(), 3):
			var e := _mundo(trazado[k], 0.0)
			pilares.append(Transform3D(Basis().scaled(Vector3(0.1, alto, 0.1)), e + Vector3(0, alto * 0.5, 0)))
		_trazado_nodo.add_child(_multi(pilares, _material(Color("#8C99A6"))))
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
