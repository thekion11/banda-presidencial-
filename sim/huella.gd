class_name Huella
extends RefCounted
## Huellas SHA-256 estables entre versiones de Godot. JSON.stringify no sirve para eso: desde Godot 4.4 escribe «11.0» donde antes
## escribía «11» y, tras un ciclo JSON, los enteros vuelven como flotantes. Aquí todos los números se escriben igual (8 decimales),
## las claves van ordenadas y los textos se escapan con JSON.stringify (idéntico en todas las versiones).


static func texto(v: Variant) -> String:
	if v is Dictionary:
		var claves: Array = v.keys()
		claves.sort()
		var partes: PackedStringArray = []
		for k in claves:
			partes.append("%s:%s" % [JSON.stringify(str(k)), texto(v[k])])
		return "{" + ",".join(partes) + "}"
	if v is Array:
		var partes2: PackedStringArray = []
		for x in v:
			partes2.append(texto(x))
		return "[" + ",".join(partes2) + "]"
	if v is int or v is float:
		return "%.8f" % float(v)
	if v is bool:
		return "true" if v else "false"
	if v == null:
		return "null"
	return JSON.stringify(str(v))


static func sha(v: Variant) -> String:
	return texto(v).sha256_text()
