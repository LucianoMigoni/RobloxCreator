# Matriz de puntuación de conceptos

Cada criterio se puntúa de 0 a 5 con una frase que lo justifique. Puntaje = suma ponderada sobre 100. Los pesos salen de lo que mide el algoritmo de Home (`skills/_shared/algoritmo-descubrimiento.md`) y de lo que un equipo de dos puede construir. Si el usuario quiere otros pesos, se cambian y se anotan en `concepto.md`.

| # | Criterio | Peso | 0 | 5 |
|---|---|---|---|---|
| 1 | **Primer minuto** (bounce < 60 s): ¿se está jugando, no leyendo, en los primeros segundos? ¿se entiende sin tutorial? | 15 | Menús, texto o espera antes de jugar | Acción divertida en < 10 s, se aprende jugando |
| 2 | **Loop central** (guía oficial *Core loops*): acción repetida minuto a minuto + motor de progresión | 15 | Acción aislada sin progreso | Acción satisfactoria que alimenta una progresión visible |
| 3 | **Motivo para volver D2–7 y D8–28** | 15 | Se "termina" en una sesión | Metas a varios días: colección, temporadas, mejoras, eventos |
| 4 | **Juego con amigos** (co-play intencional) | 10 | Se juega igual solo | Es mejor con amigos: cooperar, competir, comerciar, servidores privados |
| 5 | **Diferenciación** (algoritmo: juegos "no únicos" pierden exposición) | 10 | Igual a un juego existente | Un giro propio claro en mecánica, tema o formato |
| 6 | **Evidencia de demanda** (fuentes verificables) | 10 | Ninguna | Varios juegos del mismo género o tema en Charts con datos citados, con un hueco identificado |
| 7 | **Monetización honesta** (ver `roblox-monetization`) | 10 | Solo funciona con cajas pagas o ventajas pagas injustas | Cosméticos, pases que ahorran tiempo, packs con valor real |
| 8 | **Alcance para el equipo** (la plantilla ya trae datos, tienda, inventario, onboarding y UI) | 10 | Meses de sistemas nuevos o física compleja | Un MVP en 2–3 semanas sobre la plantilla |
| 9 | **Móvil y gama baja** (la mayoría juega en móvil, guía oficial *Design for Roblox*) | 5 | Precisión fina, muchas partes, UI densa | Controles de un dedo, pocas partes, UI grande |

Puntaje = Σ (puntos / 5 × peso).

Reglas:
- **Corte duro:** un 0 en los criterios 1, 5 o 7 descarta el concepto, aunque el total sea alto.
- **Evidencia:** sin fuente, el criterio 6 vale como mucho 2 y el concepto se marca "hipótesis por validar".
- **Público alcanzable** (`roblox-compliance`): si el público objetivo incluye menores de 16 y el núcleo del concepto los deja afuera (social hangout como actividad principal, creación libre, tema sensible principal, alcohol, temas románticos, lenguaje fuerte, violencia o sangre realista fuerte), el concepto se descarta o se cambia el público. Todo juego nuevo sale primero solo para 16+ y llega a menores de 16 recién después de una evaluación con jugadores 16+: anotarlo como riesgo si el concepto solo atrae a chicos chicos **(hub)**.
- **Desempate:** gana el de mejor criterio 3 (retención a largo plazo, que es lo que más premia el algoritmo desde junio de 2026).
