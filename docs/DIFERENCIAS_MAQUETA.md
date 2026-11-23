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
| Comité y hito de obra | Isométricas ilustradas | Escenas 3D reales de Godot (cámara orbitable, trazado elevado, 5 fases animables) | Cumple la Fase 2 del plan; presupuesto móvil con una sola MultiMesh y sin sombras. |
| Animaciones | (estático) | Reparto de cartas, hemiciclo que se llena, sello que cae, barcos, Comité 2D/3D, reproducción de obra | Superar la maqueta sin cambiar su estructura. |

## Estructura (extensiones coherentes con la Enmienda y con Chile real)
- **Cámara de Diputados** (155) además del Senado (50): dos hemiciclos en Congreso y votación cámara por cámara con "Camino de la ley". Ver `docs/AUDITORIA_VIDA_REAL.md`.
- **Pantalla Nación** con su barra propia (Cartas / Comité / Día N / Congreso / Gabinete), tal como la maqueta.
- **Pantallas sin maqueta**: menú, test ideológico, fundación del partido y fin de partida. Son necesarias para el Modo Único de la Enmienda; se construyeron con los mismos componentes congelados (paleta, tipografías, zonas táctiles ≥ 44 px). No existe referencia en Figma para ellas.

## Pendiente
- Trazado propio (estaciones sobre grafo + sliders): extensión de la Fase 3 del Documento Maestro (niveles 2 y 3), sobre el grafo real de calles principales de Gran Santiago (2.459 nodos). Costos y expropiaciones son ilustrativos.
- Reflejar estas mejoras en la maqueta de Figma (no se hizo: requiere gastar créditos de IA del plan y decisión del usuario).
- Medir rendimiento (30 fps, ≤ 800 MB) en un teléfono real.
