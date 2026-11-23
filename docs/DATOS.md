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
