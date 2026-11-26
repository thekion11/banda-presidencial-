extends SceneTree
## Estados vacíos y de error: cada uno dice qué pasa y ofrece una acción viable, nunca un «no» seco (CLAUDE.md §4.6).
## 0 cartas en la mano, 0 movimientos (en campaña y en gobierno), guardado dañado y datos del juego faltantes.

var _fallos := 0


func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	_correr.call_deferred()


func _cuadros(n: int) -> void:
	for i in range(n):
		await process_frame


func _textos(n: Node) -> String:
	var t: PackedStringArray = []
	for l in n.find_children("*", "Label", true, false):
		t.append((l as Label).text)
	for l in n.find_children("*", "RichTextLabel", true, false):
		t.append((l as RichTextLabel).get_parsed_text())
	return "\n".join(t)


func _correr() -> void:
	Movimiento.forzado = 0
	Tutorial.ruta = "user://preferencias_estados.json"
	Tutorial.marcar_visto()
	var main: Node = load("res://game/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var resp: Array[Dictionary] = []
	for p in main.datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	main.motor = Partida.crear(main.datos, 13, GeneradorPartido.construir_partido("E", "E", "metropolitana", resp, main.datos["ideologia"]))
	var est: EstadoSimulacion = main.motor.estado
	main.mostrar_dia()
	await _cuadros(2)
	var dia: PantallaDia = main._pantalla
	# 0 movimientos en campaña: no se puede delegar, la acción viable es terminar la semana
	est.pa_actual = 0
	dia._refrescar()
	await _cuadros(1)
	var corr := dia._lbl_corrector.get_parsed_text()
	_check(corr.contains("Sin movimientos") and corr.contains("termina la semana"), "sin movimientos en campaña se explica qué hacer (%s)" % corr)
	_check(dia._btn_jugar.text == "Siguiente semana" and not dia._btn_jugar.disabled, "sin movimientos el botón principal avanza la semana")
	# 0 movimientos en gobierno: delegar sigue siendo posible
	est.etapa = "gobierno"
	dia._refrescar()
	await _cuadros(1)
	corr = dia._lbl_corrector.get_parsed_text()
	_check(corr.contains("delega esta carta"), "sin movimientos en gobierno se ofrece delegar (%s)" % corr)
	# crisis: con la aprobación bajo el umbral, la cabecera cuenta las semanas que quedan antes de la caída
	var din: Dictionary = main.datos["leyes"]["dinamica"]
	est.indicadores["aprobacion"] = float(din["umbral_crisis_aprobacion"]) - 1.0
	est.semanas_en_crisis = 1
	dia._refrescar()
	var quedan := int(din["semanas_crisis_para_caida"]) - 1
	_check(dia._r["fecha"].text == "Crisis: caes en %d semanas" % quedan, "la cabecera muestra la cuenta regresiva de la crisis (%s)" % dia._r["fecha"].text)
	est.indicadores["aprobacion"] = 50.0
	dia._refrescar()
	_check(not dia._r["fecha"].text.begins_with("Crisis"), "sin crisis la cabecera vuelve a la fecha")
	# corte de legado: cuánto costarán las promesas pendientes y cuántas semanas faltan
	est.promesas_campana.clear()
	for k in range(3):
		est.promesas_campana.append({"titulo": "Promesa %d" % k, "cumplida": false, "carta_id": "x%d" % k})
	est.turno_actual = 100
	var lg: Dictionary = main.datos["leyes"]["legado"]
	var corte := Barras.legado(est, lg)
	var cap := Tema.dec(float(lg["penal_capital"]) * 3.0)
	_check(int(corte.get("faltan", -1)) == int(lg["turnos_evaluacion"][0]) - 100 and String(corte.get("texto", "")).contains("−" + cap), "el corte de legado dice cuánto cuesta y cuándo (%s)" % corte)
	var panel := PanelesDia.congreso(main.motor)
	root.add_child(panel)
	await _cuadros(1)
	_check(_textos(panel).contains("Corte de legado"), "el panel de metas de legado avisa del corte")
	panel.queue_free()
	est.promesas_campana.clear()
	# 0 cartas: la zona de la mano lo dice y el Corrector propone terminar la semana
	est.mano.clear()
	dia._refrescar()
	await _cuadros(2)
	var en_mano := _textos(dia._mano)
	_check(en_mano.contains("Sin cartas") and en_mano.contains("Termina la semana"), "la mano vacía muestra qué hacer (%s)" % en_mano)
	_check(dia._lbl_corrector.get_parsed_text().contains("antes de terminar la semana"), "el Corrector sugiere qué revisar con la mano vacía")
	_check(not dia._btn_jugar.disabled, "con la mano vacía se puede terminar la semana")
	# guardado dañado con respaldo bueno: se recupera la partida de hace un momento (revisión de código #1 del motor)
	main.guardar()  # primer guardado
	est.pa_actual = 4
	main.guardar()  # el anterior queda como respaldo
	for parte in [0, 40]:  # truncado a 0 bytes y a menos de la mitad
		var bueno := FileAccess.get_file_as_string(main.RUTA_GUARDADO)
		var t := FileAccess.open(main.RUTA_GUARDADO, FileAccess.WRITE)
		t.store_string(bueno.left(bueno.length() * parte / 100))
		t.close()
		main.continuar_guardado()
		await _cuadros(2)
		_check(main._pantalla is PantallaDia and main.motor != null, "con el guardado truncado al %d %% se recupera el respaldo" % parte)
		_check(main._pantalla is PantallaDia and String(main._pantalla._toast.text).begins_with("Recuperamos tu partida"), "al recuperar el respaldo se avisa")
		if not (main._pantalla is PantallaDia):  # sin recuperación el resto de la prueba no tiene pantalla del día: termina aquí
			quit(1)
			return
		main.guardar()
	dia = main._pantalla
	est = main.motor.estado
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://guardado_descartado.json"))
	# guardado dañado sin respaldo: se descarta y el menú lo explica con la acción viable
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_RESPALDO))
	var f := FileAccess.open(main.RUTA_GUARDADO, FileAccess.WRITE)
	f.store_string("{\"semilla\": 1, \"entradas\": \"roto\"}")
	f.close()
	main.continuar_guardado()
	await _cuadros(2)
	var menu := _textos(main._pantalla)
	_check(main._pantalla is PantallaMenu and menu.contains("Empieza una partida nueva"), "un guardado dañado vuelve al menú con aviso y acción")
	_check(not FileAccess.file_exists(main.RUTA_GUARDADO), "el guardado dañado se aparta y «Continuar» no reaparece fallando")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://guardado_descartado.json"))
	# «Partida rápida» con una última configuración dañada: se descarta y se juega con el partido por defecto
	var u := FileAccess.open(main.RUTA_ULTIMA, FileAccess.WRITE)
	u.store_string("{\"indicadores_iniciales\": \"roto\", \"nombre\": 3}")
	u.close()
	main._repetir_ultima()
	await _cuadros(2)
	_check(main.motor != null and String(main.motor.estado.partido.get("sigla", "")) == "MCA", "una última configuración dañada cae al partido por defecto")
	_check(main._pantalla is PantallaDia, "la partida rápida arranca igual con el partido por defecto")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_ULTIMA))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.RUTA_GUARDADO))
	# datos faltantes: mensaje claro, qué falta y qué hacer
	main.mostrar_error_datos(["cartas"])
	await _cuadros(1)
	var err := _textos(main)
	_check(err.contains("No se pudieron cargar los datos") and err.contains("cartas.json") and err.contains("reinstala"), "sin datos se dice qué falta y qué hacer")
	var cerrar: Array = main.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == "Cerrar el juego")
	_check(cerrar.size() == 1, "sin datos hay un botón para cerrar")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Tutorial.ruta))
	if _fallos == 0:
		print("ESTADOS OK")
	quit(1 if _fallos > 0 else 0)
