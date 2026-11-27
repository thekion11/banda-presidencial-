class_name AyudaFuzz
extends RefCounted
## Utilidades de los fuzzers: una acción aleatoria (válida o inválida) sobre el motor y la comparación de dos motores propiedad por propiedad.


static func accion(m: MotorTurno, rng: RandomNumberGenerator) -> void:
	var e := m.estado
	var basura := ["", "xx", "no_existe", "-1", " "]
	match rng.randi_range(0, 13):
		0, 1, 2:
			m.jugar_carta(rng.randi_range(-2, 7), "", "")
		3:
			var reg := ""
			if not m.regiones.catalogo.is_empty() and rng.randf() < 0.7:
				reg = String(m.regiones.catalogo[rng.randi_range(0, m.regiones.catalogo.size() - 1)]["id"])
			m.jugar_carta(rng.randi_range(0, 4), "", reg)
		4:
			var mins: Array = e.gabinete if not e.gabinete.is_empty() and rng.randf() < 0.8 else basura
			m.delegar_carta(rng.randi_range(-1, 6), String(mins[rng.randi_range(0, mins.size() - 1)]))
		5:
			var metas := m.movimientos.metas_disponibles()
			if not metas.is_empty() and rng.randf() < 0.7:
				m.buscar_meta(String(metas[rng.randi_range(0, metas.size() - 1)]["id"]))
			else:
				m.buscar_meta(basura[rng.randi_range(0, 4)])
		6:
			var sectores: Array = e.indices_sector.keys() + basura
			m.ajustar_sector(String(sectores[rng.randi_range(0, sectores.size() - 1)]), rng.randi_range(-2, 2))
		7:
			m.reducir_errores()
		8:
			m.acelerar_proyecto(rng.randi_range(-1, 4))
		9:
			var ids: Array = m.equipo.asesores.keys() + basura
			var id := String(ids[rng.randi_range(0, ids.size() - 1)])
			if rng.randf() < 0.5:
				m.contratar_asesor(id)
			else:
				m.despedir_asesor(id)
		10:
			var ids: Array = m.coalicion.partidos.keys() + basura
			var id := String(ids[rng.randi_range(0, ids.size() - 1)])
			if rng.randf() < 0.6:
				m.unirse_coalicion(id)
			else:
				m.salir_coalicion(id)
		11:
			var ids: Array = m.coalicion.partidos.keys() + basura
			var id := String(ids[rng.randi_range(0, ids.size() - 1)])
			var tipos := ["ministro", "asesor", "xx"]
			var vals: Array = e.gabinete + basura
			var t := String(tipos[rng.randi_range(0, 2)])
			var v := String(vals[rng.randi_range(0, vals.size() - 1)])
			if rng.randf() < 0.5:
				m.asignar_cuota(id, t, v)
			else:
				m.quitar_cuota(id, t, v)
		12:
			if not e.propuestas_abiertas.is_empty():
				var vs := ["A", "B", "C", "Z"]
				m.aprobar_propuesta(String(e.propuestas_abiertas[0]), String(vs[rng.randi_range(0, 3)]))
			else:
				m.aprobar_propuesta("no_existe", "A")
		13:
			m.impulsar_proyecto(String(basura[rng.randi_range(0, 4)]))


static func props(m: MotorTurno) -> Dictionary:
	var d := {}
	for pr in m.estado.get_property_list():
		if int(pr["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			d[pr["name"]] = Huella.texto(m.estado.get(pr["name"])).sha256_text()
	d["_rng"] = "%d:%d" % [m.rng.seed, m.rng.state]
	d["_ultimos"] = Huella.texto(m.ultimos_eventos).sha256_text()
	return d


static func diferencias(a: MotorTurno, b: MotorTurno) -> Array[String]:
	var pa := props(a)
	var pb := props(b)
	var dif: Array[String] = []
	for k in pa.keys():
		if pa[k] != pb.get(k, ""):
			dif.append(k)
	return dif
