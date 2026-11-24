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

## PR-05 — Gabinete completo con «rellenar» y ministros recreados desde personas reales (24-nov-2026) · estado: hablada

**Idea del usuario (resumen fiel):** poder **escoger los 25** o usar un **botón que rellene los que falten** (si relleno 24, rellena el último «en base al equilibrio o a lo más beneficioso»; si escojo uno, se rellenan los otros 24), **sin reemplazar nunca lo ya escogido**. Los candidatos serían **ministros reales que sigan vivos** (sean quienes sean), **recreados dejando su apellido pero no su nombre**, con su **ideología, experiencia, partido y estudios** reales.

**Opinión de Claude, parte 1 — escoger todos o rellenar: me gusta y reemplaza mi opción C de PR-04.** Así las 25 decisiones son **opcionales**: quien quiere control total elige todo; quien quiere rapidez elige 1-7 y rellena el resto. Cómo lo haría:
- Las elecciones del jugador quedan **bloqueadas** (candado visible); «Rellenar» solo toca los vacíos y nunca pisa una elección. Un ministerio se puede **vaciar** de uno en uno.
- El relleno es **determinista** (misma partida → mismo relleno, para que el replay y el guardado sigan exactos): puntúa a cada candidato por (a) afinidad con tu ideología y coalición, (b) ajuste entre sus estudios/experiencia y el ministerio, (c) cuotas prometidas a aliados y (d) equilibrio del conjunto (que no queden todos del mismo partido ni todo el gabinete sin experiencia); desempata por id.
- Mostrar **por qué** se rellenó así («Hacienda: economista, 12 años de experiencia, afín a tu perfil») y permitir **deshacer** el relleno.
- Si el objetivo del relleno es «lo más beneficioso», conviene decirlo con claridad en pantalla y que no sea «el mejor posible» siempre (si no, nadie elegiría a mano); por ejemplo, un modo **equilibrado** por defecto y uno **máxima eficacia** que cueste capital político o cohesión.

**Opinión de Claude, parte 2 — personas reales vivas con solo el apellido: me gusta el realismo, pero lo cambiaría.**
- *Lo que gana:* un gabinete creíble, perfiles verificables y variedad (candidatos de varios gobiernos), y encaja con el test ideológico (los mismos ejes que los partidos).
- *Problema 1:* **el apellido no anonimiza.** «Quiroz» + su partido + sus estudios + su trayectoria identifica a una persona viva sin ambigüedad. Y el juego le asigna números (competencia, riesgo de escándalo, probabilidad de fallar una delegación): eso es una **valoración de una persona real**, que es lo más delicado (honra, reclamo por injurias, políticas de Google Play sobre personas reales). La sátira ayuda, pero un número «de escándalo» sobre alguien identificable no es sátira evidente.
- *Problema 2:* contradice la regla vigente de `CLAUDE.md` («políticos reales con **alias satíricos**»); el apellido no es un alias.
- *Mi recomendación:* **alias + perfil real público y verificable.** Conservar lo que sí aporta realismo (ideología documentada, partido, estudios, años y tipo de experiencia) tomado de **fuentes públicas oficiales** (BCN reseñas biográficas, gob.cl), con fuente y fecha de corte, pero con **nombre ficticio o alias** (como los alias de los ministros actuales). Las **cifras de juego** (competencia, riesgo de escándalo) se derivarían de datos **neutros y verificables** (años de experiencia, coincidencia estudios-cartera), nunca de juicios subjetivos sobre la persona. Y un **aviso de ficción satírica** más revisión legal antes de publicar, como ya está anotado para los partidos.
- *Si el usuario prefiere mantener el apellido,* sería una decisión suya con riesgo asumido, que exigiría revisión de un abogado chileno **antes** de que lo jueguen terceros, y excluir de las cifras todo juicio de valor.
- *Costo de datos:* ~75 candidatos (3 por ministerio) con perfil verificado: una sesión de investigación por búsqueda web, con fuentes y fecha de corte; más el diseño de la puntuación del relleno y la pantalla de dos niveles de PR-04.

**Decisiones pendientes:** (1) ¿relleno por defecto «equilibrado» y modo «máxima eficacia» con costo? (2) ¿alias + perfil real (recomendado) o apellido real con revisión legal? (3) ¿candidatos de varios gobiernos, solo vivos, o también ficticios para completar? (4) ¿cuántos candidatos por ministerio?

### PR-05b — Sin apellido: solo sobrenombre si lo tienen (24-nov-2026) · estado: CRITERIO ACEPTADO por el usuario (sin implementar)

**Propuesta del usuario:** ni nombre ni apellido; solo el **sobrenombre**, para quienes tengan uno conocido.

**Opinión de Claude:** de acuerdo en el fondo (es la tradición de la sátira política y es más coherente con la regla de `CLAUDE.md`: alias, no nombre), con tres precauciones:
1. **Un apodo conocido también identifica.** Seguirá siendo una persona real reconocible, así que no elimina la necesidad de revisión legal; solo mejora el tono y la coherencia con la regla de alias.
2. **Criterio de uso:** solo apodos **documentados en prensa o fuentes públicas** (con enlace y fecha de corte en `fuentes.json`), de uso **neutro o afectuoso**; **no** apodos despectivos ni burlas (suben el riesgo de reclamo por la honra). Se aplica el **mismo criterio a todos los sectores políticos**, para no favorecer ni dañar a ninguno.
3. **Sin apodo conocido:** alias **inventado**, en el mismo estilo de los actuales («El Guardián de la Billetera»).
- Se mantiene lo ya recomendado: perfil real **público y verificable** (ideología, partido, estudios, años de experiencia) y cifras de juego derivadas de datos neutros, nunca de juicios sobre la persona; aviso de ficción satírica; revisión legal antes de que lo jueguen terceros.
- *Decisión de proceso:* la investigación de candidatos anota por persona `apodo_real` (con fuente) o `alias_inventado`, y marca si el apodo es neutral; el relleno automático y la interfaz solo muestran el alias.
**Pendiente de decisión del usuario:** (1) ¿se acepta este criterio de apodos (neutros, documentados, igual trato a todos)? (2) ¿qué hacer con apodos dudosos: inventar un alias en su lugar (propuesta de Claude)?

**Decisión del usuario (24-nov-2026):** «Sí, acepto ese criterio». Queda vigente, para cuando se implemente PR-05:
1. Solo **alias o sobrenombre**; nunca nombre ni apellido de personas reales vivas.
2. Se usa el **apodo real** únicamente si está **documentado en fuentes públicas** (enlace y fecha de corte en `fuentes.json`) y es de **uso neutro o afectuoso**; nunca despectivo; **mismo criterio para todos los sectores políticos**.
3. Sin apodo conocido, o con apodo dudoso: **alias inventado** (estilo de los actuales).
4. El perfil (ideología, partido, estudios, experiencia) es real, público y verificable; las cifras de juego salen de datos neutros; aviso de ficción satírica; **revisión legal antes de que lo jueguen terceros**.
Siguen pendientes de PR-05: modo de relleno (equilibrado / máxima eficacia), de qué gobiernos salen los candidatos y cuántos por ministerio. Nada se implementa hasta que el usuario diga «hazlo».

# Lote de propuestas del 24-nov-2026 (usuario: «ahora viene lo más caótico») — todas en estado «hablada», sin implementar

Resumen de opinión: casi todo es bueno para el juego, pero **es mucho más de lo que cabe en un solo ciclo** y el juego aún no tiene datos de prueba con personas. Orden sugerido por **impacto en la sensación de juego por costo**: (1) estadísticas y claridad de cartas + arrastrar + sonido (PR-02) → (2) ministros con rostro, eventos y peticiones (PR-08) → (3) eventos externos y sorpresa (PR-03) → (4) campaña narrativa con entrevistas (PR-07) → (5) cierre del mandato, reelección y oposición (PR-11 a PR-13) → (6) mundo exterior (PR-01x) → (7) apariencia y habilidades (PR-05x) → (8) mapa 3D completo (el más caro y de menos retorno). Decidir con la primera tanda de pruebas con personas.

## PR-06 — Mapa 3D de proyectos sobre la geografía real
**Opinión:** el 3D completo de todo Chile en una pantalla vertical es un mal ajuste: el país es una franja de 4.300 km × 200 km; en un teléfono vertical queda diminuto y tiene un costo alto en rendimiento (meta: 30 fps y 800 MB de RAM) para una sesión casual de ~20 minutos. **Recomiendo:** mantener el mapa 2D estilizado (ya con relieve real) con **zoom a la región** y **pines de proyectos** (cartera real), y dejar el 3D donde ya existe y luce: el **hito de obra** y el **Comité** (ciudad real con 83.574 edificios). Costo de un 3D nacional: alto (semanas), con riesgo de rendimiento. Prioridad: baja.

## PR-06b — Vecinos y proyectos internacionales
**Opinión:** sí, pero como **panel «Mundo»**, no como otro mapa completo: Argentina, Perú, Bolivia (vecinos) y 2-3 potencias (EE. UU., China, Brasil) con **barras de relación**, proyectos binacionales reales (pasos fronterizos, corredor bioceánico, gas y litio, acuerdos comerciales) y la **Cancillería** como ministerio clave. Alimenta eventos externos y las cartas de política exterior. Costo medio; datos por investigación con fuentes. Prioridad: media-baja.

## PR-07 — Eventos externos que «estallan» y sensación de sorpresa
**Opinión:** hoy los eventos son un aviso con un efecto; la sorpresa nace de **consecuencias encadenadas y decisiones**, no del evento en sí. Propongo: eventos **con opciones** (2-3 respuestas con costo/beneficio, sin gastar movimientos), **cadenas** (una decisión de hoy desencadena algo 3-6 semanas después), **crisis con cuenta regresiva** (terremoto, alza del cobre, conflicto vecino), **«ventanas de oportunidad»** limitadas y un aviso breve y legible (no párrafos legales: el problema de P11 del video). Datos reales (eventos 2025-2026) mezclados con eventos ficticios para que no sea predecible. Todo con la semilla (determinista). Costo medio. Prioridad alta.

## PR-08 — Ministros con rostro, eventos y peticiones
**Opinión:** muy buena: es lo que convierte a los ministros de «filas de una lista» en **personajes**. Cada ministro con retrato ilustrado (estilo coherente con las cartas), **peticiones periódicas** (presupuesto, apoyo ante una crisis, un proyecto), **eventos propios** (renuncia, escándalo, conflicto con un aliado) y **respuestas con opciones que no gastan movimientos** (usan capital político, cohesión o relación). Conecta con PR-04/05 (25 ministros, perfiles, cuotas de coalición) y con la delegación. Riesgo: contenido (25 × varios eventos) y retratos (cuota de Canva): empezar con 6 ministerios clave. Costo medio-alto. Prioridad alta.

## PR-09 — Estadísticas de las cartas
**Opinión:** coincido: hoy casi todas dicen «+2 aprobación, −1 fiscal» y los efectos de las 1.044 leyes se generan por plantilla. Mejoras: (a) efectos **diferenciados por sector** y por **tipo de carta** (reforma, obra, decreto, política exterior), (b) **riesgos y plazos visibles**, (c) **efectos secundarios y a futuro** (una ley sube cohesión hoy y baja fiscal en 8 semanas), (d) **rareza/impacto** para que haya cartas «grandes» y «chicas», (e) cada carta con **un texto corto de sabor**. Se mide con los bots. Costo medio, mucho impacto. Prioridad alta.

## PR-10 — Carrera por la presidencia como pantallas distintas (entrevistas, debates…)
**Opinión:** es lo que más diferenciaría la campaña del gobierno: hoy se juega con la misma interfaz, y se nota (video, P10). **Propongo** escenas narrativas: **entrevistas** (respuestas con efectos en regiones y grupos), **debates** (turnos), **primarias/pactos con partidos**, **cierre de campaña**, y **sondeos** como pantalla propia. *Sobre la pregunta del nombre:* «1D» no existe; sería **2D**: pantallas con **personajes ilustrados** y diálogo con opciones, lo que se suele llamar **novela visual** o **ficción interactiva**; si se agrega movimiento sutil de capas (parallax) se le llama **2,5D**. Es contenido nuevo (guiones, retratos, opciones) y requiere sistema de escenas en datos. Costo alto. Prioridad media-alta (la mejor apuesta de diferenciación).

## PR-11 — Qué pasa cuando termina el gobierno
**Opinión:** hoy termina con pantalla de fin y puntaje. Falta un **cierre con sentido**: **epílogo** (cómo te recordará la historia, según leyes, obras, aprobación y promesas), **resultado de la sucesión** (¿gana tu candidato o la oposición?), **puntaje y «legado»** que se traspase a una próxima partida (p. ej. bono) y **la puerta a la oposición o a una nueva candidatura**. Costo medio. Prioridad media.

## PR-12 — Reelección: ¿carta para reformar la Constitución?
**Opinión:** idea muy buena porque usa el sistema que ya existe (reformas constitucionales con quórum 4/7, TC, plebiscito) y es **jugada con riesgo político real**. Según recuerdo del art. 25 de la Constitución, el Presidente **no puede ser reelegido para el período siguiente** (sí puede volver a postular después de un período) — **por contrastar con el texto oficial** (no está en `data/bcn/normas.json`). Variantes jugables: reelección **inmediata por una vez**, **indefinida** o **con plazos**; cada una con costo de legitimidad (ruido en la oposición, protestas, cohesión, TC) y mayor dificultad cuanto más amplia. Por qué conviene: da **rejugabilidad** (segundo mandato) y una decisión moral. Riesgo: duplicar la duración de la partida; solución: segundo mandato como **sesión nueva con el estado heredado**. Costo medio-alto. Prioridad media.

## PR-13 — ¿Podremos ser oposición?
**Opinión:** sí, y mejoraría el juego: hoy perder la elección es **fin de partida** (frustrante). Un **Modo Oposición** (tras perder la elección o al terminar el mandato) cambiaría el verbo: **bloquear o negociar leyes, fiscalizar, acusaciones constitucionales, reconstruir el partido y preparar la próxima candidatura** — con las mismas cartas y el Congreso, pero con otras metas. Es un modo casi nuevo: costo alto. Prioridad media-baja hasta validar el modo de gobierno.

## PR-14 — Movimientos internos: cómo se gestionan
**Hoy:** 3 por turno, solo en gobierno; se gestionan desde la pestaña «Internos» del panel Gabinete; hay 4 tipos (buscar meta, ajustar sector, reducir errores, acelerar proyecto), cada uno gasta 1 y tiene sus razones de rechazo. **Opinión:** son útiles pero **poco visibles** y su efecto es difícil de percibir (pesan −4,7 % de puntaje en el informe de balance). Propongo conectarlos a **personas** (cada acción la ejecuta un ministro o partido: sube su afinidad/satisfacción) y mostrarlos con **un efecto visible** en el mapa/indicadores. Costo bajo-medio. Prioridad media.

## PR-15 — Apariencia física del personaje
**Opinión:** útil para **identificación** y para **escenas narrativas** (PR-10 y PR-08 necesitan un protagonista visible). Recomiendo **pocas opciones, buen arte** (6-8 retratos base con vestimenta/pelo/accesorios modulares y colores) antes que un editor libre. Costo medio (arte con Canva sujeto a cuota). Prioridad media-baja; depende de PR-10.

## PR-16 — Habilidades del personaje
**Opinión:** con cuidado: ya existen **perfil ideológico, partido, gabinete, asesores y coalición**; sumar «habilidades» puede **duplicar mecánicas** y confundir. Si se hace, que sean **pocos rasgos con trade-offs** (p. ej. «orador», «negociador», «técnico»), que afecten **entrevistas, votos del Congreso o ministros** y que **sustituyan** parte de lo existente. Prioridad baja hasta tener datos de prueba.

## Decisiones pendientes (no urgentes)
1. ¿Se acepta el orden de prioridad sugerido, o el usuario quiere otro?
2. PR-06: ¿mapa 2D con pines y zoom + 3D solo en obras/Comité (recomendado), o 3D nacional pese al costo?
3. PR-12: ¿reelección como carta jugable (recomendado como idea) y qué variantes (inmediata una vez, indefinida, plazos)?
4. PR-13: ¿Modo Oposición se planifica después de validar el gobierno?
