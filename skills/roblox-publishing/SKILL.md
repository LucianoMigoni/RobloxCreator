---
name: roblox-publishing
description: Prepara y ejecuta la publicación de un juego de Roblox (nombre, descripción, género, icono, miniaturas y video que cumplen las reglas oficiales, personalización de miniaturas, requisitos de lanzamiento por público y plan de lanzamiento con fechas). Usar en la fase 8 del pipeline y en cada update grande que cambie la vitrina del juego.
---

# roblox-publishing

## Objetivo
Que la vitrina del juego (icono, miniaturas, nombre, descripción) haga que juegue quien la ve y muestre exactamente lo que hay adentro, y que el lanzamiento tenga un plan con fechas. La métrica de la vitrina es el **play through rate** (PTR) de Home, y una vitrina que promete algo que no está produce rebote, que también castiga (`skills/_shared/algoritmo-descubrimiento.md`). Sale `games/<juego>/docs/lanzamiento.md` con el icono y las miniaturas.

## Cuándo usarlo
- Fase 8 del pipeline, con QA, cumplimiento y la auditoría de monetización en verde.
- En cada update grande: miniaturas nuevas para probar y anuncio del update (`roblox-liveops`).
- Cuando `roblox-metrics-growth` ve PTR bajo con bounce normal (la vitrina no convence).

**Lo llaman:** el usuario, `roblox-liveops` (updates grandes), `roblox-metrics-growth` (PTR bajo).
**Llama a:** `roblox-qa-performance`, `roblox-compliance` y `roblox-monetization` (deben estar al día antes de publicar), `roblox-metrics-growth` (después del lanzamiento).

## Base oficial
Verificado el 2026-10-25 en `/production/publishing/publish-games-and-places`, `/thumbnails`, `/experience-icons`, `/experience-genres`, `/kids-and-select` y `/discovery` (repo `Roblox/creator-docs`, commit `4e795e6`). Detalle y plantilla en `references/metadata.md`.

- **Un juego publicado es privado** (dueño, editores y miembros del grupo con permiso) hasta que se lanza. Antes se pueden invitar hasta **10 testers** de edad parecida (**File → Invite early testers**).
- **Lanzar** (File → Publish → Continue) pide la primera pregunta del cuestionario de madurez: un juego nuevo sale **solo para 16+** salvo que se complete el cuestionario y pase la evaluación para menores de 16 (`roblox-compliance`). Los requisitos se vuelven a aplicar en cada update, en cada **Publish As** y al cambiar el público. Máximo 5 juegos nuevos lanzados por día.
- **Thumbnail propio obligatorio** para tener impresiones de Home (desde el 2026-10-20). Metadata que promete Robux o recompensas, o que no coincide con el juego, reduce la exposición; también un juego "no único".
- **Icono:** cuadrado, al menos 512×512; se ve también a 150×150, así que tiene que leerse chico. Pasa moderación.
- **Miniaturas:** hasta 10 imágenes o videos; 16:9, ideal 1920×1080; nada esencial abajo (lo tapa el contador de jugadores). Videos: auténticos, cupo de 3 subidas por mes (los rechazados cuentan), sin voz, narración ni música con letra, sin imágenes reales, sin textos de oferta o promesas ("50% off", "Free UGC!"); no se ven en consolas ni VR.
- **Personalización de miniaturas:** con 2 a 5 miniaturas activas en la pestaña **Home Page**, Roblox muestra a cada grupo de jugadores la que mejor le funciona. Mantener varias activas, probar nuevas con cada update grande y no tocarlas hasta el siguiente.
- **Nombre:** estable (renombrar seguido hace que no lo encuentren), sin repetir palabras, uno o dos emojis como mucho.
- **Descripción:** la primera oración resume el juego; palabras clave relevantes, sin listas de palabras sueltas (repetir o agregar palabras irrelevantes baja el juego).
- **Género y subgénero:** se cambian una vez cada 3 meses; elegirlos solo cuando el juego está claro. Roblox puede corregirlos.

## Flujo
1. **Puerta:** `docs/qa.md`, `docs/cumplimiento.md` y `docs/monetizacion.md` al día y sin bloqueantes. Si falta algo, volver al skill dueño.
2. **Metadata** con `references/metadata.md`: nombre, descripción (primera oración y palabras clave), género y subgénero, y todo contra la spec (lo que se promete existe en el juego).
3. **Icono:** propuesta, revisada a 512 y a 150 px. Assets del catálogo con `commercialUse: true` o generados y registrados (`CLAUDE.md`, catálogo).
4. **Miniaturas:** de 3 a 5, cada una con una hipótesis distinta (la mecánica, el mundo, los amigos jugando, la progresión). Capturas reales del juego con la cámara libre de Studio (Shift + P en playtest solo). Video de gameplay si se puede grabar uno auténtico.
5. **Plan de lanzamiento** con fechas en `docs/lanzamiento.md`: testers, lanzamiento a 16+, evaluación para menores de 16 si el público lo pide, promoción y primeras revisiones de métricas (`references/metadata.md`).
6. **Publicar** (persona): subir icono y miniaturas, activar la personalización, lanzar. Anotar la fecha, la versión y el `UniverseId`.
7. **Después:** `roblox-metrics-growth` a D1, D7 y D28, y la tabla **Thumbnail Performance** de la pestaña Home Page para ver qué miniatura gana en cada grupo.

## Checklist
- [ ] QA, cumplimiento y monetización sin bloqueantes.
- [ ] Icono cuadrado ≥ 512×512, legible a 150×150.
- [ ] Miniaturas propias 16:9 (ideal 1920×1080), sin nada esencial abajo; 2 a 5 activas para personalización.
- [ ] Video, si hay, auténtico y sin voz, música con letra ni textos de oferta.
- [ ] Nombre estable y sin spam; descripción que resume el juego en la primera oración; nada que prometa Robux ni algo que no está.
- [ ] Género y subgénero correctos (no se cambian por 3 meses).
- [ ] Plan de lanzamiento con fechas y revisiones de métricas en `docs/lanzamiento.md`.

## Límites
- No publica solo: lanzar, pagar tarifas y subir imágenes lo hace una persona con la cuenta dueña.
- No compra ads ni promete jugadores: el plan dice qué se prueba y cómo se mide.
- No inventa datos de PTR o CTR: se leen de Creator Analytics después del lanzamiento.
