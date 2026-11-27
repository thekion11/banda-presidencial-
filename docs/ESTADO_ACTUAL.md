# Estado actual del proyecto (generado)

Generado con `python3 tools/estado_proyecto.py` el 2026-11-27 00:06 UTC. No editar a mano. Lo medido en el momento está marcado «medido»; lo demás se lee de las secciones de `docs/DECISIONES.md` y `docs/COBERTURA_GAME.md` donde se registró.

| Qué | Valor |
|---|---|
| Código del núcleo `sim/` (medido) | 4014 líneas en 26 archivos |
| Interfaz `game/` (medido) | 9608 líneas en 69 archivos |
| Pruebas (medido) | 70 `test_*.gd` + 1 fuzz + 15 validadores de datos y tools |
| Datos (medido) | 1964 cartas, 180 eventos, 9 MB en `data/` |
| Decisiones pendientes del dueño (medido) | 26 filas en `DECISIONES_PENDIENTES.md` (las 5 clave están arriba) |
| Secciones de la bitácora de decisiones (medido) | 60 |
| Cobertura de funciones `sim/` (registrada) | 239 de 243 ejecutadas |
| Cobertura de funciones `game/` (registrada) | 451 funciones, 420 ejecutadas (93,1 %), 31 nunca ejercitadas |
| Rendimiento (registrado) | turno p99 1,5 ms; carga con instantánea p99 13 ms |
| Mutantes reales vivos (registrado) | 0 conocidos; los equivalentes están documentados en `DECISIONES.md` (secciones AV y AX) |
| PR abiertos | no disponible (sin `gh` o sin permisos) |

Qué leer: `docs/INDICE.md` (orden de lectura) y `docs/RESUMEN_DECISIONES.md` (lo que espera al dueño).
