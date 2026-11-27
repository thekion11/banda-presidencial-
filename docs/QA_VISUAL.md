# QA visual de todas las pantallas (27-nov-2026)

Seis hojas de contacto con las 18 pantallas y estados del recorrido (`RecorridoUI`), capturadas con **ventanas reales** bajo xvfb, en tres tamaños y con letra normal y grande («Texto grande», ×1,15):

| Ventana | Lienzo lógico | Hojas |
|---|---|---|
| 360 × 640 (16:9) | 390 × 693 | `docs/comparacion/hoja_contacto_360x640_normal.png`, `…_grande.png` |
| 390 × 844 (referencia) | 390 × 844 | `docs/comparacion/hoja_contacto_390x844_normal.png`, `…_grande.png` |
| 480 × 1000 | 390 × 813 | `docs/comparacion/hoja_contacto_480x1000_normal.png`, `…_grande.png` |

Se regeneran con `tests/hoja_contacto.gd`, una corrida por ventana y letra (las instrucciones están en su cabecera), y después `python3 tools/hoja_contacto.py <carpeta> docs/comparacion`.

## Hallazgos y qué se hizo

1. **Grave: los teléfonos 16:9 se veían achicados y con bandas.** El proyecto usa `keep_width` con base 390 × 844, y en Godot ese modo solo agrega alto cuando la pantalla es *más alta* que 390:844. En un 360 × 640, que es más ancho, el juego mostraba 390 × 844 reducido al 82 %, con bandas a los lados (295 × 640 útiles) y letra bajo el mínimo de 10 pt. Las pruebas no lo veían porque simulan el alto cambiando la base en headless. **Corregido:** `Main.base_para` fija la base lógica en 390 × (alto de la pantalla): un 360 × 640 queda en 390 × 693, como suponían el diseño y las pruebas. La prueba está en `tests/test_claridad.gd`. Verificado con ventanas reales: 360×640 → 390×693, 390×844 → 390×844, 480×1000 → 390×813 y tablet 768×1024 → 390×844 con bandas (a propósito).
2. **La marca del mínimo tapaba «Requiere N votos…».** En el teléfono bajo, la línea y el rótulo «mín. 26» del hemiciclo se dibujaban por encima de su rectángulo. **Corregido:** el radio deja sitio a la marca.
3. **La cifra central de la votación se montaba sobre los asientos** con el hemiciclo achicado. **Corregido:** cifra y asientos escalan con el radio. En 390 × 844 no cambia nada: las cifras de la maqueta quedaron idénticas.
4. **Sin defecto, solo para tenerlo en cuenta:**
   - El aviso dorado de arriba («Circula una noticia falsa…») aparece en varias capturas porque el recorrido avanza más rápido que sus 2,6 s; se va solo.
   - En el Comité, el Gabinete y el fin, las tarjetas se cortan bajo el botón principal porque están dentro de una lista desplazable.
   - En el evento de prueba, la descripción «x» es un dato del recorrido.

Revisado a ojo en las seis hojas, sin otros problemas: no hay texto cortado fuera de las listas, ni botones tapados, ni superposiciones. Los títulos largos de la letra grande se parten en dos líneas.

## Lo que las pruebas headless simulan y cómo se comprobó de verdad (cola 7)

`tests/ventana_real.gd` (informe) abre **ventanas reales** bajo xvfb y recorre todas las pantallas. Comprueba el lienzo lógico, que nada fijo se salga, los botones ≥ 44 y el mapa > 1/3. Se corrió con 8 ventanas (360×640, 360×800, 390×844, 412×915, 480×1000, plegable cerrado 280×653, tablet 768×1024 y plegable abierto 884×1104) y letra ×1, ×1,15 y ×1,5: **24 combinaciones, sin fallos** tras los arreglos de abajo.

| Condición | Cómo la simulan las pruebas headless | Cómo es de verdad | Resultado |
|---|---|---|---|
| Alto de la pantalla | `root.content_scale_size = (390, alto)` (`RecorridoUI.ALTURAS`, `test_estado_tardio`, `test_claridad`…) | Ventana real con `Main.base_para` | **Coincide desde hoy.** Antes un 16:9 quedaba en 390×844 achicado (ver arriba). Lienzos reales: 360×640 → 390×693, 360×800 → 390×867, 412×915 → 390×866, 480×1000 → 390×813, 280×653 → 390×910; tablet y plegable abierto → 390×844 con bandas |
| Letra grande | `Ajustes.escala_prueba` (1,15, 1,3 y 1,5) | «Texto grande» usa el mismo camino (`Ajustes.escala_texto()` = 1,15). Los ×1,3 y ×1,5 imitan la escala de letra de Android, **que el juego no sigue** (pendiente para el usuario: necesita un plugin) | Coincide. **Hueco encontrado:** ×1,5 solo se probaba en 844. En 360×640 real el pie legal del menú y el botón de la votación se salían por abajo. Corregido: el menú sube en pantalla baja y el contenido de la capa de evento o votación se desplaza con los botones fijos. `test_textos` ahora prueba 693 con ×1,5 |
| Muesca y barra de gestos | `Tema.inset_prueba` | `DisplayServer.get_display_safe_area()`, solo en el teléfono. xvfb no tiene franjas, así que **no se puede crear aquí** | Se verificó la conversión a unidades lógicas con la base nueva: `alto lógico / alto físico` sigue valiendo. Con `immersive_mode=true` Android esconde la barra de navegación y el inset de abajo suele ser 0; el de arriba es la muesca. Falta verlo en un teléfono (`docs/MEDICION_TELEFONO.md`) |
| Renderizador | Headless usa el renderizador vacío; las capturas usan `gl_compatibility` | El proyecto usa **`mobile`** (Vulkan). Aquí se corre con lavapipe (`apt-get install mesa-vulkan-drivers` y `--rendering-method mobile`) | 54 de 55 capturas iguales o casi (≤ 1,4 % de píxeles distintos). **Comité 3D: el terreno salía casi blanco** con Mobile (mediana 255,249,222 frente a 240,223,184). Corregido con `ComiteMapa3D.FACTOR_LUZ_MOBILE = 0,78`, que solo aplica fuera de Compatibility: ahora da 235,223,198. La obra 3D del hito sale igual en los dos |
| Animaciones | `Movimiento.forzado` | `Movimiento.activo()` con la ventana real y `Ajustes.animaciones` | Mismo camino; las capturas y `test_animaciones_completas` lo ejercitan |
| Zona táctil | 44 px lógicos | En un teléfono de 360 dp de ancho, 1 px lógico = 0,92 dp, así que 44 lógicos son 40,6 dp (Android recomienda 48 dp) | Cumple la regla de CLAUDE.md (44 px). Para cumplir 48 dp en 360 dp harían falta 52 lógicos: queda anotado como decisión, no se cambió |

## Entrada: toques reales frente a eventos sintéticos (cola 7)

Las pruebas de interfaz emitían señales (`tocada`, `pressed`) o llamaban a `_gui_input` directamente. `tests/test_toque_real.gd` toca por el **camino real del motor de entrada**: `Input.parse_input_event` con `InputEventScreenTouch` y `InputEventScreenDrag`, como llegan en Android. Con `emulate_mouse_from_touch`, activo por defecto, Godot además convierte cada toque en clic.

- **Grave, corregido: un solo toque elegía la carta y en seguida la jugaba.** `CartaUI` atendía el toque y también el clic emulado, así que el segundo contaba como «tocar la carta elegida». En el teléfono, tocar una carta para mirarla gastaba movimientos. Ahora `CartaUI` y `MapaChile` atienden solo el clic, que Godot genera desde el toque. La prueba falla sin el arreglo y pasa con él, en headless y con ventana real 360×640.
- La misma prueba cubre lo demás por ese camino: el segundo toque sobre la elegida la juega; deslizar hacia arriba la juega; mantener ≥ 450 ms abre la ficha y soltar la cierra sin jugar; tocar el mapa elige una región; «Terminar semana» con movimientos sin usar pide confirmar.
- **Con clics reales de X11** (`xdotool`, ventana 360×640 escalada): un clic elige, el segundo sobre la elegida juega y un doble clic elige y juega, como está diseñado. Las coordenadas lógicas se convierten bien con `get_final_transform()`.
- Lo que no se puede crear aquí: el multitoque y los gestos del sistema (atrás deslizando desde el borde) no existen en X11. El zoom con dos dedos (`InputEventMagnifyGesture`) solo está probado con eventos sintéticos.

## Ventana del proyecto frente al export de Android (cola 7)

| Ajuste | Proyecto (`project.godot`) | Export (`export_presets.cfg`) | Lectura |
|---|---|---|---|
| Orientación | `window/handheld/orientation=1` (vertical) | `screen/orientation=1`; el manifiesto queda con `screenOrientation=1`, que revisa `tools/auditar_apk.py` | Coinciden: vertical bloqueada |
| Estiramiento | `canvas_items` + `keep_width`, base 390×844; en ejecución `Main.base_para` fija 390 × el alto real y `Main.aspecto_para` pasa a `keep` con bandas en pantallas anchas | — | Coincide con lo que suponen el diseño y las pruebas desde la cola 6 |
| Barras del sistema | — | `screen/immersive_mode=true`: Android esconde la barra de estado y la de navegación, que vuelven un momento con un gesto | El inset de abajo suele ser 0 y el de arriba es la muesca. `Tema.margen_superior` y `margen_inferior` leen la zona segura en cada pantalla. Con targetSdk 35, Android 15 fuerza el modo de borde a borde: si alguna vez se apaga el inmersivo, las franjas ya están cubiertas (`test_zonas_seguras`) |
| Muesca | — | Sin ajuste propio; el inmersivo dibuja también bajo la muesca | Cubierto por `margen_superior`. **Falta verlo en un teléfono con muesca** |
| Renderizador | `renderer/rendering_method="mobile"` | El mismo; si el teléfono no tiene Vulkan, Godot cae a OpenGL (Compatibility) | Las dos rutas se capturaron aquí; la diferencia del Comité 3D se compensó |
| Plegable y pantalla dividida | `size_changed` → `Main._ajustar_aspecto` | Se supone que Godot no reinicia la actividad al cambiar de tamaño (el manifiesto declara los cambios de tamaño como propios); hay que confirmarlo en un plegable | **Defecto corregido:** con un cambio en caliente de alto a bajo (pantalla dividida), el día se quedaba armado para el alto anterior y «Terminar semana» quedaba fuera. Ahora `Main` rearma el día cuando cambia `Tema.pantalla_baja()`, solo si no hay un evento o una votación abiertos encima. Verificado con `tests/ventana_cambio.gd`: 280×653 → 884×1104 → 280×653 → 360×640, siempre con el mapa > 1/3 y el botón dentro |

## La app se cierra en medio de una decisión (cola 7)

Al pasar a segundo plano o cerrarse, `Main` guarda la partida y la instantánea (`NOTIFICATION_APPLICATION_PAUSED` y `NOTIFICATION_WM_CLOSE_REQUEST`). Pero si Android mataba la app con un **evento con decisión en pantalla**, al continuar no volvía a aparecer. El motor lo deja pendiente (el evento ocurrió y no hay decisión registrada), así que el jugador nunca elegía y las consecuencias de la opción no llegaban. **Corregido:** `PantallaDia.retomar_decisiones()` vuelve a mostrar, al continuar, las decisiones de la semana que quedaron sin responder. La prueba está en `tests/test_atras.gd`. Las votaciones y avisos ya aplicados no se repiten, porque solo eran para mostrar.

## Ciclo de vida de Android: pausa, la app muere y se vuelve a abrir (cola 8)

`tests/test_ciclo_vida.gd` repite el ciclo en cada subestado: `NOTIFICATION_APPLICATION_PAUSED` (Android guarda ahí), destruir `Main` sin más avisos, abrir de nuevo y «Continuar partida». Compara la etapa, el turno, el día, los movimientos, los indicadores, la mano, el gabinete, las entradas y las decisiones antes y después.

| Subestado al morir | Al volver | Se pierde |
|---|---|---|
| Campaña, con una carta recién jugada | Día de campaña, todo igual | Nada |
| Ficha ampliada abierta | Día, sin ficha flotando | Nada (es solo lectura) |
| Fin de campaña con la elección pendiente | Día con «Ir a las urnas» | Nada |
| Gobierno con la hoja de delegar abierta | Día de gobierno, sin la hoja | Nada (delegar no había empezado) |
| Evento con decisión en pantalla | El evento se vuelve a mostrar (`retomar_decisiones`) | Nada |
| Votación o aviso a medias | Día; la votación no se repite | **Solo el momento de verla**: el resultado ya estaba aplicado y queda en las barras, el telón y el Congreso |
| Telón de la semana | Día de la semana nueva | Nada (es solo para mostrar) |
| Test ideológico o fundación a medias | Menú (no hay partida todavía) | Las respuestas: son 3 preguntas y no hay nada guardado que perder. Si había una partida anterior, «Continuar» la ofrece |
| Tutorial a medias | Vuelve a aparecer en la primera semana de campaña, porque solo se marca visto al terminarlo o saltarlo | Nada |
| Fin del mandato | Pantalla de fin | Nada |

## Teclado y cambio de tamaño con campos de texto (cola 8)

El teclado de Android se superpone a la ventana sin achicarla y ocupa cerca del 45 % de abajo. Con letra ×1,5 en 390×693, **la sigla del partido quedaba tapada mientras se escribía**: terminaba en y=409 y el teclado empieza en y≈381. **Corregido:** `Tema.subir_al_enfocar` sube el campo enfocado al tope de sus listas desplazables. Lo usan el nombre y la sigla del partido y todos los `Tema.campo`: la búsqueda de la cartera y los nombres de línea y estación del Comité. La orientación está bloqueada en vertical, así que no hay giro. Si la ventana cambia de alto (pantalla dividida, plegable) con el formulario abierto, lo escrito se conserva: solo el día se rearma, y solo si no hay nada encima. Prueba: `tests/test_teclado.gd`, en 693 y 844 con letra ×1 y ×1,5. Mejora posible: usar la altura real del teclado (`DisplayServer.virtual_keyboard_get_height()`) en lugar de subir siempre al tope.

## Interrupciones: llamada o notificación en pleno gesto (cola 8)

Cuando entra una llamada o el sistema roba el gesto, Android cancela el toque y Godot lo entrega como un «soltar» con `canceled = true`, tanto el toque como su clic emulado. Lo prueba `tests/test_toque_real.gd`.

- **Corregido: un deslizamiento cancelado jugaba la carta.** `ManoUI` trataba el soltar cancelado como un deslizamiento terminado. Ahora un gesto cancelado no cuenta, y tampoco el toque cancelado sobre la carta elegida (`CartaUI`) ni sobre el mapa urbano o el del Comité (`UrbanoVista`). El arrastre de una estación del Comité se cierra igual, para no dejarla a medias.
- **Corregido: con el dedo puesto y la app perdiendo el foco, la ficha ampliada se abría igual medio segundo después y quedaba abierta.** `ManoUI` anula el gesto pendiente y cierra la ficha con `NOTIFICATION_APPLICATION_FOCUS_OUT` o `PAUSED`.
- Después de una cancelación, el toque siguiente llega normal: no queda nada trabado.

## Segundo plano y batería (cola 8)

Al pasar a segundo plano (`NOTIFICATION_APPLICATION_PAUSED`), `Main` guarda, pone el árbol en pausa (`get_tree().paused`) y detiene la música en su lugar (`Musica.pausar`). Al volver (`RESUMED`) todo sigue desde donde estaba. Así no corren el mapa vivo, los tweens, las partículas, el debate ni la órbita 3D, aunque el sistema siga dándole cuadros a la app (en Android suele detener el bucle, pero no está garantizado en todos los equipos). Los temporizadores de una sola vez (`create_timer`: ocultar un aviso, la pulsación larga) no se pausan, pero son cortos y la pulsación larga ya se anula al perder el foco. Prueba: `tests/test_segundo_plano.gd`.
