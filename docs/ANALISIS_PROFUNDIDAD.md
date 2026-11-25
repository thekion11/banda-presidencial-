# Análisis de profundidad (25-nov-2026)

**Pregunta del usuario:** «estamos ampliando mucho y profundizando poco». Este análisis sale de mediciones hechas sobre el código y los datos de hoy (no de opinión), más el informe de balance (`docs/INFORME_BALANCE.md`). Las cifras se pueden reproducir: datos con scripts de Python sobre `data/`, y la simulación con 5 partidas del bot «codicioso» (733 semanas de gobierno).

## 1. Diagnóstico en una frase
El juego ya tiene **muchas piezas** (carrera, oposición, afiliación, 25 ministerios, 6 tipos de actores, 1.775 cartas, 109 eventos), pero **cada pieza influye poco en las demás y el ritmo no cabe en una sesión**. Hay que parar de sumar mecánicas y hacer que las que existen importen, se vean y se puedan jugar en 20 minutos.

## 2. Hallazgos medidos (de más grave a menos)

### H1. El ritmo de eventos es inviable (error de experiencia, no de contenido)
- **4,14 eventos por semana** de gobierno y **1,31 decisiones por semana** (≈ 860 eventos y ≈ 270 decisiones por mandato). Cada uno es una pantalla completa.
- Los mismos eventos se repiten sin parar: «Déficit hídrico» salió en 174 de 733 semanas (24 %); los de vecinos, ~150 veces cada uno. Solo se ven 116 eventos distintos en 733 semanas.
- Causa: `peso_sorteo` se usa como probabilidad **por semana de cada evento** (0,25 × 60 eventos). Cada evento nuevo que añadimos subió el ruido sin aviso.
- Contradice D-01 (sesiones de 20 minutos) y el hallazgo P11 del video (textos que se repiten decenas de veces).

### H2. La duración real es de horas, no de 20 minutos
- Un mandato son 208 semanas; con la carrera, varios. Por semana: ≈ 3,4 cartas jugadas, 4 eventos, confirmaciones. Aun a 4 s por acción son ≈ 1,5 h por mandato.
- Antes de ver el mapa hay **≥ 12 toques** (menú, afiliación, 8 preguntas, identidad, gabinete) y 5 pasos de tutorial; la decisión de PR-01 fue **máximo 3 toques**.

### H3. El mazo casi no tiene decisiones propias
- El **70 % de las cartas en mano son «reales»** (1.685 generadas por plantilla); las 90 cartas diseñadas son ≈ 5 % del mazo.
- Esas 1.685 cartas tienen solo **322 firmas de efecto distintas**; 3 firmas cubren ≈ 400 cartas («+2,5 aprobación, −1 fiscal»…). Los 3 costos casi no varían: 1.297 de 1.775 cuestan 2.
- El 100 % lleva «cifras ilustrativas» y 641 están sin verificar contra su fuente.
- Resultado: jugar la carta de «Perspectiva de género en planes de seguridad» y la de un puente da lo mismo salvo el nombre.

### H4. Con 25 ministerios el gabinete dejó de ser una decisión
- Con los 25 siempre presentes **todas las categorías de cartas están activas**. Los 25 ministros tienen **la misma reducción de costo (1)**, bono de ejecución 0,10–0,20 y riesgo de escándalo 0,05–0,12: son intercambiables.
- Solo importan al delegar (2 por turno) y en las peticiones de eventos. «Rellenar» (equilibrado o máxima eficacia) elige entre casi iguales.

### H5. Varias mecánicas «v2» son inertes o dominantes (según `INFORME_BALANCE.md`, 100 partidas por variante)
| mecánica | efecto medido al quitarla |
|---|---|
| Coalición | **0,0 %** (el bot no asigna cuotas; la mecánica no se usa) |
| Bono por aprobación | **0,0 %** (nunca se activa: la aprobación del bot en gobierno rara vez llega a 60) |
| Movimientos internos | −4,7 % |
| Delegación | −17,9 % |
| Asesores | **−31,9 %** y +35 puntos de crisis: casi obligatorios (+1 movimiento por asesor) |
| Mano continua | **−45 %** y +70 puntos de crisis: obligatoria |
Hoy añadimos decisiones y actores **sin medir** si cambian el resultado.

### H6. Las decisiones de los eventos casi no son dilemas
- Con un valor simple (aprobación 1, capital 0,8, cohesión 0,7, fiscal 0,7) la mejor opción es la 1.ª en 30 eventos y la 2.ª en 27; la peor diferencia media entre mejor y peor es 1,96 puntos. No hay riesgo, secreto ni efecto diferido: es elegir la «buena».
- Las decisiones **no tienen memoria**: no cambian qué eventos ni qué opciones aparecen después (excepto la relación con actores, que hoy solo se muestra al final y no tiene consecuencias).

### H7. Carrera y oposición son un esqueleto
- Oposición: 16 cartas, 8 eventos, 26 semanas; **no hay rival gobernando**, ni Congreso, ni votaciones: tu aprobación no depende de nadie.
- Campaña: la franja, los debates y las entrevistas son eventos con 3 botones; no hay mensajes, audiencia, encuestas ni territorio.
- Reelección: una carta sin regla real contrastada (art. 25 sin verificar).

### H8. Ingeniería y pruebas
- Archivos pegados al límite: `pantalla_dia.gd` 441/450, `motor_turno.gd` 209/220, `estado_simulacion.gd` ≈ 217/220. Cada mecánica nueva exige comprimir o dividir.
- Interfaz probada solo con «humo»; ninguna prueba con personas (U1); el balance se mide con bots, que juegan distinto a una persona.
- Las pruebas de oro se regeneran a cada cambio de datos: sirven como alarma pero ya no como garantía de que «no cambió nada».

### H9. Sensación de juego
- No hay sonido ni vibración; los efectos de una carta se ven como texto; el panel de la carta ya está al límite de espacio.
- El arte de la categoría «oposición» reutiliza el de política; 13 categorías siguen esperando arte propio (U7).

## 3. Qué hacer: orden recomendado (de mayor retorno a menor)

**Fase A — Ritmo (arregla H1 y parte de H2). Prioridad máxima.**
1. **Director de eventos:** como máximo **1 evento por semana** (2 si uno es programado); decisiones espaciadas (≈ 1 cada 4–6 semanas, ≈ 40 por mandato en vez de 270); cooldown por evento y por familia (vecinos, ministerios, instituciones); los de «una sola vez» no se repiten. `peso_sorteo` pasa a ser **peso relativo** y no probabilidad.
2. **Semanas silenciosas:** si no hay evento ni movimientos que gastar, «Siguiente semana» avanza varias semanas hasta el próximo hito (con resumen).
3. **Arranque corto:** «Empezar» con un partido sugerido y 3 toques; el test de 8 preguntas como opcional («definir mi ideología»).
**Decisión que necesito del usuario:** la duración. Opciones: (a) mantener 208 semanas con semanas silenciosas, (b) pasar a 1 turno = 1 mes (≈ 48 turnos por mandato), (c) capítulos de ~20 minutos con guardado.

**Fase B — Un mazo con intención (H3).**
4. Curar ≈ 150 cartas reales (las de mayor interés) con efectos propios, riesgos, plazos y un texto breve; el resto como «relleno» con menos peso. Mano = 2 cartas diseñadas + 3 reales (configurable en `leyes.json`).
5. Cartas con costo/beneficio asimétrico (efectos a futuro, riesgo de escándalo, requisitos de ministro o aliado).

**Fase C — Gabinete con identidad (H4, H5).**
6. Diferenciar los 25: ideología, partido, estilo (cada uno reduce el costo, sube la ejecución o abre cartas de **su** sector), conflictos y renuncias; la relación con cada actor pasa a tener **consecuencias** (renuncia, filtración, apoyo en el Congreso).
7. Hacer que coalición y bono de aprobación importen o retirarlos: medir con `tests/ablacion.gd` antes y después.

**Fase D — Decisiones con peso (H6).**
8. Opciones con riesgo y efectos diferidos; cadenas (una decisión cambia los eventos de 3–6 semanas después); eventos que **cambian de opciones** según tus decisiones y tu relación con los actores.
9. Un «registro de decisiones» visible en la pantalla de fin (qué elegiste y qué provocó).

**Fase E — Profundizar la carrera (H7).**
10. En oposición: un **rival que gobierna** (su aprobación y sus leyes mueven la tuya), un Congreso con votaciones donde bloqueas o pactas, encuestas y primarias.
11. En campaña: mensaje por segmento, territorio y franja con audiencia; debates con preguntas.
12. Reelección: contrastar el art. 25 con el texto oficial y modelar la regla real.

**Fase F — Calidad (H8, H9).**
13. **Prueba con 5–10 personas** (U1) antes de añadir más; telemetría opcional y anónima (decisión de monetización, U9).
14. Dividir `pantalla_dia`, `motor_turno` y `estado_simulacion` por responsabilidad; subir el límite solo con motivo.
15. Sonido CC0, vibración opcional, animación de efectos y accesibilidad (daltonismo, tamaño de letra).

## 4. Regla propuesta
**Congelar mecánicas nuevas** (alcance) hasta terminar las fases A y B. Todo cambio de datos debe llevar una **medición con bots** (eventos por semana, tasa de elección, puntaje, mecánicas inertes) y una **nota en `docs/DECISIONES.md`**.

## 5. Medidas de éxito (para volver a medir)
| métrica | hoy | meta |
|---|---|---|
| eventos por semana | 4,14 | ≤ 1 |
| decisiones por mandato | ≈ 270 | 30–45 |
| toques antes del primer turno | ≥ 12 (+5 de tutorial) | ≤ 3 |
| duración de un mandato (jugador) | horas | ≈ 20 min (capítulo) |
| firmas de efecto distintas en las cartas | 322 de 1.685 | ≥ 800 o menos cartas |
| mecánicas con efecto medible (> 3 %) | 4 de 7 | 7 de 7 |
| partidas probadas con personas | 0 | ≥ 10 |

---

# Resultado de la ejecución (25-nov-2026)

El usuario dejó abierta la **dirección de duración** (semanas silenciosas, turno = mes o capítulos) y pidió hacer todo lo demás, incluidos los bots. Estado frente a las métricas de éxito:

| métrica | antes | ahora | meta |
|---|---|---|---|
| eventos por semana | 4,14 | 0,76 (`test_ritmo`) | ≤ 1 ✔ |
| decisiones por mandato | ≈ 270 | ≈ 25 | 30–45 (algo bajo; ajustable con `prob_decision`) |
| eventos distintos en un mandato | 116 | ≈ 122 | ≥ 40 ✔ |
| toques antes del primer turno | ≥ 12 + 5 de tutorial | 1 (partida rápida) | ≤ 3 ✔ |
| cartas | 1.775 (322 firmas de efecto distintas) | 1.965 (556 firmas; 180 curadas con riesgo y efectos a futuro) | — |
| mano con cartas diseñadas | ≈ 37 % | ≥ 2 de 5 siempre (`test_identidad`) | ✔ |
| ministros intercambiables | 25 casi iguales | 75 candidatos con estilo, afinidad, riesgo y renuncia | ✔ |
| mecánicas con efecto medible | 4 de 7 | sin medir de nuevo (falta correr `tests/ablacion.gd`) | 7 de 7 |
| partidas probadas con personas | 0 | 0 | ≥ 10 (U1) |

**Hecho:** Fase A (director de eventos y partida rápida), B (mazo curado y composición de la mano), C (gabinete con identidad), D (decisiones con riesgo, efectos a futuro, cadenas y memoria), E (oposición con gobierno rival) y la primera parte de F (sonido, vibración, números flotantes y ajustes). Bots: políticas «humano» y «experto», decisiones por valor esperado e `informe_bots` (`docs/INFORME_BOTS.md`).

**Falta:** la duración (decisión del usuario); coalición y bono por aprobación siguen sin medirse tras los cambios; pantallas propias de debate y entrevista; Congreso y votaciones en oposición; tamaño de letra y modo daltónico; música; pruebas con personas (U1); artículo 25 de la Constitución sin contrastar.
