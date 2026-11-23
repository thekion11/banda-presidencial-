# Revisión externa — Seguimiento 3 (rama `revision/auditoria`, integrada con `ccr-ec102a3c-giitie` @ d109fe9)

Al integrar la rama principal comprobé qué de la Auditoría 2 ya estaba corregido por otras sesiones y corregí lo que faltaba (solo cambios pequeños en `game/`; pruebas ejecutadas con Godot 4.3 tras los cambios: UI humo, grafo, oro completa, guardado y balance en verde; `check_limits` OK).

| Hallazgo | Estado | Evidencia |
|---|---|---|
| C1 quórums | **Resuelto** por la rama principal | `leyes.json › tipos_ley` ahora tiene `regla` (`mayoria` / `fraccion` 4/7 / `ninguna`) con base presentes/en ejercicio. Corrección a mi propia Auditoría 1: que ley simple, QC y LOC compartan 26/78 con asistencia plena **no era un error por sí mismo** (la diferencia real es «presentes» vs «en ejercicio»); el defecto era no modelar esa base. Sigue `verificado:false` en LOC y reforma: confirmar contra BCN. |
| N1 huella por guardado | **Resuelto** | `game/main.gd:17` la calcula una vez (`_huella_datos`). |
| N2 títulos truncados/duplicados | **Resuelto** | 0 de 1.276 con «…» y 0 duplicados (generador con `recortar` y `unico`). |
| N7 réplicas de partidos | **Mitigado** | `data/partidos` excluido del paquete; coalición mínima sin `real_ref`. Falta revisión legal. |
| N9 CLAUDE.md | **Resuelto** | §4 describe movimientos, gabinete de 8 y los tests v2. |
| M2 targets táctiles | **Corregido** (la rama principal lo hizo en paralelo, d241d9e, con prueba que lo exige) | Botones 2D/3D y sliders del Comité a 44 px. Insignia (36) y badge (32) son decorativos, no botones: se dejan. |
| Fuente de 9 pt | **Corregido aquí** | `urbano_base.gd:165-177`: rótulos de lugares del mapa a 10 pt (mínimo de CLAUDE.md) y caja de colisión 12 → 13 px. |
| N3 cartas con efectos genéricos | **Abierto** | Requiere decisión de diseño (curar efectos por materia o reducir el número de cartas): no se cambia balance sin acuerdo. |
| N4 anacronismo de estado | **Abierto** | Requiere decidir si se congela el estado a la fecha de inicio. |
| N5 `verificado` vs `cifras_ilustrativas` | **Abierto** | Un validador estricto fallaría hoy con 1.206 cartas; hay que redefinir el campo antes. |
| N8 14 eventos sin verificar | **Abierto** | Servel/BCN/Senado no accesibles desde mi entorno (401/403). |
| N11 capturas v2 | **Abierto** | Regenerar con `captura_comparar.gd` bajo xvfb (no disponible aquí). |
| A1 AAB/Godot 4.3 | **Abierto** | `export_presets.cfg:21` `use_gradle_build=false`; subir a Godot ≥ 4.5 exige plantilla Gradle y probar la exportación: no se toca sin poder compilar el APK. |
| A4–A6 licencias | **Abierto** | Son decisiones/solicitudes a terceros (ODbL, Figma/Canva IA, SECTRA). |

---

# Revisión externa — Auditoría 2 (rama `ccr-ec102a3c-giitie` @ 366f162)

Alcance: integra `datos/*`, `feat/mecanicas-v2`, `feat/ui-v2`, 1.276 cartas por proyecto, eventos reales, 2ª vuelta, guardado versionado.
**Esta vez sí ejecuté las pruebas:** Godot 4.3-stable (descargado de GitHub) en un worktree aparte, sin tocar `sim/`, `game/` ni `data/`. Resultado: `validate_data.py` OK, `check_limits.py` OK; pruebas de oro (4 sem., 30 d, completa), enmienda, congreso, guardado, gabinete, delegación, movimientos, coalición, equipo, sectra, grafo, balance y UI humo: **todas pasan**. `test_presupuesto` solo imprime errores del renderizador *dummy* (mesh null) en headless: no es un fallo de la prueba, pero no valida nada de GPU. Monte Carlo (n=60): pasivo 5 % gana / 0 % completa; azar 25 % / 21,7 %; codicioso 81,7 % / 81,7 % (aprob. final media 43,1; 0 % crisis); codicioso>pasivo 81,7 % cae en crisis.
Sigo sin poder leer la BCN (401 por el proxy): lo legal sigue «verificar contra texto oficial».

## Estado de los hallazgos de la Auditoría 1
| Id | Estado | Detalle |
|---|---|---|
| C1 quórums | **Parcial** | Se añadieron `ley_organica_constitucional` (26/78) y `reforma_constitucional` (29/89 = 4/7 de 50 y 155 ✓), ambas con `verificado:false`. **Siguen sin resolverse:** `ley_simple` y `quorum_calificado` tienen aún exactamente 26/78 (`data/leyes.json › tipos_ley`), y la LOC tiene los mismos umbrales que la ley simple: solo cambian las probabilidades de TC, no la exigencia de votos. No existe base «presentes» vs «en ejercicio»; `motor_legal.votar` compara contra mínimos fijos. 0 de 1.044 proyectos de ley usan quórum calificado (897 ley simple, 111 reforma, 38 LOC), aunque muchos contienen normas de QC. |
| C2 guardado | **Resuelto en lo esencial** | `exportar_guardado` v2 con `huella_datos` (SHA‑256 de 12 conjuntos de datos, `Datos.huella`); `main.gd:76` descarta guardados con huella distinta y `test_guardado` pasa. Quedan: ver A‑N1 (coste de la huella) y que el RNG sigue siendo único (cualquier cambio de datos invalida igualmente la partida, ahora con aviso). |
| C3 calendario | **Resuelto en lo esencial** | `leyes.json › calendario`: campaña 21‑sep‑2025, 1ª vuelta 16‑nov, 2ª vuelta 14‑dic, mandato 11‑mar‑2026; 8 sem. de campaña = 56 d exactos hasta la 1ª vuelta ✓; balotaje de 4 sem. ✓ (`motor_mandato.resolver_eleccion`). La UI muestra fecha real (día 36 = 15‑abr‑2026 ✓). Pendientes: la transición dic‑2025→mar‑2026 (12 sem.) no se juega (documentado); la elección sigue siendo `aprobación ± 2 ≥ 51` (umbral 51 y piso de balotaje 38 son arbitrarios, sin rivales); `calendario.nota` debe quedar en Créditos. |
| A1 AAB/Godot | **Abierto** | `export_presets.cfg:21` sigue `use_gradle_build=false`; workflows siguen en Godot 4.3. |
| A2/A3 rendimiento | **Medido en escritorio, sin teléfono** | Carga de datos 95 ms y 47 MB estáticos (62 MB tras una partida); partida completa 249 ms; replay 86 ms (50 entradas). Ver A‑N1. |
| A4–A6 licencias | **Abierto** | Sin `LICENCIA.md` ODbL, sin respuesta de SECTRA, IA sin confirmar. |
| M1 pantalla_dia 450 líneas | **Resuelto** (426) | |
| M2 targets táctiles | **Abierto** | Siguen `Vector2(36,36)` en `barras.gd:20`, `pantalla_urbano.gd:126`, 32 px en `pantalla_partido.gd:121`; texto de 9 pt en `urbano_base.gd:165` (< 10 pt de CLAUDE.md). |
| M9 SECTRA sin id | **Abierto** | |

## NUEVOS — ALTO
**N1. `huella` se recalcula en cada guardado.** `game/main.gd:112` llama `Datos.huella(datos)` dentro de `guardar()`, que se ejecuta en cada acción (`accion_hecha.connect(guardar)`, `main.gd:82`). Serializa ~1,7 MB de cartas + resto con `JSON.stringify` y SHA‑256: **171 ms en escritorio** (medido); en un gama baja es del orden de 1 s por jugada. Propuesta: calcular una vez en `_ready` y guardarla en una variable (los datos son inmutables en ejecución).
**N2. 1.101 de 1.276 cartas reales tienen el título truncado con «…»** (p. ej. «Modifica diversos cuerpos legales, con el objeto de crear…»), 39 títulos duplicados (incl. «Plan de Inversiones Oncológicas 2026‑2030…» y «Acelerar: Plan…»). El título completo está en `meta.titulo_completo`. Con 1.044 cartas indistinguibles el jugador no puede decidir. Propuesta: título corto curado por categoría+materia (≤ 40 car.) o mostrar `titulo_completo` en detalle; deduplicar con sufijo (boletín).
**N3. Cartas de proyectos de ley casi sin diferenciación mecánica.** Las 1.044 cartas de boletines reciben ~10 plantillas de efectos por categoría (p. ej. `[+4 aprob., −0,8 cohesión, −1 capital]` en 104 cartas; `[+1,5 capital, +0,8 cohesión]` en 95). Efectos no derivados de contenido: es «relleno». Además 23 son «nacionalidad por especial gracia» y similares (sin sentido político para un presidente). Propuesta: filtrar por materia relevante (iniciativa del Ejecutivo/mensaje, urgencia ≠ «Sin urgencia») y bajar el número a ~150 con efectos curados; el resto como «fondo» no jugable.
**N4. Anacronismo de datos.** El juego parte en sep/nov‑2025 pero las cartas/proyectos muestran estado «al 23‑nov‑2026» (`meta.fecha_corte` y `estado_real: En tramitación` en 1.044 de 1.044; muchos boletines de 2022). El Senado devuelve el estado actual, no el de 2025. Un proyecto que ya es ley en 2026 aparece como «en tramitación». Propuesta: etiquetar `estado_a_fecha_de_inicio` o excluir los que cambiaron de estado tras 11‑mar‑2026; no mezclar «hoy» con la línea temporal del juego.
**N5. Indicadores contradictorios de veracidad.** Las 1.276 cartas llevan `cifras_ilustrativas: true`, y 1.206 `verificado: true` a la vez; las fuentes de las 230 obras (`mop_concesiones`, `mop_obras`, `efe_proyectos`, `metro_santiago`, `minsal_inversiones`, `planes_prensa_2026`, `wikipedia_es`) están en `verificado_contra_texto:false` (el validador solo avisa). No puedo confirmar contra los sitios oficiales (varios dan 403/401 desde este entorno). Propuesta: definir `verificado` = «URL consultada y cifra coincide» con fecha y método; el validador debe **fallar** si una carta `verificado:true` apunta a una fuente no verificada.
**N6. Cobertura: ~21 % del catálogo no aparece en 40 partidas.** Con el bot codicioso (40 semillas, 30 llegan al gobierno, 6.210 turnos de gobierno) se ven 1.062 de 1.343 cartas distintas. Algunas están bloqueadas por `disponibilidad` (evento/meta/fiscal). Propuesta: informe de alcanzabilidad por carta en CI (ninguna carta debe ser inalcanzable).

## NUEVOS — MEDIO
- **N7. Réplicas de partidos = disfraz 1:1.** `partidos_juego.json` mapea 15 partidos reales con `real_ref` y `justificacion` que cita votos y declaraciones reales (viaja en el APK). Riesgo de honra/marca y de política de Play («Impersonation»), ya reconocido en `docs/PARTIDOS.md`; la mitigación (réplicas) queda debilitada si el texto de justificación identifica al partido real. Propuesta: separar `justificacion`/`real_ref` a un archivo solo de herramientas (no empaquetado) y exigir revisión legal antes de publicar. Las cifras de escaños salen de Wikipedia (`verificado:false`).
- **N8. Eventos reales hasta 23‑nov‑2026:** 97 eventos, 14 `verificado:false` (p. ej. 16‑nov‑2025 y 14‑dic‑2025: **las dos elecciones** y 11‑mar‑2026 aparecen sin verificar; también 4‑sep‑2022 y 17‑dic‑2023). No puedo comprobarlos aquí (Servel/BCN inaccesibles o no consultados). Los efectos en el juego son arbitrarios (+1 capital por «se publica la Ley N° 21.770», `evt_real_20250929_037`). Propuesta: efectos solo en eventos con consecuencia mecánica real; verificar los 14 con Servel/DO antes de publicar.
- **N9. Doc de reglas desactualizada.** CLAUDE.md §4–5 y la Enmienda hablan de PA y 25 ministros; v2 usa «movimientos» (`mano.pa_por_turno: 5`) y gabinete de 8 (`gabinete.tamano`). `docs/DISENO_V2.md` los reemplaza pero CLAUDE.md solo recibió 6 líneas. Alinear: «5 movimientos» y gabinete 8/25, o `leyes.json › mano.pa_por_turno` renombrado a `movimientos`.
- **N10. Tamaño y memoria: bien.** `data/` 8,3 MB (cartas_reales 1,7 MB), `data/geo` 3,7 MB; APK debug ≈ 30 MB + ~4 MB de datos nuevos ≪ 150 MB; RAM estática 47–62 MB en escritorio, ≪ 800 MB. Riesgo real: parseo en hilo principal al arrancar (95 ms escritorio ⇒ ~0,5–1 s en gama baja) y `JSON.stringify` de N1.
- **N11. Captura v2 desactualizada.** `docs/comparacion/v2_coalicion_cuotas.png` muestra «Partido Horizonte Cívico (HC)», pero los datos dicen «Movimiento Horizonte Común (MHC)»: regenerar capturas tras el merge de partidos. En `v2_dia_movimientos.png` las cartas de la mano se solapan y el título se corta («Cadena nac…», «Alimentación escolar reforzada» a 10 pt); la zona del botón «Jugar · 2 mov» es ≥ 44 px ✓, el mapa ocupa ≈ 36 % ✓ (justo sobre el mínimo de un tercio).
- **N12. Replay en móvil.** Replay de 50 entradas = 86 ms; una partida de 216 turnos tendrá ~4× más entradas: estimar 0,5–2 s en gama baja. Añadir snapshot cada N turnos (ver A3 de la Auditoría 1).

## NUEVOS — BAJO
- `Datos.huella` no incluye `partidos_juego.json` ni `eventos_reales` (solo la mezcla ya cargada): si cambian los partidos, el guardado no se invalida (verificar si afecta a la simulación vía `coalicion`, que sí está).
- `reales_en_mazo: 15` (leyes.json › mano) con 1.276 cartas: documentar la lógica de muestreo (por categoría/disponibilidad) en DISENO_V2.
- `test_ui_humo` termina con 72 RIDs de `CanvasItem` filtrados y un recurso en uso (WARNING/ERROR de limpieza): no falla, pero esconde fugas reales; investigar.
- El validador sigue sin romper con `verificado_contra_texto:false` (solo `[AVISO]`): decidir un modo `--estricto` para CI de release.

## Próximo paso recomendado (orden)
1. N1 (trivial, evita jank), 2. C1 (modelar «presentes/en ejercicio» y diferenciar ley simple/QC/LOC), 3. N2–N4 (calidad de cartas), 4. A1 (AAB/Godot ≥ 4.5), 5. licencias A4–A6 y N7, 6. verificar los 14 eventos y las fuentes de las 230 obras con acceso a Servel/BCN.

---

# Revisión externa (auditoría 1) — rama `ccr-ec102a3c-giitie` @ e40d808

Revisor: tercera sesión, solo lectura del código. Fecha de contexto: 23 nov 2026.
**Limitaciones de esta pasada:** no hay `godot` en el entorno de revisión, por lo que **no ejecuté** las pruebas de Godot (solo `validate_data.py` y `check_limits.py`: ambos OK). La BCN (`bcn.cl`, `leychile.cl`) devuelve 401 por el proxy: **no pude verificar artículos contra el texto oficial**; lo marcado «verificar» queda pendiente. Las ramas `datos/proyectos-publicos` y `datos/leyes-eventos` **aún no existen en origin** (solo `ccr-ec102a3c-giitie` y esta); se auditarán cuando aparezcan.

## Resumen
El núcleo es sólido en estructura (capas, límites de líneas, RNG único con semilla, `sim/` sin nodos). Los riesgos reales están en: (1) exactitud legal de quórums, (2) guardado por eventos frágil ante cualquier cambio de datos, (3) calendario/campaña desalineados con el nuevo marco real (16‑nov‑2025 → 11‑mar‑2026), (4) publicación en Play (AAB, API objetivo, 16 KB), (5) licencias (ODbL derivada, IA, SECTRA, GeoJSON).

## CRÍTICO
**C1. Quórums legales incorrectos / incompletos** — `data/leyes.json` (`tipos_ley`, ~líneas 95‑135).
- `ley_simple` y `quorum_calificado` tienen **idénticos** umbrales (26 senadores / 78 diputados). Es imposible que ambos sean correctos. La ley simple se aprueba por mayoría de **presentes**, no de en ejercicio; modelarla con 26/78 fijos la hace más difícil de lo real y elimina el efecto de las abstenciones.
- Faltan tipos: **LOC** y **reforma constitucional**. Real: reforma constitucional = **4/7 de los en ejercicio** (Ley 21.481, DO 23‑ago‑2022; 4/7 de 155 = 89 diputados, de 50 = 29 senadores). LOC: la Cámara informa reforma que baja de 4/7 a **mayoría absoluta de en ejercicio** (78 / 26); confirmar promulgación y número en BCN. Quórum calificado: verificar si es «presentes» o «en ejercicio» en el texto vigente.
- Los artículos citados (`Art. 66 inc. 3/4`) deben re‑verificarse tras las reformas 2022‑23; `fuentes.json#cpr_chile_2026` sigue `verificado_contra_texto:false`.
- Propuesta: añadir `base_quorum: "presentes"|"en_ejercicio"`, fracción (`0.5+`, `4/7`) y calcular el mínimo en `MotorLegal.votar` (`sim/motor_legal.gd:~21`) con las abstenciones ya modeladas; tipos `loc`, `reforma_constitucional`; test de oro con 89/29 y 78/26.

**C2. El guardado por eventos se rompe con cualquier cambio de datos** — `sim/estado_simulacion.gd` (`exportar_guardado`, `"version": 1`), `sim/partida.gd:reproducir`.
El estado depende de un único `RandomNumberGenerator` consumido por: barajado del mazo (`motor_turno.gd:139`), un `randf` por **cada** evento aleatorio y semana (`motor_eventos.gd:27`), votos, TC, escándalos y retrasos. Añadir una carta, evento o proyecto de ley (justo lo que va a hacer la ampliación masiva) cambia el flujo y **toda partida guardada se reproduce distinta**, sin aviso. Propuesta: guardar `hash_datos` (sha256 de los JSON usados) + `version_motor`; al cargar, si no coincide, ofrecer partida nueva o migración; mejor aún, RNG por subsistema (`seed ^ hash("eventos")`, etc.) para aislar. Añadir test: dos conjuntos de datos distintos ⇒ el guardado antiguo se rechaza.

**C3. Calendario y campaña no corresponden al nuevo marco** — `data/leyes.json › calendario` (`2029‑09‑17` / `2030‑03‑11`), `hemiciclo.semanas_campana: 8`, `umbral_victoria_presidencial: 50` aplicado a la *aprobación*.
Real: 1ª vuelta 16‑nov‑2025, 2ª vuelta 14‑dic‑2025 (4 sem.), investidura 11‑mar‑2026 (12 sem. después) = **16 semanas** (115 días). La elección actual es una sola tirada `aprobación ± ruido ≥ 50` (`motor_turno.gd:174`): no hay segunda vuelta ni candidatos rivales (ya admitido en `AUDITORIA_VIDA_REAL.md`). Con el alcance ampliado hay que decidir: campaña 4 semanas + balotaje + 12 de transición (¿qué se juega en la transición? gabinete, empalme, ley de presupuestos prorrogada), o mantener 8 y declarar la desviación. Ojo: hoy `fecha_inicio_mandato` 2030 contradice la fecha del enunciado; los eventos programados usan `dia_objetivo` relativo (28, 36, 82, 204 …) y las fechas de Cuenta Pública (1‑jun) y Presupuestos (≈30‑nov) deben recalcularse desde el 11‑mar‑2026 (día 82 y ≈265).

## ALTO
**A1. Publicación en Google Play bloqueada por la configuración de exportación** — `export_presets.cfg:21` `gradle_build/use_gradle_build=false`: sin build Gradle **no se genera AAB**, y Play exige AAB. Además el workflow fija Godot 4.3 (`android.yml`, `ci.yml`): su plantilla apunta a API 34 y no cubre el requisito de **16 KB page size** (Android 15+, noviembre 2025) ni la API objetivo vigente (35+/36; `docs/ANDROID.md` ya dice «verificar»). Propuesta: subir a Godot ≥ 4.5 (verificar soporte 16 KB), `use_gradle_build=true`, `target_sdk` explícito, CI que produzca `.aab` firmado en release. Hasta entonces la Fase 1 no puede cerrarse.
**A2. Rendimiento Android sin medir y con riesgos evidentes.** 83.574 edificios (`edificios_santiago.bin`, 0,67 MB) + `urbano_real.json` (1 MB) + `grafo_urbano.json` (0,57 MB) parseados con `JSON.parse_string` en el hilo principal; dibujo vía `_draw`/`queue_redraw` (CPU 2D) en `urbano_base.gd`/`comite_mapa_3d.gd`. Estático «< 800 MB» en headless no prueba 30 fps. Propuesta: carga diferida y en hilo, caché binaria (`var_to_bytes`) del grafo, LOD/submuestreo ya existente documentado con presupuesto en ms, y medición real en un gama baja (p. ej. 3 GB RAM) con `Performance.get_monitor`. Si se añaden miles de proyectos, **no cargarlos todos al arranque** (ver D2).
**A3. Reproducir una partida completa al «Continuar»** (`main.gd:65`, `Partida.reproducir`): re‑simula hasta 216 turnos; con eventos/cartas masivos el arranque en Android puede tardar segundos. Propuesta: guardar además un *snapshot* del estado cada N turnos (verificado con `calcular_huella`) y reproducir solo el tramo restante.
**A4. Licencia ODbL (OSM).** `urbano_real.json`, `grafo_urbano.json`, `edificios_santiago.bin` son **bases de datos derivadas** distribuidas dentro del APK: ODbL exige atribución y ofrecer la base derivada bajo ODbL (share‑alike) — no basta con el crédito en pantalla. Propuesta: publicar esos archivos y `tools/geo/` en el repo con licencia ODbL explícita en `data/geo/LICENCIA.md` y enlace en la ficha. El relieve (AWS Terrain Tiles) también exige atribuir sus fuentes (SRTM/NED/GMTED, etc.): añadirlas a Créditos.
**A5. Contenido generado con IA.** Ilustraciones de cartas con el generador de Figma: confirmar por escrito los derechos de uso comercial y declarar IA en Play. Sin pruebas de ausencia de parecido con terceros ni de la bandera/emblemas (la bandera es de uso libre, pero el escudo nacional tiene regulación).
**A6. Datos SECTRA (`data/sectra_planes.json`)**: extraídos del sitio por API WordPress; no hay licencia de reutilización citada. Propuesta: solicitar autorización/confirmar condiciones (Ley 20.285 / portal de datos abiertos) y guardar la respuesta en `docs/`.

## MEDIO
- **M1. `pantalla_dia.gd` tiene exactamente 450 líneas** (`wc`), al borde del tope de CLAUDE.md; cualquier cambio lo rompe. Partir ya (p. ej. barra de mano/overlays).
- **M2. Zonas táctiles < 44 px**: `panel_comite.gd:53‑54` (44×36), `:137` (sliders 32), `barras.gd:20` (36×36), `barras.gd:39` (32), `pantalla_urbano.gd:126` (36×36), `pantalla_partido.gd:121` (32×32). Texto 11 pt en corrector (`pantalla_dia.gd:118`) cerca del mínimo 10. Si son decorativos, documentarlo; si son botones, subir a ≥44 (el área táctil puede ser mayor que el dibujo).
- **M3. Prueba de balance débil**: `test_balance.gd` usa 60 partidas por política y umbrales amplios; no cubre el gobierno ni la distribución de puntaje. Añadir métricas (aprobación media por año, % de crisis por política, % de leyes aprobadas) y subir `n` en CI nocturno.
- **M4. Legal simplificado vs. realismo ampliado**: sin veto, urgencias, comisión mixta, Contraloría, acusación constitucional ni estados de excepción (listado en `AUDITORIA_VIDA_REAL.md`). Para «leyes de la BCN como límites legales» se necesita un campo `base_legal` (id BCN, artículo, fecha de vigencia) por carta, validado, y un paso de validación que lea ese campo en lugar de `requisitos.ley` genérico.
- **M5. Población 2017**: coincide con el Censo 2017 (RM 7.112 mil, Valparaíso 1.815 mil; suma 17.565 mil vs 17.574 mil oficiales: redondeo), pero existe Censo 2024; actualizar o rotular claramente.
- **M6. Eventos con fuente real escasa**: de 40 eventos, 34 son `ficticio_2026`, 5 `dipres_2026` (ilustrativa) y 1 `cpr_chile_2026` (sin verificar). Para eventos reales (plebiscitos 4‑sep‑2022 y 17‑dic‑2023, elecciones 2025) exigir `fuente` primaria (SERVEL, DO, BCN) + `fecha_corte` + `verificado:true`, y que el validador **falle** (no solo avise) si un evento marcado real no está verificado.
- **M7. Presupuesto modelado como `ley_simple`** (`eventos.json: evt_vota_presupuesto_a*`): en la realidad el Congreso tiene 60 días y, si no despacha, rige el proyecto del Ejecutivo (Art. 67); no hay «rechazo» que castigue de la misma forma. Verificar el texto y modelar el plazo.
- **M8. Riesgo reputacional/legal de políticos reales con alias satíricos**: hoy `ministros.json` usa solo alias (sin nombres reales). Si la ampliación incorpora figuras reales, definir lista, revisión legal (honra, Ley 19.733) y política de Play para contenido político/sátira; no usar imágenes de personas reales.
- **M9. `sectra`**: 27 de 43 «ciudades» tienen `region_id` vacío (las regiones llevan los proyectos); 83 proyectos sin inversión, TIR negativa o 0 en algunos (p. ej. Metro Curauma ‑1,4 %), estados con mayúsculas inconsistentes («Perfil terminado»/«Perfil Terminado»; 15 variantes). Los proyectos **no tienen id propio** (se identifican por región + nombre y hay nombres repetidos, p. ej. «Grecia» en Antofagasta): crear id estable (hash de URL+nombre) antes de que `sectra` entre en los guardados.

## BAJO
- B1. Dos arquitecturas de calendario conviven (`dia_actual` interno y `calendario` en `leyes.json`); centralizar conversión día↔fecha en `sim/`.
- B2. `Datos.cargar_todo` ignora errores (`leer_json` devuelve `null` y el motor falla más tarde): validar tipos al cargar.
- B3. `ci.yml` no ejecuta `montecarlo.gd` ni la captura comparada que exige la Regla de Oro de CLAUDE.md (§1); añadir job manual/nocturno.
- B4. Sin emojis: no encontré incumplimientos obvios en `game/` (búsqueda limitada por el motor de regex; revisar con el validador de glifos).
- B5. `docs/ESTADO_FASES.md` marca la Fase 3 «Cerrada en código» y Fase 4 «contenido listo»: las pruebas de teléfono, 12 testers y verificación legal están pendientes; no declarar el hito antes.

## Requisitos de calidad para las ramas de datos (a verificar en la próxima pasada)
1. Cada registro: `id` estable y único, `region_id` ∈ 16 regiones, `fuente` con URL primaria y `fecha_corte`; rechazo en validador si falta.
2. Cifras (montos, plazos, kilómetros) comparables con su fuente: fallar si inversión ≤ 0 o > umbral por tipo; marcar `ilustrativa` lo estimado.
3. Duplicados por (nombre normalizado, región) y por URL.
4. Proyectos de ley/reformas: número de boletín, estado y fecha; leyes: id BCN, artículo, vigencia.
5. Presupuesto de paquete: APK < 150 MB y RAM ≤ 800 MB ⇒ datos masivos en archivos por región, cargados bajo demanda; medir tamaño del `.pck` tras importar.
6. Plebiscitos: 4‑sep‑2022 (Rechazo ≈ 61,9 %) y 17‑dic‑2023 (Rechazo ≈ 55,8 %) deben contrastarse con SERVEL antes de publicar.

## Fuentes consultadas
Reforma 4/7: texto del Art. 127/66 en Wikipedia (Constitución de Chile) y búsqueda sobre Ley 21.481 (Diario Oficial 23‑ago‑2022; Cámara de Diputadas y Diputados, ene‑2023). **No son fuentes primarias**: confirmar en BCN.
