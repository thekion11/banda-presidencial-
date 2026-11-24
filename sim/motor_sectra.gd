class_name MotorSectra
extends RefCounted
## Cartera real del Plan Maestro de Transporte de SECTRA (data/sectra_planes.json). Cada proyecto avanza por etapas
## (perfil -> prefactibilidad -> diseño -> ejecución) al impulsarlo con PA; al llegar a ejecución se convierte en una obra
## con la inversión real (UF -> US$ con una aproximación fija) y un impacto de aprobación regional según su TIR.

var _ref: WeakRef  # referencia débil: evita el ciclo RefCounted motor <-> módulo
var m: MotorTurno:
	get:
		return _ref.get_ref() as MotorTurno
var proyectos: Dictionary = {}  # region_id -> Array[Dictionary]
var _por_id: Dictionary = {}


func _init(p_motor: MotorTurno) -> void:
	_ref = weakref(p_motor)


static func etapa_de(estado_txt: String) -> int:
	## Etapa del plan según el estado publicado por SECTRA. -1 = ya ejecutado o en ejecución (no se gestiona).
	var e := estado_txt.to_lower()
	if e.contains("ejecuci"):
		return -1
	if e.contains("diseño"):
		return 2
	if e.contains("prefactibilidad") or e.contains("prediseño") or e.contains("anteproyecto"):
		return 1
	return 0


func cargar(datos: Dictionary) -> void:
	proyectos.clear()
	_por_id.clear()
	for c in datos.get("ciudades", []):
		var rid := String(c.get("region_id", ""))
		if rid == "" or c.get("proyectos", []).is_empty():
			continue
		var lista: Array[Dictionary] = []
		var i := 0
		for p in c["proyectos"]:
			var et := etapa_de(String(p["estado"]))
			if et >= 0:
				var d := {"id": "%s:%d" % [rid, i], "region": rid, "nombre": String(p["nombre"]),
						"inversion_uf": float(p["inversion_uf"]) if p["inversion_uf"] != null else 0.0,
						"tir": float(p["tir_pct"]) if p["tir_pct"] != null else 0.0, "tiene_tir": p["tir_pct"] != null,
						"mandante": String(p["mandante"]), "estado": String(p["estado"]), "etapa_ini": et, "descripcion": String(p["descripcion"])}
				lista.append(d)
				_por_id[d["id"]] = d
			i += 1
		proyectos[rid] = lista


func existe(pid: String) -> bool:
	return _por_id.has(pid)


func proyecto(pid: String) -> Dictionary:
	return _por_id.get(pid, {})


func estado_de(pid: String) -> Dictionary:
	## Lectura sin efectos: un proyecto sin trámite devuelve su etapa inicial sin tocar el estado de la partida.
	return m.estado.sectra.get(pid, {"etapa": int(_por_id[pid]["etapa_ini"]), "hasta": 0})


func musd(p: Dictionary) -> float:
	return float(p["inversion_uf"]) * float(m.catalogo_leyes["sectra"]["uf_en_usd"]) / 1.0e6


func en_curso() -> int:
	var n := 0
	for k in m.estado.sectra.keys():
		if int(m.estado.sectra[k]["hasta"]) > 0:
			n += 1
	return n


func impulsar(pid: String) -> Dictionary:
	if m.estado.etapa != "gobierno" or not existe(pid):
		return {"ok": false, "razon": "proyecto_no_disponible"}
	var st := estado_de(pid)
	var cfg: Dictionary = m.catalogo_leyes["sectra"]
	if int(st["etapa"]) >= 3 or int(st["hasta"]) > 0:
		return {"ok": false, "razon": "en_tramite_o_terminado"}
	if en_curso() >= int(cfg["max_simultaneos"]):
		return {"ok": false, "razon": "limite_simultaneo"}
	var costo := int(cfg["costo_pa_impulso"])
	if costo > m.estado.pa_actual:
		return {"ok": false, "razon": "pa_insuficiente", "costo": costo}
	m.estado.sectra[pid] = st
	m.estado.registrar_entrada("sectra", {"pid": pid})
	m.estado.pa_actual -= costo
	var semanas := int(cfg["semanas_por_etapa"][int(st["etapa"])])
	st["hasta"] = m.estado.dia_actual + semanas * m.estado.dias_por_turno
	m.estado.registrar_accion("sectra_impulso", {"pid": pid, "etapa": st["etapa"], "semanas": semanas})
	return {"ok": true, "semanas": semanas, "costo": costo}


func avanzar() -> void:
	## Cierre de turno: los proyectos cuyo trámite vence esta semana pasan a la etapa siguiente.
	var limite := m.estado.dia_actual + m.estado.dias_por_turno
	var claves: Array = m.estado.sectra.keys()
	claves.sort()
	for pid in claves:
		var st: Dictionary = m.estado.sectra[pid]
		if int(st["hasta"]) > 0 and int(st["hasta"]) < limite:
			st["hasta"] = 0
			st["etapa"] = int(st["etapa"]) + 1
			m.estado.registrar_accion("sectra_etapa", {"pid": pid, "etapa": st["etapa"]})
			if int(st["etapa"]) >= 3:
				_iniciar_ejecucion(String(pid))


func _iniciar_ejecucion(pid: String) -> void:
	var p: Dictionary = _por_id[pid]
	var cfg: Dictionary = m.catalogo_leyes["sectra"]
	var mm := musd(p)
	m.fx.sumar_ind("fiscal", -minf(float(cfg["tope_fiscal"]), mm * float(cfg["fiscal_por_musd"])))
	var tir := float(p["tir"])
	if bool(p["tiene_tir"]) and tir < 0.0:
		m.fx.sumar_ind("riesgo_ejecucion", float(cfg["riesgo_tir_negativa"]))
	var apr := clampf(float(cfg["aprobacion_base"]) + tir * float(cfg["aprobacion_por_tir"]), float(cfg["piso_aprobacion_obra"]), float(cfg["aprobacion_max"]))
	var dias := int(clampf(float(cfg["dias_base_obra"]) + mm * float(cfg["dias_por_musd"]), float(cfg["dias_base_obra"]), float(cfg["dias_max_obra"])))
	m.obras.iniciar(m.estado, String(p["nombre"]), dias, String(p["region"]), "", [{"ind": "aprobacion", "delta": apr}], {"sectra": pid})
