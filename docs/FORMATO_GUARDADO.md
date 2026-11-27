# Formato del guardado y del replay (26-nov-2026)

El juego guarda **solo lo que el jugador decidió**; todo lo demás se reconstruye jugando de nuevo, de forma exacta, porque el núcleo es determinista (misma semilla + mismas entradas = mismo resultado).

## Archivo `user://guardado.json`
| Clave | Tipo | Qué es |
|---|---|---|
| `version` | entero | Versión del formato (`ValidarGuardado.VERSION`, hoy 3). Un guardado con versión mayor que la del juego se rechaza. |
| `huella_datos` | texto | Huella de los datos (`Datos.huella_rapida`) con que se jugó. Si no coincide con la del juego, el guardado se descarta. |
| `semilla` | entero | Semilla de la partida (todo el azar sale de ella). |
| `partido` | diccionario | El partido creado o elegido (nombre, sigla, ejes, escaños, `indicadores_iniciales`, afiliación, dificultad, habilidad…). Los decimales se redondean a 6 cifras para que JSON los reproduzca exactos. |
| `entradas` | lista | Historial de decisiones, en orden. Cada una lleva `tipo` y las claves de su tipo. |

### Tipos de entrada (tabla `ENTRADAS` en `sim/validar_guardado.gd`)
`jugar` (idx, ministro, region, delegada), `gabinete` (ids), `asesor` (accion, id), `coalicion` (accion, id), `cuota` (id, clase, valor, quitar), `meta`, `sector` (sector, dir), `errores`, `acelerar` (idx), `aprobar_propuesta` (prop, variante, region, custom, nombres), `sectra` (pid), `presentar` (carta, urgencia, ministro, region, delegar: agenda legislativa, BM), `continuar`, `decision` (evento, idx), `cerrar`, `eleccion`. Las tres últimas sin datos propios marcan el paso del tiempo: `cerrar` termina la semana, `eleccion` vota, `continuar` abre el periodo siguiente de la carrera.

## Cómo se carga (`Partida.cargar`)
1. `Main.continuar_guardado` descarta (renombra a `guardado_descartado.json` y vuelve al menú con aviso) un archivo ilegible, sin semilla o entradas, o de otra huella de datos.
2. `ValidarGuardado.guardado_valido` revisa la forma: versión, semilla, partido con sus indicadores y cada entrada con las claves y tipos de su tipo. Si falla, se descarta igual.
3. Con una **instantánea** válida (`user://guardado.cache`, ver `sim/instantanea.gd`) el estado se restaura directo (≈ 12 ms). La instantánea solo vale si coinciden el SHA-256 del `guardado.json`, la huella de datos y el esquema completo de `EstadoSimulacion`; si no, se ignora.
4. Sin instantánea, `Partida.reproducir` crea la partida con semilla y partido y aplica cada entrada con el mismo código que usa la interfaz (≈ 130 ms; 54 guardados intermedios de partidas de 208 turnos probados en `test_replay_intermedio`).

## Qué se rompe al cambiar algo
| Cambio | Efecto en los guardados viejos | Qué hacer |
|---|---|---|
| Cualquier archivo de `data/` que entra en `Datos.cargar_todo` (cartas, eventos, leyes, ministros, regiones…) | Cambia `huella_datos`: los guardados se descartan con aviso | Es lo esperado entre versiones; no hay migración. Para una prueba cerrada, congelar los datos. |
| Orden o semántica del azar (cuántas veces se llama al RNG, en qué orden) | El replay diverge: otra partida con las mismas entradas | Regenerar los oros (`tests/test_prueba_oro_*`, `tests/oro/huellas.json`) y asumir que los guardados viejos no valen |
| Una clave nueva obligatoria en una entrada, o un tipo nuevo | `ValidarGuardado` rechaza los guardados viejos (o los nuevos, si falta en la tabla) | Subir `ValidarGuardado.VERSION`, actualizar `ENTRADAS`, regenerar `tests/oro/formato_guardado.json` |
| Un campo nuevo o con otro tipo en `EstadoSimulacion` | La instantánea vieja se ignora (el esquema no coincide); el guardado sigue valiendo | Nada; se vuelve a reproducir una vez |
| El significado de un campo del estado sin cambiar su nombre ni tipo | La instantánea vieja se restauraría mal | Subir `Instantanea.VERSION` |

## Pruebas que vigilan el formato
- `tests/test_formato_guardado.gd`: **falla si cambian las claves del archivo o las de las entradas sin subir `VERSION`** (firma en `tests/oro/formato_guardado.json`; regenerar con `-- --regenerar` solo tras subir la versión).
- `tools/check_entradas.py`: todo tipo que el motor registra está en la tabla.
- `tests/test_guardado_estructura.gd`, `test_guardado_danado`, `test_instantanea`, `test_carga_rapida`, `test_replay_intermedio`, `test_determinismo` (4 carreras completas con huella fija).

## Corrupción a mitad de escritura (revisión del 26-nov-2026)
- **Hoy:** `Main.guardar()` escribe `guardado.json.tmp` y lo renombra sobre `guardado.json`; un corte durante la escritura deja el archivo anterior intacto (probado en `test_guardado_danado`). La caché de carga (`guardado.cache`) es desechable: solo se usa si su SHA coincide con el archivo existente.
- **Respaldo (resuelto el 26-nov-2026, commit f7ffd8c de «Diseño visual»):** `guardar()` copia el guardado bueno a `user://guardado.bak` antes de renombrar el `.tmp`; `continuar_guardado()` prueba el respaldo cuando el guardado no pasa la validación (huella, semilla, entradas y `ValidarGuardado`) y avisa «Recuperamos tu partida de hace un momento»; si tampoco sirve, descarta como antes (`guardado_descartado.json`). Una partida nueva borra el guardado y su respaldo. Prueba: `test_estados` (guardado truncado a 0 bytes y al 40 % con respaldo válido).
- **Higiene de pruebas:** `user://` se comparte entre pruebas; toda prueba que escriba un guardado dañado a propósito y espere el descarte debe borrar antes `user://guardado.bak`.
