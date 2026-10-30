# Traspaso: trabajo en curso y contexto completo

Para la IA (o persona) que retome el trabajo desde un push, por ejemplo el Claude de Luciano si a Leonel se le acaban los tokens. **Leé este archivo entero antes de tocar nada:** acá está todo lo que pidió el usuario, cómo quiere que se trabaje, qué está hecho, qué se está haciendo y qué falta, para seguir igual que en el chat original.

Última actualización: 2026-10-30, hito 0 (diseño del armador). Sesión original: Claude Code en la nube de Leonel, rama `leonelblumberg/quirky-dijkstra-2kxnwz`.

## 0. Cómo retomar, paso a paso

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
6. **Tabla de tareas:** el usuario quiere verla. En Claude Code, con `TaskCreate` y `TaskUpdate`, una tarea por fila de la sección 4, y actualizarla mientras se trabaja.

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
  - Mostrar la tabla de tareas: "pone el cuadro de las tareas", "me gusta verla".
  - Pushear después de cada hito y dejar este traspaso al día.
  - Cuando pide una muestra, mandar imágenes reales (renders o capturas), no descripciones.
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

## 4. Plan en curso

Mismo orden que la tabla de tareas. Un hito = varias filas; al cerrar cada hito se hace push.

| # | Tarea | Hito | Estado |
|---|---|---|---|
| 40 | Diseñar el armador: bloques, recetas, etiquetas del mapa (`skills/roblox-game-kits/references/bloques.md`) | 0 | ✅ |
| 41 | Base del armador: tipos, validación de recetas, cargador de bloques (servidor y cliente), ayudas del mundo, despachador de premios, estado del kit | 1 | pendiente |
| 42 | Bloque Units | 1 | pendiente |
| 43 | Bloque Plots | 2 | pendiente |
| 44 | Bloque Belt | 2 | pendiente |
| 45 | Bloque Steal (hecho de cero) | 2 | pendiente |
| 46 | Bloque Rolls | 2 | pendiente |
| 47 | Bloque Merge | 2 | pendiente |
| 48 | Bloque Sell | 2 | pendiente |
| 49 | Bloque Equip | 2 | pendiente |
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

## 5. Bitácora de hitos

- **Antes del armador (hasta el 2026-10-30, commit `0a79d17`):** UI estilo hit completa (UIKit v3, HUD de PC y táctil, tienda en una lista, índice por zonas con premio validado, carteles y flechas en el mundo, ventanas revisadas para el teléfono). Chequeo en verde en GitHub.
- **Hito 0 (2026-10-30):** diseño del armador (`skills/roblox-game-kits/references/bloques.md`), este traspaso y la tabla de tareas #40 a #70.

## 6. Qué existe hoy (mapa)

- **Pipeline:** 11 skills en `skills/` (idea, diseño, UI, monetización, seguridad, QA, cumplimiento, publicación, campañas, métricas, live ops) y guías en `skills/_shared/`.
- **Herramientas** (`tools/`): `check.py`, `roblox_research.py`, `assets_import.py`, `roblox_upload.py`, `imagegen.py`, `thumbs.py`, `iconsheet.py`, `vfx_textures.py`, `ui_textures.py`, `flat_icons.py`, `render3d/`, `campaigns.py`, `analytics.py`.
- **Recursos:** `assets/index.json` (~60 paquetes) y `assets/LICENSES.md`.
- **Plantilla** (`template/`):
  - servidor: datos con bloqueo de sesión, remotes con validación y límite, economía multi-moneda, impulsos, premios, retención (diario, regalos por tiempo, misiones, ruleta, códigos, grupo, sin conexión, renacer, objetivos, índice por zonas), tienda (productos, pases, suscripción, regalos, anuncio con premio), eventos con horario, social;
  - cliente: HUD estilo hit (PC y táctil), ventanas, Juice, Sound, Effects, World (carteles y flechas);
  - tests de la lógica pura en `template/tests/`.
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
- **Monedas nuevas por receta** (Wins, Taps): en `EconomyConfig.CURRENCIES` de cada juego.

## 8. Lo que depende de las personas

- **Claves** (variables de entorno o secretos del entorno de Claude; nunca en el repo ni en el chat):
  - `OPENAI_API_KEY` (íconos y miniaturas con GPT Image);
  - `GEMINI_API_KEY` (Nano Banana, opcional);
  - `MESHY_API_KEY` (plan Pro, modelos 3D);
  - `ROBLOX_OPEN_CLOUD_API_KEY` + `ROBLOX_CREATOR_GROUP_ID` (subir íconos, texturas y sonidos);
  - `ROBLOX_ADS_API_KEY` (campañas);
  - `ROBLOX_ANALYTICS_API_KEY` (métricas).
- **Cuentas:**
  - ElevenLabs con plan pago antes de publicar sonidos;
  - decidir la cuenta dueña de los juegos (personal o grupo) y sus requisitos para menores de 16.
- **Prueba en Studio de la UI v3** (tarea de Luciano en `team/tareas.md`) y, después, de los bloques del armador.
- **Elegir las tomas de sonido** (`assets/audio/hit-sfx`, `hit-voices`).
- **PR de la rama a `main`**, revisión y merge (cuando el usuario lo pida).

## 9. Trampas aprendidas (no repetir)

- **`UIAspectRatioConstraint` con un eje en 0:** la documentación no dice qué hace (puede dar tamaño 0). En listas con scroll, `UIKit.fitHeight`, `UIKit.row` o `UIKit.grid`.
- **`UISizeConstraint.MinSize` en botones dentro de ventanas:** encima cosas. Los 44 px se logran por diseño.
- **`UIStroke`:** en `UIKit` va con `ScaledSize`, como fracción del lado menor (0.05), nunca en píxeles.
- **Teléfono:** nada en la zona del joystick (≈ 41 % izquierdo, desde el 43 % del alto) ni en la del salto.
- **Sintaxis de Luau:** una línea que empieza con `(` después de otra que termina en `)` es sintaxis ambigua y luau-lsp la marca como error. Usar una variable local o empezar con `;`.
- **luau-lsp y tablas:** un literal con tipos mezclados (`{ child, child:FindFirstChild("X") }`) falla en modo estricto. Anotar `{ Instance? }`.
- **Tests sin Roblox:** el CLI de Luau no tiene `Color3`, `Vector3` ni servicios. Lo que se prueba (recetas, `Lib/`) va sin tipos de Roblox.
- **Glifo de Robux** (`utf8.char(0xE002)` con Builder Sans): sale del DevForum, no de la documentación. Confirmar en Studio.
- **En la nube de Claude:**
  - create.roblox.com está bloqueado: la documentación sale del repo `Roblox/creator-docs`, por `raw.githubusercontent.com`;
  - las imágenes de esa documentación están en Git LFS y se bajan de `media.githubusercontent.com`;
  - Playwright está instalado global en `/opt/node22/lib/node_modules`.
