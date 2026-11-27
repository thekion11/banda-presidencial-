extends SceneTree
## D26 (informe, no prueba del CI): minutos por mandato con el bot «humano» y cuatro opciones de ritmo, usando los tiempos «típico» de docs/DURACION_SESION.md.
## Mide por semana de gobierno: eventos (informativos y decisiones), votaciones, cartas jugadas y delegadas, y cuántas semanas quedan «vacías».
## Uso: godot --headless --path . -s tests/analisis_ritmo_d26.gd -- [mandatos]

const T_BASE := 6.0
const T_CARTA := 5.0
const T_DELEGAR := 6.0
const T_DECISION := 20.0
const T_INFO := 4.0
const T_VOTO := 5.0
const T_TELON_SALTADO := 1.5  # una semana saltada: solo el aviso automático


func _init() -> void:
	var n := int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 12
	var datos := Datos.cargar_todo()
	var sem := 0
	var s := {"eventos": 0, "decisiones": 0, "votos": 0, "cartas": 0, "deleg": 0, "internos": 0, "vacias": 0, "vacias_sin_cartas": 0, "cartas_simples": 0}
	for i in range(n):
		var m := Bots.partida_completa(datos, 8000 + i, "humano", "")
		var e := m.estado
		if e.ciclo > 1 or e.registro_acciones.is_empty():
			continue
		var por_semana := {}  # turno -> {ev, dec, voto, carta, deleg}
		for a in e.registro_acciones:
			if a["etapa"] != "gobierno":
				continue
			var t := int(a["turno"])
			if not por_semana.has(t):
				por_semana[t] = {"ev": 0, "dec": 0, "voto": 0, "carta": 0, "deleg": 0, "int": 0, "simples": 0}
			var w: Dictionary = por_semana[t]
			var d: Dictionary = a["detalle"]
			match String(a["tipo"]):
				"evento":
					w["ev"] += 1
				"decision":
					w["dec"] += 1
				"votacion":
					w["voto"] += 1
				"carta":
					if bool(d.get("delegada", false)):
						w["deleg"] += 1
					else:
						w["carta"] += 1
					var c: Dictionary = m._cartas_por_id.get(String(d.get("id", "")), {})
					if not c.is_empty() and not c.has("riesgo") and not c.has("diferido") and not c.has("obra") and c["requisitos"]["ley"] == null and c.get("abre_propuesta_comite", null) == null:
						w["simples"] += 1
				"meta", "sector", "reducir_errores", "acelerar_proyecto":
					w["int"] += 1
		for t in range(1, m.turnos_mandato() + 1):
			var w: Dictionary = por_semana.get(t, {"ev": 0, "dec": 0, "voto": 0, "carta": 0, "deleg": 0, "int": 0, "simples": 0})
			sem += 1
			s["eventos"] += w["ev"] - w["dec"]
			s["decisiones"] += w["dec"]
			s["votos"] += w["voto"]
			s["cartas"] += w["carta"]
			s["deleg"] += w["deleg"]
			s["internos"] += w["int"]
			s["cartas_simples"] += w["simples"]
			if w["ev"] == 0 and w["dec"] == 0 and w["voto"] == 0:
				s["vacias"] += 1
				if w["carta"] + w["deleg"] == 0:
					s["vacias_sin_cartas"] += 1
	var f := float(maxi(sem, 1))
	var seg_igual: float = (T_BASE * f + T_CARTA * s["cartas"] + T_DELEGAR * s["deleg"] + T_DECISION * s["decisiones"] + T_INFO * s["eventos"] + T_VOTO * s["votos"] + 6.0 * s["internos"])
	var ahorro_saltar: float = (T_BASE - T_TELON_SALTADO) * s["vacias_sin_cartas"]
	var ahorro_auto: float = T_CARTA * s["cartas_simples"]
	var ahorro_dos: float = T_BASE * f / 2.0
	print("RITMO semanas=%d mandatos=%d por semana: cartas=%.2f deleg=%.2f eventos=%.2f decisiones=%.2f votos=%.2f internos=%.2f" % [sem, n, s["cartas"] / f, s["deleg"] / f, s["eventos"] / f, s["decisiones"] / f, s["votos"] / f, s["internos"] / f])
	print("RITMO semanas vacías (sin evento ni votación): %.1f %% ; sin cartas jugadas además: %.1f %% ; cartas simples (sin riesgo, diferido, ley ni obra): %.1f %% de las jugadas" % [100.0 * s["vacias"] / f, 100.0 * s["vacias_sin_cartas"] / f, 100.0 * s["cartas_simples"] / maxf(1.0, float(s["cartas"] + s["deleg"]))])
	var por := f / float(n)
	print("RITMO minutos por mandato (%.0f semanas): igual=%.0f ; avisos+saltar vacías=%.0f ; +auto-jugar obvias=%.0f ; turno de 2 semanas=%.0f" % [por, seg_igual / 60.0 / n, (seg_igual - ahorro_saltar) / 60.0 / n, (seg_igual - ahorro_saltar - ahorro_auto) / 60.0 / n, (seg_igual - ahorro_dos) / 60.0 / n])
	quit()
