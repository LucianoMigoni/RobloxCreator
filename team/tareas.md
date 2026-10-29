# Tablero

Formato y flujo: `team/README.md`. Detalle de cada paso del hub: `ROADMAP.md`.

## En curso

- [ ] Giro a juegos estilo hit: plantilla v2 (economía multi-moneda, boosts, diario, regalos por tiempo, misiones, ruleta, códigos, offline, renacer, índice, eventos, referidos, tienda con muchos productos), HUD y animaciones estilo hit, kits de género (robar, huevos, +1, pesca, buscar) y generadores de mapas. Hecho: investigación, recursos, conectores, vitrina y campañas; miniaturas con IA. Sigue: íconos y partículas estilo hit (no emoji), sonidos — hub · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub
- [ ] Fase A + B0 — abrir el PR de la rama (@leonel) y revisarlo/mergearlo (@luciano) — hub · @leonel @luciano · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub

## Pendiente

- [ ] Conectar Meshy en las dos máquinas: plan Pro, clave en `MESHY_API_KEY` y aprobar el servidor `meshy` de `.mcp.json` (`SETUP.md` paso 7) — hub · @luciano @leonel · rama — · juego: hub
- [ ] MCP de Blender en la máquina de Leonel (forma A o B de `SETUP.md` paso 6) y Pillow en las dos (`python -m pip install pillow`) — hub · @leonel @luciano · rama — · juego: hub
- [ ] Clave de imágenes con IA en las dos máquinas: `GEMINI_API_KEY` (Nano Banana Pro) y/o `OPENAI_API_KEY` (GPT Image 2.5), y el render de modelos (`cd tools/render3d && npm install && npx playwright install chromium`) (`SETUP.md` paso 8) — hub · @luciano @leonel · rama — · juego: hub
- [ ] Claves de Open Cloud: assets (`ROBLOX_OPEN_CLOUD_API_KEY` + `ROBLOX_CREATOR_GROUP_ID`) y, al lanzar, la de anuncios de usuario (`ROBLOX_ADS_API_KEY`) (`SETUP.md` paso 8) — hub · @luciano @leonel · rama — · juego: hub
- [ ] Primera campaña real con `roblox-campaigns` cuando un juego esté publicado: prueba de humo y miniaturas, con presupuesto aprobado — marketing · @luciano @leonel · rama — · juego: prueba
- [ ] C2: juego de prueba de punta a punta en `games/prueba/` (arranca con `roblox-ideation` usando datos reales de Charts aportados por ustedes; se lanza primero a 16+) — fase 1 hecha: `games/prueba/docs/concepto.md` propone Roba y Fusiona (86/100), estilo Steal a Brainrot / Grow a Garden con giro propio; plan B Jardín de Bichos (85); aprobado por Luciano el 2026-10-26 (*Steal & Fuse Critters*, en inglés y para público internacional); fase 2 en curso: plantilla copiada a `games/prueba/` y `docs/spec.md` escrita (13 mecánicas, plan en 6 hitos), spec aprobada por Luciano; **hitos 1 y 2 hechos y probados en Studio** (loop gris; robo, empujón, traba y protecciones con 2 jugadores); sigue el hito 3 (progresión). Falta además el visto bueno de Leonel al concepto — hub · @luciano @leonel · rama — · juego: prueba
- [ ] C1: importar `assets/3d/props/coin-gold-lowpoly-01.fbx` en Studio (3D Importer, Scale Unit: Studs), confirmar que mide 2 studs (si no, reexportarla con Scene → Units → Unit System **None**, como pide `roblox-game-cloner` paso 4; se exportó en métrico con escala 1), subirla y anotar el `robloxAssetId` en `assets/index.json` — mapa · @luciano · rama — · juego: hub
- [ ] A2: proteger `main` en GitHub (Settings → Rules; en repo privado puede pedir plan pago) — hub · @luciano · rama — · juego: hub
- [ ] A3/A4: instalar desde cero siguiendo `SETUP.md` y correr `setup.ps1` en Windows hasta "Todo listo" — hub · @leonel · rama — · juego: hub
- [ ] A7: probar que la IA del compañero (Codex, Gemini u otra) sigue `CLAUDE.md` vía `AGENTS.md` — hub · @leonel · rama — · juego: hub
- [ ] A5: probar Obsidian entre los dos (un cambio de uno le llega al otro tras el merge) — hub · @luciano @leonel · rama — · juego: hub
- [ ] B1a/B1b: probar persistencia y bloqueo de sesión (dos ventanas) y comprar un ítem con monedas, en una copia publicada de prueba con acceso a API activado. Remotes, abuso y UI ya probados el 2026-10-26 (`team/pruebas/`) — servidor · @luciano · rama — · juego: hub
- [ ] B3: crear una API key de analíticas de prueba (permiso `universe.analytics:read`) y correr `tools/analytics.py summary` contra un juego publicado — hub · @luciano · rama — · juego: hub
- [ ] Cuenta dueña de los juegos: decidir si publican desde una cuenta personal o un grupo, y que esa cuenta (o el dueño del grupo) cumpla lo que pide Roblox para llegar a menores de 16: verificación, 2FA y Plus/Premium 2 meses o la tarifa de 1000 Robux por juego (ver `skills/roblox-compliance`) — hub · @luciano @leonel · rama — · juego: hub
- [ ] C3: repasar `CLAUDE.md` con lo aprendido en C2 y cerrar `ROADMAP.md` — docs · @nadie · rama — · juego: hub

## Hecho

- [x] Miniaturas e íconos con IA y referencias del juego: `tools/imagegen.py`, `tools/render3d/`, recetas con escena para la IA, `thumbs.py --base`, ejemplos de antes y después — hub · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-29
- [x] Investigación de los hits de octubre 2026 (`skills/_shared/hits-2026.md`, `tools/roblox_research.py`) y recursos estilo hit (miles de modelos, sonidos, música, partículas, íconos y fuentes en el catálogo) — hub · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-28
- [x] Conectores evaluados y documentados para los dos (`skills/_shared/conectores.md`, `.mcp.json` de Meshy, `tools/roblox_upload.py`) — hub · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-28
- [x] Guía central `skills/_shared/como-son-nuestros-juegos.md`, vitrina estilo hit (`vitrina-hits.md`, recetas, `tools/thumbs.py`) y campañas (`roblox-campaigns`, `anuncios-2026.md`, `tools/campaigns.py`) — hub · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-29
- [x] C1: primer asset real en el catálogo (`coin-gold-lowpoly-01`, Blender MCP, 288 triángulos) — mapa · @luciano · rama luciano/fase-c · juego: hub · 2026-10-26
- [x] A4: completar el paso 6 de `SETUP.md` con el comando del MCP de Blender (extensión de Blender Lab en la app de Claude) — docs · @luciano · rama luciano/fase-c · juego: hub · 2026-10-26
- [x] UI: probar en Studio el nuevo `UIKit.sideBar` (emulador: teléfono chico horizontal y tablet), correr `UIKit.selfTest()` y `audit_ui.luau` — ui · @luciano · rama luciano/fase-c · juego: hub · 2026-10-26
- [x] B4: correr en Studio `perf_snapshot.luau` (Client y Server) sobre la plantilla y anotar la primera foto de rendimiento; elegir el teléfono base del equipo — qa · @luciano · rama luciano/fase-c · juego: hub · 2026-10-26
- [x] A1: el compañero tiene acceso de escritura al repo — hub · @luciano · rama — · juego: hub · 2026-10-24
- [x] A2: monorepo con ramas y PR en `CLAUDE.md` — docs · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-24
- [x] A3: `setup.ps1` crea el enlace de skills y verifica el entorno — hub · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-24
- [x] A4: `SETUP.md` — docs · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-24
- [x] A5: config común de Obsidian — hub · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-24
- [x] A6: carpeta `team/` (flujo, tablero, decisiones) — docs · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-24
- [x] A7: `AGENTS.md` y `GEMINI.md` remiten a `CLAUDE.md` — docs · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-24
- [x] Referencia del algoritmo de descubrimiento 2026 (`skills/_shared/algoritmo-descubrimiento.md`) — docs · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-24
- [x] B0: chequeo automático (`tools/check.py` + GitHub Actions + `rokit.toml` en la raíz) — hub · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-25
- [x] B1a: datos y seguridad (`DataService` con bloqueo de sesión, `Remotes` con validación y límite, skill `roblox-security`, tests de Luau) — servidor · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-25
- [x] B1b: economía, tienda y cliente (Currency, Inventory, Shop con ProcessReceipt, Onboarding, HUD/tienda/inventario con UIKit) — servidor · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-25
- [x] B2: skills `roblox-ideation` y `roblox-game-cloner` — hub · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-25
- [x] B3: skills `roblox-monetization` y `roblox-metrics-growth`, `tools/analytics.py` y regla contra textos de presión — hub · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-25
- [x] B4: skills `roblox-qa-performance`, `roblox-compliance`, `roblox-publishing` y `roblox-liveops`; reglas de público alcanzable (Kids/Select) en ideación, spec, algoritmo y `CLAUDE.md` — hub · @leonel · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub · 2026-10-25
