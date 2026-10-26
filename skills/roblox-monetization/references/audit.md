# Auditoría ética de la tienda

Verificado el 2026-10-25 en la documentación oficial: `/production/monetization` (sección *Guidelines*), `/production/monetization/paid-random-items`, `/production/monetization/passes`, `/production/monetization/immersive-ads` y `MarketplaceService.ProcessReceipt`. El público de Roblox incluye menores, así que estas reglas se aplican siempre, no solo cuando conviene.

## Automática (`python tools/check.py`, paso "reglas de seguridad y estilo")

Marca en `src/` los textos de presión o urgencia ("GET IT NOW", "LAST CHANCE", "BUY BEFORE IT'S GONE", "limited time", "only 3 left", "última oportunidad", "solo hoy", "apurate"...). Si la urgencia es **real**, por ejemplo un evento con fecha de fin verdadera, la línea se marca con `-- monetization-ok: <motivo>` y queda revisada a mano en el PR.

## Manual (una fila por ítem, producto o pase en `docs/monetizacion.md`)

| # | Regla (guía oficial) | Cómo se verifica | Resultado |
|---|---|---|---|
| 1 | Descuentos **genuinos**: no "en oferta" siempre al mismo precio | Historial de precios del ítem | |
| 2 | Descuentos **justos**: no ofrecidos por un tiempo tan corto que presione | Duración de la oferta | |
| 3 | Nada de "casi agotado" o "solo por poco tiempo" si no es verdad | Revisar textos y lógica de stock | |
| 4 | Ninguna cuenta regresiva inexacta o que se reinicia para el mismo ítem | Revisar la lógica del temporizador (¿se reinicia al entrar?) | |
| 5 | Lenguaje sin presión: "View Item", "See Price", "Open Shop" en vez de "GET IT NOW" | `tools/check.py` y lectura de `Config/UiText.luau` | |
| 6 | Ítems aleatorios comprados con Robux, o con moneda comprada con Robux: mostrar **todos** los resultados posibles y sus **probabilidades numéricas** | Captura de la UI con las probabilidades | |
| 7 | Ítems aleatorios pagos, comercio pago entre jugadores, anuncios inmersivos, suscripciones o productos comerciales: integrar `PolicyService:GetPolicyInfoForPlayerAsync` y bloquear para quien no esté habilitado (p. ej. `ArePaidRandomItemsRestricted`) | Código del servidor + prueba con la política simulada | |
| 8 | Un Game Pass no puede dar ítems aleatorios pagos | Revisar qué otorga cada pase | |
| 9 | Developer Products otorgados solo en `ProcessReceipt` en el servidor; nunca por una señal del cliente | `ShopService.luau` (la plantilla ya lo hace) | |
| 10 | Nada que valga Robux si los datos no se pueden guardar (`DataService.canSave`) | `ShopService.luau` (la plantilla ya lo hace) | |
| 11 | Cada ítem vendido tiene un propósito claro y visible en el juego (guía *Monetization foundations*) | Descripción en la tienda | |
| 12 | Cada ventaja paga declara su efecto exacto y el servidor da exactamente eso; el que no paga sigue pudiendo progresar (criterio del hub; las ventajas pagas están permitidas desde el 2026-10-26) | Descripción del producto contra el código del servidor; balance con `roblox-metrics-growth` | |

**Pasa** cuando las filas 1 a 11 están en OK (o "no aplica" con motivo) y `tools/check.py` está en verde.
