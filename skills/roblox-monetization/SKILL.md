---
name: roblox-monetization
description: Diseña y audita la monetización de un juego de Roblox, incluidas ventajas pagas fuertes como en los simuladores grandes (multiplicadores, espacios extra, velocidad, suerte con probabilidades visibles, protección de base), packs, pases y cosméticos, dentro de las reglas oficiales (descuentos genuinos, sin urgencia falsa, probabilidades visibles, PolicyService). Usar en la fase 4 del pipeline, al agregar productos o precios y antes de publicar.
---

# roblox-monetization

## Objetivo
Que el juego gane dinero sin engañar ni presionar a nadie. Pagar **puede dar ventajas importantes** (decisión del 2026-10-26, `team/decisiones.md`): es lo que hacen los simuladores que más recaudan. Cada producto dice exactamente qué da y se ofrece cuando sirve, y la tienda pasa la auditoría de reglas oficiales. Sale `games/<juego>/docs/monetizacion.md`.

## Cuándo usarlo
- Fase 4 del pipeline (con la spec y la economía definidas).
- Cada vez que se agrega o cambia un producto, un precio, una oferta o un texto de la tienda.
- Antes de publicar un update (la auditoría se repite).

**Lo llaman:** `roblox-game-cloner` (sección de monetización de la spec), `roblox-ui-designer` (precios y textos de la tienda), `roblox-metrics-growth` (cuando la monetización es el cuello de botella).
**Llama a:** `roblox-ui-designer` (pantallas de tienda y ofertas), `roblox-security` (cada remote de compra).

## Flujo

1. **Retención primero.** Si el juego ya tiene datos y la retención es baja, avisar que conviene arreglar el loop antes (FAQ del algoritmo). Monetizar fuerte con retención baja no suma.
2. **Catálogo:** para cada producto, qué se vende, dónde y cómo (`references/tactics.md`). Durable o consumible, mejora o expresión, y el producto de Roblox que corresponde.
3. **Economía de monedas:** fuentes y sumideros de la spec, con el tiempo hasta la primera compra. Los montos van en `Config/` y los cambios de saldo ya se registran como eventos de economía (`CurrencyService`), así que en Creator Analytics se ve si la economía se infla.
4. **Precios en Robux:** precio inicial razonable, comparado con productos parecidos en juegos de referencia (con fuente). Después, las herramientas oficiales de optimización de precios y precios regionales. No inventar "precios óptimos".
5. **Implementar sobre la plantilla:**
   - Ítems con monedas → `ITEMS` de `Config/ShopConfig.luau`.
   - Developer Products y Game Passes → crearlos en el Creator Dashboard y poner los ids en `PRODUCTS` y `GAME_PASSES`. `ShopService` ya otorga por `ProcessReceipt`, sin dar dos veces y solo con datos guardables.
   - Beneficios de un pase → `ShopService.hasPass(player, attribute)` en el servidor.
   - Ítems aleatorios pagos, comercio, anuncios o suscripciones → `PolicyService:GetPolicyInfoForPlayerAsync` en el servidor antes de ofrecerlos, y probabilidades visibles (reglas 6 y 7 de la auditoría).
   - Textos en `Config/UiText.luau`, sin presión.
6. **UI de la tienda** con `roblox-ui-designer`: integrada, contextual (qué hace cada ítem) e invitante; verde para comprar y dorado para lo premium.
7. **Auditoría ética** con `references/audit.md`: `python tools/check.py` en verde y la tabla manual completa.
8. **Probar en Studio:** comprar un ítem con monedas, comprar un Developer Product y un pase, y confirmar que el saldo, el inventario y el atributo del pase solo cambian cuando el servidor lo confirma.
9. **Escribir `docs/monetizacion.md`** (catálogo, precios con su fuente, auditoría) y mostrarlo al usuario.

## Checklist
- [ ] Cada producto tiene un propósito claro y visible en el juego.
- [ ] Cada ventaja paga dice su efecto exacto (x2, +3 espacios, +20 % de suerte) y el servidor da exactamente eso.
- [ ] El que no paga sigue pudiendo jugar y progresar: si no, se va, y la retención es lo que más pesa en el algoritmo.
- [ ] Ofertas genuinas y justas; sin escasez ni urgencia falsas; ninguna cuenta regresiva que se reinicia.
- [ ] Textos sin presión (`tools/check.py` en verde).
- [ ] Aleatorios pagos con todos los resultados y probabilidades, y con `PolicyService`.
- [ ] Developer Products solo por `ProcessReceipt`; nada que valga Robux sin `canSave`.
- [ ] Auditoría de `references/audit.md` aprobada y pegada en `docs/monetizacion.md`.

## Límites
- No promete ingresos ni inventa "precios óptimos": los precios se prueban y se miden.
- No implementa cajas aleatorias pagas en la plantilla: si un juego las quiere, este skill exige probabilidades y `PolicyService` antes de aprobarlas.
- Las políticas de Roblox cambian: ante la duda, verificar la página oficial y anotar la fecha.
