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
| PR-10 | U + C | Campaña con entrevistas y decisiones. | Hecho en versión de eventos (4 hitos). Falta: pantallas propias de debate/entrevista | `0706883` |
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
