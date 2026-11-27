# API de `sim/` (generado)

Índice de las funciones públicas de `sim/` con su documentación. Generado con `python3 tools/generar_api.py`; no editar a mano. Visión de conjunto y dependencias: `docs/ARQUITECTURA_SIM.md`.

## `Datos` (`sim/datos.gd`)

- `static leer_json(ruta: String) -> Variant` — Lee un archivo JSON y devuelve su contenido (Variant); null si no existe o no se puede leer.
- `static cargar_todo(base: String = "res://data/") -> Dictionary` — Carga todos los catálogos de data/ (cartas, eventos, leyes, ministros, regiones…) y arma los índices compartidos de solo lectura.
- `static huella(d: Dictionary) -> String` — SHA-256 de los datos que afectan al resultado de la simulación. Un guardado solo es reproducible con la misma huella.
- `static clave_archivos(base: String = "res://data/") -> String` — SHA-256 nativo (milisegundos) de los archivos de los que sale `cargar_todo`: identifica una versión exacta de los datos.
- `static huella_rapida(d: Dictionary, cache: String = "user://huella_datos.json", base: String = "res://data/") -> String` — Igual que `huella(d)` para datos recién cargados, pero la primera vez la guarda junto a la clave de los archivos: los arranques

## `DirectorEventos` (`sim/director_eventos.gd`)

- `exportar_memoria() -> Dictionary` — Historial incremental tal como está (para la instantánea): reconstruirlo desde `eventos_ocurridos` no da lo mismo cuando las semanas de la campaña y del gobierno se mezclan.
- `importar_memoria(d: Dictionary) -> void` — Restaura el historial exportado con `exportar_memoria`.
- `reconstruir() -> void` — Tras restaurar una instantánea: rehace el historial incremental del director a partir de lo ocurrido (es lo mismo que fue acumulando aplicar_evento).
- `mes_actual() -> int` — Mes del calendario (1 a 12) de la semana en curso: desde el ciclo 2 hay un solo reloj; en el ciclo 1 la campaña y el gobierno tienen su fecha base.
- `elegir_evento(grupo: Dictionary) -> Dictionary` — Elige el evento aleatorio de la semana (o {} si no ocurre ninguno) respetando descansos, estaciones y el ritmo de decisiones del año.
- `registrar(evt: Dictionary, ahora: int) -> void` — Llamado por aplicar_evento: deja constancia de que el evento ocurrió esta semana.

## `Encuestas` (`sim/encuestas.gd`)

- `static registrar(m: MotorTurno) -> void` — Anota la encuesta de la semana (intención de voto, margen, umbral, rival, regiones débiles) sin usar el azar de la partida.

## `EstadoSimulacion` (`sim/estado_simulacion.gd`)

- `configurar(p_semilla: int, p_dias_turno: int = 7, p_leyes: Dictionary = {}) -> void` — Deja el estado en blanco para una partida nueva con su semilla, días por turno y leyes.
- `static normalizar(v: Variant) -> Variant` — Redondea a 6 decimales los números del partido: el guardado en JSON los reproduce exactamente (replay idéntico).
- `registrar_accion(tipo: String, detalle: Dictionary) -> void` — Agrega al registro de acciones (para la interfaz y los resúmenes) una acción ya ocurrida; no entra al guardado.
- `registrar_entrada(tipo: String, datos: Dictionary) -> void` — Agrega al historial del guardado una decisión del jugador (tipo + datos); es lo único que se reproduce al cargar.
- `ind(nombre: String) -> float` — Valor actual de un indicador (aprobación, capital, cohesión, fiscal…); 0 si no existe.
- `promesas_pendientes() -> Array[Dictionary]` — Promesas de campaña que aún no se cumplen (la meta de legado del gobierno).
- `eleccion_pendiente(semanas_campana: int) -> bool` — true si terminó la campaña (o la segunda vuelta) y toca votar la elección presidencial.
- `exportar_resumen() -> Dictionary` — Resumen legible del estado para la interfaz y los informes (ver ResumenEstado).
- `calcular_huella() -> String` — Huella SHA del estado completo: dos partidas iguales dan la misma huella (pruebas de oro y replay).
- `exportar_guardado(huella_datos: String = "") -> Dictionary` — Guardado por eventos: semilla, partido, historial de entradas y huella de los datos con que se jugó.
- `exportar_json(huella_datos: String = "") -> String` — Igual que JSON.stringify(exportar_guardado()), pero cada entrada se serializa una sola vez (el juego guarda en cada acción: reescribir ~2.000 entradas costaba ~6 ms).

## `GeneradorPartido` (`sim/generador_partido.gd`)

- `static calcular_ejes(respuestas: Array) -> Vector2` — Ejes ideológicos (económico, institucional) a partir de las respuestas del test.
- `static perfil_para(eco: float, inst: float, catalogo: Dictionary) -> String` — Perfil 2D mostrado en vivo en la franja crema. Primer perfil que calza; si ninguno, arquetipo por eje económico.
- `static arquetipo_para(eco: float, catalogo: Dictionary) -> String` — Arquetipo de partido (texto del catálogo de ideología) para un eje económico dado.
- `static escanos_para(eco: float, inst: float) -> int` — Escaños propios según la distancia al centro; los números viven en data/ideologia.json › escanos.
- `static construir_partido_afiliado(afiliacion: String, base: Dictionary, nombre: String, sigla: String, region_bastion: String, respuestas: Array[Dictionary], catalogo_ideologia: Dictionary, cfg: Dictionary) -> Dictionary` — Partido según la afiliación (PR-01): propio, independiente o existente (base = partido de data/coalicion.json). Todo número viene de cfg (leyes.json "afiliacion").
- `static aplicar_habilidad(partido: Dictionary, habilidad: String, color: String, cfg: Dictionary) -> void` — PR-16/PR-15: la habilidad suma a los indicadores iniciales (datos en leyes.json «habilidades»); el color es solo apariencia (debe estar en la paleta).
- `static construir_partido( nombre: String, sigla: String, region_bastion: String, respuestas: Array[Dictionary], catalogo_ideologia: Dictionary ) -> Dictionary` — Arma el diccionario del partido del jugador (ejes, perfil, escaños, indicadores iniciales) desde su nombre, región y respuestas.

## `GrafoTrazado` (`sim/grafo_trazado.gd`)

- `cargar(d: Dictionary) -> void` — Carga el grafo urbano (nodos y aristas) y prepara posiciones y adyacencias.
- `listo() -> bool` — true si el grafo tiene nodos cargados.
- `nodo_cercano(p: Vector2) -> String` — Id del nodo del grafo más cercano a un punto del mapa.
- `ruta(origen: String, destino: String) -> Array[String]` — Camino de menor peso (longitud × costo + expropiaciones). Dijkstra con montículo binario; desempate determinista por orden de inserción.
- `evaluar(estaciones: Array) -> Dictionary` — Métricas del trazado que une las estaciones en orden: longitud, índice de costo, expropiaciones, ríos y nodos recorridos.
- `estaciones_base(variante: Dictionary) -> Array` — Estaciones de una variante del Comité: las propias o las derivadas de su trazado.
- `estaciones_de(trazado: Array) -> Array[String]` — Ajusta (snap) los vértices de un trazado precalculado a los nodos más cercanos, sin repetir consecutivos.
- `estaciones_validas(estaciones: Array) -> bool` — true si las estaciones existen en el grafo, son consecutivas distintas y su número está en el rango permitido.
- `variante_modificada(base: Dictionary, estaciones: Array, ritmo: float, cobertura: float) -> Dictionary` — Variante propia: métricas de la base escaladas por la razón entre el trazado nuevo y el de la base (mismo modo constructivo).
- `advertencias(v: Dictionary, prop: Dictionary) -> Array[String]` — Corrector de Realismo del trazado: nunca un "no" seco; propone por tramos o ceder plazo.

## `Huella` (`sim/huella.gd`)

- `static texto(v: Variant) -> String` — Representación textual estable (claves ordenadas) de cualquier valor, para hashear sin depender del orden de los diccionarios.
- `static sha(v: Variant) -> String` — SHA-256 del texto estable de un valor.
- `static fnv32(texto: String) -> int` — FNV-1a de 32 bits sobre UTF-8: valor fijo en todas las versiones de Godot (hash() no lo garantiza).

## `IndicesCartas` (`sim/indices_cartas.gd`)

- `static clave(v: Variant) -> String` — Normaliza un valor de disponibilidad (los enteros float como 3.0 se vuelven «3») para usarlo como clave de índice.
- `static tipo_real(c: Dictionary) -> bool` — true si la carta corresponde a un proyecto, ley o reforma real (por el tipo en su meta).
- `static construir(cartas: Array) -> IndicesCartas` — Construye los índices de solo lectura del catálogo de cartas (por id, reales, diseñadas y por condición de disponibilidad).

## `Instantanea` (`sim/instantanea.gd`)

- `static esquema() -> Dictionary` — Nombre y tipo de cada variable de EstadoSimulacion tal como la arma el juego ahora: una instantánea de una versión con otros campos no se usa.
- `static tomar(motor: MotorTurno, huella_datos: String, sha_guardado: String) -> PackedByteArray` — Estado completo del motor serializado y comprimido (~50 KB). Solo lee; no cambia la partida.
- `static leer(bytes: PackedByteArray) -> Dictionary` — Instantánea decodificada, o {} si está vacía o dañada.
- `static es_completa(d: Dictionary) -> bool` — Estructura mínima para restaurar (una instantánea con huella y SHA válidos pero sin sus partes se ignora en vez de fallar).
- `static vale_para(d: Dictionary, huella_datos: String, sha_guardado: String) -> bool` — true si la instantánea es completa y coincide con la huella de datos y el SHA del guardado actuales.
- `static restaurar(datos: Dictionary, semilla: int, d: Dictionary) -> MotorTurno` — Mismo motor que daría reproducir el historial, sin simularlo.

## `MotorAgenda` (`sim/motor_agenda.gd`)

- `urgencia(id: String) -> Dictionary` — Definición de una urgencia (simple, suma, inmediata); {} si no existe.
- `estado_agenda() -> Dictionary` — Salida para la UI: {en_tramite, maximo, puede_presentar, razon}.
- `prob_estimada(tipo_id: String, urg: Dictionary, desde: String = "primer_tramite") -> float` — Probabilidad estimada de aprobación (0 a 1) desde una etapa, con el apoyo de hoy (sin usar el azar). Salida de solo lectura para la UI.
- `abrir(carta: Dictionary, escala: float, region_id: String, urgencia_id: String, delegada: bool) -> Dictionary` — Ingresa el proyecto a la agenda (lo llama MotorCartas al ejecutar una presentación) y lo deja en su primera etapa.
- `agenda_catalogo(categoria: String = "") -> Array[Dictionary]` — Catálogo de proyectos que el gobierno puede presentar ahora (gabinete, ventana, etapa y quórum), aunque no estén en la mano.
- `en_tramite() -> Array[Dictionary]` — Proyectos de la agenda en trámite: {carta_id, titulo, tipo_ley, urgencia, etapa, etapa_nombre, camara, semanas_restantes, prob_aprobacion, delegada}. Solo lectura.
- `presentar(carta_id: String, urgencia_id: String = "simple", ministro_id: String = "", delegar: bool = false, region_id: String = "") -> Dictionary` — Mensaje del Ejecutivo: presenta una ley del catálogo (aunque no esté en la mano) con una urgencia. Cuesta los movimientos de la carta
- `poner_en_discusion_inmediata(carta_id: String) -> Dictionary` — Sube un proyecto en trámite a discusión inmediata sin cobrar capital ni movimientos (lo cobra quien lo llama, p. ej. una bala): acorta el plazo de la etapa
- `avanzar() -> Array[Dictionary]` — Cierre de semana: resuelve las etapas cuyo plazo venció (puede ser más de una por semana con urgencia alta) y devuelve los resultados finales.

## `MotorBalas` (`sim/motor_balas.gd`)

- `definicion(id: String) -> Dictionary` — Definición de una bala del catálogo; {} si no existe.
- `usos_habilitados() -> int` — Balas que se pueden haber usado hasta ahora: las iniciales, y todo el cupo desde el año `anio_uso_extra`.
- `usos_restantes() -> int` — Balas que aún puedes usar ahora (habilitadas menos usadas).
- `semanas_de_espera() -> int` — Semanas que faltan para poder usar otra bala (0 si no hay enfriamiento).
- `objetivos(def: Dictionary) -> Array[Dictionary]` — Proyectos de ley en trámite sobre los que la bala puede actuar ({idx, carta_id, titulo, tipo_ley, dias, fuente}); vacío si la bala no necesita objetivo.
- `riesgo_estimado(def: Dictionary) -> float` — Probabilidad (0 a 1) de que la bala salga mal ahora: base + peso x (centro - indicador), acotada.
- `baul() -> Dictionary` — Solo lectura para la interfaz: reserva, usos, enfriamiento y, por bala, costo, riesgo, condición cumplida o no y por qué.
- `usar(id: String, objetivo: int = -1, reducida: bool = false) -> Dictionary` — Usa una bala de la reserva. objetivo: índice en estado.proyectos_ley (-1 = el proyecto más lejano de votarse). reducida: acepta la versión con menos

## `MotorCartas` (`sim/motor_cartas.gd`)

- `costo_carta(carta: Dictionary, ministro_id: String = "") -> int` — Costo en movimientos de una carta, con el descuento del ministro y los bonos del gabinete y los asesores.
- `descartar_mano() -> void` — Cierre de turno: las cartas más antiguas sin jugar van al descarte para que la mano no se atasque con cartas imposibles de jugar.
- `es_real(carta: Dictionary) -> bool` — true si la carta es de un proyecto real (usa el índice; cae a su tipo si no está en el catálogo).
- `no_reales() -> Array[Dictionary]` — Cartas diseñadas (no basadas en un proyecto real), del índice compartido.
- `reales_para_mazo() -> Array[String]` — Una carta por proyecto público real: en cada mazo circula un subconjunto sorteado con la semilla (leyes.json › mano.reales_en_mazo).
- `es_unica(carta: Dictionary) -> bool` — true si la carta solo puede ejecutarse una vez en el gobierno.
- `vista_carta(idx: int, ministro_id: String = "") -> Dictionary` — Datos de una carta de la mano para la interfaz: costo, corrector de realismo y si alcanzan los movimientos.
- `jugar_carta(idx: int, ministro_id: String = "", region_id: String = "", delegada: bool = false) -> Dictionary` — `delegada`: la carta la ejecuta un ministro del gabinete sin gastar movimientos, pero puede salir mal (DISENO_V2 §5).
- `aprobar_propuesta(prop_id: String, variante_id: String, region_id: String = "", custom: Dictionary = {}, nombres: Dictionary = {}) -> Dictionary` — Aprueba una propuesta del Comité con una variante (A/B/C) o una personalizada y arranca su obra; registra la entrada.
- `static limpiar_nombre(texto: String, maximo: int) -> String` — Nombre elegido por el jugador: sin saltos ni caracteres de control, espacios colapsados y con largo máximo.
- `resolver_proyectos() -> Array[Dictionary]` — Vota los proyectos de ley cuyo plazo venció esta semana (Senado, Cámara y Tribunal Constitucional) y aplica sus efectos.

## `MotorCoalicion` (`sim/motor_coalicion.gd`)

- `cargar(lista: Array) -> void` — Carga el catálogo de los partidos de la coalición.
- `afinidad(id: String) -> float` — 1 = misma ideología que el partido del jugador; 0 = distancia >= distancia_max (ejes eco/inst).
- `adoptar_partido_propio(id: String) -> void` — PR-01: quien entra a un partido existente lo lleva como aliado permanente que pide poder (sus ministerios) y castiga si se le ignora.
- `unirse(id: String) -> Dictionary` — Invita a un partido a la coalición del gobierno; devuelve {ok, razon}.
- `salir(id: String, ruptura: bool = false) -> Dictionary` — Saca a un partido de la coalición (con ruptura si se va enojado); devuelve {ok, razon}.
- `asignar_cuota(id: String, tipo: String, valor: String, quitar: bool = false) -> Dictionary` — tipo "ministerio" (id de ministro del gabinete) o "asesor" (id de asesor contratado), entregado al partido aliado.
- `cumplimiento(id: String) -> float` — Fracción 0..1 de la petición del partido (ministerios y asesores asignados que siguen vigentes).
- `objetivo(id: String) -> float` — Satisfacción hacia la que tiende un aliado según se cumplan sus peticiones y su afinidad ideológica.
- `carta_jugada(carta: Dictionary) -> void` — Jugar cartas de las categorías que pide un aliado mejora su satisfacción.
- `mult_carta(carta: Dictionary) -> float` — Multiplicador del efecto de una carta de gobierno: un aliado satisfecho potencia las cartas de las categorías que pide;
- `amanecer() -> void` — Cada turno de gobierno: la satisfacción converge a su objetivo y se aplican cohesión, votos y movimientos internos.

## `MotorEfectos` (`sim/motor_efectos.gd`)

- `configurar(p_estado: EstadoSimulacion, p_leyes: Dictionary, p_regiones: Regiones) -> void` — Enlaza el estado, las leyes y las regiones y fija los límites y parámetros de los efectos.
- `aplicar_efecto(ef: Dictionary, escala: float, region: String) -> void` — Aplica un efecto de carta o evento ({ind, delta}) escalado a un indicador o a la aprobación regional.
- `delta_aprobacion(delta: float, region: String, decreciente: bool = false) -> void` — Cambia la aprobación (nacional o de una región) con rendimientos decrecientes al subir cuando es alta.
- `sumar_ind(nombre: String, delta: float, causa: String = "") -> void` — Suma al indicador respetando sus mínimos y máximos; con `causa` (frase corta para el jugador) anota el cambio real en los motivos de la semana.
- `reiniciar_motivos() -> void` — Vacía los motivos de la semana (se llama al cerrar el turno; el amanecer siguiente sigue sumando).
- `motivos_semana() -> Array[Dictionary]` — Hasta 3 cambios de la semana con causa conocida, de mayor a menor |delta|: {ind, delta, causa}. Solo salida: no entra al guardado ni a la huella.
- `marcar_cumplida(carta_id: String) -> void` — Marca como cumplida la primera promesa de campaña pendiente de esa carta.

## `MotorEquipo` (`sim/motor_equipo.gd`)

- `cargar(lista: Array) -> void` — Carga el catálogo de asesores.
- `contratar(id: String) -> Dictionary` — Contrata un asesor (hay un máximo de asesores); devuelve {ok, razon}.
- `despedir(id: String) -> Dictionary` — Despide a un asesor; devuelve {ok, razon}.
- `afinidad(id: String) -> float` — 1 = misma ideología que el partido; 0 = distancia mayor o igual a `distancia_max` (ejes eco/inst de data/ideologia.json).
- `movimientos_extra() -> int` — Movimientos adicionales por turno que dan los asesores contratados.
- `mult_categoria(categoria: String) -> float` — Multiplicador de efecto para una categoría de cartas según los asesores (bueno o malo).
- `efectos_amanecer() -> void` — Efectos de indicador de los asesores, una vez por turno de gobierno.

## `MotorEventos` (`sim/motor_eventos.gd`)

- `semana_abs() -> int` — Semana absoluta de la carrera (los periodos reinician el turno, no esta cuenta).
- `procesar_semana() -> Array[Dictionary]` — Paso 2 del turno: cumple lo pendiente, aplica los eventos programados de la semana y sortea el aleatorio con el director.
- `relacion_actor(id: String) -> float` — Relación (0-100) con un actor político según tus decisiones anteriores (memoizada).
- `reconstruir() -> void` — Reconstruye la memoria del director de eventos a partir de lo ocurrido (tras restaurar un estado).
- `aplicar_evento(evt: Dictionary) -> Dictionary` — Aplica un evento (efectos, votación y TC si los tiene), lo registra y desbloquea cartas ligadas; devuelve lo que muestra la interfaz.
- `relacion_exterior(iso: String, base: float) -> float` — Relación con un país vecino: valor base (data/vecinos.json) + efecto de los eventos «vecino» ya ocurridos en la partida (sin estado nuevo).
- `decidir(evento_id: String, idx: int) -> Dictionary` — Responde a un evento con opciones (no gasta movimientos): aplica los efectos de la opción y queda registrado para el replay.
- `prob_bloqueo() -> float` — Probabilidad de que tu postura prospere en el Congreso (oposición): bancada propia y aliados del Senado más la cohesión del partido.
- `relaciones_actores() -> Array[Dictionary]` — Marco de actores (PR-24): [{id, nombre, relacion}] solo de los actores con quienes ya decidiste algo; derivado de estado.decisiones.

## `MotorGabinete` (`sim/motor_gabinete.gd`)

- `por_defecto() -> Array[String]` — Gabinete inicial determinista: el relleno automático equilibrado sobre un gabinete vacío (con tamaño 25, todos los ministerios).
- `slot_de(id: String) -> String` — Ministerio (cargo) que ocupa un candidato: cada ministerio tiene 3 candidatos con perfil propio (Fase C).
- `tiene_ministerio(slot: String) -> bool` — true si el gabinete tiene un ministro en ese cargo (ministerio).
- `de_ministerio(slot: String) -> String` — Id del ministro que ocupa un cargo ('' si está vacío).
- `afinidad(id: String) -> float` — 1 = el ministro piensa como tu partido; 0 = distancia ideológica máxima (ejes eco/inst).
- `titular(categoria: String) -> String` — Ministro del gabinete que lleva las cartas de una categoría: el de mejor rendimiento (ahorro de costo y bono de ejecución) entre los de esa área.
- `rellenar(elegidos: Array, modo: String = "") -> Array[Dictionary]` — PR-05: completa el gabinete sin tocar lo ya escogido, un candidato por ministerio. Determinista (puntaje, desempate por id).
- `elegir(ids: Array) -> Dictionary` — Nombra el gabinete. Se puede cambiar en campaña o en la primera semana de gobierno (antes de gobernar).
- `categorias_activas() -> Dictionary` — Categorías de cartas habilitadas por el gabinete actual (con caché por firma del gabinete).
- `categoria_activa(cat: String) -> bool` — true si la categoría de cartas está habilitada por el gabinete.
- `anio_gobierno() -> int` — Año de mandato 1..N (en campaña cuenta como año 1).
- `bloqueo(carta: Dictionary) -> Dictionary` — Única regla de disponibilidad: {} si la carta circula; si no, {"codigo": gabinete|anio_desde|anio_hasta|evento|fiscal|meta, "valor": ...}.
- `abrir_contexto() -> void` — Los recorridos de ~2.000 cartas (rearmar el mazo) consultan lo mismo una y otra vez: categorías activas, año y fiscal se calculan una vez.
- `cerrar_contexto() -> void` — Libera el contexto de consulta abierto con abrir_contexto().
- `categoria_circula(cat: String) -> bool` — ¿Circulan las cartas de esta categoría (sin condiciones propias)? Igual que las primeras reglas de `bloqueo`.
- `disponible(carta: Dictionary) -> bool` — Misma regla que `bloqueo` (que además explica el motivo), sin crear diccionarios. Dentro de abrir/cerrar_contexto usa valores ya calculados.
- `amanecer() -> void` — Efectos semanales del gabinete: el estilo de cada ministro y la afinidad ideológica media con tu partido (leyes.json › gabinete.identidad).
- `pendiente_confirmar() -> bool` — Solo salida: true en la transición, o sea recién ganada la elección (turno 1 de gobierno) y sin nombrar gabinete desde la votación. La pantalla del gabinete
- `efecto_semanal_de(ids: Array) -> Dictionary` — Solo salida (no cambia el estado): efecto semanal que daría este gabinete por estilos y afinidad, {indicador: delta}; lo mismo que aplica `amanecer`.
- `ficha_candidato(id: String) -> Dictionary` — Solo salida: lo que el motor sabe de un candidato para mostrarlo (alias, cartera, estilo, afinidad 0 a 1 con tu partido, ahorro y bono, riesgo de escándalo).
- `efecto_de_nombrar(id: String) -> Dictionary` — Solo salida: cómo cambiaría el efecto semanal del gabinete si nombraras a `id` (reemplaza al que ocupe su ministerio, o se suma si está vacío): {indicador: diferencia por semana}.
- `revisar_renuncia(actor_id: String, forzar: bool = false) -> Dictionary` — Si tu relación con el ministro de ese ministerio cae bajo el umbral (o `forzar`, p. ej. un incidente de presupuesto), renuncia y asume el mejor candidato restante (la relación parte de cero).
- `validar_delegacion(ministro_id: String) -> Dictionary` — Comprueba que se puede delegar en ese ministro (en gobierno, en el gabinete y bajo el tope por turno); devuelve {ok, razon}.
- `prob_fallo(carta: Dictionary, ministro_id: String) -> float` — Probabilidad de que el ministro falle al ejecutar la carta delegada.
- `resolver_delegacion(carta: Dictionary, ministro_id: String) -> Dictionary` — Sortea con la semilla si el ministro lo hace bien. Si falla: efecto reducido y posible escándalo.

## `MotorLegal` (`sim/motor_legal.gd`)

- `configurar(p_leyes: Dictionary, p_rng: RandomNumberGenerator) -> void` — Enlaza las leyes y el generador de azar de la partida.
- `umbral(t: Dictionary, total: int) -> int` — Votos mínimos en una cámara de `total` miembros: base "en_ejercicio" (todos) o "presentes" (asistencia supuesta);
- `tipo(id: String) -> Dictionary` — Definición de un tipo de ley (quórum, trámite, TC); {} si no existe.
- `prob_aprobacion(estado: EstadoSimulacion, tipo_id: String, recargo: float = 0.0) -> Dictionary` — Probabilidad (0 a 1) de que cada cámara alcance el quórum del tipo de ley con el apoyo de hoy, sin usar el azar: {senado, camara}. Solo lectura.
- `votar(estado: EstadoSimulacion, tipo_id: String, votos_firmes_senado: int = -1, recargo: float = 0.0) -> Dictionary` — Simula la votación de un tipo de ley en el Senado y la Cámara; devuelve votos, quórums y si fue aprobada (usa el azar).
- `composicion(estado: EstadoSimulacion, camara: bool) -> Dictionary` — Bloques esperados de una cámara: bancada propia, aliados que suelen apoyar y oposición.
- `resolver_tc(tipo_id: String, prob_exito_override: float = -1.0) -> Dictionary` — recurso: la oposición acude al TC. cae: el TC declara inconstitucional (el gobierno pierde).
- `static fmt_cifra(n: float, unidad: String) -> String` — Formatea una cifra para los mensajes del corrector («12 mil km»).
- `corregir(carta: Dictionary, estado: EstadoSimulacion) -> Dictionary` — Nunca responde con un "no" seco: ofrece una versión viable o por tramos.

## `MotorMandato` (`sim/motor_mandato.gd`)

- `evaluar_legado() -> void` — En los turnos de evaluación del legado, penaliza capital y aprobación por cada promesa de campaña pendiente.
- `evaluar_crisis() -> void` — Cuenta las semanas con aprobación bajo el umbral y termina el gobierno por crisis al completar la racha.
- `calcular_puntaje() -> int` — Puntaje del mandato: aprobación, legado, obras, fiscal y capital con los pesos de leyes.json.
- `finalizar(motivo: String) -> void` — Cierra el periodo con un motivo (fin de mandato o crisis), fija el resultado y el puntaje.
- `hitos(maximo: int = 8) -> Array[Dictionary]` — Resumen de sesión: hitos del registro de acciones (solo lectura): [{turno, texto}] en orden cronológico, los más recientes si hay muchos.
- `sucesion() -> String` — Texto de la sucesión presidencial (solo mandato completo): depende de la aprobación final; umbrales en data/leyes.json «sucesion».
- `epilogo() -> Dictionary` — Final variado (solo texto, no toca el estado): primer epílogo de data/leyes.json «finales» cuyas condiciones se cumplen.
- `continuar_carrera() -> Dictionary` — Tras un fin de periodo (mandato completo, caída del gobierno o derrota electoral) la carrera sigue: oposición, o campaña de reelección
- `amanecer_oposicion() -> void` — Cada semana de oposición: el gobierno rival se mueve (camino aleatorio hacia su media) y tu aprobación converge a un ancla que sube si el rival lo hace mal.
- `cerrar_oposicion() -> void` — Terminadas las semanas de oposición empieza la campaña siguiente (cierre automático dentro de cerrar_turno).
- `e_dias_oposicion() -> int` — Días jugados en el periodo actual (turnos jugados por días por turno).
- `nivel() -> Dictionary` — Preset de dificultad de la partida (PR-01): fácil, normal o difícil, según estado.partido["dificultad"]; sin dato usa el defecto.
- `resolver_eleccion() -> Dictionary` — 1ª vuelta: gana quien supera el umbral; si no, pasa a la 2ª vuelta (semanas_balotaje más de campaña) con el piso configurado.

## `MotorMazo` (`sim/motor_mazo.gd`)

- `robar(n: int) -> void` — Roba cartas disponibles hasta completar la mano, rearmando el mazo desde el descarte si hace falta.
- `reponer() -> bool` — Devuelve al mazo las cartas del descarte que vuelven a estar disponibles; true si pudo reponer.
- `refiltrar_mano() -> void` — Tras cambiar el gabinete: las cartas que dejaron de estar disponibles vuelven al descarte y entran otras.
- `incorporar(ids: Array) -> Array[String]` — Desbloqueo (meta, evento o ventana): las cartas disponibles pasan al tope del mazo para robarse pronto.
- `ids_con_disponibilidad(clave: String, valor: Variant, solo_no_reales: bool = false) -> Array[String]` — Cartas ligadas a una condición (evento, año...): índice precalculado con los datos (antes recorría las ~2.000 cartas por cada evento).
- `reposicion() -> Array[String]` — DISENO_V2 §12: si la mano quedó vacía y quedan movimientos, entran más cartas disponibles (incluidas las que

## `MotorMovimientos` (`sim/motor_movimientos.gd`)

- `cargar(lista: Array) -> void` — Carga el catálogo de metas y movimientos internos.
- `amanecer() -> void` — Paso 1 del turno: renueva delegaciones y movimientos internos, y abre las cartas cuya ventana de año comienza.
- `bono_aprobacion() -> int` — DISENO_V2 §11: movimientos extra por cada umbral de aprobación superado (tramos en leyes.json › bono_movimientos).
- `fijar_movimientos() -> void` — Fin del amanecer: movimientos del turno = ahorro anterior + (base + bono por aprobación (solo gobierno) + asesores), con tope mano.tope_ahorro; y efectos de asesores.
- `ahorro_movimientos() -> Dictionary` — Salida para la UI (solo lectura): {disponibles, ingreso, tope, tope_efectivo, se_guardan, se_pierden}. `ingreso` = base + bono + asesores de esta semana;
- `metas_disponibles() -> Array[Dictionary]` — Metas que el jugador puede intentar ahora (sector con ministro, requisito previo cumplido, sin cumplir).
- `buscar_meta(meta_id: String) -> Dictionary` — Movimiento interno: cumple una meta (aplica sus efectos y desbloquea cartas); devuelve {ok, razon}.
- `ajustar_sector(sector: String, direccion: int) -> Dictionary` — Movimiento interno: sube o baja el énfasis de un sector (dirección ±1); devuelve {ok, razon}.
- `reducir_errores() -> Dictionary` — Movimiento interno: baja el riesgo de ejecución; devuelve {ok, razon}.
- `acelerar_proyecto(idx: int) -> Dictionary` — Movimiento interno: adelanta la obra en curso indicada; devuelve {ok, razon}.

## `MotorObras` (`sim/motor_obras.gd`)

- `configurar(p_leyes: Dictionary, p_rng: RandomNumberGenerator, p_regiones: Regiones) -> void` — Enlaza leyes, azar y regiones para las obras.
- `static fase_de(obra: Dictionary) -> int` — Fase de la obra (1 a 5) según sus días avanzados sobre los totales.
- `iniciar(estado: EstadoSimulacion, nombre: String, dias_totales: int, region: String, carta_id: String, efectos_final: Array, extra: Dictionary = {}) -> Dictionary` — Abre una obra en curso con sus días y efectos finales; devuelve la obra creada.
- `avanzar(estado: EstadoSimulacion, dias: int, aplicar_efecto: Callable, marcar_cumplida: Callable) -> Array[Dictionary]` — Avanza todas las obras los días dados; devuelve las terminadas y aplica sus efectos.

## `MotorPresupuesto` (`sim/motor_presupuesto.gd`)

- `gastado_anio() -> float` — Fiscal ya comprometido en extras este año de gobierno (se compara con el tope anual de la regla fiscal).
- `semanas_libre(slot: String) -> int` — Semanas que faltan para poder volver a asignar extra a ese ministerio (0 si puede).
- `fraccion_alineada(slot: String) -> float` — Fracción esperada del extra que el ministro dedica a TUS prioridades: lealtad, afinidad ideológica y competencia, acotada.
- `niveles_posibles(slot: String) -> Array[String]` — Niveles de extra que se podrían asignar hoy a ese ministerio (de menor a mayor costo en fiscal); vacío si ninguno.
- `panel() -> Dictionary` — Solo lectura para la pestaña Gabinete: topes globales y, por ministerio con ministro, extra asignado, fracción alineada esperada, riesgo y efecto semanal.
- `asignar(slot: String, nivel: String, prioridades: Array = []) -> Dictionary` — Asigna presupuesto extra a un ministerio por una temporada. prioridades: ids de cartas (obras, leyes o promesas de su sector; vacío = automático).
- `fijar_prioridades(slot: String, prioridades: Array) -> Dictionary` — Cambia las prioridades de un ministerio con extra en curso (mismo máximo).
- `amanecer() -> void` — Cada semana de gobierno: cada ministerio con extra acelera obras y leyes de su sector (más las prioritarias, menos su agenda propia) y baja el riesgo de ejecución;

## `MotorSectra` (`sim/motor_sectra.gd`)

- `static etapa_de(estado_txt: String) -> int` — Etapa del plan según el estado publicado por SECTRA. -1 = ya ejecutado o en ejecución (no se gestiona).
- `cargar(datos: Dictionary) -> void` — Carga los planes de SECTRA (proyectos de transporte) de data/.
- `existe(pid: String) -> bool` — true si el proyecto SECTRA existe.
- `proyecto(pid: String) -> Dictionary` — Datos de un proyecto SECTRA ({} si no existe).
- `estado_de(pid: String) -> Dictionary` — Lectura sin efectos: un proyecto sin trámite devuelve su etapa inicial sin tocar el estado de la partida.
- `musd(p: Dictionary) -> float` — Inversión del proyecto en millones de dólares (ilustrativo).
- `en_curso() -> int` — Cantidad de proyectos SECTRA en trámite.
- `impulsar(pid: String) -> Dictionary` — Gasta movimientos para impulsar un proyecto SECTRA; devuelve {ok, razon}.
- `avanzar() -> void` — Cierre de turno: los proyectos cuyo trámite vence esta semana pasan a la etapa siguiente.

## `MotorTurno` (`sim/motor_turno.gd`)

- `inicializar(p_estado: EstadoSimulacion, p_cartas: Array, p_eventos: Array, p_leyes: Dictionary, p_ministros: Array, p_extra: Dictionary = {}) -> void` — Conecta estado y catálogos y crea los módulos del motor.
- `turnos_mandato() -> int` — Turnos del mandato (duración en días entre días por turno).
- `aplicar_partido_inicial(datos_partido: Dictionary) -> void` — Aplica el partido elegido: indicadores, regiones y coalición propia; deja la partida en campaña.
- `iniciar_turno() -> Array[Dictionary]` — Pasos 1 y 2 del turno: amanecer y eventos; devuelve los eventos de la semana.
- `terminar_turno() -> Array[Dictionary]` — Cierra el turno y, si la partida sigue y no toca elección, inicia el siguiente.
- `ejecutar_amanecer() -> void` — Paso 1: regenera movimientos y aplica la dinámica semanal de los indicadores (ancla de aprobación, desgaste, regeneraciones).
- `cerrar_turno() -> void` — Pasos 7 y 8: votaciones, obras, crisis y avance del calendario; registra la entrada «cerrar».
- `motivos_semana() -> Array[Dictionary]` — Cambios de la semana con su causa (solo salida para la UI).
- `resolver_eleccion_presidencial() -> Dictionary` — Vota la elección presidencial (puede dar segunda vuelta).
- `continuar_carrera() -> Dictionary` — Tras un fin de periodo abre la oposición o la campaña de reelección.
- `procesar_eventos_semana() -> Array[Dictionary]` — Atajo de MotorEventos.procesar_semana.
- `costo_carta(carta: Dictionary, ministro_id: String = "") -> int` — Atajo de MotorCartas.costo_carta.
- `es_unica(carta: Dictionary) -> bool` — Atajo de MotorCartas.es_unica.
- `vista_carta(idx: int, ministro_id: String = "") -> Dictionary` — Atajo de MotorCartas.vista_carta.
- `jugar_carta(idx: int, ministro_id: String = "", region_id: String = "") -> Dictionary` — Juega una carta de la mano (con movimientos).
- `aprobar_propuesta(prop_id: String, variante_id: String, region_id: String = "", custom: Dictionary = {}, nombres: Dictionary = {}) -> Dictionary` — Atajo de MotorCartas.aprobar_propuesta.
- `impulsar_proyecto(pid: String) -> Dictionary` — Atajo de MotorSectra.impulsar.
- `calcular_puntaje() -> int` — Atajo de MotorMandato.calcular_puntaje.
- `robar_mano(n: int = 5) -> void: mazo.robar(n)` — Atajo de MotorMazo.robar.
- `carta_disponible(carta: Dictionary) -> bool` — true si el gabinete y las condiciones permiten que la carta circule.
- `elegir_gabinete(ids: Array) -> Dictionary` — Nombra el gabinete (solo en campaña o en la primera semana de gobierno).
- `delegar_carta(idx: int, ministro_id: String, region_id: String = "") -> Dictionary` — Juega una carta delegándola en un ministro (sin gastar movimientos, con riesgo de fallo).
- `prob_fallo_delegacion(idx: int, ministro_id: String) -> float` — Probabilidad de fallo de delegar la carta de la mano en ese ministro.
- `buscar_meta(meta_id: String) -> Dictionary` — Atajo de MotorMovimientos.buscar_meta.
- `ajustar_sector(sector: String, direccion: int) -> Dictionary` — Atajo de MotorMovimientos.ajustar_sector.
- `reducir_errores() -> Dictionary` — Atajo de MotorMovimientos.reducir_errores.
- `acelerar_proyecto(idx: int) -> Dictionary` — Atajo de MotorMovimientos.acelerar_proyecto.
- `contratar_asesor(id: String) -> Dictionary` — Atajo de MotorEquipo.contratar.
- `despedir_asesor(id: String) -> Dictionary` — Atajo de MotorEquipo.despedir.
- `unirse_coalicion(id: String) -> Dictionary` — Atajo de MotorCoalicion.unirse.
- `salir_coalicion(id: String) -> Dictionary` — Atajo de MotorCoalicion.salir.
- `asignar_cuota(id: String, tipo: String, valor: String) -> Dictionary` — Entrega a un aliado un ministerio o asesor que pide.
- `quitar_cuota(id: String, tipo: String, valor: String) -> Dictionary` — Retira esa cuota a un aliado.

## `Partida` (`sim/partida.gd`)

- `static armar(datos: Dictionary, semilla: int) -> MotorTurno` — Motor con los catálogos cargados y el estado vacío (sin partido ni primer turno).
- `static crear(datos: Dictionary, semilla: int, partido: Dictionary) -> MotorTurno` — Crea una partida lista para jugar: motor armado, partido aplicado y primer turno iniciado.
- `static cargar(datos: Dictionary, guardado: Dictionary, instantanea: Dictionary = {}, huella_datos: String = "", sha_guardado: String = "") -> MotorTurno` — Continúa un guardado: con una instantánea válida (ver Instantanea) restaura el estado directamente; si no, reproduce el historial.
- `static reproducir(datos: Dictionary, guardado: Dictionary) -> MotorTurno` — Reconstruye la partida exacta desde semilla + partido + entradas del jugador.

## `Regiones` (`sim/regiones.gd`)

- `cargar(p_regiones: Array) -> void` — Carga las regiones y calcula los pesos por población.
- `existe(id: String) -> bool` — true si el id corresponde a una región.
- `inicializar(estado: EstadoSimulacion, aprobacion: float, bastion: String, bono_bastion: float, variacion: float = 0.0) -> void` — Fija la aprobación regional inicial (bastión y variación determinista por semilla) y recalcula la nacional.
- `promedio(estado: EstadoSimulacion) -> float` — Aprobación nacional: promedio regional ponderado por población.
- `recalcular(estado: EstadoSimulacion) -> void` — Pone la aprobación nacional igual al promedio regional.
- `aplicar_delta(estado: EstadoSimulacion, delta: float, region: String, derrame: float) -> void` — Si hay región objetivo, recibe el delta completo y el resto un derrame; si no, todas por igual. Actualiza y promedia en una sola pasada.
- `revertir(estado: EstadoSimulacion, ancla: float, tasa: float, persistencia: float = 0.0) -> void` — Acerca cada región hacia un ancla (conservando su carácter) y recalcula la nacional.
- `revertir_a_base(estado: EstadoSimulacion, tasa: float) -> void` — Acerca cada región a su aprobación base según la tasa dada.

## `ResumenEstado` (`sim/resumen_estado.gd`)

- `static de(e: EstadoSimulacion) -> Dictionary` — Diccionario resumen de un estado para informes y la interfaz.

## `ValidarGuardado` (`sim/validar_guardado.gd`)

- `static partido_valido(p: Variant) -> bool` — true si el partido guardado tiene los indicadores y los tipos que usa el motor.
- `static entrada_valida(e: Variant) -> bool` — true si la entrada tiene un tipo conocido y las claves obligatorias de ese tipo con su tipo.
- `static guardado_valido(g: Variant) -> bool` — true si el guardado completo (versión, semilla, partido y entradas) tiene la forma esperada; se usa antes de reproducir.

## `VotoRegional` (`sim/voto_regional.gd`)

- `static ruido(semilla: int, ciclo: int, ronda: int, id: String, r: float) -> float` — eps_i de una región: uniforme en [−r, r] y fijo para esa semilla, ciclo, vuelta y región.
- `static calcular(regiones: Regiones, aprobacion_regional: Dictionary, desplazamiento: float, tope_min: float, tope_max: float, umbral: float, ruido_regional: float = 0.0, semilla: int = 0, ciclo: int = 1, ronda: int = 1) -> Dictionary` — `desplazamiento` = choque nacional − penalización + efecto rival (el mismo para todas las regiones). Devuelve el voto nacional ponderado y el detalle por región.
