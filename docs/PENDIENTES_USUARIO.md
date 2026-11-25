# Pendientes (actualizado el 24-nov-2026)

Este archivo lo mantiene Claude. Lo que depende del usuario queda en «Necesito del usuario» y **no detiene** el trabajo: se sigue con la sección «Para hacer yo».

## Necesito del usuario (no bloquea nada de lo demás)
| # | Qué | Por qué lo necesito | Estado |
|---|---|---|---|
| U1 | Probar el APK en el teléfono: fps, RAM, toques (zoom, arrastre y pulsación larga del mapa), teclado en los campos de nombre | Es lo único que no se puede medir aquí (hitos de las fases 1 y 2) | Pendiente |
| U2 | Decidir el tamaño del gabinete (PR-04, opciones A, B o C) | Cambia el tutorial, el balance y las cartas habilitadas | Pendiente |
| U3 | Decidir si quien no promete nada en campaña recibe legado completo y si una ley de 7 días debe resolverse en 1 cierre o en 2 | Reglas de diseño (hoy: legado completo y 2 cierres) | Pendiente |
| U4 | Revisión legal por un abogado chileno: alias satíricos de políticos reales, nombres de partidos, imágenes y textos, aviso de ficción | Mayor riesgo de bloqueo para publicar (informe de mercado) | Pendiente |
| U5 | Confirmar con Metro S.A. (metro.cl bloquea consultas automáticas): colores oficiales de L7, L8 y L9 y nombres definitivos de sus estaciones | Hoy salen de OSM y Wikipedia/Wikidata, sin confirmar | Pendiente |
| U6 | Licencias de uso comercial del arte: Gemini, Canva, Figma, Copernicus/OSM (atribuciones) | No se publica arte sin licencia confirmada | Pendiente |
| U7 | Generar en Gemini las 13 categorías y la portada vertical cuando renueve el cupo (prompts en `docs/ARTE_PROMPTS.md`) | Estilo mezclado entre el arte antiguo y el nuevo | Pendiente (cupo) |
| U8 | `main` ya existe (creada el 24-nov-2026 con todo el trabajo); falta ponerla como rama por defecto en GitHub (Settings → Branches) y decidir si se protege | Desde aquí no puedo cambiar ajustes del repositorio | Pendiente |
| U9 | Elegir modelo de monetización (premium barato, anuncios recompensados, packs de escenarios) | Condiciona qué datos se recolectan (Ley 21.719) y la ficha de Play | Pendiente |
| U10 | Google Play, prueba cerrada con 12+ testers y keystore de release | En pausa por instrucción del usuario | Pausado |

## Para hacer yo (actualizado tras tu «hazlo todo»)
Hecho el 24-nov-2026: fuzzing en CI, mapa de Chile con caché, reglas de disponibilidad en un solo lugar, títulos cortos (P11), cartera con buscador, PR-01 (dificultad, afiliación, «como la última vez»), PR-05 (rellenar gabinete), PR-06c (continente y vecinos vivos), consecuencias visibles por carta, finales variados (9 epílogos) y hitos del mandato en la pantalla de fin. El tutorial ya es corto (5 pasos).
En curso, en este orden: PR-09 estadísticas de cartas → PR-08 ministros con peticiones → PR-02 arrastrar cartas al mapa → PR-07 eventos externos → PR-11/12/13 cierre, reelección y oposición → PR-14 → PR-17 balas de plata → PR-18 presupuesto → PR-19 a PR-23 → PR-24 marco de actores. PR-10 (campaña narrativa), PR-15 y PR-16 (apariencia y habilidades) después. Medición D1/D7 espera tu decisión U9.

## PR-01 Dificultad (implementada con valores por defecto, ajustable)
- Fuente: `docs/PROPUESTAS.md` PR-01; presets en `data/leyes.json` bloque `dificultad` (umbral_delta, aprobacion_inicial, desgaste). Selector en la pantalla de fundación del partido; se guarda en `partido["dificultad"]` y se reproduce.
- Calibración vs bot codicioso (24 semillas, elección ganada): fácil 24, normal 18, difícil 12 (`tests/test_dificultad.gd`). Un humano suele ser peor que el bot: confirmar con prueba real (U1).
- Pendiente de decidir (usuario): beneficio de jugar "independiente" y afiliación a partido existente (siguiente paso de PR-01).
- Mapa de Chile: geometría triangulada una sola vez por ejecución (cache estática en MapaChile); resuelto.
- Balance fuera del código: fórmulas de indicadores iniciales del partido movidas a data/ideologia.json (bloque inicio). PR-05 sigue esperando tu «hazlo» (y la decisión U2).

## PR-01 Afiliación (implementada con valores por defecto, ajustable en `data/leyes.json` bloque `afiliacion`)
- Tres caminos: fundar partido propio (flujo anterior), candidatura independiente (+4 aprobación, bancada ×0,6, mínimo 4) o entrar a un partido ficticio (hereda ideología desplazada por 3 posturas, bancada = escaños del Senado ×2, cohesión +5; ese partido deja de ser aliado). `test_afiliacion.gd`.
- Falta decidir (usuario): si el partido existente debe «pedir poder y castigar» (mecánica nueva, no implementada), el beneficio definitivo del independiente, y balance 3×3 con bots por afiliación (hoy solo la dificultad está calibrada). «Continuar como la última vez»: hecho (botón «Nueva partida como la última vez» en el menú; guarda el último partido fundado en user://ultima_config.json).
- Interfaz: ya no muestra conteos ni números de página internos (cartera, gabinete, SECTRA) ni el número de boletín.

## PR-05 Rellenar el gabinete (hecho el 24-nov-2026 tras tu «hazlo»)
- Botones «Equilibrado» y «Máxima eficacia» en la pantalla de gabinete: completan solo los vacíos, nunca pisan lo escogido, explican el porqué y se pueden deshacer. Pesos en `data/leyes.json` → `gabinete.relleno`. Prueba en `test_gabinete.gd`.
- Pendiente: que «Máxima eficacia» cueste capital político o cohesión (hoy solo cambia el criterio), y los candidatos recreados desde personas reales (solo con alias/sobrenombre y tras revisión legal; ver PR-05b): no se implementó porque requiere investigación de fuentes y revisión de un abogado (U4).

## PR-06c Mapa del continente (primera etapa hecha el 24-nov-2026 tras tu «hazlo»)
- Hecho: botón «Continente» en la pantalla Nación: Sudamérica en 2D (Natural Earth 1:50m, dominio público, `tools/geo/sudamerica.py` → `data/geo/sudamerica.json`, 19 KB), países coloreados por relación con Chile (`data/vecinos.json`, cifras ilustrativas) y tres potencias como íconos (EE. UU., China, UE). Toca un país para ver su relación. Malvinas no se dibuja; aviso «mapa ilustrativo»; fuente y crédito registrados.
- Pendiente (requiere balance y tu confirmación de las dos recomendaciones): vecinos «vivos» (crisis y elecciones propias con contagio a Chile, con semilla), cartas de política exterior arrastradas sobre un país, líneas/pines de proyectos internacionales, 2,5D (relieve y paralaje). Tocar el motor cambia los hashes de oro y exige recalibrar; por eso va como etapa aparte.
- Revisión legal (U4): fronteras y reclamos del mapa.

## PR-06c segunda etapa: vecinos «vivos» (hecha el 24-nov-2026)
- 8 eventos de vecinos (crisis cambiaria y acuerdo energético con Argentina, tensión por el gas con Bolivia, elecciones en Perú, migración desde Venezuela, auge comercial con Brasil, cumbre del Pacífico con Colombia, acuerdo con Uruguay) en `data/eventos.json` con campos `pais` y `relacion_delta`; salen por el sorteo con semilla y afectan a Chile con la misma maquinaria de eventos. La relación que muestra el mapa del continente = base + eventos ocurridos en tu partida (`MotorEventos.relacion_exterior`, sin estado nuevo). Los negativos pesan menos (balance: crisis del bot activo 6,7 %).
- Los hashes de las pruebas de oro cambiaron a propósito (nuevos eventos en el sorteo).
- Sigue pendiente: cartas de política exterior arrastradas a un país, pines de proyectos internacionales y 2,5D; las elecciones propias de cada vecino con ventana fija.

## Ideas del análisis de mercado (autorizadas con tu «todo quiero todo»)
- Consecuencia visible por carta: HECHO. Al jugar una carta el aviso muestra lo que cambió («Aprob. +2 · Capital −3»). `Barras.resumen_cambios`.
- Siguientes (en este orden, una por ciclo): resumen de sesión con hitos, finales variados, tutorial corto, medición D1/D7 (esta última exige tu decisión de monetización/datos, U9, y la Ley 21.719).

## PR-09 Estadísticas de las cartas (primera etapa, 24-nov-2026)
- Hecho: el panel de detalle de la carta muestra su impacto (pequeño, mediano o grande; umbrales en `data/leyes.json` → `impacto_carta`) y si pasa por el Congreso (`FichaCarta`).
- Pendiente (más grande, requiere rebalancear con bots): efectos diferenciados por sector y tipo de carta, efectos a futuro («sube cohesión hoy, baja fiscal en 8 semanas»), texto de sabor por carta. Las 1.685 cartas reales se generan por plantilla; cambiar la plantilla en `tools/` y regenerar es el camino.

## PR-07 y PR-08: eventos con decisión (primera etapa, 25-nov-2026)
- Hecho: mecánica de eventos con opciones (`opciones` en `data/eventos.json`): el jugador elige entre 2-3 respuestas sin gastar movimientos; los efectos dependen de la respuesta; queda registrado (entrada `decision`, `estado.decisiones`) y se reproduce. 4 eventos externos (terremoto, caída del cobre, incendios, paro de camioneros) y 6 peticiones de ministerios clave (Hacienda, Salud, Educación, Seguridad, Obras, Energía). Si no respondes, el evento no aplica efectos. `test_decisiones.gd`. Los hashes de oro cambiaron a propósito.
- Pendiente: cadenas (una decisión desencadena algo 3-6 semanas después), crisis con cuenta regresiva, ventanas de oportunidad, retratos de ministros (arte), eventos propios de los otros 19 ministerios, mostrar al jugador qué ministro pide. Cada una necesita estado nuevo y rebalanceo con bots.

## PR-02 Arrastrar cartas (primera etapa, 25-nov-2026)
- Hecho: deslizar la carta elegida hacia arriba (≥ 70 px, más vertical que horizontal) desde la mano la juega; tocar «Jugar» sigue funcionando como respaldo. Si una capa (evento, tutorial) tapa la mano, el gesto no cuenta. Prueba en `test_ui_humo.gd`.
- NO hecho a propósito (contradice reglas congeladas hasta que lo confirmes): mover el botón de avanzar al centro y dejar vacía la esquina derecha (CLAUDE.md §5: botón principal siempre en la misma posición), soltar sobre una región del mapa para elegirla, soltar sobre el ícono de delegar, confirmación al terminar la semana con movimientos sin usar, sonido y vibración (no hay sonido en el juego; faltan efectos CC0). Decisiones (a)–(d) de PR-02 siguen abiertas.
