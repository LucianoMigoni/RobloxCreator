---
name: roblox-ui-designer
description: Diseña y construye la interfaz de un juego de Roblox al estilo de los juegos grandes (botones redondeados con borde grueso y gradiente, texto con contorno, colores con significado fijo, animaciones con TweenService), con prioridad móvil. Usar cuando haya que crear o rehacer HUD, tienda, inventario, popups, ofertas, onboarding u otra pantalla de UI, o auditar una UI existente (Scale vs Offset, zona segura, tamaño para dedo).
---

# roblox-ui-designer

## Objetivo
UI legible, táctil y con estilo de juego grande, construida con el kit `UIKit` (`template/src/shared/UIKit.luau`, que cada juego trae al copiar la plantilla), sin copiar iconos, logos ni pantallas de juegos existentes.

## Cuándo usarlo
- Fase 3 del pipeline, o cuando otro skill necesite UI nueva (lista abajo).
- Para auditar una UI existente antes de QA o publicación.

**Lo llaman:** `roblox-game-cloner` (paso 7: UI del juego), `roblox-monetization` (tienda, pack de inicio, popups de oferta, pase de temporada), `roblox-metrics-growth` (onboarding de los primeros 60 s, recompensas diarias), `roblox-liveops` (UI de eventos).

**Llama a:**
- `roblox-security`: cada vez que un botón dispare un RemoteEvent (comprar, equipar, reclamar). La UI solo pide; el servidor valida.
- `roblox-monetization`: para precios, textos de ofertas y orden de productos en la tienda. Este skill no decide precios.
- `roblox-qa-performance`: al final, prueba en móvil de gama baja.

## Flujo

1. **Preguntar por assets de UI.** Antes de diseñar, preguntar al usuario si tiene iconos, botones, fuentes o paleta propios.
   - Sí → registrarlos en `assets/ui/` + `assets/index.json` + `assets/LICENSES.md` (`python assets/catalog.py validate`). Subirlos a Roblox (Asset Manager de Studio, o `upload_image` del MCP sirviendo `assets/ui` con `python -m http.server` y pasando las URLs `http://localhost:8000/...`) y anotar `robloxAssetId`. Su paleta reemplaza a `UIKit.Colors`; su fuente, a `UIKit.Font` si existe en Roblox.
   - No → buscar en el catálogo: `python assets/catalog.py search --type icon --commercial`. Si no hay, usar componentes nativos del kit (texto + color) y anotar qué iconos faltan.
2. **Listar pantallas** a partir de `games/<juego>/docs/spec.md`: HUD (monedas arriba, botones laterales), popups (tienda, inventario, ajustes, ofertas), notificaciones. Escribir el inventario en `docs/ui.md` (pantalla, propósito, botones, RemoteEvent que dispara cada botón).
3. **Aplicar el estilo de los hits** según `references/hud-hits.md` (lo que tienen en común los hits actuales, medidas, tienda, índice, íconos, y las muestras `hud-hits/muestra-kit.jpg` para PC y `hud-hits/muestra-telefono.jpg` para teléfono) y `references/style-guide.md` (colores con significado fijo, fuente gruesa, contorno de texto, animaciones).
4. **Construir en código** (preferido, versionado con Rojo): `UIKit` ya está en `src/shared/UIKit.luau` del juego (viene de la plantilla, que es la fuente única: los cambios al kit se hacen ahí). Crear un controlador por pantalla en `src/client/Controllers/` (como `ShopController.luau` o `IndexController.luau` de la plantilla), arrancado desde `Main.client.luau`. Piezas del kit:
   - HUD: lo arma `HudController` (`hud.addButton`, `addTopbarButton`, `addOffer`, `addCorner`, `setObjective`); en táctil cambia solo de distribución.
   - Ventanas: `UIKit.window` (cabecera de color, ícono que se sale, X roja), `open/close/toggle`.
   - Contenido: `button`, `priceButton` (precio con el ícono de Robux), `giftButton`, `card`, `ribbon`, `tabs`, `progressBar`, `viewport` (modelo 3D, silueta), `sunburst`, `offer`.
   - Listas: `list`, `section`, `row`, `grid`. El alto de filas y tarjetas sale de `fitHeight`/`fitCells`.
   - En el mundo: `src/client/UI/World.luau` (`sign`, `tag`, `path`; etiqueta `HitSign` en Studio).
   - Construir en Studio con el MCP (`execute_luau` en datamodel Edit sobre `StarterGui`) solo para prototipos rápidos; si se conserva, pasarlo a código.
5. **Conectar con el servidor:** cada botón de acción llama a un RemoteEvent de `ReplicatedStorage.Remotes`; la UI se actualiza con lo que el servidor confirma (nunca restar monedas en el cliente). Llamar a `roblox-security` para revisar esos remotes.
6. **Probar** con el MCP de Studio (nombres exactos en `skills/_shared/mcp-tools.md`; probado el 2026-10-26):
   1. `list_roblox_studios` → `start_stop_play` (sin simulador) → `user_mouse_input` con `instance_path` para abrir el popup a probar → `get_console_output` sin errores.
   2. Con el playtest y el popup abiertos, cambiar de dispositivo con `execute_luau` (datamodel **Client**): `StudioDeviceSimulatorService:SetDeviceAsync(id)`, esperar 0.3 s, y **después** `SetOrientationAsync(Enum.ScreenOrientation.LandscapeLeft)` (antes de elegir dispositivo da error). Los ids salen de `GetDeviceListAsync()`; guía completa: tool `skill` con `rbx-device-simulator-lua`.
   3. Por cada dispositivo: `screen_capture` (en playtest **sí** muestra la UI) y las posiciones reales con `AbsolutePosition`/`AbsoluteSize` desde `execute_luau` Client. Mínimo: el teléfono base del equipo (Samsung Galaxy A06), un iPhone con notch y una tablet.
   4. Al terminar: detener el playtest y `StopSimulationAsync()` en datamodel Edit.
   - Con el simulador de teléfono activo, `user_mouse_input` **no dispara** `Activated` en los botones: abrir los popups antes de activar el simulador.
7. **Auditar** con `scripts/audit_ui.luau` vía `execute_luau` (Edit sobre `StarterGui`, o Client sobre `PlayerGui` en playtest). Corregir todo lo marcado ERROR.
8. **Mostrar al usuario** capturas + `docs/ui.md` y esperar revisión.

## Reglas técnicas obligatorias
Detalle y fuentes en `references/technical-rules.md`.
- Tamaños y posiciones en **Scale**, no Offset. Excepciones: `UISizeConstraint.MinSize` como piso táctil del HUD, la barra de Roblox (`TopbarSafeInsets`, alto fijo), los carteles del mundo y el alto de filas en listas con scroll (`UIKit.fitHeight`, que marca el atributo `FitHeight`).
- `UIAspectRatioConstraint` en todo botón, icono y popup que deba conservar forma, **nunca** con un eje en 0 (la documentación no dice qué hace): en listas con scroll, `UIKit.fitHeight`, `UIKit.row` o `UIKit.grid`.
- `ScreenGui.ScreenInsets = CoreUISafeInsets` en toda pantalla con elementos interactivos (evita notch y barra superior de Roblox).
- Botones táctiles: mínimo 44×44 px efectivos, medidos con `audit_ui.luau`, separados entre sí. En el HUD con `UISizeConstraint.MinSize`; dentro de ventanas **por diseño** (menos columnas en `UIKit.isSmallScreen()`, filas con alto mínimo, ventanas casi a pantalla completa en el teléfono): un `MinSize` adentro de una fila encima cosas.
- Con pantalla táctil, nada interactivo ni importante en la zona del joystick (≈ 41 % izquierdo, desde el 43 % del alto hacia abajo) ni en la del salto (abajo a la derecha): ver `references/technical-rules.md`.
- Texto con `TextScaled` + `UITextSizeConstraint` (MinTextSize ≥ 9).
- Animar con `UIScale` (no `Size`) para no romper el layout; nunca tweenear `Thickness` de un `UIStroke` sobre texto.

## Checklist final
- [ ] Se preguntó al usuario por sus assets de UI y se usaron si los dio.
- [ ] Todo asset usado está en `assets/index.json` con licencia; ninguno copiado de otro juego.
- [ ] `audit_ui.luau` sin ERROR.
- [ ] Verde = comprar/aceptar, rojo = cerrar, dorado = premium, en todas las pantallas.
- [ ] HUD como los hits (`references/hud-hits.md`): en PC, menú a la izquierda y plata enorme abajo a la izquierda; en táctil, menú en grilla arriba a la izquierda y plata arriba a la derecha. Ningún botón bajo el notch, la barra de Roblox ni en las zonas del joystick y del salto.
- [ ] Probado en teléfono chico horizontal y tablet: todo legible, nada se superpone, todo tocable con el pulgar (`audit_ui.luau` sin ERROR con cada ventana abierta).
- [ ] Popups abren escalando desde el centro, tienen botón cerrar rojo y se cierra uno al abrir otro.
- [ ] Ningún botón modifica monedas/inventario en el cliente; los remotes pasaron por `roblox-security`.
- [ ] `docs/ui.md` actualizado.

## Límites
- No decide precios ni ofertas (→ `roblox-monetization`), ni lógica de servidor (→ `roblox-security` y plantilla).
- Toma el estilo, nunca copia iconos, logos, mascotas ni layouts exactos de juegos existentes.
- No sube fuentes ni imágenes sin que el usuario confirme que tiene derechos sobre ellas.
- UI 3D (`BillboardGui`, `SurfaceGui`) sigue la paleta y fuentes, pero las reglas de zona segura no aplican.
