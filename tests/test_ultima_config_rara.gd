extends SceneTree
## «Partida rápida» con un ultima_config.json de nombre o sigla raros pero válidos (300 caracteres, saltos de línea, BBCode con %s/{0}, solo espacios, tildes):
## el partido pasa la validación, la pantalla del día y el telón al cerrar la semana se muestran sin textos fuera de los 390 px ni errores de script.
## Respalda y restaura los archivos de usuario.

const ARCHIVOS := ["guardado.json", "guardado.cache", "ultima_config.json", "guardado_descartado.json"]
var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _fuera(raiz: Node, ctx: String) -> void:
	for n in raiz.find_children("*", "Control", true, false):
		if not (n is Label or n is Button) or not (n as Control).is_visible_in_tree():
			continue
		var t: String = (n as Label).text if n is Label else (n as Button).text
		if t.strip_edges() == "":
			continue
		var p := n.get_parent()
		var en_scroll := false
		while p != null:
			if p is ScrollContainer:
				en_scroll = true
			p = p.get_parent()
		var r := (n as Control).get_global_rect()
		_check(en_scroll or (r.position.x >= -0.5 and r.end.x <= Tema.ANCHO + 0.5), "%s: «%s» se sale de la pantalla (%s)" % [ctx, t.replace("\n", " ").left(40), r])


func _correr() -> void:
	for a in ARCHIVOS:
		if FileAccess.file_exists("user://" + a):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a), ProjectSettings.globalize_path("user://" + a + ".bak_rara"))
	Tutorial.ruta = "user://preferencias_rara.json"
	Movimiento.forzado = 1
	var datos := Datos.cargar_todo()
	var casos := [["x".repeat(300), "ABCDEFGHIJ"], ["Línea\nnueva", "A\nB"], ["[b]neg[/b] %s {0}", "%d"], ["   ", ""], ["Ñandú Ünico", "ÑÜ"]]
	var n := 0
	for c in casos:
		n += 1
		var ctx := "caso %d" % n
		var resp: Array[Dictionary] = []
		for q in datos["ideologia"]["preguntas"]:
			resp.append(q["opciones"][1])
		var base := GeneradorPartido.construir_partido_afiliado("propio", {}, c[0], c[1], "metropolitana", resp, datos["ideologia"], datos["leyes"]["afiliacion"])
		GeneradorPartido.aplicar_habilidad(base, String(datos["leyes"]["habilidades"]["defecto"]), String(datos["leyes"]["habilidades"]["colores"][0]), datos["leyes"]["habilidades"])
		_check(ValidarGuardado.partido_valido(base), ctx + ": el partido raro debería ser válido")
		var f := FileAccess.open("user://ultima_config.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(base))
		f.close()
		var main: Node = load("res://game/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		main._repetir_ultima()
		await process_frame
		await process_frame
		_check(main._pantalla is PantallaDia, ctx + ": no se llegó a la pantalla del día")
		if main._pantalla is PantallaDia:
			_fuera(main._pantalla, ctx + " (día)")
			var dia: Node = main._pantalla
			dia._btn_jugar.pressed.emit()
			if is_instance_valid(dia) and dia._confirmar_fin:
				dia._btn_jugar.pressed.emit()
			for _i in range(4):
				await process_frame
			_check(is_instance_valid(main._pantalla), ctx + ": tras terminar la semana no hay pantalla")
			if is_instance_valid(main._pantalla):
				_fuera(main._pantalla, ctx + " (tras la semana)")
		main.queue_free()
		await process_frame
	Movimiento.forzado = -1
	for a in ARCHIVOS:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + a))
		if FileAccess.file_exists("user://" + a + ".bak_rara"):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a + ".bak_rara"), ProjectSettings.globalize_path("user://" + a))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	if _fallos == 0:
		print("test_ultima_config_rara: OK")
	quit(1 if _fallos > 0 else 0)
