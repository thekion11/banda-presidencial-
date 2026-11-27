# Auditoría de cifras desactualizadas (27-nov-2026, sesión Leyes+ahorro)
Solo lista: **no se editó `CLAUDE.md`** (necesita autorización del usuario) ni se tocaron las demás páginas. Cada fila dice dónde, qué dice, qué es ahora y la corrección propuesta. Hechos de referencia: ahorro de movimientos con tope 10 (`mano.tope_ahorro`, DECISIONES §BL, ed36340), agenda legislativa (§BM; 3 proyectos simultáneos; urgencias de 30, 15 y 6 días), `ValidarGuardado.VERSION` = 3 (la bala «balas de plata» propone 4 y **aún no está en `main`**: no hay `sim/motor_balas.gd`), 208 semanas, móvil real ≈ 2,2 min/semana (≈ 7,6 h por mandato; informe no disponible en el repositorio).

## A. CLAUDE.md (pedir autorización antes de editar)
| Línea | Dice | Corrección propuesta |
|---|---|---|
| §2 «sesiones de unos 20 minutos» | Objetivo de sesión | Sigue siendo la decisión del usuario del 24-nov, pero **contradice el móvil real**: un mandato son ≈ 22 sesiones de 20 min (D26). Añadir nota «la duración real es de ≈ 7,6 h por mandato; ver D1/D26» o decidir D1. |
| §2 ampliación 23-nov «5 movimientos por turno» | Cifra fija | «5 movimientos base por semana (más bono por aprobación y asesores; los no usados se ahorran hasta 10)». |
| §2 ampliación BM | Cita el commit 8a80b1c | Existe, pero el código de la agenda es `4373865` (y `ed36340` para el ahorro): unificar a un solo commit de referencia. Añadir «`data/leyes.json › agenda` y `mano.tope_ahorro` son las dos únicas filas descongeladas» y, cuando entre, la de balas. |
| §3 «sim/estado_simulacion.gd y motor_turno.gd bajo 220» | Límite | Hoy 210 y 219 líneas; con balas (+2 y +1) quedan en el borde: avisar que no hay margen. |
| §4 punto 1 «regenera PA» | PA | Ahora «suma el ingreso a los movimientos ahorrados (tope 10)». |
| §4 punto 4 | Sin la agenda | Ya incluye «presentar una ley del catálogo (BM)»; falta decir que cuenta contra el máximo de 3 proyectos y que su resultado llega en las votaciones de la semana. |
| §5 «el botón del medio es “Terminar semana” (pide confirmar si sobran movimientos)» | Confirmación | Con el ahorro **ya no pide confirmar** (commit 0c3a55e «ahorro de movimientos sin confirmar»): corregir la decisión PR-02 con la fecha de BL. |
| §7 Comandos | No lista `test_agenda_legislativa`, `test_agenda_combinada`, `analisis_ritmo_d26` ni (cuando entren) `fuzz_ahorro`, `fuzz_agenda`, `test_agenda_limites` | Añadirlos. |

## B. Documentos con cifras viejas
| Archivo | Dice | Corrección |
|---|---|---|
| `docs/GUIA_ESTILO.md:82` | Pastilla «5/5 mov» | Solo los disponibles con el rayo (pedido del usuario del 27-nov; commit 51fa451). |
| `docs/GOOGLE_PLAY.md:29` | «Cada semana tienes 5 movimientos» | «5 movimientos base por semana; los que no uses se guardan (hasta 10)». |
| `docs/GOOGLE_PLAY.md:42` | «Sesiones de unos 20 minutos (unas 30 semanas por sesión)» | Con 2,2 min/semana una sesión de 20 min son ≈ 9 semanas; decidir D1 antes de publicar la ficha. |
| `docs/DURACION_SESION.md` (todo) | ≈ 29 s por semana, ≈ 119 min por mandato, «6 sesiones» y «203 semanas» | Marcar como **refutado por el móvil real** (≈ 2,2 min/semana); enlazar D26; «208 semanas». |
| `docs/DECISIONES_PENDIENTES.md:10` y `:29` (D1), `RESUMEN_DECISIONES.md:8`, `ENTREGA_27NOV.md:13` | «≈ 6 sesiones de 20 min por mandato» | ≈ 22 sesiones con el dato real; reabrir D1. |
| `docs/DECISIONES.md:305` | «≈ 6 sesiones de 20 minutos (4 a 10 según el ritmo)» | Igual: anotar que el móvil real lo contradice. |
| `docs/DISENO_V2.md:8` | «5 cartas y 5 movimientos» | Añadir el ahorro (tope 10), el bono por aprobación (§11) y la agenda legislativa (nueva sección). |
| `docs/ESTADO_FASES.md:124,129,133` | Balance de «5 movimientos» (bot ≈ 80 %), bono 45/55/…/95 | El balance se midió sin ahorro; ver DECISIONES §BL (crisis ≈ 20 % sin efecto significativo con ahorro). |
| `docs/INDICE.md` | No enlaza D26, `AUDITORIA_NUMEROS_27NOV.md` ni la agenda | Añadirlos. |
| `docs/PROPUESTAS.md:69` | «A ~30-60 s por turno, 20 minutos son unos 20-30 turnos» | Con 132 s por turno son ≈ 9. |
| `docs/GUIA_PROBADOR.md:10`, `docs/PRUEBA_CERRADA.md:8` | «Qué hacer en 20 minutos» | Dejar claro que en 20 minutos se verá la campaña y ≈ 1 año de gobierno como mucho. |
| `docs/ANALISIS_PROFUNDIDAD.md` H2 | «La duración real es de horas» | Coincide con el móvil real: citarlo como confirmación. |
| `docs/API_SIM.md` | — | Al día (regenerado: 229 funciones públicas). |
| `docs/FORMATO_GUARDADO.md` | VERSION 3 y entrada `presentar` | Al día; si entra la bala, VERSION 4 y entrada `bala`. |

## C. Riesgos de coherencia a vigilar
- Dos PR pueden subir `VERSION` a 3 o 4 a la vez: `tests/test_formato_guardado.gd` lo detecta; el que entre segundo hace merge y sube.
- `docs/PRUEBA_CERRADA_INFORMES.md` no existe en el repositorio: la cifra del móvil real no tiene fuente verificable aquí.
