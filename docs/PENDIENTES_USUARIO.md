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
3. Del audit del plan: portada conectada al menú (créditos ya al día); títulos cortos para los eventos legales largos (P11); estado vacío del informe (P3); cartera con buscador y sin «Fuera de partida» (P2); texto «Tus 8 ministros» desde `leyes.json`.
4. Propuestas ACEPTADAS sin implementar: PR-01 (dificultad y afiliación), PR-05 (rellenar el gabinete), PR-06c (mapa de Sudamérica).
5. Ideas del análisis de mercado (solo proponer y registrar): consecuencias visibles por carta, finales variados, resumen de sesión con hitos, tutorial corto, medición D1 y D7.
