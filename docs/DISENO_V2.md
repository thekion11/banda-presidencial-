# Diseño v2 — Gabinete, mano continua, movimientos y proyectos (especificación del usuario, 23-nov-2026)

Alcance autorizado por el usuario (ampliación sobre la Enmienda de Cierre). Todo número de balance vive en `data/leyes.json`; `sim/` sigue determinista (misma semilla + mismas entradas = mismo resultado) y cada archivo ≤ 450 líneas (`sim/estado_simulacion.gd` y `sim/motor_turno.gd` < 220).

## Reglas pedidas
1. **Disponibilidad por gabinete.** Una carta solo está disponible si el jugador tiene en su gabinete un ministro cuya `categoria_afin` coincide con la `categoria` de la carta (las categorías `politica` y `comite` siempre están disponibles). El jugador escoge el gabinete (nuevo estado `gabinete`, tamaño en leyes.json).
2. **Ventanas y desbloqueos.** Cada carta puede traer `disponibilidad`: `anio_desde`/`anio_hasta` (año de gobierno 1–4; algunas solo existen un año, otras otro), `evento` (id de evento que la activa), `fiscal_min` (se activa al superar cierta cantidad de dinero/indicador fiscal) y `meta` (id de meta/objetivo interno que la desbloquea).
3. **Mano continua.** Por cada carta jugada entra otra nueva al instante: la mano nunca se queda sin cartas. La partida comienza con **5 cartas** y **5 movimientos** (antes PA).
4. **Costo.** Cada carta cuesta **1 a 3 movimientos**.
5. **Delegación.** Hasta **2 cartas por turno** se pueden delegar en un ministro y se usan **sin gastar movimientos**, pero **pueden salir mal** (probabilidad según competencia del ministro y riesgo de ejecución; efecto reducido o escándalo).
6. **Movimientos internos.** **3 por turno**, solo dentro de la coalición: buscar objetivos o metas (desbloquean cartas); subir o bajar índices dentro de un sector; disminuir errores de ejecución (riesgo); acelerar proyectos (obras).
7. **Estado empresario.** Opciones de crear empresas públicas, privatizar y expropiar (cartas de categoría `estado`, con sus costos fiscales, de cohesión, de capital político y de riesgo).
8. **1.040 proyectos.** Una carta por cada proyecto: los ~1.044 proyectos de ley en tramitación (`data/bcn/proyectos_ley.json`) más los proyectos públicos (`data/proyectos/`). Cada carta lleva `categoria` (ministerio) y `disponibilidad`.

## Esquema nuevo de carta (campos opcionales; las cartas actuales siguen siendo válidas)
```json
"disponibilidad": {"anio_desde": 1, "anio_hasta": 4, "evento": null, "fiscal_min": null, "meta": null}
```
Metas internas: `data/metas.json` (id, nombre, sector, descripcion, costo_mov, desbloquea[], efectos[]), cada una citando fuente.

## Ampliación 2 (usuario, 23-nov-2026): asesores, bono por aprobación, coalición y reposición de cartas
9. **Asesores:** se pueden contratar hasta **3 asesores distintos**. Cada uno da **+1 movimiento** por turno y además un efecto **positivo** y uno **negativo** extra (p. ej. +bono en un sector / −riesgo o −aprobación en otro). Catálogo en `data/asesores.json` (id, nombre ficticio, perfil, efecto_positivo, efecto_negativo, ideología afín), parámetros en leyes.json; entrada de guardado "asesor".
10. **Ideología y coalición:** la ideología importa. Cada partido de tu coalición puede tener ideología distinta (ejes de `data/ideologia.json`); si gobiernas en coalición, los partidos aliados **piden poder** (cuotas de ministerios/asesores/cartas); satisfacerlos o no afecta cohesión, votos en el Congreso y movimientos internos. Partidos ficticios (no organizaciones reales).
11. **Bono de movimientos por aprobación:** base 5. Desde **60 % de aprobación, por cada 5 % adicional (60, 65, 70, 75, 80) se agrega hasta +1 movimiento**; **después de 80 %, por cada 5 % hasta 100 % (85, 90, 95, 100) se agregan +2 movimientos**. Umbrales y valores en leyes.json.
12. **Reposición con animación:** si usaste todas tus cartas y te quedan movimientos, se agregan más cartas a la mano/mazo (la mano nunca queda vacía con movimientos disponibles). El sim emite un registro `reposicion` (ids de cartas nuevas) para que la interfaz lo anime.
