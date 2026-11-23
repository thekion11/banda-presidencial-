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
