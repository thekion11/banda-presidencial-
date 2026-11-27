class_name Musica
extends RefCounted
## Música ambiente (dirección visual v4): una pista en bucle por etapa (campaña, gobierno, oposición) y una de
## tensión durante las votaciones del Congreso. Las pistas se funden entre sí en ~1,5 s con dos reproductores.
## Pistas sintetizadas por tools/audio/generar_musica.py (sin muestras de terceros). Respeta Ajustes › Música y
## Sonido; en headless no hace nada.

const VOLUMEN := -17.0  # dB: debajo de los efectos (-6 dB)
const FUNDIDO := 1.5
const PISTAS := {"campana": "musica_campana", "gobierno": "musica_gobierno", "oposicion": "musica_oposicion", "tension": "musica_tension"}

static var _a: AudioStreamPlayer
static var _b: AudioStreamPlayer
static var _actual: String = ""  # pista que suena
static var _base: String = ""  # pista de la etapa (vuelve aquí al terminar la tensión)
static var _tension: int = 0  # capas de tensión abiertas (votaciones encadenadas)
static var _streams: Dictionary = {}


static func iniciar(raiz: Node) -> void:
	if DisplayServer.get_name() == "headless" or (_a != null and is_instance_valid(_a)):
		return
	for i in range(2):
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		raiz.add_child(p)
		if i == 0:
			_a = p
		else:
			_b = p


static func pausar(on: bool) -> void:
	## App en segundo plano: la música se detiene en su lugar y sigue desde ahí al volver.
	for p in [_a, _b]:
		if p != null and is_instance_valid(p):
			p.stream_paused = on


static func _activa() -> bool:
	return _a != null and is_instance_valid(_a) and Ajustes.musica and Ajustes.sonido


static func _stream(pista: String) -> AudioStream:
	if not _streams.has(pista):
		var ruta := "res://game/audio/%s.ogg" % String(PISTAS.get(pista, ""))
		var s: AudioStream = load(ruta) if ResourceLoader.exists(ruta) else null
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		_streams[pista] = s
	return _streams[pista]


static func etapa(nombre: String) -> void:
	## Pista de la etapa: «campana», «gobierno» u «oposicion» (cualquier otra, gobierno).
	_base = nombre if PISTAS.has(nombre) and nombre != "tension" else "gobierno"
	if _tension == 0:
		_poner(_base)


static func tension(on: bool) -> void:
	## Votación en pantalla: la pista se funde a la de tensión y vuelve a la de la etapa al cerrarse.
	_tension = maxi(0, _tension + (1 if on else -1))
	_poner("tension" if _tension > 0 else _base)


static func al_cambiar_ajuste() -> void:
	if not _activa():
		_detener()
		return
	var p := _actual
	_actual = ""
	_poner(p if p != "" else _base)


static func _poner(pista: String) -> void:
	if not _activa() or pista == "" or pista == _actual:
		return
	var s := _stream(pista)
	if s == null:
		return
	_actual = pista
	var sale := _a if _a.playing else _b
	var entra := _b if sale == _a else _a
	entra.stream = s
	entra.volume_db = -40.0
	entra.play()
	var tw := entra.create_tween().set_parallel(true)
	tw.tween_property(entra, "volume_db", VOLUMEN, FUNDIDO).set_trans(Tween.TRANS_SINE)
	if sale.playing and sale != entra:
		tw.tween_property(sale, "volume_db", -60.0, FUNDIDO).set_trans(Tween.TRANS_SINE)
		tw.chain().tween_callback(sale.stop)


static func _detener() -> void:
	_actual = ""
	for p in [_a, _b]:
		if p != null and is_instance_valid(p):
			p.stop()
