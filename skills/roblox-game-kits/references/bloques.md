# Bloques del armador

Un juego del hub = **núcleo de la plantilla** (datos, economía, retención, tienda, UI estilo hit) + **bloques de juego** elegidos en `src/shared/Config/KitConfig.luau`. Cada top hit es una combinación de bloques: no hay un kit por juego, sino piezas que se arman. Las **recetas** (`src/shared/Kits/Presets/`) son combinaciones listas de las fórmulas de `skills/_shared/hits-2026.md`.

## Reglas de todos los bloques

- **Servidor autoritativo:** el cliente pide (remote con validador y límite, o `ProximityPrompt`) y muestra. Precio, tirada, distancia, tiempo y dueño los decide el servidor.
- **Configuración pura:** los bloques leen la receta (`KitConfig`), que es solo datos (números, textos, tablas): sin `Color3` ni `Vector3`. Colores en hex (`"#46D64B"`). Así `tests/Presets.spec.luau` valida cada receta sin Roblox.
- **El mapa se encuentra por etiquetas** (`CollectionService`): `MapKit` arma un mapa con esas etiquetas y un mapa hecho a mano en Studio funciona igual si usa las mismas. Lo que el bloque necesita de una parte va en atributos (`Roll`, `Zone`, `Stage`, `Index`...).
- **Textos que ve el jugador en inglés** (`Config/UiText.luau` y la receta); docs en español.
- **Teléfono primero:** botones contextuales en la barra de acción de abajo al centro (entre el joystick y el salto), 44 px o más.
- **Dopamina:** cada logro tiene sonido, efecto y popup (`RewardService` con `show`, `Juice`, `Effects`). Lo raro se anuncia (`AnnounceService`).
- **Monetización:** los pases y productos de cada bloque están en `ShopConfig` con `kit = "<bloque>"`: la tienda solo muestra los de los bloques activos (y los que tienen id).
- **Señales:** cada acción manda `Signals.track(player, "<Evento>")`: así avanzan objetivos, misiones e índice sin que los bloques se conozcan.

## Datos

Cada bloque guarda lo suyo en `data.kits.<bloque>` con `DataService.registerKit` (antes de `DataService.start`). Las unidades del jugador:

```
data.kits.units = { list = { Unit }, nextId = number, orphans = { Unit } }
Unit = { uid, kind, variant?, size?, weight?, slot?, equipped?, locked? }
```

`kind` es el id de `units.list`; `variant` y `size`, la mutación y el tamaño (nil = Normal); `weight`, los kilos (peces); `slot` = colocada en ese espacio de la base; `equipped` = equipada; `locked` = cuidada por el jugador (no entra en "vender todo" ni en "fusionar todo"). Si una unidad sale de la receta después de publicar, al cargar pasa a `orphans` (no se borra). La cuenta de valor, ingreso, poder, nombre y sorteos está en `Lib/UnitMath.luau`, igual en servidor y cliente.

Entre bloques no hay `require` en círculo: los bonos de las mejoras pasan por `server/Kits/Bonus.luau` (`Bonus.get(player, "inventory")`) y los cambios de unidades por las señales `Units.Added`, `Units.Removed` y `Units.Changed`.

## Catálogo

| Bloque | Para qué (hits) | Mundo (etiquetas y atributos) | El jugador | Señales |
|---|---|---|---|---|
| **Units** | Todo lo coleccionable: mascotas, criaturas, peces, cultivos, dados | — | inventario (ventana) | `UnitGot` |
| **Plots** | Base que paga $/s (robar, fusión, tycoon) | `KitPlot` (Model) con `KitSlot` (`Index`), `KitCollectPad`, `KitSpawn`, `KitBarrier`, `KitLockButton`, `KitSlotShop` | `PlaceUnit`, `StoreUnit`, `LockBase`, `BuySlot`; cobro al pisar el pad | `Collect`, `Place` |
| **Belt** | Cinta compartida (*Steal a Brainrot*) | `KitBelt` (la cinta corre por su eje X) | prompt "Buy" | `UnitBought` |
| **Steal** | Robar a otra base | prompts en las unidades colocadas | prompt "Steal", `PushPlayer` | `Steal` |
| **Rolls** | Huevos, dados, gacha, puestos de compra en tandas | `KitRollStation` (`Roll`) | `RequestRoll(id, count, auto)`, prompt "Open" | `Roll`, `Hatch` |
| **Merge** | Fusión por nivel (*Chicken Farm*) o por variante (máquina dorada) | `KitMergeMachine` | `MergeUnits(kind)` | `Merge` |
| **Sell** | Vender (*Fish It*, cultivo) | `KitSellPad` | `SellUnits`; vender todo al pisar | `Sell` |
| **Equip** | Mascotas que siguen y multiplican | — | `EquipUnit`, `UnequipUnit`, `EquipBest` | `Equip` |
| **Stats** | "+1 por paso", fuerza, toques | `KitTreadmill` (`Stat`, `Gain`) | `TapStat(id)`, `SetStatCap(id, fracción)`; pasos medidos en el servidor | `<Stat>Gained`, `Steps` |
| **Zones** | Mundos y biomas con requisito | `KitGate` (`Zone`), `KitZone` (`Zone`, la región), `KitTeleport` (`Zone`) | `UnlockZone(id)`, prompt en la puerta | `ZoneUnlocked` |
| **Stages** | Escape y obby; corrida con resumen | `KitCheckpoint` (`Stage`), `KitWinPad`, `KitStageStart` | pisar; `Revive` | `Stage`, `Win`, `RunEnded` |
| **Fishing** | Pesca | `KitWater` (`Pool`) | `CastLine`, `ReelLine` | `Catch` |
| **Garden** | Cultivo con tienda que se repone | `KitGardenTile` (`Index`, dentro de la base) | `BuySeed`, `SelectSeed`; prompts plantar y cosechar | `Plant`, `Harvest` |
| **Search** | Pila con cosas escondidas (la aguja en el pajar) | `KitPile` (`Pile`), `KitDepositPad` | `DigPile`; depositar al pisar | `Dig`, `Deposit` |
| **Wild** | Capturar con requisito (dinos, huevos en nidos) | `KitWildSpawn` (`Zone`, `Pool`) | prompt "Catch" | `Capture` |
| **Upgrades** | Mejoras por nivel; escalera de multiplicadores | `KitUpgradeStation` | `BuyUpgrade(id)`; productos `Upgrade:<id>` | `Upgrade` |
| **Tycoon** | Edificios que se compran en la base | `KitTycoonButton` y `KitBuilding` (`Building`, dentro de la base) | pisar el botón | `Build` |
| **Items** | Consumibles con tecla (pociones, habilidades) | — | `UseItem(id)` | `ItemUsed` |

Premios por ítem (`Types.Reward.item`, de productos, ruleta, códigos o misiones): `"Unit:<kind>[:variant]"`, `"Item:<id>"`, `"Upgrade:<id>"`, `"Garden:Skip"`, `"Merge:Skip"`, `"Stages:Revive"`, `"Zone:<id>"`.

## Las fórmulas, armadas

| Receta | Bloques | Mapa |
|---|---|---|
| **StealAndPlace** (*Steal a Brainrot*, *Steal An Egg*) | Units, Plots, Belt, Steal, Merge, Sell, Upgrades | Cinta en el centro, bases a los costados, puesto SELL |
| **HatchAndCollect** (*Pet Simulator 99*, *Tap Simulator*) | Units, Stats (toques), Rolls (huevos x1/x3/x8), Equip, Zones, Upgrades | Mundos en fila con puertas, huevos en cada mundo |
| **PlusOneEscape** (*+1 Speed Keyboard Escape*) | Stats (velocidad por paso), Stages, Zones, Rolls (estelas), Equip | Pasillo de etapas, cintas de correr, pad de victorias |
| **Fishing** (*Fish It!*, *Fisch*) | Units (peces con peso), Fishing, Sell, Zones (islas), Upgrades (cañas) | Islas con muelles, mercader con SELL |
| **SearchAndDig** (*Search For The Needle*, *Dig & Clean*) | Units (lo que se encuentra), Search, Upgrades (herramienta, mochila), Zones | Pila gigante en un granero, depósito |
| **GrowGarden** (*Grow a Garden*) | Units (cultivos), Garden, Sell, Plots (la parcela), Upgrades | Parcela por jugador, tienda de semillas, SELL |
| **MergeTycoon** (*Chicken Farm*) | Units (gallinas por nivel), Plots (nidos), Rolls (puestos Buy 1/5/25/100), Merge, Upgrades (escalera de multiplicadores por Robux) | Granja por jugador con carteles en el piso |
| **RunAndCatch** (*Ride a Dino*) | Units, Stats (fuerza), Stages (corrida con resumen y revivir), Wild (estampida), Plots (corrales con nivel), Merge, Items (habilidades con tecla) | Pista de corrida, corrales, máquina de fusión |
| **CozyTycoon** (*My Small Business*, *Cook the Chicken*) | Tycoon, Stats (toques: la acción graciosa), Upgrades, Plots (el local) | Local por jugador con botones de compra |

Todas usan además todo el núcleo: diario, regalos por tiempo, misiones, ruleta, códigos, grupo, ganancias sin conexión, renacer, índice, eventos, invitar y tienda.

## Ideas de fuera de Roblox

Una idea externa ("la aguja en un pajar", "cocinar a cachetadas") se baja a bloques: ¿qué junta el jugador (Units)?, ¿cómo lo consigue (Rolls, Belt, Fishing, Search, Wild, Garden)?, ¿qué hace con eso (Plots, Sell, Equip, Merge)?, ¿qué sube (Stats, Upgrades)?, ¿adónde va después (Zones, Stages)? Si un verbo no entra en ningún bloque, se hace un bloque nuevo con la misma forma (`init`, `start`, `snapshot`, `item`) y se suma acá.
