# Trazabilidad de las mecánicas de CLAUDE.md §2 (auditoría del 26-nov-2026)

CLAUDE.md exige que toda mecánica nueva cite su fuente y su commit. Cada fila liga la mecánica con el documento que la autoriza, el commit en que entró, las pruebas que la cubren y lo que falta.

| Mecánica | Fuente (autorización / diseño) | Commit | Pruebas | Brecha |
|---|---|---|---|---|
| Modo único: test ideológico (8 preguntas) + partido propio; campaña de 8 semanas; elección en el turno 8 | Enmienda de Cierre (`docs/enmienda_de_cierre.pdf`) | 09b9d7e (23-nov) | `test_enmienda`, `test_identidad`, `test_validaciones` | — |
| Calendario real (campaña 21-sep-2025, 1ª vuelta 16-nov, 2ª vuelta 14-dic, mandato 11-mar-2026) | CLAUDE.md §2, ampliación del 23-nov; `docs/DISENO_V2.md` | 1c8ef5e (23-nov), 34fb880 (balotaje desde `leyes.json`) | `test_enmienda` (balotaje), `test_calendario_fechas` (las 4 fechas contra las semanas), `test_calendario_reloj` (reloj único del ciclo 2), `test_carrera`, `test_encuestas` | — |
| Gabinete elegido (25 ministerios) con relleno automático que no pisa lo escogido | PR-04 y PR-05 (`docs/PROPUESTAS.md`), decisión del 25-nov | fdd846d (gabinete), 72d2342 (relleno) | `test_gabinete`, `test_gabinete_fuzz` (400 composiciones), `test_rechazos_legales` | — |
| 5 movimientos por turno y mano continua | `docs/DISENO_V2.md` | cc59f36 (23-nov) | `test_movimientos`, `test_sin_atascos` | — |
| Delegación (hasta 2 por turno, riesgo de fallo) | `docs/DISENO_V2.md` §5; PR-02b | e76324e | `test_delegacion`, `test_rechazos_legales` (tope) | — |
| Movimientos internos (buscar meta, ajustar sector, bajar errores, acelerar) | `docs/DISENO_V2.md`; PR-14 | e76324e | `test_movimientos` | PR-14 («cómo se gestionan») figura como propuesta no cerrada |
| Asesores y bono de movimientos por aprobación | Ampliación 2 de `docs/DISENO_V2.md` (23-nov) | 051cb3b | `test_equipo`, `test_dificultad` (bono) | — |
| Coalición de 15 partidos ficticios | Ampliación 2 de `docs/DISENO_V2.md` | 6e65875 | `test_coalicion`, `test_presupuesto` | — |
| Afiliación (fundar, independiente, entrar a un partido) | PR-01 (24-nov) | 6e52236 | `test_afiliacion` | — |
| Dificultad (fácil, normal, difícil) con presets | PR-01 (24-nov) | 02bfb3d | `test_dificultad`, `test_balance` (matriz por dificultad, nueva) | La escalera es solo de campaña (D16) |
| Cartas por proyecto real (obras, leyes, reformas) | CLAUDE.md §2; `docs/DATOS.md` | 23e750c, 642b552 | `test_cobertura`, `test_sin_atascos` | ~600 cartas curadas esperan verificación humana (`docs/PENDIENTES_USUARIO.md`) |
| Eventos reales | CLAUDE.md §2; `data/fuentes.json` | 642b552 | `test_ritmo`, `test_decisiones`, `test_escenas` | Los 97 eventos del archivo de investigación pasan a 38 en el juego; criterio de selección no documentado en un solo lugar |
| Oposición y reelección (PR-12, PR-13) | PR-12 y PR-13 | 6174a7a (25-nov) | `test_carrera`, `test_congreso_oposicion` | — |
| Encuestas (semanal) | Pedido del usuario en sesión (DECISIONES §Z) | ver DECISIONES | `test_encuestas` | Su presentación en pantalla es de «Diseño visual» |
| Comité de Planificación (variantes A/B/C, sliders, estaciones, 5 fases) | Documento maestro, Fase 1 y 3 | e40d808 | `test_sectra`, `test_grafo`, `test_cartera` | — |

## Pendiente de cerrar por esta auditoría
1. (Hecho: `tests/test_calendario_fechas.gd`.)
2. Documentar en un solo lugar el criterio con que se eligieron los 38 eventos reales del juego entre los 97 de investigación.
3. Cerrar o retirar PR-14 en `docs/PROPUESTAS.md`.
