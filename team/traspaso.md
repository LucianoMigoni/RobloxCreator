# Traspaso: trabajo en curso y contexto completo

Para la IA (o persona) que retome el trabajo desde un push, por ejemplo el Claude de Luciano si a Leonel se le acaban los tokens. **Leé este archivo entero antes de tocar nada:** acá está todo lo que pidió el usuario, cómo quiere que se trabaje, qué está hecho, qué se está haciendo y qué falta, para seguir igual que en el chat original.

Última actualización: 2026-10-30, hito 0 (diseño del armador). Sesión original: Claude Code en la nube de Leonel, rama `leonelblumberg/quirky-dijkstra-2kxnwz`.

## 0. Cómo retomar, paso a paso

**Para la persona que retoma (por ejemplo, en el Claude de Luciano):** abrir Claude Code en la carpeta del repo y escribirle: *"Leé `team/traspaso.md` y seguí con el plan desde donde quedó, igual que se venía trabajando."* Nada más: este archivo tiene el resto. Si es Claude Code en Windows, la primera vez correr `powershell -ExecutionPolicy Bypass -File .\setup.ps1` (`SETUP.md`).

**Para la IA que retoma:**

1. **Rama:** `git fetch origin && git switch leonelblumberg/quirky-dijkstra-2kxnwz && git pull`. Todo el trabajo está en esa rama: `main` sigue en el primer commit, sin ningún merge. Que una sola persona a la vez pushee a esta rama; si se trabaja en paralelo, sacar `luciano/<tarea>` desde ella.
2. **Leer, en este orden:**
   1. este archivo;
   2. `CLAUDE.md`;
   3. `skills/_shared/como-son-nuestros-juegos.md` (la guía central de qué juegos hacemos);
   4. `skills/roblox-game-kits/references/bloques.md` (diseño del armador, lo que se está construyendo);
   5. `skills/roblox-ui-designer/references/hud-hits.md` (cómo es la UI de los hits);
   6. las últimas filas de `team/decisiones.md` y `team/tareas.md`.
3. **Herramientas:** `rokit install` en la raíz (Rojo 7.7.1, luau-lsp 1.70.1, Luau 0.742). En la nube de Claude, si `rokit` no está, bajar los tres binarios de sus releases de GitHub a `~/.local/bin`.
4. **Antes de cada push:** `python tools/check.py` tiene que terminar en "Chequeo OK" (rojo build, tipos estrictos de Luau, tests, reglas de seguridad, catálogo, JSON). GitHub Actions lo vuelve a correr en cada push.
5. **Seguir el plan de la sección 4 en orden.** Al terminar cada hito, en el mismo commit:
   - actualizar este archivo (secciones 4 y 5);
   - mover la tarea en `team/tareas.md`;
   - anotar las decisiones en `team/decisiones.md`.

   Después, push.
6. **Tabla de tareas:** el usuario quiere verla. En Claude Code, al empezar, crear con `TaskCreate` una tarea por fila de la sección 4 (con su número y estado: las ✅ como completadas) y actualizarla con `TaskUpdate` mientras se trabaja. Si pide "enumerame las tareas", mostrar solo la lista, sin comentarios.
7. **Dónde quedó:** la sección 4 marca la próxima tarea (la primera que no tiene ✅) y la sección 7 tiene el diseño ya decidido de los bloques que faltan del hito 2. Seguir ese diseño: es el que se venía usando.

## 1. El objetivo

- **Hub para hacer juegos de Roblox estilo top hit** que ganen mucho dinero:
  - cash grab, retención, animaciones de dopamina;
  - coloridos, adictivos, divertidos;
  - para chicos de 8 a 12 años (son los que mueven el dinero);
  - en inglés, para todo el mundo, con foco en EE. UU.;
  - teléfono primero;
  - muchas microtransacciones y pay-to-win, dentro de las reglas de Roblox.
- **Desde el 2026-10-30, un armador genérico:** "La idea es que esto sirva para cualquier tipo de tophit, es un armador de juegos genérico en sí. No necesariamente de huevos." Pidió:
  - terminar absolutamente todo el programa;
  - analizarlo para ver que esté todo bien;
  - al final, decir qué hay que conectar, qué claves faltan, etc.

## 2. Cómo quiere el usuario que se trabaje

Dicho en el chat, en sus palabras cuando importa:

- **Calidad y alcance:**
  - "Esforzate, lo quiero lo más completo, funcional y perfecto que puedas. Siempre enfocado a nuestro objetivo, no te olvides nada."
  - "Acordate todos los puntos que habíamos planteado, no te saltees cosas."
  - "No te limites", "no escatimes en recursos".
  - "Buscá siempre el mayor estándar de calidad (lo más cash grab, llamativo y buscando que la gente entre)."
- **Copiar de los hits:** "Que se asemeje a los top hits, no siendo copias literales pero que use todo lo que usan ellos en tácticas, mecánicas, estándares" y "no necesariamente evitando copiarlos". Se copia el diseño entero; los assets con dueño (arte, nombres, modelos, sonidos) se hacen propios.
- **Avisos en el trabajo:**
  - Mostrar la tabla de tareas: "pone el cuadro de las tareas", "me gusta verla". Si pide "enumerame (únicamente) las tareas", solo la lista.
  - Pushear después de cada hito ("Acordate de los push en los hitos") y dejar este traspaso al día en el mismo commit.
  - Mientras trabaja, avisarle cada tanto en una línea qué se está haciendo.
  - "Cuando termines algo importante o que tenga sentido mostrar, mandame alguna pequeña foto o algo para ver. Solo si es relevante y tiene sentido": al terminar algo visual (UI de los bloques, mapa, juego de prueba), mandar una imagen chica (render con Playwright o captura). Lo que no se ve (servidor, lógica) no lleva imagen.
  - Cuando pide una muestra, mandar imágenes reales (renders o capturas), no descripciones.
  - **Cortes:** si dice "terminá este hito y no sigas", cortar apenas se suba el hito o la parte en curso, dejar este traspaso completo y no empezar nada más (el 2026-10-30 se siguió de más y lo marcó: "¿no tenés que cortar cuando esté el hito que dijimos?"). Si no queda claro dónde cortar, preguntar.
- **Lo que depende de las personas** (claves, conectores, cuentas, pruebas) se mantiene en `team/pendientes.md`: "Añadí también las cosas que hay que hacer después, qué API keys necesitás (como ChatGPT y Google), qué conectores hay que poner".
- **El juego de prueba de Luciano no les gustó:** "lo de luciano no nos había gustado", "seguí trabajando con lo que teníamos", "acordate que la idea era rehacerlo". No se usa su código como base: `games/prueba` se rehace con el armador.
- **Idioma:**
  - Hablarle en español.
  - Todo lo que ve el jugador va en inglés (EE. UU.), con traducción automática de Roblox.
- **Ser honesto:**
  - Si algo no se probó en Studio, decirlo.
  - Si una API no se pudo verificar en la documentación, decirlo (regla de `CLAUDE.md`).
- **PRs:** no abrir PR sin que lo pida; pushear solo a la rama de trabajo.

## 3. Todo lo que pidió el usuario (historial)

Estado: ✅ hecho · 🔄 en curso (sección 4) · 👤 depende de una persona.

**2026-10-24 y 25**
- ✅ Revisar el repo y el video del algoritmo de Roblox → `skills/_shared/algoritmo-descubrimiento.md`.
- ✅ "Revisá todo lo hecho, fijate si el plan hay que ajustarlo, corregí todo lo que esté mal, y trabajá con lo que sigue" → `ROADMAP.md` fases A y B.

**2026-10-28: el giro a top hits**
- ✅ "Cambiá todo lo que está ahora": cash grab, retención con animaciones de dopamina, colorido, adictivo, para chicos, cosas en pantalla, objetivos diarios, "características típicas de juegos de Roblox actuales" → plantilla v2/v3.
- ✅ Investigar los hits (Steal An Egg, Fish It, Break and Steal an Egg, +1 Speed Keyboard Escape) → `skills/_shared/hits-2026.md`.
- 🔄 "Añadí todas las skills, animaciones, conectores, todo lo que necesites (ejemplo Blender) y código reutilizable" → falta el código de juego reutilizable: el armador (sección 4).
- 🔄 Usar ideas de juegos existentes fuera de Roblox adaptadas ("la aguja en un pajar") → receta SearchAndDig y guía de ideas externas en el skill del armador.
- ✅ Rediseñar todo si hace falta; dejarlo lo más avanzado posible; foco en chicos; muchísimas microtransacciones.
- 🔄 "Prestá atención en cómo diseñan los HUDs, cómo son los mapas" → HUD ✅; mapas: MapKit (sección 4).
- 🔄 "Conseguí todo lo necesario para la construcción, recursos, animaciones" → recursos ✅; generadores de mapas: MapKit (sección 4).
- ✅ "No tiene que ser exactamente de un juego de pesca, lo que busco es que sean buenos para generar juegos del estilo top hit."
- ✅ Usar todos los trucos (x2, bonus, retención, ruleta); pay-to-win, "lo más cash grab posible"; probabilidades chicas como los hits, no gigantes.
- ✅ Conectar Rojo, Blender, ForgeGUI (evaluar), Meshy (evaluar), Obsidian (evaluar); los dos con todo conectado → `skills/_shared/conectores.md` y `SETUP.md`. 👤 Instalar en cada máquina.
- ✅ Creador de campañas de publicidad (cómo funciona, qué rinde, cuánto poner, cómo llevarlas) → `roblox-campaigns`, `tools/campaigns.py`.
- ✅ Imágenes, miniaturas y descripción para que hagan clic → `skills/_shared/vitrina-hits.md`, `tools/thumbs.py`, `tools/imagegen.py`.
- ✅ "Anotá todo lo que estamos planteando para armar los juegos" → `skills/_shared/como-son-nuestros-juegos.md` (🔄 sumar lo del 29 y 30).
- ✅ Anuncios con premio a menores de 13: se ofrecen cada vez que Roblox lo permite, sin buscar vacíos (protección infantil) → decisión del 2026-10-28.

**2026-10-29**
- ✅ Las miniaturas estaban malas → IA con referencias del juego (`vitrina-hits.md` §6).
- ✅ Íconos y sonidos: los mejores, estilo hit → `assets/ui/hud-icons` (36), `assets/ui/icons-flat` (59), `hit-vfx`, `hit-sfx`, `hit-voices`. 👤 Elegir las tomas de sonido.
- ✅ Evaluar VFX Studio → `conectores.md` (opcional, solo para diseñar).
- ✅ Herramientas: GPT Image y Nano Banana por API (no por suscripción), Meshy directo, Blender, ElevenLabs; ForgeGUI no. 👤 Claves (sección 8).
- ✅ "Se ve muy IA... analizá el HUD de todos los top hits y replicalo" → `hud-hits.md` y UIKit v3. Pidió una muestra → enviada y aprobada como modelo: "El juego tiene que verse 10 veces mejor que eso. Pero está bien como modelo." "Tené cuidado con los espacios y las cosas superpuestas."
- ✅ Íconos como los de los hits (sin dedos mal, no emoji 3D) → render propio + GPT Image 2.5. 🔄 Los que faltan, cuando esté la clave de OpenAI.
- ✅ Investigar Chicken Farm y Ride a Dino → `hud-hits.md`. 🔄 Sus mecánicas en el armador (recetas MergeTycoon y RunAndCatch).
- 👤 "Quizás habría que conectarte ChatGPT y Gemini" → claves `OPENAI_API_KEY` y `GEMINI_API_KEY` (sección 8).

**2026-10-30**
- ✅ Tabla de tareas visible.
- 🔄 "Qué tiene la app, qué falta?" → respondido; el plan está en la sección 4.
- 🔄 Armador genérico para cualquier top hit, terminar todo, analizarlo y reportar qué conectar → sección 4.
- 🔄 Traspaso completo y push en cada hito → este archivo.
- ✅ "Añadí también las cosas que hay que hacer después: qué API keys necesitás (como ChatGPT y Google), qué conectores hay que poner, etc." → `team/pendientes.md` (tarea #71; se repite en el reporte final).
- ✅ "Enumerame (únicamente) las tareas" → cuando pida la tabla, mostrar solo la lista de tareas, sin comentarios.
- ✅ "Cuando termines algo importante... mandame alguna pequeña foto" → sección 2.
- ✅ "Acordate de los push en los hitos" → push por hito y por bloque.
- ✅ "Terminá este hito y dejá todo listo para el traspaso... para que pueda continuar en el Claude de Luciano sin problemas y de la misma forma que hacemos acá" + "No continúes luego de esto" + "Dejá también las instrucciones para que pueda seguir trabajando" → se cortó después de los bloques Plots, Sell y Equip; este archivo quedó listo para retomar (sección 0).

## 4. Plan en curso

Mismo orden que la tabla de tareas. Un hito = varias filas; al cerrar cada hito se hace push.

| # | Tarea | Hito | Estado |
|---|---|---|---|
| 40 | Diseñar el armador: bloques, recetas, etiquetas del mapa (`skills/roblox-game-kits/references/bloques.md`) | 0 | ✅ |
| 41 | Base del armador: tipos, validación de recetas, cargador de bloques (servidor y cliente), ayudas del mundo, despachador de premios, estado del kit | 1 | ✅ |
| 42 | Bloque Units | 1 | ✅ (el inventario en ventana va con la UI de los bloques, #61) |
| 43 | Bloque Plots | 2 | ✅ |
| 44 | Bloque Belt | 2 | **sigue esta** (diseño en la sección 7) |
| 45 | Bloque Steal (hecho de cero) | 2 | pendiente |
| 46 | Bloque Rolls | 2 | pendiente |
| 47 | Bloque Merge | 2 | pendiente |
| 48 | Bloque Sell | 2 | ✅ servidor (su UI va en #61) |
| 49 | Bloque Equip | 2 | ✅ servidor (mascotas que siguen y su UI van en #61) |
| 50 | Bloque Stats | 3 | pendiente |
| 51 | Bloque Zones | 3 | pendiente |
| 52 | Bloque Stages | 3 | pendiente |
| 53 | Bloque Fishing | 3 | pendiente |
| 54 | Bloque Garden | 3 | pendiente |
| 55 | Bloque Search | 3 | pendiente |
| 56 | Bloque Wild | 3 | pendiente |
| 57 | Bloque Upgrades | 3 | pendiente |
| 58 | Bloque Tycoon | 3 | pendiente |
| 59 | Bloque Items | 3 | pendiente |
| 60 | Productos de cada bloque en la tienda | 4 | pendiente |
| 61 | UI de los bloques | 4 | pendiente |
| 62 | MapKit | 5 | pendiente |
| 63 | Nueve recetas con objetivos, misiones y mapa | 5 | pendiente |
| 64 | Rehacer `games/prueba` con el armador | 6 | pendiente |
| 65 | Skill del armador y skills que lo usan | 7 | pendiente |
| 66 | Skill de game feel | 7 | pendiente |
| 67 | Poner al día CLAUDE.md, ROADMAP, guía central, hits-2026, README, tablero | 7 | pendiente |
| 68 | Íconos que faltan, listos para generar | 7 | pendiente |
| 69 | Revisión completa | 8 | pendiente |
| 70 | Push y reporte final: qué conectar, claves, cuentas, pruebas | 8 | pendiente |
| 71 | Lista de lo que hay que hacer después: claves, conectores, cuentas y pruebas (`team/pendientes.md`) | 1 | ✅ (mantenerla al día) |

## 5. Bitácora de hitos

- **Antes del armador (hasta el 2026-10-30, commit `0a79d17`):** UI estilo hit completa (UIKit v3, HUD de PC y táctil, tienda en una lista, índice por zonas con premio validado, carteles y flechas en el mundo, ventanas revisadas para el teléfono). Chequeo en verde en GitHub.
- **Hito 0 (2026-10-30):** diseño del armador (`skills/roblox-game-kits/references/bloques.md`), este traspaso y la tabla de tareas #40 a #70.
- **Hito 1, parte 1 (2026-10-30): base del armador.** Chequeo en verde.
  - `shared/Kits/Types.luau` (tipos de la receta), `shared/Kits/Tags.luau` (etiquetas del mapa), `shared/Config/KitConfig.luau` (receta activa; `{ name = "None" }` = solo núcleo).
  - `shared/Lib/KitCheck.luau` + `tests/KitCheck.spec.luau` (12 casos) + `tests/KitKnown.luau` (listas del núcleo para los tests): revisa ids, rarezas, monedas, pases, impulsos, referencias entre bloques, bloques que necesitan otros (`NEEDS`), premios por ítem (`KitCheck.ITEMS`: Unit, Roll, Item, Upgrade, Zone, Stat, Rod, Tool, Seed, Garden:Skip, Merge:Skip, Stages:Revive) y efectos de mejoras (`KitCheck.EFFECTS`). `KitCheck.BLOCKS` = orden de arranque.
  - `server/Kits/Kits.luau`: cargador. `BLOCKS` vacío hasta que cada bloque se suma con `{ key, init, start, snapshot?, income?, items? }`. Revisa la receta con las listas reales y avisa con `warn("[Kits] ...")`; registra un solo `setItemHandler` (despacha por prefijo), `setIncomeProvider` (suma) y `setKitProvider` (`state.kit.<key>`). `Main.server`: `Kits.init()` después de `Remotes.start()`, `Kits.start()` justo antes de `DataService.start()`.
  - `server/Kits/KitWorld.luau`: `tagged`, `text`/`number`/`inherited` (atributos), `part`, `position`, `ancestor`, `humanoid`, `root`, `near` (con margen de 8 studs), `playerFromPart`, `sign` (cartel HitSign desde el servidor), `prompt` + `onPrompt` (mide distancia y frena repeticiones), `onTouch` (pads).
  - Cliente: `client/Kits/Kits.luau` (cargador de UI por bloque, `start(hud)`), `KitState.luau` (`get`/`on` de `state.kit.<bloque>`), `ActionBar.luau` (botones grandes abajo al centro; se reparten el ancho, atajo de teclado, mantener apretado repite). `Main.client` llama `Kits.start(hud)` (se fue `GameConfig.KIT`).
  - Núcleo que ahora lee la receta: `EconomyConfig` (suma `currencies`, color con `Color3.fromHex`), `ObjectiveConfig.CHAIN` (`objectives`), `RetentionConfig.QUESTS.pool` (`quests`), `GameConfig.LEADERSTATS` (`leaderstats`); `LeaderboardService` muestra estadísticas del armador (atributo del jugador con el id de la estadística). `World.luau`: los carteles HitSign se redibujan si el servidor cambia sus atributos.
  - `team/pendientes.md` (claves, conectores, cuentas y pruebas) a pedido del usuario.
- **Hito 1, parte 2 (2026-10-30): bloque Units.** Chequeo en verde.
  - `shared/Lib/UnitMath.luau` + `tests/UnitMath.spec.luau` (8 casos): clave del índice, multiplicador de mutación × tamaño × peso, ingreso/valor/poder, nombre ("Huge Gold Dragon"), artículo "a"/"an", rango de rareza, sorteos con suerte desde `luckyFrom` (`entries`), variantes y peso al azar, mejor probabilidad de cada unidad en los sorteos de la receta (`chances`) y de una variante (`variantChance`).
  - `server/Kits/Units.luau`: inventario en `data.kits.units`; `add(player, kind, { source, variant?, size?, weight?, roll?, force?, quiet? })` → `(unit?, motivo?, esNueva)`; `remove`, `transfer` (robos), `place` (espacio de la base), `equip`, `lock`; `income`/`value`/`power`/`name`/`rank`/`tier`; `rollVariants` (suerte = `BoostService.multiplier(player, "Luck")`); `max` = `maxInventory` + `Bonus.get(player, "inventory")`. Señales `Added`, `Removed`, `Changed` y `Signals.track` "UnitGot" y "RareFound" (Rare o más). Avisa al servidor desde `announceFrom` (o mutación ×5 o más), global si la rareza es `global`. Índice: total = unidades × mutaciones; zonas de `units.zones` con las claves Normal. Remote `LockUnit(uid, on)`. Premio "Unit:<unidad>[:<mutación>[:<tamaño>]]" siempre entregado (puede venir de Robux). Al cargar, lo que no está en la receta pasa a `orphans`.
  - `server/Kits/Bonus.luau`: bonos entre bloques sin `require` en círculo (`register`, `get`, `notify`, `Changed`).
  - `client/Kits/Units.luau`: piezas del índice (`Bus.handle("IndexEntries")`) con rareza, "1 in N" (sorteo × mutación) y lo que da; `Units.model(def)` busca `ReplicatedStorage.Assets.Units[def.model]`.
- **Hito 2, parte 1 (2026-10-30): bloque Plots.** Chequeo en verde.
  - Lógica pura con tests: `Lib/Ladder.luau` (escaleras de precios), `Lib/UnitPick.luau` (vender todo, grupos para fusionar, las mejores), `Lib/StealRules.luau` (motivos OWN, CARRYING, LOCKED, PROTECTED, RECENT, BEST, FULL), `Lib/RollRules.luau` (cantidades con pase, precio, gratis con espera, la mayor cantidad).
  - `shared/Kits/UnitModel.luau`: modelo de una unidad (asset de `ReplicatedStorage.Assets.Units` o bola del color de la unidad o de su mutación), escalado por tamaño, anclado, atributos Kind/Variant/Size y etiqueta `KitUnit`; `standOn(model, cframe)`.
  - `server/Kits/KitFx.luau`: un solo remote `KitFx` (nombre, datos) para efectos de los bloques; el cliente los reemite con `Bus.emit("Kit:<nombre>")`.
  - `server/Kits/Plots.luau`: base libre al cargar los datos (atributos `Owner`/`OwnerName` en el KitPlot, cartel "Leo's Base", reaparecer en `KitSpawn`), espacios abiertos = receta + comprados + pase (`slotPass`/`passSlots`) + `Bonus "slots"` (sin pasar los KitSlot que hay), modelos de lo colocado sobre cada espacio (`Plots.Shown` para Steal), cobro al pisar `KitCollectPad` (lo juntado vive en `data.kits.plots.stored` y el pad muestra "Collect $X"), cobro directo con `autoCollectPass` o `collect = "auto"`, compra de espacios en `KitSlotShop` o `BuySlot`, traba con `KitLockButton` o `LockBase` (láseres `KitBarrier`), colocar solo lo nuevo con `autoPlace`, remotes `PlaceUnit(uid, slot?)` y `StoreUnit(uid)`. Ingreso = lo colocado × `BoostService.multiplier(player, "Money")`. Avisa si Max Players supera las bases.
  - `World.luau`: si cambia solo el texto de un cartel, actualiza la etiqueta sin rehacerlo.
  - **Pendiente para Zones (#51):** las zonas del índice todavía no se cierran por zona del mundo: al hacer el bloque Zones, pasar `isUnlocked = function(player) return Zones.isUnlocked(player, zone.id) end` en `Units.start` (requerir Zones desde Units no arma círculo).
- **Hito 2, parte 2 (2026-10-30): bloques Sell y Equip, y el registro de zonas.** Chequeo en verde. Acá se cortó para el traspaso.
  - `server/Kits/Gates.luau`: `Gates.open(player, zona)` dice si el jugador tiene abierta una zona; el bloque Zones (#51) registra su función con `Gates.register`; sin Zones, todo abierto. Ya lo usan las zonas del índice (`Units.start`: `isUnlocked`), así que la nota de Zones de más arriba queda resuelta así.
  - `server/Kits/Sell.luau`: `Sell.value`, `Sell.units(player, uids)`, `Sell.all(player)` (con `Lib/UnitPick.sellAll`: ni cuidadas, ni equipadas, ni colocadas, por debajo de `keepFrom`); paga valor × `multiplier` × `BoostService.multiplier(player, stat or "Money")` en `currency` (o la principal); vende todo al pisar `KitSellPad` (con cartel "Sell All"); remotes `SellUnits(uids)` y `SellAll()`; con `anywherePass` (campo nuevo) y puestos en el mapa, desde la UI solo cerca de un puesto o con el pase. Señal "Sell" y efecto `KitFx` "Sold".
  - `server/Kits/Equip.luau`: espacios = `slots` + pase (`slotPass`/`passSlots`) + `Bonus "equip"`, tope `maxSlots`; poder = Σ `Units.power` de las equipadas, sumado como "add" a `equip.stat` en BoostService (proveedor registrado); lo colocado no se equipa; remotes `EquipUnit`, `UnequipUnit`, `EquipBest`; atributo del jugador `Equipped` = "kind|variant|size;..." para que el cliente dibuje las que siguen. Señal "Equip".
  - `Units.defs()` (todas las definiciones, para los sorteos) y textos nuevos de prompts y avisos en `UiText` (`PROMPT_BUY`, `PROMPT_STEAL`, `PROMPT_SELL`, `PROMPT_MERGE`, `PROMPT_OPEN`, `STEAL_ANNOUNCE`).
  - Tipos nuevos en `Kits/Types`: `SellState`, `EquipState`, `MergeState`, `RollResult`, `RollsState`.

## 6. Qué existe hoy (mapa)

- **Pipeline:** 11 skills en `skills/` (idea, diseño, UI, monetización, seguridad, QA, cumplimiento, publicación, campañas, métricas, live ops) y guías en `skills/_shared/`.
- **Herramientas** (`tools/`): `check.py`, `roblox_research.py`, `assets_import.py`, `roblox_upload.py`, `imagegen.py`, `thumbs.py`, `iconsheet.py`, `vfx_textures.py`, `ui_textures.py`, `flat_icons.py`, `render3d/`, `campaigns.py`, `analytics.py`.
- **Recursos:** `assets/index.json` (~60 paquetes) y `assets/LICENSES.md`.
- **Plantilla** (`template/`):
  - servidor: datos con bloqueo de sesión, remotes con validación y límite, economía multi-moneda, impulsos, premios, retención (diario, regalos por tiempo, misiones, ruleta, códigos, grupo, sin conexión, renacer, objetivos, índice por zonas), tienda (productos, pases, suscripción, regalos, anuncio con premio), eventos con horario, social;
  - cliente: HUD estilo hit (PC y táctil), ventanas, Juice, Sound, Effects, World (carteles y flechas);
  - tests de la lógica pura en `template/tests/`.
- **Armador** (en curso): receta en `template/src/shared/Config/KitConfig.luau`; base hecha (sección 5, hito 1).
- **Juego de prueba** `games/prueba`: hecho sobre la plantilla vieja (v1). Al usuario no le gustó: se rehace (tarea 64).

## 7. Detalles ya decididos del armador

Para seguir igual (completa `bloques.md`):

- **Carpetas:**
  - `template/src/shared/Kits/`: `Types.luau` (tipos de la receta), `Presets/<Receta>.luau` (recetas, solo datos);
  - `template/src/shared/Lib/`: la lógica pura de cada bloque, con su `tests/<X>.spec.luau`;
  - `template/src/server/Kits/`: un módulo por bloque y `Kits.luau` (el cargador);
  - `template/src/client/Kits/`: un módulo por bloque y `Kits.luau`;
  - `template/src/server/Map/MapKit.luau`.
- **Receta del juego:** `template/src/shared/Config/KitConfig.luau` devuelve la configuración (copiar una receta y editarla). Sin bloques, la plantilla corre sin juego, como antes.
- **Interfaz de cada bloque del servidor:**
  - `init(config)`: registra datos con `DataService.registerKit`, antes de `DataService.start`;
  - `start(config)`: remotes, prompts, etiquetas, bucles;
  - `snapshot(player)`: lo que ve el cliente, en `state.kit.<bloque>`;
  - `item(player, arg, count)`: premios "Bloque:arg".
- **El cargador del servidor:**
  - registra un solo `RewardService.setItemHandler` que reparte "Bloque:arg";
  - registra un `RewardService.setIncomeProvider` que suma el ingreso de los bloques (bases, tycoon);
  - registra el `PlayerStateService.setKitProvider`.
- **Objetivos y misiones:** la receta trae `objectives` y `quests`; `ObjectiveConfig` y `RetentionConfig` los usan si están.
- **Mapa:** todo por etiquetas de `CollectionService` (tabla de `bloques.md`); `MapKit` arma el mapa de la receta con esas etiquetas, de colores y estilo hit, y un mapa hecho a mano funciona igual.
- **Puertas de zonas:** las abre el cliente (choque local) y el servidor rechaza lo que se haga en una zona cerrada.
- **Tienda:** `ShopConfig` suma pases y productos con `kit = "<bloque>"`; la tienda oculta los de bloques apagados.
- **Monedas nuevas por receta** (Wins, Taps): en `currencies` de la receta, con el color en hex; `EconomyConfig` las suma a `CURRENCIES`.

### Piezas comunes que ya existen (usarlas, no rehacerlas)

- `server/Kits/KitWorld.luau` (etiquetas, atributos, prompts con distancia medida, pads, carteles), `Bonus.luau` (bonos de mejoras: `Bonus.get(player, efecto)`), `Gates.luau` (zonas abiertas), `KitFx.luau` (efectos al cliente: `KitFx.send(player, "Nombre", datos)`), `shared/Kits/UnitModel.luau` (modelo de cada unidad), `shared/Lib/*` puros con tests.
- Cada bloque del servidor: módulo `server/Kits/<Bloque>.luau` con `init(recipe)` (guarda su config y registra datos con `DataService.registerKit("<clave>", {...})`), `start(recipe)` (remotes, etiquetas, bucles), `snapshot(player)` y, si corresponde, `income` e `items` (`{ Prefijo = función }`); y una fila en `BLOCKS` de `server/Kits/Kits.luau` en el orden de `KitCheck.BLOCKS`.
- Remotes con `Remotes.onInvoke`/`onEvent` (validador por argumento + límite). Plata con `CurrencyService.add/spend` y su tipo de transacción (`Gameplay` lo ganado jugando, `Shop` lo gastado). Avances con `Signals.track(player, "<Evento>", n)` y `Signals.dirty(player)` al cambiar algo que el cliente ve.

### Diseño decidido de los bloques que faltan del hito 2 (seguirlo así)

- **#44 Belt** (`server/Kits/Belt.luau`, datos: ninguno):
  - cada `KitBelt`: cada `spawnEvery` s, si hay menos de `maxOnBelt` (8 si falta), sortear del `pool` con `UnitMath.entries` + `Rarity.roll` (suerte 1) y mutación/tamaño con `UnitMath.rollVariant` si la receta los usa;
  - modelo con `UnitModel.make` que avanza por el eje X de la parte, de punta a punta en `walkSeconds` (`PivotTo` con `Lerp` en un bucle de `RunService.Heartbeat`), y al llegar al final se borra;
  - precio = `def.price` o `def.value × (priceMultiplier or 1)`, × `UnitMath.multiplier` de su variante; prompt "Buy" con `ObjectText` "<Huge Gold Dragon> · $X" (`KitWorld.prompt` + `onPrompt`);
  - comprar: inventario con lugar (`Units.isFull`), `CurrencyService.spend(..., Shop, "Belt")`, `Units.add(player, kind, { source = "Belt", variant, size })`; el primero que compra se lo lleva; señal "UnitBought"; `KitFx` "Bought". Con `plots.autoPlace` va solo a la base.
- **#45 Steal** (`server/Kits/Steal.luau`, hecho de cero; datos: ninguno; estado en memoria):
  - en `Plots.Shown(owner, unit, model)` poner un prompt "Steal" (`HoldDuration = holdSeconds`) en el modelo; el cliente lo esconde a su dueño (#61);
  - al dispararlo, `StealRules.check` con: dueño, si ya lleva algo, `Plots.isLocked`, hora de entrada de la víctima (guardarla en `PlayerAdded`) contra `protectNewSeconds`, hora del último robo de esa unidad contra `recentSeconds`, si es la de más ingreso de esa base (`protectBest`) y `Units.isFull(ladrón)`; el ladrón necesita base propia;
  - **llevarla:** la unidad sigue en los datos de la víctima mientras se la lleva; copia visual soldada sobre la cabeza del ladrón; velocidad × `carrySpeed`; el modelo de la base queda semitransparente y la víctima recibe `KitFx` "BeingStolen";
  - **entregar:** cuando la raíz del ladrón entra en su propia base (punto dentro de `GetBoundingBox` del KitPlot, revisado cada 0.25 s): `Units.transfer(victima, ladron, uid, "Steal")`, se coloca si hay espacio, señales "Steal" (ladrón) y "Stolen" (víctima), aviso al servidor `UiText.STEAL_ANNOUNCE` si es rara, y la unidad nueva queda protegida `recentSeconds`;
  - **se cae** si el ladrón muere, se va, lo empujan o pasan 90 s, o si la víctima se va: vuelve todo como estaba;
  - **empujón:** remote `PushPlayer(userId)` con espera de 1.5 s: el objetivo dentro de `pushRange` (medido en el servidor) recibe `ApplyImpulse` en su raíz (la documentación dice que el servidor puede hacerlo en partes del cliente con dueño automático) y suelta lo que lleva; señal "Push";
  - **velocidad:** para no pisarse con el bloque Stats (`walkSpeed`), usar un factor por fuente: agregar a `KitWorld` un `setSpeedFactor(player, fuente, factor)` que aplique `WalkSpeed = base × Π factores` (base = atributo `BaseWalkSpeed` del jugador o 16); Stats pondrá `BaseWalkSpeed`.
- **#46 Rolls** (`server/Kits/Rolls.luau`, datos `{ nextFree = { [id] = os.time } }`):
  - remote `RequestRoll(id, count, auto?)`: id con `Validate.oneOf`, `count` entero 1–100; `RollRules.amount` con `ShopService.ownsPass`; si `auto`, pedir `rolls.autoPass` si existe;
  - `paidRandom` y atributo `PaidRandomRestricted` del jugador → rechazar "RESTRICTED"; zona con `Gates.open`; si hay `KitRollStation` con ese `Roll` en el mapa, estar a menos de 20 studs de una;
  - lugar en el inventario para `count`; cobrar `RollRules.cost` con `CurrencyService.spend(..., Shop, "Roll_<id>", moneda)` o usar la gratis (`RollRules.freeReady`, después `nextFree = ahora + cooldown`);
  - cada tirada: `UnitMath.entries(def.pool, Units.defs(), Units.rarities(), units.luckyFrom)` + `Rarity.roll` con suerte `BoostService.multiplier(player, luckStat or "Luck")`, y `Units.add(player, id, { source = "Roll", roll = true })`;
  - devolver la lista de `RollResult` y mandarla con `KitFx` "Rolled" (animación del huevo en el cliente); señales "Roll" y "Hatch";
  - premio `"Roll:<id>"` = tiradas gratis de esa (sin precio, espera ni distancia; `force` porque puede venir de Robux).
- **#47 Merge** (`server/Kits/Merge.luau`, datos `{ pending = { kind, variant?, size?, readyAt }? }`):
  - remote `MergeUnits(kind, variant?)`; con `machine`, cerca de un `KitMergeMachine` (si hay en el mapa); una fusión pendiente a la vez ("BUSY");
  - modo `tier`: `count` unidades del mismo `kind` (cualquier variante, `UnitPick.group(list, kind, nil, count)`) → 1 del `tier` siguiente; con `mutationChance`, la nueva sale con mutación al azar ("MAX" si no hay nivel siguiente);
  - modo `variant`: `count` iguales de la mutación actual (`UnitPick.group(list, kind, actual, count)`) → 1 de la siguiente en `variantChain`, con el tamaño de la primera;
  - se sacan las usadas (`Units.remove(..., "Merge")`); el resultado llega ya o a `readyAt = ahora + seconds` (un bucle de 1 s lo entrega solo); premio `"Merge:Skip"` = listo ya;
  - señal "Merge" y `KitFx` "Merged".

## 8. Lo que depende de las personas

Lista completa y con casillas en **`team/pendientes.md`** (pedido del usuario del 2026-10-30: "que api keys necesitás, qué conectores hay que poner, etc."). Mantenerla al día en cada hito y repetirla en el reporte final (#70). En resumen:

- **Claves** (variables de entorno de cada PC o *Network secrets* del entorno de la nube; nunca en el repo ni en el chat): `OPENAI_API_KEY` (obligatoria para íconos y miniaturas), `GEMINI_API_KEY` (recomendada), `MESHY_API_KEY` (plan Pro), `ROBLOX_OPEN_CLOUD_API_KEY` + `ROBLOX_CREATOR_GROUP_ID`, `ROBLOX_ANALYTICS_API_KEY` y `ROBLOX_ADS_API_KEY`. En la nube no hay ninguna cargada (revisado el 2026-10-30).
- **Conectores:** MCP de Roblox Studio, Rojo, MCP de Blender y MCP de Meshy en cada PC; ElevenLabs, Higgsfield y GitHub ya conectados en la cuenta de Leonel (Luciano los conecta en claude.ai). Meshy no arranca en la nube (`.mcp.json` usa `cmd`).
- **Roblox:** grupo dueño (`GameConfig.GROUP_ID`), 2FA y documento verificado, productos y pases con sus ids en `ShopConfig`, suscripción en Robux, anuncio con premio recién cuando se cumplan sus requisitos, cuestionario de madurez, traducción automática, *Max Players* = bases de la receta.
- **Pruebas en Studio:** UI v3 (Luciano) y, después, los bloques del armador y el juego de prueba rehecho.
- **Decisiones:** tomas de sonido, receta del primer juego, PR de la rama a `main`.

## 9. Trampas aprendidas (no repetir)

- **`UIAspectRatioConstraint` con un eje en 0:** la documentación no dice qué hace (puede dar tamaño 0). En listas con scroll, `UIKit.fitHeight`, `UIKit.row` o `UIKit.grid`.
- **`UISizeConstraint.MinSize` en botones dentro de ventanas:** encima cosas. Los 44 px se logran por diseño.
- **`UIStroke`:** en `UIKit` va con `ScaledSize`, como fracción del lado menor (0.05), nunca en píxeles.
- **Teléfono:** nada en la zona del joystick (≈ 41 % izquierdo, desde el 43 % del alto) ni en la del salto.
- **Sintaxis de Luau:** una línea que empieza con `(` después de otra que termina en `)` es sintaxis ambigua y luau-lsp la marca como error. Usar una variable local o empezar con `;`.
- **luau-lsp y tablas:** un literal con tipos mezclados (`{ child, child:FindFirstChild("X") }`) falla en modo estricto. Anotar `{ Instance? }`.
- **luau-lsp y listas opcionales:** `for _, x in lista or {} do` falla ("Cannot call a value of type {X} in union"). Usar `lista or ({} :: { X })` o, mejor, `local l = lista; if l then for ... end end`. Lo mismo con un mapa (`{ [string]: F }`).
- **`pcall` de una función sin retorno:** `local ok, err = pcall(f, x)` falla ("Function only returns 1 value"). Castear: `pcall(f :: (T) -> ...any, x)`.
- **Literales en los tests:** listas de tablas con campos distintos (una con `reward`, otra sin) se infieren mal; castear la lista (`:: { Types.IndexZone }`). Y `local a, b = {}, {}` que después reciben números: anotar `{ number }`.
- **Tests sin Roblox:** el CLI de Luau no tiene `Color3`, `Vector3` ni servicios. Lo que se prueba (recetas, `Lib/`) va sin tipos de Roblox.
- **Glifo de Robux** (`utf8.char(0xE002)` con Builder Sans): sale del DevForum, no de la documentación. Confirmar en Studio.
- **En la nube de Claude:**
  - create.roblox.com está bloqueado: la documentación sale del repo `Roblox/creator-docs`, por `raw.githubusercontent.com`;
  - las imágenes de esa documentación están en Git LFS y se bajan de `media.githubusercontent.com`;
  - Playwright está instalado global en `/opt/node22/lib/node_modules`.
