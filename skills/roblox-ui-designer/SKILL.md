---
name: roblox-ui-designer
description: Diseña y construye la interfaz de un juego de Roblox al estilo de los juegos grandes (botones redondeados con borde grueso y gradiente, texto con contorno, colores con significado fijo, animaciones con TweenService), con prioridad móvil. Usar cuando haya que crear o rehacer HUD, tienda, inventario, popups, ofertas, onboarding u otra pantalla de UI, o auditar una UI existente (Scale vs Offset, zona segura, tamaño para dedo).
---

# roblox-ui-designer

## Objetivo
UI legible, táctil y con estilo de juego grande, construida con el kit `scripts/UIKit.luau`, sin copiar iconos, logos ni pantallas de juegos existentes.

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
3. **Aplicar el estilo** según `references/style-guide.md`: colores con significado fijo, fuente gruesa, contorno de texto, botones grandes, animaciones de rebote y escala.
4. **Construir en código** (preferido, versionado con Rojo): copiar `scripts/UIKit.luau` a `src/shared/UIKit.luau` del juego y crear un controlador por pantalla en `src/client/` (`ShopController.client.luau`, etc.) que use `UIKit.screen`, `UIKit.sideBar`, `UIKit.currencyBar`, `UIKit.button`, `UIKit.popup`, `UIKit.open/close`.
   - Construir en Studio con el MCP (`execute_luau` en datamodel Edit sobre `StarterGui`) solo para prototipos rápidos; si se conserva, pasarlo a código.
5. **Conectar con el servidor:** cada botón de acción llama a un RemoteEvent de `ReplicatedStorage.Remotes`; la UI se actualiza con lo que el servidor confirma (nunca restar monedas en el cliente). Llamar a `roblox-security` para revisar esos remotes.
6. **Probar** con el MCP de Studio (nombres exactos en `skills/_shared/mcp-tools.md`): `list_roblox_studios` → `start_stop_play` → `user_mouse_input` para abrir/cerrar popups → `get_console_output` sin errores. `screen_capture` solo captura la vista 3D, **no la UI 2D**: para revisar la UI visualmente, pedir al usuario una captura del playtest (o usar computer-use sobre la ventana de Studio). Revisar en el emulador de dispositivos de Studio un teléfono chico en horizontal y una tablet (la tool `skill` del MCP tiene referencia de simulación de dispositivos).
7. **Auditar** con `scripts/audit_ui.luau` vía `execute_luau` (Edit sobre `StarterGui`, o Client sobre `PlayerGui` en playtest). Corregir todo lo marcado ERROR.
8. **Mostrar al usuario** capturas + `docs/ui.md` y esperar revisión.

## Reglas técnicas obligatorias
Detalle y fuentes en `references/technical-rules.md`.
- Tamaños y posiciones en **Scale**, no Offset (excepción: `UISizeConstraint.MinSize` como piso táctil y grosores de `UIStroke`).
- `UIAspectRatioConstraint` en todo botón, icono y popup que deba conservar forma.
- `ScreenGui.ScreenInsets = CoreUISafeInsets` en toda pantalla con elementos interactivos (evita notch y barra superior de Roblox).
- Botones táctiles: mínimo 44×44 px efectivos (piso con `UISizeConstraint.MinSize`), separados entre sí.
- Texto con `TextScaled` + `UITextSizeConstraint` (MinTextSize ≥ 9).
- Animar con `UIScale` (no `Size`) para no romper el layout; nunca tweenear `Thickness` de un `UIStroke` sobre texto.

## Checklist final
- [ ] Se preguntó al usuario por sus assets de UI y se usaron si los dio.
- [ ] Todo asset usado está en `assets/index.json` con licencia; ninguno copiado de otro juego.
- [ ] `audit_ui.luau` sin ERROR.
- [ ] Verde = comprar/aceptar, rojo = cerrar, dorado = premium, en todas las pantallas.
- [ ] Monedas arriba, botones laterales fijos, ningún botón bajo el notch ni la barra de Roblox.
- [ ] Probado en teléfono chico horizontal y tablet: todo legible, nada se superpone, todo tocable con el pulgar.
- [ ] Popups abren escalando desde el centro, tienen botón cerrar rojo y se cierra uno al abrir otro.
- [ ] Ningún botón modifica monedas/inventario en el cliente; los remotes pasaron por `roblox-security`.
- [ ] `docs/ui.md` actualizado.

## Límites
- No decide precios ni ofertas (→ `roblox-monetization`), ni lógica de servidor (→ `roblox-security` y plantilla).
- Toma el estilo, nunca copia iconos, logos, mascotas ni layouts exactos de juegos existentes.
- No sube fuentes ni imágenes sin que el usuario confirme que tiene derechos sobre ellas.
- UI 3D (`BillboardGui`, `SurfaceGui`) sigue la paleta y fuentes, pero las reglas de zona segura no aplican.
