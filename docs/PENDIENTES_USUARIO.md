# Pendientes (actualizado el 25-nov-2026)

> Todo lo aceptado (del usuario y de Claude) está registrado en `docs/DECISIONES.md`.

Este archivo lo mantiene Claude. Lo que depende del usuario queda en «Necesito del usuario» y **no detiene** el trabajo: se sigue con la sección «Para hacer yo».

## Necesito del usuario (no bloquea nada de lo demás)
| # | Qué | Por qué lo necesito | Estado |
|---|---|---|---|
| U1 | Probar el APK en el teléfono: fps, RAM, toques (zoom, arrastre y pulsación larga del mapa), teclado en los campos de nombre | Es lo único que no se puede medir aquí (hitos de las fases 1 y 2) | Pendiente |
| U2 | Tamaño del gabinete | DECIDIDO el 25-nov-2026: el de la vida real (25 ministerios) con relleno automático | Hecho |
| U3 | Decidir si quien no promete nada en campaña recibe legado completo y si una ley de 7 días debe resolverse en 1 cierre o en 2 | Reglas de diseño (hoy: legado completo y 2 cierres) | Pendiente |
| U4 | Revisión legal por un abogado chileno: alias satíricos de políticos reales, nombres de partidos, imágenes y textos, aviso de ficción | Mayor riesgo de bloqueo para publicar (informe de mercado) | Pendiente |
| U5 | Confirmar con Metro S.A. (metro.cl bloquea consultas automáticas): colores oficiales de L7, L8 y L9 y nombres definitivos de sus estaciones | Hoy salen de OSM y Wikipedia/Wikidata, sin confirmar | Pendiente |
| U6 | Licencias de uso comercial del arte: Gemini, Canva, Figma, Copernicus/OSM (atribuciones) | No se publica arte sin licencia confirmada | Pendiente |
| U7 | Generar en Gemini las 13 categorías y la portada vertical cuando renueve el cupo (prompts en `docs/ARTE_PROMPTS.md`) | Estilo mezclado entre el arte antiguo y el nuevo | Pendiente (cupo) |
| U8 | `main` ya existe (creada el 24-nov-2026 con todo el trabajo); falta ponerla como rama por defecto en GitHub (Settings → Branches) y decidir si se protege | Desde aquí no puedo cambiar ajustes del repositorio | Pendiente |
| U9 | Elegir modelo de monetización (premium barato, anuncios recompensados, packs de escenarios) | Condiciona qué datos se recolectan (Ley 21.719) y la ficha de Play | Pendiente |
| U10 | Google Play, prueba cerrada con 12+ testers y keystore de release | En pausa por instrucción del usuario | Pausado |

## Para hacer yo (actualizado tras tu «hazlo todo»)
Hecho el 24-nov-2026: fuzzing en CI, mapa de Chile con caché, reglas de disponibilidad en un solo lugar, títulos cortos (P11), cartera con buscador, PR-01 (dificultad, afiliación, «como la última vez»), PR-05 (rellenar gabinete), PR-06c (continente y vecinos vivos), consecuencias visibles por carta, finales variados (9 epílogos) y hitos del mandato en la pantalla de fin. El tutorial ya es corto (5 pasos).
En curso, en este orden: PR-09 estadísticas de cartas → PR-08 ministros con peticiones → PR-02 arrastrar cartas al mapa → PR-07 eventos externos → PR-11/12/13 cierre, reelección y oposición → PR-14 → PR-17 balas de plata → PR-18 presupuesto → PR-19 a PR-23 → PR-24 marco de actores. PR-10 (campaña narrativa), PR-15 y PR-16 (apariencia y habilidades) después. Medición D1/D7 espera tu decisión U9.

## PR-01 Dificultad (implementada con valores por defecto, ajustable)
- Fuente: `docs/PROPUESTAS.md` PR-01; presets en `data/leyes.json` bloque `dificultad` (umbral_delta, aprobacion_inicial, desgaste). Selector en la pantalla de fundación del partido; se guarda en `partido["dificultad"]` y se reproduce.
- Calibración vs bot codicioso (24 semillas, elección ganada): fácil 24, normal 18, difícil 12 (`tests/test_dificultad.gd`). Un humano suele ser peor que el bot: confirmar con prueba real (U1).
- Pendiente de decidir (usuario): beneficio de jugar "independiente" y afiliación a partido existente (siguiente paso de PR-01).
- Mapa de Chile: geometría triangulada una sola vez por ejecución (cache estática en MapaChile); resuelto.
- Balance fuera del código: fórmulas de indicadores iniciales del partido movidas a data/ideologia.json (bloque inicio). PR-05 sigue esperando tu «hazlo» (y la decisión U2).

## PR-01 Afiliación (implementada con valores por defecto, ajustable en `data/leyes.json` bloque `afiliacion`)
- Tres caminos: fundar partido propio (flujo anterior), candidatura independiente (+4 aprobación, bancada ×0,6, mínimo 4) o entrar a un partido ficticio (hereda ideología desplazada por 3 posturas, bancada = escaños del Senado ×2, cohesión +5; ese partido deja de ser aliado). `test_afiliacion.gd`.
- Falta decidir (usuario): si el partido existente debe «pedir poder y castigar» (mecánica nueva, no implementada), el beneficio definitivo del independiente, y balance 3×3 con bots por afiliación (hoy solo la dificultad está calibrada). «Continuar como la última vez»: hecho (botón «Nueva partida como la última vez» en el menú; guarda el último partido fundado en user://ultima_config.json).
- Interfaz: ya no muestra conteos ni números de página internos (cartera, gabinete, SECTRA) ni el número de boletín.

## PR-05 Rellenar el gabinete (hecho el 24-nov-2026 tras tu «hazlo»)
- Botones «Equilibrado» y «Máxima eficacia» en la pantalla de gabinete: completan solo los vacíos, nunca pisan lo escogido, explican el porqué y se pueden deshacer. Pesos en `data/leyes.json` → `gabinete.relleno`. Prueba en `test_gabinete.gd`.
- Pendiente: que «Máxima eficacia» cueste capital político o cohesión (hoy solo cambia el criterio), y los candidatos recreados desde personas reales (solo con alias/sobrenombre y tras revisión legal; ver PR-05b): no se implementó porque requiere investigación de fuentes y revisión de un abogado (U4).

## PR-06c Mapa del continente (primera etapa hecha el 24-nov-2026 tras tu «hazlo»)
- Hecho: botón «Continente» en la pantalla Nación: Sudamérica en 2D (Natural Earth 1:50m, dominio público, `tools/geo/sudamerica.py` → `data/geo/sudamerica.json`, 19 KB), países coloreados por relación con Chile (`data/vecinos.json`, cifras ilustrativas) y tres potencias como íconos (EE. UU., China, UE). Toca un país para ver su relación. Malvinas no se dibuja; aviso «mapa ilustrativo»; fuente y crédito registrados.
- Pendiente (requiere balance y tu confirmación de las dos recomendaciones): vecinos «vivos» (crisis y elecciones propias con contagio a Chile, con semilla), cartas de política exterior arrastradas sobre un país, líneas/pines de proyectos internacionales, 2,5D (relieve y paralaje). Tocar el motor cambia los hashes de oro y exige recalibrar; por eso va como etapa aparte.
- Revisión legal (U4): fronteras y reclamos del mapa.

## PR-06c segunda etapa: vecinos «vivos» (hecha el 24-nov-2026)
- 8 eventos de vecinos (crisis cambiaria y acuerdo energético con Argentina, tensión por el gas con Bolivia, elecciones en Perú, migración desde Venezuela, auge comercial con Brasil, cumbre del Pacífico con Colombia, acuerdo con Uruguay) en `data/eventos.json` con campos `pais` y `relacion_delta`; salen por el sorteo con semilla y afectan a Chile con la misma maquinaria de eventos. La relación que muestra el mapa del continente = base + eventos ocurridos en tu partida (`MotorEventos.relacion_exterior`, sin estado nuevo). Los negativos pesan menos (balance: crisis del bot activo 6,7 %).
- Los hashes de las pruebas de oro cambiaron a propósito (nuevos eventos en el sorteo).
- Sigue pendiente: cartas de política exterior arrastradas a un país, pines de proyectos internacionales y 2,5D; las elecciones propias de cada vecino con ventana fija.

## Ideas del análisis de mercado (autorizadas con tu «todo quiero todo»)
- Consecuencia visible por carta: HECHO. Al jugar una carta el aviso muestra lo que cambió («Aprob. +2 · Capital −3»). `Barras.resumen_cambios`.
- Siguientes (en este orden, una por ciclo): resumen de sesión con hitos, finales variados, tutorial corto, medición D1/D7 (esta última exige tu decisión de monetización/datos, U9, y la Ley 21.719).

## PR-09 Estadísticas de las cartas (primera etapa, 24-nov-2026)
- Hecho: el panel de detalle de la carta muestra su impacto (pequeño, mediano o grande; umbrales en `data/leyes.json` → `impacto_carta`) y si pasa por el Congreso (`FichaCarta`).
- Pendiente (más grande, requiere rebalancear con bots): efectos diferenciados por sector y tipo de carta, efectos a futuro («sube cohesión hoy, baja fiscal en 8 semanas»), texto de sabor por carta. Las 1.685 cartas reales se generan por plantilla; cambiar la plantilla en `tools/` y regenerar es el camino.

## PR-07 y PR-08: eventos con decisión (primera etapa, 25-nov-2026)
- Hecho: mecánica de eventos con opciones (`opciones` en `data/eventos.json`): el jugador elige entre 2-3 respuestas sin gastar movimientos; los efectos dependen de la respuesta; queda registrado (entrada `decision`, `estado.decisiones`) y se reproduce. 4 eventos externos (terremoto, caída del cobre, incendios, paro de camioneros) y 6 peticiones de ministerios clave (Hacienda, Salud, Educación, Seguridad, Obras, Energía). Si no respondes, el evento no aplica efectos. `test_decisiones.gd`. Los hashes de oro cambiaron a propósito.
- Pendiente: cadenas (una decisión desencadena algo 3-6 semanas después), crisis con cuenta regresiva, ventanas de oportunidad, retratos de ministros (arte), eventos propios de los otros 19 ministerios, mostrar al jugador qué ministro pide. Cada una necesita estado nuevo y rebalanceo con bots.

## PR-02 Arrastrar cartas (primera etapa, 25-nov-2026)
- Hecho: deslizar la carta elegida hacia arriba (≥ 70 px, más vertical que horizontal) desde la mano la juega; tocar «Jugar» sigue funcionando como respaldo. Si una capa (evento, tutorial) tapa la mano, el gesto no cuenta. Prueba en `test_ui_humo.gd`.
- NO hecho a propósito (contradice reglas congeladas hasta que lo confirmes): mover el botón de avanzar al centro y dejar vacía la esquina derecha (CLAUDE.md §5: botón principal siempre en la misma posición), soltar sobre una región del mapa para elegirla, soltar sobre el ícono de delegar, confirmación al terminar la semana con movimientos sin usar, sonido y vibración (no hay sonido en el juego; faltan efectos CC0). Decisiones (a)–(d) de PR-02 siguen abiertas.

## PR-11 / PR-12 / PR-13 (25-nov-2026)
- PR-11 hecho en parte: epílogo (finales variados), hitos y **resultado de la sucesión** (texto según aprobación final; umbrales en `leyes.json` → `sucesion`). Pendiente: bono de legado que pase a la próxima partida (requiere guardar progreso entre partidas: decisión de datos/privacidad, U9) y la puerta a una nueva candidatura.
- PR-12 (reelección): NO implementado. El artículo 25 de la Constitución debe contrastarse con el texto oficial antes de modelarlo (regla de CLAUDE.md §6) y hoy no está en `data/bcn/normas.json`; además exige un segundo mandato como sesión nueva con estado heredado. Necesito que confirmes si lo quieres como partida nueva heredada.
- PR-13 (oposición): NO implementado. Es un modo casi nuevo (verbos distintos: bloquear, fiscalizar, acusar, reconstruir el partido); conviene validar primero el modo de gobierno con personas (D-02).

## PR-17 Balas de plata (25-nov-2026)
- Hecho: 5 cartas únicas de «recursos extraordinarios» (urgencia legislativa, veto, DFL, plebiscito, estado de excepción) en `data/cartas.json` con `unica: true`: efectos fuertes y costo alto en capital político; entran al mazo normal y no se repiten. Prueba en `test_decisiones.gd`. Los hashes de oro cambiaron a propósito.
- Pendiente: reglas legales finas (el DFL no vale para materias vedadas, el plebiscito puede salir mal) y un mazo aparte de 3-5 cartas por mandato.

## Nota legal informal (consulta del usuario a Gemini, 25-nov-2026; NO reemplaza a U4)
Lo que el usuario recopiló, y cómo lo cumple el proyecto:
- Figuras históricas fallecidas: nombres y hechos de libre uso. Políticos vivos: la representación en su rol público suele protegerse por libertad de expresión e información **si no se difama ni se sugiere que patrocinan el juego**. → Mantener alias satíricos, aviso de ficción y cero afirmaciones de auspicio.
- Fotografías: la persona no es dueña del nombre, pero **la foto sí tiene dueño** (fotógrafo o agencia). → El juego no usa fotos de personas: solo ilustraciones propias/generadas y retratos de dominio público (Wikimedia Commons con licencia verificada).
- Banderas y escudos: símbolos públicos, sin derechos de autor comerciales; evitar usarlos como marca o logotipo y símbolos prohibidos por ley. → La bandera chilena aparece como ambientación, no como marca del juego.
- Marcas, armas comerciales, música con derechos y mapas propietarios requieren licencia. → Mapas propios/abiertos (OSM, Natural Earth), sin marcas reales; sonido solo CC0 cuando se agregue.
Sigue pendiente U4: revisión por un abogado chileno (esta nota es de una fuente general, no asesoría jurídica).

## PR-18 a PR-23, PR-10, PR-15, PR-16 (25-nov-2026, hechos con la mecánica de eventos con decisión)
- PR-18 Ley de Presupuestos: decisión anual programada (años 1 a 4) sobre qué priorizar (salud y educación, obras o austeridad). PR-19: decisión en las elecciones del año 2 y 4. PR-20: comisiones legislativas piden negociar (Hacienda) o citan a un ministro (Salud). PR-21 Contraloría: objeta un decreto (decreto de insistencia) y anuncia una auditoría. PR-22: Banco Central, Tribunal Constitucional y Fiscalía. PR-23: reportaje crítico y entrevista de fin de año. PR-10 campaña narrativa: 4 hitos programados (entrevista matinal, cabildo, entrevista de fondo, cierre) con decisiones. Todo en `data/eventos.json`; sorteo con semilla y replay.
- PR-16 habilidades: Negociador, Comunicador, Gestor o Economista al fundar el partido (suman a los indicadores iniciales; datos en `leyes.json` → `habilidades`). PR-15 apariencia: color del emblema (6 colores de la paleta). Retratos modulares del personaje quedan para cuando haya cupo de arte (U7).
- Pendiente de estas: pantallas propias de cada actor (hoy son decisiones en el overlay de evento), mini-juego de reparto de gasto por sector, conteo de votos animado (PR-19), presidentes de comisión con nombre y relación (PR-20), PR-24 marco de actores único (necesita estado por actor: lo haré al unificar ministros, aliados, instituciones y medios).
- Balance: con las decisiones el bot gana más elecciones; recalibré la dificultad difícil (umbral +1,2, aprobación −3, desgaste ×1,08): fácil 24, normal 22, difícil 11 de 24.

## PR-12, PR-13, PR-14, PR-24 (25-nov-2026)
- PR-12 reelección: carta «Reforma constitucional: reelección presidencial» (quórum de reforma, años 3 y 4, cuesta aprobación, cohesión y capital) y dos epílogos nuevos («Un segundo mandato» / «Quisiste quedarte…»). Es mecánica ILUSTRATIVA: el texto del artículo 25 sigue sin contrastarse con el oficial (bcn.cl devuelve 401 desde aquí); el juego no afirma la regla real. Un segundo mandato jugable como sesión heredada sigue pendiente.
- PR-13 oposición: «Pasar a la oposición» tras perder la elección → 4 escenas con decisiones (fiscalizar, acusación constitucional, reconstruir el partido, preparar candidatura) y un resultado según visibilidad, partido y alianzas (`leyes.json` → `oposicion`). Es un modo LIGERO: no hay Congreso ni cartas en oposición.
- PR-14 internos: sin cambios nuevos; ya muestran aviso por acción. Vincularlos a personas queda con PR-24.
- PR-24 marco de actores: NO hecho. Necesita estado por actor (relación de cada ministro, aliado, institución y medio) y unificar los eventos con decisión bajo un solo modelo; sin eso sería decoración. Es el siguiente paso grande y cambia hashes y balance.
- PR-08: los 25 ministerios ya tienen su petición (evento con decisión); 6 ministerios clave + 19 más. Los retratos siguen pendientes (U7).

## PR-24 Marco de actores (primera versión, 25-nov-2026)
- Hecho: los eventos con decisión de 25 ministerios, 2 comisiones, Contraloría, Banco Central, TC, Fiscalía y medios declaran su `actor` y cada opción un `relacion` (+1 apoyar, 0 negociar, −1 ignorar). `MotorEventos.relaciones_actores()` deriva la relación (50 ± 10 por decisión; `leyes.json` → `actores`) del registro de decisiones, sin estado nuevo, y la pantalla de fin muestra «Tu relación con los actores». Prueba en `test_decisiones.gd`.
- Pendiente: que la relación tenga consecuencias (p. ej. un ministro enojado renuncia, un medio hostil amplifica escándalos) y mostrarla durante la partida, no solo al final. Requiere rebalancear.

## Decisiones del usuario del 25-nov-2026 (hechas)
- **Gabinete real:** `leyes.json` → `gabinete.tamano = 25`. El gabinete por defecto es el relleno equilibrado sobre uno vacío (los 25). Quien quiere puede quitar y volver a elegir; «Rellenar» (equilibrado o máxima eficacia) completa los vacíos sin pisar lo escogido. Consecuencia de diseño: con los 25 ministerios todas las categorías de cartas quedan habilitadas; lo que decide ahora es quién ejecuta cada carta (delegación, bonos y riesgo de cada ministro) y la relación con cada actor. Balance recomprobado (bots: 90 % de elecciones ganadas por el bot activo; dificultad 24/22/11 de 24).
- **PR-02 completo:** el botón del medio es «Terminar semana · N mov» con confirmación si sobran movimientos; la esquina inferior derecha queda vacía; se juega deslizando la carta hacia arriba o tocándola dos veces; soltarla sobre el ícono izquierdo delega. Reglas de CLAUDE.md actualizadas. Falta (no pedido aún): sonido, vibración, animación de la carta sobre el mapa y soltar sobre una región concreta para elegirla en campaña.
- **PR-12, la pregunta precisa:** cuando la partida termine el mandato con la reforma de reelección aprobada y tu aprobación final sea alta, ¿quieres que el juego te ofrezca **continuar jugando un segundo mandato de 4 años en la misma partida** (con el mismo gabinete, partido y estado, otros 208 turnos), o prefieres que **solo aparezca el epílogo** como hoy? (Mi recomendación: continuar en la misma partida, porque conserva lo que construiste y evita guardar progreso entre partidas.)

## Verificación de cartas de proyectos reales (26-nov-2026)
De las 1.685 cartas reales, 639 (todas de proyectos públicos) siguen con `verificado: false`. No se marcan sin leer la ficha primaria; por archivo de `data/proyectos/`, sin verificar de cada total: `curados_rm` 40/93, `curados_norte` 27/59, `curados_centro` 49/56, `curados_energia_transporte` 24/70, `curados_sur` 18/56, `concesiones_vial` 23/66, `minsal_oncologico` 14/26, `curados_educ_viv` 13/75, `planes_y_gobierno_2026` 11/11, `concesiones_edificacion` 6/17, `concesiones_aeropuertos` 5/30, `metro_santiago` 4/4, `concesiones_seguridad` 3/9, `concesiones_agua` 1/6, `concesiones_salud` 1/13. Orden sugerido: primero las fichas MOP (se pueden contrastar contra concesiones.mop.gob.cl, que sí responde desde aquí), luego Minsal/Dipres y al final las de prensa. Mientras tanto la interfaz las rotula como cifras ilustrativas.

### Fichas del MOP (revisión del 26-nov-2026)
De las 39 fichas de concesiones MOP con `verificado: false`, **38 son concesiones ya terminadas** (`estado: terminado`, sin inversión publicada en la fuente) y **no generan cartas jugables**; no hay nada que contrastar para el juego. La restante, el **Sistema Nacional de Alerta Temprana de Tsunami** (licitación, 115 MUSD), no tiene región asignada y su página en concesiones.mop.gob.cl se arma con JavaScript (la ficha en HTML simple no contiene los datos), así que no se puede leer y contrastar con una descarga simple: su verificación pasa por la API de WordPress que ya es la fuente del dato, es decir, sería circular. Las ~600 cartas restantes sin verificar son de proyectos curados (`curados_*`, Minsal, planes de gobierno, Metro): ahí sí hace falta leer la fuente primaria de cada una (Dipres/Minsal/prensa), en el orden de la lista anterior.

## Medición en un teléfono real (26-nov-2026, riesgo declarado por «Diseño visual»)
En escritorio (render por software) el pico de memoria es de 578 MB y el costo de dibujo es de unos 3 a 5 ms por cuadro, pero **nada de esto se midió en un teléfono**. Faltan dos cosas que el escritorio no prueba: el costo de GPU con suavizado MSAA 2× y la nitidez y el peso de la caché del mapa urbano (una vista del tamaño de la pantalla, ≈ 1.000×1.300 px) en un teléfono de gama baja.
- **Qué hacer (10 minutos):** instalar el APK de depuración, jugar una semana, abrir el mapa urbano y el Comité 3D, y luego **Informe de prueba → Copiar informe** (trae el mínimo de cuadros por segundo, la memoria máxima, el modelo del teléfono y la versión). Meta: 30 fps estables y ≤ 800 MB.
- **Comparación:** `tests/medir_transiciones.gd`, `medir_cuadros.gd` y `medir_memoria.gd` dan las cifras de escritorio contra las que comparar.
- Pantallas bajas (360×640): el mapa del día queda en el 27 % de la pantalla (CLAUDE.md pide más de un tercio); decisión del usuario en `RESUMEN_DECISIONES.md`.
