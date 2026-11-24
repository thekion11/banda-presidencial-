# Paquete de prompts de arte para Gemini (D-03)

Estado: preparado el 24-nov-2026. Las imágenes se generan a mano en la app de Gemini y se suben a Drive; Claude las recorta a 1024×820, revisa paleta y las integra.
Pendiente antes de publicar: confirmar la licencia de uso comercial de las imágenes de Gemini (igual que Canva y Figma).

## Cómo usarlo
1. En cada conversación nueva de Gemini pega primero el **BLOQUE DE ESTILO**, y justo después el **prompt de la ilustración**. Sirve también pegarlos juntos.
2. Pide proporción **5:4** (o 4:3 si no hay 5:4). Claude recorta a 1024×820 (5:4 aprox.), así que deja el sujeto en el centro y margen en los bordes.
3. Si sale texto, letras, logos, banderas reales o rostros reconocibles, pide "regenera sin texto ni rostros". Rechaza esas versiones.
4. Guarda con el nombre exacto de la columna "Archivo" (ej. `seguridad_justicia.png`; PNG o JPG sirven) y súbelas a la carpeta de Drive "banda presidencial" > "arte". Máximo 10 MB cada una.
5. Orden: primero la tabla A (22 temáticas, cubren 923 de 1.343 cartas). Después la B (portada y categorías).

## BLOQUE DE ESTILO (pegar siempre primero)
```
Ilustración editorial plana en vector, estilo infografía de prensa moderna, formas geométricas simples, sin degradados complejos, sin texturas fotográficas. Paleta cerrada: azul océano profundo #0B2236 (fondo), azul panel #16405F (planos secundarios), dorado #F2C14E (acento principal), rojo #C23B2E (un detalle pequeño), crema #FBF7EC (luces y siluetas). Composición horizontal 5:4, sujeto central grande y legible a tamaño pequeño, borde seguro del 8%. SIN texto, SIN letras, SIN números, SIN logotipos, SIN banderas reales, SIN rostros detallados ni personas reconocibles (si hay figuras, siluetas anónimas sin cara). Una sola escena, sin collage, sin marco.
```

## A. Ilustraciones temáticas (22) — prioridad alta
| # | Archivo | Cartas | Escena para pegar tras el bloque de estilo |
|---|---|---|---|
| 1 | `seguridad_justicia` | 199 | Balanza de la justicia y mazo sobre un estrado, columnas de tribunal al fondo; sin personas. |
| 2 | `obras_vial` | 113 | Carretera y puente en construcción, grúa y maquinaria amarilla (dorado), cerros andinos al fondo. |
| 3 | `politica_reforma` | 111 | Hemiciclo semicircular visto de frente con un libro grande abierto (texto constitucional) en primer plano, sin texto legible. |
| 4 | `salud_hospitales` | 105 | Fachada de hospital moderno con cruz, ambulancia pequeña, corazón o pulso estilizado en dorado. |
| 5 | `trabajo` | 59 | Siluetas de trabajadores de varios oficios (construcción, oficina, taller) ante un reloj grande. |
| 6 | `social_familia` | 52 | Siluetas de una familia diversa: adulto mayor, mujer, niño y persona con silla de ruedas, tomados de la mano. |
| 7 | `medioambiente_agua` | 46 | Planta de agua potable: estanques circulares, tuberías y una gota grande dorada. |
| 8 | `obras_edificacion` | 45 | Edificio público en construcción con andamios y una grúa torre, planos azules en el cielo. |
| 9 | `ambiente` | 45 | Paisaje chileno: cordillera, bosque nativo, un cóndor en vuelo y un río; sol dorado. |
| 10 | `transportes_transito` | 44 | Calle con semáforo, paso de cebra, auto y moto estilizados, señal de tránsito sin texto. |
| 11 | `economia_consumo` | 40 | Almacén o tienda de barrio con toldo, carro de compras y caja registradora, monedas doradas. |
| 12 | `transportes_aeropuertos` | 39 | Terminal de aeropuerto con torre de control y un avión despegando. |
| 13 | `seguridad_carceles` | 36 | Muro perimetral con torre de vigilancia y portón, luz de reflector; tono sobrio. |
| 14 | `educacion_escuela` | 34 | Escuela con libros apilados, birrete y un globo terráqueo; pizarra sin texto. |
| 15 | `seguridad_defensa` | 29 | Radar y silueta de buque de guerra, avión militar y escudo genérico (sin emblemas reales). |
| 16 | `politica_tratados` | 27 | Dos manos estrechándose sobre un globo terráqueo, pluma y documento sin texto. |
| 17 | `transportes_trenes` | 24 | Tren o metro moderno entrando a una estación, rieles en perspectiva. |
| 18 | `social_pensiones` | 19 | Pareja de adultos mayores en una banca bajo un árbol, alcancía dorada grande a su lado. |
| 19 | `descentralizacion_municipal` | 18 | Edificio municipal con reloj y plaza, mapa de Chile alargado detrás con regiones marcadas. |
| 20 | `politica_electoral` | 17 | Urna de votación con papeleta entrando y una fila de siluetas; marca de verificación dorada. |
| 21 | `economia_puertos` | 15 | Puerto con grúas pórtico, contenedores apilados y un carguero. |
| 22 | `hacienda_tributaria` | 11 | Calculadora grande, monedas y un documento con sello (sin texto), pila de billetes estilizados. |

## B. Portada y categorías (15) — prioridad media
Hoy miden 512×410 (salvo `estado`, ya en 1024×820). Mismo bloque de estilo.
| Archivo | Escena |
|---|---|
| `portada` | Palacio de gobierno de frente con banda presidencial dorada y roja flotando sobre él, cordillera detrás; formato vertical 9:16 si se puede (pantalla de inicio). |
| `comite` | Mesa de reunión con planos desplegados y siluetas alrededor, vista isométrica. |
| `descentralizacion` | Mapa de Chile alargado con regiones en bloques de color y pines dorados. |
| `economia` | Gráfico de barras ascendente, engranajes y monedas. |
| `educacion` | Libro abierto, lápiz y birrete. |
| `energia` | Torres eléctricas, paneles solares y aerogeneradores al atardecer. |
| `hacienda` | Edificio de tesorería con columnas y bolsa de monedas. |
| `medioambiente` | Árbol grande con raíces visibles y hojas doradas. |
| `obras` | Excavadora y casco de obra sobre planos. |
| `politica` | Fachada de congreso con columnas y un podio vacío. |
| `salud` | Estetoscopio y cruz médica con pulso. |
| `seguridad` | Escudo y luz de patrulla estilizada, sin emblemas reales. |
| `social` | Manos sosteniendo una casa pequeña y un corazón. |
| `transportes` | Bus, tren y avión en un mismo plano de movimiento. |
| `vivienda` | Fila de casas y un edificio de departamentos con ventanas doradas. |

## Revisión (la hace Claude al recibirlas)
- Paleta: dominan #0B2236 y #16405F; dorado como acento; rojo solo en detalles.
- Sin texto, logos, banderas ni personas reconocibles.
- Legible a 200 px de ancho; mismo trazo y grosor entre piezas.
- Si una pieza desentona, se pide regenerar con el mismo bloque de estilo y una frase de corrección.

## Registro de avance (24-nov-2026)
Todo recortado a 1024×820 e integrado en `game/arte/cartas/`; originales de Gemini recibidos por el chat de la sesión.
| Bloque | Estado |
|---|---|
| Tabla A: 22 temáticas | **22 de 22 integradas** (cubren 1.304 de 1.343 cartas) |
| Tabla B: `portada` | Recibida en vertical 572×1024 (`game/arte/marca/portada.jpg`; original en `docs/arte_originales/`). **Aún no está conectada al menú** (rediseño de portada pendiente) y es de baja resolución para pantalla completa: hay que reescalarla o regenerarla. |
| Tabla B: `comite` | Recibida en vertical 572×1024; se recortó el centro a 5:4 y se amplió a 1024×820 (`game/arte/cartas/comite.jpg`). Original en `docs/arte_originales/`. Si se ve borrosa en el teléfono, regenerar en horizontal. |
| Tabla B: 13 categorías restantes | Pendientes (`descentralizacion`, `economia`, `educacion`, `energia`, `hacienda`, `medioambiente`, `obras`, `politica`, `salud`, `seguridad`, `social`, `transportes`, `vivienda`). Hoy 512×410. |
| Límite diario de Gemini | Alcanzado el 24-nov-2026; se retoma cuando se renueve. |

### Pendientes de calidad conocidos
- `descentralizacion_municipal`: árboles verdes (fuera de paleta) y un detalle borroso al sur del mapa; regenerar con «solo estos cinco colores, sin verde».
- `social_pensiones`: muy oscura (silueta azul sobre fondo azul); revisar a tamaño de carta.
- `seguridad_defensa` y `trabajo`: muy cargadas; revisar a tamaño de carta.
- Ninguna ilustración se ha visto aún dentro de la carta en el teléfono: falta APK de revisión.
- Licencia de uso comercial de las imágenes de Gemini: sin confirmar.

### Lecciones del estilo (para las que faltan)
- Añadir al bloque de estilo: «sin marco ni borde; la ilustración llega hasta el filo» y «pocos elementos, grandes».
- Pedir **horizontal 5:4** para las categorías; la vertical 9:16 solo para la portada.
