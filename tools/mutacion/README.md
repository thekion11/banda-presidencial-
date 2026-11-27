# Mutación manual (tools/mutacion)

Mutantes escritos a mano: cada uno cambia **una** línea de `sim/` o `game/` y una prueba o fuzz de la suite debe fallar («matarlo»).
Un mutante que sobrevive indica una regla sin prueba (o un cambio equivalente, que se documenta).

- `mutantes.py`: la lista (`M*` núcleo, `G*` interfaz, `T*` umbrales y empates). Cada texto original debe aparecer exactamente una vez en su archivo.
- `run_mutante.py M01 G29 ...`: copia el repo, aplica el mutante y corre TODA la suite; escribe `resultados.jsonl` en `$MUTACION_DIR` (por defecto `/tmp/mutacion`). Tarda 2 a 7 min por mutante.
- `matar.py "fuzz_toque_real -- 80 9100" G29 G34`: comprueba que una prueba concreta mata cada mutante (rápido; para escribir pruebas nuevas).

Equivalentes documentados: M15, M22, M30, M34, G11 (núcleo/interfaz), G20 (hay 75 ministros en 25 cargos y el tamaño del gabinete es 25: nunca se elige uno más),
G30, G31, G32, G33 y G35 (atender el toque además del clic emulado es inocuo ahí: la acción es idempotente, está protegida por `_saliendo`, o el overlay
que se abre tapa el segundo evento). Los que sí importan, G29 (carta) y G34 (mano), mueren con `tests/test_toque_real.gd` y `tests/fuzz_toque_real.gd`.
