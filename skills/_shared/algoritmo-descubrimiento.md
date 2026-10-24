# Algoritmo de descubrimiento de Roblox (Recommended for You)

Verificado el 2026-10-24 en la documentación oficial (https://create.roblox.com/docs/discovery y `/discovery-faq`), leída desde su fuente en el repo `Roblox/creator-docs` (`content/en-us/discovery.md` y `discovery-faq.md`, commit `46be165` del 2026-10-23). Roblox agrega, quita y repondera señales: **volver a verificar antes de decisiones grandes** (concepto, lanzamiento, rediseño) y actualizar la fecha de este archivo.

Lo marcado **(hub)** es criterio nuestro derivado de las reglas oficiales, no texto de Roblox.

## Qué cambió en 2026

Comparando el historial de `discovery.md` en `Roblox/creator-docs` (versión del 2026-04-15 contra la actual):

| Fecha | Cambio |
|---|---|
| 2026-06-15 | **Se reemplazan las señales de entrada.** Salen *qualified play through rate (qPTR)* y *deep play through rate*; entran *play through rate (PTR)* y *first play bounce rate*, una señal **negativa** medida a < 60 s y a 61–180 s. |
| 2026-06-15 | **De 7 días a 28.** Antes todas las señales eran "últimos 7 días" (playtime, play days, spend days, Robux, co-play, qualified sessions). Ahora cada una se mide en tres ventanas: D1, D2–7 y D8–28. |
| 2026-06-15 | **Las señales tienen prioridad.** Antes eran una lista plana ("cuando mejoran todas juntas"). Ahora hay "más importantes" (PTR, bounce, play days, playtime) e "importantes" (co-play, qualified sessions, spend days, Robux), y el objetivo declarado es premiar la **retención a largo plazo**. |
| 2026-06-15 | El ranking excluye también la **retención** (no solo engagement y monetización) de jugadores llegados por otras fuentes, y suma "curación" a esa lista. Se documentan estacionalidad y competencia como causas de cambios en impresiones. |
| 2026-10-02 | Se publica el FAQ: no hay que esperar 28 días, no hay castigo por mal arranque, el género no es señal, los juegos finitos o de historia no se penalizan, los ads no penalizan pero sus jugadores no cuentan, y Home muestra unos 100 juegos por usuario. |
| 2026-10-20 | **Thumbnail propio obligatorio** para recibir impresiones de Home. |

No cambió: las dos etapas (retrieval y ranking), *explore and expand*, el tope de 60 min diarios de playtime y las reglas contra metadata engañosa y juegos no únicos (vigentes desde diciembre de 2024).

## Cómo decide

- **Dos etapas.** *Retrieval*: elige candidatos por engagement, retención y monetización; alcanza con muy pocas visitas de cualquier fuente (ads, búsqueda, amigos, redes, notificaciones). *Ranking*: ordena de forma personalizada usando **solo** el comportamiento de quienes llegaron orgánicamente desde Recommended for You (RFY).
- **Otras fuentes no cuentan para el ranking.** Lo que hacen los jugadores traídos por ads, curación, amigos, búsqueda o redes no entra en las señales de RFY. Los ads no penalizan, pero a un jugador adquirido por ad el algoritmo lo da por adquirido y ya no le muestra el juego en RFY (las impresiones de RFY pueden bajar aunque suban las visitas totales).
- **Promedios por usuario, no totales.** Un juego chico con jugadores muy enganchados no queda en desventaja.
- **Explore y expand.** Tras un update prueba el juego con una cohorte nueva; si esa cohorte retiene y gasta, lo muestra a más cohortes parecidas.
- **Ventana móvil, sin castigo por mal arranque.** El juego se prueba a diario; si se arregla el onboarding, vuelve a ganar impresiones.
- **Un juego nuevo no espera 28 días.** Primero cuentan play through rate y bounce (primera sesión), después D1, D2–7 y D8–28.
- **El género no es señal explícita**: se aprende del comportamiento. Etiquetas precisas igual importan porque una etiqueta engañosa produce rebotes.
- **Competencia relativa.** Si otros juegos mejoran más que el tuyo, tu distribución puede bajar aunque tus señales no cambien. Hay estacionalidad semanal (pico el sábado), de vacaciones y de vuelta a clases.

## Señales

Todas se miden sobre jugadores que llegaron orgánicamente desde RFY.

| Prioridad | Señal | Qué mide | Ventanas |
|---|---|---|---|
| Más importante | Play through rate (PTR) | Cuántos juegan después de ver el juego en RFY | — |
| Más importante | First play bounce rate | Cuántos se van tras una sesión corta. **Señal negativa** | < 60 s y 61–180 s |
| Más importante | Play days per user | Días distintos en que juegan | D1, D2–7, D8–28 |
| Más importante | Playtime per user | Tiempo jugado (tope: 60 min por usuario, juego y día) | D1, D2–7, D8–28 |
| Importante | Intentional co-play days per user | Días en que vuelven a jugar **con amigos** (join, invitaciones, servidores privados) | D1, D2–7, D8–28 |
| Importante | Qualified play sessions per user | Sesiones significativas (filtra clics accidentales y rebotes) | D1, D2–7, D8–28 |
| Importante | Spend days per user | Días distintos en que gastan Robux | D1, D2–7, D8–28 |
| Importante | Robux spent per user | Robux gastados | D1, D2–7, D8–28 |

Orden de trabajo que recomienda Roblox: si la retención es baja, primero el gameplay; con retención sólida, mejorar la monetización suma impresiones. Los juegos fuertes en retención **y** monetización reciben distribución más amplia; los fuertes en solo una siguen recibiendo impresiones.

No confundir con el panel de **Retention** de Creator Analytics, que muestra D1/D7/D30 por cohorte: las ventanas del algoritmo son D1, D2–7 y D8–28.

## Requisitos y qué reduce la exposición

- **Thumbnail propio obligatorio**: con el thumbnail por defecto el juego no es elegible para Home.
- **Reducen la exposición** en Home y búsqueda:
  - metadata que promete recompensas o Robux (ej. "Robux! Play now!");
  - metadata que no coincide con el juego (thumbnail de dinosaurios en un obby sin dinosaurios);
  - **juegos no únicos**: título, imágenes o place file muy parecidos a juegos existentes.
- Si el juego tiene exposición reducida, el Creator Dashboard muestra un banner que se actualiza a diario.
- Ayuda: un video de gameplay fiel en la página del juego.

## Qué implica en cada fase del hub

| Fase | Regla |
|---|---|
| 1 `roblox-ideation` | Puntuar cada concepto también por: motivo para volver en D2–7 y D8–28, juego con amigos (co-play) y si cabe una mecánica jugable en el primer minuto. **(hub)** |
| 2 `roblox-game-cloner` | Se toman mecánicas, nunca título, thumbnails, mapa ni place file: un clon reconocible es "no único" y pierde exposición. La spec debe decir qué lo diferencia. |
| 3 `roblox-ui-designer` | El bounce se mide a los 60 y 180 s: el jugador tiene que estar jugando, no leyendo, en los primeros segundos. Onboarding corto y por acción. **(hub)** |
| 4 `roblox-monetization` | Retención primero. La señal premia días con gasto y Robux por usuario: ofertas útiles y recurrentes antes que un único pago grande, siempre con monetización honesta. **(hub)** |
| 6 `roblox-qa-performance` | Carga y rendimiento en móvil de gama baja: un juego que tarda o se traba rebota antes de los 60 s. **(hub)** |
| 8 `roblox-publishing` | Thumbnail propio, metadata precisa sin promesas de Robux, video de gameplay. La métrica de la vitrina es PTR (no solo CTR). |
| 9 `roblox-metrics-growth` | Creator Analytics → **Acquisition → Home Recommendations**: leer primero PTR, bounce, play days y playtime; si están estables, co-play, qualified sessions, spend days y Robux. Comparar con el benchmark (no afecta al algoritmo, solo orienta). Instrumentar el onboarding con `AnalyticsService:LogOnboardingFunnelStepEvent` para ver dónde se van en los primeros minutos. |
| 10 `roblox-liveops` | Cada update abre una fase *explore*: publicar updates con mejoras medibles. Experience Events y notificaciones traen de vuelta en D2–7 y D8–28. |
