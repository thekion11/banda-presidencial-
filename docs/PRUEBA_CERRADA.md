# Prueba cerrada: qué observar y qué registrar (U1)

Objetivo: reemplazar con datos de personas lo que hoy solo se mide con bots. Tres decisiones dependen de esto: **la duración del juego** (semanas silenciosas, turno = mes o capítulos de ~20 min), **la dificultad en «Normal»** (hoy los bots que juegan bien ganan ≈ 96 %, `docs/DECISIONES.md` §AA) y **el ritmo de eventos** (hoy ≈ 0,5 por semana y ≈ 30 decisiones por mandato). Esta lista es para quien organiza la prueba; la guía para quien juega es `docs/GUIA_PRUEBA.md`.

## 1. Preparación (30 minutos)
- [ ] APK de depuración de `main` (la última con el CI en verde) instalada en **al menos 2 teléfonos distintos**, uno de gama baja (≤ 4 GB de RAM). Anotar modelo, versión de Android y el commit (`Informe de prueba` lo trae).
- [ ] 5 a 10 personas: al menos 3 que **nunca** hayan visto el juego, 2 que jueguen estrategia por turnos y 2 que no jueguen videojuegos. Registrar edad aproximada y si les interesa la política (no nombres).
- [ ] Una sesión por persona de **20 minutos** con cronómetro, sin explicarles nada antes de empezar (solo la guía de 1 página). Quien observa no ayuda; anota **dónde se queda quieta** la persona más de 10 segundos.
- [ ] Desactivar música/sonido solo si lo piden: preguntar al final si los notaron.

## 2. Qué observar mientras juegan (marcar con hora)
| Momento | Qué mirar | Señal de problema |
|---|---|---|
| Menú → primer mapa | Toques y segundos hasta ver el mapa; si usan «Partida rápida» o el test | > 60 s, o la persona pregunta «¿qué hago?» |
| Test ideológico | ¿Elige el rápido (3) o el completo (8)? ¿Entiende que define su perfil? | Dudas sobre qué eligió |
| Primera carta | Cómo la juega (deslizar / doble toque) y si encuentra «Terminar semana» | Intenta tocar una vez y espera; no encuentra el botón central |
| Delegar y movimientos internos | ¿Los descubre solos? ¿Los usa más de una vez? | Nunca los toca (o solo eso) |
| Eventos con decisión y debates | ¿Lee el texto? ¿Elige por contenido o por azar? ¿Entiende «Ronda 2 de 3»? | Toca la primera opción sin leer |
| Encuestas (telón de fin de semana) | ¿Miran la intención de voto? ¿Cambia lo que juegan? | Ignoran el telón |
| Votación en el Congreso | ¿Entienden por qué se aprobó o rechazó? | «No sé por qué perdí» |
| Elección | Reacción al resultado; si perdieron, ¿quieren seguir en la oposición? | Frustración sin explicación |
| Texto grande / daltonismo | ¿Lo activan? ¿Se corta algún texto? | Letras cortadas, botones que no se alcanzan |

## 3. Qué registrar (todo local; el jugador copia el informe)
Por persona, en una planilla (una fila):
- Del juego (`Informe de prueba` → copiar): turnos jugados, etapa final, aprobación final, **victoria/derrota en la elección**, cartas jugadas, delegaciones, decisiones de eventos, cuadros por segundo (mínimo y medio), memoria, cierres o errores.
- De quien observa: **minutos hasta la primera carta**, minutos totales, veces que preguntó algo, **pantallas donde se confundió**, abandono (¿pidió parar antes de los 20 minutos? ¿en qué turno?).
- Del cuestionario final (escala 1-5): «Entendí qué tenía que hacer», «Las decisiones se sintieron importantes», «Quiero jugar otra partida», «Se me hizo largo», «Se me hizo corto», «La dificultad fue…» (muy fácil / justa / muy difícil).

## 4. Cómo leer los resultados (umbrales sugeridos)
| Pregunta | Si observas… | Entonces |
|---|---|---|
| ¿Es ganable en Normal? | Ganan la elección entre 55 % y 85 % de quienes completan la campaña | Normal está bien. > 85 %: subir la dificultad de Normal (restar aprobación inicial); < 55 %: suavizarla |
| ¿La duración? | La mayoría quiere parar antes de la semana 40 de gobierno, o dice «largo» | Decidir la opción de duración (mes o capítulos); hoy un mandato son 208 turnos |
| ¿El ritmo de eventos? | «Siempre pasa lo mismo» o «no pasa nada» | Ajustar `director_eventos` (prob_semana, decisiones por año) |
| ¿Arranque? | Más de 2 minutos hasta la primera carta | Revisar menú, test rápido y tutorial |
| ¿Rendimiento? | FPS medio < 30 o memoria > 800 MB en el teléfono de gama baja | Priorizar el 3D y las animaciones antes que más contenido |
| ¿Delegar / movimientos internos? | Casi nadie los usa, o todos los usan en cada turno | Rebalancear (hoy valen ≈ 25-30 % del puntaje cada uno en los bots) |

## 5. Después de la prueba
- [ ] Juntar los informes en una carpeta y pasarlos a una sesión de análisis (los registros no llevan datos personales).
- [ ] Anotar en `docs/DECISIONES.md` las decisiones tomadas y su evidencia (cuántas personas, qué se observó), el mismo día.
- [ ] Repetir la medición de bots con los cambios (`tests/montecarlo.gd`, `tests/informe_bots.gd`) para confirmar el efecto.
- [ ] Si se cambia el balance, regenerar las pruebas de oro y dejarlo en el commit.

## 6. PROPUESTA (sin implementar): métricas locales con consentimiento para la prueba cerrada
**Estado: propuesta. Es una mecánica nueva (CLAUDE.md §2, alcance congelado) y la decide el usuario; no se escribió código.** Ya existe un registro local (`game/componentes/registro_prueba.gd`, «Informe de prueba» del menú) con una línea JSON por acción (hora, turno, aprobación, movimientos, fps, memoria), recortado a 1.500 líneas, que el jugador copia a mano. Lo que sigue sería lo mínimo que le falta para contestar las preguntas de §4 y de `docs/DURACION_SESION.md`.

**Qué medir (todo derivable sin datos personales):**
1. Duración real de cada sesión (abrir app → pasar a segundo plano o cerrar) y semanas jugadas en ella.
2. Segundos por semana: del inicio del turno a «Terminar semana» (mediana y p90), separados por campaña y gobierno.
3. Tiempo hasta la primera carta jugada y toques antes de ver el mapa (la regla de ≤ 3 de PR-01).
4. Abandono: semana y etapa de la última sesión de cada partida, y si terminó el mandato.
5. Por decisión de evento: segundos hasta elegir y opción elegida (para detectar decisiones sin sentido o que se abandonan).
6. Uso de las mecánicas: delegaciones, movimientos internos, asesores, coalición y gabinete cambiado (qué se ignora).
7. Fallos: rechazos del motor por razón (`razon`) y errores de script; fps mínimo y medio por pantalla.

**Dónde:** las acciones del motor ya quedan en `estado.registro_acciones`; los tiempos y las sesiones se anotan en `game/main.gd` y `pantalla_dia.gd` (área de «Diseño visual»), extendiendo `RegistroPrueba.anotar`. Nada en `sim/` (el núcleo sigue determinista y sin reloj).

**Cómo exportar:** sin red y sin permisos: el botón «Copiar informe» existente, más un «Compartir» con el selector del sistema de Android (no pide permisos). Nada se envía solo.

**Consentimiento y privacidad:** pantalla de un toque al primer arranque de la versión de prueba («Guardar métricas de esta prueba en tu teléfono: Sí / No»), desactivable en Ajustes y borrable; sin identificadores (ni ID de publicidad ni de instalación), sin texto libre y sin ubicación. Mientras la app siga sin recopilar ni transmitir nada, la política de privacidad y la declaración de seguridad de datos de Play siguen siendo «ningún dato recopilado» (ver `docs/RIESGOS_PLAY_STORE.md`); si algún día se enviaran, habría que cambiarlas.

**Costo estimado:** medio día para el registro y la pantalla de consentimiento; una prueba de formato (`test_registro_prueba`) para que el informe nunca incluya claves fuera de la lista.
