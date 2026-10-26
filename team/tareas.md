# Tablero

Formato y flujo: `team/README.md`. Detalle de cada paso del hub: `ROADMAP.md`.

## En curso

- [ ] C1: primer asset real en el catálogo — mapa · @luciano · rama luciano/fase-c · juego: hub
- [ ] C2: juego de prueba de punta a punta en `games/prueba/` (arranca con `roblox-ideation` usando datos reales de Charts aportados por ustedes; se lanza primero a 16+) — fase 1 (ideación) en curso — hub · @luciano @leonel · rama luciano/fase-c · juego: prueba
- [ ] Fase A + B0 — abrir el PR de la rama (@leonel) y revisarlo/mergearlo (@luciano) — hub · @leonel @luciano · rama leonelblumberg/quirky-dijkstra-2kxnwz · juego: hub

## Pendiente

- [ ] A2: proteger `main` en GitHub (Settings → Rules; en repo privado puede pedir plan pago) — hub · @luciano · rama — · juego: hub
- [ ] A4: completar el paso 6 de `SETUP.md` con el comando del MCP de Blender (`claude mcp get Blender`) — docs · @luciano · rama — · juego: hub
- [ ] A3/A4: instalar desde cero siguiendo `SETUP.md` y correr `setup.ps1` en Windows hasta "Todo listo" — hub · @leonel · rama — · juego: hub
- [ ] A7: probar que la IA del compañero (Codex, Gemini u otra) sigue `CLAUDE.md` vía `AGENTS.md` — hub · @leonel · rama — · juego: hub
- [ ] A5: probar Obsidian entre los dos (un cambio de uno le llega al otro tras el merge) — hub · @luciano @leonel · rama — · juego: hub
- [ ] B1a/B1b: probar la plantilla en Studio con una copia publicada de prueba (acceso a API activado): persistencia, bloqueo con dos ventanas, comprar un ítem con monedas, `audit_remotes.luau`, `abuse_test.luau` y `audit_ui.luau` sobre el HUD y los popups (teléfono chico y tablet) — servidor · @luciano · rama — · juego: hub
- [ ] B3: crear una API key de analíticas de prueba (permiso `universe.analytics:read`) y correr `tools/analytics.py summary` contra un juego publicado — hub · @luciano · rama — · juego: hub
- [ ] Cuenta dueña de los juegos: decidir si publican desde una cuenta personal o un grupo, y que esa cuenta (o el dueño del grupo) cumpla lo que pide Roblox para llegar a menores de 16: verificación, 2FA y Plus/Premium 2 meses o la tarifa de 1000 Robux por juego (ver `skills/roblox-compliance`) — hub · @luciano @leonel · rama — · juego: hub
- [ ] C3: repasar `CLAUDE.md` con lo aprendido en C2 y cerrar `ROADMAP.md` — docs · @nadie · rama — · juego: hub

## Hecho

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
