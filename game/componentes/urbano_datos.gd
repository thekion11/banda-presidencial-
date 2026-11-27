class_name UrbanoDatos
extends RefCounted
## Preparación de los datos del mapa urbano al cargarlos (separada de UrbanoBase para no acercarse al tope de 450 líneas).


static func _norm(n: String) -> String:
	return n.to_lower().replace("-", " ").strip_edges()


static func fusionar_futuras(d: Dictionary) -> void:
	## Líneas 7, 8 y 9 (en construcción o proyectadas): se suman a las líneas y estaciones reales. Una estación que ya existe
	## (Baquedano, Puente Cal y Canto, Matta…) se comparte y pasa a ser combinación; las nuevas se añaden con la marca «futuro».
	var f: Variant = Datos.leer_json("res://data/geo/metro_futuro.json")
	if f == null:
		return
	var por_nombre := {}
	for i in range(d["estaciones"].size()):
		por_nombre[_norm(String(d["estaciones"][i]["n"]))] = i
	for lid in f["lineas"]:
		var ln: Dictionary = f["lineas"][lid]
		var orden: Array = []
		var dentro: Array = []  # [nombre, posición] de las estaciones dentro de la ventana del mapa, en orden
		var fuera_ini := false
		var fuera_fin := false
		var n := (ln["estaciones"] as Array).size()
		for k in range(n):
			var e: Dictionary = ln["estaciones"][k]
			var p: Array = e["p"]
			var visible: bool = p[0] >= 0.0 and p[0] <= 1.0 and p[1] >= 0.0 and p[1] <= 1.0
			if not visible:
				if k < n / 2:
					fuera_ini = true
				else:
					fuera_fin = true
				continue
			var clave := _norm(String(e["n"]))
			var nombre := String(e["n"])
			if por_nombre.has(clave):
				var ex: Dictionary = d["estaciones"][por_nombre[clave]]
				if not (ex.get("l", []) as Array).has(lid):
					ex["l"] = (ex.get("l", []) as Array) + [lid]
				nombre = String(ex["n"])
				p = ex["p"]
			else:
				d["estaciones"].append({"n": nombre, "p": p, "l": [lid], "futuro": true})
				por_nombre[clave] = d["estaciones"].size() - 1
			orden.append(nombre)
			dentro.append(p)
		var cabos: Array = []
		if dentro.size() >= 2:
			for fin in range(2):
				var a: Array = dentro[0] if fin == 0 else dentro[dentro.size() - 1]
				var b: Array = dentro[1] if fin == 0 else dentro[dentro.size() - 2]
				var dir := Vector2(float(a[0]) - float(b[0]), float(a[1]) - float(b[1])).normalized()
				cabos.append({"n": orden[0 if fin == 0 else orden.size() - 1], "p": a, "d": [dir.x, dir.y], "sigue": fuera_ini if fin == 0 else fuera_fin})
		d["metro"].append({"id": lid, "color": ln["color"], "vias": ln["vias"], "cabos": cabos, "orden": orden, "futuro": true,
				"estado": ln["estado"], "apertura": ln["apertura"], "apertura_fecha": ln["apertura_fecha"]})
