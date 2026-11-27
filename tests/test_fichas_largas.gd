extends SceneTree
## Texto largo (cola 5 de la coordinadora): la ficha ampliada de cada carta de data/ y la pantalla de cada evento de
## data/, con «Texto grande» (×1,15) y con letra ×1,5, en 390×844 y en el teléfono bajo 390×693. Ninguna ficha
## desborda su hoja ni se sale por arriba, y en cada evento el texto y sus botones quedan en pantalla (≥ 44 px).
## Imprime el largo máximo de títulos y descripciones y las piezas que no caben (para proponer recortes de datos).

const ESCALAS := [1.15, 1.5]
const ALTOS := [844, 693]

var _fallos := 0
var _malas := {}  # id -> motivo (una vez por pieza)


func _check(c: bool, id: String, msg: String) -> void:
	if not c:
		_fallos += 1
		if not _malas.has(id):
			_malas[id] = msg


func _init() -> void:
	_correr.call_deferred()


func _evento_ui(evt: Dictionary) -> Dictionary:
	## Lo que la interfaz recibe de MotorEventos.aplicar_evento (con el texto extra de las decisiones con Congreso).
	var res := {"id": evt["id"], "titulo": evt["titulo"], "descripcion": evt["descripcion"], "hora": evt["hora_etiqueta"], "votacion": null, "efectos": evt["efectos_base"]}
	if evt.has("opciones"):
		res["opciones"] = evt["opciones"]
		res["efectos"] = []
		if (evt["opciones"] as Array).any(func(o: Dictionary) -> bool: return o.has("congreso")):
			res["descripcion"] = "%s Con tu bancada y tus aliados, tu postura prospera con un %d %% de probabilidad." % [String(evt["descripcion"]), 55]
	if evt.has("escena"):
		res["escena"] = evt["escena"]
	return res


func _correr() -> void:
	Movimiento.forzado = 0
	var datos := Datos.cargar_todo()
	var leyes: Dictionary = datos["leyes"]
	var cartas: Array = datos["cartas"]
	var eventos: Array = (datos["eventos"] as Array).filter(func(e: Dictionary) -> bool: return e.get("votacion", null) == null)
	var largo := {"titulo_carta": "", "titulo_evento": "", "desc_evento": ""}
	for c in cartas:
		if String(c["titulo"]).length() > String(largo["titulo_carta"]).length():
			largo["titulo_carta"] = String(c["titulo"])
	for e in eventos:
		if String(e["titulo"]).length() > String(largo["titulo_evento"]).length():
			largo["titulo_evento"] = String(e["titulo"])
		if String(e["descripcion"]).length() > String(largo["desc_evento"]).length():
			largo["desc_evento"] = String(e["descripcion"])
	for k in largo.keys():
		print("más largo · %s: %d caracteres («%s»)" % [k, String(largo[k]).length(), String(largo[k]).left(70)])
	print("piezas: %d cartas, %d eventos sin votación" % [cartas.size(), eventos.size()])
	for alto in ALTOS:
		root.content_scale_size = Vector2i(390, alto)
		for esc in ESCALAS:
			Ajustes.escala_prueba = esc
			var tag := "[%d, ×%s]" % [alto, str(esc)]
			for c in cartas:
				var f := FichaAmpliada.crear(c, int(c.get("costo_pa", 1)), leyes)
				root.add_child(f)
				await process_frame
				await process_frame
				var marco: Control = f.get_child(1)
				var hoja: Control = marco.get_child(0)
				var necesita := hoja.get_combined_minimum_size().y
				_check(necesita <= marco.size.y + 0.5, String(c["id"]), "%s ficha de «%s»: necesita %d px y la hoja mide %d" % [tag, String(c["titulo"]).left(40), necesita, marco.size.y])
				_check(marco.get_global_rect().position.y >= Tema.margen_superior() - 0.5, String(c["id"]), "%s ficha de «%s»: se sale por arriba (y = %d)" % [tag, String(c["titulo"]).left(40), marco.get_global_rect().position.y])
				_check(marco.get_global_rect().end.y <= alto + 0.5, String(c["id"]), "%s ficha de «%s»: se sale por abajo (%d)" % [tag, String(c["titulo"]).left(40), marco.get_global_rect().end.y])
				f.free()
			for e in eventos:
				var capa := OverlaysDia.evento(_evento_ui(e), func() -> void: pass, {"camara": "Cámara", "senado": "Senado"}, 36, func(_i: int) -> void: pass)
				root.add_child(capa)
				await process_frame
				await process_frame
				for n in capa.find_children("*", "Control", true, false):
					var ctl := n as Control
					if not ctl.is_visible_in_tree():
						continue
					var r := ctl.get_global_rect()
					if (ctl is Label or ctl is Button) and String(ctl.get("text")).strip_edges() != "":
						_check(r.end.y <= alto + 0.5 and r.position.x >= -0.5 and r.end.x <= Tema.ANCHO + 0.5, String(e["id"]), "%s evento «%s»: «%s» se sale de la pantalla (%s)" % [tag, String(e["titulo"]).left(40), String(ctl.get("text")).left(30), r])
					if ctl is BaseButton:
						_check(r.size.y >= Tema.TACTIL - 0.5, String(e["id"]), "%s evento «%s»: botón de %d px" % [tag, String(e["titulo"]).left(40), r.size.y])
				capa.free()
	Ajustes.escala_prueba = 0.0
	root.content_scale_size = Vector2i(390, 844)
	for id in _malas.keys():
		print("FALLO: ", _malas[id])
	print("piezas que no caben: %d" % _malas.size())
	if _fallos == 0:
		print("FICHAS LARGAS OK")
	quit(1 if _fallos > 0 else 0)
