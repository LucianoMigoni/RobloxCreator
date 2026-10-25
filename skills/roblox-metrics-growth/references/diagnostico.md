# Del síntoma a la acción

Fuentes (verificadas el 2026-10-25): `/discovery` y `/discovery-faq` (señales de Home), `/production/analytics/retention` (cómo mejorar D1, D7 y D30), `/production/analytics/funnel-events`. Lo marcado **(hub)** es criterio nuestro.

## Antes de diagnosticar
- **Estacionalidad:** el pico semanal suele ser el sábado; hay temporadas de vacaciones y vuelta a clases. Comparar mismos días de la semana y ventanas iguales.
- **Competencia:** las impresiones pueden bajar aunque tus señales no cambien, si otros juegos mejoran más.
- **Explore y expand:** después de un update, Roblox prueba el juego con cohortes nuevas. El PTR puede bajar un tiempo cuando suben las impresiones, y es normal.
- **Benchmark:** el panel compara con juegos parecidos. Sirve de guía, no afecta al algoritmo.
- **Un cambio a la vez (hub)**, con fecha, para saber qué movió qué.

## Tabla
| Síntoma | Dónde se ve | Causa probable | Acción | Skill |
|---|---|---|---|---|
| PTR bajo | Home Recommendations | Thumbnail o título poco atractivos o que no reflejan el juego | Thumbnail propio y fiel, probar variantes (personalización de thumbnails), metadata precisa | `roblox-publishing` |
| Bounce < 60 s alto | Home Recommendations; embudo de onboarding (primer paso con caída) | Carga lenta, inicio confuso, nada que hacer en los primeros segundos | Acción jugable en segundos, onboarding más corto, medir la carga en móvil de gama baja | `roblox-game-cloner` (primer minuto), `roblox-ui-designer`, `roblox-qa-performance` |
| Bounce 61–180 s alto | Home Recommendations; embudo (pasos 2 y 3) | El loop no engancha después del primer intento | Recompensa temprana, objetivo visible, primera compra alcanzable en el primer minuto o dos | `roblox-game-cloner` |
| D1 baja | Retention (D1), play days D1 | Loop central, primera experiencia, rendimiento (guía oficial de retención) | Pulir el loop y el onboarding; QA de rendimiento | `roblox-game-cloner`, `roblox-qa-performance` |
| D2–7 / D7 baja | Retention (D7), play days D2–7 | Progresión (guía oficial) | Metas de varios días, desbloqueos, recompensas diarias honestas | `roblox-game-cloner`, `roblox-liveops` |
| D8–28 / D30 baja | Retention (D30), play days D8–28 | Falta de "final" o de metas largas (guía oficial: sistema de cierre) | Temporadas, eventos, contenido nuevo con cadencia | `roblox-liveops` |
| Poco co-play | Intentional co-play days | Jugar solo es igual que con amigos | Recompensas cooperativas, invitaciones, servidores privados | `roblox-game-cloner`, `roblox-monetization` |
| Buena retención, poco gasto | Spend days, Robux por usuario | Tienda poco visible o sin compras contextuales | Compras contextuales, pase de temporada, revisar el catálogo | `roblox-monetization` |
| Economía inflada | Eventos de economía (fuentes contra sumideros) | Demasiadas fuentes o sumideros poco atractivos | Rebalancear montos en `Config/`, agregar sumideros con valor | `roblox-monetization` |
| Banner de exposición reducida | Creator Dashboard | Metadata engañosa, promesas de Robux, juego no único | Corregir la metadata y diferenciar el juego | `roblox-publishing` |
