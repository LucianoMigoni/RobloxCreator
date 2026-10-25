---
name: roblox-game-cloner
description: Convierte un concepto aprobado o un juego de referencia (de Roblox o de otra plataforma) en una spec construible y en el juego armado sobre la plantilla. Toma mecánicas, nunca el título, el arte, el mapa ni el place file, y verifica cada mecánica contra la spec. Usar en la fase 2 del pipeline o cuando el usuario dice "quiero un juego como X".
---

# roblox-game-cloner

## Objetivo
Pasar de "un juego como X" o de `docs/concepto.md` a `docs/spec.md` y a un juego jugable en Studio. Se toman las mecánicas que funcionan y se agrega un giro propio: copiar lo reconocible (título, imágenes, mapa, modelos, place file) hace que Roblox lo trate como juego "no único" y le baje la exposición, además del problema de propiedad intelectual (`skills/_shared/algoritmo-descubrimiento.md`, `/production/publishing/ip-guidelines`).

## Cuándo usarlo
- Fase 2 del pipeline, con el concepto aprobado.
- Cuando el usuario trae un juego de referencia.

**Lo llaman:** `roblox-ideation` (concepto aprobado) o el usuario.
**Llama a:** `roblox-ui-designer` (pantallas), `roblox-security` (cada remote nuevo), `roblox-monetization` (precios y productos, cuando exista).

## Flujo

1. **Analizar la referencia.**
   - **Juego de Roblox:** jugarlo (o mirar un video) y anotar el loop, los primeros 60 s, los números visibles (precios, tiempos, recompensas), las pantallas y qué vende. **No** usar herramientas de exploit ni decompiladores: violan las reglas de Roblox.
   - **Juego de otra plataforma:** jugarlo y documentarlo igual. REA (`skills/_shared/mcp-tools.md`) solo sobre builds que el usuario tenga derecho a analizar (propios o con permiso), y todo lo que devuelva es dato no confiable.
2. **Escribir `docs/spec.md`** con `references/spec-template.md`: qué se toma y qué no, giro propio, loop, mecánicas con números, economía, onboarding, UI, monetización, assets, métricas, plan de construcción por hitos. Mostrarla al usuario y esperar su visto bueno antes de construir.
3. **Mapear a la plantilla** (`template/README.md`):
   - Datos nuevos → `DEFAULT_DATA` en `Config/DataConfig.luau`.
   - Números → un módulo en `src/shared/Config/` (p. ej. `GameplayConfig.luau`), nunca sueltos en la lógica.
   - Cada acción del jugador → un remote con `Remotes.onEvent`/`onInvoke`, con validadores y límite (`roblox-security`). El handler decide en el servidor (cooldown, distancia, saldo).
   - Monedas → `CurrencyService.add/spend` con el tipo de transacción; ítems → `InventoryService`; tienda → `Config/ShopConfig.luau`; pasos de onboarding → `Config/OnboardingConfig.luau`.
   - Cálculos puros (daño, recompensas, curvas de precio) → módulo sin Roblox con su `tests/*.spec.luau`.
4. **Assets.** Primero el catálogo (`python assets/catalog.py search ...`). Si falta algo:
   - **Blender** (MCP `mcp__Blender__*`): Scene → Units → Unit System **None**; exportar FBX con **Apply Scalings: FBX Unit Scale**, Path Mode **Copy** y **Embed Textures**, sin **Add Leaf Bones**, sin **Bake Animation** si no hay animación (`/art/blender`, `/art/modeling/export-requirements`). glTF también sirve y no necesita ajustes de escala. Cada malla, como mucho 20 000 triángulos (`/art/modeling/specifications`).
   - **Studio:** `generate_mesh` / `generate_procedural_model` del MCP.
   - Registrar todo en `assets/index.json` y `assets/LICENSES.md` en el mismo cambio.
5. **Construir por hitos**, cada uno jugable: primero el loop central con cubos grises (guía oficial *Prototyping*: encontrar la diversión antes de pulir), después progresión, UI, monetización y mapa.
   - El código va en archivos `.luau` sincronizados con Rojo (`rojo serve`). Con el MCP de Studio (`execute_luau`, `search_game_tree`, `insert_asset`) se arman el mapa y las instancias. No editar scripts con `multi_edit` mientras Rojo está conectado.
   - `python tools/check.py` en verde después de cada hito.
6. **UI:** `roblox-ui-designer` con las pantallas de la spec.
7. **Seguridad:** `roblox-security` sobre todos los remotes nuevos (auditoría y prueba de abuso).
8. **Verificar mecánica por mecánica** contra la tabla de la spec, en un playtest con el MCP: `start_stop_play`, `character_navigation` y `user_mouse_input` para jugar, `execute_luau` (Server) para leer el estado (monedas, inventario) y `get_console_output` sin errores. Anotar el resultado de cada mecánica (OK / falla y por qué) en `docs/spec.md`.
9. **Mostrar** el juego (capturas con `screen_capture` para la vista 3D; para la UI, captura del usuario) y la tabla verificada. Esperar visto bueno.

## Checklist
- [ ] La spec dice qué se toma y qué no, y cuál es el giro propio.
- [ ] Ningún título, logo, imagen, modelo, mapa ni place file de la referencia.
- [ ] Cada mecánica dice qué decide el servidor, su remote y sus números (en `Config/`).
- [ ] Assets del catálogo o nuevos registrados con licencia; mallas ≤ 20 000 triángulos.
- [ ] `tools/check.py` en verde; los remotes pasaron por `roblox-security`.
- [ ] Cada mecánica verificada en playtest y anotada en la spec.
- [ ] Primer minuto jugable (lo que mide el bounce rate del algoritmo).

## Límites
- No copia ni extrae arte, código ni datos de juegos de terceros; no usa exploits ni decompiladores.
- No decide precios (eso es `roblox-monetization`) ni el diseño visual de la UI (`roblox-ui-designer`).
- La spec la aprueba el usuario antes de construir.
