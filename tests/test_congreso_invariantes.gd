extends SceneTree
## Congreso: invariantes de escaños y quórum por dificultad, afiliación y coalición. Las cámaras siempre suman su total, nadie tiene escaños negativos, los mínimos de cada
## tipo de ley caben en la cámara, y una votación se aprueba exactamente cuando alcanza el mínimo en las dos cámaras.

var _fallos := 0
var _votaciones := 0

func _check(c: bool, msg: String) -> void:
	if not c:
		print("FALLO: ", msg)
		_fallos += 1


func _init() -> void:
	var datos := Datos.cargar_todo()
	var h: Dictionary = datos["leyes"]["hemiciclo"]
	var n_sen := int(h["total_senadores"])
	var n_dip := int(h["total_diputados"])
	var cfg_af: Dictionary = datos["leyes"]["afiliacion"]
	var resp: Array[Dictionary] = []
	for p in datos["ideologia"]["preguntas"]:
		resp.append(p["opciones"][1])
	for dif in ["facil", "normal", "dificil"]:
		for afil in ["propio", "independiente", "existente"]:
			var base: Dictionary = datos["coalicion"][4] if afil == "existente" else {}
			var partido := GeneradorPartido.construir_partido_afiliado(afil, base, "I", "III", "metropolitana", resp.slice(0, 3) if afil == "existente" else resp, datos["ideologia"], cfg_af)
			partido["dificultad"] = dif
			var etiqueta := "%s/%s" % [dif, afil]
			var m := Partida.crear(datos, 77, partido)
			m.estado.etapa = "gobierno"  # solo para consultar el Congreso: no se juega
			_check(int(m.estado.partido["escanos_propios"]) >= 1 and int(m.estado.partido["escanos_propios"]) <= n_sen, etiqueta + ": escaños propios dentro del Senado")
			for t in m.legal.leyes["tipos_ley"]:
				_check(int(t["votos_minimos"]) >= 1 and int(t["votos_minimos"]) <= n_sen, "%s: mínimo del Senado de %s (%d)" % [etiqueta, t["id"], int(t["votos_minimos"])])
				_check(int(t["votos_minimos_camara"]) >= 1 and int(t["votos_minimos_camara"]) <= n_dip, "%s: mínimo de la Cámara de %s (%d)" % [etiqueta, t["id"], int(t["votos_minimos_camara"])])
			# coalición completa (3 aliados) con satisfacciones extremas
			var ids: Array = datos["coalicion"].map(func(p: Dictionary) -> String: return p["id"])
			for id in ids.slice(0, int(datos["leyes"]["coalicion"]["max_aliados"])):
				m.unirse_coalicion(String(id))
			for sat in [0.0, 50.0, 100.0]:
				for id in m.estado.coalicion.keys():
					m.estado.coalicion[id]["satisfaccion"] = sat
				m.coalicion._recalcular_apoyo()
				for camara in [false, true]:
					var comp: Dictionary = m.legal.composicion(m.estado, camara)
					var total := n_dip if camara else n_sen
					_check(int(comp["propios"]) >= 0 and int(comp["aliados"]) >= 0 and int(comp["oposicion"]) >= 0, "%s sat %.0f: bloques no negativos %s" % [etiqueta, sat, str(comp)])
					_check(int(comp["propios"]) + int(comp["aliados"]) <= total, "%s sat %.0f: propios + aliados no pasan del total de la cámara %s" % [etiqueta, sat, str(comp)])
					_check(int(comp["propios"]) + int(comp["aliados"]) + int(comp["oposicion"]) >= total or int(comp["oposicion"]) == 0, "%s sat %.0f: los bloques cubren la cámara %s" % [etiqueta, sat, str(comp)])
				for t in m.legal.leyes["tipos_ley"]:
					for _k in range(5):
						var v := m.legal.votar(m.estado, String(t["id"]))
						if bool(v.get("sin_votacion", false)):
							continue
						_votaciones += 1
						_check(int(v["senado"]) >= 0 and int(v["senado"]) <= n_sen and int(v["camara"]) >= 0 and int(v["camara"]) <= n_dip, "%s: votos dentro de las cámaras (%d, %d)" % [etiqueta, int(v["senado"]), int(v["camara"])])
						_check(bool(v["aprobada"]) == (int(v["senado"]) >= int(v["min_senado"]) and int(v["camara"]) >= int(v["min_camara"])), "%s: aprobada solo si alcanza el mínimo en las dos cámaras" % etiqueta)
						_check(int(v["contra_senado"]) >= 0 and int(v["abst_senado"]) >= 0 and int(v["senado"]) + int(v["abst_senado"]) + int(v["contra_senado"]) == n_sen, "%s: a favor + abstención + en contra = Senado" % etiqueta)
	print("test_congreso_invariantes: %d votaciones revisadas" % _votaciones)
	print("test_congreso_invariantes: ", "OK" if _fallos == 0 else "FALLO")
	quit(1 if _fallos > 0 else 0)
