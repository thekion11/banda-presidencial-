extends SceneTree
## Botones que no hacen nada: en la pantalla del día (campaña y gobierno) cada botón visible y habilitado, al pulsarlo, cambia algo observable
## (estado del motor, pantalla, textos visibles, cantidad de nodos visibles o el tema de algún control). Un botón habilitado sin efecto es un fallo.
## Cada botón se prueba en una partida nueva. Respalda y restaura los archivos de usuario.

const ARCHIVOS := ["guardado.json", "guardado.cache", "guardado.bak", "ultima_config.json", "guardado_descartado.json"]
var _fallos := 0
var _probados := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _botones(raiz: Node) -> Array[Button]:
	var r: Array[Button] = []
	for b in raiz.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree() and not (b as Button).disabled and (b as Button).get_global_rect().size.x > 2.0:
			r.append(b)
	return r


func _foto(main: Node) -> String:
	var p: Node = main._pantalla
	var partes: Array[String] = [str(p.get_instance_id()), main.motor.estado.calcular_huella()]
	var vis := 0
	for n in p.find_children("*", "Control", true, false):
		if (n as Control).is_visible_in_tree():
			vis += 1
			if n is Label:
				partes.append((n as Label).text)
			elif n is Button:
				partes.append((n as Button).text + str((n as Button).disabled))
	partes.append(str(vis))
	var capa: Node = p.get("_capa")
	if capa != null:
		partes.append(str(capa.get_child_count()))
	return "|".join(partes)


func _nuevo(datos: Dictionary, etapa: String) -> Node:
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	if etapa == "campana":
		main._repetir_ultima()
	else:
		main.datos = datos
		main.motor = AyudaV2.gobierno(datos, 31)
		main.mostrar_dia()
	await process_frame
	await process_frame
	return main


func _correr() -> void:
	for a in ARCHIVOS:
		if FileAccess.file_exists("user://" + a):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a), ProjectSettings.globalize_path("user://" + a + ".bak_botones"))
	Tutorial.ruta = "user://preferencias_botones.json"
	Movimiento.forzado = 1
	var datos := Datos.cargar_todo()
	var args := OS.get_cmdline_user_args()
	for etapa in ["campana", "gobierno"]:
		if args.size() > 0 and args[0] != etapa:
			continue
		var base: Node = await _nuevo(datos, etapa)
		var n := _botones(base._pantalla).size()
		var nombres: Array[String] = []
		for b in _botones(base._pantalla):
			nombres.append((b as Button).text.replace("\n", " ").left(30) + "@" + str((b as Button).get_path()).get_slice("/", 6))
		base.queue_free()
		await process_frame
		for i in range(n):
			if args.size() > 1 and i != int(args[1]):
				continue
			var main: Node = await _nuevo(datos, etapa)
			var bs := _botones(main._pantalla)
			if i >= bs.size():
				main.queue_free()
				continue
			var antes := _foto(main)
			var b := bs[i]
			var dia0: Node = main._pantalla
			if dia0 is PantallaDia and not dia0._zona_panel.visible and dia0._nav.is_ancestor_of(b) and dia0._nav.find_children("*", "Button", true, false)[0] == b:
				continue  # la pestaña «Mapa» ya activa: pulsarla de nuevo es idempotente (el mapa ya está abierto)
			var txt := b.text.replace("\n", " ").left(30)
			var ruta := str(b.get_path()).substr(str(main._pantalla.get_path()).length())
			var caja := str(b.get_global_rect())
			_probados += 1
			if b.toggle_mode:
				b.button_pressed = not b.button_pressed
			b.pressed.emit()
			for _k in range(3):
				await process_frame
			if is_instance_valid(main._pantalla):
				_check(_foto(main) != antes, "%s: el botón %d «%s» (%s, %s) está habilitado y no cambia nada" % [etapa, i, txt, ruta, caja])
			main.queue_free()
			await process_frame
	Movimiento.forzado = -1
	for a in ARCHIVOS:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + a))
		if FileAccess.file_exists("user://" + a + ".bak_botones"):
			DirAccess.rename_absolute(ProjectSettings.globalize_path("user://" + a + ".bak_botones"), ProjectSettings.globalize_path("user://" + a))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	if _fallos == 0:
		print("test_botones_activos: OK (%d botones)" % _probados)
	quit(1 if _fallos > 0 else 0)
