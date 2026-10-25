---
name: roblox-liveops
description: Planifica y ejecuta la operación de un juego de Roblox publicado (cadencia de contenido, updates grandes, mejoras de calidad, arreglos, eventos temporales y de temporada, Experience Events, anuncios y notificaciones), con cada update ligado a una métrica y a un changelog. Usar en la fase 10 del pipeline, en cada ciclo de updates y al planificar un evento.
---

# roblox-liveops

## Objetivo
Que el juego tenga siempre algo nuevo que hacer y un motivo para volver en D2–7 y D8–28, con un ritmo que el equipo pueda sostener. Cada update abre una fase *explore* del algoritmo: Roblox lo prueba con jugadores nuevos y, si retienen y gastan, lo muestra a más (`skills/_shared/algoritmo-descubrimiento.md`). Sale `games/<juego>/docs/liveops.md` (calendario) y un changelog por update.

## Cuándo usarlo
- Fase 10 del pipeline, con el juego publicado y las primeras métricas.
- Al empezar cada ciclo de updates y al planificar un evento.
- Cuando `roblox-metrics-growth` marca caída de play days en D2–7 o D8–28 (falta motivo para volver).

**Lo llaman:** el usuario, `roblox-metrics-growth` (retención a mediano plazo baja).
**Llama a:** `roblox-metrics-growth` (métrica de cada update y revisión), `roblox-monetization` (ofertas de eventos y pases de temporada), `roblox-qa-performance` y `roblox-compliance` (antes de cada publicación), `roblox-publishing` (miniaturas nuevas en updates grandes), `roblox-ui-designer` y `roblox-security` (UI y remotes nuevos).

## Base oficial
Verificado el 2026-10-25 en `/production/game-design/liveops-essentials`, `/liveops-planning`, `/content-updates`, `/production/promotion/experience-events`, `/experience-notifications` y la referencia de `ExperienceNotificationService` (repo `Roblox/creator-docs`, commit `4e795e6`).

- **Cuatro tipos de update:** cadencia de contenido, updates grandes, mejoras de calidad (QoL) y arreglos de errores.
- **Cadencia:** de semanal a mensual; muchos juegos sacan algo cada dos semanas a un mes. Se apoya en sistemas que ya existen (mascotas, vehículos, armas, mapas, misiones, variantes), con **menos de tres semanas de trabajo** por entrega. Agregar un sistema nuevo ya es un update grande.
- **Que no se consuma de golpe:** progresión (contenido al final para los avanzados), contenido por tiempo limitado que lleve semanas completar, pase de temporada.
- **Updates grandes:** sistemas nuevos y permanentes (sociales, competitivos, colecciones y logros, eventos en vivo); llevan meses.
- **QoL:** UI, flujos, accesibilidad, rendimiento; se sacan cuando haga falta. **Arreglos:** priorizar por gravedad, esfuerzo y jugadores afectados.
- **Planificar cada evento con:** KPI a mover, qué hace el jugador y cómo impacta en la economía (que las recompensas no la inflen), cómo y cuándo se comunica (dentro y fuera del juego), y datos **rápidos** (por hora el mismo día) y **comparables** (la semana anterior y la siguiente).
- **Experience Events** (Creator Dashboard → **Engagement → Events & Updates**): hasta 10 eventos en curso o próximos; los jugadores tocan *Notify Me* y reciben aviso al empezar. Quien entra desde el evento trae `EventId` en `Player:GetJoinData().GameJoinContext`. Charts tiene una lista *Trending Events* (evento empezado hace menos de 7 días, mínimo 1000 RSVP, público). Programa *Off-Platform Featuring*: postular al menos 7 días antes.
- **Anuncio de update:** hasta 60 caracteres, una vez cada 3 días, a quienes activaron notificaciones del juego.
- **Notificaciones del juego** (servidor, paquete oficial del Creator Store o la API Open Cloud): llegan a usuarios de 13+ que las activaron. Para pedir el permiso: `ExperienceNotificationService:CanPromptOptInAsync()` en `pcall` y después `PromptOptIn()` en un momento que justifique un aviso futuro (el texto es fijo; no se muestra a quien lo vio en los últimos 30 días).
- **Ofertas por tiempo limitado:** con fecha de fin real; nada de cuentas regresivas que se reinician (reglas de monetización, `roblox-monetization`).

## Flujo
1. **Diagnóstico:** `roblox-metrics-growth` dice qué señal está más floja. Primero lo más importante: si el problema es el primer minuto, el próximo update es de onboarding o QoL, no de contenido.
2. **Calendario** en `docs/liveops.md` (`references/changelog-template.md`): las próximas 4 a 8 semanas con cadencia, eventos, QoL y arreglos, y el update grande en curso. Ritmo que el equipo de dos personas sostiene sin quemarse (lo pide la guía oficial).
3. **Cada update:** qué agrega, qué métrica debería mover, cuánto y la fecha de revisión. Como mucho un cambio grande por update, para poder leer el efecto.
4. **Eventos:** fecha de inicio y fin reales, recompensas revisadas contra la economía (`CurrencyService` registra las fuentes nuevas), Experience Event creado y comunicado con anticipación, y la oferta del evento auditada (`roblox-monetization`).
5. **Antes de publicar:** `roblox-qa-performance` (checklist completa), `roblox-compliance` si cambió contenido o texto de jugadores, `roblox-publishing` si el update es grande (miniaturas nuevas para probar).
6. **Changelog** (`references/changelog-template.md`) en `games/<juego>/docs/changelog/AAAA-MM-DD.md` y anuncio de update (≤ 60 caracteres).
7. **Revisión** en la fecha: comparar la semana anterior con la siguiente (mismos días de la semana) y anotar si se mantiene, se ajusta o se revierte.

## Checklist
- [ ] Calendario de 4 a 8 semanas con dueño y fecha por entrega.
- [ ] Cada update con métrica objetivo y fecha de revisión.
- [ ] Contenido de cadencia sobre sistemas existentes y de menos de tres semanas de trabajo.
- [ ] Eventos con fechas reales, recompensas revisadas contra la economía y oferta auditada.
- [ ] QA (y cumplimiento si corresponde) en verde antes de publicar.
- [ ] Changelog escrito y anuncio enviado.
- [ ] Revisión hecha y anotada.

## Límites
- No inventa fechas de eventos de Roblox ni temporadas: se verifican en la fuente oficial antes de planificarlas.
- No envía notificaciones ni crea eventos en el Dashboard: lo hace una persona (o el código del juego, con el permiso del jugador).
- Un evento no reemplaza un loop flojo: si D1 es bajo, primero gameplay.
