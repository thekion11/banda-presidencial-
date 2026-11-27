# Mutantes manuales: (id, archivo, texto_original, texto_nuevo, descripción). Cada texto_original debe aparecer EXACTAMENTE una vez.
MUTANTES = [
 ("M01", "sim/motor_legal.gd", '"aprobada": sen >= min_sen and dip >= min_cam,', '"aprobada": sen > min_sen and dip >= min_cam,', "votación: el Senado necesita un voto más que el mínimo"),
 ("M02", "sim/motor_legal.gd", "	return base / 2 + 1", "	return base / 2", "umbral de mayoría simple sin el +1"),
 ("M03", "sim/motor_efectos.gd", 'ind[nombre] = clampf(float(ind.get(nombre, 0.0)) + delta, _min, _max_viv', 'ind[nombre] = clampf(float(ind.get(nombre, 0.0)) + delta, _min - 5.0, _max_viv', "indicadores pueden bajar de 0 (hasta -5)"),
 ("M04", "sim/motor_obras.gd", 'if int(obra["dias_avanzados"]) >= int(obra["dias_totales"]):', 'if int(obra["dias_avanzados"]) > int(obra["dias_totales"]):', "las obras terminan un turno tarde cuando el avance es exacto"),
 ("M05", "sim/motor_mandato.gd", 'if _m.estado.semanas_en_crisis >= int(d["semanas_crisis_para_caida"]):', 'if _m.estado.semanas_en_crisis > int(d["semanas_crisis_para_caida"]):', "el gobierno cae una semana después de lo debido"),
 ("M06", "sim/motor_mandato.gd", '+ _m.rng.randf_range(-ruido, ruido) - sin_prom + efecto_rival', '+ _m.rng.randf_range(-ruido, ruido) + efecto_rival', "la elección ignora la penalización por no hacer promesas"),
 ("M07", "sim/motor_gabinete.gd", "	if _m.rng.randf() < p:\n		res[\"fallo\"] = true", "	if _m.rng.randf() > p:\n		res[\"fallo\"] = true", "delegación: falla con la probabilidad complementaria"),
 ("M08", "sim/motor_gabinete.gd", 'p -= float(mi["bono_ejecucion"]) * float(d["peso_bono_ejecucion"])', 'p += float(mi["bono_ejecucion"]) * float(d["peso_bono_ejecucion"])', "el ministro afín aumenta el riesgo de fallo en vez de bajarlo"),
 ("M09", "sim/motor_gabinete.gd", 'if _m.estado.delegadas_turno >= int(_m.catalogo_leyes["delegacion"]["max_por_turno"]):\n		return {"ok": false, "razon": "limite_delegaciones"}', 'if _m.estado.delegadas_turno > int(_m.catalogo_leyes["delegacion"]["max_por_turno"]):\n		return {"ok": false, "razon": "limite_delegaciones"}', "se permite una delegación más que el máximo por turno"),
 ("M10", "sim/motor_cartas.gd", 'costo -= int(mi["reduccion_costo_pa"])', 'costo += int(mi["reduccion_costo_pa"])', "el ministro afín encarece la carta en vez de abaratarla"),
 ("M11", "sim/motor_coalicion.gd", 'c["satisfaccion"] = minf(100.0, float(c["satisfaccion"]) + float(_cfg()["bono_carta_afin"]))', 'c["satisfaccion"] = float(c["satisfaccion"]) + float(_cfg()["bono_carta_afin"])', "la satisfacción del aliado no tiene tope de 100"),
 ("M12", "sim/motor_mandato.gd", '+ _m.estado.ind("fiscal") * float(p["peso_fiscal"]) + _m.estado.ind("capital")', '+ _m.estado.ind("capital")', "el puntaje final ignora el indicador fiscal"),
 ("M13", "sim/motor_legal.gd", '"cae": rng.randf() >= p_exito', '"cae": rng.randf() < p_exito', "Tribunal Constitucional: cae con la probabilidad complementaria"),
 ("M14", "sim/regiones.gd", 'reg[id] = clampf(a + (ancla + sesgo - a) * tasa, 0.0, 100.0)', 'reg[id] = clampf(a + (ancla - sesgo - a) * tasa, 0.0, 100.0)', "el sesgo regional persistente tiene el signo invertido"),
 ("M15", "sim/motor_coalicion.gd", 'est.internos_actual = maxi(0, est.internos_actual - int(cfg["penal_internos_malestar"]))', 'est.internos_actual = est.internos_actual - int(cfg["penal_internos_malestar"])', "los movimientos internos pueden quedar negativos"),
 ("M16", "sim/partida.gd", 'motor.buscar_meta(String(e["meta"]))', 'pass', "el replay ignora las entradas de tipo «meta»"),
 ("M17", "sim/encuestas.gd", 'snappedf(clampf(base + u * margen, 0.0, 100.0), 0.1)', 'snappedf(base + u * margen, 0.1)', "la intención de voto de la encuesta no se recorta a 0..100"),
 ("M18", "sim/motor_mazo.gd", 'while e.mano.size() < n and intentos > 0:', 'while e.mano.size() <= n and intentos > 0:', "la mano se llena con 6 cartas en vez de 5"),
 ("M19", "sim/director_eventos.gd", 'if oc.has(id) and ahora - int(oc[id]) < cd_evento:', 'if oc.has(id) and ahora - int(oc[id]) < cd_evento - 1:', "un evento puede repetirse una semana antes del descanso"),
 ("M20", "sim/huella.gd", 'var f := roundf(float(v) * 100000000.0) / 100000000.0', 'var f := roundf(float(v) * 1000.0) / 1000.0', "la huella redondea a 3 decimales en vez de 8"),
]

MUTANTES += [
 ("M21", "sim/motor_legal.gd", "var abst_sen := roundi(fr * float(n_sen - sen))", "var abst_sen := roundi(fr * float(n_sen))", "la abstención del Senado se calcula sobre toda la cámara y no sobre los no favorables"),
 ("M22", "sim/motor_legal.gd", "		0.0, 1.0)\n	var n_sen := int(h[\"total_senadores\"])", "		0.0, 2.0)\n	var n_sen := int(h[\"total_senadores\"])", "el apoyo esperado en la votación puede pasar de 1"),
 ("M23", "sim/motor_legal.gd", "return propios + roundi(float(total - propios) * apoyo)", "return roundi(float(total) * apoyo)", "los votos ignoran los escaños propios"),
 ("M24", "sim/motor_legal.gd", '(base * int(f["num"]) + int(f["den"]) - 1) / int(f["den"])', '(base * int(f["num"])) / int(f["den"])', "los quórums de fracción redondean hacia abajo en vez de hacia arriba"),
 ("M25", "sim/motor_turno.gd", 'fx.sumar_ind("fiscal", float(d["regen_fiscal_semanal"]))', 'fx.sumar_ind("fiscal", -float(d["regen_fiscal_semanal"]))', "la regeneración fiscal semanal resta en vez de sumar"),
 ("M26", "sim/motor_turno.gd", 'ancla -= maxf(0.0, float(d["fiscal_critico"]) - estado.ind("fiscal")) * float(d["penal_fiscal_critico"])', 'ancla -= 0.0', "no hay penalización por fiscal crítico"),
 ("M27", "sim/motor_eventos.gd", "return _m.estado.dias_carrera / _m.estado.dias_por_turno + _m.estado.turno_actual", "return _m.estado.dias_carrera / _m.estado.dias_por_turno + _m.estado.turno_actual + 1", "la semana absoluta de la carrera se desplaza en una"),
 ("M28", "sim/motor_mandato.gd", 'else turnos_jugados * e.dias_por_turno', 'else (turnos_jugados - 1) * e.dias_por_turno', "el reloj de la carrera pierde una semana por periodo"),
 ("M29", "sim/motor_gabinete.gd", 'res["escala"] = float(res["escala"]) * float(d["escala_si_falla"])', 'res["escala"] = float(res["escala"]) + float(d["escala_si_falla"])', "si el ministro falla, el efecto se suma en vez de reducirse"),
 ("M30", "sim/motor_gabinete.gd", 'return clampf(p, float(d["prob_fallo_min"]), float(d["prob_fallo_max"]))', 'return clampf(p, 0.0, float(d["prob_fallo_max"]))', "la probabilidad de fallo de delegación pierde su mínimo"),
 ("M31", "sim/encuestas.gd", 'lerpf(float(cfg["margen_inicial"]), float(cfg["margen_final"]), avance)', 'lerpf(float(cfg["margen_final"]), float(cfg["margen_inicial"]), avance)', "el margen de error de las encuestas crece en vez de bajar"),
 ("M32", "sim/encuestas.gd", 'while e.encuestas.size() > int(cfg["historial_max"]):', 'while e.encuestas.size() >= int(cfg["historial_max"]):', "el historial de encuestas guarda una menos"),
 ("M33", "sim/instantanea.gd", 'd["sha_guardado"] == sha_guardado and sha_guardado != ""', 'd["sha_guardado"] == sha_guardado', "una instantánea sin sha de guardado sería válida"),
 ("M34", "sim/instantanea.gd", ' and (e["mazo"] is Array)', '', "es_completa deja de exigir que el mazo sea un Array"),
 ("M35", "sim/partida.gd", "if Instantanea.vale_para(instantanea, huella_datos, sha_guardado):", "if not instantanea.is_empty():", "Partida.cargar usa cualquier instantánea sin validarla"),
 ("M36", "sim/validar_guardado.gd", 'if e["tipo"] == "jugar" and e.has("delegada") and not (e["delegada"] is bool):\n		return false', 'if false:\n		return false', "el validador acepta «delegada» que no es booleano"),
 ("M37", "sim/motor_coalicion.gd", 'if float(est.coalicion[id]["satisfaccion"]) < float(cfg["umbral_ruptura"]):', 'if float(est.coalicion[id]["satisfaccion"]) < float(cfg["umbral_ruptura"]) - 100.0:', "un aliado muy insatisfecho nunca rompe la coalición"),
 ("M38", "sim/motor_mandato.gd", "	else:\n		_m.estado.semanas_en_crisis = 0", "	else:\n		pass", "el contador de semanas en crisis nunca se reinicia"),
]

MUTANTES += [
 ("G01", "game/pantallas/pantalla_partido.gd", '		nombre = "Partido Independiente"', '		nombre = ""', "un partido sin nombre ya no recibe el nombre por defecto"),
 ("G02", "game/pantallas/pantalla_partido.gd", "		sigla = nombre.substr(0, 3)", "		sigla = nombre.substr(0, 0)", "una sigla vacía ya no se completa con las 3 primeras letras del nombre"),
 ("G03", "game/pantallas/pantalla_dia.gd", "	if i == _sel and _mano_tocada:", "	if i == _sel:", "tocar una carta la juega al primer toque, sin elegirla antes"),
 ("G04", "game/pantallas/pantalla_dia.gd", "	if est.eleccion_pendiente(sem):\n		_resolver_eleccion()\n		return", "	if false:\n		_resolver_eleccion()\n		return", "el botón de terminar semana no lleva a las urnas cuando la campaña terminó"),
 ("G05", "game/pantallas/pantalla_dia.gd", "	_mano_tocada = false\n	var r := motor.jugar_carta(_sel, _ministro, _region)", "	var r := motor.jugar_carta(_sel, _ministro, _region)", "tras jugar una carta la selección no se limpia (el siguiente toque la juega)"),
 ("G06", "game/main.gd", "	if not ValidarGuardado.guardado_valido(g):", "	if false:", "continuar acepta guardados con estructura inválida"),
 ("G07", "game/componentes/barras.gd", '	var dias := (dia - 1) if etapa == "gobierno" else (turno - 1) * 7', '	var dias := (dia - 1) if etapa == "gobierno" else turno * 7', "la fecha de campaña que muestra la pantalla se adelanta una semana"),
 ("G08", "game/tema.gd", "const TACTIL := 44.0", "const TACTIL := 30.0", "la zona táctil mínima baja de 44 a 30 px"),
 ("G09", "game/main.gd", "		guardar()  # al pasar a segundo plano (o salir) se deja también la instantánea al día\n		guardar_instantanea()", "		guardar_instantanea()", "al pasar a segundo plano la aplicación no guarda la partida"),
 ("G10", "game/tema.gd", '	return "%d %%" % roundi(v)', '	return "%d %%" % floori(v)', "los porcentajes se muestran truncados en vez de redondeados"),
 ("G11", "game/pantallas/pantalla_dia.gd", "	_ministro = \"\"\n", "", "tras jugar una carta delegada el ministro elegido se arrastra a la siguiente"),
]

MUTANTES += [
 ("G12", "game/pantallas/pantalla_fin.gd", "MESES[clampi(int(p[1]) - 1, 0, 11)]", "MESES[clampi(int(p[1]), 0, 11)]", "la fecha de un hito del fin de partida muestra el mes siguiente"),
 ("G13", "game/pantallas/pantalla_fin.gd", '"Postularte a la reelección" if reelige else', '"Seguir tu carrera: pasar a la oposición" if reelige else', "el botón del fin de mandato invierte reelección y oposición"),
 ("G14", "game/pantallas/pantalla_fin.gd", "		if leyes.size() > 8:", "		if leyes.size() > 80:", "la lista de leyes del resumen no se recorta a 8"),
 ("G15", "game/pantallas/pantalla_fin.gd", '"Intentar de nuevo" if derrota else "Volver al inicio"', '"Volver al inicio" if derrota else "Intentar de nuevo"', "el botón de pie del fin invierte derrota y victoria"),
 ("G16", "game/pantallas/pantalla_eleccion.gd", 'if int(res["ronda"]) == 1 else "Ganas la segunda vuelta"', 'if int(res["ronda"]) == 2 else "Ganas la segunda vuelta"', "la elección anuncia «Ganas la segunda vuelta» en la primera vuelta"),
 ("G17", "game/pantallas/pantalla_eleccion.gd", "float(h[\"umbral_pasa_balotaje\"]) if ronda == 1 else 0.0", "0.0 if ronda == 1 else 0.0", "la barra de la elección pierde el piso de segunda vuelta"),
 ("G18", "game/pantallas/panel_delegar.gd", "Tema.bien() if p <= 0.25 else", "Tema.bien() if p <= 0.0 else", "el riesgo de delegar nunca se pinta como bajo"),
 ("G19", "game/pantallas/panel_delegar.gd", "elif est.delegadas_turno >= maximo:", "elif est.delegadas_turno > maximo:", "el panel de delegar permite una delegación más que el máximo"),
]

MUTANTES += [
 ("G20", "game/pantallas/panel_gabinete.gd", "					if elegidos.size() < tam:", "					if elegidos.size() <= tam:", "el gabinete deja elegir un ministro más que el tamaño"),
 ("G21", "game/pantallas/panel_gabinete.gd", "					elegidos.erase(id)  # vaciar el cargo", "					pass", "tocar un ministro elegido ya no vacía el cargo"),
 ("G22", "game/pantallas/panel_gabinete.gd", "						elegidos.erase(otro)", "						pass", "elegir un candidato no reemplaza al anterior del mismo ministerio"),
 ("G23", "game/pantallas/panel_internos.gd", '	if est.etapa != "gobierno":', '	if est.etapa == "gobierno":', "el aviso «solo en gobierno» de movimientos internos se invierte"),
 ("G24", "game/pantallas/panel_internos.gd", '"" if int(meta["costo_mov"]) == 1 else "s"', '"" if int(meta["costo_mov"]) == 2 else "s"', "el plural del costo de una meta interna se rompe"),
 ("G25", "game/pantallas/panel_internos.gd", 'roundi(100.0 * float(o["dias_avanzados"])', 'roundi(10.0 * float(o["dias_avanzados"])', "el porcentaje de avance de la obra se muestra diez veces menor"),
 ("G26", "game/pantallas/panel_equipo.gd", '"Despedir" if contratado else', '"Despedir" if not contratado else', "el botón del asesor invierte contratar y despedir"),
 ("G27", "game/pantallas/pantalla_afiliacion.gd", '	if k == "existente":', '	if k == "propio":', "la afiliación manda a la lista de partidos al elegir «propio»"),
 ("G28", "game/pantallas/panel_equipo.gd", 'roundi(afin * 100.0)', 'roundi(afin * 10.0)', "la afinidad del asesor con el partido se muestra diez veces menor"),
]

MUTANTES += [
 ("T01", "sim/motor_movimientos.gd", "			if apr >= u:", "			if apr > u:", "el bono de movimientos por aprobación exige superar el tramo, no alcanzarlo"),
 ("T02", "sim/motor_movimientos.gd", "	if costo > m.estado.internos_actual:", "	if costo >= m.estado.internos_actual:", "un movimiento interno no se puede pagar con el saldo justo"),
 ("T03", "sim/motor_equipo.gd", '	if est.asesores.size() >= int(_cfg()["max"]):', '	if est.asesores.size() > int(_cfg()["max"]):', "se puede contratar un asesor más que el máximo"),
 ("T04", "sim/motor_equipo.gd", 'else 1.0 - float(_cfg()["mitigacion_afin"]) * afinidad(id)', 'else 1.0 + float(_cfg()["mitigacion_afin"]) * afinidad(id)', "la afinidad agrava lo negativo de un asesor en vez de atenuarlo"),
 ("T05", "sim/motor_mandato.gd", "	var electo := voto_final >= umbral", "	var electo := voto_final > umbral", "la elección exige superar el umbral, no alcanzarlo"),
 ("T06", "sim/motor_mandato.gd", 'and voto_final >= float(h["umbral_pasa_balotaje"])', 'and voto_final > float(h["umbral_pasa_balotaje"])', "pasar a segunda vuelta exige superar el piso, no alcanzarlo"),
 ("T07", "sim/motor_mandato.gd", 'if ap >= float(c["umbral_gana"])', 'if ap > float(c["umbral_gana"])', "la sucesión exige superar el umbral de victoria"),
 ("T08", "sim/motor_mandato.gd", '	if _m.estado.ind("aprobacion") < float(d["umbral_crisis_aprobacion"]):', '	if _m.estado.ind("aprobacion") <= float(d["umbral_crisis_aprobacion"]):', "la semana en crisis cuenta también con aprobación igual al umbral"),
 ("T09", "sim/motor_legal.gd", 'or rng.randf() < float(t["prob_recurso_tc"])', 'or rng.randf() > float(t["prob_recurso_tc"])', "la oposición recurre al TC con la probabilidad complementaria"),
 ("T10", "sim/motor_legal.gd", "var p_exito := prob_exito_override if prob_exito_override >= 0.0 else", "var p_exito := prob_exito_override if prob_exito_override > 0.0 else", "una probabilidad de éxito forzada en 0 del TC se ignora"),
 ("T11", "sim/motor_coalicion.gd", 'float(c["satisfaccion"]) >= float(cfg["umbral_satisfechos"])', 'float(c["satisfaccion"]) > float(cfg["umbral_satisfechos"])', "un partido satisfecho exige superar el umbral"),
 ("T12", "sim/motor_coalicion.gd", 'if float(est.coalicion[id]["satisfaccion"]) < float(cfg["umbral_ruptura"]):', 'if float(est.coalicion[id]["satisfaccion"]) <= float(cfg["umbral_ruptura"]):', "un partido rompe la coalición con satisfacción igual al umbral"),
 ("T13", "sim/motor_turno.gd", 'float(d["fiscal_critico"]) - estado.ind("fiscal")', 'estado.ind("fiscal") - float(d["fiscal_critico"])', "la penalización fiscal crítica se aplica al revés (con caja sana)"),
 ("T14", "sim/motor_movimientos.gd", 'float(cfg["min"]), float(cfg["max"]))', 'float(cfg["min"]) - 50.0, float(cfg["max"]))', "el índice sectorial puede bajar del mínimo"),
]

_DOBLE = '(ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed'
MUTANTES += [
 ("G29", "game/componentes/carta_ui.gd", "	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):\n		return\n	if event.pressed:", "	if not ((event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or event is InputEventScreenTouch):\n		return\n	if event.pressed:", "la carta atiende el toque y además el clic emulado (un toque elige y juega)"),
 ("G30", "game/componentes/mapa_chile.gd", "	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:", "	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):", "el mapa de Chile atiende el toque y además el clic emulado"),
 ("G31", "game/pantallas/cuerpo_dia.gd", "		if ev is InputEventMouseButton and ev.pressed:", "		if " + _DOBLE + ":", "el cuerpo del día atiende el toque y además el clic emulado"),
 ("G32", "game/componentes/telon_semana.gd", "		if ev is InputEventMouseButton and ev.pressed:", "		if " + _DOBLE + ":", "el telón de semana atiende el toque y además el clic emulado"),
 ("G33", "game/componentes/cambio_mando.gd", "		if ev is InputEventMouseButton and ev.pressed:", "		if " + _DOBLE + ":", "el cambio de mando atiende el toque y además el clic emulado"),
 ("G34", "game/componentes/mano_ui.gd", "	if not (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT):\n		return\n	if ev.pressed:", "	if not ((ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT) or ev is InputEventScreenTouch):\n		return\n	if ev.pressed:", "la mano atiende el toque y además el clic emulado en sus gestos"),
 ("G35", "game/componentes/obra_3d.gd", "	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:", "	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or event is InputEventScreenTouch:", "la obra 3D atiende el toque y además el clic emulado"),
]


MUTANTES += [
 ("D01", "data/cartas_curadas.json", '"id": "plan_afp_estatal",\n    "categoria": "hacienda",\n    "costo_pa": 3,\n    "titulo": "AFP estatal autónoma (reforma constitucional)",\n    "efectos": [\n      {\n        "ind": "capital",\n        "delta": -4\n      },\n      {\n        "ind": "cohesion",\n        "delta": -2\n      },\n      {\n        "ind": "aprobacion",\n        "delta": 1\n      }\n    ],\n    "requisitos": {\n      "ley": "reforma_constitucional",\n      "quorum": "reforma_constitucional"', '"id": "plan_afp_estatal",\n    "categoria": "hacienda",\n    "costo_pa": 3,\n    "titulo": "AFP estatal autónoma (reforma constitucional)",\n    "efectos": [\n      {\n        "ind": "capital",\n        "delta": -4\n      },\n      {\n        "ind": "cohesion",\n        "delta": -2\n      },\n      {\n        "ind": "aprobacion",\n        "delta": 1\n      }\n    ],\n    "requisitos": {\n      "ley": "ley_simple",\n      "quorum": "ley_simple"', "la AFP estatal deja de ser reforma constitucional (pasa con ley simple)"),
 ("D02", "data/leyes.json", '"id": "reforma_constitucional",\n      "nombre": "Reforma Constitucional (4/7 de los miembros en ejercicio)",\n      "articulo_constitucional": "Art. 127 CPR (4/7, Ley 21.481)",\n      "requiere_votacion": true,\n      "dias_tramitacion_base": 63,\n      "puede_ir_tc": true,\n      "prob_recurso_tc": 0.4,\n      "prob_exito_tc": 0.6,\n      "fuente": "fuentes.json#cpr_chile_2026",\n      "verificado": true,\n      "base_quorum": "en_ejercicio",\n      "regla": "fraccion",\n      "fraccion": {\n        "num": 4', '"id": "reforma_constitucional",\n      "nombre": "Reforma Constitucional (4/7 de los miembros en ejercicio)",\n      "articulo_constitucional": "Art. 127 CPR (4/7, Ley 21.481)",\n      "requiere_votacion": true,\n      "dias_tramitacion_base": 63,\n      "puede_ir_tc": true,\n      "prob_recurso_tc": 0.4,\n      "prob_exito_tc": 0.6,\n      "fuente": "fuentes.json#cpr_chile_2026",\n      "verificado": true,\n      "base_quorum": "en_ejercicio",\n      "regla": "fraccion",\n      "fraccion": {\n        "num": 3', "la reforma constitucional exige 3/7 en vez de 4/7"),
 ("D03", "data/cartas_curadas.json", '"id": "plan_coeva",\n    "categoria": "medioambiente",\n    "costo_pa": 3', '"id": "plan_coeva",\n    "categoria": "medioambiente",\n    "costo_pa": 1', "la reforma COEVA cuesta 1 movimiento en vez de 3"),
]


MUTANTES += [
 ("G36", "game/componentes/mapa_zoom.gd", "	pan.x = clampf(pan.x, tam.x * (1.0 - zoom), 0.0)", "	pan.x = pan.x", "el desplazamiento horizontal del mapa con zoom no se limita"),
 ("G37", "game/componentes/mapa_zoom.gd", "	zoom = clampf(zoom, 1.0, MAX)\n	pan.x", "	zoom = clampf(zoom, 0.5, MAX)\n	pan.x", "el zoom del mapa puede bajar de 1 (se ve fuera del mapa)"),
 ("G38", "game/componentes/mapa_zoom.gd", "	zoom = clampf(zoom * factor, 1.0, MAX)", "	zoom = clampf(zoom * factor, 1.0, MAX * 3.0)", "el pellizco puede pasar del zoom máximo"),
 ("G39", "game/componentes/mapa_zoom.gd", "var era: bool = _pulsado and not _movido and not ev.canceled", "var era: bool = _pulsado and not ev.canceled", "un arrastre del mapa se toma como toque y elige región"),
]

MUTANTES += [
 ("V01", "sim/voto_regional.gd", "		var gana := voto >= umbral", "		var gana := voto > umbral", "una región gana con el umbral exacto solo si lo supera"),
 ("V02", "sim/voto_regional.gd", "		nacional += peso * voto", "		nacional += voto * 0.0625", "el voto nacional pondera todas las regiones por igual (no por población)"),
 ("V03", "sim/voto_regional.gd", "		votos += hab * voto / tope_max", "		votos += hab * voto", "el total de votos estimados no se escala por el tope"),
 ("V04", "sim/voto_regional.gd", "+ desplazamiento, tope_min, tope_max)\n		var gana", "+ desplazamiento, tope_min, tope_max * 2.0)\n		var gana", "el voto regional puede pasar de 100"),
 ("V05", "sim/voto_regional.gd", "		ganadas += 1 if gana else 0", "		ganadas += 1", "se cuentan todas las regiones como ganadas"),
 ("V06", "sim/voto_regional.gd", '"voto_nacional": clampf(nacional, tope_min, tope_max)', '"voto_nacional": nacional + 1.0', "el voto nacional se desvía de la suma ponderada"),
]

MUTANTES += [
 ("S01", "sim/motor_movimientos.gd", "e.pa_actual = mini(maxi(int(_m.catalogo_leyes[\"mano\"][\"tope_ahorro\"]), ingreso), maxi(0, e.pa_actual) + ingreso)", "e.pa_actual = maxi(maxi(int(_m.catalogo_leyes[\"mano\"][\"tope_ahorro\"]), ingreso), maxi(0, e.pa_actual) + ingreso)", "el ahorro de movimientos no tiene tope (se acumula sin límite)"),
 ("S02", "sim/motor_movimientos.gd", "e.pa_actual = mini(maxi(int(_m.catalogo_leyes[\"mano\"][\"tope_ahorro\"]), ingreso), maxi(0, e.pa_actual) + ingreso)", "e.pa_actual = mini(mini(int(_m.catalogo_leyes[\"mano\"][\"tope_ahorro\"]), ingreso), maxi(0, e.pa_actual) + ingreso)", "el tope de ahorro puede quedar bajo el ingreso de la semana"),
 ("S03", "sim/motor_movimientos.gd", "maxi(0, e.pa_actual) + ingreso)", "ingreso)", "no se ahorra nada: lo que sobra se pierde"),
 ("S04", "sim/motor_movimientos.gd", "maxi(0, e.pa_actual) + ingreso)", "maxi(0, e.pa_actual) + ingreso + 1)", "cada semana se crea un movimiento de la nada"),
 ("S05", "sim/motor_movimientos.gd", "e.pa_actual = mini(maxi(int(_m.catalogo_leyes[\"mano\"][\"tope_ahorro\"]), ingreso), maxi(0, e.pa_actual) + ingreso)", "e.pa_actual = mini(maxi(int(_m.catalogo_leyes[\"mano\"][\"tope_ahorro\"]) + 1, ingreso), maxi(0, e.pa_actual) + ingreso)", "el tope de ahorro es uno más alto que el configurado"),
]

MUTANTES += [
 ("G40", "game/componentes/tablero_gabinete.gd", "return data is Dictionary and String(data.get(\"slot\", \"\")) == slot and al_soltar.is_valid()", "return data is Dictionary and al_soltar.is_valid()", "un candidato se puede soltar en un puesto ajeno"),
 ("G41", "game/pantallas/panel_gabinete.gd", "		if actual != \"\":\n			elegidos.erase(actual)\n		elegidos.append(id)", "		elegidos.append(id)", "nombrar a otro candidato del mismo puesto no saca al anterior (dos en un cargo)"),
 ("G42", "game/pantallas/panel_gabinete.gd", "		boton.disabled = elegidos.size() != tam", "		boton.disabled = elegidos.size() < tam - 1", "se puede confirmar un gabinete incompleto"),
 ("G43", "game/pantallas/panel_gabinete.gd", "			elegidos.assign(previo)\n			previo.clear()", "			elegidos.clear()\n			previo.clear()", "«Deshacer» vacía el gabinete en vez de devolver el anterior"),
 ("G44", "game/pantallas/panel_gabinete.gd", "				auto[String(n[\"id\"])] = true  # en el tablero se ven punteados: los puso el relleno, no tú", "				pass", "el relleno automático no se distingue de lo elegido"),
]

MUTANTES += [
 ("A01", "sim/motor_agenda.gd", "return m.estado.agenda.size() + m.estado.proyectos_ley.size() >= int(_cfg()[\"max_simultaneos\"])", "return m.estado.agenda.size() + m.estado.proyectos_ley.size() > int(_cfg()[\"max_simultaneos\"])", "la agenda admite un proyecto más que el máximo"),
 ("A02", "sim/motor_agenda.gd", "	if _semana_rechazo(String(carta[\"id\"])) > _m.eventos.semana_abs():", "	if _semana_rechazo(String(carta[\"id\"])) > _m.eventos.semana_abs() + 1000:", "un proyecto rechazado se puede volver a presentar de inmediato (sin espera)"),
 ("A03", "sim/motor_agenda.gd", "	if _en_agenda(String(carta[\"id\"])) or _m.estado.proyectos_ley.any(func(p: Dictionary) -> bool: return String(p[\"carta_id\"]) == String(carta[\"id\"])):", "	if _en_agenda(String(carta[\"id\"])):", "se puede presentar una ley que ya espera votación desde la mano"),
 ("A04", "sim/motor_agenda.gd", "	var costo := 0 if delegar else _m.costo_carta(carta, ministro_id)", "	var costo := _m.costo_carta(carta, ministro_id)", "presentar delegado cuesta movimientos"),
 ("A05", "sim/motor_agenda.gd", "	if _m.estado.ind(\"capital\") < float(urg[\"costo_capital\"]):\n		return {\"ok\": false, \"razon\": \"capital_insuficiente\"", "	if _m.estado.ind(\"capital\") <= float(urg[\"costo_capital\"]) - 100.0:\n		return {\"ok\": false, \"razon\": \"capital_insuficiente\"", "se puede presentar con urgencia sin tener el capital"),
 ("A06", "sim/motor_agenda.gd", "		while final.is_empty() and int(p[\"dia_etapa_fin\"]) < limite:", "		while final.is_empty() and int(p[\"dia_etapa_fin\"]) <= limite:", "una etapa se resuelve un día antes de su plazo"),
 ("A07", "sim/motor_agenda.gd", "				_entrar(p, \"tc\" if bool(tc[\"recurso\"]) else \"promulgacion\")", "				_entrar(p, \"promulgacion\")", "el Tribunal Constitucional nunca interviene en la agenda"),
 ("A08", "sim/motor_agenda.gd", "	_m.estado.agenda_rechazos[String(p[\"carta_id\"])] = _m.eventos.semana_abs() + int(_cfg()[\"cooldown_rechazo_semanas\"])", "	_m.estado.agenda_rechazos[String(p[\"carta_id\"])] = _m.eventos.semana_abs()", "tras un rechazo no hay semanas de espera"),
 ("A09", "sim/motor_agenda.gd", "return maxi(1, roundi(float(u[\"dias\"]) * float(_cfg()[\"dias_mixta_frac\"])))", "return maxi(1, roundi(float(u[\"dias\"]) * float(_cfg()[\"dias_mixta_frac\"]) * 2.0))", "la comisión mixta dura el doble"),
 ("A10", "sim/motor_agenda.gd", "	_m.estado.delegadas_turno += 1 if delegar else 0", "	_m.estado.delegadas_turno += 0", "presentar delegado no cuenta como delegación del turno"),
]

MUTANTES += [
 ("A11", "sim/motor_agenda.gd", "		p[\"dia_etapa_fin\"] = mini(int(p[\"dia_etapa_fin\"]), _m.estado.dia_actual + int(urgencia(\"inmediata\")[\"dias\"]))", "		p[\"dia_etapa_fin\"] = maxi(int(p[\"dia_etapa_fin\"]), _m.estado.dia_actual + int(urgencia(\"inmediata\")[\"dias\"]))", "la discusión inmediata puede alargar el plazo en vez de acortarlo"),
 ("A12", "sim/motor_agenda.gd", "		if not ETAPAS_VOTO.has(p[\"etapa\"]) and p[\"etapa\"] != \"comision_mixta\":", "		if false:", "se puede subir la urgencia en etapas donde no corresponde (TC, promulgación)"),
]

# Balas de plata (sim/motor_balas.gd) y presupuesto extra (sim/motor_presupuesto.gd): matan tests/fuzz_balas_presupuesto.gd (B04, B07, B08, P01, P03, P05, P07) y tests/test_balas_bordes.gd (el resto).
MUTANTES += [
 ('BAB01', 'sim/motor_balas.gd', '\t\t\treturn m.gabinete.anio_gobierno() >= int(cond["valor"])', '\t\t\treturn m.gabinete.anio_gobierno() > int(cond["valor"])', 'condición anio_min exige superar el año'),
 ('BAB02', 'sim/motor_balas.gd', 'e.turno_actual - int(e.eventos_ocurridos[String(id)]) <= int(_cfg()["semanas_reciente"])', 'e.turno_actual - int(e.eventos_ocurridos[String(id)]) < int(_cfg()["semanas_reciente"])', 'evento_reciente: borde de la ventana'),
 ('BAB03', 'sim/motor_balas.gd', 'if int(c["oposicion"]) * 2 > int(c["total"]):', 'if int(c["oposicion"]) * 2 >= int(c["total"]):', 'oposición mayoritaria con empate'),
 ('BAB04', 'sim/motor_balas.gd', '\treturn maxi(0, usos_habilitados() - _usadas_del_ciclo().size())', '\treturn maxi(0, usos_habilitados() - _usadas_del_ciclo().size() + 1)', 'un uso de bala de más'),
 ('BAB05', 'sim/motor_balas.gd', '\treturn int(c["usos_max"]) if m.gabinete.anio_gobierno() >= int(c["anio_uso_extra"]) else int(c["usos_iniciales"])', '\treturn int(c["usos_max"]) if m.gabinete.anio_gobierno() > int(c["anio_uso_extra"]) else int(c["usos_iniciales"])', 'el cupo extra se habilita un año tarde'),
 ('BAB06', 'sim/motor_balas.gd', 'maxi(0, ultimo + int(_cfg()["enfriamiento_semanas"]) - m.estado.turno_actual)', 'maxi(0, ultimo + int(_cfg()["enfriamiento_semanas"]) - m.estado.turno_actual - 1)', 'el enfriamiento entre balas dura una semana menos'),
 ('BAB07', 'sim/motor_balas.gd', '\tif _usadas_del_ciclo().has(String(def["id"])):', '\tif false:', 'una bala se puede usar dos veces en el mismo mandato'),
 ('BAB08', 'sim/motor_balas.gd', '\t\tif vedados.has(String(p["tipo_ley"])):\n\t\t\tcontinue', '\t\tif false:\n\t\t\tcontinue', 'el DFL actúa sobre materias vedadas'),
 ('BAB09', 'sim/motor_balas.gd', 'float(r["centro"]) - m.estado.ind(String(r["ind"])))', 'm.estado.ind(String(r["ind"])) - float(r["centro"]))', 'el riesgo de la bala baja cuando el indicador es malo'),
 ('BAB10', 'sim/motor_balas.gd', '\tusadas[id] = [e.ciclo, e.turno_actual]\n\te.balas["usadas"] = usadas', '\te.balas["usadas"] = usadas', 'el uso de la bala no queda registrado'),
 ('BAB11', 'sim/motor_balas.gd', '\tif capital < costo:', '\tif capital <= costo:', 'con capital justo se obliga a la versión reducida'),
 ('BAP01', 'sim/motor_presupuesto.gd', '\tif gastado_anio() + fiscal > float(c["tope_anual_fiscal"]):', '\tif gastado_anio() + fiscal > float(c["tope_anual_fiscal"]) * 2.0:', 'el tope anual de extras se duplica'),
 ('BAP02', 'sim/motor_presupuesto.gd', '\tif e.ind("fiscal") - fiscal < float(c["piso_fiscal"]):', '\tif e.ind("fiscal") - fiscal < float(c["piso_fiscal"]) - 100.0:', 'el piso fiscal del extra se ignora'),
 ('BAP03', 'sim/motor_presupuesto.gd', '\tif _activos().size() >= int(c["max_simultaneos"]):', '\tif _activos().size() > int(c["max_simultaneos"]):', 'un presupuesto simultáneo de más'),
 ('BAP04', 'sim/motor_presupuesto.gd', '\treturn clampf(f, float(a["fraccion_min"]), float(a["fraccion_max"]))', '\treturn f', 'la fracción alineada no se acota'),
 ('BAP05', 'sim/motor_presupuesto.gd', '\tm.fx.sumar_ind("fiscal", -float(n["fiscal"]), "presupuesto extra a un ministerio")', '\tm.fx.sumar_ind("fiscal", float(n["fiscal"]), "presupuesto extra a un ministerio")', 'el presupuesto extra crea fiscal de la nada'),
 ('BAP06', 'sim/motor_presupuesto.gd', '\tlibre[slot] = m.estado.turno_actual + int(_cfg()["enfriamiento_semanas"])', '\tlibre[slot] = m.estado.turno_actual', 'no hay enfriamiento tras terminar un extra'),
 ('BAP07', 'sim/motor_presupuesto.gd', '\tif _activos().has(slot):\n\t\treturn {"ok": false, "razon": "ya_activo"', '\tif false:\n\t\treturn {"ok": false, "razon": "ya_activo"', 'se puede asignar dos veces al mismo ministerio'),
]
