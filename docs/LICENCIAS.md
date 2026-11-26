# Licencias y atribuciones (auditoría del 26-nov-2026)

Resumen de todo lo que entra al APK y bajo qué licencia. «Abierto» = decisión o confirmación que depende del usuario o de un tercero.

| Componente | Origen | Licencia | Estado |
|---|---|---|---|
| Motor | Godot 4.x | MIT (aviso de licencias en Créditos de Godot) | Mostrar el aviso en Créditos antes de publicar |
| Tipografías Space Grotesk e Inter | Google Fonts | SIL OFL 1.1; textos en `game/fuentes/OFL-*.txt` | Hecho |
| Sonidos y música (`game/audio/`, 25 archivos) | Sintetizados por código del repositorio (`game/audio/LEEME.txt`) | Propios, sin muestras de terceros | Hecho |
| Calles, Metro, río, parques y edificios de Gran Santiago (`data/geo/urbano_real.json`, `grafo_urbano.json`, `edificios_santiago.bin`) | Extracto BBBike de OpenStreetMap | ODbL 1.0: atribución «© colaboradores de OpenStreetMap» (ya en Créditos) y, por ser base derivada distribuida, ofrecer esa base bajo ODbL | **Abierto:** falta `data/geo/LICENCIA.md` (ver A4 en `docs/REVISION.md`); este documento lo reemplaza como aviso provisional |
| Relieve (`relieve*.png`, `elevacion_santiago.bin`) | Teselas Terrarium (SRTM, NED, GMTED y otras) | Cada fuente exige atribución | Citadas en Créditos; **Abierto:** listar cada fuente |
| Límites regionales (`regiones_mapa.json`, `sudamerica.json`) | GeoJSON público (`caracena/chile-geojson`) y Natural Earth | Natural Earth: dominio público; el GeoJSON de regiones no declara licencia | **Abierto:** sustituir por datos BCN/IDE o confirmar con el autor |
| Líneas 7, 8, 9 del Metro (`metro_futuro.json`) | OpenStreetMap; colores de Wikipedia/Wikidata | ODbL; Wikipedia CC BY-SA 4.0 (solo datos factuales) | Sin confirmar por Metro S.A. |
| Estaciones del Metro en operación | GTFS Red Metropolitana (DTPM) | Datos abiertos del Estado de Chile | Citado en Créditos |
| Planes de SECTRA (`data/sectra_planes.json`) | Sitio público de SECTRA | Sin licencia de reutilización citada | **Abierto:** pedir autorización (A6) |
| Cifras y proyectos (DIPRES, MOP, MINVU, MINSAL, Servel, BCN, INE) | Sitios oficiales; cada una en `data/fuentes.json` con fecha de corte | Información pública; las cifras ilustrativas van rotuladas | Hecho; ver auditoría de fuentes abajo |
| Ilustraciones de cartas y portada (`game/arte/`, `docs/arte_originales/`) | Gemini, Canva y Figma (generación con IA) | Uso comercial **sin confirmar** (`docs/ARTE_PROMPTS.md`) | **Abierto:** confirmar términos antes de publicar |
| Código del repositorio | Propio | Sin archivo `LICENSE` | **Abierto:** el usuario decide si lo publica y con qué licencia |

## Auditoría de `data/fuentes.json` (122 entradas)
- Sin ids duplicados, todas las URL son https, ninguna fecha de corte es futura y ninguna está vencida según su `vigencia_dias`.
- Seis URL se comparten entre entradas distintas (sitios institucionales genéricos como `mop.gob.cl`, `minvu.gob.cl`): aceptable porque las entradas `curados_*` documentan lotes de proyectos y la institución es la misma, pero conviene enlazar a la página exacta cuando se verifique cada lote.
- 109 entradas llevan `verificado_contra_texto`; 13 no lo traen (las ilustrativas, las de herramientas geoespaciales y las de calendario). Entradas con `verificado_contra_texto: false` (p. ej. las `curados_*`, Wikipedia y las de leyes 18.603 y 19.039) siguen pendientes de verificación humana: `docs/PENDIENTES_USUARIO.md`.
- 13 entradas no se citan desde ningún dato, código ni documento (`osm_odbl`, `copernicus_dem`, `geojson_regiones`, `servel_fecha_constitucion_regiones_2026`, `ley_18603_partidos`, `ley_19039_marcas`, `wikipedia_parlamentarias_2021/2025`, `servel_elecciones_2025_zip`, `senado_votaciones_xml`, `metro_estaciones_wikipedia`, `gtfs_red_metro`, `metro_futuro_osm`): documentan el origen de datasets o herramientas (tools/geo) y se conservan como respaldo; no se borran para no perder trazabilidad.
- Wikipedia aparece como fuente de 4 entradas (resultados electorales 2021/2025, estaciones del Metro): están marcadas como no verificadas y deben contrastarse con Servel antes de publicar.
