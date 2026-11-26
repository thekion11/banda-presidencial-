# Decisiones que esperan al usuario (26-nov-2026)

Una sola tabla con lo que **no** puede decidir ningún agente: cada fila trae la recomendación y el costo de cada opción. El detalle y la evidencia están en `docs/DECISIONES.md` (sección entre paréntesis) y en `docs/PENDIENTES_USUARIO.md` (U1 a U10). Lo que dependa de personas reales se resuelve con la prueba cerrada (`docs/PRUEBA_CERRADA.md`).

## A. Diseño y balance
| # | Decisión | Opciones y costo | Recomendación | Evidencia |
|---|---|---|---|---|
| D1 | **Duración del juego** (hoy 208 turnos por mandato; 20 min de sesión) | a) mantener 208 con semanas silenciosas que se saltan solas: costo bajo (motor y datos ya listos; falta UI de resumen). b) 1 turno = 1 mes (≈ 48 turnos): costo alto, reescala eventos, obras y plazos, y rehace oros. c) capítulos de ~20 min con guardado: costo medio, solo UI y cortes narrativos | **a) como primer paso, medir en la prueba cerrada** si la sesión de 20 min alcanza para un capítulo; b) solo si los testers dicen «largo» | §K, §Y; `PRUEBA_CERRADA.md` §4 |
| D2 | **Dificultad en Normal** (bots que juegan bien ganan ≈ 96 %; salto a Difícil ≈ 48 %) | a) dejar. b) restar aprobación inicial a Normal (−1,5): costo de un cambio de datos y regenerar oros. c) suavizar Difícil (−2,0 de aprobación inicial, +1,5 de umbral). d) añadir un nivel intermedio: costo medio en UI | **Esperar los datos de personas** (los bots no juegan como humanos); si ganan > 85 %, aplicar b) | §AA |
| D3 | **Bono por aprobación**: originales (60 a 100) o recalibrados (45 a 95) | a) recalibrados (hoy, con efecto medible −5 %). b) originales: la mecánica queda casi inerte (−3 %) | **a)** | §R, `DISENO_V2.md` §11 |
| D4 | **Umbral de victoria** 52 (el documento original decía 51 y el PDF 50) | Cambiar mueve toda la dificultad (cada punto ≈ 20 puntos de % de victoria para quien juega bien) | Dejar 52 y decidir con D2 | §AA |
| D5 | **Cartas de «Estado»** (se juegan el 7 %) | 1) dejar. 2) beneficios diferidos con el campo que ya existe (datos, bajo). 3) bajar costos (rompe la señal). 4) ligarlas a la ideología (mecánica nueva) | **2) para las 6 de menor costo** | §AD |
| D6 | **Delegación e internos** valen ≈ 25-30 % del puntaje cada uno | Rebalancear con otro costo (capital no movió nada); depende de cómo los usen personas | Esperar la prueba cerrada | §T |
| D7 | **Audiencia por debate** (hoy solo dato, sin efecto) | Darle efecto sobre los resultados: cambia el balance | Esperar la prueba cerrada | §Z |
| D8 | **Más eventos anuales en los años 2 a 4** (38 de 54 programados caen en el año 1) | Contenido nuevo: cuenta pública, incendios, receso legislativo (≈ 12 eventos); costo medio | Hacerlo si los testers sienten vacío después del año 1 | §AC |
| D9 | **Noche electoral y carta que sigue al dedo** (propuestas de la sesión visual) | Cambian cómo se juega; mecánicas/pantallas nuevas | Requiere tu autorización (alcance congelado) | — |
| D10 | **Regla «solo se guarda semilla, partido e historial»** y la instantánea de carga | a) mantener la caché desechable (hoy). b) borrar `sim/instantanea.gd`: la carga de un mandato pasa de 12 ms a 130-200 ms | a), la fuente de verdad no cambia | §Y |

## B. Contenido y datos
| # | Decisión | Opciones y costo | Recomendación |
|---|---|---|---|
| D11 | **Artículo 25 de la Constitución** (reelección ilustrativa) | Aportar el texto oficial o autorizar una fuente (bcn.cl da 401 desde aquí) | Aportar el texto: desbloquea modelar la regla real |
| D12 | **~600 cartas de proyectos reales sin verificar** | Verificar leyendo cada fuente primaria (≈ 1 hora por 20 fichas) o mantener el rótulo de «cifras ilustrativas» | Mantener el rótulo y verificar por lotes por área (lista en `PENDIENTES_USUARIO.md`) |
| D13 | **Arte** (13 categorías, retratos, moderador) | Gemini (cupo), Canva/Figma (sin créditos) o arte propio | U7 |

## C. Legal y publicación (U4 a U10)
| # | Decisión | Costo | Recomendación |
|---|---|---|---|
| U4 | Revisión legal de alias satíricos, partidos y textos | Un abogado chileno | Antes de cualquier publicación |
| U5, U6 | Metro S.A. (colores/nombres) y licencias del arte | Confirmaciones externas | Antes de publicar |
| U8 | Poner `main` como rama por defecto en GitHub | 1 minuto en Settings | Hacerlo |
| U9 | Monetización | Condiciona qué datos se recolectan | Después de la prueba cerrada |
| U10 | Google Play y keystore de release | En pausa por instrucción | Cuando D1 y D2 estén decididos |

## Cómo se usa esta tabla
Cuando decidas algo, dímelo con el número (p. ej. «D2 b») y se aplica, se mide con los bots, se regeneran los oros y queda en `docs/DECISIONES.md` el mismo día.
