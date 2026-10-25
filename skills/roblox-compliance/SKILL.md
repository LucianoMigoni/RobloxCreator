---
name: roblox-compliance
description: Revisa que un juego de Roblox cumpla las reglas para llegar a su público (cuestionario Maturity & Compliance, etiqueta de madurez, requisitos para Roblox Kids y Select, PolicyService, filtrado de texto con TextService, Community Standards y propiedad intelectual). Usar en la fase 7 del pipeline, antes de publicar y en cada update que cambie contenido, textos de jugadores o productos con políticas.
---

# roblox-compliance

## Objetivo
Que el juego llegue al público que buscamos sin riesgo de moderación: contenido declarado tal como es, texto de jugadores filtrado, productos con políticas bloqueados para quien no puede usarlos y nada de propiedad intelectual ajena. Sale `games/<juego>/docs/cumplimiento.md`.

## Cuándo usarlo
- Fase 7 del pipeline, con el juego completo.
- En cada update que cambie una respuesta del cuestionario (Roblox exige volver a enviarlo), agregue texto de jugadores o un producto con política (aleatorios pagos, comercio, anuncios, suscripciones, productos comerciales, compartir contenido).
- En la fase 1, para saber a qué público puede llegar un concepto (un *social hangout* o la creación libre ya dejan afuera a los menores de 16).

**Lo llaman:** `roblox-ideation` y `roblox-game-cloner` (público alcanzable), `roblox-monetization` (políticas de productos), `roblox-publishing` y `roblox-liveops` (antes de publicar).
**Llama a:** `roblox-security` (los remotes de texto validan largo y frecuencia), `roblox-monetization` (si un producto necesita `PolicyService`), el skill dueño de cada falla.

## Base oficial
Verificado el 2026-10-25 en `/production/promotion/content-maturity`, `/production/publishing/kids-and-select`, `/production/publishing/publish-games-and-places`, `/ui/text-filtering` y la referencia de `PolicyService` y `TextService` (repo `Roblox/creator-docs`, commit `4e795e6`). Estas reglas cambiaron varias veces en 2026: **volver a verificar antes de cada lanzamiento** y actualizar la fecha.

- **Sin información de madurez, Roblox restringe el juego para todos los jugadores.** Inexacta o engañosa: moderación del juego y de la cuenta.
- **Etiquetas y quién accede:**

  | Etiqueta | Cuentas que acceden |
  |---|---|
  | Minimal o Mild | Roblox Kids (5–8), Roblox Select (9–15) y Roblox (16+) |
  | Moderate | Roblox Select (9–15) y Roblox (16+) |
  | Content May Vary | Solo 16+ con verificación de edad (*age check*) |
  | Restricted | Solo 18+ con verificación de identidad; injugable en algunos países (Corea, Arabia Saudita, Turquía, entre otros) |

- **Primera publicación:** el cuestionario empieza con una pregunta sobre contenido restringido por edad. Responder "No" da *Content May Vary* y el juego sale **solo para 16+**. Para llegar a Kids y Select hay que completar el cuestionario entero.
- **Para llegar a menores de 16** (además de lo anterior), quien es dueño del juego (persona o dueño del grupo) necesita: cuenta en regla, verificación (estimación facial si es menor de 18; documento si es mayor), 2FA, y Roblox Plus o Premium activo durante 2 meses seguidos **o** una tarifa reembolsable de 1000 Robux por juego. El juego pasa una **evaluación**: 250 jugadas únicas de jugadores 16+ "muy comprometidos" (antigüedad, historial y gasto en Roblox) en 60 días, más una revisión de seguridad. Se sigue en el panel **Audience Reach**. Existe una revisión acelerada con una tarifa reembolsable de 50 000 Robux.
- **Qué deja afuera a los menores:** *social hangout* como actividad principal (16+; con espacios privados, 18+), creación libre como dibujar o escribir (16+), tema principal sensible (16+), violencia fuerte, sangre realista abundante, alcohol, temas románticos o lenguaje fuerte (18+). Declarar según el contenido **más extremo** que pueda encontrar un jugador.
- **Assets subidos:** violencia, sangre, humor grosero o temas románticos realistas o excesivos se pueden moderar aunque la etiqueta los permita.
- **`PolicyService:GetPolicyInfoForPlayerAsync`** (servidor, `pcall`): `ArePaidRandomItemsRestricted`, `IsPaidItemTradingAllowed`, `AreAdsAllowed`, `IsEligibleToPurchaseSubscription`, `IsEligibleToPurchaseCommerceProduct`, `IsContentSharingAllowed`, entre otros. El cuestionario pregunta si el juego los respeta.
- **Texto de jugadores que ven otros** (nombres de mascotas, carteles, mensajes fuera del chat): `TextService:FilterStringAsync` en el servidor, una vez por envío, y después `GetNonChatStringForBroadcastAsync` (todos) o `GetNonChatStringForUserAsync` (un jugador). **Si el filtrado falla, el texto no se muestra.** El texto guardado en DataStores se vuelve a filtrar al mostrarlo. El chat de Roblox ya filtra lo suyo.

## Flujo
1. **Inventario de contenido:** recorrer el juego y la spec, y anotar para cada categoría del cuestionario qué hay, con qué intensidad y frecuencia (`references/checklist.md`). Incluir assets, títulos, descripción y miniaturas: el título también cuenta (por ejemplo, para temas románticos o *social hangout*).
2. **Etiqueta esperada y público:** con el inventario, qué etiqueta sale y a quién llega. Si el público objetivo incluye menores de 16 y algo lo impide, proponer el cambio de contenido antes de publicar (no maquillar las respuestas).
3. **Texto de jugadores:** listar todo lugar donde un jugador escribe algo que otro ve. Cada uno pasa por un remote validado (`roblox-security`) y por el filtrado del servidor; si falla, no se muestra.
4. **Políticas:** cada producto o función con política consulta `PolicyService` en el servidor y oculta o bloquea lo que el jugador no puede usar. Aleatorios pagos con todos los resultados y probabilidades (`roblox-monetization`).
5. **Community Standards y propiedad intelectual:** nada de marcas, personajes, música o imágenes ajenas sin licencia; los assets salen del catálogo con `commercialUse: true` (`assets/LICENSES.md`). Metadata sin promesas de Robux ni contenido que no está en el juego.
6. **Requisitos de cuenta** (persona): marcar en `team/tareas.md` lo que falte en la cuenta dueña del juego (verificación, 2FA, Plus/Premium o tarifa).
7. **Escribir `docs/cumplimiento.md`** con el inventario, las respuestas propuestas, la etiqueta esperada, los textos filtrados, las políticas y los pendientes, y mostrarlo. **El cuestionario lo envía una persona** del equipo en el Creator Dashboard (**Publish settings → Content rating**) después de revisar las respuestas.

## Checklist
Ver `references/checklist.md`. Bloqueantes: cuestionario sin enviar o desactualizado, texto de jugadores sin filtrar, producto con política sin `PolicyService`, asset sin licencia comercial.

## Límites
- No envía el cuestionario ni paga tarifas: lo hace una persona con la cuenta dueña del juego.
- No es asesoría legal. Ante una duda de propiedad intelectual o de ley local, no publicar hasta resolverla.
- Las respuestas del cuestionario describen el juego, no el público que queremos: si no coinciden, se cambia el juego.
