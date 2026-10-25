---
name: roblox-metrics-growth
description: Mide y hace crecer un juego de Roblox con las señales que usa el algoritmo de Home (PTR, bounce, play days, playtime, co-play, gasto en D1/D2–7/D8–28), la retención D1/D7/D30 y los embudos y eventos de economía de la plantilla, con la API oficial Open Cloud Analytics (tools/analytics.py) y el Creator Dashboard. Usar en la fase 9 del pipeline, en modo mejora antes de lanzar o en modo análisis con el juego publicado.
---

# roblox-metrics-growth

## Objetivo
Saber con datos dónde se van los jugadores y qué cambiar, un cambio a la vez. Sale `games/<juego>/docs/metricas.md`.

## Cuándo usarlo
- **Modo mejora** (antes de lanzar o en un juego existente sin datos): instrumentar y fijar objetivos.
- **Modo análisis** (juego publicado): datos, diagnóstico, acciones y revisión en una fecha.

**Lo llaman:** el usuario, `roblox-liveops` (cada ciclo), `roblox-publishing` (después del lanzamiento).
**Llama a:** el skill que corresponda según `references/diagnostico.md`.

## Fuentes de datos
| Fuente | Qué trae | Cómo |
|---|---|---|
| Creator Analytics → **Acquisition → Home Recommendations** | Señales del algoritmo: PTR, bounce < 60 s y 61–180 s, play days, playtime, co-play, qualified sessions, spend days, Robux por usuario (D1, D2–7, D8–28) y benchmark | Dashboard (captura o export); no están en la API |
| **Open Cloud Analytics** | Retención D1/D7/D30, playtime, sesiones, usuarios activos, ingresos, usuarios que pagan, embudos | `python tools/analytics.py summary --universe <id>` con `ROBLOX_ANALYTICS_API_KEY` (permiso `universe.analytics:read`; nunca en el repo) |
| Embudo de onboarding de la plantilla | Dónde se cortan los primeros minutos | `OnboardingService` (`LogOnboardingFunnelStepEvent`) → panel de embudos de Creator Analytics |
| Eventos de economía de la plantilla | Fuentes y sumideros de monedas | `CurrencyService` (`LogEconomyEvent`) → panel de economía de Creator Analytics |

Cada número en `metricas.md` lleva fuente y fecha. Nada se inventa ni se extrapola sin decirlo.

## Flujo

**Modo mejora**
1. Verificar que el embudo de onboarding refleje los primeros minutos reales del juego (`Config/OnboardingConfig.luau`): un paso por hito del primer minuto.
2. Verificar que cada fuente y sumidero de monedas pase por `CurrencyService` con el tipo de transacción correcto, para que la economía se vea completa.
3. Eventos propios solo si responden una pregunta concreta (`AnalyticsService:LogCustomEvent`). La API tiene un límite de eventos por minuto: registrar transacciones, no cada acción menor.
4. Fijar objetivos iniciales por señal, comparando con el benchmark del panel cuando haya datos. Sin datos todavía: "medir la primera semana" y no un número inventado.

**Modo análisis**
1. **Datos:** `tools/analytics.py summary` (28 días) y capturas de Home Recommendations y de los embudos.
2. **Contexto:** estacionalidad, updates recientes, ads (los jugadores traídos por ads no cuentan para Home) y fase de exploración (`references/diagnostico.md`).
3. **Diagnóstico:** primero las señales más importantes (PTR, bounce, play days, playtime); si están estables, co-play, qualified sessions, spend days y Robux. Ubicar el síntoma en la tabla de `references/diagnostico.md`.
4. **Acciones:** como mucho tres, cada una con la métrica que debería moverse, cuánto y la fecha de revisión (una o dos semanas, comparando los mismos días de la semana).
5. **Escribir `docs/metricas.md`** (datos con fuente, diagnóstico, acciones) y mostrarlo. En la revisión, anotar qué pasó y si se mantiene el cambio.

## Checklist
- [ ] Cada número tiene fuente y fecha; la API key no aparece en ningún archivo.
- [ ] Embudo de onboarding y eventos de economía cubren el juego real.
- [ ] Diagnóstico empezando por las señales más importantes, con estacionalidad y exploración en cuenta.
- [ ] Como mucho tres acciones, con métrica objetivo y fecha de revisión.
- [ ] `docs/metricas.md` actualizado y revisado por el usuario.

## Límites
- No garantiza crecimiento: el algoritmo también depende de la competencia y de la temporada.
- `tools/analytics.py` usa solo la API oficial; nada de scraping ni de herramientas de terceros.
- No cambia el juego: deriva al skill que corresponde.
