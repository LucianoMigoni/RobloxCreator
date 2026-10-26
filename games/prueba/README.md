# Steal & Fuse Critters (`games/prueba`)

Juego de prueba del hub (C2). Concepto: `docs/concepto.md`; spec: `docs/spec.md`. Copiado de `template/` el 2026-10-26; lo de abajo describe la base heredada. Todo lo sensible pasa en el servidor; el cliente solo pide y muestra. Las reglas de seguridad están en `skills/roblox-security/SKILL.md`.

## Qué trae

| Pieza | Archivo | Qué hace |
|---|---|---|
| Arranque | `src/server/Main.server.luau`, `src/client/Main.client.luau` | Inician los módulos en orden |
| Datos | `src/server/Data/DataService.luau` | Guardado con bloqueo de sesión, autoguardado, guardado al salir y al cerrar |
| Remotes | `src/server/Net/Remotes.luau` + `Validate` + `RateLimiter` | Única puerta del cliente: validación y límite de frecuencia |
| Estado para el cliente | `src/server/PlayerStateService.luau` → `src/client/PlayerState.luau` | El cliente pide su estado al entrar y recibe cada cambio |
| Monedas | `src/server/Economy/CurrencyService.luau` | Sumar y gastar con tope, con eventos de economía en AnalyticsService |
| Inventario | `src/server/Economy/InventoryService.luau` | Ítems únicos del jugador |
| Tienda | `src/server/Shop/ShopService.luau` | Compras con monedas, Developer Products (ProcessReceipt) y Game Passes |
| Onboarding | `src/server/Onboarding/OnboardingService.luau` | Embudo de los primeros minutos en Creator Analytics |
| UI | `src/shared/UIKit.luau`, `src/client/Controllers/` | HUD, tienda e inventario con el estilo del hub |
| Configuración | `src/shared/Config/` | Precios, productos, pasos, textos, tiempos: nada de números sueltos en la lógica |
| Tests | `tests/*.spec.luau` | Lógica pura (validación, saldo, recibos, bloqueo) con el CLI de Luau |

## Cómo extenderla

- **Un dato nuevo del jugador:** agregarlo a `DEFAULT_DATA` en `Config/DataConfig.luau`. Los jugadores existentes lo reciben al cargar (`Reconcile`). Si el cliente lo tiene que ver, sumarlo a `Types.PlayerSnapshot` y a `PlayerStateService.snapshot`.
- **Un remote nuevo:** en el servicio que lo usa, con `Remotes.onEvent` u `onInvoke`: un validador por argumento y un límite (ver `skills/roblox-security`). En el cliente, `Net.event`/`Net.func`. Crearlo de otra forma hace fallar `tools/check.py`.
- **Ganar monedas jugando:** `CurrencyService.add(player, monto, Enum.AnalyticsEconomyTransactionType.Gameplay, "<qué>")`. El monto lo decide el servidor, nunca el cliente.
- **Un ítem de tienda:** `ITEMS` en `Config/ShopConfig.luau`. Un pack de Robux o un pase: crearlo en el Creator Dashboard y poner su id en `PRODUCTS` o `GAME_PASSES`; con id `0` no se muestra ni se otorga.
- **Un paso de onboarding:** `STEPS` en `Config/OnboardingConfig.luau`. Los de servidor los marca `OnboardingService.complete`; los de cliente llegan por el remote `ReportOnboardingStep` y nunca dan premio.
- **Una pantalla nueva:** un controlador en `src/client/Controllers/`, arrancado desde `Main.client.luau`, con `UIKit` (ver `skills/roblox-ui-designer`).
- **Lógica pura nueva** (cálculos sin Roblox): módulo aparte requerido por ruta (`require("./X")`) y su `tests/X.spec.luau`.

## Probar

- Sin Studio: `python tools/check.py` desde la raíz del repo (tipos, tests, reglas).
- En Studio: el flujo de prueba de `skills/roblox-security/SKILL.md` (auditoría, prueba de abuso, persistencia) y `audit_ui.luau` de `skills/roblox-ui-designer`. Los datos solo se guardan en un lugar publicado con acceso a API activado, y solo en una copia de prueba.
