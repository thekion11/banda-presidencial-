extends SceneTree
## Hoja de íconos (informe): cada tipo de `Icono` en cada tamaño de `Icono.TAMANOS`, sobre océano y sobre crema, para
## revisar de un vistazo el grosor de trazo, el tamaño y el centrado. Guarda docs/comparacion/iconos.png.
## Uso: xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/hoja_iconos.gd -- docs/comparacion

var _dir := "docs/comparacion"


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_dir = a[0]
	_correr.call_deferred()


func _correr() -> void:
	var fondo := ColorRect.new()
	fondo.color = Tema.OCEANO
	fondo.size = Vector2(390, 844)
	root.add_child(fondo)
	var y := 12.0
	for t in Icono.TIPOS:
		var et := Tema.etiqueta_corta(t, 10, Tema.TEXTO_SUAVE)
		et.position = Vector2(8, y + 6)
		fondo.add_child(et)
		var x := 70.0
		for crema in [false, true]:
			if crema:
				var cr := ColorRect.new()
				cr.color = Tema.CREMA
				cr.position = Vector2(x - 4, y - 2)
				cr.size = Vector2(150, 30)
				fondo.add_child(cr)
			for lado in Icono.TAMANOS:
				var guia := ColorRect.new()  # caja del ícono: el dibujo debe quedar centrado en ella
				guia.color = Color(Tema.ORO, 0.18)
				guia.position = Vector2(x, y + (26.0 - lado) * 0.5)
				guia.size = Vector2(lado, lado)
				fondo.add_child(guia)
				var ic := Icono.crear(t, Tema.TINTA if crema else Tema.TEXTO, lado)
				ic.position = guia.position
				fondo.add_child(ic)
				x += lado + 6.0
			x += 12.0
		y += 34.0
	for i in range(6):
		await process_frame
	root.get_texture().get_image().get_region(Rect2i(0, 0, 390, int(y) + 8)).save_png("%s/iconos.png" % _dir)
	print("hoja de íconos: %d tipos × %d tamaños" % [Icono.TIPOS.size(), Icono.TAMANOS.size()])
	quit()
