# Informe de balance — ablación de las mecánicas v2

Fecha: 23-nov-2026 · rama `feat/mecanicas-v2` (con `ccr-ec102a3c-giitie`: 1.540 cartas reales + 68 de diseño) · Godot 4.3.

## Método
- `tests/ablacion.gd` (`godot --headless --path . -s tests/ablacion.gd -- 100 [variante] ['{"seccion.clave": valor}']`).
- Política del bot: **completo** (`tests/bots.gd`): juega como el codicioso y además contrata 3 asesores, se alía con 2 partidos, delega 2 cartas por turno y usa los movimientos internos.
- Cada variante desactiva UNA mecánica **solo con parámetros de `data/leyes.json`**: `asesores.max=0`, `coalicion.max_aliados=0`, `delegacion.max_por_turno=0`, `movimientos_internos.por_turno=0`, `bono_movimientos.tramos=[]`, `mano.continua=false`. `sin_nada_v2` las desactiva todas.
- n = 100 partidas por variante, semillas 1000–1099 (idénticas entre variantes). «Puntaje» = `resultado_final.puntaje` de las partidas en que el jugador ganó la elección (cualquier final: mandato completo o crisis).
- Umbrales usados (criterio propio, no del diseño): **dominante** = quitarla baja el puntaje medio más de 25 %; **obligatoria** = quitarla cambia la tasa de crisis en más de 10 puntos.

## Resultados (parámetros finales, 1.540 cartas)
| variante | gana elección | cae en crisis | completa mandato | aprobación final | puntaje medio | puntaje mediano | Δ puntaje medio vs completo |
|---|---|---|---|---|---|---|---|
| completo | 76,0 % | 0,0 % | 76,0 % | 31,0 | 4160 | 4117 | — |
| sin_asesores | 76,0 % | 35,5 % | 49,0 % | 20,8 | 2831 | 3384 | **−31,9 %** |
| sin_coalicion | 76,0 % | 0,0 % | 76,0 % | 30,2 | 4162 | 4153 | +0,0 % |
| sin_delegacion | 76,0 % | 0,0 % | 76,0 % | 38,7 | 3415 | 3422 | −17,9 % |
| sin_internos | 76,0 % | 0,0 % | 76,0 % | 29,7 | 3966 | 3987 | −4,7 % |
| sin_bono_aprobacion | 76,0 % | 0,0 % | 76,0 % | 31,0 | 4160 | 4117 | 0,0 % (idéntico) |
| sin_mano_continua | 76,0 % | 69,7 % | 23,0 % | 13,5 | 2290 | 2010 | **−45,0 %** |
| sin_nada_v2 | 76,0 % | 0,0 % | 76,0 % | 28,7 | 2211 | 2224 | −46,9 % |

La tasa de elección casi no cambia entre variantes porque la campaña no usa asesores, delegación ni movimientos internos (solo gobierno); la mano continua sí actúa en campaña pero con estos datos no mueve la tasa.

## Ajustes de parámetros hechos (solo `data/leyes.json`)
Medidos antes de fusionar las 1.540 cartas (578 cartas), con «completo» y n = 100:
| parámetro | antes → después | motivo |
|---|---|---|
| `delegacion.prob_fallo_base` | 0,15 → 0,40 | la delegación era la mecánica dominante (quitarla bajaba el puntaje −28,5 %). |
| `delegacion.prob_anula_si_falla` (nuevo) | — → 0,75 | endurecer `escala_si_falla` no bastaba: aun con efecto ×0 el puntaje no cambiaba, porque una delegación fallida igual iniciaba la obra o ley (el puntaje cuenta obras). Ahora un fallo puede dejar la carta sin hacer. Aporte resultante ≈ 20 %. |
| `movimientos_internos.acelerar_proyecto.dias` | 14 → 5 | tras lo anterior, los movimientos internos quedaron dominantes (−26,6 %); acelerar obras es lo que más pesa en el puntaje. |
| `movimientos_internos.reducir_errores.delta_riesgo` | −4 → −2 | idem (aporte resultante ≈ 22,7 % antes de fusionar; −4,7 % con las 1.540 cartas). |
`escala_si_falla` quedó en 0,4 (era 0,5). Se probó y se descartó un peso mayor de los efectos negativos de los asesores (`escala_efecto_negativo` 2, 4, 6: puntaje 4155 / 4187 / 3895; recién con 6 aparecen crisis): los asesores no dependen de sus efectos sino de sus +3 movimientos.

## Hallazgos que NO se resolvieron con parámetros (decisión de producto)
1. **Asesores: dominantes (−31,9 %) y casi obligatorios (+35,5 puntos de crisis al quitarlos).** El beneficio viene de la regla fijada por la especificación: +1 movimiento por asesor, hasta 3, sobre una base de 5 (+60 % de acciones). Los efectos positivo y negativo casi no pesan. Se podría suavizar con otra regla (p. ej. +1 movimiento solo con el primer asesor, o costo en capital político al contratar) o subiendo la base de movimientos, pero cambia la especificación del usuario; no lo hice.
2. **Mano continua: obligatoria (+69,7 puntos de crisis al quitarla).** Es una regla central del diseño (DISENO_V2 §3), no una opción; sin ella el bot queda con menos jugadas por turno y la aprobación cae con estos datos. Se documenta como dependencia estructural.
3. **Bono por aprobación: inerte.** Los resultados con y sin bono son idénticos: la aprobación del bot en gobierno rara vez llega a 60 % (media final 31). El bono solo se activa en partidas muy exitosas. Para que importe habría que cambiar la dinámica de aprobación o los umbrales (60/65/…); no se tocó.
4. **Coalición: inerte para este bot.** El bot no asigna cuotas, así que la satisfacción cae y la coalición se rompe; el efecto neto es ≈ 0. La mecánica sí está probada (`test_coalicion`), pero no se midió su valor con un jugador que gestione cuotas; hace falta una política de bot que lo haga.
5. Interacción: `sin_mano_continua` provoca crisis (69,7 %) pero `sin_nada_v2` no (0 %): el daño viene de dejar activos los efectos negativos de asesores, delegaciones fallidas y movimientos sin la mano continua que los compense. La causa probable (no verificada con una prueba aislada) es dejar activos los efectos negativos de asesores, delegaciones fallidas y movimientos sin la mano continua que los compense; es una advertencia sobre combinar mecánicas, no un error.

## Aserciones de `tests/test_balance.gd`
Sin cambios. Pasan con los parámetros finales (suite completa en verde con godot 4.3).

## Replay y RNG (auditoría 3)
- `test_guardado` reproduce desde el JSON del guardado dos partidas completas (política codicioso y política completo: gabinete, asesores, coalición, delegación, metas, movimientos internos) y comprueba que la huella final es idéntica y que reproducir dos veces da lo mismo.
- No hay un RNG nuevo: todo usa el RNG único de la partida (`MotorTurno.rng`), cuyo orden de consumo está fijado por las entradas del jugador. Nuevos consumos: delegación (fallo, escándalo, anulación), reposición y barajado del mazo al reponer. **Cualquier cambio en estos datos o en el orden de consumo cambia el flujo y por eso `Datos.huella` invalida los guardados anteriores** (ya ocurría con el RNG único; ver C2 de la auditoría 1). Aislar el RNG por subsistema (semilla ^ hash del subsistema) sigue siendo la mitigación recomendada.
- El partido se redondea a 6 decimales al iniciar (`EstadoSimulacion.normalizar`) para que el JSON lo reproduzca sin deriva.

## Ley interpretativa de la Constitución (auditoría 3, punto 3)
Tipo `ley_interpretativa`: 4/7 de los en ejercicio (29/89), con cita del art. 66 en `normas.json`; `verificado:false`. Ninguna carta real la exige, por lo que se añadió la carta de diseño ilustrativa `pol_ley_interpretativa` (rotulada; `tools/generar_carta_interpretativa.py`).

## Medición repetida el 25-nov-2026 (tras las fases A a F)
`tests/ablacion.gd -- 24` (política «completo», 24 partidas por variante, 1.965 cartas, 25 ministerios con candidatos, director de eventos). Puntaje medio con todo: 2.933.

| variante | cae en crisis | aprobación final | puntaje medio | Δ vs completo |
|---|---|---|---|---|
| completo | 0 % | 48,3 | 2.933 | — |
| sin_asesores | 0 % | 39,3 | 2.610 | −11 % |
| sin_coalicion | 0 % | 49,4 | 2.890 | −1,5 % (casi inerte) |
| sin_delegacion | 0 % | 39,5 | 2.047 | −30 % |
| sin_internos | 0 % | 36,6 | 2.014 | −31 % |
| sin_bono_aprobacion | 0 % | 48,5 | 2.927 | −0,2 % (inerte) |
| sin_mano_continua | 41,7 % | 15,8 | 2.023 | −31 % y 42 puntos de crisis |
| sin_nada_v2 | 0 % | 34,3 | 1.418 | −52 % |

Lectura: los asesores dejaron de ser dominantes (de −32 % a −11 %); la delegación y los movimientos internos pesan ahora ≈ 30 % cada uno (antes −18 % y −5 %), es decir, tienden a ser dominantes y conviene revisarlos; la coalición y el bono por aprobación siguen sin efecto medible con este bot (el bot no asigna cuotas y casi nunca llega a 60 % de aprobación). Pendiente de decisión de diseño: o se les da una función real (cuotas visibles, bono más bajo) o se retiran.


## Actualización del 26-nov-2026 (main b1c8677)
Medición con bots sobre el juego actual (director de eventos v2, coalición y bono con función real, encuestas, mano con cartas reales sorteadas sin reposición). 80 partidas por combinación, semillas 1000-1079; «gana» = gana la elección, «crisis» = cae en crisis de gobierno.

| política | dificultad | gana | crisis | completa el mandato | aprobación final |
|---|---|---|---|---|---|
| azar | fácil | 100 % | 25 % | 75 % | 23,4 |
| azar | normal | 38 % | 15 % | 23 % | 21,1 |
| azar | difícil | 3 % | 0 % | 3 % | 28,1 |
| humano | fácil | 100 % | 4 % | 96 % | 31,2 |
| humano | normal | 89 % | 4 % | 85 % | 31,6 |
| humano | difícil | 23 % | 0 % | 23 % | 34,6 |
| codicioso | fácil | 100 % | 8 % | 93 % | 28,0 |
| codicioso | normal | 96 % | 6 % | 90 % | 27,3 |
| codicioso | difícil | 48 % | 4 % | 44 % | 26,5 |
| completo | fácil | 100 % | 0 % | 100 % | 54,4 |
| completo | normal | 96 % | 0 % | 96 % | 54,1 |
| completo | difícil | 48 % | 0 % | 48 % | 53,6 |

Lectura: de normal a difícil hay un escalón (≈ 5,7 puntos de golpe: −3,5 de aprobación inicial y +2,2 de umbral). Los remedios probados (umbral de normal +0,7; ruido de elección ±4) no mueven a quien juega bien; la decisión sobre la tasa de victoria deseada en normal queda para después de las pruebas con personas (`docs/DECISIONES.md` §AA). Ablación (n=16-24): sin delegación −30 %, sin internos −22 a −32 %, sin mano continua −25 a −32 % (y 43 % de crisis), sin asesores −12 %, sin coalición −7 %, sin bono −5 %. Reproducir: `tests/montecarlo.gd`, `tests/ablacion.gd`, `tests/informe_bots.gd`.

## Monte Carlo grande del 26-nov-2026 (200 partidas por celda, semillas 20000-20199, main tras `149c458`)
Intervalos de confianza de Wilson al 95 % entre paréntesis (puntos porcentuales). «Crisis» se calcula sobre las partidas que llegaron al gobierno; «puntaje» y «aprobación» sobre las que terminaron el mandato o cayeron. Reproducir: `godot --headless --path . -s tests/informe_dificultad.gd -- 200` (≈ 25 min).

| Política | Dificultad | Gana la elección | Crisis (de las electas) | Completa el mandato | Puntaje mediano | Aprobación media |
|---|---|---|---|---|---|---|
| pasivo | facil | 16.5 % (12-22) | 100.0 % (90-100) | 0.0 % | 0 | 10.4 |
| pasivo | normal | 0 % (0-2) | — | 0 % | — | — |
| pasivo | dificil | 0 % (0-2) | — | 0 % | — | — |
| azar | facil | 100.0 % (98-100) | 35.0 % (29-42) | 65.0 % | 2145 | 20.4 |
| azar | normal | 39.5 % (33-46) | 39.2 % (29-50) | 24.0 % | 2134 | 19.2 |
| azar | dificil | 0.5 % (0-3) | 100.0 % (21-100) | 0.0 % | 0 | 7.9 |
| humano | facil | 100.0 % (98-100) | 6.0 % (3-10) | 94.0 % | 1523 | 28.1 |
| humano | normal | 76.0 % (70-81) | 7.9 % (5-13) | 70.0 % | 1500 | 28.0 |
| humano | dificil | 18.5 % (14-24) | 0.0 % (0-9) | 18.5 % | 1522 | 29.4 |
| codicioso | facil | 100.0 % (98-100) | 11.0 % (7-16) | 89.0 % | 1852 | 25.4 |
| codicioso | normal | 94.0 % (90-97) | 15.4 % (11-21) | 79.5 % | 1873 | 24.9 |
| codicioso | dificil | 43.0 % (36-50) | 18.6 % (12-28) | 35.0 % | 1833 | 23.9 |
| completo | facil | 100.0 % (98-100) | 0.0 % (0-2) | 100.0 % | 3042 | 53.0 |
| completo | normal | 94.0 % (90-97) | 0.0 % (0-2) | 94.0 % | 3050 | 52.1 |
| completo | dificil | 43.0 % (36-50) | 1.2 % (0-6) | 42.5 % | 3019 | 52.6 |

**Lectura**
- La escalera de dificultad existe pero es solo de campaña: el codicioso gana la elección el 100 % en fácil, ≈ 94 % en normal y ≈ 43 % en difícil; el azar, 100 %, ≈ 40 % y ≈ 0,5 %. Una vez en el gobierno, el puntaje mediano es igual en las tres dificultades (D16 en `docs/DECISIONES_PENDIENTES.md`).
- Con la cohesión con desgaste (`regen_cohesion_semanal` −1,85), el codicioso que ignora la cohesión cae en crisis el 11 % (fácil), el 15 % (normal) y el 19 % (difícil) de las veces; «completo» (asesores, coalición, delegación, internos) casi nunca (0-1 %). Está por debajo del techo de 20 % de `test_balance`, pero los intervalos de normal y difícil llegan a ≈ 21 % y ≈ 28 %: `test_balance` solo exige el techo con el nivel por defecto; si se endurece, mirar estas celdas. El pasivo en fácil gana el 16,5 % y siempre cae en crisis.
- Fácil es trivial para cualquiera que juegue (el azar gana el 100 %); difícil exige jugar bien (humano 18 %, codicioso 43 %).
- El jugador casual simulado («humano») gana el 76 % en normal y completa el mandato el 70 %: no es un juego difícil para quien lo juega con atención.
