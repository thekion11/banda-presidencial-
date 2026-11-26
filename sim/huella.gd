class_name Huella
extends RefCounted
## Huellas SHA-256 estables entre versiones de Godot. JSON.stringify no sirve para eso: desde Godot 4.4 escribe «11.0» donde antes
## escribía «11» y, tras un ciclo JSON, los enteros vuelven como flotantes. Aquí todos los números se escriben igual (8 decimales),
## las claves van ordenadas y los textos se escapan con JSON.stringify (idéntico en todas las versiones).


static func texto(v: Variant) -> String:
	## Representación textual estable (claves ordenadas) de cualquier valor, para hashear sin depender del orden de los diccionarios.
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
		var f := roundf(float(v) * 100000000.0) / 100000000.0
		if f == 0.0:
			f = 0.0  # -0,0 y los negativos que redondean a cero se escriben igual que 0 (lo encontró el fuzzing: eje_inst -0,0 contra 0,0 tras el JSON)
		return "%.8f" % f
	if v is bool:
		return "true" if v else "false"
	if v == null:
		return "null"
	return JSON.stringify(str(v))


static func sha(v: Variant) -> String:
	## SHA-256 del texto estable de un valor.
	return texto(v).sha256_text()


static func fnv32(texto: String) -> int:
	## FNV-1a de 32 bits sobre UTF-8: valor fijo en todas las versiones de Godot (hash() no lo garantiza).
	var h := 2166136261
	for b in texto.to_utf8_buffer():
		h = ((h ^ int(b)) * 16777619) & 0xFFFFFFFF
	return h
