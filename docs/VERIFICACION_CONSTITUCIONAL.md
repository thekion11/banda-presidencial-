# Verificación de lo constitucional y legal que usa el juego (27-nov-2026)

CLAUDE.md §6: los artículos constitucionales se verifican contra el texto oficial antes de publicar. Esta página dice qué usa `data/`, qué quedó verificado, con qué fuente y qué no se pudo.

## Acceso a las fuentes oficiales desde el entorno de desarrollo
| Fuente | Resultado | Uso |
|---|---|---|
| `bcn.cl` / `leychile.cl` (texto consolidado de la Constitución y las leyes) | **401 (bloqueado)** | No se pudo releer el texto consolidado en línea |
| `camara.cl`, `senado.cl` (sitio general), `diariooficial.interior.gob.cl`, `oas.org` | 403 | No disponibles |
| `servel.cl/elecciones-2025/` | 200 | **Leído**: fechas y regla de la segunda votación |
| `tribunalcalificador.cl` (Tricel) | 200 | Hay sentencias y autos acordados; la proclamación (PDF) ya está en `data/eventos_reales.json` |
| Texto oficial de la Constitución entregado por el equipo (PDF actualizado al 7-oct-2025) | Extractado en `data/bcn/normas.json` (29 artículos con cita literal) | Base de las reglas de quórum |
Consecuencia: **todo lo que depende del texto consolidado completo queda sin verificar de nuevo hoy**; lo verificado se apoya en las citas literales ya guardadas y en las páginas del Servel.

## Lo que sí se verificó hoy (con lectura del texto)
| Dato del juego | Fuente leída | Resultado |
|---|---|---|
| Primera vuelta presidencial el 16-nov-2025 | Servel, página «Elecciones 2025» (27-nov-2026) | Confirmado |
| Segunda votación el domingo 14-dic-2025 entre las dos primeras mayorías | Servel, misma página | Confirmado |
| Regla de elección: mayoría absoluta = más del 50 % de los votos válidamente emitidos; si nadie la logra, segunda votación | Servel, misma página; Art. 26 en `normas.json` («mayoría absoluta de los sufragios válidamente emitidos») | Confirmado |
| Asunción del presidente el 11-mar-2026 | Senado y Gob.cl (evento `real_20260311_061`, nivel primario) | Confirmado |
| Reforma constitucional: 4/7 de los diputados y senadores en ejercicio | Cita literal de Art. 127 en `normas.json` («las cuatro séptimas partes de los diputados y senadores en ejercicio») | Confirmado: `tipos_ley.reforma_constitucional.verificado` pasa a `true` |
Se agregó la fuente `servel_segunda_votacion_2025` (fecha de corte 27-nov-2026) en `data/fuentes.json`.

## Reglas de `leyes.json` frente a la Constitución
| Elemento del juego | Regla del juego | Respaldo | Estado |
|---|---|---|---|
| `decreto_supremo` | Art. 32 N° 6, sin votación | Art. 32 en `normas.json` (cita «Son atribuciones especiales del Presidente de la República») | Verificado como atribución; el N° 6 no figura literal |
| `ley_simple` | Art. 66 inc. 4: mayoría de los presentes | Resumen en `normas.json`; sin cita literal del inciso | **Sin verificar** el texto del inciso |
| `quorum_calificado` | Art. 66 inc. 3: mayoría absoluta de los en ejercicio | Ídem | **Sin verificar** |
| `ley_organica_constitucional` | Art. 66 inc. 2 (tras la Ley 21.481): mayoría absoluta de los en ejercicio | Ídem | **Sin verificar** (la reducción de 4/7 a mayoría absoluta por la Ley 21.481 se debe contrastar con el texto del inciso) |
| `ley_interpretativa` | Art. 66: 4/7 de los en ejercicio | Cita literal parcial: «cuatro séptimas partes» (sin «interpretativas» ni «en ejercicio») | **Sin verificar** del todo |
| `reforma_constitucional` | Art. 127: 4/7 en ejercicio | Cita literal completa | **Verificado** |
| Tribunal Constitucional (probabilidades de recurso y de éxito, 4/5 de inconstitucionalidad) | Art. 93 en `normas.json` («cuatro quintos de sus integrantes en ejercicio») | Los 4/5 coinciden; las **probabilidades** son del juego (ilustrativas) | Ilustrativo |
| Plazos de tramitación (28, 56, 63… días) | — | Valores del juego | Ilustrativo |

## Umbrales y constantes que NO son derecho (decisiones del juego)
| Constante | Valor | Comentario |
|---|---|---|
| `umbral_victoria_presidencial` | 52 | Es un umbral de balance sobre la aprobación del juego, no el 50 % de los votos válidos de la ley |
| `umbral_pasa_balotaje` | 38 | Piso del juego para pasar a segunda vuelta; en la vida real pasan las dos primeras mayorías (en 2025 pasaron con 26,85 % y 23,93 %) |
| `semanas_campana` | 8 | 8 semanas antes de la primera vuelta = 21-sep-2025: convención (no fecha legal) |
| `semanas_balotaje` | 4 | 16-nov a 14-dic-2025 son 28 días: coincide con el calendario real (`test_calendario_fechas`) |
| 4 años = 1.460 días = 208 turnos | 208 × 7 = 1.456 días | Simplificación: la Constitución dice «cuatro años» (1.461 días con un año bisiesto); 4 días de diferencia sin efecto en el juego |
| `asistencia_presentes` | 0,9 | Ilustrativo (lo dice su nota en `leyes.json`) |

## Cartas reales
- 935 cartas de proyectos de ley y 109 de reformas constitucionales llevan `verificado: true` (verificadas contra la ficha de tramitación en su momento); 639 cartas de proyectos públicos siguen en `verificado: false` (`docs/PENDIENTES_USUARIO.md`). 2 cartas de propuesta constitucional sin marca.
- No se intentó releer fichas de tramitación hoy: `tramitacion.senado.cl` respondió antes (la ficha de la Ley 21.841 está en `eventos_reales.json`), pero verificar lotes de 10 exige leer cada ficha; queda como lista priorizada en `PENDIENTES_USUARIO.md`.

## Qué hace falta del usuario
1. **Artículo 25** (reelección): el texto no está en `normas.json` (decisión D11): aportar el texto o autorizar una fuente alternativa.
2. **Texto consolidado de los incisos del Art. 66** (3 reglas sin verificar): aportar el PDF actualizado o abrir el acceso a `bcn.cl`.
3. Decidir si se publican los umbrales de balance (52 y 38) con la nota de que no son derecho.

## Fichas de proyectos públicos verificadas hoy (Minsal)
Se leyeron las dos páginas primarias del Ministerio de Salud (`minsal.cl`, 27-nov-2026) y se marcaron `verificado: true` 10 fichas de `data/proyectos/minsal_oncologico.json`:
- **Hospitales de Panguipulli y de Valdivia** (2 fichas): la nota del 16-oct-2025 confirma que la ministra Aguilera, ante la Comisión de Salud del Senado en Los Ríos, dijo que ambos están en la cartera de inversión 2026. La ficha no trae monto ni plazo (y no se inventó ninguno).
- **Plan de Inversiones Oncológicas 2026-2030** (8 fichas: Antofagasta, Independencia, Iquique, Los Ángeles, Punta Arenas, Rancagua, San Felipe y Santiago): la nota del 31-ago-2026 lista las comunas de habilitación (Iquique, Antofagasta, Viña del Mar, San Felipe, Santiago, Independencia, Rancagua, Talca, Los Ángeles y Valdivia) y de modernización de equipamiento (Valparaíso y Punta Arenas) dentro de los 25 proyectos del Plan Nacional de Cáncer. Sin monto por comuna.
Quedan **229 de 639 proyectos** sin verificar (curados del centro 49, RM 40, norte 27, energía y transporte 24, concesiones viales 23, sur 18, educación y vivienda 13, planes de gobierno 11, otros 24; 4 del Minsal). Los de Dipres: las fichas con presupuestos simbólicos siguen «sin verificar» por decisión anterior (`data/verificacion/dipres_siap.json`).
**Hallazgo:** regenerar `data/cartas_reales.json` con `tools/generar_cartas.py` hoy cambia la `disponibilidad` (el evento al que se liga) de **102 cartas** respecto de lo publicado, porque la lista de eventos cambió después (se retiraron duplicados). El archivo vigente es válido (todas las referencias existen), así que **no se regeneró**: hacerlo cambia el azar de las partidas (oros) y es decisión del dueño junto con el próximo cambio de datos.
