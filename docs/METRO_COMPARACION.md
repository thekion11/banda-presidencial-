# Metro del mapa vs. lista de estaciones (cotejo automático)

Fuente de la lista: Wikipedia en español, artículos de cada línea del Metro de Santiago (https://es.wikipedia.org/wiki/Línea_1_del_Metro_de_Santiago y análogos L2, L3, L4, L4A, L5, L6) (corte 2026-11-24).
**Lista de Wikipedia en español cotejada contra el GTFS oficial de la Red Metropolitana (DTPM, V171.20261114): coincide en nombres y orden en las 7 líneas (solo difiere la abreviatura «Pdte.» de L6). metro.cl respondió 403.**

Geometría del mapa: OpenStreetMap (© colaboradores, ODbL), extracto de Gran Santiago (ventana lon -70,80..-70,52; lat -33,57..-33,38).

| Línea | Estaciones (lista) | Dentro del mapa | Fuera de la ventana | Terminales dentro |
|---|---|---|---|---|
| L1 | 27 | 27 | — | San Pablo sí, Los Dominicos sí |
| L2 | 26 | 24 | Copa Lo Martínez, Hospital El Pino | Vespucio Norte sí, Hospital El Pino NO |
| L3 | 21 | 16 | Plaza Quilicura, Lo Cruzat, Ferrocarril, Los Libertadores, Cardenal Caro | Plaza Quilicura NO, Fernando Castillo Velasco sí |
| L4 | 23 | 19 | Hospital Sótero del Río, Protectora de la Infancia, Las Mercedes, Plaza de Puente Alto | Tobalaba sí, Plaza de Puente Alto NO |
| L4A | 6 | 6 | — | Vicuña Mackenna sí, La Cisterna sí |
| L5 | 30 | 30 | — | Plaza de Maipú sí, Vicente Valdés sí |
| L6 | 10 | 10 | — | Cerrillos sí, Los Leones sí |

## Cotejo con el GTFS oficial (Red Metropolitana, DTPM)
Fuente: Red Metropolitana de Movilidad (DTPM), GTFS vigente V171.20261114 (vigencia 2026-11-14 a 2026-12-31; corte 2026-11-24). https://www.dtpm.cl/descargas/gtfs/GTFS_20261114_v2.zip
Nombres y orden de las 7 líneas iguales a la lista; 132 estaciones del mapa comparadas en posición: la mayor diferencia es de 175 m (límite 250 m).


Estaciones distintas en la lista: 126; en el mapa: 115.
Todas las estaciones del mapa calzan con una línea de la lista y ninguna está a más de 0.012 del trazado de su línea.

## Qué no cubre el mapa
Las 11 estaciones fuera de la ventana son extensiones periféricas (L2 sur, L3 norte, L4 sur); el mapa las indica con una flecha en el borde.

## Líneas futuras (no se dibujan; fuente y fecha en data/metro_oficial.json)
- L7: en construcción, apertura est. 2028
- L8: en licitación, apertura c. 2032-2033
- L9: en construcción por tramos, apertura 2030 (Bío Bío - La Pintana), 2032, 2033
- Extensión L6: en construcción, apertura desde 2028 (Lo Errázuriz, Isidora Goyenechea)

## Discrepancias abiertas
- Los Leones L1-L8: 2033 (L1 y L8) frente a 2030 (L6), sin resolver
