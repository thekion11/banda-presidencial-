# Orden de fusión de los PR del 27-nov (propuesta de la sesión «balas/presupuesto»)

Los tres PR tocan `sim/validar_guardado.gd` (VERSION), `tests/oro/*`, `docs/DECISIONES.md` y archivos compartidos (`estado_simulacion.gd`, `motor_turno.gd`, `resumen_estado.gd`). Para que no choquen:

1. **PR #11 (balas + presupuesto)** primero: `VERSION` 3 → 4 (entradas `bala` y `presupuesto`). Ya está mezclado con `main` hasta `cf618fd` y con la suite en verde.
2. **Núcleo (PR #12)** después: hace merge de `main`; si agrega entradas o estado al guardado, `VERSION` 4 → 5. Regenera oros.
3. **Piso ideológico y luna de miel (PR #10)** al final: merge de `main`; si cambia el guardado, `VERSION` +1; regenera oros (cambia la aprobación y el balance).

Reglas comunes: quien llega segundo hace `git merge origin/main`, resuelve `VERSION`, `tests/oro/formato_guardado.json` (`-- --regenerar`), `tests/oro/huellas.json` y las constantes `ORO` de `test_prueba_oro_*` (se regeneran, no se mezclan a mano), renumera su sección de `DECISIONES.md` (la última hoy es §BP) y corre `tools/run_all_tests.sh`. `motor_turno.gd` está en el límite de 220 líneas: quien necesite líneas compacta blancos entre fachadas y lo dice en su PR.
