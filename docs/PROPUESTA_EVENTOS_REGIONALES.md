# Propuesta: 16 eventos regionales (26-nov-2026) — SIN IMPLEMENTAR

**Estado: propuesta para decisión del usuario.** Agregar contenido y un campo nuevo de evento toca el alcance congelado (CLAUDE.md §2); no se agregó nada a `data/`. Motivo (`docs/EQUIDAD_REGIONAL.md`): 95 de 97 eventos reales y los 142 diseñados son nacionales, así que ningún evento mueve la aprobación de una sola región.

## Qué se necesita
- **Datos (16 eventos).** Un evento por región en `data/eventos.json`: `tipo: aleatorio_semilla`, `etapa: gobierno`, `familia: regional`, `peso_sorteo` bajo (0,02 a 0,04, como los externos), dos o tres `opciones` con costo y beneficio como el resto de las decisiones, y `meses` cuando son estacionales (incendios en verano, temporal en invierno). Todas las cifras rotuladas «ilustrativo»; el hecho real que los inspira lleva fuente y fecha de corte en `data/fuentes.json`.
- **Un campo nuevo y una función pequeña (≈ 10 líneas en `sim/motor_eventos.gd`).** Hoy `aplicar_evento` aplica los efectos con región vacía (nacionales). Hace falta un campo opcional `region` (id de `data/regiones.json`) en el evento y en sus opciones, que pase a `MotorEfectos.aplicar_efecto(ef, 1.0, region)`; el soporte regional de `delta_aprobacion` ya existe y se prueba (`test_unidades_sim`). Más una regla en `tools/validate_referencias.py` (la región debe existir) y una prueba que dispare un evento regional y compruebe que mueve esa región (derrame al resto según `campana.derrame_regional`).
- **Cambia el azar** (nuevos sorteos): se regeneran los oros y se repite el Monte Carlo (≈ 1 hora de trabajo).

## Los 16 eventos (borrador)
| Región | Hecho real que lo inspira (fuente por verificar) | Decisión que ofrece | Estación |
|---|---|---|---|
| Arica y Parinacota | Presión migratoria en la frontera de Chacalluta (Servicio Nacional de Migraciones, Policía de Investigaciones) | Reforzar la frontera, un plan humanitario o negociar con Perú | Todo el año |
| Tarapacá | Campamentos y tomas en Alto Hospicio (MINVU, Catastro Nacional de Campamentos) | Desalojar, urbanizar los campamentos o un plan de vivienda | Todo el año |
| Antofagasta | Sequía y precios del cobre en Calama (Cochilco, DGA) | Plan hídrico, apoyo a pymes mineras o esperar | Todo el año |
| Atacama | Aluviones por lluvias de verano (SENAPRED, 2015 y 2017) | Emergencia inmediata, reconstrucción o seguro de desastres | Verano |
| Coquimbo | Sequía de más de una década (DGA, Ministerio de Agricultura) | Embalses, desalinización o camiones aljibe | Todo el año |
| Valparaíso | Incendio forestal con víctimas en Viña del Mar (CONAF, 2024) | Declarar catástrofe, subsidio de reconstrucción o fiscalización de campamentos | Verano |
| Metropolitana de Santiago | Alerta ambiental invernal por contaminación (Seremi del Medio Ambiente) | Restricción vehicular, subsidio de calefacción limpia o campaña | Invierno |
| O'Higgins | Heladas que arruinan la fruta (INDAP, Ministerio de Agricultura) | Seguro agrícola, créditos o nada | Primavera |
| Maule | Incendios forestales de 2023 y forestales (CONAF) | Plan de manejo, indemnizaciones o cortafuegos | Verano |
| Ñuble | Incendios y reconstrucción en la Región (CONAF, SENAPRED) | Brigadas permanentes, subsidio o espera | Verano |
| Biobío | Cierre de acerías y empleo industrial en Concepción (Huachipato, 2024) | Reconversión, subsidio a la planta o dejar que opere el mercado | Todo el año |
| La Araucanía | Seguridad rural en la macrozona sur (Ministerio del Interior) | Estado de excepción, diálogo o plan de inversión | Todo el año |
| Los Ríos | Temporal e inundaciones en Valdivia (SENAPRED, DGA) | Defensas fluviales, ayuda inmediata o plan de manejo de cuencas | Invierno |
| Los Lagos | Marea roja y salmonicultura (SERNAPESCA, Subpesca) | Compensar a pescadores, fiscalizar o dejar actuar a la industria | Verano |
| Aysén | Aislamiento por cortes de la Carretera Austral (MOP) | Conectividad aérea, mejorar la ruta o subsidio al transporte | Invierno |
| Magallanes y la Antártica Chilena | Gas y conectividad de Punta Arenas (ENAP, Subtel) | Subsidio al gas, nuevo gasoducto o conexión por fibra | Todo el año |

Las 16 filas son un **borrador de temas**: cada una debe validarse contra su fuente oficial antes de escribir el evento (fecha, cifras y lenguaje neutro, sin nombrar autoridades reales: CLAUDE.md §2).

## Costo y recomendación
Medio día para el código y la validación, más la redacción de 16 eventos (textos cortos de ≤ 260 caracteres, opciones de ≤ 80) y su verificación. **Recomendación:** esperar la prueba cerrada; si los testers sienten el juego «centralista» o «sin lugares», aprobar esta propuesta (decisión D8 en `docs/DECISIONES_PENDIENTES.md`).
