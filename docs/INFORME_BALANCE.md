# Informe de balance (Monte Carlo, 23-nov-2026)

Comando: `godot --headless --path . -s tests/montecarlo.gd -- 120` sobre `ccr-ec102a3c-giitie` (1.276 cartas por proyecto + 58 base, gabinete de 8, 5 movimientos, segunda vuelta, quórums del art. 66/127). n = 120 partidas por política.

| Política | Gana elección | Cae en crisis | Completa mandato | Aprob. final media | Puntaje mediano | Promesas pend. |
|---|---|---|---|---|---|---|
| pasivo | 3,3 % | 3,3 % | 0,0 % | 9,0 | 0 | 0,0 |
| azar | 21,7 % | 5,0 % | 16,7 % | 16,1 | 1.653 | 3,1 |
| codicioso | 76,7 % | 0,0 % | 76,7 % | 36,5 | 2.306 | 2,2 |
| codicioso > pasivo (campaña bien jugada, luego no juega) | 76,7 % | 76,7 % | 0,0 % | 8,9 | 0 | 22,9 |
| codicioso > azar | 76,7 % | 30,0 % | 46,7 % | 14,8 | 1.610 | 3,0 |

Lectura:
- Jugar pesa en la campaña (pasivo 3 % vs codicioso 77 %) y gobernar sin hacer nada lleva a la crisis (77 %). `test_balance` exige estas relaciones y pasa.
- El azar gana 1 de cada 5 elecciones: la dificultad es razonable para una primera prueba.

Límites del informe (qué NO mide):
- Los bots **no usan** delegación, movimientos internos, asesores ni coalición: el equilibrio de esas mecánicas no está medido; solo está probado su funcionamiento (`test_delegacion`, `test_movimientos`, `test_equipo`, `test_coalicion`).
- La aprobación media del bot codicioso es 36,5: el **bono por aprobación (desde 60 %)** casi nunca se activa; con estos bots no se puede evaluar si desbloquea demasiados movimientos (el máximo teórico, con asesores, es 18).
- Los efectos de las cartas por proyecto son ilustrativos: el balance fino depende de pruebas con personas.
