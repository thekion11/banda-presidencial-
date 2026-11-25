# Registro de decisiones y consultas aceptadas

Este archivo reúne **todo lo que fue aceptado**: ideas y órdenes del usuario, y propuestas, dudas y consultas de Claude que el usuario aprobó. Lo mantiene Claude; cada decisión nueva se anota aquí el mismo día. El detalle de cada propuesta vive en `docs/PROPUESTAS.md`; lo que falta en `docs/PENDIENTES_USUARIO.md`.

Origen: **U** = idea u orden del usuario · **C** = propuesta o duda de Claude aceptada por el usuario.

## A. Reglas de trabajo y alcance
| Fecha | Origen | Decisión | Estado |
|---|---|---|---|
| 23-nov-2026 | U | Ampliación autorizada del alcance (calendario real, gabinete, 5 movimientos, delegación, internos, asesores, coalición, cartas por proyecto real, eventos reales). | Hecho (CLAUDE.md §2) |
| 24-nov-2026 | U | Sesiones de unos 20 minutos (antes 3 a 8) — D-01. | Vigente (CLAUDE.md §2) |
| 24-nov-2026 | U | Publicar en `main` lo ya hecho y seguir; trabajar sin parar cada ~10 min y dejar pendiente lo que dependa del usuario. | Vigente |
| 24-nov-2026 | U | No publicar secretos; no gastar créditos de Figma/Canva; ignorar Google Play (en pausa). | Vigente |
| 24-nov-2026 | U | Los números internos (boletín, conteos del catálogo, páginas «1/85», «1685 proyectos») no se muestran al jugador. | Hecho (`da43e50`, `96ce40d`) |
| 25-nov-2026 | U | «Quiero todo lo pendiente hecho» y «todo lo aceptado debe estar registrado». | Vigente (este archivo) |

## B. Propuestas numeradas (PR-xx)
| ID | Origen | Qué se aceptó | Estado | Dónde |
|---|---|---|---|---|
| PR-01 | U + C | Pantalla de dificultad (fácil, normal, difícil) y de afiliación (fundar partido propio, independiente, entrar a un partido ficticio); test completo para fundadores e independientes, 3 posturas para quien entra a un partido; «Nueva partida como la última vez»; máximo 3 toques antes del mapa. | Hecho. Falta decidir: que el partido existente «pida poder y castigue», y calibrar las 9 combinaciones con bots | `02bfb3d`, `6e52236`, `f7ba474`; `leyes.json` → `dificultad`, `afiliacion` |
| PR-02 | U | Jugar las cartas deslizándolas; botón del medio = avanzar; esquina inferior derecha vacía; delegar soltando sobre el ícono izquierdo; confirmar al terminar con movimientos sin usar; tocar dos veces como respaldo. | Hecho. Falta: sonido, vibración, animación sobre el mapa, soltar sobre una región | `01e8355`, `486ef83`; CLAUDE.md §4 y §5 |
| PR-04 | U (25-nov) | El gabinete es el de la vida real: los 25 ministerios, con relleno automático. | Hecho | `486ef83`; `leyes.json` → `gabinete.tamano` |
| PR-05 | U + C | Botón «Rellenar» (equilibrado o máxima eficacia) que nunca pisa lo escogido, explica el porqué y se puede deshacer. | Hecho. Falta: que «máxima eficacia» cueste capital | `72d2342` |
| PR-05b | U + C | Ministros reales solo con sobrenombre documentado y neutral; si no, alias inventado; perfil real y público; revisión legal antes de publicar. | Criterio vigente; recreación de candidatos NO implementada (necesita investigación y revisión legal, U4) | PROPUESTAS.md |
| PR-06c | U + C | Mapa del continente 2D (Sudamérica + potencias como íconos) y vecinos «vivos» con crisis y efecto sobre Chile. | Hecho en 2 etapas. Falta: cartas de política exterior, pines de proyectos internacionales, 2,5D | `a1ae463`, `039d88a` |
| PR-07 | U + C | Eventos con opciones sin gastar movimientos, externos y sorpresa. | Hecho (4 eventos externos). Falta: cadenas, cuenta regresiva, ventanas de oportunidad | `f60e13d` |
| PR-08 | U + C | Ministros con peticiones y decisiones. | Hecho (25 ministerios). Falta: retratos (U7) y eventos propios más variados | `f60e13d`, `11d6b8b` |
| PR-09 | U + C | Estadísticas de cartas más claras. | Parcial: impacto pequeño/mediano/grande y exigencia legal; consecuencia visible al jugar. Falta: efectos por sector, a futuro y texto de sabor | `d614692`, `2965cbb` |
| PR-10 | U + C | Campaña con entrevistas y decisiones. | Hecho en versión de eventos (4 hitos). Escenas de varias rondas hechas (sección U); falta audiencia/encuestas | `0706883` |
| PR-11 | U + C | Cierre del mandato: epílogo, hitos y sucesión. | Hecho. Falta: bono de legado entre partidas (decisión de datos, U9) | `cc228ae`, `f7ec506`, `796434d` |
| PR-12 | U + C | Reelección mediante reforma constitucional. | Carta + epílogos hechos (mecánica ilustrativa; art. 25 sin contrastar). **Consulta abierta a ti:** ¿segundo mandato dentro de la misma partida? | `d5802c3` |
| PR-13 | U + C | Modo Oposición tras perder. | Hecho en versión ligera (4 escenas). Falta: Congreso y cartas en oposición | `d5802c3` |
| PR-14 | U + C | Movimientos internos más visibles. | Sin cambios (ya muestran aviso por acción); vincular a personas queda con PR-24 | — |
| PR-15 | U + C | Apariencia del personaje. | Parcial: color del emblema. Falta: retratos modulares (arte, U7) | `0706883` |
| PR-16 | U + C | Habilidades del personaje. | Hecho (4 habilidades) | `0706883` |
| PR-17 | U + C | «Balas de plata»: recursos extraordinarios de un solo uso. | Hecho (5 cartas). Falta: reglas finas y mazo aparte | `6b22b5c` |
| PR-18 a PR-23 | U + C | Presupuesto anual, elecciones, comisiones, Contraloría, instituciones autónomas y medios. | Hecho como eventos con decisión (19). Falta: pantallas propias y mini-juego de presupuesto | `0706883` |
| PR-24 | C | Marco de actores único. | Primera versión: relación derivada de las decisiones. Falta: consecuencias | `d910fa8` |

## C. Ideas del análisis de mercado (aceptadas con «hazlo todo»)
| Idea | Estado | Dónde |
|---|---|---|
| Consecuencias visibles por carta | Hecho | `2965cbb` |
| Finales variados | Hecho (9 epílogos) | `cc228ae` |
| Resumen de sesión con hitos | Hecho (hitos del mandato) | `f7ec506` |
| Tutorial corto | Hecho (5 pasos; textos actualizados) | `tutorial.gd` |
| Medición D1/D7 | NO hecho: depende de la decisión de monetización y datos (U9, Ley 21.719) | — |

## D. Metro y mapa urbano
Aceptados y hechos: mapa limpio con enfoque por línea, comparación con las líneas reales, zoom, vista esquemática, sugerencias de nombre, líneas del jugador guardadas y nombradas solo durante la planeación, líneas 7, 8 y 9 con su color y trazado (commits `48bdbb9` a `ec7e864`; detalle en `docs/METRO_COMPARACION.md`).

## E. Técnica y calidad
| Decisión | Estado |
|---|---|
| Actualizar a la última versión de Godot (4.7.2) | Hecho (`f13fa64`) |
| Revisar todo el código y mejorarlo; números de balance a `data/` | Hecho en lo revisado; pendiente: lo que siga en código (ver PENDIENTES) |
| Fuzzing del núcleo en el CI (de la rama `ccr-c6aa6dd1-uuqdjm`) | Hecho |
| `main` creada y con APK de depuración en CI | Hecho (U8 pendiente: ponerla por defecto en GitHub) |

## F. Consultas y dudas de Claude respondidas
| Consulta | Respuesta | Fecha |
|---|---|---|
| ¿Qué pasa con el test ideológico al entrar a un partido? | Solo confirma 3 posturas | 24-nov |
| ¿Se acepta el criterio de apodos (neutros, documentados, igual trato)? | «Sí, acepto ese criterio» | 24-nov |
| PR-06c: ¿solo Sudamérica o también potencias? ¿vecinos vivos? | Sudamérica + potencias como íconos; vecinos vivos | 24-nov |
| Tamaño del gabinete (PR-04, A/B/C) | El de la vida real (25) con relleno automático | 25-nov |
| PR-02: ¿mover el botón de avanzar? | Sí, hazlo | 25-nov |

## G. Consultas abiertas (esperan al usuario)
1. **PR-12:** al terminar un mandato con reelección aprobada y aprobación alta, ¿ofrecer continuar un segundo mandato de 4 años en la misma partida (recomendado) o solo el epílogo?
2. **PR-01:** ¿el partido existente debe «pedir poder y castigar» si se lo ignora?
3. **U3:** ¿legado completo a quien no promete nada en campaña? ¿una ley de 7 días se resuelve en 1 o 2 cierres?
4. **U9:** modelo de monetización (condiciona D1/D7 y el bono de legado entre partidas).
5. Resto de la lista de «Necesito del usuario» en `docs/PENDIENTES_USUARIO.md` (U1, U4 a U8).

## H. Decisiones del 25-nov-2026 (respuesta a las consultas abiertas)
| Origen | Decisión | Estado |
|---|---|---|
| U | **PR-01:** el partido existente «pide poder y castiga»: queda como aliado permanente (no se abandona), pide sus ministerios; si lo desatiendes rompe y cuesta cohesión y capital. | Hecho |
| U | **U3:** quien no promete nada es «intrascendente»: pierde votos en la elección (`campana.min_promesas`, `penal_sin_promesas`), su legado vale cero y recibe el epílogo «Un presidente intrascendente»; el juego avisa antes de ir a las urnas. | Hecho |
| U | **PR-12 ampliado, «Carrera política»:** en una misma partida el jugador puede perder elecciones y pasar a ser oposición, volver a ganar, ser oposición otra vez, ser reelecto si cambió la Constitución y seguir; con un sistema completo de oposición, debates, entrevistas y campaña con franja televisiva. | Hecho en su primera versión completa (ver sección I) |

## I. Carrera política (PR-12/PR-13 ampliados, hecha el 25-nov-2026)
**Qué es:** una sola partida puede encadenar periodos: campaña → elección → gobierno → (reelección si cambiaste la Constitución, si no) oposición → campaña → elección → …; también tras una derrota o la caída del gobierno se pasa a la oposición. La pantalla de fin ofrece «Seguir tu carrera» (o «Postularte a la reelección») y muestra el resumen de tus periodos.
- **Oposición jugable** (`leyes.json` → `oposicion.semanas` = 26): 16 cartas propias (fiscalizar, acusación constitucional, bloquear, negociar, recorrer el país, entrevista, debate, congreso interno, alianza, proyecto alternativo, comisión investigadora, vocería, territorio, financiamiento, equipo técnico, votar a favor); solo circulan en oposición. 8 eventos con decisión (debate parlamentario, entrevista a fondo, acusación, presupuesto, congreso del partido, encuesta, filtración, comisión).
- **Campaña completa** en cada periodo: franja televisiva (dos spots), entrevistas (matinal, de fondo, televisión abierta), cabildo, debate en radio, debate presidencial final y cierre; todas con decisiones.
- **Reelección:** solo si la carta «Reforma constitucional: reelección presidencial» se ejecutó en el gobierno (mecánica ilustrativa; el artículo 25 real sigue sin contrastarse con el texto oficial).
- **Reglas:** los hitos con fecha real ocurren una sola vez; las decisiones se reinician por periodo; el calendario avanza con un solo reloj; todo se guarda y se reproduce exacto (`test_carrera.gd`: derrota → oposición → campaña → gobierno → reelección y replay idéntico).
- **Pendiente:** pantallas propias de debate y entrevista (hoy son eventos con decisión), Congreso y votaciones en oposición, un rival que gobierne mientras tú eres oposición (que tu aprobación dependa de su desempeño), la franja con spots elegibles y medición de audiencia. El PantallaOposicion ligero anterior fue reemplazado.

## J. Análisis de profundidad (25-nov-2026)
El usuario pidió un análisis profundo porque «estamos ampliando mucho y profundizando poco». Resultado en `docs/ANALISIS_PROFUNDIDAD.md` (9 hallazgos medidos, 6 fases de trabajo y métricas de éxito). **Propuesta de Claude pendiente de aprobación:** congelar mecánicas nuevas hasta terminar la Fase A (ritmo de eventos) y la Fase B (mazo con intención); decidir la duración (semanas silenciosas, turno = mes o capítulos de 20 minutos).

## K. Fase A del análisis de profundidad (hecha el 25-nov-2026; el usuario dejó abierta la dirección de duración)
Instrucción del usuario: «dejaría la dirección del juego abierta, haría todo lo demás, puedes poner más secciones, bots también, que sea lo mejor posible sin límite de recursos».
- **Director de eventos** (`leyes.json` → `director_eventos`; `MotorEventos._director`): `peso_sorteo` pasó a ser peso relativo; máximo un evento aleatorio por semana; cooldown por evento (40 semanas), por familia (6) y entre decisiones (4). Resultado medido (`test_ritmo.gd`): de 4,14 a 0,77 eventos por semana; de ≈ 270 a ≈ 27 decisiones por mandato; 117 eventos distintos.
- **Partida rápida:** un toque desde el menú (última configuración o partido por defecto) lleva directo al mapa.
- **Rebalanceo por el nuevo ritmo:** al haber menos eventos el juego se volvió demasiado fácil (bot codicioso 100 % y 0 % de crisis); se ajustó `umbral_victoria_presidencial` 51 → 52 y `umbral_crisis_aprobacion` 12 → 24. Bots ahora: codicioso ≈ 90–98 % de elecciones y ≈ 14 % de crisis; azar ≈ 25 % de elecciones y crisis casi segura. Dificultad difícil: 7 de 24.
- Sigue abierta (decisión del usuario): duración del juego (semanas silenciosas, turno = mes o capítulos).

## L. Fase D: decisiones con peso (hecha el 25-nov-2026)
- **Riesgo** (`opciones[].riesgo {prob, efectos}`), **efecto a futuro** (`diferido {semanas, efectos, texto}`), **cadenas** (`cadena {evento, semanas}`: eventos de tipo `cadena` que aparecen semanas después) y **memoria** (`requiere {decision | relacion}`: eventos que solo salen si decidiste algo antes o si tu relación con un actor es muy baja o muy alta). Estado nuevo: `pendientes` (consecuencias programadas), guardado y replay exactos.
- Contenido: 11 eventos en cadena, 5 eventos con memoria y 23 opciones existentes con riesgo, efecto diferido o cadena. La pantalla de decisión rotula «con riesgo» y «con efecto a futuro»; tras decidir, el aviso dice qué cambió, si salió mal y cuándo habrá consecuencias.
- `EstadoSimulacion.exportar_resumen` pasó a `sim/resumen_estado.gd` (el archivo estaba al límite). La validación de datos comprueba riesgos, plazos, cadenas y memorias.

## M. Fases B y C (hechas el 25-nov-2026)
**Fase B, mazo con intención**
- `data/cartas_curadas.json` (180 cartas diseñadas a mano en `data/curadas/grupo_A|B|C.json`, escritas por subagentes y validadas con `tools/validar_curadas.py`): 13 categorías, con riesgo (≈ 28 %), efecto a futuro (≈ 40 %) y leyes (≈ 28 %); valor medio calibrado (≈ 0,98 por movimiento, frente a 0,87 de las cartas reales generadas).
- Mecánica nueva en cartas: `riesgo {prob, efectos}` y `diferido {semanas, texto, efectos}` (mismo modelo que las decisiones de eventos); la consecuencia diferida de una carta sale como aviso breve, no como pantalla completa. El panel de la carta rotula «con riesgo» y «efecto a futuro».
- Composición de la mano: al menos 2 cartas diseñadas (`leyes.json` → `mano.min_disenadas`).
**Fase C, gabinete con identidad**
- 3 candidatos por ministerio (75 en total; alias ficticios): cada uno con estilo (técnico, político, comunicador, negociador), ejecución, riesgo de escándalo, ahorro de costo, perfil ideológico y un rasgo. La pantalla de gabinete deja elegir uno por cargo; el relleno (equilibrado o máxima eficacia) elige por puntaje, incluida la afinidad con tu partido.
- Efectos reales: el **ministro titular** del área lleva cada carta (su ahorro de costo y su bono cuentan, y una fracción de su riesgo de escándalo); cada semana el estilo de los ministros y la afinidad ideológica media del gabinete mueven indicadores; con relación muy baja el ministro **renuncia** y asume el mejor candidato restante; con relación alta es **estrella** y rinde más. Las cuotas de coalición se guardan por ministerio.
**Bots y balance**
- El bot codicioso ahora valora riesgo y efectos a futuro, y no juega cartas que le hacen daño en gobierno. `umbral_crisis_aprobacion` 24 → 15. Resultado (24 partidas de gobierno): azar ≈ 50 % de caídas, codicioso ≈ 17–21 %, «completo» (con asesores, delegación y movimientos internos) 0 %.
- `test_carrera` verifica replay exacto de toda la carrera; `test_identidad` cubre candidatos, titular, renuncias y composición de la mano.

## N. Fase E: oposición con rival que gobierna (hecha el 25-nov-2026)
- Nuevo indicador `rival` (aprobación del gobierno rival, 0 a 100): parte en 55 («luna de miel»), camina con ruido hacia su media (42) y tus cartas pueden bajarla o subirla; en oposición el chip de Fiscal de la cabecera pasa a mostrar «Rival». Tu aprobación converge a un ancla que sube si el rival lo hace mal (`leyes.json` → `oposicion`).
- Contenido: 10 cartas más de oposición (denuncia a la Contraloría, primarias, gira, libro programático, afiliación, franja, centro de estudios, pacto de ley, filtración, movilización; con riesgo y efectos a futuro), `rival` en las existentes, y 10 eventos nuevos (reforma tributaria del gobierno, escándalo, acuerdo, ley de seguridad, reajuste, encuesta, liderazgo joven, candidatura única, crisis climática, debate televisivo).
- Al empezar una nueva campaña la aprobación vuelve a la base de tu partido más una pequeña herencia (`herencia_campana` 0,04) para que la segunda campaña no sea más fácil que la primera. Medido con bots: tras una oposición jugada, la segunda elección la gana ≈ 33 % el bot al azar y ≈ 97 % el codicioso.
- Sigue sin contrastarse el artículo 25 de la Constitución (la fuente oficial exige autenticación y no se intentó eludirla): la reelección permanece como mecánica ilustrativa hasta que el usuario aporte el texto o autorice otra fuente.

## O. Fase F, sensación de juego (primera parte, 25-nov-2026)
- **Sonido:** 8 efectos sintetizados por código (`tools/audio/generar_sonidos.py` → `game/audio/*.wav`, ≈ 114 KB, sin muestras de terceros: no requieren licencia): toque, jugar, éxito, alerta, evento, decisión, turno y error. `Feedback.sonar`.
- **Vibración** corta al jugar (más larga si sale mal o hay escándalo) y **números flotantes** con lo que cambió la carta.
- **Ajustes** (menú → Ajustes): sonido, vibración y animaciones, guardados en `user://ajustes.json`.
- El aviso (toast) pasó a su propio componente (`game/componentes/toast.gd`).
- Pendiente de esta fase: tamaño de letra y modo daltónico (el diseño fijo de 390×844 exige rehacer medidas), música de fondo, telemetría opcional (depende de U9).

## P. Bots y métricas (hecho el 25-nov-2026)
- Nuevas políticas de bot (`tests/bots.gd`): **humano** (casual: se salta ≈ 20 % de las semanas, hasta 3 cartas, decide bien el 70 % de las veces, no usa mecánicas avanzadas), **experto** (completo con gabinete de máxima eficacia y decisiones óptimas); todas las políticas no aleatorias eligen la opción de mayor valor esperado en los eventos (riesgo y efectos a futuro incluidos).
- `tests/informe_bots.gd` compara las seis políticas en 1.ª campaña, gobierno y carrera (2.ª elección tras oposición); con `--escribir` guarda `docs/INFORME_BOTS.md`. No está en la suite (tarda ≈ 4 min).
- Calibración final: `umbral_crisis_aprobacion` 12; en campañas posteriores a la primera el voto suma `peso_rival_voto × (42 − aprobación del rival)`; la herencia de aprobación entre periodos quedó en 0. Codicioso: ≈ 90 % de elecciones y ≈ 15 % de caídas; azar: ≈ 22 % y ≈ 60 %; humano: ≈ 70 % y ≈ 14 %.
- **CI**: desde el commit de la carrera política el paso «Validar datos y límites» fallaba (informe de alcanzabilidad: las cartas de oposición no dependen del gabinete) y por eso el resto de pruebas no corría en CI. Corregido en `8c25601`.


## Q. Director de eventos v2 (25-nov-2026, profundización del punto A pedida por el usuario)
- Probabilidad de evento por semana dinámica: 0,45 + 0,12 por cada semana de silencio sobre 2 (tope 0,9), todo en `data/leyes.json › director_eventos`.
- Estaciones (`meses` en cada evento: ×3 en su mes, ×0,2 fuera) y contexto (`contexto`: p. ej. fiscal < 45 multiplica ×2,5 los eventos de crisis fiscal).
- Decisiones: entre 8 y 12 por año (bajo el mínimo se piden siempre en gobierno; sobre el máximo, nunca).
- Eventos menores (aleatorios informativos con suma de efectos ≤ 3) se muestran como aviso breve, no como pantalla completa.
- Medido (`test_ritmo`): 0,49 eventos por semana (antes 0,76), 32 decisiones por mandato (meta 30–45 ✔), 101 eventos distintos, silencio máximo 11 semanas, máx. 11 decisiones en 52 semanas. Bots: codicioso 93 % elecciones / 11 % crisis; experto 93 % / 0 %.
- Pendiente: arranque con test ideológico rápido (3 preguntas); la dirección de duración sigue abierta (decisión del usuario).

- Ablación con el director v2 (25-nov, n=24, puntaje medio; completo 2.922): sin internos 1.974 (−32 %), sin delegación 2.000 (−32 %), sin mano continua 2.179 (−25 %, 9 % crisis), sin asesores 2.580 (−12 %), sin coalición 2.839 (−3 %) y sin bono por aprobación 2.836 (−3 %). Coalición y bono siguen inertes (decidir función real o retirar); delegación e internos dominan.

## R. Coalición y bono por aprobación con función real (25-nov-2026, el usuario: «dales función real»)
- Coalición: un aliado con satisfacción ≥ 75 potencia +12 % el efecto de las cartas de las categorías que pide; uno bajo 35 frena −10 % las que rechaza (tope ±30 %). Claves en `leyes.json › coalicion` (`bono_efecto_afin`, `penal_efecto_rechazada`, `tope_bono_efecto`); código en `MotorCoalicion.mult_carta`, aplicado en `MotorCartas`. El bot «completo» ahora entrega las cuotas que piden sus aliados.
- Bono por aprobación recalibrado: +1 movimiento por cada umbral 45, 55, 65, 75, 85 y 95 (antes 60+, que casi nunca se alcanzaba).
- Director: tras 8 semanas sin evento (`silencio_max`) el siguiente es seguro (silencio máximo medido 9).
- Ablación (n=16): sin coalición −7 % (antes −3 %), sin bono −5 % (antes −3 %), sin delegación −31 %, sin internos −22 %, sin asesores −14 %, sin mano continua −32 % con 43 % de crisis. Bots: codicioso 93 %/4 % crisis, completo y experto 93 %/0 %.

## S. Arranque corto: test ideológico rápido (25-nov-2026, cierre de la Fase A)
- Quien funda partido o va de independiente empieza con un test rápido de 3 preguntas (rol del Estado, regla fiscal, quórum de reformas) con sus deltas ×1,8 (`data/ideologia.json › rapido`), que llega a los mismos extremos que las 8. Un botón en la primera pregunta cambia al test completo y de vuelta. Quien entra a un partido existente sigue confirmando 3 posturas.
- Con la partida rápida (1 toque) y este test (3 toques + identidad) se cumple la meta de ≤ 3 toques de decisión antes del primer turno. Pruebas: `test_afiliacion` (extremos) y `test_ui_humo` (3 preguntas).

## T. Delegación e internos: medido y sin cambio (25-nov-2026)
- Prueba: costo de capital por delegar (1 y 2 puntos) y movimientos internos 3 → 2 (n=12, bot «completo»). El costo de capital no movió el puntaje (3.046 → 3.076): el capital sobra, así que no crea dilema. Sin delegación −30 % (2.896 → 2.035); sin internos −23 % (3.076 → 2.379).
- Lectura: ambos valen lo que aportan en acciones extra (2 cartas y 3 movimientos por semana sobre ~4 propios), no son jugadas «siempre mejores» en abstracto; la delegación ya tiene riesgo real (fallo, anulación, escándalo). Se revirtió el cambio para no sumar ruido; queda a revisar con jugadores reales (U1) antes de tocar.

## U. Escenas de debate y entrevista por rondas (25-nov-2026, PR-10 «Carrera por la presidencia como pantallas distintas»)
- Fuente: PR-10 (`docs/PROPUESTAS.md`, prioridad media-alta, autorizada por el usuario con la carrera política PR-12 ampliado). Sin arte nuevo y sin mecánica nueva en el motor: cada ronda es un evento con decisión del mismo día (mismo sistema de guardado y replay), con el campo `escena {nombre, ronda, rondas}` que la interfaz muestra en la cabecera («DEBATE PRESIDENCIAL FINAL · RONDA 2 DE 3»).
- Escenas: debate presidencial final (3 rondas: economía, seguridad, cierre), debate en radio (2), entrevista en televisión abierta (2) y debate parlamentario en oposición (2). Cada ronda mezcla tono (ataque, unidad, programa) con efectos pequeños; el total equivale a lo que daba el evento único.
- Prueba: `test_escenas` (3 rondas en orden el mismo día, decisión y replay exacto). Pendiente: audiencia/encuestas por ronda y retratos del moderador (arte, U7).

## V. Accesibilidad básica (25-nov-2026, Fase F del análisis de profundidad)
- Ajustes nuevos, desactivados por defecto: «Texto grande» (+15 % en las etiquetas con ajuste de línea; las cortas no cambian para no desbordar) y «Colores para daltonismo» (escala de aprobación azul–naranja de Okabe-Ito). La paleta congelada sigue siendo la predeterminada. Prueba: `test_accesibilidad`.
- Pendiente: probar el texto grande en cada pantalla con personas (U1) y música.

## W. Congreso y votaciones en oposición (25-nov-2026, PR-12 ampliado)
- Cuatro votaciones del gobierno rival por periodo de oposición (presupuesto, pensiones, reforma tributaria y seguridad; días 28, 70, 112 y 154). Cada una ofrece rechazar y buscar bloquear, negociar enmiendas o apoyar. Rechazar y negociar se sortean con la semilla: la probabilidad de que prospere tu postura = 0,10 + bancada propia y aliados del Senado / 50 + 0,004 × (cohesión − 50), entre 10 % y 85 % (`leyes.json › oposicion.congreso`). Si ganas, sube tu aprobación y baja la del rival; si pierdes, cuesta cohesión. La descripción del evento muestra la probabilidad.
- Se puede formar coalición también en oposición (más escaños = más probabilidad). En la pantalla de oposición la pestaña inferior pasa de «Gabinete» a «Coalición» y solo muestra las alianzas (sin gabinete ni internos).
- Prueba: `test_congreso_oposicion` (probabilidad según aliados y cohesión, votación en oposición y replay exacto).

## X. Optimización del motor por código (25-nov-2026, a pedido del usuario)
- Medido en un mandato completo (208 turnos, bot codicioso, escritorio): 7,6 → 5,5 ms por turno (−28 %); reproducir un guardado de mandato completo 1.500 → 850 ms (−43 %, el costo que se paga al cargar una partida; en un teléfono es varias veces mayor). Cargar los datos (~95 ms) y crear la partida (~80 ms) no cambian.
- Causas y arreglos (todos con resultado idéntico: las pruebas de oro no cambiaron): (1) `MotorGabinete.categorias_activas` reconstruía un diccionario con los 25 ministros por cada carta consultada (~4.000 veces al rearmar el mazo) → caché con firma del gabinete (la mano se rearma 170 → 62 ms por mandato); (2) el director de eventos comparaba cada candidato contra todo el catálogo para los descansos (O(n²)) → un solo recorrido de lo ocurrido por semana; relación con actores memorizada mientras elige; (3) índice de eventos por etapa e id; (4) `es_real` con caché y mazo de cartas reales con conjuntos en vez de búsquedas lineales.
- Lo que no hacía falta tocar: la interfaz (animaciones a 20 fps, rotación 3D solo si es visible) y el guardado (la huella de datos ya se calcula una vez).
- Prueba: `test_rendimiento` (tope de 40 ms por turno y 8 s de replay con margen para el CI, replay idéntico y caché que se invalida al cambiar el gabinete).
- **Segunda tanda de optimización (25-nov-2026, solo código):** (5) las cartas ligadas a un evento se buscaban recorriendo las ~2.000 cartas cada vez que ocurría un evento → índice por condición (`MotorMazo.ids_con_disponibilidad`): 4,8 → 3,5 ms por turno y reproducir un mandato 869 → 586 ms (acumulado desde el inicio: 7,6 → 3,5 ms por turno, −54 %, y 1.500 → 590 ms al cargar, −61 %); (6) la huella de los datos (≈350 ms en escritorio, ~2 s en un teléfono modesto) se calculaba en cada arranque → `Datos.huella_rapida` la guarda en disco con una clave (SHA-256 nativo de los archivos): los arranques siguientes de la misma versión no la recalculan, y si cambia un dato se recalcula. Resultados idénticos (pruebas de oro intactas); pruebas en `test_guardado`.
- Medido y sin cambios necesarios: armar el día completo tarda ~80 ms (45 ms la mano), el gabinete 73 ms, la cartera 46 ms, cada guardado ~5 ms (71 KB).
