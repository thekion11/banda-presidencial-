extends SceneTree
## Regresión visual: captura con ventana real (1×) las pantallas clave del recorrido (RecorridoUI) para compararlas con
## las de referencia en tests/golden/. Esconde los avisos que se van solos (su duración depende de la velocidad de la
## máquina) para que la captura no dependa del tiempo. Lo llama tools/regresion_visual.py; no se corre a mano.
## Uso: xvfb-run -a -s "-screen 0 1400x1400x24" godot --path . --rendering-method gl_compatibility --resolution 360x640 -s tests/golden_capturar.gd -- <carpeta> 360x640

const CLAVE := ["menú", "afiliación", "test ideológico", "gabinete (configuración)", "día", "panel congreso", "panel nacion", "mapa urbano", "votación", "elección", "fin de partida"]

var _dir := "/tmp/golden"


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_dir = a[0]
	if a.size() > 1:
		var wh := a[1].split("x")
		DisplayServer.window_set_size(Vector2i(int(wh[0]), int(wh[1])))
	DirAccess.make_dir_recursive_absolute(_dir)
	for r in ["user://guardado.json", "user://guardado.bak", "user://guardado.cache", "user://ultima_config.json"]:  # el menú cambia si hay partida guardada
		DirAccess.remove_absolute(ProjectSettings.globalize_path(r))
	_correr.call_deferred()


static func _ascii(paso: String) -> String:
	var r := paso.replace(" ", "_").replace("(", "").replace(")", "")
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"]]:
		r = r.replace(par[0], par[1])
	return r


func _correr() -> void:
	for i in range(3):
		await process_frame
	var hechas := [0]
	await RecorridoUI.recorrer(self, func(main: Node, paso: String) -> void:
		if not CLAVE.has(paso):
			return
		for t in main.find_children("*", "Toast", true, false):
			(t as Control).visible = false
		await process_frame
		await process_frame
		root.get_texture().get_image().save_png("%s/%s.png" % [_dir, _ascii(paso)])
		hechas[0] += 1)
	print("golden: %d capturas en %s" % [hechas[0], _dir])
	quit()
