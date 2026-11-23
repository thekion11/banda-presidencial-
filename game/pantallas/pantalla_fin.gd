class_name PantallaFin
extends Control
## Fin de partida con resumen: puntaje, promesas cumplidas, leyes aprobadas, obras terminadas y línea de tiempo
## de los eventos reales vividos (fecha y fuente). Solo lee el estado.

signal otra_vez

var motor: MotorTurno
var datos: Dictionary = {}

const MESES := ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]


static func fecha_corta(iso: String) -> String:
	var p := iso.split("-")
	if p.size() != 3:
		return iso
	return "%d %s %s" % [int(p[2]), MESES[clampi(int(p[1]) - 1, 0, 11)], p[0]]


func _fuente_texto(id_ref: String) -> String:
	var id := id_ref.get_slice("#", 1) if "#" in id_ref else id_ref
	for f in datos.get("fuentes", []):
		if String(f["id"]) == id:
			return "%s (corte %s)" % [f["institucion"], f["fecha_corte"]]
	return id_ref


func leyes_aprobadas() -> Array[String]:
	var res: Array[String] = []
	for a in motor.estado.registro_acciones:
		if a["tipo"] == "votacion" and bool(a["detalle"].get("aprobada", false)) and motor._cartas_por_id.has(a["detalle"]["carta"]):
			res.append(String(motor._cartas_por_id[a["detalle"]["carta"]]["titulo"]))
	return res


func eventos_reales() -> Array[Dictionary]:
	## Eventos con fecha real que ocurrieron en la partida, en orden cronológico.
	var res: Array[Dictionary] = []
	for e in motor.catalogo_eventos:
		if motor.estado.eventos_ocurridos.has(String(e["id"])) and e.get("meta", {}).has("fecha_real"):
			res.append(e)
	res.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["meta"]["fecha_real"]) < String(b["meta"]["fecha_real"]))
	return res


func _dato(titulo: String, valor: String) -> Control:
	var v := FilasUI.col(0)
	v.add_child(Tema.etiqueta(valor, 22, Tema.ORO, true))
	v.add_child(Tema.etiqueta(titulo, 11, Tema.TEXTO_SUAVE))
	var p := FilasUI.tarjeta(v)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


func _ready() -> void:
	var est := motor.estado
	var r := est.resultado_final
	add_child(Tema.fondo_hero("politica" if est.etapa == "fin_mandato" else "seguridad", 0.34, 0.0 if est.etapa == "fin_mandato" else 0.35))
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 20
	col.offset_right = -20
	col.offset_top = 210
	col.offset_bottom = -113
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	var titulos := {"fin_mandato": "Fin del mandato", "crisis": "Caída del gobierno", "derrota_electoral": "Derrota electoral"}
	col.add_child(Tema.etiqueta("FIN DE PARTIDA", 10, Tema.ORO, true))
	col.add_child(Tema.etiqueta(String(titulos.get(est.etapa, "Fin")), 30, Tema.TEXTO, true))
	var umbral := float(motor.catalogo_leyes["hemiciclo"]["umbral_victoria_presidencial"])
	var detalle := ""
	match est.etapa:
		"derrota_electoral":
			detalle = "Tu aprobación el día de la elección fue %.1f %%, bajo el umbral de %.0f %%. No alcanzaste la presidencia." % [float(r.get("voto_final", 0.0)), umbral]
		"crisis":
			detalle = "Tu aprobación se desplomó y el gobierno no resistió la crisis política en el turno %d." % est.turno_actual
		_:
			detalle = "Completaste los 4 años con %.1f %% de aprobación." % float(r.get("aprobacion", 0.0))
	col.add_child(Tema.etiqueta(detalle, 13, Tema.TEXTO_SUAVE))
	var lista := FilasUI.col(8)
	var total_prom := est.promesas_campana.size()
	var leyes := leyes_aprobadas()
	var fila1 := HBoxContainer.new()
	fila1.add_theme_constant_override("separation", 8)
	fila1.add_child(_dato("Puntaje final", str(int(r.get("puntaje", 0)))))
	fila1.add_child(_dato("Promesas cumplidas", "%d de %d" % [total_prom - est.promesas_pendientes().size(), total_prom]))
	lista.add_child(fila1)
	var fila2 := HBoxContainer.new()
	fila2.add_theme_constant_override("separation", 8)
	fila2.add_child(_dato("Leyes aprobadas", str(leyes.size())))
	fila2.add_child(_dato("Obras terminadas", str(est.obras_terminadas.size())))
	lista.add_child(fila2)
	if not leyes.is_empty():
		lista.add_child(FilasUI.titulo("Leyes aprobadas"))
		for t in leyes.slice(0, 8):
			lista.add_child(Tema.etiqueta("· " + t, 12, Tema.TEXTO))
		if leyes.size() > 8:
			lista.add_child(Tema.etiqueta("y %d más." % (leyes.size() - 8), 11, Tema.TEXTO_SUAVE))
	lista.add_child(FilasUI.titulo("Línea de tiempo: eventos reales que viviste"))
	var evs := eventos_reales()
	if evs.is_empty():
		lista.add_child(Tema.etiqueta("No viviste eventos con fecha real en esta partida.", 12, Tema.TEXTO_SUAVE))
	for e in evs:
		var v := FilasUI.col(1)
		v.add_child(Tema.etiqueta("%s · %s" % [fecha_corta(String(e["meta"]["fecha_real"])), String(e["titulo"]) if String(e["titulo"]).length() <= 70 else String(e["titulo"]).substr(0, 69) + "…"], 12, Tema.TEXTO, false, 600))
		v.add_child(Tema.etiqueta("Fuente: " + _fuente_texto(String(e.get("fuente", ""))), 10, Tema.TEXTO_SUAVE))
		lista.add_child(FilasUI.tarjeta(v, Tema.PANEL))
	lista.add_child(Tema.etiqueta("Huella de la partida (para reproducirla): " + est.calcular_huella().substr(0, 16), 10, Tema.TEXTO_SUAVE))
	col.add_child(FilasUI.scroll(lista))
	var b := FilasUI.boton_pie("Volver al inicio")
	b.pressed.connect(func() -> void: otra_vez.emit())
	add_child(b)
