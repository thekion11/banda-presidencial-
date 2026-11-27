class_name ComiteMapa3D
extends SubViewportContainer
## Vista 3D real del Comité sobre Gran Santiago: terreno con elevaciones reales, calles, río, parques, líneas de Metro y
## edificios de OpenStreetMap. Solo se construye la ventana que rodea al trazado (presupuesto móvil: MultiMesh, sin sombras).
## Exageraciones visuales (documentadas): relieve ×1.8; edificios ×1.6 en planta y ×1.8 en altura, y hasta ×2 más en ventanas grandes.

const FACTOR_LUZ_MOBILE := 0.78  # medido con capturas de los dos renderizadores (docs/QA_VISUAL.md)
const M_POR_U := 100.0  # 1 unidad 3D = 100 m
const REAL_W_M := 26003.0
const REAL_H_M := 21128.0
const EXAG_RELIEVE := 1.8
const MAX_EDIFICIOS := 4500  # menos edificios: el trazado debe destacar sobre el relieve

var semilla: int = 7
var _vp: SubViewport
var _raiz: Node3D
var _cam: Camera3D
var _trazado_nodo: Node3D
var _escena: Node3D
var _ventana: Rect2 = Rect2()
var _centro: Vector2 = Vector2(0.5, 0.5)
var _base_m: float = 500.0
var _angulo: float = 0.7
var _elevacion: float = 1.05
var _distancia: float = 60.0
var _lod: float = 1.0
var _arrastrando: bool = false
var _auto: bool = true


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_vp = SubViewport.new()
	_vp.msaa_3d = Viewport.MSAA_2X
	add_child(_vp)
	_raiz = Node3D.new()
	_vp.add_child(_raiz)
	_cam = Camera3D.new()
	_cam.fov = 36.0
	_cam.near = 0.5
	_cam.far = 800.0
	_vp.add_child(_cam)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#0B2236")  # océano de la paleta del juego (antes celeste, fuera de paleta)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#C9D6E4")
	var k := luz_renderizador()
	env.ambient_light_energy = 0.75 * k
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
	sol.light_energy = 1.05 * k
	sol.light_color = Color("#FFE8C2")
	_vp.add_child(sol)
	_trazado_nodo = Node3D.new()
	_raiz.add_child(_trazado_nodo)


static func luz_renderizador() -> float:
	## El teléfono usa el renderizador Mobile (Vulkan), que ilumina más fuerte que Compatibility (con el que se afinó la
	## escena y se capturan las pruebas): con la misma luz el terreno crema quedaba casi blanco. Se compensa aquí.
	return 1.0 if RenderingServer.get_current_rendering_method() == "gl_compatibility" else FACTOR_LUZ_MOBILE


func _xz(p: Array) -> Vector2:
	return Vector2((float(p[0]) - _centro.x) * REAL_W_M / M_POR_U, (float(p[1]) - _centro.y) * REAL_H_M / M_POR_U)


func _alto(px: float, py: float) -> float:
	return (UrbanoBase.elevacion_m(px, py) - _base_m) / M_POR_U * EXAG_RELIEVE


func _pos(p: Array, extra: float = 0.0) -> Vector3:
	var q := _xz(p)
	return Vector3(q.x, _alto(float(p[0]), float(p[1])) + extra, q.y)


func _material(color: Color, emision: float = 0.0, vertex: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	m.vertex_color_use_as_albedo = vertex
	if emision > 0.0:
		m.no_depth_test = true  # el trazado se ve siempre, aunque sea subterráneo o quede tras un edificio
		m.render_priority = 5
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emision
	return m


func _multi(trans: Array[Transform3D], material: Material, colores: Array[Color] = [], plano: bool = false) -> MultiMeshInstance3D:
	## `plano`: calles, río y Metro son cintas finas de las que solo se ve la cara de arriba: un plano (2 triángulos)
	## en vez de una caja (12) quita ~4/5 de los triángulos de la escena sin cambiar lo que se ve.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colores.is_empty()
	if plano:
		var pl := PlaneMesh.new()
		pl.size = Vector2.ONE
		mm.mesh = pl
	else:
		var caja := BoxMesh.new()
		caja.size = Vector3.ONE
		mm.mesh = caja
	mm.instance_count = trans.size()
	for k in range(trans.size()):
		mm.set_instance_transform(k, trans[k])
		if not colores.is_empty():
			mm.set_instance_color(k, colores[k])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = material
	return mi


func _tramo(a: Vector3, b: Vector3, ancho: float, alto: float) -> Transform3D:
	var dir := b - a
	if dir.length() < 0.0005:
		return Transform3D(Basis().scaled(Vector3(0.0001, 0.0001, 0.0001)), a)
	return Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP).scaled(Vector3(ancho, alto, dir.length())), (a + b) * 0.5)


func _en_ventana(p: Array) -> bool:
	return _ventana.has_point(Vector2(float(p[0]), float(p[1])))


func _terreno() -> MeshInstance3D:
	var nx := 72
	var nz := 58
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verts: Array[Vector3] = []
	var cols: Array[Color] = []
	for j in range(nz + 1):
		for i in range(nx + 1):
			var px := _ventana.position.x + _ventana.size.x * float(i) / nx
			var py := _ventana.position.y + _ventana.size.y * float(j) / nz
			var q := _xz([px, py])
			var e := UrbanoBase.elevacion_m(px, py)
			verts.append(Vector3(q.x, _alto(px, py) - 0.03, q.y))
			cols.append(Color("#DCD3B8").lerp(Color("#B9A98A"), clampf((e - 600.0) / 500.0, 0.0, 1.0)))
	for j in range(nz):
		for i in range(nx):
			var a := j * (nx + 1) + i
			for t in [a, a + 1, a + nx + 1, a + 1, a + nx + 2, a + nx + 1]:
				st.set_color(cols[t])
				st.add_vertex(verts[t])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _material(Color.WHITE, 0.0, true)
	return mi


func _construir(ventana: Rect2) -> void:
	if _escena != null:
		_escena.queue_free()
	_escena = Node3D.new()
	_raiz.add_child(_escena)
	_ventana = ventana
	_centro = ventana.get_center()
	_base_m = UrbanoBase.elevacion_m(_centro.x, _centro.y)
	var d := UrbanoBase.datos()
	var dim_km := maxf(ventana.size.x * REAL_W_M, ventana.size.y * REAL_H_M) / 1000.0
	var lod := clampf(dim_km / 6.0, 1.0, 2.0)  # a mayor ventana, mayor exageración de edificios y menos calles menores
	_lod = lod
	var max_cl := 3 if dim_km <= 8.0 else 2
	_escena.add_child(_terreno())
	var calles: Array[Transform3D] = []
	var col_c: Array[Color] = []
	var ancho: Array[float] = [0.30, 0.30, 0.22, 0.14, 0.0]
	var color_cl: Array[Color] = [Color("#8E846E"), Color("#8E846E"), Color("#A89E86"), Color("#BDB49B"), Color("#CFC7B3")]
	for k in d.get("calles", []):
		var cl := int(k["c"])
		if cl > max_cl:
			continue
		var pl: Array = k["p"]
		for i in range(pl.size() - 1):
			if _en_ventana(pl[i]) or _en_ventana(pl[i + 1]):
				calles.append(_tramo(_pos(pl[i], 0.04), _pos(pl[i + 1], 0.04), ancho[cl], 0.04))
				col_c.append(color_cl[cl])
	_escena.add_child(_multi(calles, _material(Color.WHITE, 0.0, true), col_c, true))
	var rio: Array[Transform3D] = []
	for pl in d.get("rio", []):
		for i in range(pl.size() - 1):
			if _en_ventana(pl[i]) or _en_ventana(pl[i + 1]):
				rio.append(_tramo(_pos(pl[i], 0.05), _pos(pl[i + 1], 0.05), 0.55, 0.06))
	_escena.add_child(_multi(rio, _material(Color("#7FB5D6")), [], true))
	var metro: Array[Transform3D] = []
	var col_m: Array[Color] = []
	for l in d.get("metro", []):
		for via in l["vias"]:
			for i in range(via.size() - 1):
				if _en_ventana(via[i]) or _en_ventana(via[i + 1]):
					metro.append(_tramo(_pos(via[i], 0.09), _pos(via[i + 1], 0.09), 0.32 * _lod, 0.05))
					col_m.append(Color(String(l["color"])))
	_escena.add_child(_multi(metro, _material(Color.WHITE, 0.0, true), col_m, true))
	var blds: Array[Transform3D] = []
	var col_b: Array[Color] = []
	for e in UrbanoBase.edificios_en(ventana, MAX_EDIFICIOS):
		var pisos := int(e["pisos"])
		var h := absi(hash("%d:%d:%d" % [semilla, int(float(e["x"]) * 65535.0), int(float(e["y"]) * 65535.0)])) % 100
		var metros_alto := float(pisos if pisos > 0 else 2 + h % 4) * 3.2
		var alto := metros_alto / M_POR_U * 1.8 * lod
		var w := maxf(float(e["w"]), 6.0) / M_POR_U * 1.6 * lod
		var dd := maxf(float(e["d"]), 6.0) / M_POR_U * 1.6 * lod
		var base := Basis(Vector3.UP, deg_to_rad(float(e["ang"]))).scaled(Vector3(w, alto, dd))
		blds.append(Transform3D(base, _pos([e["x"], e["y"]], alto * 0.5)))
		col_b.append(Color("#CFC7B3") if h % 3 != 0 else Color("#C4B999"))  # tonos apagados para no competir con el trazado
		if pisos >= 10:
			col_b[col_b.size() - 1] = Color("#A9BBCE")
	_escena.add_child(_multi(blds, _material(Color.WHITE, 0.0, true), col_b))
	_distancia = maxf(ventana.size.x * REAL_W_M, ventana.size.y * REAL_H_M) / M_POR_U * 1.05
	_actualizar_camara()


func poner_trazado(trazado: Array, elevada: bool) -> void:
	for h in _trazado_nodo.get_children():
		h.queue_free()
	if trazado.size() < 2:
		return
	var mn := Vector2(1, 1)
	var mx := Vector2.ZERO
	for q in trazado:
		mn = mn.min(Vector2(q[0], q[1]))
		mx = mx.max(Vector2(q[0], q[1]))
	# Ventana cuadrada (en metros) centrada en el trazado: un trazado largo y delgado ya no deja un terreno en cinta.
	var lado_m := maxf((mx.x - mn.x) * REAL_W_M, (mx.y - mn.y) * REAL_H_M) * 1.25 + 3000.0
	var tam := Vector2(lado_m / REAL_W_M, lado_m / REAL_H_M)
	var ven := Rect2((mn + mx) * 0.5 - tam * 0.5, tam).intersection(Rect2(0, 0, 1, 1))
	if _escena == null or not _ventana.encloses(Rect2(mn, mx - mn)):
		_construir(ven)
	var extra := 0.9 if elevada else 0.35
	var tramos: Array[Transform3D] = []
	for k in range(trazado.size() - 1):
		tramos.append(_tramo(_pos(trazado[k], extra), _pos(trazado[k + 1], extra), 1.0 * _lod, 0.4 * _lod))
	_trazado_nodo.add_child(_multi(tramos, _material(Tema.ROJO, 0.4)))
	var estaciones: Array[Transform3D] = []
	for k in range(0, trazado.size(), maxi(1, trazado.size() / 6)):
		estaciones.append(Transform3D(Basis().scaled(Vector3(1.9, 0.7, 1.9) * _lod), _pos(trazado[k], extra + 0.1)))
	_trazado_nodo.add_child(_multi(estaciones, _material(Color("#FBF7EC"), 0.3)))
	if elevada:
		var pil: Array[Transform3D] = []
		for k in range(0, trazado.size(), 3):
			var p := _pos(trazado[k], 0.0)
			pil.append(Transform3D(Basis().scaled(Vector3(0.3, extra, 0.3)), p + Vector3(0, extra * 0.5, 0)))
		_trazado_nodo.add_child(_multi(pil, _material(Color("#8C99A6"))))
	_trazado_nodo.scale = Vector3(1, 0.01, 1)
	_trazado_nodo.position = Vector3.ZERO
	create_tween().tween_property(_trazado_nodo, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _actualizar_camara() -> void:
	var y := sin(_elevacion) * _distancia
	var r := cos(_elevacion) * _distancia
	_cam.position = Vector3(sin(_angulo) * r, y, cos(_angulo) * r)
	_cam.look_at_from_position(_cam.position, Vector3(0, 0, 0), Vector3.UP)


func _process(delta: float) -> void:
	if _auto and not _arrastrando and is_visible_in_tree() and _escena != null:
		_angulo += delta * 0.15
		_actualizar_camara()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_arrastrando = event.pressed
			_auto = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_distancia = maxf(8.0, _distancia * 0.9)
			_actualizar_camara()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_distancia = minf(300.0, _distancia * 1.1)
			_actualizar_camara()
	elif event is InputEventMagnifyGesture:
		_distancia = clampf(_distancia / event.factor, 8.0, 300.0)
		_actualizar_camara()
	elif event is InputEventMouseMotion and _arrastrando:
		_angulo -= event.relative.x * 0.01
		_elevacion = clampf(_elevacion + event.relative.y * 0.006, 0.25, 1.35)
		_actualizar_camara()
