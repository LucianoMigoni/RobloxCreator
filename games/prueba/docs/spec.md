# Spec: Steal & Fuse Critters (games/prueba)

Fecha: 2026-10-26 · Autor: Luciano (con Claude) · Concepto de origen: `docs/concepto.md` (Roba y Fusiona, 86/100) · Estado: **aprobada** por Luciano (2026-10-26) · Hito 1 hecho

Los nombres y textos que ve el jugador están en inglés, tal cual van a verse (entre comillas o en `código`). El resto es interno, en español.

## Referencia y diferenciación
- **Referencias:** *Steal a Brainrot*, *Steal An Egg* (estilo de robar y colocar) y *Grow a Garden* (colocar y ganar sin estar conectado). Se analizaron con su página pública y los Charts del 2026-10-26 (datos en `docs/concepto.md`). **Todavía no se jugaron:** antes del hito 1, una persona juega 15 min cada una y anota el ritmo real. Sin exploits ni decompiladores.
- **Se toma** (mecánicas y ritmos, no arte):
  - cinta compartida de criaturas que se compran con monedas;
  - base propia con pedestales que pagan por segundo;
  - entrar a otra base, agarrar una criatura y llevarla a la tuya;
  - traba de base temporal;
  - rarezas y mutaciones;
  - renacer con multiplicador;
  - servidores chicos.
- **No se toma:** títulos, logos, thumbnails, mapas, modelos, place files, nombres ni diseños de personajes. **No hay personajes brainrot** (decisión del 2026-10-26).
- **Giro propio:** la **fusión**: dos *critters* del mismo nivel dan uno del nivel siguiente, con probabilidad de mutación visible. Robar sirve para completar el par que te falta.

## Idioma y público
Todo lo que ve el jugador va en inglés, para público internacional (`CLAUDE.md`):
- textos en `Config/UiText.luau`;
- nombres de *critters* y productos en `Config/GameplayConfig.luau` y `Config/ShopConfig.luau`.

Sin texto dentro de imágenes. El juego sale primero solo para 16+ (`team/decisiones.md`); el contenido es apto para todas las edades.

## Loop central
- **Minuto a minuto:** comprar en la cinta → colocar en un pedestal → juntar monedas en el *collect pad* → fusionar pares → (opcional) robar el que te falta.
- **Progresión:** nivel máximo de *critter* alcanzado, monedas por segundo, álbum y renacimientos (multiplicador permanente).
- **Primeros 10 / 30 / 60 s:**
  - 10 s: apareces en tu base, junto a la cinta, con 10 monedas; compras el primer *Pebble Pup*.
  - 30 s: ya genera; juntas monedas y compras el segundo.
  - 60 s: primera fusión, guiada por el onboarding → *Mossling* (×3 de ingreso).
- **Motivos para volver:**
  - D1: ganancias sin estar conectado y la fusión que quedó a medias.
  - D2–7: completar el álbum (8 niveles × 3 variantes) y llegar al primer renacimiento.
  - D8–28: renacimientos acumulados y un *critter* nuevo por semana (`roblox-liveops`).
- **Con amigos:** robarse entre amigos, defender la base juntos y competir por la cinta compartida. Servidores de 8.

## Critters
Un nivel por *critter*. Dos del mismo nivel se fusionan en el siguiente. Ingreso ×2,5 por nivel: fusionar siempre conviene, porque da más que dos sueltos y libera un pedestal.

| Nivel | Nombre en el juego | Monedas/s | Precio en la cinta | Peso en la cinta normal | Peso en la cinta VIP |
|---|---|---|---|---|---|
| 1 | "Pebble Pup" | 1 | 10 | 70 % | — |
| 2 | "Mossling" | 3 | 60 | 25 % | 60 % |
| 3 | "Bubblebug" | 7 | 400 | 5 % | 30 % |
| 4 | "Zapfrog" | 18 | — (fusión) | — | 10 % (precio 2 500) |
| 5 | "Cloud Kitty" | 45 | — | — | — |
| 6 | "Lava Lizard" | 110 | — | — | — |
| 7 | "Star Owl" | 275 | — | — | — |
| 8 | "Crystal Dragon" | 700 | — | — | — |

**Mutaciones** (solo al fusionar; probabilidades **siempre visibles** en la pantalla de fusión):

| Mutación | Efecto | Probabilidad base | Con "Lucky Fuse" |
|---|---|---|---|
| "Normal" | ×1 | 94 % | 82 % |
| "Gold" | ×2 ingreso | 5 % | 15 % |
| "Rainbow" | ×5 ingreso | 1 % | 3 % |

Si alguno de los dos *critters* fusionados tenía mutación, el resultado conserva la mejor de las dos y además tira su probabilidad (nunca se pierde una mutación al fusionar).

## Mecánicas
Todos los números viven en `src/shared/Config/GameplayConfig.luau`, que se crea en el hito 1. Los cálculos puros (ingreso con multiplicadores, fusión con mutación, ganancia sin conexión, elección de nivel en la cinta) van en módulos sin Roblox, cada uno con su `tests/*.spec.luau`.

| Id | Mecánica | Reglas y números (→ `GameplayConfig`) | Decide el servidor | Remote (validadores, límite) | Datos guardados |
|---|---|---|---|---|---|
| M1 | Asignación de base | 8 bases por servidor. Al entrar se te asigna una libre y apareces en ella. Cada base tiene 8 pedestales, un *collect pad*, un fusionador y una barrera de traba | Qué base; nada lo pide el cliente | — | — |
| M2 | Cinta compartida | Aparece un *critter* cada 4 s según los pesos de la tabla; camina 20 s y desaparece. Todos ven la misma cinta y gana el primero que compra | Spawn, nivel (al azar con los pesos; se juega con monedas, no con Robux), quién compra | — (`ProximityPrompt` "Buy" en cada critter, manejado en el servidor; implementado así en el hito 1) | — |
| M3 | Comprar | Precio de la tabla. Requiere pedestal libre y estar a ≤ 14 studs de la cinta. El *critter* camina a tu base y se coloca solo | Saldo (`CurrencyService.spend`), pedestal libre, distancia, que el slot exista y siga libre | (M2) | `critters` |
| M4 | Ingreso | Cada pedestal acumula `monedas/s × mutación × multiplicador` (renacer, pases) en su contador | Todo el cálculo; tick de 1 s | — | — |
| M5 | Juntar | Pisar el *collect pad* de tu base pasa lo acumulado a tu saldo | `Touched` en el servidor: dueño del pad, monto | — | `coins` |
| M6 | Fusionar | En el fusionador (`ProximityPrompt`) eliges un nivel con al menos 2 *critters*; se consumen 2 (los "Normal" primero) y sale 1 del siguiente nivel con tirada de mutación | Que tenga el par, nivel < 8, estar en su base, tirada | Hito 1: `ProximityPrompt` "Fuse" en el servidor, que fusiona el par de nivel más bajo. Hito 4: elegir nivel con `FuseCritters(tier)`: `Validate.number{min=1,max=7,integer=true}`, 2/s | `critters`, `album` |
| M7 | Robar | En una base ajena sin traba, mantienes 1,5 s el `ProximityPrompt` de un pedestal → cargas el *critter* (velocidad ×0,7, 1 a la vez) → si tocas tu base, va a un pedestal libre; si no tienes lugar, el prompt no aparece | Que la base no esté trabada ni protegida, que no sea el *critter* más valioso del dueño, distancia (la valida el prompt y se repite en el servidor), pedestal libre | — (`ProximityPrompt.Triggered` se maneja en el servidor) | `critters` de los dos jugadores |
| M8 | Empujar | El dueño o un amigo presente toca "Push" a ≤ 10 studs de quien carga un *critter* robado → se cae y vuelve a su pedestal. Enfriamiento de 2 s. Empuje cómico, sin daño | Distancia, que el objetivo cargue algo robado de esa base | `Push()`: sin argumentos, 1 cada 2 s | — |
| M9 | Traba de base | "Lock" cierra la barrera 60 s; después hay 90 s de enfriamiento | Enfriamiento y duración (con pase: 120 s) | `LockBase()`: sin argumentos, 1/s | — |
| M10 | Protecciones gratis | Un jugador nuevo no puede ser robado sus primeros 300 s. El *critter* más valioso de cada jugador no se puede robar. Un *critter* recién robado no se puede volver a robar por 30 s | Todo | — | — |
| M11 | Ganancias sin conexión | Al volver: 50 % del ingreso por segundo × el tiempo ausente, con tope de 2 h. Se cobra en el *collect pad* | Cálculo con `os.time()` del servidor, nunca la hora del cliente | — | `lastSeen` |
| M12 | Renacer | Requiere tener un "Lava Lizard" (nivel 6). Reinicia monedas y *critters*, y suma +50 % de ingreso permanente por renacimiento | Requisito, reinicio, multiplicador | `Rebirth()`: invoke sin argumentos, 1 cada 5 s | `rebirths` |
| M13 | Álbum | Registra cada nivel × mutación que conseguiste (24 entradas) | Al comprar, fusionar o robar | — (viaja en el estado) | `album` |

Los remotes se crean con `Remotes.onEvent`/`onInvoke` en el servicio que los usa (`roblox-security`). El cliente solo pide; el estado vuelve por `StateChanged`.

## Datos nuevos (`DEFAULT_DATA` en `Config/DataConfig.luau`)
```lua
critters = {} :: { { uid: string, tier: number, mutation: string, pedestal: number } },
album = {} :: { [string]: boolean }, -- "3_Gold" = true
rebirths = 0,
lastSeen = 0, -- os.time() del servidor al salir
shieldUntil = 0, -- producto "Shield"
starterPackGranted = false,
```
`Reconcile` completa estos campos en los jugadores existentes. Se suman a `Types.PlayerSnapshot`.

## Economía
| Fuente / sumidero | Monto | Frecuencia | Transacción de analíticas |
|---|---|---|---|
| Collect pad | ingreso acumulado | cuando el jugador pisa el pad (~cada 15–30 s al principio) | Gameplay, "Collect" |
| Ganancias sin conexión | hasta 2 h al 50 % | 1 vez por sesión | Gameplay, "Offline" |
| Onboarding completo | +100 | 1 vez | Onboarding (plantilla) |
| Comprar en la cinta | −10 / −60 / −400 / −2 500 | según el jugador | Shop, "Conveyor" |
| Coin Packs (Robux) | ver Monetización | — | IAP (plantilla) |

Tiempo hasta la primera compra: unos 10 s (arranca con 10 monedas). Primera fusión: menos de 60 s. Primer "Lava Lizard" y renacimiento: entre 25 y 40 min (estimado; se ajusta con el prototipo y los eventos de economía).

## Onboarding (`Config/OnboardingConfig.STEPS`)
| Paso | Fuente | Qué enseña | Texto en el juego |
|---|---|---|---|
| "Joined" | server | — | — |
| "BoughtFirstCritter" | server | Comprar en la cinta | "Buy a critter from the belt!" |
| "CollectedCoins" | server | Juntar en el pad | "Step on the pad to collect coins" |
| "FirstFuse" | server | Fusionar | "Fuse two of the same critter!" |
| "FirstSteal" | server | Robar (opcional en el primer minuto) | "Steal a critter from another base!" |

`COMPLETION_REWARD` = 100. Los pasos que todavía no tienen texto de ayuda se muestran con una flecha y una sola línea, sin pantallas de tutorial.

## UI (para `roblox-ui-designer`)
| Pantalla | Botones / elementos (texto en el juego) | Remote |
|---|---|---|
| HUD | Monedas arriba ("Coins") con monedas/s; botones laterales "Shop", "Album" y "Rebirth" | — |
| Acciones junto al salto | "Lock" (con enfriamiento visible) y "Push" (solo aparece si hay un ladrón cerca) | `LockBase`, `Push` |
| Fusionador (popup) | Una fila por nivel con "2/2"; botón verde "FUSE"; probabilidades "Normal 94% · Gold 5% · Rainbow 1%" siempre visibles | `FuseCritters` |
| Cinta | Etiqueta 3D sobre cada *critter* (nombre, "+3/s", precio) y prompt "Buy" | `BuyCritter` |
| Robo | Prompt "Steal" (mantener 1,5 s); aviso al dueño: "Someone is stealing your Mossling!" | — |
| Álbum (popup) | Grilla de 8 × 3 con siluetas de lo que falta | — |
| Renacer (popup) | Qué se pierde y qué se gana: "+50% coins forever" | `Rebirth` |
| Tienda (popup) | Pases y productos con su efecto exacto | plantilla (`ShopService`) |

## Monetización (para `roblox-monetization`)
Pagar da ventajas importantes, dentro de las reglas oficiales (`skills/roblox-monetization`). Los precios en Robux los fija `roblox-monetization` en la fase 4. Los ids se crean en el Creator Dashboard (0 = pendiente).

| Producto | Tipo | Efecto exacto (texto en la tienda) | Regla oficial que cumple |
|---|---|---|---|
| "2x Coins" | Game Pass | "Doubles all coins your critters make" | Efecto exacto, aplicado con `ShopService.hasPass` |
| "+4 Pedestals" | Game Pass | "4 more pedestals in your base" | — |
| "Long Lock" | Game Pass | "Your base lock lasts 120s instead of 60s" | La traba gratis se mantiene |
| "Fast Thief" | Game Pass | "Carry stolen critters 1.5x faster" | — |
| "Auto Collect" | Game Pass | "Coins go straight to your balance" | — |
| "VIP" | Game Pass | "VIP belt with Mosslings, Bubblebugs and Zapfrogs + 1.5x coins" | Pesos de la cinta VIP visibles en la cinta |
| "Starter Pack" | Game Pass (una sola vez) | "500 coins + 1 Bubblebug" | Se otorga una vez (`starterPackGranted`) |
| "Coin Pack" S / M / L | Developer Product | cantidad exacta de monedas | `ProcessReceipt` (plantilla) |
| "Buy a Zapfrog" | Developer Product | "Get 1 Zapfrog now" (compra directa, sin azar) | Precio a la vista |
| "Shield (15 min)" | Developer Product | "Nobody can steal from you for 15 minutes" | Duración exacta, guardada en `shieldUntil` |
| "Lucky Fuse x10" | Developer Product | "Your next 10 fuses: Gold 15% · Rainbow 3%" | **Aleatorio pago:** todos los resultados y probabilidades a la vista, y `PolicyService` (`ArePaidRandomItemsRestricted` → no se ofrece) |

Nada de cuentas regresivas falsas: el temporizador de la cinta y el de la traba son reales.

## Assets
| Asset | Fuente | Triángulos (máx.) | Licencia |
|---|---|---|---|
| 8 *critters* (uno por nivel, con versiones Gold y Rainbow por material) | Blender MCP, nuevos | ≤ 1 500 c/u | propio |
| Pedestal, *collect pad*, fusionador, cinta, barrera de traba | Blender MCP o partes de Studio | ≤ 800 c/u | propio |
| Moneda | Catálogo: `coin-gold-lowpoly-01` (falta importarla y subirla) | 288 | propio |
| Mapa (8 bases en círculo alrededor de la cinta) | Partes de Studio con el MCP | — | propio |

El hito 1 usa cubos grises: los modelos llegan en el hito 6. Todo asset nuevo se registra en `assets/index.json` + `LICENSES.md` en el mismo cambio.

## Métricas objetivo
- **Embudo** (Creator Analytics → Funnels): % que llega a "BoughtFirstCritter", "CollectedCoins", "FirstFuse" y "FirstSteal". Objetivo inicial (hipótesis del hub, a ajustar con datos): más del 80 % compra en el primer minuto y más del 60 % fusiona.
- **Algoritmo:** bounce < 60 s, play days D2–7 y D8–28, co-play days, spend days (`skills/_shared/algoritmo-descubrimiento.md`).
- **Economía:** monedas creadas contra gastadas por fuente (eventos de `CurrencyService`); tiempo hasta el primer renacimiento.

## Plan de construcción (cada hito jugable y con `tools/check.py` en verde)
1. **Loop gris:**
   - bases (M1), cinta (M2), comprar (M3), ingreso y pad (M4, M5), fusión sin mutaciones (M6);
   - `GameplayConfig.luau` con todos los números;
   - módulos puros con tests (ingreso, fusión, pesos de la cinta).
   - **Prueba de la hipótesis del concepto:** ¿la fusión se entiende sola en el primer minuto?
2. **Robo:** robar, empujar, traba y protecciones (M7–M10), con la auditoría y la prueba de abuso de `roblox-security`; prueba con dos cuentas en Studio.
3. **Progresión:** mutaciones, ganancias sin conexión, renacer y álbum (M11–M13); onboarding.
4. **UI:** `roblox-ui-designer` con las pantallas de arriba, en el A06, el iPhone y la tablet.
5. **Monetización:** pases y productos, probabilidades visibles y `PolicyService`; auditoría de `roblox-monetization`.
6. **Arte y mapa:** *critters* y piezas con Blender, mapa con el MCP, rendimiento con `perf_snapshot` (`roblox-qa-performance`).

## Riesgos y cumplimiento
- **Contenido** (`roblox-compliance`): sin violencia (el empuje es cómico y no hace daño), sin sangre, sin texto libre de jugadores (no hay campos de texto). Etiqueta esperada: apta para todas las edades; se confirma con el cuestionario de madurez.
- **Aleatorio pago:** solo "Lucky Fuse", con probabilidades y `PolicyService`. La cinta y la fusión base son azar con monedas del juego, y sus probabilidades también se muestran.
- **Frustración por robo:** M10, más medir el bounce de los que fueron robados en su primera sesión.
- **Economía:** inflación por ganancias sin conexión y multiplicadores; se mira en los eventos de economía después de cada hito.
- **Rendimiento:** hasta 96 *critters* visibles (8 bases × 12 pedestales); ≤ 1 500 triángulos cada uno y `StreamingEnabled` activado. Es el valor que tenía el lugar de prueba del 2026-10-26; la plantilla no lo fija, así que se verifica en el place del juego.
- **Seguridad:** cada remote con validadores y límite; robar y juntar se deciden en el servidor (prompts y `Touched`); el cliente nunca informa montos.

## Verificación por mecánica (se completa en el playtest de cada hito)
| Id | Resultado | Fecha | Nota |
|---|---|---|---|
| M1 Asignación de base | OK | 2026-10-26 | 8 bases de cubos grises en anillo; apareces en la tuya, mirando a la cinta |
| M2 Cinta compartida | OK | 2026-10-26 | Un critter cada 4 s; cruza en 20 s y desaparece |
| M3 Comprar | OK | 2026-10-26 | Con E en el prompt: cobra 10, coloca en el primer pedestal libre; sin saldo no compra. Falta que el critter camine hasta la base (pulido, hito 6) |
| M4 Ingreso | OK | 2026-10-26 | El pedestal muestra lo acumulado ("15 coins" a los ~15 s con un Pebble Pup) |
| M5 Juntar | OK | 2026-10-26 | Pisar el pad pasa lo acumulado al saldo y deja el pedestal en cero |
| M6 Fusionar | OK (versión del hito 1) | 2026-10-26 | 2 Pebble Pup → Mossling +3/s; lo no juntado pasa al pedestal del resultado. Elegir nivel: hito 4 |
| Onboarding | OK | 2026-10-26 | Joined → BoughtFirstCritter → CollectedCoins → FirstFuse, con +100 al completar (saldo 116) |
| M7–M13 | pendiente (hitos 2 y 3) | | |

Prueba del hito 1: Studio con `rojo serve` de `games/prueba` en un lugar sin publicar (los datos no se guardan), playtest con el MCP: `character_navigation` + tecla E, estado leído desde `execute_luau` Server, consola sin errores de script. Está la cinta compartida, pero solo se probó con un jugador.
