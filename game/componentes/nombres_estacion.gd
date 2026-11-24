class_name NombresEstacion
extends RefCounted
## Sugerencias de nombre para las estaciones de una línea nueva a partir de lo que hay cerca (lugares conocidos y estaciones reales
## de Metro): «Parque Bicentenario», «Matta Oriente»… Solo mira datos del mapa; el jugador puede cambiar cualquier nombre.

const M_ANCHO := 26003.0
const M_ALTO := 21128.0
const RADIO_LUGAR_M := 900.0
const RADIO_ESTACION_M := 2600.0


static func _metros(a: Array, b: Array) -> float:
	return Vector2((float(a[0]) - float(b[0])) * M_ANCHO, (float(a[1]) - float(b[1])) * M_ALTO).length()


static func _cardinal(desde: Array, hasta: Array) -> String:
	var dx := (float(hasta[0]) - float(desde[0])) * M_ANCHO
	var dy := (float(hasta[1]) - float(desde[1])) * M_ALTO  # el plano crece hacia el sur
	if absf(dx) >= absf(dy):
		return "Oriente" if dx > 0.0 else "Poniente"
	return "Sur" if dy > 0.0 else "Norte"


static func sugerir(posiciones: Array) -> Array[String]:
	## Un nombre por posición (x, y en el plano 0..1), sin repetir dentro de la línea y sin coincidir con una estación real.
	var d := UrbanoBase.datos()
	var reales := {}
	for e in d.get("estaciones", []):
		reales[String(e["n"])] = true
	var res: Array[String] = []
	var usados := {}
	for k in range(posiciones.size()):
		var p: Array = posiciones[k]
		var base := ""
		var mejor_l := RADIO_LUGAR_M
		for l in d.get("lugares", []):
			var dl := _metros(p, l["p"])
			if dl < mejor_l and not reales.has(String(l["n"])):
				mejor_l = dl
				base = String(l["n"])
		if base == "":
			var mejor_s := RADIO_ESTACION_M
			for e in d.get("estaciones", []):
				var ds := _metros(p, e["p"])
				if ds < mejor_s:
					mejor_s = ds
					base = "%s %s" % [e["n"], _cardinal(e["p"], p)]
		if base == "":
			base = "Estación %d" % (k + 1)
		base = base.left(22)  # deja sitio para el número que desambigua
		var nombre := base
		var n := 2
		while usados.has(nombre):
			nombre = "%s %d" % [base, n]
			n += 1
		usados[nombre] = true
		res.append(nombre)
	return res
