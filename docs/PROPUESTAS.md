# Propuestas del usuario y opinión de Claude

Registro de ideas habladas. Regla acordada el 24-nov-2026: **por ahora solo se conversa; nada se implementa hasta que el usuario diga «hazlo»**. Estados: hablada · aceptada · rechazada · por hacer · hecha.

## PR-01 — Pantallas previas al inicio: dificultad y afiliación (24-nov-2026) · estado: hablada

**Idea del usuario (resumen fiel):** al iniciar, primero una pantalla que pregunte la **dificultad**; después otra que pregunte si quieres ser **independiente**, entrar a **un partido grande («de un partidazo»)** o **fundar el propio**; solo si se elige fundar aparece el formulario de partido.

**Opinión de Claude**
- *Me gusta:* refleja cómo funciona la política real (candidato independiente, militante de un partido, fundador de movimiento) y le da sentido a cosas que ya existen: los 15 partidos ficticios de la coalición, los escaños, las cuotas de poder y la ideología. Hoy todos los jugadores parten «fundando partido», y eso es una sola experiencia; con esto serían tres partidas distintas con el mismo motor.
- *Dificultad:* conviene que sea un conjunto de **presets en `data/leyes.json`** (fácil / normal / difícil) y no números en el código. El balance actual está calibrado para una sola dificultad (el bot competente gana ~75-80 % la elección): hay que medir cada preset con los bots antes de ofrecerlos. La dificultad debe guardarse en la partida (para el replay) y mostrarse en el informe de prueba.
- *Afiliación, cómo lo veo (a validar contigo):*
  - **Independiente:** libertad total y sin obligaciones con aliados, pero parte con pocos escaños y sin coalición base; compensa con más aprobación personal inicial o más flexibilidad. Riesgo: que sea simplemente «peor»; hay que darle una ventaja real.
  - **Partido existente:** hereda la ideología, los escaños y las alianzas del partido (usando las réplicas ficticias), pero el partido **pide poder** (cuotas) y te castiga si lo ignoras. Es la opción «fácil de empezar, difícil de gobernar».
  - **Fundar el propio:** el flujo actual (formulario + ideología propia), con pocos escaños pero máxima identidad.
- *Pregunta abierta importante:* ¿qué pasa con el **test ideológico de 8 preguntas**? Hoy define el perfil del partido. Si entras a un partido existente, la ideología ya viene dada: ¿se omite, se hace igual para medir tu «distancia» con el partido, o solo lo hacen independientes y fundadores? Yo me inclino por: fundadores e independientes lo hacen; quien entra a un partido confirma o discrepa de 2-3 posturas.
- *Riesgo de fricción:* el juego apunta a sesiones de 3 a 8 minutos. Dos pantallas más antes de jugar son aceptables si son **de un toque** (tres tarjetas grandes) y si «Continuar con lo de la última vez» existe. Recomiendo no pasar de 3 toques antes de ver el mapa.
- *Legal:* usar las réplicas ficticias de partidos es coherente con lo ya decidido (nombres reales solo con revisión legal).
- *Documentos:* contradice la Enmienda de Cierre original («Test Ideológico + Creación de Partido» obligatorios): habría que sumar una «ampliación autorizada» en `CLAUDE.md`, igual que con el gabinete y la segunda vuelta.
- *Costo estimado (cuando se haga):* medio. 2 pantallas nuevas y 1 de selección de partido; condiciones iniciales por afiliación en datos; pruebas por combinación (3 dificultades × 3 afiliaciones = 9 casos de balance); actualizar guardado y replay. Es un trabajo de ~1 día con las sesiones, no de horas.
- *Orden de pantallas sugerido:* Dificultad → Afiliación → (según elección: formulario / lista de partidos / región) → test ideológico si corresponde → gabinete → campaña.

**Decisiones que pide esta propuesta (no urgentes):** (1) ¿qué cambia exactamente con cada dificultad (umbral de elección, indicadores iniciales, severidad de eventos, movimientos base)? (2) ¿el independiente tiene un beneficio propio? (3) ¿se mantiene el test ideológico para quien entra a un partido?
