# Equidad regional del contenido (26-nov-2026)

Conteo hecho sobre `data/cartas.json`, `cartas_reales.json` y `cartas_curadas.json` (1.964 cartas) y `data/eventos_reales.json` (97 eventos), contra la población de `data/regiones.json`. «Índice» = % de cartas de la región ÷ % de población (1,0 = proporcional).

| Región | Población % | Cartas con región | % | Obras (de ellas) | % | Índice |
|---|---|---|---|---|---|---|
| Metropolitana de Santiago | 40,5 | 160 | 25,2 | 120 | 23,3 | 0,62 |
| Valparaíso | 10,3 | 42 | 6,6 | 28 | 5,4 | 0,64 |
| Biobío | 8,9 | 46 | 7,2 | 38 | 7,4 | 0,82 |
| Maule | 5,9 | 61 | 9,6 | 56 | 10,9 | 1,62 |
| La Araucanía | 5,5 | 37 | 5,8 | 32 | 6,2 | 1,07 |
| O'Higgins | 5,2 | 29 | 4,6 | 23 | 4,5 | 0,88 |
| Los Lagos | 4,7 | 36 | 5,7 | 28 | 5,4 | 1,20 |
| Coquimbo | 4,3 | 38 | 6,0 | 33 | 6,4 | 1,39 |
| Antofagasta | 3,5 | 30 | 4,7 | 19 | 3,7 | 1,37 |
| Ñuble | 2,7 | 26 | 4,1 | 23 | 4,5 | 1,50 |
| Los Ríos | 2,2 | 23 | 3,6 | 22 | 4,3 | 1,65 |
| Tarapacá | 1,9 | 25 | 3,9 | 19 | 3,7 | 2,09 |
| Atacama | 1,6 | 24 | 3,8 | 19 | 3,7 | 2,32 |
| Arica y Parinacota | 1,3 | 18 | 2,8 | 17 | 3,3 | 2,20 |
| Magallanes y la Antártica Chilena | 0,9 | 22 | 3,5 | 20 | 3,9 | 3,65 |
| Aysén | 0,6 | 18 | 2,8 | 17 | 3,3 | 4,80 |

## Lectura
- **Ninguna región queda sin contenido**: la menor tiene 18 cartas de proyecto y 17 obras.
- **Está sesgado a favor de las regiones pequeñas**: Aysén y Magallanes tienen 3 a 5 veces más cartas que su peso poblacional. Es lo esperable en un juego donde cada región es un lugar a recorrer y la inversión pública por habitante es mayor allí; no es un defecto.
- **Las dos más pobladas quedan bajo lo proporcional** (Metropolitana 0,62; Valparaíso 0,64). El mapa urbano y el Comité 3D compensan en parte: toda la cartografía y los corredores detallados (5) son de Gran Santiago, no cuentan en esta tabla.
- **Maule es la más alta de las grandes** (1,62, 61 cartas de las cuales 56 son obras): conviene revisar si hay duplicados entre fichas del MOP y del MINVU en esa región (`tools/informe_cartas.py`).
- **1.329 de las 1.964 cartas (68 %) no tienen región** (leyes y reformas nacionales, y cartas diseñadas): ahí no hay desequilibrio posible.
- **Eventos reales: 95 de 97 son «nacional»**; solo 4 llevan región (Valparaíso 2, Los Ríos 1, Metropolitana 1). Los 142 eventos diseñados tampoco se ligan a una región. Es el hueco real: un evento regional (incendio, sismo, paro) no mueve la aprobación de su región.
- **Recomendación:** no cambiar el contenido ahora; si la prueba cerrada muestra que se siente «centralista», agregar eventos con región (≈ 16, uno por región, con el efecto en esa región ya soportado por `MotorEfectos.aplicar_efecto(…, region)`): son solo datos. Revisión de duplicados en Maule antes.
