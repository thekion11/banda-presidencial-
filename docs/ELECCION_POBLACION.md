# La elección toma en cuenta la población (27-nov-2026)

**Petición del usuario (vía la coordinadora, 27-nov-2026):** «Las elecciones deben tomar en cuenta la población».

## Qué hace el motor ahora
- `sim/voto_regional.gd` (`VotoRegional.calcular`): para cada región, `voto_i = aprobación_i + desplazamiento` (acotado a 0..100), con `desplazamiento = choque nacional (la misma tirada ±ruido_eleccion de antes) − penalización por no tener promesas + efecto del rival`. El **voto nacional** es la suma ponderada `Σ peso_i · voto_i` con `peso_i` = población de la región / población total (`regiones.pesos`, suman 1). Umbral y segunda vuelta se evalúan igual en la 1ª y la 2ª vuelta sobre el voto nacional, que se calcula como antes (aprobación nacional + desplazamiento) y coincide con `Σ peso_i · voto_i` salvo los topes 0..100 por región; así no cambia ni un bit de lo ya medido (umbrales exactos incluidos). Si la aprobación nacional se aparta del promedio regional (solo en pruebas con estado forzado), la diferencia se reparte por igual entre regiones.
- Salida (solo para la pantalla): `MotorMandato.resolver_eleccion` devuelve y deja en `estado.ultima_eleccion` por región `{id, habitantes_miles, peso, voto, gana_gobierno (voto ≥ umbral), votos_estimados_miles = habitantes × voto / 100}`, más `total_habitantes_miles`, `regiones_ganadas` y `votos_estimados_miles`. `estado.ultima_eleccion` no entra al guardado por eventos ni a las huellas (se recalcula al reproducir). Las encuestas por región traen ahora su `peso`.
- **Efecto en el balance sin ruido regional: ninguno (con ruido 6, ver §BV).** Como la aprobación nacional ya era el promedio regional ponderado por población, el voto nacional sale igual que antes (diferencia máxima 0,000000 en 100 campañas, `tests/analisis_voto_regional.gd`); los tres oros y las huellas no cambian. Lo nuevo es el desglose por región y la cifra de votos estimados («votos estimados» son ilustrativos: no hay participación ni padrón por región).

## Ruido regional (D23, cerrada): `campana.ruido_eleccion_regional` = 6 desde el 27-nov-2026 (DECISIONES §BV)
Cada región suma un ruido determinista en [−6, 6] (derivado de semilla, ciclo, vuelta y región) y el voto nacional es Σ peso · voto; `gano_por` dice si ganaste por población, por regiones, por ambas o por ninguna.

## Lo que no se hizo y por qué
- **Ruido regional aleatorio (D23):** no existe un parámetro en `data/leyes.json` para un componente aleatorio por región (solo el choque nacional) y `data/` está congelado. Añadirlo cambiaría el balance y los oros. Propuesta al usuario (D23): un `ruido_regional` pequeño con costo medible antes de repartir la prueba.
- **Cámara de Diputados y Senado por geografía:** el hemiciclo del motor no tiene distritos ni circunscripciones. Propuesta (sin implementar): 155 diputados repartidos por distritos de población y 50 senadores por región (cada región elige el mismo número en el Senado), de modo que ganar en regiones grandes dé más diputados y en regiones pequeñas más senadores. Es una mecánica nueva; requiere autorización del usuario (D24).

## Pruebas
`tests/test_voto_regional.gd`: pesos suman 1; la RM pesa su población relativa; voto nacional = suma ponderada; una fila por región; «región grande gana / pequeñas pierden» (y al revés); determinismo del resultado; `voto_final = Σ peso · voto` en una campaña real.
