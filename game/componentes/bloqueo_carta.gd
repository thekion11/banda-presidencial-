class_name BloqueoCarta
extends RefCounted
## Estado de disponibilidad de una carta: "" si está disponible o el motivo de bloqueo (gabinete, año, evento, fiscal_min, meta).

const NOMBRES := {"politica": "Política", "educacion": "Educación", "energia": "Energía", "medioambiente": "Medio ambiente",
	"descentralizacion": "Descentralización", "economia": "Economía", "comite": "Comité", "transportes": "Transportes"}


static func nombre_cat(cat: String) -> String:
	return String(NOMBRES.get(cat, cat.capitalize()))


static func motivo(motor: MotorTurno, carta: Dictionary) -> String:
	if not motor.gabinete.categoria_activa(String(carta["categoria"])):
		return "Falta un ministro de %s en el gabinete" % nombre_cat(String(carta["categoria"]))
	var d: Variant = carta.get("disponibilidad", null)
	if d == null:
		return ""
	var anio := motor.gabinete.anio_gobierno()
	if d.get("anio_desde", null) != null and anio < int(d["anio_desde"]):
		return "Disponible desde el año %d de gobierno" % int(d["anio_desde"])
	if d.get("anio_hasta", null) != null and anio > int(d["anio_hasta"]):
		return "Solo existía hasta el año %d de gobierno" % int(d["anio_hasta"])
	if d.get("evento", null) != null and not motor.estado.eventos_ocurridos.has(String(d["evento"])):
		return "Se activa con un evento (%s)" % String(d["evento"])
	if d.get("fiscal_min", null) != null and motor.estado.ind("fiscal") < float(d["fiscal_min"]):
		return "Requiere caja fiscal de %d o más" % roundi(float(d["fiscal_min"]))
	if d.get("meta", null) != null and not motor.estado.metas_cumplidas.has(String(d["meta"])):
		var meta: Dictionary = motor.movimientos.metas.get(String(d["meta"]), {})
		return "Se desbloquea con la meta «%s»" % String(meta.get("nombre", d["meta"]))
	return ""


static func bloqueadas(motor: MotorTurno) -> Array[Dictionary]:
	## Cartas del catálogo que hoy no están disponibles, con su motivo.
	var res: Array[Dictionary] = []
	for c in motor.catalogo_cartas:
		var mot := motivo(motor, c)
		if mot != "" and not motor.estado.cartas_ejecutadas.has(String(c["id"])):
			res.append({"carta": c, "motivo": mot})
	return res
