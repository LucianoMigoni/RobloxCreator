---
name: roblox-security
description: Asegura un juego de Roblox con servidor autoritativo. Cada RemoteEvent/RemoteFunction pasa por validación de argumentos y límite de frecuencia, la economía se calcula en el servidor y los datos usan bloqueo de sesión. Usar al crear o cambiar remotes, en la fase 5 del pipeline, antes de publicar y al revisar PRs con código de servidor.
---

# roblox-security

## Objetivo
Que ningún cliente pueda dar monedas, ítems, daño ni progreso que el servidor no haya decidido. Que un fallo de red no pierda ni duplique datos. Las piezas viven en la plantilla, que es la fuente única: este skill dice cómo usarlas y cómo auditarlas.

| Pieza | Archivo |
|---|---|
| Registro de remotes con validación y límite | `template/src/server/Net/Remotes.luau` |
| Validadores (NaN, infinito, UTF-8, topes) | `template/src/server/Net/Validate.luau` |
| Límite de frecuencia (balde de fichas) | `template/src/server/Net/RateLimiter.luau` |
| Acceso del cliente a los remotes | `template/src/shared/Net.luau` |
| Datos con bloqueo de sesión | `template/src/server/Data/DataService.luau` y `SessionLock.luau` |
| Tests de la lógica pura | `template/tests/*.spec.luau` (los corre `python tools/check.py`) |

## Cuándo usarlo
- Fase 5 del pipeline, y cada vez que otra fase cree o cambie un remote (UI, tienda, monetización, live ops).
- Antes de publicar un update.
- Al revisar un PR que toca `src/server` o agrega remotes.

**Lo llaman:** `roblox-ui-designer` (cada botón que dispara un remote), `roblox-monetization` (compras), `roblox-game-cloner` (mecánicas nuevas).
**Llama a:** `roblox-qa-performance` para la prueba en Studio en móvil.

## Flujo

1. **Inventario.** Listar todos los remotes del juego (buscar `Remotes.onEvent`, `Remotes.onInvoke` y `Remotes.toClient` en `src/server`). En `games/<juego>/docs/seguridad.md`, una fila por remote: nombre, dirección, argumentos y validadores, límite, qué hace y qué verifica el handler.
2. **Definir cada remote con `Remotes`**, nunca con `Instance.new("RemoteEvent")` ni `OnServerEvent` sueltos (`tools/check.py` lo marca como error):
   ```lua
   Remotes.onInvoke("RequestPurchase", {
   	args = { Validate.oneOf(ShopConfig.ITEM_IDS) },
   	rate = { count = 3, perSeconds = 1 },
   }, function(player, itemId)
   	-- reglas del juego: saldo, distancia a la tienda, que no lo tenga ya...
   end)
   ```
   - Validadores estrictos: ids de una lista (`oneOf`) antes que texto libre; números con `min`/`max`/`integer`; texto siempre con `maxLength`.
   - Límite según el uso: acción de botón 2–5/s, acción continua (golpear, recolectar) hasta ~20/s, compra 1–3/s.
   - Lo que el validador no puede saber lo verifica el handler: permiso, distancia, estado (vivo, en partida), saldo, cooldown. Ver `references/threats.md`.
   - El cliente usa `Net.event(nombre)` / `Net.func(nombre)` y solo muestra lo que el servidor confirma.
3. **Servidor → cliente** con `Remotes.toClient`. Si un cliente lo dispara, se rechaza y se registra.
4. **ProximityPrompt, ClickDetector y DragDetector** no son remotes pero se disparan igual desde cualquier distancia: en su handler, verificar que esté habilitado, que el personaje exista y esté cerca, y aplicar límite (`RateLimiter.new`).
5. **Datos:** todo lo persistente pasa por `DataService`. Nada que valga Robux se da si `DataService.canSave(player)` es falso.
6. **Chequeo estático:** `python tools/check.py` sin errores (tests, tipos, reglas).
7. **Prueba en Studio** (con el MCP, nombres en `skills/_shared/mcp-tools.md`):
   1. `list_roblox_studios` → `start_stop_play` (iniciar).
   2. `execute_luau` con datamodel **Server** y el contenido de `scripts/audit_remotes.luau`: sin ERROR.
   3. `execute_luau` con datamodel **Client** y `scripts/abuse_test.luau`: sin ERROR. Después `get_console_output`: deben aparecer los `[Remotes] ... rechazado` y ningún error de script. Y el estado del jugador (monedas, inventario) no debe haber cambiado.
   4. Datos. Necesita un lugar publicado con **File → Experience Settings → Security → Enable Studio Access to API Services**. Studio usa las mismas DataStores que el juego publicado: activarlo **solo en una copia de prueba**, nunca en el juego en vivo. Jugar, cambiar algo, salir y volver a entrar: el cambio persiste. Con dos ventanas de Studio jugando el mismo lugar a la vez, la segunda debe quedar en "errored" mientras la primera tenga el bloqueo.
8. **Escribir `docs/seguridad.md`** (inventario + resultados de 6 y 7) y mostrarlo al usuario. En el PR, pegar los reportes.

## Checklist
- [ ] Todo remote se crea con `Remotes` (`tools/check.py` en verde).
- [ ] Cada argumento tiene validador; textos con tope; ids de una lista cuando se puede.
- [ ] Cada remote cliente→servidor tiene un límite de frecuencia acorde a su uso.
- [ ] Los handlers verifican permiso, distancia, estado y saldo en el servidor.
- [ ] El cliente nunca modifica monedas, inventario ni progreso; solo pide y muestra.
- [ ] Compras solo en `ProcessReceipt` y solo con `DataService.canSave` verdadero.
- [ ] ProximityPrompts, ClickDetectors y DragDetectors con verificación en el handler.
- [ ] `audit_remotes.luau` y `abuse_test.luau` sin ERROR; la consola muestra rechazos y no errores.
- [ ] Persistencia y bloqueo de sesión probados en Studio.
- [ ] `docs/seguridad.md` actualizado.

## Límites
- No es un anti-cheat de movimiento (velocidad, teletransporte, noclip): eso depende de cada juego y la guía oficial no tiene una solución universal. Ver `references/threats.md`.
- No ofusca ni esconde código del cliente: todo lo que se replica se puede leer. La seguridad está en el servidor.
- La consecuencia ante abusos (expulsar, banear) la decide cada juego con `Remotes.rejections(player)`. La plantilla solo descarta y registra, como recomienda la guía oficial.
