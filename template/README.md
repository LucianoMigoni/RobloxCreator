# Plantilla de juego

Base que copia cada juego (`cp -r template games/<juego>`). Todo lo sensible pasa en el servidor; el cliente solo pide y muestra. Las reglas de seguridad están en `skills/roblox-security/SKILL.md`.

## Qué trae

| Pieza | Archivo | Qué hace |
|---|---|---|
| Arranque | `src/server/Main.server.luau`, `src/client/Main.client.luau` | Inician los módulos en orden, con los bloques del armador antes de cargar los datos |
| Armador de juegos | `src/shared/Config/KitConfig.luau` (receta), `src/shared/Kits/`, `src/server/Kits/`, `src/client/Kits/` | La jugabilidad por bloques (unidades, bases, huevos, fusión, pesca, cultivo, etapas...): la receta dice cuáles usa y cómo (`skills/roblox-game-kits/references/bloques.md`). `Lib/KitCheck` la revisa |
| Datos | `src/server/Data/DataService.luau` | Guardado con bloqueo de sesión, autoguardado, guardado al salir y al cerrar |
| Remotes | `src/server/Net/Remotes.luau` + `Validate` + `RateLimiter` | Única puerta del cliente: validación y límite de frecuencia |
| Estado para el cliente | `src/server/PlayerStateService.luau` → `src/client/PlayerState.luau` | El cliente pide su estado al entrar y recibe cada cambio |
| Economía | `src/server/Economy/`, `src/server/Boosts/BoostService.luau` | Varias monedas con tope y analíticas; multiplicadores e impulsos con reloj |
| Premios | `src/server/Rewards/RewardService.luau` | Todo premio pasa por acá: moneda, "N minutos de ganancia", impulsos, tiradas, ítems del kit |
| Retención | `src/server/Retention/` | Diario con racha, regalos por tiempo, misiones, ruleta, códigos, grupo, ganancias sin conexión, renacer, objetivos e índice por zonas |
| Tienda | `src/server/Shop/ShopService.luau` | Developer Products (ProcessReceipt), Game Passes, suscripción, regalos de pases y anuncio con premio |
| Social y eventos | `src/server/Social/`, `src/server/Events/EventService.luau` | Anuncios al servidor, campañas, tablas, ajustes y eventos con horario |
| UI estilo hit | `src/shared/UIKit.luau`, `src/client/Controllers/`, `src/client/UI/` | HUD, ventanas, tienda, índice, carteles y flechas en el mundo (`skills/roblox-ui-designer/references/hud-hits.md`) |
| Configuración | `src/shared/Config/` | Precios, productos, premios, textos, tiempos: nada de números sueltos en la lógica |
| Tests | `tests/*.spec.luau` | Lógica pura (validación, saldo, recibos, bloqueo, retención, índice) con el CLI de Luau |

## Cómo extenderla

- **Un dato nuevo del jugador:** agregarlo a `DEFAULT_DATA` en `Config/DataConfig.luau`. Los jugadores existentes lo reciben al cargar (`Reconcile`). Si el cliente lo tiene que ver, sumarlo a `Types.PlayerSnapshot` y a `PlayerStateService.snapshot`.
- **Un remote nuevo:** en el servicio que lo usa, con `Remotes.onEvent` u `onInvoke`: un validador por argumento y un límite (ver `skills/roblox-security`). En el cliente, `Net.event`/`Net.func`. Crearlo de otra forma hace fallar `tools/check.py`.
- **Ganar monedas jugando:** `CurrencyService.add(player, monto, Enum.AnalyticsEconomyTransactionType.Gameplay, "<qué>")`. El monto lo decide el servidor, nunca el cliente.
- **Algo que se vende por Robux:** crearlo en el Creator Dashboard y poner su id en `PRODUCTS`, `PASSES` o `SUBSCRIPTIONS` de `Config/ShopConfig.luau`; con id `0` (o `""`) no se muestra ni se otorga. La oferta de arriba de la tienda es `FEATURED`.
- **El índice del juego:**
  1. En el servidor, el kit anota cada hallazgo con `IndexService.discover(player, "Kitty|Normal")` y define las zonas con `IndexService.setZones({ { id, name, keys, reward, image?, isUnlocked? } })`. El premio de cada zona lo cobra el jugador con CLAIM; el servidor valida que la completó.
  2. En el cliente, el kit da las piezas con `Bus.handle("IndexEntries", ...)`: `key`, `name`, `zone`, `variant`, `rarity`, `chance`, `detail`, `icon` o `model` (tipo `Entry` en `Controllers/IndexController.luau`).
- **Carteles y flechas en el mundo:** en Studio, la etiqueta `HitSign` en una parte con los atributos `Text`, `Variant` e `Icon` pone el cartel. Desde el kit, `World.sign`/`World.tag` (`src/client/UI/World.luau`), y `Bus.call("ShowPath", parte)` dibuja las flechas hasta el objetivo (`nil` las saca).
- **Una pantalla nueva:** un controlador en `src/client/Controllers/`, arrancado desde `Main.client.luau`, con `UIKit` (ver `skills/roblox-ui-designer`). Dentro de listas con scroll, el alto de filas y tarjetas sale de `UIKit.fitHeight`/`UIKit.row`, nunca de una escala vertical.
- **La jugabilidad:** elegir una receta de `src/shared/Kits/Presets/` en `Config/KitConfig.luau` y editarla (unidades, precios, zonas, objetivos, misiones). La receta también puede traer monedas propias (`currencies`), objetivos (`objectives`), misiones (`quests`) y la tabla de jugadores (`leaderstats`): reemplazan las del núcleo. Al arrancar, el servidor la revisa y avisa cada problema en la consola (`[Kits]`).
- **Un bloque nuevo del armador:** un módulo en `src/server/Kits/` con `init`, `start` y, si hace falta, `snapshot`, `income` e `items`, sumado a `BLOCKS` de `server/Kits/Kits.luau`; su UI en `src/client/Kits/` con `start(hud)`, sumada a `BLOCKS` de `client/Kits/Kits.luau`. Las partes del mapa se encuentran por etiqueta (`Kits/Tags.luau`, `KitWorld.tagged`).
- **Lógica pura nueva** (cálculos sin Roblox): módulo aparte requerido por ruta (`require("./X")`) y su `tests/X.spec.luau`.

## Probar

- Sin Studio: `python tools/check.py` desde la raíz del repo (tipos, tests, reglas).
- En Studio: el flujo de prueba de `skills/roblox-security/SKILL.md` (auditoría, prueba de abuso, persistencia), `audit_ui.luau` de `skills/roblox-ui-designer` y `require(game.ReplicatedStorage.Shared.UIKit).selfTest()` en la barra de comandos. La UI se revisa en el emulador de dispositivos (teléfono horizontal y PC). Los datos solo se guardan en un lugar publicado con acceso a API activado, y solo en una copia de prueba.
