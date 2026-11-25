class_name FichaCarta
extends RefCounted
## PR-09: datos legibles de una carta (impacto, exigencia legal) para la cabecera del panel de detalle. Solo lectura.


static func impacto(carta: Dictionary, leyes: Dictionary) -> String:
	var pts := 0.0
	for ef in carta["efectos"]:
		if String(ef["ind"]) in ["aprobacion", "capital", "cohesion", "fiscal"]:
			pts += absf(float(ef["delta"]))
	var cfg: Dictionary = leyes["impacto_carta"]
	if pts <= float(cfg["pequeno"]):
		return "pequeño"
	return "mediano" if pts <= float(cfg["mediano"]) else "grande"


static func exigencia(carta: Dictionary) -> String:
	var req: Dictionary = carta.get("requisitos", {})
	if req.get("quorum", null) != null or req.get("ley", null) != null:
		return "pasa por el Congreso"
	return ""


static func linea(carta: Dictionary, leyes: Dictionary) -> String:
	var ex := exigencia(carta)
	var extra := ""
	if carta.has("riesgo"):
		extra += " · con riesgo"
	if carta.has("diferido"):
		extra += " · efecto a futuro"
	return "impacto " + impacto(carta, leyes) + ((" · " + ex) if ex != "" else "") + extra


static func caber(msg: String) -> String:
	## El panel del corrector mide 66 px (cabecera + 3 líneas de 10 pt): si el mensaje no cabe se corta en una palabra y termina en "…".
	var f := Tema.fuente_texto(400)
	var palabras := msg.split(" ")
	while palabras.size() > 1 and f.get_multiline_string_size("Corrector: " + " ".join(palabras), HORIZONTAL_ALIGNMENT_LEFT, 304, 10).y > f.get_height(10) * 3.05:
		palabras.remove_at(palabras.size() - 1)
		palabras[palabras.size() - 1] = palabras[palabras.size() - 1].rstrip(".,;:") + "…"
	return " ".join(palabras)
