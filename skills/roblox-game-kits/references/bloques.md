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

Cada bloque: `template/src/server/Kits/<Bloque>.luau` (servidor) y, cuando tiene UI, `template/src/client/Kits/<Bloque>.luau`. Lo que el cliente ve llega en `state.kit.<clave>` (tipos `<Bloque>State` en `Kits/Types.luau`) y los efectos por `KitFx` (`Bus.on("Kit:<Nombre>")`).

| Bloque (clave) | Para qué (hits) | Mundo (etiquetas y atributos) | Remotes y acciones | Señales |
|---|---|---|---|---|
| **Units** (`units`) | Todo lo coleccionable: mascotas, criaturas, peces, cultivos, dados | — | `LockUnit(uid, on)` | `UnitGot`, `RareFound`, `Discover` |
| **Plots** (`plots`) | Base que paga $/s (robar, fusión, tycoon) | `KitPlot` (Model) con `KitSlot` (`Index`), `KitCollectPad`, `KitSpawn`, `KitBarrier`, `KitLockButton`, `KitSlotShop` y una parte "Sign" | `PlaceUnit(uid, slot?)`, `StoreUnit(uid)`, `BuySlot()`, `LockBase()`; cobro al pisar el pad | `Collect`, `Place`, `SlotBought`, `Lock` |
| **Belt** (`belt`) | Cinta compartida (*Steal a Brainrot*) | `KitBelt` (la cinta corre por su eje X) | prompt "Buy" | `UnitBought` |
| **Steal** (`steal`) | Robar a otra base y llevarla a la propia | prompt "Steal" en cada unidad colocada (atributo `Owner`; `BeingStolen` mientras se la llevan) | prompt, `PushPlayer(userId)` | `StealStart`, `Steal`, `Stolen`, `Push` |
| **Rolls** (`rolls`) | Huevos, dados, gacha, puestos de compra en tandas | `KitRollStation` (`Roll`): cartel y prompt "Open" que abre la ventana | `RequestRoll(id, count, auto?)` | `Roll`, `Hatch` |
| **Merge** (`merge`) | Fusión por nivel (*Chicken Farm*) o por variante (máquina dorada) | `KitMergeMachine` | `MergeUnits(kind, variant?)` | `Merge` |
| **Sell** (`sell`) | Vender (*Fish It*, cultivo) | `KitSellPad` (vende todo al pisar) | `SellUnits(uids)`, `SellAll()` | `Sell` |
| **Equip** (`equip`) | Mascotas que siguen y multiplican | — (atributo del jugador `Equipped`) | `EquipUnit(uid)`, `UnequipUnit(uid)`, `EquipBest()` | `Equip` |
| **Stats** (`stats`) | "+1 por paso", fuerza, toques | `KitTreadmill` (`Stat`, `Gain`) | `TapStat(id)`, `SetStatCap(id, 0..1)`; pasos medidos en el servidor | `<Stat>Gained`, `Steps`, `Tap` |
| **Zones** (`zones`) | Mundos y biomas con requisito | `KitGate` (`Zone`), `KitZone` (`Zone`, la región), `KitTeleport` (`Zone`) | `UnlockZone(id)`, prompt "Unlock" en la puerta | `ZoneUnlocked`, `Teleport` |
| **Stages** (`stages`) | Escape y obby; corrida con resumen | `KitCheckpoint` (`Stage`), `KitWinPad`, `KitStageStart` | pisar; `Revive()`, `EndRun()` | `Stage`, `Win`, `RunStarted`, `RunEnded`, `Revive` |
| **Fishing** (`fishing`) | Pesca | `KitWater` (`Pool`) | `CastLine()`, `ReelLine()`, `BuyRod(id)` | `Cast`, `Catch`, `RodBought` |
| **Garden** (`garden`) | Cultivo con tienda que se repone | `KitGardenTile` (`Index`, dentro de la base) | `BuySeed(id, n)`, `SelectSeed(id)`, `PlantSeed(tile, id?)`, `HarvestPlant(tile)`, `BuyTile()`; prompt en cada parcela | `SeedBought`, `Plant`, `Harvest`, `TileBought` |
| **Search** (`search`) | Pila con cosas escondidas (la aguja en el pajar) | `KitPile` (`Pile`), `KitDepositPad` | `DigPile()` (o el prompt), `BuyTool(id)`; depositar al pisar | `Dig`, `Found`, `Deposit`, `ToolBought` |
| **Wild** (`wild`) | Capturar con requisito (dinos, huevos en nidos) | `KitWildSpawn` (`Pool` = número de `wild.spawns`, `Zone`) | prompt "Catch" (mantener; el servidor mide el tiempo) | `Capture` |
| **Upgrades** (`upgrades`) | Mejoras por nivel; escalera de multiplicadores | `KitUpgradeStation` | `BuyUpgrade(id)` | `Upgrade` |
| **Tycoon** (`tycoon`) | Edificios que se compran en la base | `KitTycoonButton` y `KitBuilding` (`Building`, dentro de la base) | pisar el botón | `Build` |
| **Items** (`items`) | Consumibles con tecla (pociones, habilidades) | — | `UseItem(id)` | `ItemUsed` |

Premios por ítem (`Types.Reward.item`, de productos, ruleta, códigos, misiones o zonas del índice): `"Unit:<unidad>[:<mutación>[:<tamaño>]]"`, `"Roll:<tirada>"`, `"Item:<objeto>"`, `"Upgrade:<mejora>"`, `"Zone:<zona>"`, `"Stat:<estadística>"` (suma `count`), `"Rod:<caña>"`, `"Tool:<herramienta>"`, `"Seed:<semilla>"`, `"Garden:Skip"`, `"Merge:Skip"`, `"Stages:Revive"`. `Lib/KitCheck.item` los revisa. Lo que llega por Robux nunca se pierde: si no hay dónde usarlo (nada creciendo, nada fusionándose, no está muerto), queda guardado para la próxima.

Piezas comunes: `KitWorld` (etiquetas, prompts y pads con la distancia medida en el servidor, carteles, velocidad por factores), `Bonus` (efectos de las mejoras), `Gates` (zonas abiertas), `KitFx` (efectos al cliente), `UnitModel` (modelo de cada unidad).

## El mapa

`server/Map/MapKit.luau` arma el mapa de la receta al arrancar el servidor, solo si la receta trae `map` y el lugar **no** tiene una carpeta `Map` en Workspace. Un mapa hecho a mano gana siempre: basta con ponerle las mismas etiquetas y atributos.

- **Plan como datos:** el plan sale de `shared/Lib/MapPlan.luau`, que es lógica pura y está probada en `tests/MapPlan.spec.luau`. Los tests revisan:
  - que cada bloque encuentre lo suyo;
  - que nada choque y que lo que se usa esté sobre un piso;
  - que el mismo nombre de receta dé siempre el mismo mapa.
- **Estilo:** sale de mirar las miniaturas oficiales y fotogramas de videos de gameplay de *Steal An Egg*, *Steal a Brainrot* y *Fish It!* (2026-11-03). Lo que hace rico a sus mapas, y lo que copia MapPlan:
  - **Piso y colores:** plástico con studs (`SurfaceType.Studs`) y colores muy saturados (verde lima). Alrededor, cerros en terrazas color arena con el borde verde que encierran el mapa, o mar en los juegos de agua.
  - **Bases:**
    - corrales con cerco de postes y travesaños de color (Steal An Egg);
    - o edificios de paredes altas con vidrio (Steal a Brainrot);
    - en los dos casos, pedestales para las unidades, placa de cobro verde y láser en la entrada.
  - **Puestos:** de madera, con toldo a rayas y un aro brillante en el piso. La cinta es una alfombra roja con studs y arco.
  - **Adornos:**
    - faroles, flores y arbustos;
    - una máquina de fusión de bloques de colores;
    - islas con cerco de madera, muelles de tablas y un arco con el nombre de la zona;
    - la criatura más rara, gigante, en la plaza (vitrina).
  - **Lo que no se puede con partes:** el agua de terreno de Fish It!, las ruinas y los efectos de partículas. Eso se agrega a mano en Studio sobre el mapa armado (carpeta `Map` propia).
- **Opciones de `map`:**

  | Opción | Qué hace |
  |---|---|
  | `theme` | Uno de `KitCheck.THEMES`. Cada zona toma su bioma por el nombre ("Sunny Beach", "Snowy Peaks"). |
  | `shops` | Ventanas con puesto en el lobby, de `KitCheck.SHOPS`. Sin esto, van las que piden los bloques activos, y esas ventanas dejan de ocupar lugar en el menú del HUD. |
  | `treadmills` | `{ stat, gains }`: tres cintas de correr por isla, con la ganancia de cada zona. |
  | `spin` | Ruleta en el mundo. |
  | `leaderboard` | Tablas de los dos primeros `leaderstats`. |
  | `groupChest` | Cofre del grupo. Se pone solo con `GameConfig.GROUP_ID`. |
  | `nextUpdate` | Arco con el cartel "NEXT UPDATE: …". |
  | `bases` | `"pen"` (corral, por defecto) o `"building"` (paredes altas). |
  | `backdrop` | `"hills"`, `"ocean"` o `"none"`. Por defecto: mar en playa, bajo el agua y pesca; cerros en lo demás. |
  | `showcase` | Unidad gigante de la vitrina. Por defecto, la última de `units.list`; `""` para ninguna. |
- **Distribución:**
  - **Plaza:** spawn en el centro, mirando a −Z, y cuatro pasos en cruz.
  - **Alrededor de la plaza:** puestos, tablas, ruleta y cofre en anillos, mirando al centro.
  - **Hacia −Z:** arco del cartel y la fila de venta, mejoras y fusión.
  - **Hacia +Z:** las bases a los dos lados de una avenida con la cinta.
  - **Hacia +X:** las islas de las zonas, con puentes y puertas. Adentro van las estaciones de tiradas junto al camino y cuatro lotes para cintas de correr, agua, pilas y salvajes.
  - **Hacia −X:** las plataformas de etapas sobre el vacío, con huecos de 4 a 7 studs que se saltan caminando.
- **Etiquetas del lobby (núcleo):**

  | Etiqueta | Atributos | Qué hace |
  |---|---|---|
  | `KitShopStand` | `Window`, `Label` | Prompt local que abre esa ventana. "Robux" abre la tienda en la sección Currency. |
  | `KitLeaderboard` | `Stat` | `Social/GlobalLeaderboardService` guarda y lee los mejores con OrderedDataStore, con los valores codificados con `Lib/Ranking`. Deja la lista en el atributo `Top`, y `LeaderboardController` la dibuja en la parte con atributo `Face`. |
  | `KitGroupChest` | — | Prompt que cobra el premio por unirse al grupo (`Bus "ClaimGroup"`). |
  | `KitShowcase` | `Unit` | `server/Map/Showcase` pone encima el modelo de esa unidad escalado ×4, mirando al spawn, con su cartel. |
- **`KitZone`:** es una caja que cubre la zona. Al teletransportarse se llega al centro de su cara de abajo, así que esa cara tiene que estar en el piso.
- **Vista previa sin Studio:**
  - Comando: `node tools/render3d/mapview.cjs --recipe <receta.luau> --out <prefijo>`.
  - Genera dos imágenes: `-hero.png` (en perspectiva) y `-top.png` (vista desde arriba).
  - Sirve para revisar el armado y para mostrarlo en el PR.
  - Ejemplos en `references/mapa/`:
    - `completo-heroe.jpg` y `completo-arriba.jpg`: la receta de prueba con todo prendido;
    - `robar-pradera.jpg`: robar y colocar con cerros, corrales, alfombra roja y vitrina;
    - `temas.jpg`: robar en dulces (cerros de chocolate), obby en el espacio y huevos en la playa (con mar).

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

**Las nueve están hechas** en `template/src/shared/Kits/Presets/<Receta>.luau` (2026-11-03). Cada una trae:
- unidades de muestra con su ícono (`assets/ui/unit-icons`, `pet-icons`) y emoji de respaldo;
- economía que arranca con los $10 iniciales;
- objetivos que enseñan el loop paso a paso (el tutorial sin pantallas) y misiones;
- tienda propia (pases x3/x8, unidades "OP", "+10K Speed", escalera por Robux) y mapa.

`tests/Presets.spec.luau` revisa las nueve:
- KitCheck sin errores;
- mapa sano y completo;
- íconos con respaldo;
- que lo primero se pueda pagar.

Vista previa de los mapas: `references/mapa/recetas.jpg`.

**Son muestras.** Un juego real copia la receta a su `KitConfig.luau` y la hace propia: sus nombres, criaturas con modelo 3D, íconos, precios, zonas y eventos. También hace propio el mapa:
1. Arrancar el juego en Studio.
2. Copiar la carpeta `Map` que arma MapKit.
3. Pegarla fija en el lugar.
4. Editarla a mano, con agua de terreno, partículas y modelos. Basta con mantener las etiquetas.

**Campos de la receta además de los bloques:**

| Campo | Qué hace |
|---|---|
| `objectives` | La cadena de objetivos. |
| `endless` | Los objetivos que siguen después de la cadena; por defecto, "Earn $X". |
| `quests` | Las misiones. Los eventos de `objectives`, `endless` y `quests` tienen que estar en `KitCheck.SIGNALS` o ser `"<Stat>Gained"`. |
| `rebirth` | Moneda, costo y qué multiplica el renacer. En +1 Speed se paga con victorias y multiplica la velocidad. |
| `shop` | Pases y productos propios. |
| `iconFallbacks` | El emoji de cada ícono propio (`{ pebble_pup = "🐶" }`), que se ve hasta subir el ícono. Los de las nueve recetas ya están en `Icons.luau`. |
| `map` | El mapa (ver "El mapa"). |

## Ideas de fuera de Roblox

Una idea externa ("la aguja en un pajar", "cocinar a cachetadas") se baja a bloques: ¿qué junta el jugador (Units)?, ¿cómo lo consigue (Rolls, Belt, Fishing, Search, Wild, Garden)?, ¿qué hace con eso (Plots, Sell, Equip, Merge)?, ¿qué sube (Stats, Upgrades)?, ¿adónde va después (Zones, Stages)? Si un verbo no entra en ningún bloque, se hace un bloque nuevo con la misma forma (`init`, `start`, `snapshot`, `item`) y se suma acá.
