# Decisiones que esperan al usuario: resumen de una página (26-nov-2026)

Nada de esto lo decidió un agente. Cada fila: qué hay hoy, la recomendación y a qué se asocia. Detalle y evidencia: `docs/DECISIONES_PENDIENTES.md` (D1 a D16, U4 a U10).

## Para la prueba cerrada (decidir primero)
| Decisión | Hoy | Recomendación |
|---|---|---|
| **Duración** (D1) | 208 semanas; ≈ 6 sesiones de 20 min por mandato (`DURACION_SESION.md`) | Mantener 208 y medir en la prueba cuántas semanas hace cada persona por sesión; pasar a «turno = mes» o «capítulos» solo si dicen «largo» |
| **Dificultad y umbral** (D2, D4, D16) | Normal: el bot que juega bien gana 94 %; Difícil 43 %; el puntaje en el gobierno es igual en las tres (solo cambia la campaña); umbral 52 | Esperar datos de personas. Si ganan más del 85 % en Normal, restar 1,5 de aprobación inicial; si quieres presión también al gobernar, que los presets toquen la dinámica (solo datos) |
| **Bono por aprobación** (D3) | Recalibrado 45 a 95 (efecto medible −5 %) | Dejarlo; los valores originales (60 a 100) lo dejan casi inerte |
| **Cohesión con desgaste** (D15) | −1,85 por semana: mediana 76 (antes pegada en 100); el codicioso cae en crisis 15 % (antes 4-7 %) | Mantener y revisar con la prueba; revertir es cambiar un número |
| **Métricas locales con consentimiento** | Propuesta sin implementar (`PRUEBA_CERRADA.md` §6) | Autorizarla: sin ella la prueba solo tiene lo que los testers cuenten |

| **Congelar `data/` durante la prueba** (D17) | Cualquier cambio de datos invalida las partidas guardadas de los testers | Sí: congelar `data/` y no regenerar `cartas_reales.json` (D18: 102 cartas cambiarían de evento y moverían los oros) hasta después de la prueba |
| **Renderizador** (`RENDERIZADORES.md`) | Proyecto en «mobile» (Vulkan), pero todo lo medido es `gl_compatibility`; Vulkan no se pudo medir | Pasar a `gl_compatibility` antes de la prueba (2 líneas en `project.godot`) |

## Diseño pendiente de decisión
| Decisión | Recomendación |
|---|---|
| **Cartas de «Estado»** (D5): solo se juegan el 7 % | Dar beneficio diferido a las 6 más baratas (solo datos) |
| **Leyes rechazadas sin alternativa** (D14): solo 7 de 1.964 cartas ofrecen una versión por tramos | Esperar la prueba (solo el 5 % se rechaza) |
| **Eventos en los años 2 a 4** (D8), **audiencia del debate** (D7), **delegación e internos** (D6) | Esperar la prueba cerrada |
| **Noche electoral y carta que sigue al dedo** (D9) | Requieren tu autorización (alcance congelado) |

## Interfaz
| Decisión | Hoy | Recomendación |
|---|---|---|
| **Mapa en 360×640** | Con la pantalla baja el mapa ocupa el 27 % (CLAUDE.md pide más de un tercio) | Aceptar 27 % en teléfonos bajos (son pocos); llegar al tercio exigiría achicar las cartas bajo 10 pt o quitar el Corrector |
| **Escala de letra del sistema Android** | Solo «Texto grande» (+15 %) propio; seguir la escala del sistema exige un plugin nativo | Dejar «Texto grande» y ofrecer un tamaño mayor solo si los testers lo piden |

## Publicación (en pausa)
| Decisión | Recomendación |
|---|---|
| **Keystore de release / Play App Signing, cuenta de desarrollador** (U10) | Crear el keystore tú (guía en `FIRMA_APK_PRUEBA_CERRADA.md`) y activar Play App Signing; cuando D1 y D2 estén decididos |
| **Licencias**: imágenes con IA, código del repositorio, SECTRA, GeoJSON de regiones, base ODbL derivada (`LICENCIAS.md`) | Confirmar las del arte y publicar la base ODbL antes de Play |
| **Revisión legal de alias y partidos** (U4); nombres oficiales que coinciden con apellidos (6 cartas) | Un abogado chileno antes de publicar |
| **~600 cartas de proyectos reales sin verificar** (D12); **artículo 25** (D11) | Mantener el rótulo de cifras ilustrativas y verificar por lotes; aportar el texto del artículo 25 |
| **`main` como rama por defecto** (U8) | Hacerlo (1 minuto en Settings) |
| **Texto del Art. 25 y de los incisos del Art. 66** (`VERIFICACION_CONSTITUCIONAL.md`): `bcn.cl` está bloqueado desde el entorno | Aportar el PDF actualizado de la Constitución: desbloquea modelar la reelección y verificar 3 reglas de quórum |
| **Riesgos de la ficha de Play** (`RIESGOS_PLAY_STORE.md`) | Leerlo antes de abrir la cuenta |

Para decidir, di el número (por ejemplo «D2 b»): se aplica, se mide con los bots, se regeneran los oros y queda en `docs/DECISIONES.md` el mismo día.
