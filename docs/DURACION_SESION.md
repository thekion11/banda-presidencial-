# Duración de una sesión y de un mandato (estimación del 26-nov-2026, para la prueba cerrada)

CLAUDE.md fija «sesiones de unos 20 minutos» (decisión del usuario del 24-nov-2026) con un mandato de 208 turnos semanales. Esta cuenta estima si cuadra. **Son estimaciones con supuestos de tiempo de toque, no mediciones**: la prueba cerrada debe medirlas (ver `docs/PRUEBA_CERRADA.md`).

## Qué hace un jugador por semana (medido con el bot «humano», 36 mandatos completos, semillas 8000-8039)
| Por semana de gobierno | Valor medio |
|---|---|
| Cartas jugadas con movimientos | 1,85 |
| Cartas delegadas en un ministro | 1,44 |
| Eventos (informativos, programados y decisiones) | 0,84 |
| de ellos, decisiones con opciones | 0,20 (≈ 41 por mandato) |
| Votaciones de leyes que se resuelven | 0,66 |
| Movimientos internos (meta, sector, errores, acelerar) | 0,22 |
| Semanas de gobierno por partida | ≈ 203 (de 208) |
| Campaña: cartas jugadas | ≈ 2,2 por semana (17,6 en 8 semanas) |

El bot «humano» salta el 20 % de las semanas y juega como máximo 3 cartas; una persona que use los 5 movimientos juega más.

## Tiempos supuestos (segundos por acción)
| Acción | Rápido | Típico | Lento |
|---|---|---|---|
| Base de la semana (telón con encuesta, terminar semana y confirmar) | 5 | 6 | 8 |
| Leer y jugar una carta (deslizar o doble toque) | 3,5 | 5 | 8 |
| Delegar una carta (arrastrar al ícono) | 4,5 | 6 | 9 |
| Decisión de evento (leer, elegir) | 12 | 20 | 35 |
| Evento informativo | 2,5 | 4 | 6 |
| Sello de votación | 3 | 5 | 6 |
| Movimiento interno | 4 | 6 | 8 |

## Resultado
| Perfil | Segundos por semana | Mandato de 203 semanas | Sesiones de 20 min | Semanas por sesión |
|---|---|---|---|---|
| Rápido | 25 | 84 min | 4,2 | 48 |
| Típico | 35 | 119 min | 5,9 | 34 |
| Lento | 59 | 199 min | 9,9 | 20 |

La campaña de 8 semanas dura unos 3 a 4 minutos (típico: ≈ 25 s por semana con 2,2 cartas); una segunda vuelta suma 4 semanas más.

## Lectura
- **Una sesión de 20 minutos son unas 34 semanas (≈ 8 meses de juego): un mandato de 4 años cuesta unas 6 sesiones** (4 a 10 según el ritmo). Un mandato completo no cabe en una sesión; sí cabe una campaña entera con sus primeros meses de gobierno.
- Esto es coherente con guardado automático y «Continuar», pero no con la lectura del mandato como una partida de «unos 20 minutos». Es el mismo asunto de la decisión abierta sobre la duración de la partida (semanas silenciosas, turno = mes o capítulos de 20 minutos; `docs/DECISIONES_PENDIENTES.md`).
- Palancas sin mecánicas nuevas, si el usuario quiere acortar: pasar a turno = mes (un mandato de 48 turnos: ≈ 25 min), o «capítulos» de un año (52 semanas ≈ 30 min). Ambas son decisiones de diseño suyas; no se tocó nada.
- Lo que más pesa en el tiempo son las decisiones de evento (0,2 por semana × 20 s ≈ 4 s) y las cartas (≈ 18 s por semana): bajar la mano o los movimientos reduciría el tiempo, pero cambia el balance.

## Qué medir en la prueba cerrada
Tiempo real por semana y por sesión, semanas jugadas por sesión, número de sesiones por mandato y abandono por semana (propuesta de métricas locales opt-in en `docs/PRUEBA_CERRADA.md`, sin implementar).


## Dato real de teléfono (27-nov-2026): el ritmo es ≈ 4 veces más lento que la estimación
Primer informe real (`PRUEBA_CERRADA_INFORMES.md`, informe 1): **65 acciones y turno máximo 9 en 20 minutos** en la primera partida del usuario.
- Ritmo real: ≈ 2,2 minutos por semana de juego (133 s) y ≈ 18 s por acción (7,2 acciones por semana). La estimación de este documento era ≈ 34 semanas por sesión de 20 minutos (≈ 0,6 min por semana); lo medido es ≈ 4 veces más lento.
- Un mandato de 208 semanas a ese ritmo: 208 × 2,2 min ≈ 460 min ≈ **7,6 horas ≈ 23 sesiones de 20 minutos** (más 8 semanas de campaña). Con una sola partida y siendo la primera del jugador (aprende y lee todo), el ritmo puede mejorar; hace falta una segunda y una tercera partida antes de concluir.
- Toques medidos por semana (`tests/medir_toques.gd`, interfaz real): jugar o delegar una carta 2 toques, terminar la semana 1 (2 si sobran movimientos), eventos y votaciones tras terminar la semana ≈ 2,3 toques (49 % son avisos que solo se descartan). Total ≈ 9 a 10 toques en una semana con 3 cartas.
- Cuenta de lo que ahorraría cada opción sin mecánica nueva (estimación a partir de esas mediciones, no medida jugando): avisos informativos que se cierran solos ≈ 1,1 toques por semana (≈ 11 %); saltar solas las semanas sin decisiones ni cartas ≈ 15 % de las semanas; confirmar menos al terminar la semana ≈ 0,1 toques. Sumadas, ≈ 25 a 30 % más rápido, no 4 veces: **solo cambiar la escala del turno (D1 b: 1 turno = 2 semanas o 1 mes) acerca un mandato a 4 h o 2 h**. Ver D26.

## ¿Es normal una aprobación de 36,8 en la semana 9 de gobierno?
Sí para una partida casual, no para una experta (`tests/analisis_aprobacion_semana9.gd`, 30 partidas por celda, mediana de la aprobación al llegar a la semana 9 de gobierno; p10 a p90 entre paréntesis):
| Política | Fácil | Normal | Difícil |
|---|---|---|---|
| azar | 36,7 (30–42) | 35,4 (31–40) | sin partidas que lleguen a gobierno |
| humano (casual) | 36,5 (33–41) | 35,4 (30–39) | 32,2 (20–37) |
| codicioso | 42,0 (35–45) | 39,0 (36–44) | 37,9 (30–43) |
| completo (usa todo) | 49,0 (42–56) | 49,0 (40–53) | 46,7 (40–49) |
Todas parten de ≈ 51–55 al asumir. **36,8 está en el centro de lo que da el bot casual** (35–37); no es un síntoma de error, pero muestra que un juego casual pierde ≈ 15 puntos de aprobación en 9 semanas, una caída empinada que el piso ideológico y la luna de miel (en curso) deberían amortiguar.
