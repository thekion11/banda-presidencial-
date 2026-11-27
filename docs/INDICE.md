# Índice de documentos y orden de lectura (26-nov-2026)

## Para el dueño del proyecto: léelo en este orden
1. **`RESUMEN_DECISIONES.md`**: las decisiones que esperan tu respuesta, con la recomendación de cada una (una página).
2. **`RESUMEN_EXPERIMENTO.md`**: qué hizo cada sesión, qué arregló y qué descubrió.
3. **`PRUEBA_CERRADA.md`** y **`GUIA_PRUEBA.md`**: cómo probar el juego con personas y qué registrar (incluye la propuesta de métricas locales).
4. **`DURACION_SESION.md`**: cuántas sesiones de 20 minutos cuesta un mandato.
5. **`ESTADO_ACTUAL.md`**: foto generada del proyecto (código, pruebas, datos, cobertura, rendimiento, PR abiertos).
6. **`CHANGELOG.md`**: todo lo hecho hoy, por área.
7. **`DECISIONES_PENDIENTES.md`**: la tabla completa (D1 a D16, U4 a U10) con costos de cada opción.
8. **`GUIA_PROBADOR.md`** (para quien prueba) y **`FIRMA_APK_PRUEBA_CERRADA.md`**, **`RIESGOS_PLAY_STORE.md`**, **`LICENCIAS.md`**: lo necesario para publicar.

## Reglas y diseño (referencia)
| Documento | Qué es |
|---|---|
| `../CLAUDE.md` | Reglas obligatorias del proyecto y lista de comandos |
| `DISENO_V2.md` | Especificación de las mecánicas v2 (gabinete, mano continua, movimientos, delegación, asesores, coalición) |
| `PROPUESTAS.md` | Propuestas PR-01 a PR-24 con su estado y las decisiones D-01 a D-03 |
| `TRAZABILIDAD_MECANICAS.md` | Cada mecánica autorizada con su fuente, commit y pruebas |
| `DECISIONES.md` | Bitácora de decisiones y hallazgos, con índice al inicio (secciones A a AZ) |
| `ESTADO_FASES.md` | Historial por fases y estado de cada una |
| `ESTADO_SISTEMAS.md` | Qué hace cada sistema hoy, dónde vive y qué lo prueba |

## Técnica
| Documento | Qué es |
|---|---|
| `CONTRIBUIR.md` | Guía de una página para quien herede el proyecto |
| `ARQUITECTURA_SIM.md` | Mapa de dependencias de `sim/`, tamaño y tiempos de `data/` |
| `API_SIM.md` | Índice de las funciones públicas de `sim/` (generado) |
| `FORMATO_GUARDADO.md` | Formato del guardado, versiones y qué se rompe al cambiar datos |
| `DATOS.md` | Fuentes, licencias y datos por verificar |
| `COBERTURA_GAME.md` | Funciones de `game/` que ninguna prueba ejercita |
| `REVISION_CODIGO.md`, `REVISION_PR8.md` | Revisión de código de `sim/` y revisión cruzada de las pruebas del PR #8 |
| `HIGIENE_REPO.md` | Archivos huérfanos, documentos antiguos y ramas |
| `ANDROID.md` | Cómo compilar para Android |
| `RENDERIZADORES.md` | Vulkan («mobile») frente a OpenGL («gl_compatibility»): qué se pudo medir y qué se recomienda |
| `MEDICION_TELEFONO.md` | Pasos con `adb` para medir fps y RAM en un teléfono real y comprobar el determinismo |

## Balance y calidad
| Documento | Qué es |
|---|---|
| `INFORME_BALANCE.md` | Mediciones de balance con bots, incluida la tabla de 200 partidas por política y dificultad con intervalos de confianza |
| `INFORME_BOTS.md` | Qué hace cada bot y cómo se comparan |
| `ANALISIS_PROFUNDIDAD.md` | Diagnóstico del 25-nov sobre profundidad de las mecánicas |
| `PROPUESTA_EVENTOS_REGIONALES.md` | Propuesta (sin implementar) de 16 eventos regionales con el campo `region` |
| `VERIFICACION_CONSTITUCIONAL.md` | Qué de lo constitucional, electoral y de las fichas se verificó contra fuentes oficiales y qué falta |
| `CUMPLIMIENTO_UI.md` | Cumplimiento de las reglas de interfaz de CLAUDE.md §5 por pantalla (sesión visual) |
| `EQUIDAD_REGIONAL.md` | Cartas, obras y eventos por región frente a su población |
| `REVISION.md` | Auditorías del 23-nov (fotos fechadas) |
| `AUDITORIA_VIDA_REAL.md` | Qué tan fiel es la estructura del juego a Chile real |

## Contenido, arte y publicación
| Documento | Qué es |
|---|---|
| `PARTIDOS.md` | Partidos reales investigados y sus réplicas ficticias |
| `METRO_COMPARACION.md` | Cotejo automático del Metro del mapa con la lista oficial |
| `DIFERENCIAS_MAQUETA.md` | Diferencias entre el juego y la maqueta, y por qué |
| `ARTE_PROMPTS.md` | Instrucciones para generar el arte de las cartas |
| `GOOGLE_PLAY.md`, `POLITICA_PRIVACIDAD.md`, `PROMOCION.md`, `VIDEO_1.md` | Borradores de ficha, privacidad, promoción y video |
| `PENDIENTES_USUARIO.md` | Verificaciones de datos y tareas que solo puede hacer una persona |
| `documento_maestro.pdf`, `enmienda_de_cierre.pdf`, `guia_tecnica_fase_0.pdf` | Documentos originales del proyecto |
