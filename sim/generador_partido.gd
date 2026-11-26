class_name GeneradorPartido
extends RefCounted
## Test ideológico -> partido propio. Fórmulas de la Enmienda de Cierre, sección 2.


static func calcular_ejes(respuestas: Array) -> Vector2:
	## Ejes ideológicos (económico, institucional) a partir de las respuestas del test.
	var eco: float = 0.0
	var inst: float = 0.0
	for resp in respuestas:
		eco += float(resp.get("delta_eco", 0.0))
		inst += float(resp.get("delta_inst", 0.0))
	return Vector2(clampf(eco, -1.0, 1.0), clampf(inst, -1.0, 1.0))


static func perfil_para(eco: float, inst: float, catalogo: Dictionary) -> String:
	## Perfil 2D mostrado en vivo en la franja crema. Primer perfil que calza; si ninguno, arquetipo por eje económico.
	for p in catalogo.get("perfiles", []):
		if eco >= float(p["eco_min"]) and eco <= float(p["eco_max"]) \
				and inst >= float(p["inst_min"]) and inst <= float(p["inst_max"]):
			return String(p["nombre"])
	return arquetipo_para(eco, catalogo)


static func arquetipo_para(eco: float, catalogo: Dictionary) -> String:
	## Arquetipo de partido (texto del catálogo de ideología) para un eje económico dado.
	var nombre := "Coalición Reformista"
	for arq in catalogo.get("arquetipos", []):
		if eco >= float(arq["eco_min"]) and eco <= float(arq["eco_max"]):
			nombre = String(arq["nombre"])
			break
	return nombre


static var _escanos: Dictionary = {}


static func escanos_para(eco: float, inst: float) -> int:
	## Escaños propios según la distancia al centro; los números viven en data/ideologia.json › escanos.
	if _escanos.is_empty():
		_escanos = Datos.leer_json("res://data/ideologia.json")["escanos"]
	return clampi(roundi(float(_escanos["base"]) - float(_escanos["pendiente"]) * sqrt(eco * eco + inst * inst)), int(_escanos["min"]), int(_escanos["max"]))


static func construir_partido_afiliado(afiliacion: String, base: Dictionary, nombre: String, sigla: String, region_bastion: String,
		respuestas: Array[Dictionary], catalogo_ideologia: Dictionary, cfg: Dictionary) -> Dictionary:
	## Partido según la afiliación (PR-01): propio, independiente o existente (base = partido de data/coalicion.json). Todo número viene de cfg (leyes.json "afiliacion").
	var op: Dictionary = cfg["opciones"][afiliacion]
	var p := construir_partido(nombre, sigla, region_bastion, respuestas, catalogo_ideologia)
	if afiliacion == "existente":
		var ide: Dictionary = base["ideologia"]
		var peso := float(op["peso_postura"])
		var ejes := calcular_ejes(respuestas)
		p["eje_eco"] = clampf(float(ide["eco"]) + peso * ejes.x, -1.0, 1.0)
		p["eje_inst"] = clampf(float(ide["inst"]) + peso * ejes.y, -1.0, 1.0)
		p["arquetipo"] = arquetipo_para(p["eje_eco"], catalogo_ideologia)
		p["perfil"] = perfil_para(p["eje_eco"], p["eje_inst"], catalogo_ideologia)
		p["escanos_propios"] = maxi(int(op["escanos_min"]), roundi(float(base["escanos_senado"]) * float(op["escanos_mult"])))
		p["partido_base"] = String(base["id"])
	elif afiliacion == "independiente":
		p["escanos_propios"] = maxi(int(op["escanos_min"]), roundi(float(p["escanos_propios"]) * float(op["escanos_factor"])))
	var ind: Dictionary = p["indicadores_iniciales"]
	ind["aprobacion"] = clampf(float(ind["aprobacion"]) + float(op["aprobacion"]), 0.0, 100.0)
	ind["cohesion"] = clampf(float(ind["cohesion"]) + float(op["cohesion"]), 0.0, 100.0)
	p["afiliacion"] = afiliacion
	return p


static func aplicar_habilidad(partido: Dictionary, habilidad: String, color: String, cfg: Dictionary) -> void:
	## PR-16/PR-15: la habilidad suma a los indicadores iniciales (datos en leyes.json «habilidades»); el color es solo apariencia (debe estar en la paleta).
	var op: Dictionary = cfg["opciones"].get(habilidad, cfg["opciones"][cfg["defecto"]])
	var ind: Dictionary = partido["indicadores_iniciales"]
	for k in ["aprobacion", "capital", "cohesion", "fiscal"]:
		if op.has(k):
			ind[k] = clampf(float(ind[k]) + float(op[k]), 0.0, 100.0)
	partido["habilidad"] = habilidad if cfg["opciones"].has(habilidad) else String(cfg["defecto"])
	partido["color_emblema"] = color if (cfg["colores"] as Array).has(color) else String(cfg["colores"][0])


static func construir_partido(
		nombre: String,
		sigla: String,
		region_bastion: String,
		respuestas: Array[Dictionary],
		catalogo_ideologia: Dictionary
) -> Dictionary:
	## Arma el diccionario del partido del jugador (ejes, perfil, escaños, indicadores iniciales) desde su nombre, región y respuestas.
	var ejes := calcular_ejes(respuestas)
	var eco: float = ejes.x
	var inst: float = ejes.y
	var distancia := sqrt(eco * eco + inst * inst)

	var f: Dictionary = catalogo_ideologia["inicio"]  # fórmulas en data/ideologia.json
	var cohesion_ini := float(roundi(float(f["cohesion"]["base"]) + float(f["cohesion"]["k"]) * distancia))
	var fiscal_ini := float(roundi(float(f["fiscal"]["base"]) + float(f["fiscal"]["k"]) * eco))
	var capital_ini := float(roundi(float(f["capital"]["base"]) + float(f["capital"]["k"]) * inst))
	var fa: Dictionary = f["aprobacion"]
	var aprobacion_ini := clampf(float(fa["base"]) + float(fa["k"]) * (1.0 - distancia * float(fa["atenuacion_distancia"])), float(fa["min"]), float(fa["max"]))

	return {
		"nombre": nombre.strip_edges(),
		"sigla": sigla.strip_edges().to_upper(),
		"region_bastion": region_bastion,
		"eje_eco": eco,
		"eje_inst": inst,
		"arquetipo": arquetipo_para(eco, catalogo_ideologia),
		"perfil": perfil_para(eco, inst, catalogo_ideologia),
		"escanos_propios": escanos_para(eco, inst),
		"indicadores_iniciales": {
			"aprobacion": aprobacion_ini,
			"capital": capital_ini,
			"cohesion": cohesion_ini,
			"fiscal": fiscal_ini,
			"riesgo_ejecucion": float(f["riesgo_ejecucion"]),
			"viviendas_anio": float(f["viviendas_anio"])
		}
	}
