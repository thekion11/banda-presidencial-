# Propuestas del usuario y opinión de Claude

Registro de ideas habladas. Regla acordada el 24-nov-2026: **por ahora solo se conversa; nada se implementa hasta que el usuario diga «hazlo»**. Estados: hablada · aceptada · rechazada · por hacer · hecha.

## PR-01 — Pantallas previas al inicio: dificultad y afiliación (24-nov-2026) · estado: ACEPTADA en lo conversado (sin implementar; falta «hazlo»)

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

**Decisiones del usuario sobre PR-01 (24-nov-2026):** acepta la opinión y la solución propuestas por Claude:
1. **Test ideológico:** lo hacen completo los **fundadores e independientes**; quien **entra a un partido existente** solo confirma o discrepa de 2-3 posturas del partido.
2. **Fricción:** máximo 3 toques antes de ver el mapa, tarjetas grandes de un toque y opción «continuar como la última vez».
3. **Documentos:** al implementarse se suma una «ampliación autorizada» en `CLAUDE.md` (la Enmienda de Cierre original queda ampliada).
4. Siguen abiertas, sin urgencia: qué cambia con cada dificultad y el beneficio propio del independiente.

## D-01 — Duración objetivo de las sesiones (24-nov-2026) · estado: DECIDIDA: unos 20 minutos

**Dicho por el usuario:** los 8 minutos de `CLAUDE.md` («sesiones de 3 a 8 minutos») son muy poco: apunta a **un poco más**.

**Opinión de Claude**
- Me parece razonable: con 1.685 proyectos, 1.607 cartas, gabinete, delegación, movimientos internos y coalición, el juego tiene más profundidad de la que cabe en 8 minutos; una sesión de unos **10 a 20 minutos** es típica de estrategia móvil por turnos.
- Lo que **cambia** si se sube: (a) el costo de las pantallas previas (PR-01) pesa menos, porque se amortiza en una sesión más larga; (b) conviene definir **puntos de pausa naturales** (fin de campaña, fin de cada año de gobierno) con un resumen de «lo que lograste esta sesión»; (c) la guía de prueba y el informe de prueba hoy hablan de 10-15 minutos: se mantienen; (d) el balance por turno no cambia, pero la **duración de un turno** sí importa: hoy una semana tarda ~30-60 s; 20 minutos serían unos 20-30 turnos, es decir, la campaña entera más unas semanas de gobierno.
- Lo que **no cambia**: el guardado por eventos ya permite pausar en cualquier momento; la partida completa (208 turnos) sigue siendo de varias sesiones.
- **Falta una cifra:** ¿cuánto es «un poco más»? Propongo **10 a 20 minutos** como nuevo objetivo. Cuando el usuario la confirme, se actualiza la línea de identidad de `CLAUDE.md` (hoy dice 3 a 8) y `docs/GUIA_PRUEBA.md`.

**Confirmación del usuario (24-nov-2026):** objetivo de **unos 20 minutos por sesión** (antes 3 a 8).

**Consecuencias que registro (a aplicar cuando el usuario diga «hazlo»):**
- `CLAUDE.md` §2 pasa de «sesiones de 3 a 8 minutos» a «sesiones de unos 20 minutos» (hecho en este commit, es solo el texto de la regla).
- A ~30-60 s por turno, 20 minutos son unos 20-30 turnos: la campaña completa (8, o 12 con segunda vuelta) más unas 10-15 semanas de gobierno. Un año de gobierno son 52 turnos: **un año ≈ 2 sesiones**.
- Puntos de pausa naturales con resumen de sesión: fin de campaña, resultado de elección, cada trimestre (13 turnos) y cada año de gobierno.
- La guía de prueba sigue en 10-15 minutos a propósito (primeros testers: recorrido corto).
- Con sesiones de 20 minutos, el tutorial y las pantallas previas de PR-01 se justifican mejor; en cambio, los textos largos de eventos (P11 del video) siguen siendo un problema porque se repiten decenas de veces.

## PR-02 — Jugar cartas arrastrándolas al mapa; el botón del medio pasa a «avanzar» (24-nov-2026) · estado: hablada

**Idea del usuario (resumen fiel):** eliminar el botón de avanzar de abajo a la derecha; el botón de abajo al medio pasa a ser el de **avanzar**; la esquina inferior derecha queda **vacía**. Usar una carta = **agarrarla, deslizarla hacia el mapa y soltarla**, con una **animación y un sonido** y una **animación en el mapa**.

**Opinión de Claude**
- *Me gusta mucho:* arrastrar al mapa es más táctil y satisfactorio que «elegir + pulsar», quita un toque por carta y hace del mapa el protagonista. En **campaña** además resuelve algo hoy torpe: la carta necesita una región, y soltarla **sobre la región** elige carta y región en un solo gesto. Para obras con ubicación pasa lo mismo en gobierno.
- *Riesgos y cómo los resolvería (propuesta):*
  1. **Jugadas accidentales** (un arrastre es fácil de disparar y la jugada cuesta movimientos): arrastre **vertical hacia arriba** para jugar (el horizontal sigue para recorrer la mano), un **umbral** antes de armar la jugada, retroalimentación mientras arrastras (costo, aviso del corrector, si el destino es válido) y **cancelar soltando sobre la mano**.
  2. **La mano en abanico** ya tapa cartas y corta textos (P10 del video): arrastrar desde un abanico solapado es difícil. Habrá que rediseñar la mano (cartas más legibles, recorrido horizontal) junto con este gesto.
  3. **Accesibilidad:** el gesto cuesta a algunas personas y en juego a una mano. Recomiendo conservar **un respaldo** simple (p. ej. tocar de nuevo la carta elegida) y un ajuste para activarlo; el gesto sería la forma principal, no la única.
  4. **Delegar:** hoy es el botón de la izquierda tras elegir la carta. Coherente con el gesto: **soltar la carta sobre el ícono de delegar** (esquina inferior izquierda). Así quedan tres destinos claros: **mapa = jugar, ícono izquierdo = delegar, mano = cancelar**.
  5. **El botón del medio = avanzar** sigue siendo «el botón principal en la misma posición» (regla de CLAUDE.md §5). El riesgo es terminar la semana por error con movimientos sin usar: su texto debería mostrar el estado («Terminar semana · 3 mov sin usar») y pedir confirmación si sobran movimientos. Eso además arregla el hallazgo P12 del video (el botón se apagaba sin explicar).
  6. **La esquina derecha vacía:** se respeta como pidió; la dejo anotada como espacio libre por si más adelante hace falta (p. ej. «descartar»), sin proponerlo ahora.
- *Sonido y animación:* el sonido hoy **no existe** en el juego. Hace falta elegir efectos con licencia clara (CC0), mantenerlos pequeños (APK), un control de volumen/silencio y vibración corta opcional. La animación en el mapa: pulso sobre la región, cifras flotantes de lo ganado/perdido (+3 aprobación) y un ícono de obra cuando corresponda.
- *Tutorial y pruebas:* el tutorial debe enseñar el gesto con una mano animada; las pruebas de interfaz que hoy pulsan «Jugar» tendrán que simular el arrastre.
- *Documentos:* cambia el paso 4 del ciclo de turno y las reglas de interfaz; la maqueta del PDF muestra el botón «Jugar», así que es una **diferencia deliberada** que se anota en `docs/DIFERENCIAS_MAQUETA.md` al implementarse.
- *Costo estimado (cuando se haga):* medio-alto, ~1 a 1,5 días: gesto con zonas de destino, rediseño de la mano, animaciones y sonido, tutorial, pruebas y capturas.

**Pendiente de decidir (no urgente):** (a) ¿conservar un respaldo de toque? (b) ¿delegar soltando sobre el ícono izquierdo? (c) ¿confirmar al avanzar si sobran movimientos? (d) ¿vibración y ajuste de sonido?

### PR-02b — ¿A quién se delega? (pregunta del usuario, 24-nov-2026) · estado: hablada

**Pregunta:** si delegar es soltar la carta en la esquina izquierda, ¿cómo se indica a qué ministro o consejero se le delega?

**Cómo funciona hoy (para partir de lo real):** la delegación va solo a **ministros del gabinete** (8) con `delegar_carta(idx, ministro_id)`: no gasta movimientos, máximo 2 por turno, y puede fallar (probabilidad según el ministro, el riesgo de ejecución y si la carta es de su área). Hoy se elige en una hoja (`PanelDelegar`) con los ministros ordenados por probabilidad de fallo. Los **asesores no reciben delegaciones**: dan +1 movimiento por turno y un efecto positivo y uno negativo.

**Opciones consideradas**
- **A. Soltar y elegir en una hoja** (dos pasos): soltar sobre el ícono abre la hoja de hoy y ahí se toca al ministro. Seguro y reutiliza lo existente, pero rompe la fluidez del gesto.
- **B. Destinos al arrastrar** (un solo gesto): al empezar a arrastrar una carta, la esquina izquierda se despliega en **2 o 3 fichas de ministro** (foto/alias, cartera y **% de fallo para ESTA carta**); se suelta sobre la ficha elegida. Las fichas muestran primero al ministro **del área de la carta** (el de menor riesgo) y al mejor alternativo, más una ficha «Elegir…» que abre la hoja con los 8.

**Recomendación de Claude: B, con la hoja como respaldo.** Es coherente con «mapa = jugar, izquierda = delegar, mano = cancelar»: el gesto sigue siendo uno solo y la decisión importante (a quién y con qué riesgo) se ve antes de soltar. El riesgo se muestra con **color y porcentaje** («30 % de fallar») y no solo con números. El contador de delegaciones (2 por turno) sigue en el ícono.
- *Cartas sin ministro de su área* (política, comité, estado siempre disponibles): la ficha sugerida es Interior o Secretaría General de Gobierno.
- *Si falla la delegación:* animación propia (la carta se «agrieta») y el aviso de escándalo si lo hay; hoy el motor ya lo registra.
- *Consejeros (asesores):* **no los haría delegables** en este diseño; son personal de apoyo, no ejecutores, y sumarlos mezclaría dos mecánicas (movimientos extra vs. delegación). Si el usuario quiere que también reciban delegaciones, habría que definir qué cambia (riesgo, límites) y medirlo con los bots.
- *Idea a validar, no existe hoy:* la **coalición** reparte ministerios entre aliados; delegar en un ministro de un partido aliado podría subir su satisfacción. Es una sinergia atractiva, pero hay que diseñarla y medirla antes.

**Decisiones pendientes:** (1) ¿B con hoja de respaldo? (2) ¿los asesores quedan fuera de la delegación? (3) ¿se explora la sinergia con la coalición?

### PR-02c — RETIRADA (24-nov-2026)
El usuario aclaró que esos dos mensajes («Lo Jugadas accidentales.» y «Propongo arrastrar.») se enviaron por error. La interpretación y la opinión que Claude había registrado aquí se retiran y **no cuentan como decisión**. Sigue vigente solo lo anotado en PR-02 sobre jugadas accidentales (umbral, zona de cancelar, retroalimentación y respaldo de toque), pendiente de que el usuario lo acepte o lo cambie.

## PR-04 — ¿Y los 25 ministros? Cómo elige el jugador un gabinete completo (24-nov-2026) · estado: hablada

**Observación del usuario:** en Chile hay 25 ministros; si la delegación (PR-02b) y las cartas dependen del gabinete, ¿cómo escoge el jugador esos 25?

**Corrección de un error mío (importante):** el «gabinete de 8» **no fue decisión del usuario**. La especificación decía «el jugador escoge el gabinete (tamaño en leyes.json)»; el 8 lo fijó la sesión que implementó, y yo lo anoté en CLAUDE.md y `docs/DISENO_V2.md` como si fuera del usuario. Ya lo corregí en ambos archivos. Hoy `data/ministros.json` trae **25 ministerios con un único titular cada uno** (alias ficticios), y el jugador elige 8 de esos 25: es una simplificación, no la estructura real.

**La estructura real:** los 25 ministerios existen siempre y **todos** tienen titular; lo que el presidente decide es **quién** ocupa cada uno (y a qué partido le «regala» cuáles). Eso encaja con la coalición: los aliados piden ministerios (cuotas), y 25 puestos son una moneda de poder mucho más rica que 8.

**Opciones**
- **A. Los 25 a mano:** elegir persona para cada ministerio entre 2-3 candidatos. Fiel a la realidad, pero son ~25 decisiones antes de jugar: demasiado para una sesión de ~20 minutos.
- **B. Solo 8 (como hoy):** simple, pero pierde la estructura real y deja 17 ministerios sin existir.
- **C. Híbrido (recomendado): «gabinete de 25 con núcleo elegido».** Eliges tú los **ministerios políticos clave** (Interior, Hacienda, Segpres, Segegob, Defensa, RR.EE., Seguridad, y quizá uno más) entre candidatos con perfil visible (ideología, competencia, riesgo de escándalo, partido). Los **~17 restantes** se llenan **automáticamente** con una propuesta según tu ideología, tu coalición y las cuotas que prometiste; puedes cambiar cualquiera después (un cambio de gabinete cuesta capital político y tiene riesgo de crisis).
- *Qué pasa con las cartas disponibles:* con 25 ministerios llenos, todas las categorías estarían siempre habilitadas y la regla «las cartas dependen de tus ministros» perdería peso. Hay que decidir cómo conservarla: por **calidad** del titular (un ministro técnico desbloquea cartas avanzadas), por **ministerios vacantes o interinos** (una crisis deja un ministerio sin titular), o por **cuotas de la coalición** (si se lo diste a un aliado, sus cartas dependen de su satisfacción).
- *Efecto en la delegación (PR-02b):* mejora: la ficha sugerida es el ministro del área, y la lista completa («Elegir…») necesita **buscador/filtro** por tener 25 entradas.
- *Costo de datos:* hoy hay 1 ministro por ministerio. Un gabinete con elección necesita **2-3 candidatos ficticios por ministerio** (hasta ~75 personajes con perfil); es trabajo de datos para una sesión y requiere cuidado de alias (personajes ficticios, no personas reales).
- *Costo de interfaz:* la pantalla de gabinete pasa a dos niveles (núcleo elegido + vista de los 25 con propuesta automática editable).

**Decisiones pendientes:** (1) ¿A, B o C? (2) ¿cómo se conserva el peso de «mis ministros habilitan cartas»? (3) ¿cuántos ministerios son «núcleo»? (4) ¿cambiar un ministro cuesta capital político?
