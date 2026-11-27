# Verificación de fichas de proyectos (lotes, desde el 27-nov-2026)

`data/` está **congelado** (CLAUDE.md §2, D17), así que ninguna ficha se marca como verificada en los datos. Cada lote queda aquí y, lo aplicable, en `docs/VERIFICACION_PROYECTOS.json`; `tools/aplicar_verificacion.py` lo aplica de golpe (solo con `--descongelado`, autorizado por el usuario; luego hay que regenerar los oros). Solo se anota «aplicable» lo que se leyó en la fuente. Consulta del 27-nov-2026; lo leído por un agente de lectura, no por mí en persona.

## Lote 1 (9 fichas: Minsal oncológico, concesión hospitalaria y Metro)
| Ficha | Veredicto | Fuente leída | Hallazgo |
|---|---|---|---|
| minsal-onco-talca, -valdivia | Aplicable (comuna y tipo de obra) | minsal.cl, nota del 31-ago-2026 | Confirma las comunas del plan. La nota es posterior al corte del juego (11-mar-2026), no dice «diseño» y no da montos (la ficha tampoco). |
| minsal-onco-valparaiso-equipamiento | Aplicable | misma | «se modernizará equipamiento en Valparaíso y Punta Arenas». |
| minsal-onco-vina-del-mar | Aplicable | misma | Viña del Mar figura entre las comunas. |
| conc-concesion-hospital-de-maipu-y-la-florida | Parcial, **imprecisión de estado** | MOP Concesiones, díptico de marzo 2025 | Comunas y concesión confirmadas (inversión UF 6.568.000, puesta en servicio 13-02-2015), pero la concesión sigue **vigente**: «terminado» vale solo para la construcción. |
| metro-linea-7 | **DISCREPANCIA de monto** | MTT, 18-mar-2026 | La fuente dice «US $2.528» y la ficha 2.700 (millones USD). Comunas confirmadas. |
| metro-linea-8 | Parcial; **posible discrepancia** | Solo resúmenes (metro.cl da 403) | Metro cita US$1.899,5 millones (~1.900); la ficha dice 2.000. Peñalolén aparece en 6 comunas en una fuente y no en otra. |
| metro-linea-9 | Parcial | Solo resúmenes y prensa | Monto 2.733 consistente. El estado «diseño» parece desactualizado (obras iniciadas en La Pintana, agosto 2025, según titulares de gob.cl). |
| metro-linea-a-aeropuerto | Parcial | Prensa (Meganoticias, 26-jun-2026) | US$365 millones coincide; «en ingeniería», operativa 2032; sin comunas. |

**Datos que la fuente contradice (prioridad):** monto de la Línea 7 (2.700 frente a 2.528); posible monto de la Línea 8 (2.000 frente a ~1.900); estado «terminado» del hospital de Maipú/La Florida (la concesión sigue vigente). Ninguno se corrige hoy por el congelamiento; si el usuario descongela, la corrección de la Línea 7 es la única con fuente primaria leída. Las 4 fichas oncológicas son las únicas «aplicables» de este lote.
