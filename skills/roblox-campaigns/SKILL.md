---
name: roblox-campaigns
description: Crea y lleva las campañas para publicitar un juego de Roblox estilo hit. Cubre el plan por etapas con presupuesto y fechas (prueba de humo, miniaturas, Kids y Select, empuje, update, inactivos, earnings), las creatividades con el kit de miniaturas, las campañas de Ads Manager (por API o a mano), el premio de bienvenida por LaunchData, share links y clips para redes, y el análisis diario con reglas para cortar o escalar. Usar al lanzar un juego, en cada update grande y cuando haya que traer, recuperar o monetizar jugadores con publicidad.
---

# roblox-campaigns

## Objetivo
Que cada dólar de publicidad traiga jugadores que retienen y gastan, y que el juego entre en Home lo antes posible. Sale:
- `games/<juego>/docs/campanas/<fecha>-<nombre>.md`: el plan que se aprueba en el PR, más su `.json` para la API.
- Las creatividades en `games/<juego>/marketing/ads/`.
- El seguimiento diario dentro del mismo plan.

Base: `skills/_shared/anuncios-2026.md` (cómo funciona Ads Manager hoy, costos reales, APIs y fuentes) y `skills/_shared/vitrina-hits.md` (imágenes que hacen clic). Reglas del hub: `skills/_shared/como-son-nuestros-juegos.md`.

## Cuándo usarlo
- Al lanzar: después de `roblox-publishing` (vitrina lista, juego público).
- En cada update grande, con `roblox-liveops`: campaña de update y evento.
- Cuando `roblox-metrics-growth` ve buena retención y poca gente: falta tráfico, no juego.
- Para recuperar inactivos (con 20 000 o más) o escalar ganancias (objetivo Earnings, si Roblox lo habilitó).

**Lo llaman:** el usuario, `roblox-publishing`, `roblox-liveops` y `roblox-metrics-growth`.
**Llama a:**
- `roblox-publishing` / `vitrina-hits.md`: miniaturas y video.
- `roblox-metrics-growth`: D1 y D7 por fuente.
- `roblox-monetization`: la oferta de bienvenida no rompe reglas.
- `roblox-compliance`: publicidad y edades.

## Reglas que no se negocian
- **Gastar lo aprueba una persona.** `tools/campaigns.py create` y `set` simulan si no se agrega `--yes`. Nunca se corre `--yes` sin el visto bueno explícito del usuario en esta conversación, con el monto total a la vista.
- **El anuncio amplifica, no arregla.** Sin primer minuto sano (rebote en 60 s bajo) y D1 razonable no se pasa de la prueba de humo.
- **Todo lo que muestra el anuncio existe en el juego.** Capturas y renders reales, sin arte con cara de IA, sin "free Robux" ni ofertas en la imagen.
- **Clones no:** Ads Manager no entrega juegos "no únicos" (sin gasto ni conversiones).
- **Edades:**
  - A menores de 13 no se les ofrecen formatos con recompensa.
  - Los links a redes solo los ve el público de 16+.
  - Prohibido premiar likes, favoritos o suscripciones externas.
  - Un creador de contenido pago avisa que es publicidad.
- **Bots o tráfico falso:** suspensión de la cuenta. No se compra tráfico fuera de Roblox que entre al juego de forma automática.

## Flujo
1. **Diagnóstico** (`roblox-metrics-growth`):
   - ¿Cómo están el PTR de Home, el rebote en 60 s, D1 y D7?
   - ¿El juego llega a menores de 16? (Creator Hub → Audience Reach.)
   - ¿Ya tiene vitrina con 2 a 5 miniaturas activas y video?
   - Si falta algo de esto, se arregla antes de gastar.
2. **Plan:**
   ```
   python tools/campaigns.py plan --game games/<juego> --goal launch --budget <USD> --universe <id> [--kids-pending]
   ```
   - Objetivos: `launch`, `update`, `lapsed` o `earnings`.
   - Genera etapas con fechas (cada empuje arranca un jueves), presupuesto por etapa, 10 espacios de creatividades con su hipótesis, LaunchData y reglas de corte.
   - Revisarlo con el usuario: presupuesto total, países, dispositivos y si conviene la revisión rápida de Kids y Select (100 000 Robux devolvibles) en vez de la etapa `kids`.
3. **Creatividades:**
   - Una por espacio: imagen con IA y referencias del juego (`tools/imagegen.py`, recetas de `skills/_shared/vitrina/recetas/`) y textos con `tools/thumbs.py compose --base` (`skills/_shared/vitrina-hits.md` §6).
   - `tools/thumbs.py check` sin avisos de tamaño. Hoja de contacto en el PR.
   - Subirlas a la biblioteca de Ads Manager (o con `tools/roblox_upload.py`) y anotar cada assetId en el `.json` (`creativeAssetIds`).
4. **El juego listo para recibir:**
   - Premio de bienvenida por LaunchData en `Config/CampaignConfig.luau` (`references/campanas.md`), mostrado al entrar ("Welcome gift!").
   - Share links por canal externo.
   - Evento con "Notify Me" para el fin de semana del empuje.
5. **Crear:**
   - Por API: `python tools/campaigns.py create <plan.json>` simula; con el visto bueno del usuario, `--yes`. Clave de usuario en `ROBLOX_ADS_API_KEY`.
   - A mano en Ads Manager si el objetivo no es el de la API v1, que solo crea `ENGAGEMENT`, o si la API cambió. Anotar en el `.json` el id de cada campaña.
6. **Seguimiento diario** (después de las primeras 48 h):
   - Exportar el reporte de Ads Manager a CSV y correr `python tools/campaigns.py report <csv>`.
   - Aplicar las reglas de corte: apagar miniaturas con CTR bajo, reemplazarlas con variantes de la ganadora y no pausar la campaña entera, porque reinicia el aprendizaje.
   - Anotar cada decisión en la tabla de seguimiento del plan.
7. **Cerrar la etapa:**
   - Comparar contra el "pasa si…" de la etapa.
   - D1 y D7 de los que llegan por anuncio contra los orgánicos: Creator Analytics → Acquisition, o `tools/analytics.py`.
   - Decidir con el usuario si se pasa a la siguiente, se repite con otras creatividades o se vuelve a arreglar el juego.
8. **Fuera de Roblox** (en paralelo, `references/campanas.md` §3): clips verticales del loop, share link por canal y creadores chicos con código propio.
9. **Aprendizajes:**
   - Qué miniatura ganó y por qué, CPP, CTR y D7 por etapa, en `games/<juego>/docs/decisiones.md`.
   - Si sirve para otros juegos, también en `skills/_shared/anuncios-2026.md` con la fecha.

## Checklist
- [ ] Vitrina lista: ícono, 3 a 5 miniaturas activas, video y descripción (`vitrina-hits.md`).
- [ ] Rebote en 60 s y D1 revisados antes de gastar más que la prueba de humo.
- [ ] Plan generado y aprobado en el PR, con presupuesto total y fechas.
- [ ] Creatividades reales, 16:9, con hipótesis distintas y assetIds anotados.
- [ ] Premio de bienvenida por LaunchData funcionando (probado con la URL de prueba de Ads Manager).
- [ ] Ninguna campaña creada con `--yes` sin el visto bueno del usuario.
- [ ] Seguimiento diario anotado; reglas de corte aplicadas; aprendizajes guardados.

## Límites
- **No paga solo:** el pago y las cuentas los maneja una persona (la Ads API usa un medio de pago ya cargado en Ads Manager).
- **No promete jugadores:** los rangos de costo son de la comunidad y cambian con la subasta; se miden en la prueba de humo.
- **La Ads API es experimental:** si una llamada falla por formato, verificar en https://create.roblox.com/docs/cloud/guides/advertising y actualizar `tools/campaigns.py`.
- **Sin datos inventados:** CTR, CPP y ROAS se leen del reporte; las métricas de retención, de Creator Analytics.
