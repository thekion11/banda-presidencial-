class_name Feedback
extends RefCounted
## Sonido, vibración y textos flotantes. Respeta Ajustes; si faltan los audios o no hay dispositivo de audio, no hace nada.

static var _jugadores: Dictionary = {}  # nombre -> AudioStreamPlayer
const SONIDOS := ["toque", "jugar", "exito", "alerta", "evento", "decision", "turno", "error"]


static func iniciar(raiz: Node) -> void:
	for n in SONIDOS:
		var ruta := "res://game/audio/%s.wav" % n
		if not ResourceLoader.exists(ruta) or _jugadores.has(n) and is_instance_valid(_jugadores[n]):
			continue
		var p := AudioStreamPlayer.new()
		p.stream = load(ruta)
		p.volume_db = -6.0
		raiz.add_child(p)
		_jugadores[n] = p


static func sonar(nombre: String) -> void:
	if Ajustes.sonido and _jugadores.has(nombre) and is_instance_valid(_jugadores[nombre]):
		(_jugadores[nombre] as AudioStreamPlayer).play()


static func vibrar(ms: int = 30) -> void:
	if Ajustes.vibracion:
		Input.vibrate_handheld(ms)


static func flotante(padre: Control, texto: String, pos: Vector2, color: Color = Tema.CREMA) -> void:
	## Texto que sube y se desvanece (lo que cambió una carta). Sin animaciones activadas, no se muestra.
	if not Ajustes.animaciones or texto == "":
		return
	var l := Tema.etiqueta(texto, 14, color, true)
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", pos.y - 70.0, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 1.1).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)


static func tras_jugar(capa: Control, r: Dictionary, cambios: String, pos: Vector2 = Vector2(110, 430)) -> void:
	## Sonido, vibración y número flotante al jugar una carta (según salga bien, mal o con escándalo).
	if bool(r.get("escandalo", false)) or bool(r.get("salio_mal", false)):
		sonar("alerta")
		vibrar(60)
	else:
		sonar("jugar")
		vibrar(20)
	flotante(capa, cambios, pos, Tema.bien() if not bool(r.get("salio_mal", false)) else Tema.mal())
