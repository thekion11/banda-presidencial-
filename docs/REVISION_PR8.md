# Revisión cruzada del PR #8 de «Búsqueda infinita de fallas» (26-nov-2026)

Alcance: las 40 pruebas y herramientas nuevas del PR (fuzz de carrera, instantánea, propiedades, flujo de interfaz, Congreso, calendario, guardado, obras, coalición, última configuración, semillas extremas y «mono»; pruebas de regresión; `soak_*`) y su cambio de `ci.yml` y `run_all_tests.sh`. Se ejecutaron los 12 fuzz del CI sobre la rama del PR, con un directorio de datos aislado cada uno.

## Resultado
- **Los 12 fuzz del CI pasan** (código 0) y suman **≈ 90 s**: carrera 16 s, flujo de interfaz 26 s, semillas extremas 13 s, propiedades 7 s, «mono» 7 s, última configuración 6 s, calendario 5 s, guardado 5 s, obras 2 s, coalición 2 s, instantánea 1 s, Congreso 1 s. Con el CI actual (≈ 4 a 5 min de un límite de 20) hay margen: **no hace falta recortar para bajar el tiempo**.
- **Dependencia del tiempo, la red o el azar global:** ninguna. Las pruebas leen solo argumentos de línea de comandos (`OS.get_cmdline_user_args`); la única referencia a `Time` es una conversión de fecha a texto (determinista). No hay llamadas HTTP ni `randomize()`.
- **Estado compartido:** 10 archivos escriben en `user://` (`guardado.json`, `guardado.cache`, `ultima_config.json`, `preferencias_*.json`). Todos los borran al terminar, y `tools/run_all_tests.sh` los aísla con un `XDG_DATA_HOME` propio por prueba y comprueba al final que no cambió el guardado real del usuario. **Hueco:** los pasos del `ci.yml` (que son bucles de `godot …` seguidos) **no** usan ese aislamiento; hoy funcionan porque cada prueba limpia lo suyo y corren en serie, pero una prueba que falle a medias podría dejar un guardado dañado para la siguiente (ya pasó con `guardado.bak` y `test_guardado_danado`). Recomendación: exportar `XDG_DATA_HOME=$(mktemp -d)` por prueba también en el `ci.yml`, como en `run_all_tests.sh`.
- **Orden:** ninguna prueba depende de que otra corra antes. Las que usan la interfaz (`fuzz_ui`, `fuzz_flujo_ui`, `fuzz_mono`, `test_gestos_mano`, `test_fundacion`) crean su propia `Main` y su archivo de preferencias.

## Solapes (no son duplicados: cubren más profundidad)
| Prueba del PR | Se solapa con | Qué agrega |
|---|---|---|
| `fuzz_carrera` | `test_carrera`, `test_replay_intermedio` | Carreras largas con oposición y reelección, replay idéntico y restaurar la instantánea |
| `fuzz_propiedades` | `fuzz_acciones` (replay), `test_determinismo` | Misma semilla y entradas = mismo resultado en 9 combinaciones de dificultad y afiliación |
| `fuzz_congreso` | `test_congreso_invariantes` | 3.000 votaciones con entradas extremas y «aprobada» exacta (atrapa el mutante de `>=`) |
| `fuzz_guardado` | `test_guardado_estructura` | 1.000 mutaciones estructurales y 600 de valores absurdos frente a 300 |
| `fuzz_instantanea` | `test_instantanea`, `test_instantanea_fabricada` | 800 mutaciones de la instantánea |
| `fuzz_calendario` | `test_calendario_reloj`, `test_calendario_fechas` | 80 carreras con 19 segundas vueltas |
| `fuzz_ultima_config` y `test_ultima_config_rara` | — | Mismo tema (configuración guardada dañada): `test_ultima_config_rara` es el caso fijo y el fuzz es el barrido; se pueden dejar los dos |

## Recortes seguros (opcionales)
1. `fuzz_propiedades -- 1 800` (7 s): su garantía (mismo resultado con misma entrada) ya la dan `test_determinismo` (4 carreras completas con huella fija) y el replay de `fuzz_acciones`; si hace falta ganar segundos, es lo primero que se puede quitar del CI (sigue disponible a mano).
2. `fuzz_flujo_ui -- 9 2100` (26 s) es la prueba más cara y la única que ejercita las pausas de la interfaz: **no recortar**; si hiciera falta, bajar a 6 partidas.
3. `soak_memoria` y `soak_pantallas` no están en el CI (correctamente: son medidas largas).
Ahorro máximo sin perder cobertura: ≈ 7 s. No vale la pena tocar nada.

## Mejora recomendada al CI
Aislar `user://` por prueba también en `ci.yml` (hallazgo arriba) y, como el CI de la rama prueba la mezcla con `main`, mantener `run_all_tests.sh` como fuente única de lo que corre el CI.
