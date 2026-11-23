# Datos, fuentes y licencias

Todo dato real vive en `data/` y apunta a `data/fuentes.json` con enlace y fecha de corte. `tools/validate_data.py` avisa cuando una fuente vence o no ha sido verificada.

| Dato | Origen | Estado |
|---|---|---|
| Límites regionales (`data/geo/regiones_mapa.json`) | GeoJSON público de regiones de Chile (repositorio `caracena/chile-geojson`), simplificado con `tools/geo/simplificar_regiones.py` | **Verificar la licencia del origen antes de publicar**; alternativa: generar desde datos oficiales de la BCN/IDE con licencia clara. |
| Población por región | Censo 2017 (INE), cifras en miles de memoria | **Verificar** y actualizar con Censo 2024. Marcada como ilustrativa. |
| Quórums y artículos | Constitución (BCN Ley Chile) | **Sin verificar contra el texto.** |
| Presupuesto, vivienda | DIPRES, MINVU | Ilustrativas (fecha de corte 2026-04-15). |
| Eventos inventados | `ficticio_2026` | No representan hechos reales. |
| Calles, Metro, río y parques de Gran Santiago (`data/geo/urbano_real.json`, `grafo_urbano.json`) | Extracto de BBBike de OpenStreetMap (ODbL), procesado con `tools/geo/osm_santiago.py` | **Hecho.** Obligatoria la atribución « © colaboradores de OpenStreetMap » (visible en los mapas y Créditos). Overpass y Geofabrik no estaban accesibles desde el entorno de desarrollo; BBBike sí. Los costos y expropiaciones del grafo son ilustrativos. |
| Edificios y lugares de Gran Santiago (`data/geo/edificios_santiago.bin`, 83.574 edificios; lista `lugares` en `urbano_real.json`) | Mismo extracto de OpenStreetMap, procesado con `tools/geo/osm_edificios.py` | Hecho. Las alturas salen de `building:levels` cuando existe; si no, se estiman (2–5 pisos). El 3D exagera visualmente planta y altura. |
| Relieve de Gran Santiago (`relieve_santiago.png`, `elevacion_santiago.bin`) | AWS Terrain Tiles (Terrarium), `tools/geo/relieve_urbano.py` | Hecho. Elevaciones reales (450–1.223 m) con exageración ×1,8 en el 3D. |
| Relieve (teselas de elevación) | AWS Terrain Tiles (Terrarium), ver arriba | Hecho para el mapa nacional. Copernicus DEM GLO-30 sigue pendiente. |
| Ilustraciones de cartas (`game/arte/cartas/*.jpg`) | Generadas con IA (modelo de imágenes de Figma, 2026-11-23) a partir de prompts propios; 14 categorías, 512×410 | Declarar el uso de IA en la ficha de Google Play. Algunas escenas incluyen la bandera chilena. Revisar derechos de uso comercial según los términos de Figma AI. Los prompts están en el historial del proyecto. |
| Partidos políticos (`data/partidos/`) | Servel (nómina y fechas, verificado); escaños de Wikipedia; historial de BCN y prensa; réplicas ficticias propias | Ver `docs/PARTIDOS.md`: huecos y advertencia legal (no es asesoría). |
| Tipografías | Space Grotesk e Inter (SIL OFL 1.1) | Licencias en `game/fuentes/`. |

Regenerar el mapa:
```
curl -sL -o regiones.json https://raw.githubusercontent.com/caracena/chile-geojson/master/regiones.json
python3 tools/geo/simplificar_regiones.py regiones.json 0.02
```

Regenerar la cartografía urbana:
```
curl -sL -o Santiago.osm.pbf https://download.bbbike.org/osm/bbbike/Santiago/Santiago.osm.pbf
pip install osmium
python3 tools/geo/osm_santiago.py Santiago.osm.pbf
python3 tools/geo/osm_edificios.py Santiago.osm.pbf
python3 tools/geo/relieve_urbano.py
```

**Sobre Google Maps:** sus mapas, teselas y datos no se pueden copiar ni guardar sin conexión en una app (términos de servicio), y exigen clave de pago. OpenStreetMap ofrece cartografía comparable con licencia ODbL, por eso es la base del juego.

## Plan Maestro de Transporte (SECTRA) — `data/sectra_planes.json`

- Fuente: sitio público de SECTRA (`sectra.gob.cl`, tipo de contenido «plan-y-proyecto», API REST de WordPress). Extraído con `python3 tools/sectra_planes.py`; registrado en `data/fuentes.json` (`sectra_planes`). Inversión en UF; la conversión a US$ usa una aproximación fija (`uf_aprox`, `leyes.json › sectra.uf_en_usd`).
- Cobertura real: 14 regiones con proyectos (452 proyectos). **Región Metropolitana y Aysén no publican proyectos en el sitio**: no se inventan; el juego no muestra cartera SECTRA para ellas.
- Salvedades: los montos de «cartera» por ciudad son inconsistentes entre páginas (no se usan); 83 proyectos no informan inversión y varios no informan TIR o mandante (se muestran como «s/d»); los estados se normalizan a etapas (perfil, prefactibilidad, diseño, ejecución); los ya en ejecución o terminados no se gestionan.
- Mecánica (`sim/motor_sectra.gd`): impulsar un proyecto cuesta PA y lo hace avanzar una etapa tras N semanas (máx. 3 simultáneos); al llegar a ejecución se crea una obra con la inversión real y un efecto de aprobación según su TIR. Todos los parámetros viven en `leyes.json › sectra`. Se guarda como entrada `sectra` (replay exacto). Prueba: `tests/test_sectra.gd`.

## Base legal y línea de tiempo real (`data/bcn/`, `data/eventos_reales.json`)

Corte: 2026-11-23. Todo se regenera con scripts de `tools/`; ninguno esquiva bloqueos (LeyChile/BCN devuelve 401 a clientes automáticos, por eso los PDF oficiales se bajan a mano).

| Archivo | Contenido | Fuente / script | Verificación |
|---|---|---|---|
| `bcn/normas.json` | Constitución con 29 artículos clave (cita literal + regla/quórum), LOC y DL estructurales, Ley 20.955, DFL 1 Justicia 2000, y ~160 leyes publicadas 2022-2026 | PDF oficial BCN (Constitución al 7-oct-2025) y WS del Senado · `tools/bcn_normas.py` | Citas comprobadas como subcadena del texto oficial. LOC/DL: `verificado:false` (fecha y texto pendientes) |
| `bcn/reformas_constitucionales.json` | 29 leyes de reforma citadas en las notas del texto vigente, con fecha | Notas del PDF · `tools/bcn_reformas.py` | Fecha única = verificado; 20.990 cita dos fechas (queda sin verificar). Artículo afectado sólo confirmado para 21.481, 21.654 y 21.233 |
| `bcn/reformas_propuestas.json` | Propuestas 2022 y 2023 + 112 proyectos que modifican la Constitución | Wikipedia (propuestas) y WS Senado/Cámara · `tools/reformas_propuestas_build.py` | Propuestas: secundaria. Normas sustantivas de 2023: hueco |
| `bcn/proyectos_ley.json` | 1.270 boletines (mensajes 2022-2026 y mociones desde 2025-11-01) con estado, urgencia, ley y Diario Oficial | `opendata.camara.cl` + `tramitacion.senado.cl` · `tools/bcn_proyectos.py` | Primaria. `tema` es una heurística por palabras clave |
| `bcn/resultados_2da_vuelta_2025.json` | Segunda vuelta 14-dic-2025 por región y extranjero | Sentencia de proclamación del Tricel (PDF escaneado, transcrito a mano) | Cada fila cuadra; hay 2 votos de diferencia por candidato frente al total oficial (anotado) |
| `eventos_reales.json` | Hitos verificables (electorales, legislativos, institucionales, económicos) | `tools/eventos_reales_build.py` | `verificado:true` sólo con fuente primaria; el resto lleva `nivel_verificacion` |

Huecos conocidos: series de IPC, dólar, cobre y tasa (mindicador.cl y APIs del Banco Central no accesibles); resultados de primera vuelta por región (la única tabla disponible es secundaria y no cuadra); texto sustantivo de la propuesta 2023; quórums y fechas de leyes sectoriales no originadas en un boletín reciente; conflictos sociales y desastres 2025-2026.

Regenerar: `python3 tools/bcn_proyectos.py --cache /tmp/cache`, `python3 tools/bcn_normas.py --cpr constitucion.pdf --pdf ley.pdf`, `python3 tools/bcn_reformas.py --cpr constitucion.pdf`, `python3 tools/reformas_propuestas_build.py`, `python3 tools/eventos_reales_build.py` y `python3 tools/validate_data.py`.
