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

## Para hacer yo (en este orden)
1. Fuzzing del núcleo (`tests/fuzz_acciones.gd`, de la rama `ccr-c6aa6dd1-uuqdjm`): integrarlo al CI y corregir lo que encuentre.
2. Pendientes de los informes de revisión: mapa de Chile (rendimiento: la geometría se recalcula al abrir cada pantalla del día); reglas de disponibilidad duplicadas en la interfaz; código muerto de `carta_ui.gd`. (Hecho el 24-nov-2026: hemiciclo con geometría precalculada (capturas idénticas pixel a pixel), ilustraciones a 640×512 (los originales de 1024×820 quedan en `docs/arte_originales/cartas/`; unos 3 MB menos de RAM por ilustración), guardado atómico, aviso por guardado dañado, registro de prueba que solo añade líneas.)
3. Del audit del plan: portada conectada al menú (créditos ya al día); títulos cortos para los eventos legales largos (P11, hecho: descripción ≤120 caracteres, texto completo en meta); estado vacío del informe (P3); cartera con buscador y sin «Fuera de partida» (P2); texto «Tus 8 ministros» desde `leyes.json`.
4. Propuestas ACEPTADAS sin implementar: PR-01 (dificultad y afiliación), PR-05 (rellenar el gabinete), PR-06c (mapa de Sudamérica).
5. Ideas del análisis de mercado (solo proponer y registrar): consecuencias visibles por carta, finales variados, resumen de sesión con hitos, tutorial corto, medición D1 y D7.

## PR-01 Dificultad (implementada con valores por defecto, ajustable)
- Fuente: `docs/PROPUESTAS.md` PR-01; presets en `data/leyes.json` bloque `dificultad` (umbral_delta, aprobacion_inicial, desgaste). Selector en la pantalla de fundación del partido; se guarda en `partido["dificultad"]` y se reproduce.
- Calibración vs bot codicioso (24 semillas, elección ganada): fácil 24, normal 18, difícil 12 (`tests/test_dificultad.gd`). Un humano suele ser peor que el bot: confirmar con prueba real (U1).
- Pendiente de decidir (usuario): beneficio de jugar "independiente" y afiliación a partido existente (siguiente paso de PR-01).
- Mapa de Chile: geometría triangulada una sola vez por ejecución (cache estática en MapaChile); resuelto.
- Balance fuera del código: fórmulas de indicadores iniciales del partido movidas a data/ideologia.json (bloque inicio). PR-05 sigue esperando tu «hazlo» (y la decisión U2).

## PR-01 Afiliación (implementada con valores por defecto, ajustable en `data/leyes.json` bloque `afiliacion`)
- Tres caminos: fundar partido propio (flujo anterior), candidatura independiente (+4 aprobación, bancada ×0,6, mínimo 4) o entrar a un partido ficticio (hereda ideología desplazada por 3 posturas, bancada = escaños del Senado ×2, cohesión +5; ese partido deja de ser aliado). `test_afiliacion.gd`.
- Falta decidir (usuario): si el partido existente debe «pedir poder y castigar» (mecánica nueva, no implementada), el beneficio definitivo del independiente, y balance 3×3 con bots por afiliación (hoy solo la dificultad está calibrada). «Continuar como la última vez» sigue pendiente.
- Interfaz: ya no muestra conteos ni números de página internos (cartera, gabinete, SECTRA) ni el número de boletín.

## PR-05 Rellenar el gabinete (hecho el 24-nov-2026 tras tu «hazlo»)
- Botones «Equilibrado» y «Máxima eficacia» en la pantalla de gabinete: completan solo los vacíos, nunca pisan lo escogido, explican el porqué y se pueden deshacer. Pesos en `data/leyes.json` → `gabinete.relleno`. Prueba en `test_gabinete.gd`.
- Pendiente: que «Máxima eficacia» cueste capital político o cohesión (hoy solo cambia el criterio), y los candidatos recreados desde personas reales (solo con alias/sobrenombre y tras revisión legal; ver PR-05b): no se implementó porque requiere investigación de fuentes y revisión de un abogado (U4).

## PR-06c Mapa del continente (primera etapa hecha el 24-nov-2026 tras tu «hazlo»)
- Hecho: botón «Continente» en la pantalla Nación: Sudamérica en 2D (Natural Earth 1:50m, dominio público, `tools/geo/sudamerica.py` → `data/geo/sudamerica.json`, 19 KB), países coloreados por relación con Chile (`data/vecinos.json`, cifras ilustrativas) y tres potencias como íconos (EE. UU., China, UE). Toca un país para ver su relación. Malvinas no se dibuja; aviso «mapa ilustrativo»; fuente y crédito registrados.
- Pendiente (requiere balance y tu confirmación de las dos recomendaciones): vecinos «vivos» (crisis y elecciones propias con contagio a Chile, con semilla), cartas de política exterior arrastradas sobre un país, líneas/pines de proyectos internacionales, 2,5D (relieve y paralaje). Tocar el motor cambia los hashes de oro y exige recalibrar; por eso va como etapa aparte.
- Revisión legal (U4): fronteras y reclamos del mapa.
