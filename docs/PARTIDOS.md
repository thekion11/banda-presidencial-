# Partidos políticos: datos reales y réplicas ficticias

Archivos: `data/partidos/partidos_reales.json` (hechos públicos con fuente) y `data/partidos/partidos_juego.json` (réplicas ficticias que usa el juego). Validación: `python3 tools/validate_data.py` (módulo `tools/validate_partidos.py`). Fecha de consulta: 2026-11-23.

## Criterio

1. **Lista.** Partidos con constitución legal vigente según la nómina del Servel (`servel_partidos_constituidos`, tabla regional con actualización al 30-sep-2026): **15 partidos**. Los 13 disueltos en febrero de 2026 (Ley 18.603, arts. 56 N°2 y 57) figuran en `disueltos_2026` con su estado; el Tricel revocó el 24-abr-2026 las disoluciones de Evópoli y de la FRVS. El Partido Radical figura como constituido en el Servel; su fallo del Tricel no se pudo confirmar (hueco).
2. **Solo hechos neutrales.** Fechas, regiones, citas textuales de principios (solo donde `verificado: true`), coaliciones, votos documentados y escaños. Sin calificativos.
3. **Fuente primaria primero.** Servel para existencia, fechas y regiones (verificado). Las cifras de escaños salen de Wikipedia (secundaria) y llevan `verificado: false`. Las posiciones salen de prensa, BCN y sitios de la Cámara y del Senado; los votos por partido solo existen donde la fuente los entrega.
4. **Réplicas ficticias.** Una por partido real (`real_ref`). Nombre y sigla propios, sin parecido con el real (el validador compara nombres y rechaza siglas reales). Posición en los ejes de `data/ideologia.json` (`eje_eco`: -1 estatista a +1 mercado; `eje_inst`: -1 ruptura o regionalismo a +1 institucionalidad), con `justificacion` que cita los hechos del historial. Los valores son estimaciones editoriales y las cuotas (`pide`, `rechaza`) y los escaños están rotulados `cifras_ilustrativas`.
5. **Huecos conocidos** (también en `meta.huecos`): voto por partido en la Cámara (pensiones 2025, tributarias, matrimonio igualitario, aborto), tributaria 2020, seguridad y medioambiente casi vacíos, declaración de principios sin texto primario para PCCh, FA, UDI, PNL, Radical, Cristiano, FRVS y PDG, y composición del Senado 2022-2026 por partido.

## Uso de nombres reales

> **No es asesoría legal.** Lo que sigue es lo que se encontró en fuentes públicas. No se puede concluir que usar solo el nombre de un partido real sea seguro sin la revisión de un abogado chileno.

**Ley 18.603 (partidos políticos).** El art. 8 (texto leído en una copia de Justia Chile; contrastar con la versión vigente de BCN) dice que el nombre, la sigla, el símbolo y el lema de un partido no pueden presentar igualdad ni manifiesta similitud gráfica o fonética con los de partidos ya inscritos, ni llevar el nombre de personas vivas o fallecidas, y que no se aceptan imágenes que permitan identificar personas. La norma regula la inscripción de partidos, no los videojuegos. Se usa como criterio de prudencia: los nombres ficticios no se parecen a los reales, y esa misma regla impediría que un partido creado por el jugador copie uno real.

**Marcas (INAPI, Ley 19.039 / DFL 4 de 2022).** El art. 20 (copia de Justia, versión anterior al DFL) prohíbe registrar como marca, entre otros, el nombre o retrato de una persona sin su consentimiento (letra c) y los signos que se presten a error o engaño (f) o que sean iguales o parecidos a marcas ya registradas en la misma clase (h). No se encontró información sobre si los partidos tienen marcas registradas, ni sobre cómo se trata la parodia en la práctica del INAPI. Hueco: consultar la base de INAPI por cada nombre y emblema.

**Honra y libertad de expresión.** La Constitución garantiza el respeto y la protección de la honra (art. 19 N°4) y la libertad de emitir opinión (art. 19 N°12); la Ley 19.733 regula las libertades de opinión e información. No se revisó jurisprudencia chilena sobre sátira política en videojuegos ni sobre uso del nombre de organizaciones. El documento de diseño ya fija "políticos reales con alias satíricos"; las organizaciones reales no tienen ese resguardo explícito. Hueco: parecer jurídico.

**Google Play.** La política de suplantación de identidad (Impersonation) prohíbe apps que se hagan pasar por una persona u organización, que oculten su finalidad o que sugieran una afiliación falsa, y pide no coordinarse para engañar a los usuarios en contenido político. La política de comportamiento engañoso (4.2) admite excepciones para "obvious satire or parody", pero esa excepción está en la sección de contenido manipulado, no en la de suplantación. Llamar "broma" a una app no la exime. Fuentes: `google_play_suplantacion`, `google_play_conducta_enganosa`.

**Conclusión.** Hay riesgo que no se puede descartar con fuentes públicas: marca, honra y reglas de la tienda. **La opción predeterminada es la conservadora: réplicas ficticias** (`partidos_juego.json`), sin nombres, siglas ni emblemas reales en la interfaz. Los nombres reales quedan en `partidos_reales.json` solo como respaldo de datos y para la pantalla de créditos y fuentes, y la decisión de mostrarlos en el juego requiere revisión de un abogado chileno antes de publicar.

## Ficha de las réplicas

| Real (Servel) | Réplica | Sigla | Bloque | Eco | Inst |
|---|---|---|---|---|---|
| Partido Socialista de Chile | Movimiento Laborista Reformista | MLR | Bloque de la Aurora | -0.50 | 0.20 |
| Partido Por la Democracia | Convergencia Progresista Cívica | CPC | Bloque de la Aurora | -0.20 | 0.35 |
| Partido Demócrata Cristiano | Concordia Comunitaria de Centro | CCC | Bloque de la Aurora | -0.10 | 0.45 |
| Partido Comunista de Chile | Frente Obrero Popular | FOP | Bloque de la Aurora | -0.85 | -0.30 |
| Frente Amplio | Movimiento Horizonte Común | MHC | Bloque de la Aurora | -0.65 | -0.35 |
| Partido Liberal de Chile | Sociedad Abierta Ciudadana | SAC | Bloque de la Aurora | 0.00 | 0.00 |
| Partido Radical de Chile | Liga Laica Reformista | LLR | Bloque de la Aurora | -0.25 | 0.40 |
| Federación Regionalista Verde Social | Confederación Territorial Ecosocial | CTE | Pacto Costa y Cordillera | -0.35 | -0.55 |
| Renovación Nacional | Compromiso Cívico Austral | CCA | Bloque del Faro | 0.40 | 0.60 |
| Unión Demócrata Independiente | Cuerpo Gremial Solidario | CGS | Bloque del Faro | 0.65 | 0.65 |
| Evolución Política | Vanguardia Cívica Moderna | VCM | Bloque del Faro | 0.55 | 0.45 |
| Partido Republicano de Chile | Frente por la Tradición y el Orden | FTO | Frente del Roble | 0.70 | 0.50 |
| Partido Nacional Libertario | Liga de la Libertad Individual | LLI | Frente del Roble | 0.95 | -0.20 |
| Partido de la Gente | Plataforma Voz Directa | PVD | Independiente (sin pacto) | 0.15 | -0.50 |
| Partido Cristiano de Chile | Concilio Cívico por la Familia | CCF | Frente del Roble | 0.45 | 0.40 |
