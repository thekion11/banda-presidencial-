# Revisión de código independiente de los cambios de hoy (26-nov-2026)

Alcance: los commits con más líneas en `sim/` del 25 y 26-nov (rendimiento `64b63e2` con 1.553 líneas, refactor del director `380ba5b`, cachés `2f78706`, índice de cartas `d61991b`, validación del guardado `be588a6`, encuestas `863a9fc`, esquema de la instantánea `41a79f5`, Congreso en oposición `079ef90`…), más el guardado de `game/main.gd`. Se buscó: errores lógicos, carreras con el guardado, casos límite sin probar. Todo hallazgo lleva archivo y la prueba que faltaría.

## Hallazgos
| # | Gravedad | Dónde | Qué | Prueba que faltaría |
|---|---|---|---|---|
| 1 | Media | `game/main.gd` `guardar()` | El guardado se escribe en `.tmp` y se renombra encima del anterior (bien: un corte a mitad de escritura no deja un archivo truncado), pero **no se comprueba el resultado del renombrado ni se conserva una copia del último guardado bueno**. Si el sistema de archivos pierde el renombrado (corte de energía en el instante del renombrado, almacenamiento lleno) o el archivo queda vacío, la única defensa es descartarlo y la partida se pierde. | Un test que deje `guardado.json` vacío o truncado, con un `guardado.bak` válido, y compruebe que «Continuar» recupera la partida de la copia |
| 2 | Baja | `game/main.gd` `continuar_guardado()` | El descarte renombra a `guardado_descartado.json` sobre el anterior: solo se conserva el último descartado (suficiente para diagnosticar, pero un segundo descarte borra el primero). | — (decisión: numerar las copias) |
| 3 | Baja | `game/main.gd` línea 134 | `semilla = tiempo_unix % 2.000.000.000`: dos partidas empezadas en el mismo segundo comparten semilla, y la semilla se puede adivinar (no importa en un juego sin competencia). | Un test que cree dos partidas seguidas y exija semillas distintas, si se quiere |
| 4 | Informativa | `sim/motor_eventos.gd` `relacion_actor`, `sim/motor_gabinete.gd` (firma `.hash()`) | Las cachés se invalidan comparando `Dictionary.hash()` (32 bits): una colisión devolvería una relación o categorías de antes. La probabilidad es de ≈ 2⁻³² por cambio. | Aceptable; si se quiere cero riesgo, comparar además el tamaño del diccionario |
| 5 | Informativa | `sim/director_eventos.gd` `_elegir` | `_silencio(ahora)` se calcula antes de `_sincronizar()`: tras reiniciar `eventos_ocurridos` (nuevo periodo) usa `_ultima` vieja un instante. Con `eventos_ocurridos` vacío devuelve «mucho silencio» y fuerza evento seguro: efecto nulo (probado por `test_director_invariantes`). | Un test que reinicie el periodo y compruebe el primer sorteo |
| 6 | Verificado, sin falla | `sim/instantanea.gd` | Restaurar guarda y recupera el estado del azar (`rng.seed` y `rng.state`), `ultimos_eventos` y las votaciones de la semana; las instantáneas dañadas, viejas o de otra versión se descartan (800 mutaciones del fuzz de fallas, 0 aceptadas). Una interrupción entre escribir `guardado.json` y escribir la caché no es un riesgo: la caché solo vale si su SHA coincide con el del archivo que existe. | Cubierto: `test_instantanea`, `test_carga_rapida` |
| 7 | Verificado, sin falla | `sim/indices_cartas.gd` compartido entre partidas | Ninguna parte de `sim/` modifica las cartas o eventos del catálogo (las manos guardan referencias a las mismas): se revisó con búsqueda de asignaciones a campos de carta; solo se escribe sobre el estado. | `test_determinismo` y `test_replay_intermedio` lo detectarían |
| 8 | Verificado, sin falla | `ValidarGuardado` | Los rechazos del motor (`jugar_carta` con índice o ministro inválidos) ocurren **antes** de `registrar_entrada`, así que un guardado propio nunca contiene entradas inválidas. | `test_rechazos_legales` |

## Cambios hechos hoy a partir de esta revisión
Ninguno en `sim/`: no se halló un error lógico nuevo. Lo que sí salió de las pruebas, antes de esta revisión: la carta duplicada en el mazo (`DECISIONES.md` §AW), el reloj del ciclo 2 (§AI), la composición del Congreso (§AO) y los partidos absurdos (§BB).

## Propuesta para el hallazgo 1 (no es una mecánica: es robustez del guardado; el archivo es de «Diseño visual»)
1. En `guardar()`, antes de renombrar, copiar el `guardado.json` existente a `guardado.bak` (si es válido).
2. En `continuar_guardado()`, si `guardado.json` no pasa `ValidarGuardado` o no se puede leer, probar `guardado.bak` antes de descartar; si se usa, avisar «Recuperamos tu partida de hace un momento».
3. Prueba: truncar `guardado.json` a la mitad y a 0 bytes con un `.bak` bueno, y comprobar la recuperación y que `Partida.cargar` no devuelve `null`.
Costo: ≈ 15 líneas y una prueba. Pérdida máxima: la última acción.
