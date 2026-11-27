# Estado actual de cada sistema (26-nov-2026)

Resumen vivo de qué hace cada sistema del juego, dónde vive, qué lo prueba y qué le falta. Las decisiones y su historia están en `docs/DECISIONES.md`; las reglas, en `CLAUDE.md`. Todos los números de balance viven en `data/leyes.json`.

| Sistema | Dónde | Estado | Pruebas | Pendiente |
|---|---|---|---|---|
| Turno semanal (8 pasos) | `sim/motor_turno.gd` | Completo. 208 turnos de gobierno, 8 de campaña, 26 de oposición | `test_prueba_oro_*`, `test_enmienda`, `fuzz_acciones` | Duración del juego (decisión del usuario) |
| Director de eventos | `sim/motor_eventos.gd`, `data/eventos.json` | v2: ≤ 1 evento aleatorio por semana, probabilidad con el silencio, estaciones y contexto, 8–12 decisiones por año, cooldowns por evento, familia y decisión. 180 eventos (87 con decisión, cadenas, memoria, actores) | `test_ritmo`, `test_decisiones` | Más contenido por familia |
| Escenas de debate y entrevista | `data/eventos.json` (campo `escena`) | Debate final en 3 rondas, radio, entrevista TV y debate parlamentario en 2 | `test_escenas` | Audiencia por ronda (sin efecto de balance aún) |
| Mazo y mano | `sim/motor_mazo.gd`, `sim/motor_cartas.gd`, `sim/indices_cartas.gd` | Mano continua de 5; ≥ 2 cartas diseñadas; reales sorteadas sin reposición entre las elegibles; 1.964 cartas | `test_gabinete`, `test_identidad`, `test_sin_atascos` | 639 cartas reales sin verificar contra su fuente |
| Gabinete | `sim/motor_gabinete.gd`, `data/ministros.json` | 25 ministerios reales, 75 candidatos con estilo, afinidad y riesgo; relleno automático; renuncias por mala relación | `test_gabinete`, `test_identidad`, `test_delegacion` | — |
| Coalición | `sim/motor_coalicion.gd` | 15 partidos ficticios; aliados satisfechos potencian +12 % las cartas de lo que piden y suman escaños; también en oposición | `test_coalicion` | — |
| Movimientos, delegación y asesores | `sim/motor_movimientos.gd`, `sim/motor_equipo.gd` | Bono por aprobación (+1 por umbral 45…95), 3 internos, 2 delegaciones, asesores | `test_movimientos`, `test_equipo`, `test_delegacion` | Delegación e internos dominan (se miden con jugadores reales) |
| Carrera política | `sim/motor_mandato.gd` | Campaña → elección (balotaje) → gobierno → reelección si se reformó la Constitución, o oposición → campaña… | `test_carrera`, `test_finales` | Artículo 25 sin contrastar con el texto oficial |
| Oposición y Congreso rival | `sim/motor_eventos.gd`, `data/eventos.json` | Rival que gobierna, 16+10 cartas propias, 4 votaciones del gobierno con probabilidad según bancada, aliados y cohesión | `test_congreso_oposicion`, `test_carrera` | Pantallas propias de votación (sesión visual) |
| Encuestas | `sim/encuestas.gd` → `estado.encuestas` | Una por semana de campaña y oposición, más una al cerrar la campaña; error determinista (sin azar de la partida) | `test_encuestas` | — |
| Afiliación y dificultad | `sim/generador_partido.gd`, `data/leyes.json` | Fundar, independiente o entrar a un partido; test ideológico rápido (3) o completo (8); fácil, normal, difícil | `test_afiliacion`, `test_dificultad` | — |
| Piso ideológico y luna de miel | `sim/piso_ideologico.gd`, `sim/luna_de_miel.gd`, `leyes.json` | Piso de aprobación y de voto por región y nacional (ideología, coalición, afinidad regional); 13 semanas de impulso al empezar cada gobierno (aprobación, Congreso, coalición) | `test_piso_ideologico`, `test_luna_de_miel` | Barra con línea de piso, chip «Luna de miel» y voto duro (sesión visual) |
| Guardado | `sim/partida.gd`, `game/main.gd` | Por eventos (semilla + partido + historial); replay exacto; archivo dañado se descarta con aviso | `test_guardado`, `test_guardado_danado`, `test_prueba_oro_completa` | — |
| Instantánea de carga | `sim/instantanea.gd` | Caché desechable (`user://guardado.cache`) validada por SHA del guardado, huella de datos y esquema del estado; si no sirve, se reproduce el historial | `test_instantanea`, `test_carga_rapida` | Visto bueno del usuario (matiza «solo se guarda semilla, partido e historial») |
| Rendimiento | todo `sim/` | Turno ≈ 0,6 ms; carga de un mandato ≈ 13 ms con instantánea y ≈ 130–200 ms sin ella (escritorio) | `test_rendimiento` | Medir 3D, memoria y fps en teléfono real |
| Accesibilidad | `game/ajustes.gd`, `game/tema.gd` | Texto grande (+15 %) y colores para daltonismo, opcionales | `test_accesibilidad` | Probar con personas; modo reducir movimiento (sesión visual) |
| Balance con bots | `tests/bots.gd`, `tests/ablacion.gd`, `tests/informe_bots.gd` | Pasivo 0 %, azar ~45 %, humano ~75–95 %, codicioso/completo/experto ~93–97 % de elecciones con 0–7 % de crisis | `test_balance`, `test_dificultad`, `montecarlo` | Pruebas con personas (U1) |
| Datos reales | `data/`, `data/fuentes.json` | Todos los eventos con fuente y fecha de corte; 97 hitos reales (84 verificados); sin ids duplicados | `validate_data.py` | 13 hitos y 639 proyectos sin verificar (lista en `PENDIENTES_USUARIO.md`) |
| Razones de rechazo | `game/componentes/razones.gd` | 27 de 41 razones del motor tienen texto propio; el resto cae en el mensaje genérico | (pendiente `test_razones`) | Textos con indicación de qué hacer (pedido a la sesión visual) |

## Cómo comprobarlo todo
`CLAUDE.md` §7 lista los comandos; `python3 tools/check_limits.py` vigila los 450 líneas por archivo (220 en `estado_simulacion.gd` y `motor_turno.gd`).
