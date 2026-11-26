# Registro de decisiones y consultas aceptadas

**Índice por tema** (cada letra es una sección de este archivo; lo que espera tu decisión está en `docs/DECISIONES_PENDIENTES.md`):
- **Reglas de trabajo y alcance:** A, E · **Propuestas y consultas:** B, C, F, G, H
- **Mapa, Metro y urbano:** D · **Carrera política y oposición:** I, N, W, Z (encuestas)
- **Eventos, decisiones y escenas:** K, L, Q, U · **Mazo, gabinete, coalición y movimientos:** M, R, T, AD (cartas de Estado)
- **Afiliación y arranque:** S · **Accesibilidad y sensación de juego:** O, V
- **Balance y bots:** P, AA (dificultad) · **Rendimiento y carga:** X, Y, AE
- **Calidad: pruebas, datos y validadores:** AB, AC, AE


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

## Y. Metas de rendimiento: turno < 1 ms y cargar un guardado < 100 ms (26-nov-2026, pedido del usuario)
- **Medido** (`test_rendimiento`, 10 partidas completas del bot, escritorio): turno del motor (cartas + cierre + amanecer + eventos) **0,75–0,81 ms** de media por turno (antes 7,6 ms al empezar la jornada de optimización); cargar un guardado de mandato completo **15 ms** con instantánea (antes 1.500 ms), y 175–200 ms si hay que reproducir el historial (sin instantánea).
- **Optimizaciones de simulación** (resultado idéntico, verificado con comparaciones contra la versión anterior en el director de eventos y en el relleno del gabinete): índices de cartas y eventos precalculados al cargar los datos y compartidos entre partidas (`IndicesCartas`); grafo urbano y cartera SECTRA armados al primer uso (la creación de una partida pasó de ~80 a ~10 ms); relleno de gabinete 10 → 1,2 ms; director de eventos sin recorridos O(n²) ni historial reconstruido cada semana; caché de gabinete (categorías, titulares, identidad), contexto de disponibilidad, una sola resolución de la referencia débil por llamada (`m` cuesta ~0,5 µs), aprobación regional en una pasada y constantes de efectos leídas una vez.
- **Cambio de comportamiento (intencional):** las cartas reales del mazo ahora se sortean probando cartas al azar hasta juntar las necesarias (mismo resultado en distribución que mezclar las ~1.700, ~25 veces más rápido). Cambia la secuencia aleatoria: se regeneraron las tres pruebas de oro. Bots tras el cambio (n=30): completo y experto 97 % de elecciones con 0 % de crisis; codicioso 97 % / 7 %.
- **Instantánea de carga (`sim/instantanea.gd`, nuevo, necesita tu visto bueno):** ni optimizando todo el código se llega a < 100 ms reproduciendo ~1.300 entradas en GDScript, así que al cerrar cada semana y al pasar la app a segundo plano se deja `user://guardado.cache` (estado completo comprimido, ~50 KB, ~10 ms). **El guardado sigue siendo el de siempre (semilla + partido + historial) y es la única fuente de verdad:** la instantánea solo se usa si el SHA-256 del archivo de guardado y la huella de los datos coinciden con los que tenía al tomarse; si no (jugaste algo después, otra versión de los datos, archivo dañado) se ignora y se reproduce el historial, y se renueva. `test_instantanea` comprueba, en campaña y gobierno, que restaurar da el mismo estado que reproducir y que ambas siguen igual 12 turnos después; `test_carga_rapida` prueba el flujo de la interfaz (válida, vieja y dañada). La regla del proyecto dice «solo se guarda semilla, partido e historial»: esto la matiza (hay un archivo de caché desechable); si prefieres mantenerla al pie de la letra, se borra `instantanea.gd` y la carga vuelve a 175–200 ms.
- Límites de los tests (con margen para el CI): turno medio < 1,0 ms y peor < 2,0 ms; cargar con instantánea < 100 ms de media y < 160 ms en el peor caso; reproducir el historial < 400 ms.

## Z. Encuestas de campaña y oposición (26-nov-2026, análisis de profundidad H7 / PR-10)
- Cada semana de campaña y de oposición se registra una encuesta en `estado.encuestas` (máx. 12, la más reciente al final; se limpia al abrir cada periodo): `{semana, turno, etapa, intencion, margen, umbral, rival, regiones:[{id, valor} × 3 más débiles]}`. `intencion` es lo que votaría hoy (aprobación, menos la penalización por no comprometerte con 2 promesas, más el efecto del rival en campañas posteriores) con un error de muestreo que baja de 4,0 a 1,5 puntos (`leyes.json › encuestas`). `umbral` solo en campaña; `rival` en oposición y campañas posteriores. El error sale de un hash de (semilla, semana, etapa): no usa el azar de la partida, no cambia ninguna otra secuencia y se rehace al reproducir. Las pruebas de oro no cambiaron.
- Código: `sim/encuestas.gd` (llamado al fijar los movimientos del amanecer). Prueba: `test_encuestas`. La presentación (gráfico/ficha) es de la sesión «Diseño visual». Pendiente: audiencia por debate (hoy solo datos; sin efecto sobre el balance hasta decidirlo).
- Encuestas (ajuste del mismo día): se registra una encuesta más al cerrar la última semana de campaña, para que la última antes de votar refleje la campaña ya terminada (sin ella iba una semana atrasada y fallaba por hasta 4,5 puntos). `test_encuestas` comprueba en 10 partidas (bots «codicioso» y «azar») que la encuesta final queda a menos de margen + ruido de la elección real y que su umbral es el de la elección.
- Encuestas: una sola por semana también con segunda vuelta (la del amanecer de la 2ª vuelta reemplaza a la de «antes de votar» de la misma semana; hallazgo de «Búsqueda infinita de fallas»; `test_encuestas` recorre partidas con balotaje). Nueva `test_sin_atascos`: en 12 partidas de 4 políticas de bot a lo largo de hasta 4 periodos de la carrera (4.584 turnos de campaña, gobierno y oposición) siempre hay mano, movimientos y una carta jugable al empezar el turno, y la partida avanza.
- **Limpieza de duplicados en `data/` (26-nov-2026):** no hay ids repetidos en ningún catálogo. Se retiraron tres contenidos que repetían a otro más rico: los eventos `evt_baja_cobre` y `evt_incendios` (informativos) por sus versiones con decisión `evt_ext_cobre` y `evt_ext_incendio` (mismo título; podían salir los dos), y la carta `des_zonas_extremas` por `cur_descentralizacion_zonas_extremas`. Ninguno tenía referencias. Las pruebas de oro se regeneraron (cambia el conjunto sorteable). Los títulos repetidos que quedan son intencionales (eventos anuales: presupuestos, fiestas patrias; rondas «Réplica» de debates distintos).

## AA. Medición de dificultad con bots (26-nov-2026; observación de «Búsqueda infinita de fallas», sin cambio de datos)
- 80 partidas por combinación sobre main (gana la elección / cae en crisis / completa el mandato): **fácil** 100 % para todos salvo el azar en crisis (25 %); **normal** azar 38 %, humano 89 %, codicioso 96 %, completo 96 % (0 % de crisis); **difícil** azar 3 %, humano 23 %, codicioso 48 %, completo 48 %.
- Lectura: de normal a difícil hay un **escalón**, no una rampa: difícil resta 3,5 de aprobación inicial **y** sube el umbral 2,2 (≈ 5,7 puntos juntos) y la elección se decide con un ruido de solo ±2, así que quien juega bien gana casi siempre en normal y apenas la mitad en difícil. Probé dos remedios y **no los apliqué**: umbral de normal +0,7 (humano 85 %, codicioso y completo 96 % igual) y ruido de elección ±4 (sin efecto en normal: 96 %; difícil 52 %). Con el margen actual de normal, ninguno de los dos mueve a quien juega bien.
- Para decidir con datos de personas (U1): ¿qué tasa de victoria queremos en normal para un jugador competente (hoy los bots que juegan bien ganan ≈ 96 %)? Opciones: subir `aprobacion_inicial` negativa de normal (p. ej. −1,5), suavizar difícil (−2,0 y umbral +1,5) o añadir un nivel intermedio. Sin datos de personas no lo toco: la dificultad «correcta» depende de cómo juegan los humanos, que los bots no reproducen.

## AB. Calidad de pruebas y datos (26-nov-2026, cola de la coordinadora)
- **Director de eventos** movido a `sim/director_eventos.gd` (`motor_eventos.gd` baja de 444 a 280 líneas, lejos del límite); la secuencia de eventos de 6 partidas completas con carrera es idéntica antes y después (comparación por huella del texto).
- **Replay con guardados intermedios** (`test_replay_intermedio`): 54 guardados, a mitad de semana y al abrirla, en 3 partidas completas de 208 turnos con decisiones; todos reproducen la misma huella. **Sin atascos** ampliada a 3 dificultades × 3 afiliaciones (18 partidas, 5.362 turnos). **Cobertura** (`test_cobertura`): cada una de las 12 áreas de ministerio tiene ≥ 37 cartas disponibles en cada año del mandato (≥ 10 exigido); comité (4) y estado (9) son pequeñas por diseño y se exige ≥ 3.
- **Números de balance fuera del código:** `tools/check_constantes.py` (en el CI) revisa los literales numéricos de `sim/` contra `tools/constantes_aceptadas.json` (50 aceptados con motivo: redondeos, algoritmos, valores por defecto, escalas 0-100). Encontró y movió a `data/` dos que vivían en el código: la fórmula de escaños de un partido nuevo (`ideologia.json › escanos`) y los pesos del ministro titular (`leyes.json › gabinete.titular`). Resultados idénticos (oros intactos).

## AC. Validación de datos, perfil de turnos y análisis de contenido (26-nov-2026, cola de la coordinadora)
- **Validadores endurecidos (en el CI):** `tools/validate_referencias.py` (fuentes de cartas, eventos y metas; propuestas del Comité, eventos y metas citados por la disponibilidad; cadenas y decisiones requeridas; regiones; probabilidades y pesos; 3 candidatos por ministerio; ministerios que piden los partidos; escaños) y `tools/validate_tipos.py` (esqueleto de 591 rutas de `leyes.json`: un dato borrado, nulo o de otro tipo se detecta con su ruta). `tools/test_validate.py` prueba 19 datos rotos a propósito y 1.514 mutaciones de `leyes.json`: 0 sin detectar. El motor no atrapa excepciones (un dato roto se vería como error de script en plena partida); por eso la defensa está en la validación previa, no en el motor.
- **Perfil de 208 semanas** (`tests/perfil_turnos.gd`, 6 partidas, 1.248 cierres de turno): media 0,33 ms, p95 0,52, p99 1,53, máximo 1,99 ms; **ningún pico ≥ 3 ms**. Los picos de 1,5–2 ms son los turnos en que se rearma el mazo (`reponer`) o termina una obra con votación.
- **Instantáneas de versión anterior:** `test_instantanea` comprueba que una instantánea con otro número de versión o sin los campos nuevos se descarta y se reproduce el historial con el mismo estado (los guardados antiguos con otra huella de datos se descartan con aviso, como ya probaba `test_guardado_danado`).
- **Congreso:** `test_congreso_invariantes` (9 combinaciones de dificultad × afiliación, coalición de 3 aliados con satisfacción 0, 50 y 100, 675 votaciones): los bloques no son negativos, los mínimos de cada ley caben en su cámara, a favor + abstención + en contra suman la cámara y una ley se aprueba exactamente al alcanzar el mínimo en las dos.
- **Cartas muertas** (`tests/analisis_cartas_muertas.gd`; 16 partidas del bot «humano» en difícil): se juega el 80 % de las apariciones de cartas curadas, 65 % de las diseñadas y 34 % de las reales. Por área, la de **Estado** casi no se juega (7 %): las nacionalizaciones y expropiaciones cuestan 6–7 de fiscal por +1 a +3 de aprobación, así que un bot que maximiza valor las descarta siempre; son opciones ideológicas de alto riesgo y se pueden dejar así, o ligarse a la ideología del partido (decisión de diseño, no se hizo). Las obras (hospital, riego, regeneración) se juegan menos porque su aprobación llega tarde. Sin cartas inalcanzables por error.
- **Calendario de eventos:** de 54 eventos programados de gobierno, 38 caen en el año 1 (los hitos reales del calendario 2026) y solo 5–6 por año en los años 2 a 4, con un hueco máximo de 27 semanas entre programados; esos huecos los llena el director (silencio máximo medido 9–11 semanas). Si se quisiera más pulso de calendario en los años 2 a 4, faltan eventos anuales recurrentes (cuenta pública, temporada de incendios, receso legislativo): contenido nuevo, pendiente de autorización.

## AD. Cartas del área «Estado»: análisis y opciones (26-nov-2026; propuesta sin aplicar, decide el usuario)
- **Qué pasa:** las 9 cartas de Estado (3 empresas públicas, 3 privatizaciones, 3 expropiaciones) se juegan el 7 % de las veces que aparecen (bot «humano», difícil), contra 34-94 % de las demás áreas. Con el valor por movimiento que usan los bots (aprobación 1, capital 0,5, cohesión 0,4, fiscal 0,6, riesgo −0,5), la mediana del resto de las cartas es **+0,70** (p25 +0,25) y las de Estado van de **−2,80 a 0,00**: ninguna es positiva.

| carta | costo | valor/mov | por qué |
|---|---|---|---|
| expropiar activos | 3 | −2,80 | −7 fiscal, −4 capital, −3 cohesión, +4 riesgo por +1 aprobación |
| expropiar ferrocarril | 3 | −2,40 | pierde aprobación (−2) además de fiscal y capital |
| expropiar suelo para vivienda | 3 | −1,57 | +4.000 viviendas casi no compensan −4 fiscal y −3 capital |
| empresa pública del litio | 3 | −1,40 | −6 fiscal y −3 capital por +2 aprobación |
| empresa de conectividad | 3 | −0,90 | −5 fiscal |
| empresa de farmacias | 2 | −0,70 | la mejor de las que gastan: +3 aprobación |
| privatizar sanitarias | 3 | −0,50 | +7 fiscal, pero −3 aprobación y −3 cohesión |
| privatizar energía | 3 | −0,23 | +6 fiscal, −2 aprobación |
| vender terrenos fiscales | 2 | 0,00 | +4 fiscal, costos menores |

- **Lectura:** son cartas de «apuesta ideológica» pensadas para pagar un costo político hoy (capital, cohesión, fiscal) a cambio de algo a futuro, pero **no tienen ningún beneficio a futuro** en los datos: el motor ya soporta efectos diferidos (`diferido`) y riesgo (`riesgo`), y las cartas curadas los usan; estas no. Un jugador humano que busca una identidad (nacionalizar el litio, privatizar sanitarias) las verá siempre peores que la alternativa sin costo.
- **Opciones (todas son cambios de datos, sin mecánicas nuevas):**
  1. **Dejarlas** como opciones de alto costo para quien quiera jugar ideológicamente (el área existe «porque Chile discute esto», no para ganar puntos). Riesgo: cartas que casi nadie juega.
  2. **Dar beneficios diferidos** con el campo `diferido` que ya existe: empresas públicas y expropiaciones devuelven fiscal y aprobación a las 26-52 semanas (p. ej. litio: +4 fiscal y +2 aprobación a las 40 semanas; farmacias: +2 aprobación a las 12 semanas; conectividad: +3 cohesión a las 26), y las privatizaciones devuelven aprobación si salen bien (`riesgo` 25-30 % de perder más). Con eso el valor por movimiento de las mejores pasaría de −0,7 a ≈ +0,3 sin volverlas obvias.
  3. **Bajar sus costos** de fiscal a la mitad: las vuelve atractivas de inmediato, pero rompe la señal de que son decisiones de alto costo.
  4. **Ligarlas a la ideología** del partido (bonus o castigo según el eje económico): es la solución natural, pero es una **mecánica nueva** y necesita tu autorización (alcance congelado).
- **Recomendación:** opción 2 para las 6 de menor costo (empresas públicas y privatizaciones) y dejar las 3 expropiaciones como están (son las de mayor riesgo político). Se mide con `tests/analisis_cartas_muertas.gd` y los bots antes y después.

## AE. Arranque, ciclo de vida, determinismo y tamaño (26-nov-2026, cola 3 de la coordinadora)
- **Tiempos de arranque** (escritorio con `xvfb` y render por software; en un teléfono serán mayores): cargar la escena principal ≈ 350-390 ms, `_ready` (datos + huella desde disco + menú) ≈ 165 ms, partida nueva hasta ver el mapa ≈ 170-185 ms, **continuar una partida ≈ 60-95 ms** (con instantánea o reproduciendo cinco semanas). Arranque en frío hasta el menú ≈ 0,5 s. El costo dominante es cargar recursos de la escena (fuentes y texturas), no la simulación.
- **Ciclo de vida de Android** (`test_carga_rapida`): pausa a mitad de semana (cartas jugadas, semana sin cerrar) → el sistema mata la app → reanudar da el mismo estado; cierre abrupto sin pausa tras jugar más cartas → se recupera hasta la última acción guardada; un `guardado.json.tmp` a medias (escritura interrumpida) no daña el guardado anterior.
- **Determinismo entre plataformas** (`test_determinismo`: 4 carreras completas con campaña, gobierno, oposición y reelección, ejecutadas dos veces con datos cargados dos veces: huellas idénticas). Revisión del código de `sim/`: no hay seno, coseno, potencias ni exponenciales (solo raíz cuadrada, exacta en IEEE 754); cada operación de GDScript se evalúa por separado (no hay multiplicar-y-sumar fusionado como en C++ compilado para ARM); el azar es el PCG de Godot (igual en todas las plataformas); `hash()` solo se usa como llave de cachés (nunca decide un resultado); el orden de los diccionarios es el de inserción. Las huellas de las pruebas de oro coinciden entre el CI (Linux) y esta máquina y entre Godot 4.3 y 4.7.2. **Falta comprobarlo en un teléfono real**: el informe de `test_determinismo` imprime las huellas de 4 semillas para compararlas en el dispositivo con la misma versión de los datos.
- **Presupuesto del APK** (`tools/check_presupuesto.py`, en el CI): contenido que entra al paquete ≈ 11 MB sin comprimir (datos 7 MB, juego 4 MB) + ≈ 40 MB estimados de motor ≈ 51 MB de 150 MB (34 %); el último APK de depuración compilado mide 30,8 MB. Aviso desde el 60 %, falla desde el 90 %.
- **Textos de `data/`** (`tools/validar_textos.py`, en el CI): sin emojis, sin espacios dobles, «…» en vez de tres puntos, tildes en las palabras comunes y largos máximos (título 60, descripción 260, opción 80). Encontró y corrigió tres nombres de actor sin tilde («Educacion», «Energia», «Economia») y tres títulos de eventos de ministerio demasiado largos (61-69 caracteres).
- **Comando único:** `tools/run_all_tests.sh [godot]` ejecuta lo mismo que el CI (validadores, todas las `tests/test_*.gd` y el fuzz de 60 partidas): ≈ 2,5 min, todo en verde.

## AF. Ritmo, cohesión y Corrector (26-nov-2026, cola 4 de la coordinadora)
- **Ritmo con el bot «humano»** (`tests/analisis_ritmo_decisiones.gd`, 78 partidas con gobierno entre las 3 afiliaciones): 63 % de las semanas no traen evento, 18 % traen una decisión, 10 % la mano no tiene ninguna carta buena y las semanas «sin nada interesante» (sin evento y con ≤ 1 carta buena) suben del 9 % en el año 1 al 29 % en el año 4. Aprobación mediana 41 → 35 → 29 → 32 (el desgaste hace su trabajo); capital 84 → 55 → 27 → 38 (se gasta bien).
- **Hallazgo: la cohesión estaba muerta.** Mediana 100 y p10 96-99 en los cuatro años, es decir, saturada el 98 % de las semanas: las cartas que cuestan cohesión eran gratis y las que la dan no valían nada. No dependía de la coalición ni de la regeneración (con +0,2, +0,1 o 0 daba lo mismo): entra más de +1 por semana desde las cartas, aliados y gabinete, y no tenía desgaste. Se midió con 30 partidas por variante: la cohesión final se mantiene en 100 hasta una regeneración de −1,0/semana y cae a mediana 47 con −2,0; **−1,85 da mediana 76 (p10 54, p90 89)** sin cambiar victorias (90 %), crisis (3 %), leyes rechazadas (5,4 % contra 5,8 %) ni puntaje (1.290 contra 1.284).
- **Cambio aplicado (solo dato):** `dinamica.regen_cohesion_semanal` 0,2 → **−1,85** (es un desgaste semanal; el nombre queda por compatibilidad con el esqueleto de `leyes.json`). Ahora la cohesión es un recurso que hay que cuidar: el bot codicioso, que la ignora, sube de ≈ 5 % a ≈ 17 % de crisis (n=30; los bots que la cuidan siguen en 0 %); `test_balance` sigue exigiendo < 20 %. Se regeneraron las pruebas de oro y las huellas de `tests/oro/huellas.json`. Para revertir, volver a 0,2.
- **Corrector de realismo (CLAUDE.md §4.6), cobertura real:** (a) los 41 rechazos del motor ya llevan texto propio, 22 de ellos con indicación de qué hacer y 19 que solo informan porque no hay otra salida (datos inválidos o estados ya cumplidos); (b) **el corrector legal (versión viable o por tramos) existe solo en 7 de 1.964 cartas** (5 propuestas del Comité y 2 de vivienda): las 527 obras y las 1.117 leyes no lo usan; (c) cuando una ley es rechazada (5 % de 1.380 votaciones con el bot «humano») o el Tribunal Constitucional la tumba (recurso en el 23 %), se pierde capital y la carta, sin ofrecer una versión por tramos. Ofrecerla («reingresar una versión reducida») sería una mecánica nueva: queda en `DECISIONES_PENDIENTES.md` como D14.

## AG. Auditoría de fuentes y licencias (26-nov-2026, cola 4 de la coordinadora)
- `data/fuentes.json` está estructuralmente sano (sin duplicados, https, sin fechas futuras ni vencidas); los hallazgos y los 13 ids sin cita viva están en `docs/LICENCIAS.md`. No se borró nada.
- Nuevo `docs/LICENCIAS.md`: tabla de todo lo que entra al APK con su licencia y su estado. Pendientes del usuario (no decididos): licencia de uso comercial de las imágenes con IA, licencia del código, autorización de SECTRA, licencia del GeoJSON de regiones y publicar la base ODbL derivada.

## AH. Auditoría de alias satíricos y nombres reales (26-nov-2026, cola 4)
Regla (CLAUDE.md §2): políticos reales con alias satíricos, personajes de pantalla ficticios, cifras ilustrativas rotuladas. Se buscaron apellidos de políticos reales (Kast, Boric, Jara, Matthei, Kaiser, Parisi, Bachelet, Piñera, Jadue, Sichel, Tohá, Marcel, Montes, etc.) en todos los campos de texto de `data/` (menos URL y fuente), `game/`, `sim/` y `tests/`.
- **Lo que ve el jugador no nombra a políticos reales.** Ministros (75), asesores (10), partidos de la coalición (15), vecinos y los 38 eventos de `juego_eventos_reales.json` usan alias («El Vigía del Pasillo», «La Calculadora Ortodoxa», «Movimiento Laborista Reformista») o describen el hecho sin nombrar a la persona. Cero infracciones en `game/` y `sim/`.
- **Nombres reales presentes solo en archivos de investigación que el juego no carga:** `data/eventos_reales.json` (8 descripciones con Piñera, Jara, Kast, Boric, Parisi, Kaiser, Matthei), `data/partidos/partidos_reales.json` y `partidos_juego.json` (notas con fuente), y `data/bcn/`. El juego solo carga `juego_eventos_reales.json`, generado por `tools/generar_eventos.py`, que ya los elimina; `tools/validar_textos.py` ahora falla (y corre en el CI) si un texto de `data/` que ve el jugador nombra a un político real. Se deja asi, con riesgo bajo.
- **Coincidencias que no son personas:** «Los Lagos» (región), «Villa Frei» y «CESFAM Eduardo Frei Montalva» (nombres oficiales de estación y centro de salud), «Escuela Salvador Allende», «Avenida Ricardo Lagos», «Consultorio Ossandón» y «Pedro Lagos Marchant»: son nombres oficiales de obras y lugares reales con fuente, no sátira política. Se mantienen; si el usuario prefiere evitarlos en pantalla, hay 6 cartas de obra afectadas (decisión suya, sin cambio).
- Cifras: las ilustrativas llevan `es_ilustrativa` en `fuentes.json` y la nota «ilustrativo» en los textos del juego.

## AI. Reloj único en el ciclo 2 y CI más estricto (26-nov-2026, hallazgos de «Búsqueda infinita de fallas»)
- **Bug corregido:** desde el ciclo 2, al ganar la elección el gobierno arrancaba 56 días antes de la fecha de la elección (`resolver_eleccion` no sumaba a `dias_carrera` las semanas de campaña jugadas; la fecha de pantalla retrocedía y `semana_abs` repetía semanas). Ahora `dias_carrera += (turno_actual - 1) · dias_por_turno` en la rama «electo» si `ciclo > 1`. El ciclo 1 no cambia (su transición dic-2025 a mar-2026 no se juega). Prueba nueva `tests/test_calendario_reloj.gd` (falla antes: 22 fallos; pasa después). Se regeneró `tests/oro/huellas.json` (solo cambian carreras con ciclo ≥ 2); los oros de 4 semanas, 30 días y partida completa no cambian.
- **CI:** cada prueba corre con `timeout 300`, guarda su salida y falla si trae «SCRIPT ERROR», «Parse Error» o «Could not find type» (una clase sin importar devolvía código 0 sin ejecutar la prueba). Igual en `tools/run_all_tests.sh`.

## AJ. Pruebas negativas y unitarias directas (26-nov-2026, tarea 5 de la cola 4 y hallazgo 3 de «Búsqueda infinita de fallas»)
- `tests/test_rechazos_legales.gd`: índice inválido, ministro inexistente o fuera del gabinete, región inexistente, sin movimientos, delegación sobre el tope, carta única ya ejecutada y partida terminada devuelven su razón y no cambian la huella ni agregan entradas al guardado.
- `tests/test_puntaje_tc.gd`: fórmula exacta de `calcular_puntaje` con los pesos de `leyes.json`; `resolver_tc` (tipos que no van al TC, éxito 0 y 1, frecuencia de recurso por tipo) y `corregir` (ratio, modo por tramos, piso `ratio_obra_min`).
