extends SceneTree
## Hoja de contacto (informe, QA visual): captura cada paso del recorrido de pantallas (RecorridoUI) con la ventana real
## del tamaño que se pase a xvfb (--resolution), con letra normal o grande. Guarda un PNG por paso; tools/hoja_contacto.py
## los junta en docs/comparacion/hoja_contacto_*.png.
## Uso: xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 360x640 -s tests/hoja_contacto.gd -- /tmp/hc/360x640_normal 0 360x640

var _dir := "/tmp/hoja_contacto"
var _n := 0


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_dir = a[0]
	if a.size() > 1:
		Ajustes.escala_prueba = float(a[1])
	if a.size() > 2:  # Godot achica la ventana a la proporción del proyecto si no cabe: se fija a mano
		var wh := a[2].split("x")
		DisplayServer.window_set_size(Vector2i(int(wh[0]), int(wh[1])))
	DirAccess.make_dir_recursive_absolute(_dir)
	_correr.call_deferred()


func _correr() -> void:
	for i in range(3):
		await process_frame
	await RecorridoUI.recorrer(self, func(_main: Node, paso: String) -> void:
		_n += 1
		root.get_texture().get_image().save_png("%s/%02d_%s.png" % [_dir, _n, paso.replace(" ", "_").replace("›", "-")]))
	print("hoja de contacto: %d pasos en %s" % [_n, _dir])
	quit()
