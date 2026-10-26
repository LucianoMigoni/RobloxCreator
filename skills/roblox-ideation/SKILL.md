---
name: roblox-ideation
description: Genera y puntúa conceptos de juegos de Roblox con evidencia verificable y con lo que premia el algoritmo de descubrimiento (primer minuto, retención D2–7 y D8–28, juego con amigos, diferenciación). Usar en la fase 1 del pipeline, cuando el usuario trae una idea, un género o nada y hay que decidir qué juego hacer.
---

# roblox-ideation

## Objetivo
Elegir un concepto con buenas probabilidades: que enganche en el primer minuto, que dé motivos para volver, que se juegue mejor con amigos, que sea distinto de lo que ya existe y que el equipo lo pueda construir rápido sobre la plantilla. Sale `games/<juego>/docs/concepto.md`.

## Cuándo usarlo
- Fase 1 del pipeline: hay una idea suelta, un género o nada.
- Para reevaluar un juego que no retiene (con `roblox-metrics-growth`).

**Lo llaman:** el usuario al empezar un juego (ver `CLAUDE.md` → Empezar un juego nuevo).
**Llama a:** `roblox-game-cloner` con el concepto aprobado (fase 2).

## Reglas de evidencia
- **Nunca inventar cifras** (jugadores, visitas, ingresos, retención). Cada dato lleva su fuente (URL) y la fecha en que se vio.
- Fuentes válidas: Charts de Roblox (top y trending por género), la página del juego (visitas, favoritos, última actualización), Creator Analytics de los juegos propios, y la documentación oficial. Si el sitio no es accesible desde la sesión, pedirle al usuario capturas o los datos y citarlos como "aportado por el usuario, fecha".
- Lo que no se pudo verificar va en una lista aparte, marcado como **hipótesis**, y no suma en el criterio de evidencia.
- Contexto oficial que sí se puede citar: la mayoría juega en móvil y hoy hay más usuarios de 13 años o más que de menos de 13 (`/production/roblox-user-base`, `/production/game-design/design-for-roblox`). Los "turistas" saltan entre juegos y los "locales" forman casi toda la base comprometida: el concepto tiene que convertir turistas en locales.

## Flujo

1. **Entender el pedido.** Idea, género, referencias y restricciones del usuario (plazo, tamaño del equipo, qué no quiere). Si no trae nada, preguntar qué juegos juega o le gustan.
2. **Investigar.** Entre 10 y 20 juegos de referencia del género o tema (Charts por género, juegos que el usuario nombró). Por cada uno: género y subgénero oficial (`references/genres.md`), loop central, cómo engancha en el primer minuto, qué vende, y los datos visibles con fuente y fecha.
3. **Tendencias y huecos.** Qué se repite (convenciones que los jugadores ya conocen y conviene respetar) y qué falta: un tema poco cubierto, una mecánica que nadie combinó con otra, un público desatendido (por ejemplo, el de 13+).
4. **Proponer de 3 a 5 conceptos** con la plantilla `references/concepto-template.md`. Cada uno con gancho, loop central (guía oficial *Core loops*: acción repetida + motor de progresión), primer minuto, motivos para volver, juego con amigos, diferenciación, monetización (con ventajas pagas si encajan), género oficial, alcance y riesgos.
5. **Puntuar** con `references/scoring.md`. Aplicar los cortes duros: primer minuto, diferenciación o monetización en 0 descartan el concepto.
6. **Recomendar** uno, con la hipótesis más riesgosa a validar primero en el prototipo (guía oficial *Prototyping*: encontrar la diversión antes de construir de más).
7. **Escribir `docs/concepto.md`** y mostrarlo al usuario. Esperar su visto bueno (puerta de revisión) antes de pasar a `roblox-game-cloner`.

## Checklist
- [ ] Cada dato numérico tiene fuente y fecha; lo no verificado está marcado como hipótesis.
- [ ] De 3 a 5 conceptos, cada uno con todos los campos de la plantilla.
- [ ] Puntuación con justificación por criterio y cortes duros aplicados.
- [ ] Género y subgénero de la lista oficial.
- [ ] Ningún concepto copia título, imágenes ni mapa de un juego existente.
- [ ] Recomendación con la hipótesis a validar primero.
- [ ] `docs/concepto.md` escrito y revisado por el usuario.

## Límites
- No promete éxito: la puntuación ordena opciones, no predice ingresos.
- No usa herramientas de terceros que scrapean Roblox ni datos sin fuente.
- No decide precios (eso es `roblox-monetization`) ni diseña mecánicas al detalle (eso es la spec de `roblox-game-cloner`).
