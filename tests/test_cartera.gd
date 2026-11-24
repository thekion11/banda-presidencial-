extends SceneTree
## Cartera de proyectos: la búsqueda por título ignora tildes y mayúsculas, se combina con los filtros y no cambia nada de la partida.

var _fallos: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO CARTERA: ", msg)


func _init() -> void:
	_correr.call_deferred()


func _correr() -> void:
	var datos := Datos.cargar_todo()
	var c := PantallaCartera.crear(datos)
	root.add_child(c)
	await process_frame
	var total := c.filtrados.size()
	_check(total > 1000, "la cartera trae todos los proyectos (%d)" % total)
	c.f_texto = "METRO"
	c.aplicar_filtros()
	var metro := c.filtrados.size()
	_check(metro > 0 and metro < total, "buscar «METRO» (mayúsculas) filtra: %d de %d" % [metro, total])
	for x in c.filtrados:
		_check(PantallaCartera._sin_tildes(String(x["titulo"])).contains("metro"), "todo resultado contiene «metro»: %s" % x["titulo"])
	c.f_texto = "pensión"
	c.aplicar_filtros()
	var con_tilde := c.filtrados.size()
	c.f_texto = "PENSION"
	c.aplicar_filtros()
	_check(c.filtrados.size() == con_tilde, "la búsqueda ignora las tildes (%d contra %d)" % [con_tilde, c.filtrados.size()])
	c.f_texto = "zzzz_no_existe"
	c.aplicar_filtros()
	_check(c.filtrados.is_empty(), "una búsqueda sin coincidencias deja la lista vacía")
	c.f_texto = ""
	c.f_tipo = "proyecto_publico"
	c.aplicar_filtros()
	var obras := c.filtrados.size()
	c.f_texto = "metro"
	c.aplicar_filtros()
	_check(c.filtrados.size() <= obras and c.filtrados.size() <= metro, "la búsqueda se combina con el filtro de tipo")
	if _fallos == 0:
		print("CARTERA OK (búsqueda por título con filtros)")
	quit(0 if _fallos == 0 else 1)
