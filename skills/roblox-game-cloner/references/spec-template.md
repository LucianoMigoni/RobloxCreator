# Plantilla de `games/<juego>/docs/spec.md`

La spec es construible cuando cada mecánica dice **qué decide el servidor**, qué remote la dispara, qué datos guarda y con qué números, y cuando cada número vive en `src/shared/Config/`.

```markdown
# Spec: <juego>

Fecha · Autor · Concepto de origen: `docs/concepto.md` · Estado: borrador | aprobada

## Referencia y diferenciación
- Referencia(s): <juego(s)>, cómo se analizaron (jugándolo, video, build propio con REA).
- **Se toma:** mecánicas y ritmos (lista).
- **No se toma:** título, logo, thumbnails, mapa, modelos, place file, nombres de personajes (un clon reconocible es "no único" y pierde exposición; además, propiedad intelectual).
- **Giro propio:** qué lo diferencia.

## Loop central
- Minuto a minuto (acción más repetida):
- Progresión (qué crece y para qué):
- Primeros 10 / 30 / 60 s:
- Motivos para volver D1, D2–7, D8–28:
- Con amigos:

## Mecánicas
| Id | Mecánica | Reglas y números (→ Config) | Decide el servidor | Remote (validadores, límite) | Datos guardados |
|---|---|---|---|---|---|
| M1 | Recolectar | +1 moneda por toque, 0,5 s de cooldown (`Config/GameplayConfig`) | cooldown, distancia, monto | `Collect` (instance Part; 4/s) | `coins` |

## Economía
| Fuente / sumidero | Monto | Frecuencia | Transacción de analíticas |
|---|---|---|---|
| Recolectar | +1 | ~2/s | Gameplay |
| Comprar ítem | −precio | — | Shop |
Tiempo estimado para comprar el primer ítem (objetivo: dentro del primer minuto o dos).

## Progresión y contenido
Niveles, zonas, ítems (ids y precios en `Config/ShopConfig`).

## Onboarding
Pasos del embudo (`Config/OnboardingConfig.STEPS`): nombre, fuente (server/client), qué enseña.

## UI (para `roblox-ui-designer`)
Pantallas, botones y el remote que dispara cada uno.

## Monetización (para `roblox-monetization`)
Qué se vende y por qué es honesto. Ids pendientes de crear en el Creator Dashboard.

## Assets
| Asset | Fuente (catálogo, Blender, generate_mesh, Creator Store) | Triángulos | Licencia |
|---|---|---|---|

## Métricas objetivo
Pasos del embudo a medir, señales del algoritmo a vigilar (PTR, bounce, play days, co-play).

## Plan de construcción
Hitos en orden, cada uno jugable: 1) loop central con cubos grises, 2) progresión, 3) UI, 4) monetización, 5) pulido y mapa.

## Riesgos y cumplimiento
Contenido para el cuestionario de madurez y etiqueta esperada (`roblox-compliance`), texto de jugadores (filtrado), productos con `PolicyService`, rendimiento en móvil.
```
