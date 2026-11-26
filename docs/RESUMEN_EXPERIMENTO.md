# Resumen del experimento de sesiones paralelas (25 y 26-nov-2026)

Cuatro sesiones trabajaron sobre el mismo repositorio con reparto de áreas. Esta es la lista de qué hizo cada una, qué encontró, qué arregló y qué queda en manos del usuario. Todo lo que cambió una decisión quedó en `docs/DECISIONES.md` (índice al inicio) y lo que espera al usuario en `docs/DECISIONES_PENDIENTES.md`.

## Reparto de áreas
| Sesión | Área | Archivos propios |
|---|---|---|
| Núcleo y datos (esta) | `sim/`, `data/`, balance, rendimiento, validadores, tests del núcleo, docs de decisiones | `sim/`, `data/`, `tools/`, `tests/` del núcleo, `docs/DECISIONES*.md` |
| Diseño visual | `game/` (presentación, audio, movimiento, lienzo de Claude Design), tests de interfaz | `game/`, `tests/captura*`, `tests/test_ui_humo.gd` |
| Búsqueda infinita de fallas | Solo pruebas y fuzzing; avisa a la dueña de cada área | PR #8 (fuzz_*, test_instantanea_fabricada, test_region_larga) |
| Mejora continua de sesiones (coordinadora) | Asigna colas de tareas, revisa avance, pide informes | — |

## Núcleo y datos (esta sesión)
**Hecho**
- **Rendimiento:** turno ≈ 0,55 ms (meta < 1 ms en 10 partidas), cargar un guardado ≈ 12 ms con instantánea (meta < 100 ms) y ≈ 130 ms sin ella. Índices de cartas, grafo y SECTRA perezosos, director de eventos incremental. Pruebas: `test_rendimiento`, `test_instantanea`, `test_carga_rapida`.
- **Carga de guardados:** instantánea desechable (`user://guardado.cache`) validada por SHA-256, huella de datos y esquema del estado; validación estructural previa (`ValidarGuardado`) tras el hallazgo de fallas; guardado dañado se descarta con aviso.
- **Mecánicas ya autorizadas, completadas:** encuestas semanales, bono de la coalición por aliado satisfecho, Congreso en oposición, escenas por rondas, accesibilidad, test ideológico rápido; números de balance movidos de código a `data/`.
- **Validadores y CI:** `check_constantes`, `validate_referencias`, `validate_tipos` (591 rutas de `leyes.json`), `test_validate` (19 datos rotos + 1.514 mutaciones), `check_presupuesto` (APK ≈ 51 de 150 MB), `validar_textos` (ahora también rechaza apellidos de políticos reales), `run_all_tests.sh`. El CI recorre todos los `tests/test_*.gd`, con límite de 300 s y falla ante «SCRIPT ERROR».
- **Balance:** cohesión de 100 constante a mediana 76 (`regen_cohesion_semanal` −1,85); análisis de ritmo (63 % de semanas sin evento; tedio del 9 % al 29 % entre el año 1 y el 4); matriz de dificultad en `test_balance`.
- **Pruebas nuevas hoy:** `test_calendario_reloj`, `test_calendario_fechas`, `test_rechazos_legales`, `test_puntaje_tc`, `test_unidades_sim`, `test_gabinete_fuzz`, `test_guardado_estructura`, `test_determinismo` (4 carreras completas en `tests/oro/huellas.json`).
- **Auditorías:** fuentes y licencias (`docs/LICENCIAS.md`), alias satíricos, trazabilidad de mecánicas (`docs/TRAZABILIDAD_MECANICAS.md`), mapa de dependencias y tamaños (`docs/ARQUITECTURA_SIM.md`), cobertura de funciones de `sim/` (98,4 %; `tools/cobertura_funciones.py`).

**Errores encontrados por las otras sesiones y corregidos aquí**
- Al ganar la elección desde el ciclo 2 el reloj retrocedía 56 días (fallas) → corregido, y también la semana perdida al caer por crisis.
- Un guardado con la forma cambiada rompía la carga en 104 de 200 mutaciones (fallas) → `ValidarGuardado`.
- Una prueba que no compilaba devolvía código 0 y contaba como pasada (fallas) → el CI y `run_all_tests.sh` fallan ante errores de script.
- Un `ci.yml` con YAML inválido y un conflicto de fusión → corregidos.

## Diseño visual
Dirección visual v4 integrada desde el lienzo de Claude Design: sistema de movimiento, telón entre semanas con encuesta, vuelo de la carta al mapa y sello de votación, cambio de mando, fuegos y música ambiente, accesibilidad (daltonismo, texto grande), créditos y brújula del perfil. Rendimiento de dibujo: mapa de Chile en 3 llamadas (antes ~385), contornos en una llamada por color (día 612 → 268), lo tapado no se dibuja; informes de RAM y de cuadros por pantalla. Divisiones de `pantalla_dia` (449 → 351 líneas) y `test_ui_humo` (450 → 337).

## Búsqueda infinita de fallas
Fuzzing y pruebas sin tocar el código de las demás: acciones inválidas, flujo completo de la interfaz con pausas (18 partidas, 74 pausas, 0 fallos), grafo real de 2.459 nodos, coalición, rechazos, calendario (80 partidas con 19 segundas vueltas), guardado (1.000 mutaciones, 0 errores de script) e instantánea fabricada. Aportó los hallazgos del reloj, del guardado y del CI, y la matriz de Monte Carlo por dificultad y política. Sus archivos entran por el PR #8.

## Mejora continua de sesiones (coordinadora)
Ordenó cinco colas de trabajo (ver los mensajes en las sesiones) con foco en cobertura, auditorías, balance y documentación, y mantuvo el reparto de áreas.

## Pendiente del usuario (no decidido por ninguna sesión)
Ver `docs/DECISIONES_PENDIENTES.md` (D1 a D16, U4 a U10) y `docs/PENDIENTES_USUARIO.md`. Lo más importante:
1. **Duración de la partida** (semanas silenciosas, turno = mes o capítulos de 20 minutos).
2. **Dificultad** (D16): hoy solo cambia la campaña; si debe afectar también al gobierno.
3. **Corrector de leyes rechazadas** (D14) y **cohesión con desgaste** (D15, aplicada, revertible).
4. **Licencias abiertas:** imágenes con IA, código del repositorio, SECTRA, GeoJSON de regiones, base ODbL derivada (`docs/LICENCIAS.md`).
5. **Verificación humana** de ~600 cartas de proyectos reales y de los artículos constitucionales.
6. **Arte** definitivo y publicación (Google Play en pausa).
