# Resumen para ti — noche del 27-nov-2026
Escrito por la sesión «Leyes + ahorro». **Cada afirmación sobre lo que está hecho se verificó contra `origin/main` (hash entre paréntesis).** Lo que vive solo en otras ramas se marca «NO está en main» y no lo doy por hecho.

## 1. Qué pediste y qué quedó
| Tu pedido | Estado en `main` |
|---|---|
| Plan Estratégico convertido en cartas | Hecho: 16 cartas `plan_*` (27ced2a); anotado en `CLAUDE.md` (d30c4ad) |
| Test rápido de 3 preguntas, congelar `data/`, renderizador `gl_compatibility` | Hecho y anotado (d30c4ad; `project.godot` usa `gl_compatibility`) |
| Mapa del país más grande con zoom | Hecho (b9a09ec) y riel con las 16 regiones de norte a sur (1644057) |
| Gabinete menos «formulario» | Hecho: tablero de 25 puestos con tu opción A (fab29d1), fichas de contratación (ebd8503, 5826deb), el gabinete se elige tras ganar la elección (ba4f537); alias satíricos y retrato con canas (04e0798) |
| «Los movimientos deben poder guardarse… solo marcar los disponibles» | Hecho: ahorro con tope 10 (ed36340); la cabecera muestra solo los disponibles (51fa451); cerrar semana ya no pide confirmar (0c3a55e) |
| «Falta poder solicitar que se presenten leyes desde mi gobierno» | Hecho: agenda legislativa con urgencia simple (30 días), suma (15) e inmediata (6), etapas, delegación y máximo de 3 proyectos (8a80b1c); pantalla en «Congreso» (0c3a55e, cf618fd) |
| Elección con población por región | Motor (f220b36) y pantalla (c0e39bd) hechos |

Calidad: la última suite completa que corrí pasó en verde en 6e4d86d; después solo cambiaron pruebas y scripts (39e5c98) y la interfaz de otras sesiones, que no volví a correr entera.

## 2. Qué necesito que decidas (mi recomendación en una línea)
1. **D1/D26 · duración.** Un teléfono real da ≈ 2,2 min por semana: un mandato son ≈ 7,6 h (≈ 22 sesiones de 20 min), no 20 minutos. *Recomiendo* avisos automáticos y saltar semanas vacías ahora (solo interfaz), más un cierre de legislatura a las 104 semanas; decidir el turno de 2 semanas con más partidas de testers (`PROPUESTA_D1_D26.md`). Ojo: la cifra viene de una sola partida y su informe (`PRUEBA_CERRADA_INFORMES.md`) **no está en main**.
2. **D21 · reformas 4/7 del plan** pasan en 88–100 % de los casos (muy fáciles). *Recomiendo* dejarlo y decidir con datos de personas.
3. **D27 · quórum de `plan_refinacion_cobre`, `plan_litio_baterias` y `plan_hidrogeno_enap`:** creo (de memoria, **sin verificar contra BCN**) que la Constitución pide quórum calificado y hoy son ley simple. *Recomiendo* pasarlas a quórum calificado junto con D21, tras verificar el artículo.
4. **D17 · `data/` congelado.** Ya descongelé solo 2 filas con tu autorización (tope de ahorro y agenda); cualquier otro cambio borra los guardados de los testers. *Recomiendo* mantener el congelamiento.
5. **D23/D24 · ruido regional y Congreso por geografía.** *Recomiendo* esperar a la prueba cerrada. (El valor «ruido regional = 6» y el «piso del 5 % o 20–30 %» que me mencionaron **NO están en main**: viven en las ramas `piso-luna` y del núcleo; no los puedo verificar desde aquí.)
6. **Orden de fusión de los PR #11 → #12 → #10.** **NO está en main** y no veo los PR desde aquí; *recomiendo* seguir la propuesta de orden y de `VERSION` del guardado que dejó la rama `balas` (08d5c21) y volver a pasar la suite completa tras cada fusión.
7. **D22 · textos y retratos del gabinete** y **D25 · proyectos SECTRA de la RM y Aysén** (ambos tocan `data/`). *Recomiendo* textos sí y retratos solo si se resuelven las licencias; SECTRA solo con fuente oficial.

## 3. Riesgos que conozco
- **Ritmo:** probablemente demasiado lento para «sesiones de 20 minutos» (ver 1). `CLAUDE.md` §2 y varias páginas aún dicen 20 minutos y «5 movimientos»: lista en `AUDITORIA_NUMEROS_27NOV.md`; no toqué `CLAUDE.md` sin tu autorización.
- **Balance solo medido con bots.** Un jugador activo cae en crisis ≈ 20 % de las veces (con o sin ahorro; 150 partidas por celda). Nada se midió con muchos jugadores reales.
- **Guardados:** los cambios de datos y reglas de hoy descartan las partidas guardadas anteriores (huella de datos). Sin testers aún, no hay pérdida real.
- **Lo constitucional no está verificado:** `bcn.cl` bloquea el acceso; Art. 25/66 y 229 proyectos reales siguen sin verificar (`VERIFICACION_CONSTITUCIONAL.md`).
- **Rendimiento en teléfono no medido** (30 fps y 800 MB son de un PC).
- **Cupo de la agenda:** lo corregí hoy (6e4d86d); antes lo llenaban las leyes de la mano y la función quedaba inutilizable. Si ves «Agenda llena» con la agenda vacía, avisa.
- **Pruebas de la otra sesión de búsqueda** (`fuzz_ahorro`, `fuzz_agenda`, `test_agenda_limites`) siguen en su rama, no en main.
