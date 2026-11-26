# Diferencias entre el juego y la maqueta (y por qué)

Regla del proyecto: la maqueta manda. Esta lista deja explícito dónde el juego se aparta de ella. Las comparaciones fotograma a fotograma están en `docs/comparacion/` y se regeneran con `tests/captura_comparar.gd`.

## Cifras y textos (por balance real, no por estilo)
| Maqueta | Juego | Motivo |
|---|---|---|
| Aprobación 90 %, PA 16, capital 65… (cifras ilustrativas) | Aprobación ~40–60 %, PA 8 por turno, indicadores que salen de la partida | La maqueta rotula sus cifras como ilustrativas; el balance se calibra con bots Monte Carlo (`tests/test_balance.gd`). |
| Fecha "Mié 15 abr 2026" | Fecha calculada desde `data/leyes.json › calendario` (mandato desde el 11 mar 2030) | El calendario sale de los datos. Es ilustrativo. |
| Regiones con 58–90 % de aprobación | Aprobación regional con variación territorial determinista | Misma razón: son cifras de la partida, no de la maqueta. |

## Visual
| Elemento | Maqueta | Juego | Motivo |
|---|---|---|---|
| Ilustración de cartas | Escenas planas, estilo vectorial | Escenas pintadas generadas con IA (14 categorías) | Más riqueza visual; hay que declarar el uso de IA en Play. Respaldo: dibujo procedural. |
| Mapa nacional | Regiones coloreadas con textura de relieve ilustrada | Relieve real sombreado (teselas públicas de elevación) y Chile ensanchado ×2,3 | Datos reales y legibilidad en pantalla vertical. |
| Mapa urbano | Plano esquemático de manzanas | Cartografía real de Gran Santiago (calles, río, parques y las líneas de Metro con sus colores oficiales) | Datos reales de OpenStreetMap (ODbL) con el pipeline de la Fase 3. Es más denso que la maqueta; se prioriza la fidelidad al territorio. |
| Botones y chips | Colores planos | Degradados y marcos metálicos | Profundidad, manteniendo la paleta congelada. |
| Mapas urbanos y Comité 3D | Plano estilizado | Edificios, calles, río, parques, Metro, cerros y nombres de lugares reales (OSM + elevaciones públicas); exageración visual de relieve y edificios | Realismo del territorio chileno. |
| Comité y hito de obra | Isométricas ilustradas | Escenas 3D reales de Godot (cámara orbitable, trazado elevado, 5 fases animables) | Cumple la Fase 2 del plan; presupuesto móvil con una sola MultiMesh y sin sombras. |
| Animaciones | (estático) | Reparto de cartas, hemiciclo que se llena, sello que cae, barcos, Comité 2D/3D, reproducción de obra | Superar la maqueta sin cambiar su estructura. |

## Estructura (extensiones coherentes con la Enmienda y con Chile real)
- **Cámara de Diputados** (155) además del Senado (50): dos hemiciclos en Congreso y votación cámara por cámara con "Camino de la ley". Ver `docs/AUDITORIA_VIDA_REAL.md`.
- **Pantalla Nación** con su barra propia (Cartas / Comité / Día N / Congreso / Gabinete), tal como la maqueta.
- **Pantallas sin maqueta**: menú, test ideológico, fundación del partido y fin de partida. Son necesarias para el Modo Único de la Enmienda; se construyeron con los mismos componentes congelados (paleta, tipografías, zonas táctiles ≥ 44 px). No existe referencia en Figma para ellas.

## Pantallas v2 (gabinete, movimientos, delegación, asesores, coalición, internos) — revisión del 23-nov-2026
**Limitación:** no existe maqueta en Figma ni el Documento Maestro (PDF) dibuja estas pantallas: son extensiones de `docs/DISENO_V2.md`. La comparación se hizo sobre lo que el PDF sí fija (paleta, tipografías, 390×844, componentes Carta / Corrector / Botón de jugar, reglas de pantalla de la p. 9: mapa > 1/3, mano en abanico, botón principal fijo) y sobre `docs/comparacion/dia_maqueta_vs_juego.png`. Capturas nuevas: `docs/comparacion/v2_*.png` (`tests/captura_comparar.gd`); lado a lado con la maqueta del día: `v2_dia_maqueta_vs_juego.png`. Los paneles nuevos reutilizan Tema, Barras y la hoja inferior (paleta congelada, Space Grotesk / Inter, zonas táctiles ≥ 44 px, sin emojis).

| Elemento | Maqueta | Juego | Motivo / estado |
|---|---|---|---|
| Botón "Jugar · 2 PA" y pastilla "16 PA" | PA | "Jugar · 2 mov", "4/8 mov" | DISENO_V2 renombra PA a movimientos y suma bono por aprobación y asesores. Texto, no estilo. |
| Texto de la mano | "Toca una carta · 5 en mano" | "base 5 · aprob. +2 · asesor +1" | Explica el origen de los movimientos del turno. |
| Franja del corrector | Una franja con el corrector | Primera línea con título, categoría y costo de la carta elegida, y alto fijo | El abanico tapa los títulos de las no elegidas (regla de la maqueta: solo la elegida muestra todo). Corregido: antes el título no se leía completo. |
| Carta elegida | Sube con marco dorado | Sube y crece sin invadir la cabecera "Tu mano" | Bug corregido: con la carta 1 elegida cubría "Tu mano". |
| Botón de delegar | Ícono de persona | Mismo ícono + insignia con delegaciones restantes | Compacto; el detalle va en la hoja de delegación. |
| Hoja de delegación, panel Gabinete (4 pestañas), selector de 8 ministros | Sin maqueta | Hoja inferior y filas de varias líneas sobre `PANEL`/`OCEANO` | Nuevos; contraste del texto rojo pequeño aclarado a `#F59A87` (`FilasUI.ROJO_TEXTO`) para llegar a 4,5:1 sobre el panel. |
| Pantalla de configuración de gabinete | Sin maqueta | Botón "Comenzar campaña" fijo al pie; la fundación del partido lo tiene al final del contenido | Diferencia abierta: unificar la posición con la pantalla de fundación. |
| Mapa visible con el panel Gabinete abierto | Mapa > 1/3 en el día | El panel tapa el mapa (igual que Comité y Congreso) y deja visible la fila Jugar / avanzar | Excepción de hoja a pantalla completa; en la vista de día el mapa mide 290 de 844 px (34,4 %), verificado en `tests/test_ui_humo.gd`. |

Verificación automática (`tests/test_ui_humo.gd`): el botón principal conserva su rectángulo al cambiar de carta y con cada pestaña del panel Gabinete abierta, y el panel nunca lo cubre.

## Pantallas para las primeras pruebas con personas — 23-nov-2026
Sin maqueta (ni en Figma ni en el PDF): se construyeron con los componentes congelados (paleta, Space Grotesk / Inter, zonas táctiles ≥ 44 px, sin emojis) y el botón principal a pantalla completa en el mismo rectángulo que el de fundación y gabinete (16, 739, 358 × 52). Capturas a 390×844 en `docs/comparacion/v3_*.png` (`tests/captura_comparar.gd`).

| Pantalla | Archivo | Qué hace |
|---|---|---|
| Tutorial (5 pasos: mano, movimientos, delegación, gabinete, turno) | `game/componentes/tutorial.gd` | Aparece en la semana 1 de la primera partida con un marco dorado sobre el elemento explicado. Saltable; solo guarda la preferencia local `user://preferencias.json` (`tutorial_visto`). |
| Resultado de la elección (1ª y 2ª vuelta) | `game/pantallas/pantalla_eleccion.gd` | Aprobación del día de la elección frente al umbral (y al piso de 2ª vuelta), desglose por región y aviso de segunda vuelta. El texto dice «aprobación», no «votos»: el motor mide aprobación con un margen de la jornada. |
| Fin de partida | `game/pantallas/pantalla_fin.gd` | Puntaje, promesas cumplidas, leyes aprobadas, obras terminadas y línea de tiempo de los eventos reales vividos (fecha y fuente). |
| Cartera de proyectos | `game/pantallas/pantalla_cartera.gd` | Las 1.276 cartas reales con fuente, estado real y estado en la partida; filtros por tipo, región y sector y paginación. Solo lectura: no llama a ninguna acción del motor. Entradas: menú principal y panel Congreso. |

Diferencias y límites conocidos:
- La derrota en elección mostraba «% de los votos»; ahora dice aprobación (resultado y fin de partida).
- La cartera lista los proyectos reales; el estado «en tu mazo / bloqueada» solo existe con una partida en curso.
- Los chips de filtro se desplazan con el dedo (barra oculta); con muchas regiones hay que deslizar.

## Pendiente
- Trazado propio (estaciones sobre grafo + sliders): extensión de la Fase 3 del Documento Maestro (niveles 2 y 3), sobre el grafo real de calles principales de Gran Santiago (2.459 nodos). Costos y expropiaciones son ilustrativos.
- Reflejar estas mejoras en la maqueta de Figma (no se hizo: requiere gastar créditos de IA del plan y decisión del usuario).
- Medir rendimiento (30 fps, ≤ 800 MB) en un teléfono real.

## Evidencia del botón principal fijo (23-nov-2026, 390x844)
`tests/test_ui_humo.gd` recorre 6 semillas y, con cada carta de la mano y cada pestaña del panel Gabinete, exige que el rectángulo del botón principal sea idéntico (y que el mapa ocupe > 1/3). Rectángulo medido (posición, tamaño) en cada semilla:

| Semilla | Botón principal | Cartas en mano |
|---|---|---|
| 7 | (74, 710) 242×54 | 5 |
| 11 | (74, 710) 242×54 | 5 |
| 20260415 | (74, 710) 242×54 | 5 |
| 31337 | (74, 710) 242×54 | 5 |
| 99991 | (74, 710) 242×54 | 5 |
| 123456 | (74, 710) 242×54 | 5 |

La prueba falla si la posición cambia: la sesión de UI revirtió la corrección del corrector (alto fijo) y obtuvo 9 `FALLO UI`. Captura comparada de la pantalla de juego: `docs/comparacion/v2_dia_maqueta_vs_juego.png` (lado a lado con la maqueta del día del PDF del Documento Maestro; referencia = PDF, no existe maqueta en Figma; fecha 23-nov-2026).

### Corrección: botón principal de la configuración de gabinete (23-nov-2026)
La diferencia que quedaba abierta ("Comenzar campaña" fijo al pie vs botón de fundación al final del contenido) está CORREGIDA: ambos botones miden 358×52 y están en (16, 739) a 390×844. `tests/test_ui_humo.gd` lo exige en las 6 semillas (compara el rectángulo del botón de la fundación con el del gabinete).

## Dirección visual v4: movimiento e integración — 25-nov-2026
Referencia: lienzo de Claude Design «Presidente de Chile — Dirección visual v4» (artboards Menú principal, Pantalla del día, Votación, Resultado de la elección y Sistema de movimiento). Paleta, tipografías, 390×844, zonas táctiles ≥ 44 px y botón principal fijo sin cambios. Comparación antes/después: `docs/comparacion/v4_antes_despues.jpg` (arriba antes, abajo después; `tests/captura_comparar.gd`).

| Elemento | Antes | Ahora | Archivo |
|---|---|---|---|
| Sistema de movimiento | Tweens sueltos por pantalla | Un módulo único: duraciones 120 / 260 / 700 ms, salida cúbica; entradas escalonadas, presión de botones, halo, cifras que cuentan, barras que se llenan, vaivén | `game/componentes/movimiento.gd` |
| Cambio de pantalla | Fundido de 0,22 s | Fundido + subida de 16 px | `game/main.gd` |
| Botones | Estáticos | Todos se hunden a 0,95 y rebotan al soltar (enganche global en `main.gd`) | `movimiento.gd › presion` |
| Botón principal (día, pie de pantallas, menú) | Plano | Halo dorado que respira, dibujado detrás: el rectángulo no cambia (`tests/test_ui_humo.gd`, `tests/test_movimiento.gd`) | `movimiento.gd › halo` |
| Menú | Lista vertical de 7 botones iguales | Insignia + rótulo, cinta tricolor animada bajo el título, motas de ambiente, «Nueva partida» primero con halo, secundarios en grilla 2×2 | `pantalla_menu.gd`, `particulas.gd` |
| Chips de indicadores | Cifra fija | La cifra cuenta, el chip destella verde/coral al cambiar y lleva una mini barra interna (sin cambiar su alto: el mapa sigue > 1/3) | `barras.gd` |
| Pastilla de movimientos | Fija | Late al gastar o recuperar movimientos | `pantalla_dia.gd` |
| Mano | Carta elegida fija | La elegida se mece 3 px tras posarse | `mano_ui.gd` |
| Jugar una carta | La carta desaparecía de la mano | Una copia vuela a la región elegida (gira y se encoge); al llegar, el mapa reacciona con golpe de cámara (acerca, rebota y tiembla), ondas y destello de la región, y el número flotante sale en el punto de impacto | `mano_vuelo.gd`, `mapa_chile.gd › reaccionar` |
| Sello de votación (Senado y Cámara) | APROBADA/RECHAZADA casi sin movimiento: el contenedor le reiniciaba giro y escala | Fuera del contenedor: cae girado desde grande, golpea con onda expansiva, chispas, temblor de la capa y sonido (éxito/error); RECHAZADA hace un vaivén de «no» | `sello_voto.gd` |
| Barra inferior | Sin estado | Pestaña abierta en oro con filo superior | `barras.gd › nav` |
| Hojas (Comité, Congreso, Gabinete) | Aparecen de golpe | Se funden y asientan | `pantalla_dia.gd` |
| Elección | Estática | La cifra cuenta, la barra se llena, regiones escalonadas, confeti oro/rojo/crema al ganar | `pantalla_eleccion.gd` |
| Fin de partida, afiliación, test, gabinete, ajustes | Estáticas | Entradas escalonadas; cifras del resumen cuentan; barra del test se desliza; tarjetas de afiliación con degradado | varias |

### Paquete visual del 25-nov-2026 (pedido por el usuario)
| Elemento | Antes | Ahora | Archivo |
|---|---|---|---|
| Fin de semana | Se pasaba directo a los eventos | Telón que baja con «Semana N → N+1» (o «Día N → N+7»), cada indicador contando de su valor anterior al nuevo con su diferencia en verde o coral; se va solo en ~2 s o al tocarlo, y entonces siguen los eventos | `telon_semana.gd` |
| Hemiciclo de votación | Se llenaba de golpe; la cifra subía proporcional | Los votos caen uno a uno con rebote; el contador va sincronizado con los votos a favor posados; línea dorada «mín. N» que se enciende (con sonido) al cruzarla; si la votación es ajustada (±3 del mínimo), el tramo final va lento; el sello cae al terminar | `hemiciclo.gd › animar_votacion` |
| Escándalo ministerial | Solo un aviso de texto | Destello rojo, titular de diario que entra girando con el ministerio y el alias del ministro, y los chips de Aprobación y Capital tiemblan | `golpe_prensa.gd` |
| Movimientos agotados | El botón cambiaba de texto | La pastilla se sacude y se apaga; el halo de «Siguiente semana» pulsa más rápido y fuerte | `movimiento.gd › movimientos` |
| Mapa vivo | Estático entre jugadas | Las regiones que se movieron en el último cambio laten en verde o coral; el bastión tiene un pulso dorado; las obras se mecen y las propuestas laten. Capa animada aparte: el mapa completo no se redibuja cada cuadro | `mapa_chile.gd › _dibujar_vivo` |

Cuadros del recorrido grabado (`tests/grabar_video.gd`, 780×1688): `docs/comparacion/v4_paquete_visual.jpg` (movimientos agotados, escándalo, telón, votación ajustada, sello aprobado y rechazado).

Limitación: los eventos del juego (`data/eventos.json`) no traen región, así que no hay «pin del evento en su región»; agregarlo exigiría datos nuevos con fuente.

### Paquete 2 del 25-nov-2026: momentos y sonido (pedido por el usuario: «Sigue»)
| Elemento | Antes | Ahora | Archivo |
|---|---|---|---|
| Ganar la elección | Del resultado se pasaba al primer día | Cambio de mando: la banda presidencial (azul, crema y rojo con filo dorado) cruza la pantalla sobre La Moneda, aparece la piocha dorada y la fecha del mandato; se va sola o al tocarla | `cambio_mando.gd` |
| Debates y entrevistas (escenas por rondas) | Mismo diseño que un evento | Focos que barren, marco de cámara, insignia «EN VIVO» que late y puntos de ronda; en radio, «AL AIRE» y ondas de micrófono | `escena_tv.gd` |
| Obra terminada | Solo desaparecía el marcador | Fuegos artificiales oro, crema y rojo sobre la región tras el telón de fin de semana | `mapa_chile.gd › lanzar_fuegos` |
| Música | Sin música | Bucles sintetizados por etapa (campaña, gobierno, oposición; el menú usa gobierno) y pista de tensión mientras hay una votación en pantalla, con fundidos de 1,5 s; ajuste «Música» | `musica.gd`, `tools/audio/generar_musica.py` |
| Ajustes | Animaciones sí/no | Nuevo «Reducir movimiento»: quita temblores, golpe de cámara, chispas, partículas y suaviza el destello rojo; deja fundidos, cifras y barras | `ajustes.gd`, `movimiento.gd › intenso` |

### Claridad (video de prueba, docs/VIDEO_1.md) — 26-nov-2026
| Hallazgo | Antes | Ahora | Archivo |
|---|---|---|---|
| P4 Créditos | Panel centrado que tapaba el título | Hoja inferior desde y=330 que sube al abrirse; el título queda visible | `pantalla_menu.gd` |
| P5/P6 Test ideológico | ~40 % vacío bajo las opciones y «Perfil» sin explicar | Brújula del perfil: ejes Estado↔Mercado y movilización↔vía institucional (los de `data/ideologia.json`), zonas de los 6 perfiles, la tuya en dorado y el punto que se desliza tras cada respuesta | `brujula_perfil.gd` |
| P9 Tutorial | Velo parejo y marco que no destacaba | Foco: todo oscuro salvo el elemento explicado; el marco dorado viaja de un paso a otro y late. La tarjeta y su botón no se mueven (regla del botón fijo) | `tutorial.gd` |
| P10 Mano | Cartas tapadas y textos cortados | Mantener el dedo 0,45 s sobre una carta abre su ficha completa (título entero, costo, efectos con nombre, impacto y exigencia legal); soltar la cierra sin jugarla. El segundo toque sobre la elegida cuenta al soltar | `ficha_ampliada.gd`, `mano_ui.gd`, `carta_ui.gd` |
| P11 Eventos | Título repetido al inicio de la descripción | En los avisos el efecto va primero y la descripción no repite el título («Se publica la Ley N° 21.770: Establece…» → «Establece…») | `overlays_dia.gd` |

Prueba: `tests/test_claridad.gd`.

Reglas: todo el movimiento respeta Ajustes › «Animaciones y movimiento» y se apaga en modo headless, así que las pruebas miden siempre el estado final. El azar de las partículas es solo visual y no toca la semilla de la partida. Prueba propia: `tests/test_movimiento.gd`.
