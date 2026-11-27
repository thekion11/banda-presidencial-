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
| Texto de la mano | "Toca una carta · 5 en mano" | "5 mov base · aprob. +2 · asesor +1" | Explica el origen de los movimientos del turno. |
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

Correcciones encontradas al capturar todas las pantallas: dos cartas jugadas seguidas dejaban la onda del mapa sin posición (fallaba el dibujo del mapa) y la pantalla de Ajustes quedaba en tamaño 0 (sin fondo, sobre el menú). Ambas corregidas.

Capturas a 390×844 generadas por `tests/captura_comparar.gd` (función `_v4`): `docs/comparacion/v4_creditos.png`, `v4_test_brujula.png`, `v4_tutorial_foco.png`, `v4_ficha_ampliada.png`, `v4_escandalo.png`, `v4_telon_semana.png`, `v4_votacion_rechazada.png`, `v4_evento_claro.png`, `v4_debate_tv.png`, `v4_radio.png`, `v4_cambio_mando.png` y `v4_ajustes.png`.

### Encuestas en el telón (26-nov-2026)
`estado.encuestas` (sim/encuestas.gd, sesión del motor; forma fijada por `tests/test_encuestas.gd`) se presenta dentro del telón de fin de semana, sin pantalla nueva: intención con su margen de error (franja clara en la barra), umbral de victoria en campaña (marca dorada) o gobierno rival en oposición (marca coral), cambio respecto de la semana anterior y las regiones donde más cuesta. Rotulada «ilustrativa». En gobierno no aparece. Captura: `docs/comparacion/v4_telon_semana.png`.

### Daltonismo en todo lo que sube o baja (26-nov-2026)
`Ajustes › Colores para daltonismo` antes solo cambiaba la escala de aprobación; el resto del juego seguía usando verde contra coral (difícil con deuteranopía). Ahora `Tema.bien()` / `Tema.mal()` (y `bien_tinta()` / `mal_tinta()` sobre crema) devuelven azul y naranja Okabe-Ito con el ajuste activo, y la paleta congelada sin él. Se usan en votos del hemiciclo, sellos, telón, mapa vivo, reacción del mapa, chips, ficha ampliada, número flotante y paneles. Contraste ≥ 4,5:1 comprobado en `tests/test_claridad.gd`. Con texto grande, el título del telón cabe en una línea.

### Lienzo de Claude Design (26-nov-2026)
El lienzo «Presidente de Chile — Dirección visual v4» tiene dos páginas: **Dirección visual** (5 maquetas: menú, día, votación, elección y la hoja del sistema de movimiento, ampliada con todas las piezas nuevas) y **Juego actual** (24 capturas reales a 780×1688 de todas las pantallas: menú, créditos, afiliación, test con brújula, gabinete, tutorial con foco, día, ficha ampliada, carta al mapa, movimientos agotados, escándalo, Congreso, telón, votación con suspenso, aprobada y rechazada, evento claro, debate en TV y en radio, fuegos, elección, cambio de mando, fin y ajustes).

### Comparación v4 con la maqueta (26-nov-2026)
Lado a lado actualizado: `docs/comparacion/v4_dia_maqueta_vs_juego.png`. Se corrigió lo que se apartaba sin motivo:
- **Día:** vuelve la línea punteada dorada que une la región elegida con su tarjeta, y la región se marca con el contorno dorado desde que se abre la pantalla (antes solo al tocarla). «0 obra(s) en curso» pasa a «0 obras / 1 obra en curso»; «base 5» pasa a «5 mov base».
- **Cabecera:** el título de campaña «Campaña · Semana 1 de 8» ensanchaba la pantalla a 403 px, y la barra inferior y el selector de Nación se salían 1 px. Ahora es «Campaña · Sem. 1/8», el mismo formato que la oposición, y `tests/test_textos.gd` exige que nada se salga de los 390 px.
- **Nación:** vuelve el rótulo de la maqueta «Límites: datos abiertos (ilustrativo)» bajo la lista de regiones.
- **Hemiciclo:** con 5 filas (Senado) y 8 (Cámara), los asientos quedaban más separados a lo largo de cada fila que entre filas y se leían como rayos. Ahora son 4 y 6 filas, con anillos parejos como en la maqueta. Lado a lado: `docs/comparacion/v4_votacion_maqueta_vs_juego.png` y `v4_nacion_maqueta_vs_juego.png`.
- Siguen apartándose a propósito: cifras reales de la partida, «Terminar semana» en lugar de «Jugar» (PR-02), «Camino de la ley» por la votación bicameral y la cifra central, que se vuelve verde al cruzar el mínimo.

### Paleta congelada con prueba (26-nov-2026)
`tests/test_paleta.gd` lee todos los colores escritos en `game/` y exige que cada uno sea un color de la paleta (CLAUDE.md §5, más las tintas Okabe-Ito del modo daltónico) o una mezcla de dos de ellos o con negro o blanco, con una diferencia perceptual de hasta ΔE 8. Detectó cinco colores fuera de la paleta: cuatro cintas de categoría (Comité, Educación, Social y Política, violetas y magentas) y el filtro «Cárceles» del mapa urbano. Ahora son mezclas de la paleta (#2476B6, #5873A4, #945360, #6E678A y #216EA9), siguen distinguibles entre sí (ΔE ≥ 12) y la cinta oscurecida mantiene contraste ≥ 4,5 con su texto crema.

### Otros tamaños de teléfono (26-nov-2026)
El proyecto escala con ancho lógico fijo de 390 (`keep_width`), así que cada teléfono cambia solo el alto: 360×640 queda en 390×693, 412×915 en 390×866 y 480×1000 en 390×812. `tests/test_textos.gd` y `tests/test_tactil.gd` recorren ahora las cuatro alturas (`RecorridoUI.ALTURAS`) y exigen que ningún texto ni botón se salga de la pantalla, salvo dentro de una zona desplazable. Solo fallaba 390×693, y de forma grave: el botón «Terminar semana» quedaba fuera de la pantalla, y lo mismo el botón de la votación y la franja del perfil en el test ideológico. Con `Tema.pantalla_baja()` (alto < 760) esas pantallas compactan alturas fijas: menos aire sobre la mano (214 → 198), Corrector de 66 a 50, hemiciclo de 230 a 170, opciones del test de 62 a 52 (≥ 44), brújula de 150 a 116 y márgenes menores. En 390×844 todo queda igual.
**Proporciones extremas (27-nov-2026, `Main.aspecto_para`):** con `keep_width`, una tablet 768×1024 quedaba en 390×520 lógicos y un plegable abierto 884×1104 en 390×487, y no cabía la pantalla del día. Ahora, si la pantalla es más ancha que 16:9 (ancho/alto > 0,565), se muestra el 390×844 completo y centrado, con bandas color océano a los lados, y se vuelve a calcular al abrir o cerrar el plegable. Teléfonos medidos:

| Teléfono | Alto lógico |
|---|---|
| 360×640 | 693 |
| 360×800 y 412×915 | ~866 |
| 1080×2400 | 867 |
| Plegable cerrado 280×653 | 910 (agregado a `RecorridoUI.ALTURAS`) |

El botón principal queda en la misma posición dentro de cada pantalla, y las auditorías de textos y zonas táctiles pasan en los cinco altos.
**Resuelto (27-nov-2026):** en 390×693 el mapa del día llegó a medir el 27 % de la pantalla. Al compactar la cabecera y la barra pasó al 32 %, y en pantalla baja se quita la fila «Tu mano · 5 mov base» (los movimientos siguen en la pastilla de la cabecera). Ahora el mapa supera el tercio en todos los altos probados, comprobado en `tests/test_reglas_ui.gd`.

### Letra grande de Android (1,3 y 1,5) (26-nov-2026)
Godot no aplica la escala de letra del sistema Android a la interfaz. Hoy el juego ofrece «Texto grande» (+15 % en las etiquetas con ajuste de línea, vía `Ajustes.escala_texto()`). `tests/test_textos.gd` recorre además todas las pantallas con la letra a ×1,3 y ×1,5 (`Ajustes.escala_prueba`, solo para pruebas) y exige que nada se salga de la pantalla. Cambios para que quepa:
- el título del menú (46 pt) ya no crece;
- las opciones del test ideológico se desplazan si no caben, y la franja del perfil queda fija y crece con la letra.

**Decisión pendiente del usuario:** seguir la escala de letra del sistema Android necesitaría un plugin nativo (Configuration.fontScale). También se podría ofrecer un tamaño de letra mayor que el «Texto grande» actual. Las dos cosas son ampliaciones de alcance.

### Estados vacíos y de error (26-nov-2026)
Cada estado dice qué pasa y ofrece una acción viable, nunca un «no» seco. Prueba: `tests/test_estados.gd`. Capturas: `docs/comparacion/e_*.png`.
- **Sin movimientos:** el Corrector lo dice. En gobierno ofrece delegar la carta (no gasta movimientos) o terminar la semana; en campaña, terminar la semana, porque se renuevan al empezar la próxima.
- **Sin cartas:** la zona de la mano explica que al empezar la próxima semana entran cartas nuevas, y el Corrector sugiere revisar el Comité, el Congreso o el gabinete. Antes la zona quedaba en blanco.
- **Guardado dañado:** el juego lo aparta (`guardado_descartado.json`) y vuelve al menú con el aviso «Empieza una partida nueva». Esto ya estaba en main, con la validación de la sesión del motor.
- **Crisis:** con la aprobación bajo el umbral de `leyes.json` (12 %), el gobierno cae al completar 3 semanas seguidas (`MotorMandato.evaluar_crisis`). La interfaz no lo mostraba; ahora la fecha de la cabecera cambia, en coral, por «Crisis: caes en N semanas», y al cerrar cada semana en crisis un aviso lo explica. Propuesto por la sesión del motor; es información que ya existía, no una mecánica nueva. Captura: `e_crisis.png`.
- **Datos faltantes** (instalación dañada): antes de cargar se comprueba que estén todos los archivos. Si falta alguno, se dice cuál y se ofrece actualizar o reinstalar el juego, en vez de un error de script.

### Conteo de toques (26-nov-2026, `tests/medir_toques.gd`)
Medido en la interfaz real: 3 partidas de 30 semanas, campaña, elección y gobierno.
- **Jugar una carta:** 2 toques (elegirla y tocarla otra vez) o un solo gesto (deslizarla hacia arriba).
- **Delegar:** 2 toques (soltar la carta sobre el ícono y confirmar) o 3 (elegir, ícono y confirmar).
- **Terminar la semana:** 1 toque. Pide un segundo solo si quedan movimientos: pasó 3 veces en 90 semanas, y en las 3 lo que quedaba no alcanzaba para ninguna carta.
- **Eventos y votaciones después de cada semana:** 2,8 toques de media, mediana 2 y máximo 10. El 22 % de las semanas pide 5 o más. Por clase de pantalla, el 52 % son votaciones (2 páginas cuando el proyecto pasa a la otra cámara), el 30 % avisos y el 19 % decisiones. El telón se cierra solo y no cuenta.

Ninguna acción pasa de 3 toques; lo que se acumula es la secuencia de eventos. **Propuestas para el usuario** (sin pantallas nuevas):
- a) no pedir confirmación al terminar la semana cuando los movimientos que quedan no pagan ninguna carta (toca la decisión PR-02);
- b) mostrar la cámara revisora en la misma página de la votación cuando el resultado de la primera ya está decidido, lo que ahorraría unos 0,7 toques por semana.

### Cabecera y barra del día más cerca de la maqueta (26-nov-2026)
La diferencia numérica (`docs/comparacion/DIFERENCIA_MAQUETA.md`) mostraba que la cabecera del día ocupaba 111 px frente a unos 82 en la maqueta, lo que corría todo hacia abajo y achicaba el mapa. Cambios:
- el margen superior fijo de 30 px pasa a seguir la zona segura del teléfono (`Tema.margen_superior()`: la muesca o cámara más 4 px, mínimo 12);
- los chips de indicadores se compactan (relleno de 3 y 6 px) y la barra inferior también (2 y 4 px). Los botones siguen ≥ 44 px.

Píxeles distintos del día frente a la maqueta: de 43,1 % a 39,2 %. El mapa gana unos 30 px de alto.

En la votación: el contenido sube con la zona segura, el hemiciclo del Senado se compacta (radio 0,41 del ancho en vez de 0,46, alto 205 en vez de 230) y el sello «APROBADA / RECHAZADA» pasa a 32 pt con letras separadas, como en la maqueta. Píxeles distintos: de 22,5 % a 22,0 %.

En el mapa urbano, las fichas de líneas de Metro (una extensión sobre la maqueta) ocupaban dos filas sobre el mapa, y la hoja de obras se salía por abajo: su tercera fila quedaba cortada. Ahora las fichas van en una sola fila que se desliza de lado (`LeyendaMetro.compacta`) y las notas de líneas futuras y propias, bajo el mapa (`notas_aparte`). Todo cabe y los píxeles distintos bajan de 23,0 % a 21,8 %. El mapa urbano entra también a `RecorridoUI`, así que lo cubren las auditorías de textos y zonas táctiles.

El hito de obra y el mapa urbano también usan la zona segura arriba (antes 40 px fijos). Las cifras grandes llevan punto de miles, como en la maqueta: «+1.540», «US$1.900 M» (`Tema.miles`). Hito: de 19,1 % a 17,8 %; urbano: de 21,8 % a 21,3 %.

### Atrás de Android, coma decimal, corte de legado y confeti (26-nov-2026)
- **Botón Atrás** (hallazgo de «Búsqueda infinita de fallas»; comportamiento propuesto por la sesión del motor; `Main.atras`, prueba `tests/test_atras.gd`). Antes cerraba la app sin preguntar en cualquier pantalla. Ahora `quit_on_go_back = false` y Atrás:
  - cierra lo que esté encima: mapa urbano, hito, cartera, delegación, ficha, ajustes, créditos, tutorial o telón;
  - no salta un evento, una votación ni el resultado de la elección: avisa que hay que responder;
  - con un panel del día abierto, vuelve al mapa;
  - en el día pide un segundo Atrás para ir al menú, con la partida guardada, y en el menú un segundo Atrás para salir.
- **Coma decimal** (hallazgo de «Búsqueda»): los decimales visibles llevan coma, como en Chile: «57,4 %», «± 3,6», «TIR 3,5 %», «+1,5 desde la semana pasada» (`Tema.dec`, con prueba en `test_claridad`).
- **Corte de legado** (pedido de la sesión del motor): al cerrar las semanas 104 y 208 de gobierno, cada promesa pendiente resta capital y aprobación (`leyes.json › legado`). El panel de metas de legado dice cuánto costará y cuántas semanas faltan, en coral desde 8 semanas antes. En las 4 últimas, un aviso lo recuerda al cerrar cada semana. Prueba en `test_estados`.
- **Confeti** de la elección ganada: cae detrás del contenido, sin tapar el título ni las cifras.
- **Cintas de las cartas:** el nombre del sector salía de `to_upper()` y perdía la tilde: «EDUCACION», «POLITICA», «ENERGIA», «ECONOMIA», «OPOSICION». Ahora lleva tilde y todos caben en los 62 px de la cinta. Oposición y Estado no tenían color propio; ahora tienen colores de la paleta, distinguibles de los demás. Si alguna vez faltara una ilustración, la carta muestra su color y el nombre del sector en vez de quedar vacía. `test_claridad` comprueba que cada categoría de los datos tenga color, ilustración y una cinta con tilde que quepa.
- **Respaldo del guardado** (revisión de código #1 de la sesión del motor): `guardar()` copia el guardado bueno a `guardado.bak` antes de reemplazarlo. Si al continuar el guardado está dañado (truncado, por ejemplo) y el respaldo sirve, se recupera con el aviso «Recuperamos tu partida de hace un momento»; si no hay respaldo, se descarta como antes. Una partida nueva borra el respaldo de la anterior. Prueba en `test_estados`.

### Piso del desvío del día y de Nación (27-nov-2026)
Desglose por franja de los píxeles distintos frente a la maqueta (ΔE > 20, `tools/diferencia_maqueta.py`):

| Pantalla | Franja | Puntos del total |
|---|---|---|
| Día (39,2 %) | Mano | 16,9 |
| | Mapa y tarjetas | 10,0 |
| | Corrector | 5,6 |
| | Botones | 3,2 |
| | Barra | 1,9 |
| | Cabecera | 1,5 |
| Nación (29,2 %) | Mapa y lista | 21,6 |
| | Selector Chile/Continente | 2,6 |
| | Cabecera | 1,8 |
| | Barra | 1,8 |
| | Evento | 1,3 |

**Por qué no baja más sin romper reglas o decisiones:**
- **Mano:** las cartas llevan ilustraciones pintadas, no los dibujos planos de la maqueta, y la mano muestra cartas reales de la partida.
- **Mapa:** los colores salen de la aprobación real de la partida (la maqueta usa cifras ilustrativas de 58 a 90 %) y el relieve es real.
- **Corrector:** suma una línea con el costo y el impacto de la carta, que vino del pase de claridad.
- **Botones:** «Terminar semana» y la esquina vacía son la decisión PR-02 del usuario.
- **Nación:** el selector Chile/Continente es la ampliación PR-06c.

Lo estructural que sí se podía alinear ya está hecho: zona segura, chips y barra compactos, línea región–tarjeta, contornos, botón «▶ Día N».

**Piso estimado:** unos 30 % para el día y unos 25 % para Nación, mientras se mantengan el arte pintado y los datos reales. Bajar de ahí pediría volver al arte plano de la maqueta o usar cifras ilustrativas en el mapa, y las dos cosas son decisión del usuario.

Reglas: todo el movimiento respeta Ajustes › «Animaciones y movimiento» y se apaga en modo headless, así que las pruebas miden siempre el estado final. El azar de las partículas es solo visual y no toca la semilla de la partida. Prueba propia: `tests/test_movimiento.gd`.


## Mapa del país más grande y con zoom (pedido del usuario, 27-nov-2026)

Cita literal del usuario (27-nov-2026, ~03:00 UTC, transmitida por la coordinadora): «El mapa del país debe agrandarse un poco para ver todas las regiones, además de poder hacerle zoom, la elección del personal del gabinete no es tan entretenida además de qué es solo un formulario, es poco atractivo».

- **Más grande:** en la pantalla del día el país se dibuja ~17 % más ancho (`estirar_x` de 2,3 a 2,7, centro en 0,29). Ocupa el mar libre a la izquierda de las tarjetas sin taparlas. La diferencia numérica con la maqueta casi no cambia (día 39,3 → 39,4 %).
- **Zoom** (`game/componentes/mapa_zoom.gd`, en el día y en Nación): doble toque para acercar ×2,5 sobre el punto o volver; pellizco (`InputEventMagnifyGesture`, también en Android) y rueda del ratón acercan sobre el dedo, hasta ×4; con el mapa acercado, arrastrar desplaza sin dejar ver fuera del mapa; el botón «Ver todo» (≥ 44 px) vuelve a la vista completa. Al acercar (≥ ×1,6) cada región lleva su nombre, sin que se encimen; tocar un nombre elige la región (área ≥ 44 px). La región elegida se elige al soltar, porque el arrastre desplaza. Con «Reducir movimiento» o sin animaciones el zoom no se anima.
- **Rendimiento:** la capa base sigue en caché y se repinta solo al cambiar el zoom o el encuadre; mientras dura el gesto se dibuja en vivo, como durante la reacción a una carta. `medir_cuadros`: el día en reposo sigue en 201 llamadas.
- **Pruebas:** `tests/test_mapa_zoom.gd` (doble toque, «Ver todo», pellizco, rueda, tope, arrastre con límites, toque y nombre que eligen, carta que vuela al punto visible, doble toque real por `Input.parse_input_event`), más `test_gestos`, `test_toque_real` y `test_reglas_ui` (mapa > 1/3).


## Movimientos: solo los disponibles, con símbolo (pedido del usuario, 27-nov-2026)

Cita literal (27-nov ~03:10 UTC): «Los movimientos deben poder guardar si no los use […] la parte de movimiento de arriba solo debe marcar los movimientos disponibles no lo de 5/5 ya qué se pueden acumular, por otro lado la palabra movimientos está cortada es mejor cambiarla por un símbolo que de a entender».

- La pastilla de la cabecera muestra el rayo y el número disponible («7»), sin «/5». Con el tope de ahorro (10), cuando el motor lo publique, mostrará «10 · tope». Tocarla explica: «Movimientos disponibles (el rayo): cada carta cuesta de 1 a 3».
- «Terminar semana» ya no lleva el número; la ficha de la carta muestra el rayo y el costo; el Corrector, el Comité y SECTRA dicen «cuesta N»; la mano dice «5 por semana».
- El símbolo alternativo (ficha de acción) está en el lienzo, página «Propuesta 27-nov», para que el usuario elija.
- Falta, cuando el motor guarde los movimientos: que «Terminar semana» deje de pedir confirmación si sobran y avise «Se guardan N», y actualizar el tutorial.


## Riel de regiones en el mapa del día (elección del usuario, 27-nov-2026)

El usuario eligió «Mapa A + riel de regiones (Recomendado)» en la página «Propuesta 27-nov» del lienzo. A la derecha del mapa, donde la maqueta pone las tarjetas de evento y de región, va un riel deslizable con las 16 regiones de norte a sur y su aprobación en color (`game/componentes/riel_regiones.gd`). Tocar una región la elige y acerca el mapa sobre ella; tocarla otra vez abre su detalle (Nación, o el mapa urbano para la Metropolitana). La línea punteada une la región con su fila. El evento del día pasa a la cabecera, junto a la fecha, y tocarlo lo muestra completo. La leyenda de colores del mapa sale: el riel ya muestra el porcentaje. Diferencia con la maqueta en el día: 39,4 → 39,8 %. Prueba: `tests/test_mapa_zoom.gd` (16 regiones en orden, porcentajes del motor, elegir, acercar y abrir el detalle).
