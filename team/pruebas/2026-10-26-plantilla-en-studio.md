# Pruebas en Studio de la plantilla — 2026-10-26

Quién: Luciano (con Claude, por el MCP de Studio). Rama `luciano/fase-c`, sobre `leonelblumberg/quirky-dijkstra-2kxnwz`.
Cómo: `rojo serve` de `template/` sincronizado a un Baseplate sin publicar (PlaceId 0).

## Resultados

| Prueba | Resultado |
|---|---|
| `UIKit.selfTest()` (Edit) | OK |
| Arranque en playtest | Sin errores de script. DataStore no disponible (lugar sin publicar): el jugador queda en "errored" como está previsto |
| `audit_remotes.luau` (Server) | 0 ERROR, 0 WARN, 4 OK (`StateChanged`, `GetPlayerState`, `ReportOnboardingStep`, `RequestPurchase`) |
| `abuse_test.luau` (Client) | 0 ERROR, 6 rechazos OK; consola con `[Remotes] ... rechazado` (valor no permitido y límite de frecuencia); estado del jugador sin cambios |
| `audit_ui.luau` (Client, con la tienda abierta) | 0 ERROR, 0 WARN en Galaxy A06 (después de los arreglos de abajo) |
| HUD y tienda en dispositivos | Galaxy A06 (705×338), iPhone 17 Pro (750×381) y iPad 10.ª gen (1179×819): todo legible, sin superposiciones, nada en las zonas del joystick ni del salto |
| Persistencia y bloqueo con dos ventanas | **No probado**: necesita una copia publicada con acceso a API (sigue en Pendiente) |

## Arreglos hechos

1. **Botones laterales de 44×30 px en el Galaxy A06.** El `MinSize` 44×44 del botón, junto con el `UIAspectRatioConstraint` y la lista, solo se respetó en el ancho. Arreglo: la `SideBar` tiene un ancho mínimo de 44 px, así el botón cuadrado mide 44×44.
2. **`audit_ui.luau` no lo detectaba**: si el botón tenía `MinSize` no medía el tamaño real. Ahora mide siempre.
3. **Botones laterales pegados** (7 px de separación en un viewport de 573): el `Padding` 0.03 se medía contra la barra (40 % de la pantalla). Ahora es 0.075 (3 % del alto de pantalla) y el botón pasa del 12 % al 11 % para que sigan entrando 3 por columna.
4. **El popup tapaba el contador de monedas**: `CurrencyBar` con `ZIndex` 10 para ver el saldo mientras se compra.

## Primera foto de rendimiento (Galaxy A06 simulado, Baseplate vacío)

| | Cliente | Servidor |
|---|---|---|
| Instancias | 52 699 | 49 688 |
| Draw calls de escena | 9 | — |
| Triángulos de escena | 17 365 | — |
| BaseParts / MeshParts en Workspace | 23 / 19 | 23 / 19 |
| StreamingEnabled | true | true |

La memoria (2950 MB) es la de todo Studio, no la del juego: sirve solo para comparar fotos tomadas igual. Las instancias incluyen las de Studio. La prueba real de memoria es en el teléfono.

## Aprendido del MCP de Studio

- `screen_capture` muestra la UI en playtest.
- El simulador de dispositivos se maneja con `StudioDeviceSimulatorService` desde `execute_luau` (también en datamodel Client durante el playtest). La orientación se fija después de elegir el dispositivo.
- Con el simulador de teléfono activo, `user_mouse_input` no dispara `Activated`: abrir los popups antes de activarlo.
- La consola muestra `ContentId: rbxassetid://203785492 failed` en cada playtest. No viene del repo ni del lugar (buscado en el código y en Workspace, Lighting, PlayerGui, ReplicatedStorage y StarterGui): probablemente es un plugin de Studio.
