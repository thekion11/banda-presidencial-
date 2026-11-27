# Propuesta D25: proyectos de transporte de la Región Metropolitana y Aysén para el panel SECTRA (27-nov-2026)

**Origen:** pedido del usuario vía la coordinadora («Faltan», captura del selector con 14 de 16 regiones). Solo investigación y propuesta: `data/` está congelado. Lectura de fuentes hecha por un agente de lectura; lo no leído en la página se marca NO VERIFICADO.

## Hallazgos
- **Aysén sí tiene página SECTRA** (https://www.sectra.gob.cl/plan-y-proyecto/region-de-aysen-del-general-carlos-ibanez-del-campo/) con 7 proyectos, todos en Coyhaique; `data/sectra_planes.json` no la trae (hueco de la descarga, no de la fuente). La página no indica unidad ni fecha del dato.
- **RM: SECTRA no publica proyectos** (confirma la nota del juego); hay que usar otras fuentes (EFE, MTT, MOP, Metro).
- **El resto del motor cubre las 16 regiones:** `data/regiones.json` tiene 16 filas, los pesos suman 1 y la elección por población usa las 16 (`tests/test_voto_regional.gd`).

## Aysén (leído en la página de SECTRA; inversión SIN unidad ni fecha)
| Proyecto (Coyhaique) | Etapa | Mandante | Inversión (sin unidad) |
|---|---|---|---|
| Par 12 de Octubre – Arturo Prat | Ejecución terminada | SERVIU | 17,72 |
| Prolongación doble calzada Av. Baquedano | Diseño terminado | MOP | 359,081 |
| Prolongación Los Pilcheros | Perfil terminado | MTT | 38,599 |
| Prolongación Héctor Monreal | Perfil terminado | MTT | 77,119 |
| Par Ignacio Serrano – Sargento Aldea | Ejecución terminada | SERVIU | 18,562 |
| Par Bilbao – Pdte. Errázuriz (Magallanes a Victoria) | Ejecución terminada | SERVIU | 30,285 |
| Ampliación perfil Almirante Simpson (Ogana a Victoria) | Diseño terminado | SERVIU | 154,89 |
No se encontró proyecto urbano de transporte de Puerto Aysén en fuente oficial leída.

## Región Metropolitana (leído en fuente oficial)
| Proyecto | Tipo | Inversión | Etapa | Mandante | Fuente (fecha) |
|---|---|---|---|---|---|
| Tren Santiago–Batuco (obras superficiales) | ferrocarril | US$ 470 millones el contrato; US$ 950 millones el total | Ejecución desde el 25-ago-2025; servicio parcial 2028, total 2030 | EFE | efe.cl, 25-ago-2025 |
| Señalización Batuco y Melipilla | ferrocarril | 4,45 millones de UF | Adjudicado | EFE | efe.cl/proyectos/santiago-batuco |
| Tren Alameda–Melipilla | ferrocarril | US$ 1.877 millones (estimada) | Construcción parcial; tramo a Estación Central en licitación | EFE | efe.cl/proyectos/alameda-melipilla |
| Eje Bandera (buses, 1,6 km) | buses | $ 1.249 millones (unidad inferida) | Reapertura, marcha blanca | MTT | mtt.gob.cl, 2-oct-2026 |
**NO VERIFICADOS** (de buscador, metro.cl da 403): Metro L7 (US$ 2.528 M), L8 (US$ 1.899,5 M), L9 (US$ 2.732–2.733 M), extensión L2 (US$ 409,2 M), AVO II (UF 19,67 M presupuesto oficial). Ver `VERIFICACION_PROYECTOS.md`.

## Inconsistencias vistas
EFE da Batuco en US$ 950 M y en US$ 705 M (2022); L9 en 2.732 y 2.733; la apertura de L7 pasó de 2027 a fines de 2028; SECTRA Aysén da cifras sin unidad (359,081 para Baquedano no puede cargarse como UF sin confirmar).

## Propuesta de carga (sin mecánica nueva)
Mismo esquema de ciudad que las otras en `sectra_planes.json` (`id`, `titulo`, `region_id`, `proyectos[]` con id, nombre, etapa, mandante), pero con **inversión como valor + unidad + fecha** (`inversion_valor`, `inversion_unidad`: UF | CLP_MM | USD_MM | sin_unidad, `fecha_dato`, `fuente_url`, `verificado`) porque `inversion_uf` obliga a convertir y perder trazabilidad. Las filas sin unidad se cargan con `sin_unidad` y sin monto en el panel.
- **Costo:** cambia `data/sectra_planes.json`: huella y oros (como todo cambio de datos), `data/` congelado (D17), exige autorización del usuario y debe entrar antes de repartir la prueba cerrada. El esquema nuevo toca el validador (`validate_data.py`) y la UI del panel (visual).
- **Recomendación:** cargar solo lo leído en fuente oficial (Aysén: 7 filas con unidad «sin unidad»; RM: 4 filas), marcar el resto como pendiente, y hacerlo antes de la prueba cerrada si el usuario autoriza descongelar `sectra_planes.json`. Alternativa sin tocar `data/`: que la UI muestre las 16 regiones con el mensaje «sin proyectos publicados por SECTRA», que es lo que visual ya hace.
