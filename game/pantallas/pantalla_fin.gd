class_name PantallaFin
extends Control
## Fin de partida con resumen: puntaje, promesas cumplidas, leyes aprobadas, obras terminadas y línea de tiempo
## de los eventos reales vividos (fecha y fuente). Solo lee el estado.

signal otra_vez
signal continuar  # la carrera sigue: oposición o campaña de reelección (carrera política)
signal reintentar  # solo tras una derrota electoral: nueva partida directa

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
	var cifra := Tema.etiqueta(valor, 22, Tema.ORO, true)
	if valor.is_valid_int():  # las cifras del resumen cuentan hasta su valor
		Movimiento.contar(cifra, float(valor.to_int()), func(x: float) -> String: return str(roundi(x)), 0.0, 1.0, 0.35)
	v.add_child(cifra)
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
	var epi := motor.mandato.epilogo()
	col.add_child(Tema.etiqueta(String(titulos.get(est.etapa, "Fin")), 30, Tema.TEXTO, true))
	if String(epi["id"]) != "":
		col.add_child(Tema.etiqueta(String(epi["titulo"]), 16, Tema.ORO, true))
	var umbral := float(motor.catalogo_leyes["hemiciclo"]["umbral_victoria_presidencial"]) + float(motor.mandato.nivel()["umbral_delta"])
	var detalle := ""
	match est.etapa:
		"derrota_electoral":
			detalle = "Tu aprobación el día de la elección fue %s %%, bajo el umbral de %.0f %%. No alcanzaste la presidencia." % [Tema.dec(float(r.get("voto_final", 0.0))), umbral]
		"crisis":
			detalle = "Tu aprobación se desplomó y el gobierno no resistió la crisis política en el turno %d." % est.turno_actual
		_:
			detalle = "Completaste los 4 años con %s %% de aprobación." % Tema.dec(float(r.get("aprobacion", 0.0)))
	col.add_child(Tema.etiqueta(detalle, 13, Tema.TEXTO_SUAVE))
	if motor.mandato.sucesion() != "":
		var su := Tema.etiqueta("Sucesión: " + motor.mandato.sucesion(), 12, Tema.ORO)
		su.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(su)
	if String(epi["texto"]) != "":
		var et := Tema.etiqueta(String(epi["texto"]), 12, Tema.TEXTO)
		et.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(et)
	var lista := FilasUI.col(8)
	var reelige := est.etapa == "fin_mandato" and est.cartas_ejecutadas.has("reforma_reeleccion")
	var bo := Tema.boton("Postularte a la reelección" if reelige else "Seguir tu carrera: pasar a la oposición", Tema.ROJO, Tema.TEXTO, 14, 48)
	bo.pressed.connect(func() -> void: continuar.emit())
	lista.add_child(bo)
	if not est.carrera.is_empty():
		lista.add_child(FilasUI.titulo("Tu carrera política"))
		for c in est.carrera:
			lista.add_child(Tema.etiqueta("· Periodo %d: %s (aprobación %.0f %%)" % [int(c["ciclo"]), String({"fin_mandato": "mandato completo", "crisis": "gobierno caído", "derrota_electoral": "derrota electoral"}.get(c["resultado"], c["resultado"])), float(c["aprobacion"])], 12, Tema.TEXTO))
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
	if not est.lineas_jugador.is_empty():
		lista.add_child(FilasUI.titulo("Líneas de Metro que creaste"))
		for ln in est.lineas_jugador:
			var v2 := FilasUI.col(1)
			v2.add_child(Tema.etiqueta("%s · %s" % [ln["id"], String(ln["nombre"])], 12, Tema.TEXTO, false, 600))
			v2.add_child(Tema.etiqueta("%d estaciones · %s" % [(ln["nombres_estaciones"] as Array).size(), "operativa" if ln["estado"] == "operativa" else "en construcción al terminar el mandato"], 10, Tema.TEXTO_SUAVE))
			lista.add_child(FilasUI.tarjeta(v2, Tema.PANEL))
	var hitos := motor.mandato.hitos()
	if not hitos.is_empty():
		lista.add_child(FilasUI.titulo("Hitos de tu mandato"))
		for h in hitos:
			lista.add_child(Tema.etiqueta("· Semana %d: %s" % [int(h["turno"]), String(h["texto"])], 12, Tema.TEXTO))
	var actores := motor.eventos.relaciones_actores()
	if not actores.is_empty():
		lista.add_child(FilasUI.titulo("Tu relación con los actores"))
		for a in actores.slice(0, 6):
			lista.add_child(Tema.etiqueta("· %s: %d/100" % [String(a["nombre"]), roundi(float(a["relacion"]))], 12, Tema.TEXTO))
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
	Movimiento.escalonar(col, 0.05, 0.05)
	Movimiento.escalonar(lista, 0.3, 0.04, 10)
	var derrota := est.etapa == "derrota_electoral"
	var b := FilasUI.boton_pie("Intentar de nuevo" if derrota else "Volver al inicio")
	b.pressed.connect(func() -> void: (reintentar if derrota else otra_vez).emit())
	add_child(b)
	if derrota:
		col.offset_bottom = -163.0
		var sec := Tema.boton("Volver al inicio", Color.TRANSPARENT, Tema.TEXTO, 13, 44)
		for e in ["normal", "hover", "pressed", "focus"]:
			sec.add_theme_stylebox_override(e, Tema.caja(Color(0, 0, 0, 0), 22, Color("#5D7A94"), 1))
		sec.anchor_top = 1.0
		sec.anchor_bottom = 1.0
		sec.anchor_right = 1.0
		sec.offset_left = 16.0
		sec.offset_right = -16.0
		sec.offset_top = -157.0
		sec.offset_bottom = -113.0
		sec.pressed.connect(func() -> void: otra_vez.emit())
		add_child(sec)
