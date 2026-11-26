class_name PanelCoalicion
extends RefCounted
## Coalición (DISENO_V2 §10): partidos aliados ficticios (máx. 3). Piden cuotas de ministerios y asesores; su satisfacción
## afecta la cohesión, los votos en el Congreso y los movimientos internos. Aviso de malestar y de ruptura.

static var abierto: String = ""  # partido con las cuotas desplegadas


static func _aviso(sat: float, cfg: Dictionary) -> Array:
	if sat < float(cfg["umbral_ruptura"]) + 10.0:
		return ["Riesgo de ruptura: bajo %d %% rompe el pacto y cuesta cohesión y capital." % roundi(float(cfg["umbral_ruptura"])), FilasUI.ROJO_TEXTO]
	if sat < float(cfg["umbral_malestar"]):
		return ["Malestar: quita %d movimiento interno por turno." % int(cfg["penal_internos_malestar"]), FilasUI.ROJO_TEXTO]
	if sat >= float(cfg["umbral_satisfechos"]):
		return ["Satisfecho: aporta movimientos internos si todos tus aliados lo están.", Tema.bien()]
	return ["Conforme por ahora.", Tema.TEXTO_SUAVE]


static func _cuotas(motor: MotorTurno, pid: String, avisar: Callable, cambio: Callable) -> Control:
	var est := motor.estado
	var v := FilasUI.col(6)
	var item := func(tipo: String, valor: String, nombre: String) -> void:
		var dueno := ""
		for otro in est.coalicion.keys():
			if est.coalicion[otro]["ministros" if tipo == "ministerio" else "asesores"].has(motor.gabinete.slot_de(valor) if tipo == "ministerio" else valor):
				dueno = String(otro)
		var propio := dueno == pid
		var estado_txt := "Asignado a este partido" if propio else ("Asignado a %s" % motor.coalicion.partidos[dueno]["sigla"] if dueno != "" else "Libre")
		var b := FilasUI.fila_boton([[nombre, 12, Tema.TINTA if propio else Tema.TEXTO, true], [("Ministerio · " if tipo == "ministerio" else "Asesor · ") + estado_txt, 11, Tema.TINTA if propio else Tema.TEXTO_SUAVE]],
				Tema.ORO if propio else Tema.OCEANO.lightened(0.1), 52.0)
		b.disabled = dueno != "" and not propio
		b.pressed.connect(func() -> void:
			var r := motor.quitar_cuota(pid, tipo, valor) if propio else motor.asignar_cuota(pid, tipo, valor)
			if not bool(r["ok"]):
				avisar.call(Razones.texto(r))
			cambio.call())
		v.add_child(b)
	for mid in est.gabinete:
		item.call("ministerio", mid, String(motor.catalogo_ministros[mid]["alias"]))
	for aid in est.asesores:
		item.call("asesor", aid, String(motor.equipo.asesores[aid]["nombre"]))
	if est.asesores.is_empty():
		v.add_child(Tema.etiqueta("Aún no tienes asesores para ofrecer.", 11, Tema.TEXTO_SUAVE))
	return v


static func crear(motor: MotorTurno, avisar: Callable, cambio: Callable) -> Control:
	var est := motor.estado
	var cfg: Dictionary = motor.catalogo_leyes["coalicion"]
	var col := FilasUI.col(8)
	col.add_child(Tema.etiqueta("COALICIÓN · %d DE %d ALIADOS" % [est.coalicion.size(), int(cfg["max_aliados"])], 10, Tema.ORO, true))
	col.add_child(Tema.etiqueta("Apoyo en el Congreso: %d senadores y %d diputados votan contigo." % [int(est.apoyo_coalicion["senado"]), int(est.apoyo_coalicion["camara"])], 12, Tema.TEXTO))
	col.add_child(Tema.etiqueta("Los aliados piden ministerios y asesores. Si no los atiendes, baja su satisfacción, tu cohesión y tus movimientos internos. Un aliado satisfecho (%d o más) potencia un %d %% las cartas de lo que pide." % [int(cfg["umbral_satisfechos"]), roundi(100.0 * float(cfg["bono_efecto_afin"]))], 11, Tema.TEXTO_SUAVE))
	for pid in motor.coalicion.partidos.keys():
		var p: Dictionary = motor.coalicion.partidos[pid]
		var aliado := est.coalicion.has(pid)
		var pet: Dictionary = p["peticion"]
		var v := FilasUI.col(4)
		v.add_child(Tema.etiqueta("%s (%s)%s" % [p["nombre"], p["sigla"], " · ALIADO" if aliado else ""], 13, Tema.ORO if aliado else Tema.TEXTO, true))
		v.add_child(Tema.etiqueta("Afinidad ideológica: %d %% · escaños %d sen. / %d dip." % [roundi(motor.coalicion.afinidad(pid) * 100.0), int(p["escanos_senado"]), int(p["escanos_camara"])], 11, Tema.TEXTO_SUAVE))
		v.add_child(Tema.etiqueta("Pide: %d ministerio(s), %d asesor(es) y cartas de %s." % [int(pet["ministerios"]), int(pet["asesores"]), BloqueoCarta.nombre_cat(String(pet["categoria_carta"]))], 11, Tema.TEXTO))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		if aliado:
			var sat := float(est.coalicion[pid]["satisfaccion"])
			v.add_child(Tema.etiqueta("Satisfacción %d %% · cumplimiento de cuotas %d %%" % [roundi(sat), roundi(motor.coalicion.cumplimiento(pid) * 100.0)], 11, Tema.TEXTO, false, 600))
			v.add_child(FilasUI.chip_barra(sat, Tema.color_aprobacion(sat + 12.0)))
			var av := _aviso(sat, cfg)
			v.add_child(Tema.etiqueta(String(av[0]), 11, av[1], false, 600))
			var bq := Tema.boton("Cuotas" if abierto != pid else "Ocultar", Tema.PANEL.lightened(0.12), Tema.TEXTO, 13, 44)
			bq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bq.pressed.connect(func() -> void:
				abierto = "" if abierto == pid else pid
				cambio.call())
			var bs := Tema.boton("Salir", Tema.ROJO, Tema.TEXTO, 13, 44)
			bs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bs.pressed.connect(func() -> void:
				var r := motor.salir_coalicion(pid)
				avisar.call(("Pacto roto" + (": −%d cohesión y −%d capital." % [roundi(float(cfg["penal_ruptura_cohesion"])), roundi(float(cfg["penal_ruptura_capital"]))] if est.etapa == "gobierno" else ".")) if bool(r["ok"]) else Razones.texto(r))
				cambio.call())
			fila.add_child(bq)
			fila.add_child(bs)
			v.add_child(fila)
			if abierto == pid:
				v.add_child(_cuotas(motor, pid, avisar, cambio))
		else:
			var bu := Tema.boton("Unirse a la coalición", Tema.ROJO, Tema.TEXTO, 13, 44)
			bu.pressed.connect(func() -> void:
				var r := motor.unirse_coalicion(pid)
				avisar.call(("%s se une a tu coalición." % p["sigla"]) if bool(r["ok"]) else Razones.texto(r))
				cambio.call())
			v.add_child(bu)
		col.add_child(FilasUI.tarjeta(v, Tema.PANEL, Tema.ORO if aliado else Color(0, 0, 0, 0)))
	return FilasUI.scroll(col)
