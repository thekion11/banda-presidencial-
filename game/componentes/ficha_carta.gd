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
	return "impacto " + impacto(carta, leyes) + ((" · " + ex) if ex != "" else "")
