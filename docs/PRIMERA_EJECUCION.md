# Primera ejecución con instalación limpia (27-nov-2026)

Recorrido de una persona que instala el juego por primera vez, sin guardado, sin «última configuración» y sin el tutorial visto. Lo genera `tests/primera_ejecucion.gd`, que pulsa los botones reales de cada pantalla y guarda una captura por paso en `docs/comparacion/primera_ejecucion_*.png`:

```
xvfb-run -a godot --path . --rendering-method gl_compatibility --resolution 390x844 -s tests/primera_ejecucion.gd -- docs/comparacion
```

Camino: «Nueva partida» → «Fundar mi partido» → test rápido (3 preguntas) → identidad del partido (ya viene escrita) → gabinete (ya viene completo) → día 1 de campaña con tutorial → primera carta jugada.

**Cómo se estiman los segundos:** se cuentan las palabras que se ven enteras en pantalla (no lo que queda más abajo en una lista) a 4 palabras por segundo, que es leer por encima, más 1 s por toque. «Toques» son los que hacen falta para llegar a ese paso desde el anterior.

| Paso | Toques | Palabras en pantalla | Segundos estimados | Nota |
|---|---|---|---|---|
| 01 menú | 0 | 47 | 12 | Instalación limpia: no aparecen «Continuar» ni «como la última vez» |
| 02 afiliación | 1 | 39 | 11 | Tres tarjetas con una línea de explicación cada una |
| 03 test, pregunta 1 | 1 | 56 | 15 | Test rápido de 3 preguntas; enlace al test completo de 8 |
| 04 fundación | 3 | 66 | 20 | Nombre, sigla, región, habilidad y dificultad ya vienen elegidos |
| 05 gabinete | 1 | 220 | 56 | El más largo de leer: 25 ministerios ya llenos; basta «Comenzar campaña» |
| 06 día con tutorial | 1 | 99 | 26 | El tutorial se abre solo, con «Saltar tutorial» |
| 07 día sin tutorial | 5 | 70 | 22 | 5 pasos de tutorial |
| 08 primera carta | 2 | 67 | 19 | Tocar elige la carta y tocar otra vez la juega: «Promesa nacional: +0,5…» |
| **Total** | **14** | | **≈ 185 s (3 min)** | |

## Hallazgos

1. **No hay callejones sin salida.** Cada pantalla tiene un botón principal grande (≥ 48 px) en el mismo lugar de abajo, y el Atrás de Android vuelve un paso (`tests/test_atras.gd`).
2. **El gabinete era el paso más pesado y repetía su explicación.** El encabezado y el panel decían lo mismo con otras palabras («Un candidato por ministerio…» y «Elige un candidato por ministerio…»). **Corregido:** el encabezado ahora dice lo que falta saber, «Ya viene completo: puedes empezar así y cambiarlo durante la campaña.» Siguen siendo unas 220 palabras visibles porque la lista muestra 5 ministros con sus datos, pero no hace falta leerlas para seguir.
3. **La región de la promesa pasaba desapercibida.** En campaña, el recuadro «Elige una región» invita a tocar el mapa, pero la carta se juega igual sin elegir. En ese caso la promesa se reparte por igual entre todas las regiones, y el aviso decía solo «Promesa registrada». **Corregido:** el aviso dice «Promesa nacional: +0,5 de aprobación. Toca el mapa para dirigir la próxima» o «Promesa en Atacama: +0,5 de aprobación» (`game/pantallas/pantalla_dia.gd`; lo prueba `tests/test_claridad.gd`).
4. **El test rápido sale por defecto y eso se aparta de CLAUDE.md.** Fundadores e independientes reciben 3 preguntas, y el test completo de 8 queda a un toque. CLAUDE.md §2 (PR-01) pide el test completo para ellos y las 3 posturas solo para quien entra a un partido. El cambio lo hizo la sesión del motor en el commit `1619c07` (25-nov, DECISIONES §S) para cumplir la meta de ≤ 3 toques: fue deliberado, pero sin autorización explícita del usuario. **Queda como D19 en `docs/DECISIONES_PENDIENTES.md`** (la recomendación es dejarlo y enmendar CLAUDE.md). El comportamiento no se toca hasta que decida el usuario.
5. **El camino más corto ya existe.** «Partida rápida» en el menú lleva al día 1 en **1 toque**, con un partido por defecto o con la última configuración.
6. **El tutorial cuesta 5 toques y unos 50 s.** Se puede saltar desde el primer paso. No propongo acortarlo: cada paso señala una zona distinta (mano, movimientos, mapa, «Terminar semana», paneles).

## Capturas

`docs/comparacion/primera_ejecucion_01_menu.png` … `primera_ejecucion_08_primera_carta.png` (390 × 844).
