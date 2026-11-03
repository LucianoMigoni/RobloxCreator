# Momentos del juego y su respuesta

Lo que hace hoy cada momento del núcleo y de los bloques del armador (revisado en el código el 2026-11-03). Los niveles son los de la escalera de `SKILL.md`. Al agregar un momento, sumar su fila.

## Núcleo

| Momento | Dónde | Sonido | Pantalla y mundo | Nivel |
|---|---|---|---|---|
| Premio (diario, misión, ruleta, código, compra) | `RewardController` (`Bus "ShowReward"`) | Según el origen: `Reward`, `Purchase`, `Rebirth`, `CoinsBurst` | Popup con rayos, título arcoíris si es grande, filas con rebote, confeti y destellos; la plata vuela al contador | 3–4 |
| Rareza alta de otro jugador | `AnnounceController` (desde `announceFrom`) | — | Cartel arriba para todo el servidor | 4 |
| Error de un pedido | `KitUi.error` | `Error` | Aviso en inglés por código, sin repetir en 1,2 s | Error |

## Bloques

| Bloque | Momento (`Kit:<Evento>`) | Sonido | Pantalla y mundo | Nivel |
|---|---|---|---|---|
| Plots | `Collect` | `CoinsBurst` y `Coin` por moneda | Aviso y 8 monedas que vuelan al contador (`KitUi.coinsTo`) | 2 |
| Plots | `SlotBought` | `Purchase` | Aviso | 2 |
| Plots | `Locked` | `Equip` | Aviso con el tiempo | 1 |
| Rolls | `Rolled` | `Riser` → `EggCrack` → `Reveal` o `Legendary` | El huevo tiembla, destello blanco, cartas con rebote y rayos del color de la rareza; desde Legendary, confeti y sacudida | 3–4 |
| Inventory | `Sold` | `Cash` y `Coin` | Aviso y monedas que vuelan (`KitUi.coinsTo`) | 2 |
| Inventory | `Merged` | Del popup | Popup de la unidad nueva (`KitUi.showUnit`) | 3 |
| Inventory | `MergeStarted` | `Whoosh` | Aviso con el tiempo | 1 |
| Extras (cinta) | `Bought` | `Purchase` | `KitUi.announce` | 2–3 |
| Extras (tycoon) | `Built` | `Purchase` | Confeti y aviso | 3 |
| Steal | `Carrying` | `Whoosh` | Aviso y flechas a la base | 2 |
| Steal | `Stole` | Del popup | Popup de la unidad robada | 3 |
| Steal | `BeingStolen` | `Error` | Aviso y sacudida de cámara | Error |
| Steal | `Pushed` | `Whoosh` | Sacudida corta y aviso | Error |
| Steal | `WasStolen`, `StealFailed` | `Error` | Aviso | Error |
| Steal | `StealStopped` | `Reward` | Aviso | 2 |
| Stats | Toque (TAP!) | `Click` | "+N" que sube y botón que late | 1 |
| Stages | `Stage` | `LevelUp` | El contador de etapa late; aviso | 3 |
| Stages | `Win` | `Victory` | Popup de premio y confeti | 4 |
| Stages | `RunStarted`, `Revived` | `Whoosh`, `Reward` | Aviso | 2 |
| Stages | `RunDied`, `RunEnded` | `Error`; resumen | Ventana de revivir; popup de resumen | Error, 3 |
| Fishing | `Bite` | `Notify` | "!" sobre la cabeza y zoom de cámara (`fovPunch`) | 2 |
| Fishing | `Caught` | Del aviso o popup | `KitUi.announce` (popup si es nuevo o desde Epic) | 2–4 |
| Fishing | `TooEarly`, `Escaped` | `Error` | `KitUi.error` | Error |
| Fishing | `RodBought` | `Purchase` | Aviso | 2 |
| Garden | `Harvested` | Del aviso o popup | `KitUi.announce` | 2–4 |
| Search | `Dug` | `Pickup` | — | 1 |
| Search | `Found` | Del aviso o popup | `KitUi.announce` | 2–4 |
| Search | `Deposited` | `Cash` y `Coin` (o `Reward`) | Aviso y monedas que vuelan | 2 |
| Wild | `Captured` | Del aviso o popup | `KitUi.announce` | 2–4 |
| Upgrades | `Upgraded` | `LevelUp` | Aviso | 3 |
| Items | `ItemUsed` | `Reward` | Aviso | 2 |
| Zones | `ZoneOpened` | `LevelUp` | Popup "zona abierta" | 3 |

## Ideas para el próximo pase

- `Effects.floatingText` "+$X" sobre la placa de cobro y sobre lo vendido.
- `Juice.countUp` en el contador del HUD cuando entra mucha plata de golpe.
- Voz "NEW RECORD" al pasar el mejor de etapas.
- `Effects.highlight` sobre la unidad que se está robando.
