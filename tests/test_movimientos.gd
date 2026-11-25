extends SceneTree
## Movimientos internos (DISENO_V2 §6) y cartas de Estado empresario (§7).

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO MOVIMIENTOS: ", msg)


func _init() -> void:
	var datos := Datos.cargar_todo()
	var cfg: Dictionary = datos["leyes"]["movimientos_internos"]
	var tam := 8  # gabinete corto de prueba: el real tiene 25 y no deja sectores sin ministro
	var carta_meta := AyudaV2.carta_sintetica("t_desbloqueo", "salud", {"meta": "meta_salud_1"})
	var m := AyudaV2.gobierno(datos, 31, [carta_meta])
	var est := m.estado
	m.estado.gabinete.assign(AyudaV2.ministros_de(datos, ["salud", "obras"], tam))
	_check(est.internos_actual == int(cfg["por_turno"]) and est.internos_actual == 3, "3 movimientos internos por turno")
	# buscar_meta: sector sin ministro, requisito previo, costo, efectos y desbloqueo de cartas
	_check(String(m.buscar_meta("meta_inexistente")["razon"]) == "meta_inexistente", "meta inexistente")
	_check(String(m.buscar_meta("meta_salud_2")["razon"]) == "requiere_meta_previa", "la meta 2 exige la 1")
	_check(not m.carta_disponible(m._cartas_por_id["t_desbloqueo"]), "carta ligada a la meta bloqueada")
	var cap := est.ind("capital")
	var r := m.buscar_meta("meta_salud_1")
	_check(bool(r["ok"]) and est.metas_cumplidas.has("meta_salud_1"), "meta cumplida")
	_check(est.internos_actual == 3 - int(m.movimientos.metas["meta_salud_1"]["costo_mov"]), "la meta cobra su costo en movimientos internos")
	_check(est.ind("capital") > cap, "la meta aplica sus efectos")
	_check(m.carta_disponible(m._cartas_por_id["t_desbloqueo"]) and r["desbloqueadas"].has("t_desbloqueo"), "la meta desbloquea la carta")
	_check(String(m.buscar_meta("meta_salud_1")["razon"]) == "meta_cumplida", "no se cumple dos veces")
	est.gabinete.assign(AyudaV2.ministros_de(datos, ["salud"], 1))
	est.gabinete.assign(est.gabinete.slice(0, 1))
	_check(String(m.buscar_meta("meta_vivienda_1")["razon"]) == "sector_sin_ministro", "sin ministro del sector no hay meta")
	est.gabinete.assign(AyudaV2.ministros_de(datos, ["salud", "obras"], tam))
	# ajustar sector
	var apr := est.ind("aprobacion")
	var fis := est.ind("fiscal")
	var s := m.ajustar_sector("salud", 1)
	_check(bool(s["ok"]) and is_equal_approx(float(s["indice"]), float(cfg["ajustar_sector"]["inicial"]) + float(cfg["ajustar_sector"]["paso"])), "sube el índice del sector")
	_check(est.ind("fiscal") < fis and est.ind("aprobacion") > apr, "subir el sector cuesta fiscal y da aprobación")
	_check(bool(m.ajustar_sector("salud", -1)["ok"]) and is_equal_approx(float(est.indices_sector["salud"]), float(cfg["ajustar_sector"]["inicial"])), "baja el índice")
	_check(String(m.ajustar_sector("salud", 1)["razon"]) == "movimientos_insuficientes", "sin movimientos internos no se actúa")
	m.terminar_turno()
	_check(est.internos_actual == 3, "los movimientos internos se renuevan")
	_check(String(m.ajustar_sector("energia", 1)["razon"]) == "sector_sin_ministro", "sector sin ministro")
	_check(String(m.ajustar_sector("salud", 2)["razon"]) == "direccion_invalida", "dirección inválida")
	# reducir errores
	est.indicadores["riesgo_ejecucion"] = 40.0
	_check(bool(m.reducir_errores()["ok"]) and is_equal_approx(est.ind("riesgo_ejecucion"), 40.0 + float(cfg["reducir_errores"]["delta_riesgo"])), "reducir errores baja el riesgo")
	# acelerar proyecto
	_check(String(m.acelerar_proyecto(0)["razon"]) == "indice_invalido", "sin obras no se acelera")
	m.obras.iniciar(est, "Obra de prueba", 365, "", "", [])
	var dias := int(est.obras_en_curso[0]["dias_avanzados"])
	var a := m.acelerar_proyecto(0)
	_check(bool(a["ok"]) and int(est.obras_en_curso[0]["dias_avanzados"]) == dias + int(cfg["acelerar_proyecto"]["dias"]), "acelerar adelanta días de la obra")
	_check(est.internos_actual == 1 and bool(m.ajustar_sector("salud", 1)["ok"]) and est.internos_actual == 0, "se gastaron los 3 movimientos del turno")
	_check(String(m.reducir_errores()["razon"]) == "movimientos_insuficientes", "presupuesto de movimientos agotado")
	# en campaña no hay movimientos internos
	var c := AyudaV2.gobierno(datos, 32)
	c.estado.etapa = "campana"
	_check(String(c.reducir_errores()["razon"]) == "solo_en_gobierno", "solo en gobierno")
	# replay exacto de la secuencia (misma semilla + mismas entradas)
	var g: Dictionary = JSON.parse_string(JSON.stringify(est.exportar_guardado("")))
	_check(g["entradas"].any(func(e: Dictionary) -> bool: return e["tipo"] == "meta") and g["entradas"].any(func(e: Dictionary) -> bool: return e["tipo"] == "acelerar"), "el guardado registra los movimientos internos")
	# Estado empresario: 3 tipos x 2-3 variantes, con costos fiscales, de cohesión, capital y riesgo
	var tipos := {}
	for k in datos["cartas"]:
		if k["categoria"] == "estado":
			var sub := String(k["meta"]["subtipo"])
			tipos[sub] = int(tipos.get(sub, 0)) + 1
			_check(bool(k["meta"]["cifras_ilustrativas"]) and k["requisitos"]["ley"] != null, "carta estado rotulada y con ley: %s" % k["id"])
			var inds := {}
			for ef in k["efectos"]:
				inds[ef["ind"]] = true
			_check(inds.has("fiscal") and inds.has("capital") and inds.has("riesgo_ejecucion"), "costos fiscal/capital/riesgo: %s" % k["id"])
	for t in ["empresa_publica", "privatizacion", "expropiacion"]:
		_check(int(tipos.get(t, 0)) >= 2 and int(tipos[t]) <= 3, "2-3 variantes de %s" % t)
	var me := AyudaV2.gobierno(datos, 33)
	var fis0 := me.estado.ind("fiscal")
	me.estado.mano.clear()
	me.estado.mano.append(me._cartas_por_id["estado_priv_terrenos"])
	_check(me.carta_disponible(me.estado.mano[0]), "las cartas estado están siempre disponibles")
	_check(bool(me.jugar_carta(0)["ok"]) and me.estado.proyectos_ley.size() == 1, "una privatización entra a tramitación como ley")
	print("MOVIMIENTOS OK" if _fallos == 0 else "MOVIMIENTOS FALLÓ")
	quit(1 if _fallos > 0 else 0)
