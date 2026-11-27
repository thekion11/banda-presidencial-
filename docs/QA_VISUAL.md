# QA visual de todas las pantallas (27-nov-2026)

Seis hojas de contacto con las 18 pantallas y estados del recorrido (`RecorridoUI`), capturadas con **ventanas reales** bajo xvfb, en tres tamaños y con letra normal y grande («Texto grande», ×1,15):

| Ventana | Lienzo lógico | Hojas |
|---|---|---|
| 360 × 640 (16:9) | 390 × 693 | `docs/comparacion/hoja_contacto_360x640_normal.png`, `…_grande.png` |
| 390 × 844 (referencia) | 390 × 844 | `docs/comparacion/hoja_contacto_390x844_normal.png`, `…_grande.png` |
| 480 × 1000 | 390 × 813 | `docs/comparacion/hoja_contacto_480x1000_normal.png`, `…_grande.png` |

Se regeneran con `tests/hoja_contacto.gd`, una corrida por ventana y letra (las instrucciones están en su cabecera), y después `python3 tools/hoja_contacto.py <carpeta> docs/comparacion`.

## Hallazgos y qué se hizo

1. **Grave: los teléfonos 16:9 se veían achicados y con bandas.** El proyecto usa `keep_width` con base 390 × 844, y en Godot ese modo solo agrega alto cuando la pantalla es *más alta* que 390:844. En un 360 × 640, que es más ancho, el juego mostraba 390 × 844 reducido al 82 %, con bandas a los lados (295 × 640 útiles) y letra bajo el mínimo de 10 pt. Las pruebas no lo veían porque simulan el alto cambiando la base en headless. **Corregido:** `Main.base_para` fija la base lógica en 390 × (alto de la pantalla): un 360 × 640 queda en 390 × 693, como suponían el diseño y las pruebas. La prueba está en `tests/test_claridad.gd`. Verificado con ventanas reales: 360×640 → 390×693, 390×844 → 390×844, 480×1000 → 390×813 y tablet 768×1024 → 390×844 con bandas (a propósito).
2. **La marca del mínimo tapaba «Requiere N votos…».** En el teléfono bajo, la línea y el rótulo «mín. 26» del hemiciclo se dibujaban por encima de su rectángulo. **Corregido:** el radio deja sitio a la marca.
3. **La cifra central de la votación se montaba sobre los asientos** con el hemiciclo achicado. **Corregido:** cifra y asientos escalan con el radio. En 390 × 844 no cambia nada: las cifras de la maqueta quedaron idénticas.
4. **Sin defecto, solo para tenerlo en cuenta:**
   - El aviso dorado de arriba («Circula una noticia falsa…») aparece en varias capturas porque el recorrido avanza más rápido que sus 2,6 s; se va solo.
   - En el Comité, el Gabinete y el fin, las tarjetas se cortan bajo el botón principal porque están dentro de una lista desplazable.
   - En el evento de prueba, la descripción «x» es un dato del recorrido.

Revisado a ojo en las seis hojas, sin otros problemas: no hay texto cortado fuera de las listas, ni botones tapados, ni superposiciones. Los títulos largos de la letra grande se parten en dos líneas.
