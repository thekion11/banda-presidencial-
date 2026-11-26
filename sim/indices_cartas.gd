class_name IndicesCartas
extends RefCounted
## Índices de solo lectura derivados del catálogo de cartas (que no cambia durante una partida): por id, cartas reales y diseñadas, y cartas ligadas
## a una condición de disponibilidad. Se construyen una vez al cargar los datos (Datos.cargar_todo) y se comparten entre partidas y reproducciones:
## armarlos en cada partida costaba ~15 ms de los ~100 ms que debe tardar cargar un guardado.

const TIPOS_REALES := ["proyecto_publico", "proyecto_de_ley", "reforma_constitucional", "propuesta_constitucional"]

var n: int = 0
var por_id: Dictionary = {}
var es_real: Dictionary = {}  # id -> bool
var reales: Array[Dictionary] = []
var no_reales: Array[Dictionary] = []
var r_ids := PackedStringArray()  # cartas reales en arrays paralelos: id, categoría (índice en r_cats) y si tienen condiciones de disponibilidad
var r_cat := PackedInt32Array()
var r_cond := PackedByteArray()
var r_cats: Array[String] = []
var disp: Dictionary = {}  # clave de disponibilidad -> valor normalizado -> cartas, en el orden del catálogo


static func clave(v: Variant) -> String:
	return str(int(v)) if (v is float or v is int) and float(v) == floorf(float(v)) else str(v)


static func tipo_real(c: Dictionary) -> bool:
	var meta: Variant = c.get("meta", null)
	return meta != null and TIPOS_REALES.has(meta.get("tipo", ""))


static func construir(cartas: Array) -> IndicesCartas:
	var x := IndicesCartas.new()
	x.n = cartas.size()
	for c in cartas:
		var id: String = c["id"]
		x.por_id[id] = c
		var real := tipo_real(c)
		x.es_real[id] = real
		if real:
			x.reales.append(c)
			x.r_ids.append(id)
			var cat := String(c["categoria"])
			if not x.r_cats.has(cat):
				x.r_cats.append(cat)
			x.r_cat.append(x.r_cats.find(cat))
			x.r_cond.append(1 if c.get("disponibilidad", null) != null else 0)
		else:
			x.no_reales.append(c)
		var d: Variant = c.get("disponibilidad", null)
		if d == null:
			continue
		for k in d.keys():
			if d[k] == null:
				continue
			if not x.disp.has(k):
				x.disp[k] = {}
			var vk := clave(d[k])
			if not x.disp[k].has(vk):
				x.disp[k][vk] = []
			x.disp[k][vk].append(c)
	return x
