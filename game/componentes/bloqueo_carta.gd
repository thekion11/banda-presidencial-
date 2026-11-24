class_name BloqueoCarta
extends RefCounted
## Estado de disponibilidad de una carta: "" si está disponible o el motivo de bloqueo (gabinete, año, evento, fiscal_min, meta).

const NOMBRES := {"politica": "Política", "educacion": "Educación", "energia": "Energía", "medioambiente": "Medio ambiente",
	"descentralizacion": "Descentralización", "economia": "Economía", "comite": "Comité", "transportes": "Transportes"}


static func nombre_cat(cat: String) -> String:
	return String(NOMBRES.get(cat, cat.capitalize()))


static func motivo(motor: MotorTurno, carta: Dictionary) -> String:
	## Texto del bloqueo; la regla vive en motor.gabinete.bloqueo (sim), aquí solo se redacta.
	var b := motor.gabinete.bloqueo(carta)
	if b.is_empty():
		return ""
	var v: Variant = b["valor"]
	match String(b["codigo"]):
		"gabinete": return "Falta un ministro de %s en el gabinete" % nombre_cat(String(v))
		"anio_desde": return "Disponible desde el año %d de gobierno" % int(v)
		"anio_hasta": return "Solo existía hasta el año %d de gobierno" % int(v)
		"evento": return "Se activa con un evento (%s)" % String(v)
		"fiscal": return "Requiere caja fiscal de %d o más" % roundi(float(v))
		_:
			var meta: Dictionary = motor.movimientos.metas.get(String(v), {})
			return "Se desbloquea con la meta «%s»" % String(meta.get("nombre", v))


static func bloqueadas(motor: MotorTurno) -> Array[Dictionary]:
	## Cartas del catálogo que hoy no están disponibles, con su motivo.
	var res: Array[Dictionary] = []
	for c in motor.catalogo_cartas:
		var mot := motivo(motor, c)
		if mot != "" and not motor.estado.cartas_ejecutadas.has(String(c["id"])):
			res.append({"carta": c, "motivo": mot})
	return res
