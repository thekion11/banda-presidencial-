class_name PanelInternos
extends RefCounted
## Movimientos internos (DISENO_V2 §6, solo gobierno): buscar metas, ajustar índices sectoriales, reducir errores
## de ejecución y acelerar obras. Presupuesto propio: `estado.internos_actual` (3 por turno).


static func _boton(texto: String, fondo: Color, accion: Callable, color: Color = Tema.TEXTO) -> Button:
	var b := Tema.boton(texto, fondo, color, 12, 44)
	b.pressed.connect(accion)
	return b


static func crear(motor: MotorTurno, avisar: Callable, cambio: Callable) -> Control:
	var est := motor.estado
	var cfg: Dictionary = motor.catalogo_leyes["movimientos_internos"]
	var col := FilasUI.col(8)
	var ejecutar := func(r: Dictionary, ok_txt: String) -> void:
		avisar.call(ok_txt if bool(r["ok"]) else Razones.texto(r))
		cambio.call()
	col.add_child(Tema.etiqueta("MOVIMIENTOS INTERNOS · COALICIÓN", 10, Tema.ORO, true))
	col.add_child(Tema.etiqueta("Movimientos internos: %d de %d este turno" % [est.internos_actual, int(cfg["por_turno"])], 15, Tema.ORO, true))
	if est.etapa != "gobierno":
		col.add_child(Tema.etiqueta("Solo se pueden usar en gobierno. En campaña los movimientos son los de tus cartas.", 12, Tema.TEXTO_SUAVE))
	# Metas
	col.add_child(FilasUI.titulo("Buscar metas"))
	var disp := motor.movimientos.metas_disponibles()
	col.add_child(Tema.etiqueta("%d meta(s) disponibles · %d cumplidas. Cumplirlas desbloquea cartas." % [disp.size(), est.metas_cumplidas.size()], 11, Tema.TEXTO_SUAVE))
	for meta in disp:
		var v := FilasUI.col(4)
		v.add_child(Tema.etiqueta("%s · %s" % [meta["nombre"], meta["sector_nombre"]], 13, Tema.TEXTO, true))
		v.add_child(Tema.etiqueta(String(meta["descripcion"]), 11, Tema.TEXTO_SUAVE))
		var n_des: int = Array(meta["desbloquea"]).size()
		v.add_child(Tema.etiqueta("Costo %d mov. interno(s)%s" % [int(meta["costo_mov"]), " · desbloquea %d carta(s)" % n_des if n_des > 0 else ""], 11, Tema.ORO))
		var id := String(meta["id"])
		v.add_child(_boton("Buscar meta", Tema.ROJO, func() -> void: ejecutar.call(motor.buscar_meta(id), "Meta cumplida: %s." % meta["nombre"])))
		col.add_child(FilasUI.tarjeta(v))
	# Sectores
	col.add_child(FilasUI.titulo("Índices sectoriales"))
	col.add_child(Tema.etiqueta("Subir un índice da aprobación pero cuesta caja fiscal; bajarlo hace lo contrario. Solo sectores con ministro.", 11, Tema.TEXTO_SUAVE))
	var cats: Array = motor.gabinete.categorias_activas().keys()
	cats.sort()
	var cfg_s: Dictionary = cfg["ajustar_sector"]
	for cat in cats:
		var cs := String(cat)
		var idx := float(est.indices_sector.get(cs, cfg_s["inicial"]))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		var etiq := Tema.etiqueta_corta("%s · %d" % [BloqueoCarta.nombre_cat(cs), roundi(idx)], 13, Tema.TEXTO, false, 600)
		etiq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		etiq.custom_minimum_size = Vector2(0, 44)
		etiq.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(etiq)
		var bajar := _boton("−", Tema.PANEL.lightened(0.1), func() -> void: ejecutar.call(motor.ajustar_sector(cs, -1), "Índice de %s: bajó." % BloqueoCarta.nombre_cat(cs)))
		var subir := _boton("+", Tema.PANEL.lightened(0.1), func() -> void: ejecutar.call(motor.ajustar_sector(cs, 1), "Índice de %s: subió." % BloqueoCarta.nombre_cat(cs)))
		bajar.custom_minimum_size = Vector2(56, 44)
		subir.custom_minimum_size = Vector2(56, 44)
		h.add_child(bajar)
		h.add_child(subir)
		col.add_child(FilasUI.tarjeta(h))
	# Errores
	col.add_child(FilasUI.titulo("Errores de ejecución"))
	var ver := FilasUI.col(4)
	ver.add_child(Tema.etiqueta("Riesgo de ejecución: %d. Cada movimiento lo baja %d puntos." % [roundi(est.ind("riesgo_ejecucion")), absi(roundi(float(cfg["reducir_errores"]["delta_riesgo"])))], 12, Tema.TEXTO))
	ver.add_child(_boton("Reducir errores · %d mov." % int(cfg["reducir_errores"]["costo"]), Tema.ROJO, func() -> void: ejecutar.call(motor.reducir_errores(), "Riesgo de ejecución reducido.")))
	col.add_child(FilasUI.tarjeta(ver))
	# Obras
	col.add_child(FilasUI.titulo("Acelerar proyectos"))
	if est.obras_en_curso.is_empty():
		col.add_child(Tema.etiqueta("No hay obras en curso.", 12, Tema.TEXTO_SUAVE))
	for i in range(est.obras_en_curso.size()):
		var o: Dictionary = est.obras_en_curso[i]
		var vo := FilasUI.col(4)
		vo.add_child(Tema.etiqueta("%s · fase %d de 5 · %d %%" % [o["nombre"], MotorObras.fase_de(o), roundi(100.0 * float(o["dias_avanzados"]) / float(o["dias_totales"]))], 12, Tema.TEXTO))
		vo.add_child(_boton("Acelerar +%d días · %d mov." % [int(cfg["acelerar_proyecto"]["dias"]), int(cfg["acelerar_proyecto"]["costo"])], Tema.ROJO, func() -> void: ejecutar.call(motor.acelerar_proyecto(i), "Obra acelerada.")))
		col.add_child(FilasUI.tarjeta(vo))
	return FilasUI.scroll(col)
