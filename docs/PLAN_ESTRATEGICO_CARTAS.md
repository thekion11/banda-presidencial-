# Plan Estratégico (27-nov-2026): diseño de las cartas (antes de implementar)

**Origen y autorización.** Encargo de la coordinadora, que informa que el usuario pegó hoy su «Plan Estratégico de Desarrollo, Soberanía Financiera e Industrialización de Chile» (8 propuestas) y eligió «Cartas del juego». Esa conversación no está en esta sesión: la autorización del usuario consta **solo por la coordinadora** y está pendiente de que el usuario la confirme aquí (D20). Se trabaja bajo la autorización permanente de aceptar encargos de la coordinadora que respeten CLAUDE.md: solo **datos y cartas con el esquema actual**, sin mecánicas ni pantallas nuevas. Fuente en `data/fuentes.json`: «Plan del usuario, 27-nov-2026» (cifras ilustrativas, sin verificar). Todas las cartas llevan `cifras_ilustrativas` y el riesgo de que lo prometido no se cumpla.

**Esquema usado (sin campos nuevos).** `data/cartas_curadas.json`: `categoria`, `costo_pa`, `efectos`, `requisitos {ley, quorum}`, `riesgo {prob, efectos}`, `diferido {semanas, texto, efectos}`, `sabor`, `curada`. Las obras (`obra {nombre, dias_totales}`) existen en `cartas.json`; se verá si el cargador las acepta en curadas, si no van en `cartas.json`.

| Propuesta | Cartas (id) | Requisito legal | Efecto inmediato | Riesgo (azar) | Diferido (semanas) |
|---|---|---|---|---|---|
| 1 AFP estatal | `plan_afp_estatal` (reforma constitucional por la autonomía), `plan_afp_comision` (ley simple, comisión 0,1 %) | reforma 4/7; ley simple | capital −4, cohesión −2 / aprobación +3 | la comisión baja pero la rentabilidad no está garantizada: 40 % de pérdida de aprobación y fiscal | 26: aprobación +3 |
| 2 Fondo soberano | `plan_fondo_soberano` (ley simple), `plan_fondo_regla` (reforma 4/7: fiscalización vinculante del CFA) | ley simple; reforma | fiscal −3 (capitalización), capital −1 | 35 %: mala rentabilidad real, fiscal −3 | 52: fiscal +6 (solo si sale bien) |
| 3 Industrialización | `plan_refinacion_cobre`, `plan_litio_baterias`, `plan_hidrogeno_enap` | ley simple; contratos a 10–15 años | fiscal −4, riesgo ejecución +2 | 45 %: la planta se retrasa o el comprador no firma | 52–78: aprobación +2, fiscal +4 |
| 4 Empresa estatal de tecnología/IA | `plan_empresa_ia` | quórum calificado | fiscal −3, cohesión −1 | 40 %: despidos y rechazo de funcionarios (cohesión −3) | 26: fiscal +3, riesgo −2 |
| 5 Construcción industrializada | `plan_construccion_prefab` | quórum calificado | fiscal −4, viviendas +4.000 | 40 %: sobrecostos | 26: riesgo ejecución −2 |
| 6 Reforma COEVA | `plan_coeva` (reforma 4/7 por autonomía) | reforma 4/7 | capital −4, aprobación −1 | 45 %: litigios y críticas ambientales, aprobación −2 | 26: aprobación +2, riesgo −3 |
| 7 Soberanía hídrica | `plan_desaladoras`, `plan_carretera_hidrica`, `plan_exportar_agua` | ley simple | fiscal −5 | 50 % la exportación de agua dulce no se concreta (aprobación −2); | 52: aprobación +3 |
| 8 Transporte | `plan_red_ferroviaria`, `plan_megapuertos`, `plan_metro_regiones` | ley simple | fiscal −4 | 40 %: retrasos de obra | 52: aprobación +3 |

**Implementado (commit de esta fecha): 16 cartas `plan_*`** generadas con `tools/generar_plan.py` (sin obras con fases: el beneficio se modela con `diferido`). Total previsto original: unas 18 cartas, categorías existentes (hacienda, economia, estado, energia, medioambiente, transportes, politica); ninguna categoría ni color nuevo.

**Supuestos y límites.** (1) Las afirmaciones optimistas del plan («sin alzas de impuestos», seguro contra pérdidas, 0,1 % de comisión, exportación de agua) se modelan como incertidumbre: el beneficio fuerte solo llega en `diferido` y con `riesgo` explícito; ninguna carta da efectos grandes a la vez. (2) Cifras ilustrativas rotuladas. (3) Qué exige reforma constitucional se toma de la regla ya verificada (4/7, `VERIFICACION_CONSTITUCIONAL.md`); esas cartas son difíciles a propósito. (4) Los efectos respetan los techos de balance existentes (cada carta suma |efecto| similar a sus vecinas del mismo costo).

**Costo para el resto.** Agregar cartas cambia `data/` y, por tanto, la huella y los oros (D17: congelar `data/` en la prueba cerrada; esta ampliación debe entrar antes del congelamiento). Se regeneran los oros documentando el motivo, se avisa a Visual (categorías ya existentes: sin arte nuevo salvo que quiera ilustraciones) y a Búsqueda (fuzz de las cartas nuevas).
