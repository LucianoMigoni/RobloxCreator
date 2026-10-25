# Amenazas y defensas

Verificado el 2026-10-25 en la documentación oficial (repo `Roblox/creator-docs`):
`/scripting/security/client-server-boundary`, `/scripting/security/server-side-detection`,
`/scripting/security/network-ownership` y `/cloud-services/data-stores/player-data-purchasing`.

El supuesto de partida: un exploiter puede disparar **cualquier** RemoteEvent o RemoteFunction, en cualquier momento, con **cualquier** argumento. También puede activar ProximityPrompts, ClickDetectors y DragDetectors a cualquier distancia y aunque estén deshabilitados.

| Amenaza | Qué hace el exploiter | Defensa | Dónde está en la plantilla |
|---|---|---|---|
| Tipo cambiado | Manda texto donde va un número, o una tabla que imita una `Instance` | Validar el tipo de cada argumento | `Validate.number/string/instance/...` |
| NaN | `0/0` es de tipo number y falla **toda** comparación: pasa chequeos de rango y saldo | Rechazar `n ~= n` | `Validate.number` |
| Infinito | `math.huge`, `-1/0`: monedas infinitas, cuentas rotas | Rechazar ±infinito | `Validate.number` |
| Texto gigante o UTF-8 inválido | Satura memoria, CPU y la DataStore (que solo acepta UTF-8 válido) | Tope de bytes obligatorio y `utf8.len` | `Validate.string` (`maxLength` es obligatorio) |
| Tablas raras | Claves NaN o nil, diccionarios donde va lista, miles de elementos | Lista secuencial con tope | `Validate.array` |
| Argumentos de más | Parámetros extra que el handler no espera | Cantidad exacta | `Validate.args` |
| Spam | Dispara un remote miles de veces por segundo | Balde de fichas por jugador y por remote | `RateLimiter`, `rate` en cada remote |
| Contexto falso | Pide comprar lejos de la tienda, abrir una puerta sin llave, actuar muerto | El handler verifica permiso, distancia, estado y saldo **en el servidor** | Cada handler (el validador no sabe de reglas del juego) |
| Remote solo servidor→cliente disparado por el cliente | Prueba remotes para ver qué acepta | Se rechaza y se registra (la guía lo usa también como trampa) | `Remotes.toClient` |
| Rutas o instancias arbitrarias | Pide al servidor cargar o `require` algo que el cliente eligió | No aceptar rutas ni referencias libres; solo ids de una lista | `Validate.oneOf` |
| Compra falsa | Dispara `PromptProductPurchaseFinished` u otra señal del cliente | Otorgar solo en `MarketplaceService.ProcessReceipt`, en el servidor | `server/Shop/ShopService.luau` |
| Duplicación por cambio de servidor | Sale y entra rápido (o teletransporta) para que dos servidores tengan sus datos | Bloqueo de sesión en la metadata de la clave | `DataService` + `SessionLock` |
| Datos que fallaron al cargar | Si se guardaran los valores por defecto, borraría el progreso real | Estado "errored": juega con defaults que nunca se guardan; sin compras | `DataService.canSave` |
| ProximityPrompt / ClickDetector | Los dispara desde lejos o deshabilitados; ClickDetector no tiene ningún chequeo en el servidor | En el handler: ¿está habilitado?, ¿el personaje existe y está cerca?, límite de frecuencia | A cargo de cada juego (ver checklist) |
| Partes no ancladas | Toma la propiedad de red y mueve la parte hasta su personaje, salteando distancias | Partes ancladas o propiedad de red asignada por el servidor para acciones críticas | A cargo de cada juego |
| Movimiento (velocidad, teletransporte) | Controla su personaje y su física | No hay solución universal: heurísticas por juego, con tolerancia a la latencia. "Server authority" está en beta | A cargo de cada juego |

## Consecuencias (guía oficial)

- **Decide el servidor.** No banear por detecciones del cliente.
- **Primero neutralizar.** Descartar el pedido, corregir el valor, devolver al jugador a la última posición válida. Expulsar solo si hace falta.
- **Proporcional y reversible.** Puede haber falsos positivos: preferir acciones reversibles a bans permanentes.
- **Escalera:** registro silencioso → mitigación silenciosa → restricciones temporales (comercio, rankings) → expulsión o ban. Para reincidentes, la Ban API (`Players:BanAsync`) en vez de solo expulsar.
- **Demorar lo visible**, para no enseñarle al exploiter qué lo delató.

`Remotes` hace el registro y la mitigación silenciosa (descarta y anota). `Remotes.rejections(player)` deja que cada juego decida el siguiente escalón.
