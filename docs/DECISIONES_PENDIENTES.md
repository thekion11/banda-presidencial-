# Decisiones que esperan al usuario (26-nov-2026)

> **Actualización del 27-nov-2026: el usuario aceptó las recomendaciones de este documento y de `RESUMEN_DECISIONES.md` en todo lo que no marcó distinto** (`DECISIONES.md` §BJ). Cerradas: D19, D20, D17 (congelar `data/` tras las cartas del plan), renderizador `gl_compatibility`, bono por aprobación 45–95 (D3) y umbral 52 (D4) como están. Sin cambios de balance fuera de eso.

Una sola tabla con lo que **no** puede decidir ningún agente: cada fila trae la recomendación y el costo de cada opción. El detalle y la evidencia están en `docs/DECISIONES.md` (sección entre paréntesis) y en `docs/PENDIENTES_USUARIO.md` (U1 a U10). Lo que dependa de personas reales se resuelve con la prueba cerrada (`docs/PRUEBA_CERRADA.md`).

## Las 5 decisiones clave (por impacto, con mi recomendación)
| # | Decisión | Recomendación | ¿Un sí/no? |
|---|---|---|---|
| 1 | **Duración de la partida** (D1): hoy un mandato son unas 6 sesiones de 20 min | Mantener 208 semanas y medirlo en la prueba cerrada | No: tres opciones |
| 2 | **Dificultad** (D2, D4, D16): la dificultad solo cambia la campaña; en Normal los bots que juegan bien ganan 94 % | Esperar datos de personas; si en Normal ganan más del 85 %, restar 1,5 de aprobación inicial | No |
| 3 | **Métricas locales con consentimiento** en la prueba cerrada (`PRUEBA_CERRADA.md` §6) | Sí: sin ellas la prueba solo tiene lo que cuenten los testers | **Sí/no** |
| 4 | **Congelar `data/` durante la prueba cerrada** (D17): cualquier cambio de datos borra las partidas guardadas de los testers | Sí | **Sí/no** |
| 5 | **Licencias antes de publicar**: imágenes con IA, código, SECTRA, GeoJSON y base ODbL (`LICENCIAS.md`) | Confirmar el uso comercial del arte antes de abrir Google Play | No: confirmaciones externas |

### Se resuelven con un solo sí/no
| # | Pregunta | Recomendación |
|---|---|---|
| D3 | ¿Dejar el bono por aprobación recalibrado (45 a 95) en vez del original (60 a 100)? | Sí |
| D15 | ¿Mantener la cohesión con desgaste (−1,85 por semana)? | Sí |
| D4 | ¿Dejar el umbral de victoria en 52? | Sí (decidirlo junto con D2) |
| U8 | ¿Poner `main` como rama por defecto en GitHub? | Sí (1 minuto en Settings) |
| PR #8 | ¿Pasar a «Ready for review» y fusionar el PR de pruebas de «Búsqueda infinita de fallas» cuando su CI quede en verde? | Sí |
| 3 y 4 | Métricas con consentimiento y congelar `data/` (arriba) | Sí |

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
| D14 | **Corrector para leyes rechazadas** (hoy solo 7 de 1.964 cartas ofrecen versión viable o por tramos; una ley rechazada pierde capital y la carta) | a) dejar. b) «reingresar una versión reducida» tras una derrota: mecánica nueva, costo medio | Esperar la prueba cerrada: solo el 5 % de las leyes se rechaza | §AF |
| D15 | **Cohesión con desgaste** (aplicado: −1,85/semana; antes estaba saturada en 100) | Mantener, revertir a +0,2 o ajustar (−1,0 casi no cambia nada; −2,0 la deja en 47) | Mantener y revisar con la prueba cerrada | §AF |
| D16 | **La dificultad solo cambia la campaña** (Monte Carlo de «Búsqueda infinita de fallas», 40 partidas por celda: en fácil el azar gana la elección el 100 % y el pasivo el 25 %; «completo» no cae en crisis en ninguna dificultad y su puntaje mediano es ≈ 3.000 en las tres; en difícil el codicioso gana el 52,5 %) | a) dejar (la dificultad es de campaña). b) que los presets también toquen el gobierno (regeneración fiscal, umbral de crisis, desgaste de aprobación): solo datos en `leyes.json`, pero cambia el balance y hay que regenerar los oros. c) rebajar el azar en fácil (menos aprobación inicial) | Decidir tras la prueba cerrada; si se hace, opción b con techos por dificultad en `test_balance` | §AA, §AM |
| D17 | **Guardados entre versiones**: cualquier cambio de `data/` cambia la huella y los guardados viejos se descartan (renombrados a `guardado_descartado.json`, con aviso); un guardado sin `version` también | a) aceptarlo (hoy) y **congelar `data/` durante la prueba cerrada**. b) avisar y preguntar antes de descartar y guardar la «revisión de datos» junto a la partida (costo medio, solo UI y un campo). c) que la huella cubra solo lo que cambia el resultado y no los textos (costo alto, riesgo de falsos válidos) | **a)** para la prueba cerrada; b) si habrá actualizaciones frecuentes | `FORMATO_GUARDADO.md` |
| D18 | **Regenerar `data/cartas_reales.json`**: `tools/generar_cartas.py` con los datos de hoy cambia la `disponibilidad` (evento, meta o ventana a la que se liga la carta) de **102 de 1.685 cartas** respecto del archivo publicado; el resto es idéntico. Causa: la lista de eventos cambió después de generar el archivo (se retiraron duplicados, §BC), y el generador reparte las cartas por orden de eventos | a) dejarlo como está (válido: todas las referencias existen; las 102 cartas simplemente aparecen ligadas a otro evento). b) regenerar: el catálogo queda en sincronía con el generador y los datos. **Efectos de b):** cambia qué cartas entran al mazo y cuándo, así que cambian las pruebas de oro (`ORO` de `test_prueba_oro_completa`, `tests/oro/huellas.json`), hay que repetir el Monte Carlo (`tests/informe_dificultad.gd`) y se invalida cualquier guardado de la versión anterior (huella de datos) | **a)** hasta después de la prueba cerrada (congelar `data/`, D17); hacer b) cuando se abra una nueva versión de datos, junto con los oros y el Monte Carlo | `VERIFICACION_CONSTITUCIONAL.md` |

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

## D19. CERRADA el 27-nov-2026 (el usuario: dejar el test rápido y enmendar CLAUDE.md; hecho). Test ideológico rápido (3 preguntas) por defecto para fundadores e independientes
- Qué hay: commit 1619c07 (25-nov-2026, DECISIONES.md §S) lo introdujo para cumplir la meta de ≤ 3 toques antes del primer turno; un botón cambia al test completo de 8 preguntas. Los deltas rápidos (×1,8) están en `data/ideologia.json › rapido`.
- Discrepancia: CLAUDE.md §2 (PR-01) dice test completo de 8 preguntas para fundadores e independientes. En los documentos no hay una autorización explícita del usuario para el test rápido por defecto; figuraba como «pendiente» en DECISIONES.md §Q.
- Opciones: (a) dejarlo por defecto y enmendar CLAUDE.md; (b) por defecto el de 8 preguntas, con el rápido como opción. Recomendación: (a), por la sesión de ~20 min, pero la decide el usuario.

## D20. Cartas del Plan Estratégico (27-nov-2026): CERRADA el 27-nov-2026 (el usuario confirmó; CLAUDE.md §2, commit 27ced2a)
- Qué hay: 16 cartas `plan_*` (DECISIONES §BI, `docs/PLAN_ESTRATEGICO_CARTAS.md`) hechas por encargo de la coordinadora, que dice que el usuario las pidió hoy («Cartas del juego»).
- Cita de la coordinadora (27-nov-2026, ~02:00 UTC, su conversación): el usuario pegó el «Plan Estratégico de Desarrollo, Soberanía Financiera e Industrialización de Chile (Visión Integral)» sin más texto; ante la pregunta «¿Qué quieres que hagan las sesiones?» (opciones: Cartas del juego (Recomendado) / Revisión crítica / Perfeccionar el documento / Solo guardarlo) respondió «Cartas del juego (Recomendado)» (descripción: «Convertir las 8 propuestas en cartas/proyectos jugables con costos, efectos, plazos y su validación legal, rotuladas como cifras ilustrativas. Es contenido nuevo: lo autorizas tú, y quedaría registrado en docs con fecha y fuente.»).
- Falta: que el usuario lo confirme en esta sesión (o pegue su texto) para anotarlo como ampliación autorizada en CLAUDE.md §2. Mientras tanto son reversibles con un commit.
- Recomendación: confirmar; revisar los valores de riesgo y diferido tras jugar con ellas (entran antes de congelar `data/`, D17).


## D21. Dificultad de las 3 reformas constitucionales del plan (27-nov-2026)
- Hallazgo de «Búsqueda» (Monte Carlo sobre las 16 cartas `plan_*`; `tests/test_plan_cartas.gd` fija el contrato): se aprueban en 73–95 % de las partidas de gobierno, y las tres reformas 4/7 (`plan_afp_estatal`, `plan_coeva`, `plan_fondo_regla`) pasan en 86–95 %, alto para una reforma constitucional. Ninguna carta es dominante (cuestan capital −0,3 a −7,7; ganancias modestas). A vigilar: `plan_exportar_agua` (+2,0 aprobación y +3,4 fiscal a 52 semanas pese al riesgo de 55 %), no concluyente.
- Causa probable (no medida por mí): la composición del Congreso (apoyo base más coalición) hace que 4/7 se alcance seguido con coalición completa; es una propiedad del modelo del Congreso, no de las cartas.
- Opciones: a) dejarlas (hoy; `data/` congelado). b) descongelar solo esas 3 filas y exigir más (p. ej. capital mínimo o coalición mínima en `requisitos`): cambia huella y oros y debe ir antes de repartir la prueba cerrada. c) subir la dificultad del 4/7 en el Congreso para todas las reformas: cambio de balance general, mayor alcance.
- Recomendación: a) por ahora, y decidir con los datos de personas de la prueba cerrada; si se quiere endurecer, b) es lo mínimo y se hace antes de entregar la prueba. Es del usuario: toca `data/` congelado.
- **Medición de «Búsqueda» para D21 (`tests/analisis_plan2.gd`, 3 bots, 3 dificultades, semanas de gobierno 0, 26 y 104; mínimo 29 de 50 senadores y 89 de 155 diputados):** en las semanas 0 y 26 el 4/7 casi no limita (≈ 43–45 de 50 y ≈ 131–143 de 155 a favor, 86–90 % de cada cámara), y la aprobación (75–100 %) la decide sobre todo el Tribunal Constitucional (10–30 % de caídas por recurso o inconstitucionalidad), no los votos. En la semana 104 el margen se estrecha (≈ 31–33 y ≈ 94–103) y se aprueba en 50–86 % (codicioso) y 70–100 % (humano). No es un artefacto del bot: con los tres bots el apoyo es igual; depende del modelo del Congreso y la coalición. Confirma la causa probable de arriba. La recomendación no cambia (a): decidir con datos de personas; si se endurece, hacerlo en el Congreso para todas las reformas o con requisitos en esas 3 cartas.

## D22. Gabinete más atractivo con contenido nuevo (petición del usuario, 27-nov-2026)
- Contexto: el usuario dijo que elegir el gabinete es «solo un formulario, es poco atractivo» (DECISIONES §BK). Visual lo mejora con lo que ya existe (alias, estilo, rasgo, afinidad, riesgo de escándalo, efecto semanal al nombrar).
- Propuesta que **requiere `data/`** (hoy congelado): por candidato, una frase característica, una mini biografía satírica y un retrato (arte con IA o ilustración). Son 75 candidatos (25 ministerios × 3). Costo: texto 75 × 2 líneas (barato, con revisión de tono y sin personas reales: son alias satíricos), arte 75 retratos (medio; licencias del arte con IA pendientes, `LICENCIAS.md`). Cambia la huella y los oros, y debe entrar antes de repartir la prueba cerrada.
- Recomendación: textos sí (bajo costo, alto efecto), retratos solo si se resuelven las licencias; decidir antes de la prueba cerrada.

## D23 y D24. Elección con población: ruido regional y Congreso por geografía (27-nov-2026)
- **D23:** componente aleatorio por región en la elección presidencial (`ruido_regional` en `data/leyes.json`). Hoy no existe y `data/` está congelado; añadirlo cambia el balance y los oros. Recomendación: no, hasta ver datos de personas (el voto por región ya se muestra sin él).
- **D24:** Cámara y Senado por geografía (155 diputados por distritos de población, 50 senadores por región; `docs/ELECCION_POBLACION.md`). Es una mecánica nueva. Recomendación: esperar a la prueba cerrada.

## D25. Proyectos de transporte de la RM y Aysén en el panel SECTRA (27-nov-2026)
- Investigación y propuesta en `docs/PROPUESTA_SECTRA_RM_AYSEN.md` (no se tocó `data/`). Resumen: Aysén sí tiene 7 proyectos en la página de SECTRA (hueco de la descarga); la RM no publica y habría que usar EFE/MTT/MOP/Metro (Metro da 403).
- Decisión del usuario: autorizar o no descongelar `data/sectra_planes.json`. Recomendación: cargar solo lo leído en fuente oficial con unidad explícita, antes de la prueba cerrada; si no, dejar el mensaje «sin proyectos publicados».
