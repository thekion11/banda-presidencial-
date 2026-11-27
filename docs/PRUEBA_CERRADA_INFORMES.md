# Informes de la prueba cerrada (datos reales de teléfono)

Un informe por partida jugada en un teléfono real, tal como lo pega el usuario desde «Informe de prueba». Cada uno lleva su cita literal y lo que se midió.

## Informe 1 (27-nov-2026): primera partida real del usuario
**Texto literal (pegado por el usuario, recibido vía la coordinadora):**
«PRESIDENTE DE CHILE · informe de prueba — versión 0.9.0-prueba1 · commit 244b3dd · compilado 2026-11-27 02:43 UTC — dispositivo: V2248 · Android · pantalla (1080, 2388) · motor Godot 4.7.2-stable (official) — partidas registradas: 1 · fps mínimo observado: 34 · memoria estática máx: 128 MB — semilla 1795747789.0: 65 acciones, turno máx 9, etapa gobierno, aprobación 36.8, duración 20 min».

**Feedback del usuario:** «falta poder usar las balas de plata, poder darle presupuesto extra a los ministros para qué hagan sus proyectos con prioridad en nuestras propuestas pero tienen autonomía».

| Medida | Valor real | Meta (CLAUDE.md §5) | ¿Cumple? |
|---|---|---|---|
| fps mínimo observado | 34 | ≥ 30 estables | Sí (un solo teléfono, una partida) |
| Memoria estática máxima | 128 MB | ≤ 800 MB | Sí |
| Dispositivo | V2248, pantalla 1080×2388 | — | — |
| Ritmo | 65 acciones y turno máx 9 en 20 min | ≈ 34 semanas por sesión (estimación) | **No: ≈ 4 veces más lento** (ver abajo) |
| Aprobación al terminar | 36,8 | — | Ver análisis en `DURACION_SESION.md` |

**Límites del dato:** una sola partida, la primera del jugador (aprende, lee y explora); el informe no distingue campaña de gobierno (dice «turno máx 9, etapa gobierno», pero los turnos de campaña y de gobierno se numeran aparte y no se sabe cuántos son de cada uno), ni la dificultad, ni si ganó la elección y con cuánto voto.
