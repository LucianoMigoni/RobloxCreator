# Traspaso: trabajo en curso y contexto completo

Para la IA (o persona) que retome el trabajo desde un push, por ejemplo el Claude de Luciano si a Leonel se le acaban los tokens. **Leé este archivo entero antes de tocar nada:** acá está todo lo que pidió el usuario, cómo quiere que se trabaje, qué está hecho, qué se está haciendo y qué falta, para seguir igual que en el chat original.

Última actualización: 2026-11-03. Terminados: MapKit (#62) con el estilo de los hits, las nueve recetas (#63), el juego de prueba rehecho con el armador (#64), los skills del armador (#65) y de game feel (#66), los juegos al día con la plantilla (#66b) la documentación al día (#67), la revisión completa (#69) y el reporte final (#70). El plan del armador está terminado: lo que sigue son las pruebas en Studio, las claves y las cuentas, en orden y con los comandos en `team/paso-a-paso.md` (detalle en `team/pendientes.md`), y el PR cuando el usuario lo pida. Sesión original: Claude Code en la nube de Leonel, rama `leonelblumberg/quirky-dijkstra-2kxnwz`.

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
7. **Clave de OpenAI:** desde el 2026-11-02 está cargada en la configuración del entorno de la nube (la toman las sesiones nuevas). Al empezar, comprobar que exista solo por el nombre (`printenv | cut -d= -f1 | grep OPENAI`), nunca imprimir el valor, y usarla con `tools/imagegen.py` para todo lo visual (íconos, mascotas, miniaturas). Si no está, pedírsela al usuario por la configuración del entorno (`team/claves-ia.md`), no por el chat.
8. **Dónde quedó:** la sección 4 marca la próxima tarea (la primera que no tiene ✅). La sección 7 tiene el diseño ya decidido del armador: seguirlo, es el que se viene usando.

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
- **Lo visual, al nivel de los top hits (2026-11-02):**
  - "Ahora que tenés esto de ChatGPT, esforzate con la UI, los íconos y toda la GUI. Cualquier cosa, si necesitás más dinero, avisame."
  - "Hacelo bien completo, siempre buscando que sea profesional."
  - "Que todos los íconos, UI, GUI sean lo más completos y lindos posible. Que sean como los top hits. Acordate de todo lo que agregamos y todo lo que necesitamos."
  - Al ver los bocetos 3D sin terminar: "Estos íconos así son muy malos, todos los que sean así rehacelos para que sean de calidad". Nunca se usa un boceto (render de `tools/render3d`) como ícono final: siempre pasa por GPT Image con la receta. Si se muestra un boceto, aclarar que es la base.
  - Con ChatGPT, mandar una prueba de cada cosa relevante (hoja de íconos, maqueta, miniatura).
  - Avisar si hace falta más saldo de OpenAI (al 2026-11-02 quedan unos USD 4,2 de los 5; una hoja de 9 íconos en calidad alta cuesta USD 0,086 y una miniatura, USD 0,11).
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
- ✅ "Añadí todas las skills, animaciones, conectores, todo lo que necesites (ejemplo Blender) y código reutilizable" → el armador: 18 bloques, nueve recetas, MapKit y los skills `roblox-game-kits` y `roblox-game-feel`.
- ✅ Usar ideas de juegos existentes fuera de Roblox adaptadas ("la aguja en un pajar") → receta SearchAndDig y "Ideas de fuera de Roblox" en `bloques.md`.
- ✅ Rediseñar todo si hace falta; dejarlo lo más avanzado posible; foco en chicos; muchísimas microtransacciones.
- ✅ "Prestá atención en cómo diseñan los HUDs, cómo son los mapas" → HUD (`hud-hits.md`) y mapas (MapKit, con el estilo de los hits).
- ✅ "Conseguí todo lo necesario para la construcción, recursos, animaciones" → recursos y el generador de mapas (MapKit).
- ✅ "No tiene que ser exactamente de un juego de pesca, lo que busco es que sean buenos para generar juegos del estilo top hit."
- ✅ Usar todos los trucos (x2, bonus, retención, ruleta); pay-to-win, "lo más cash grab posible"; probabilidades chicas como los hits, no gigantes.
- ✅ Conectar Rojo, Blender, ForgeGUI (evaluar), Meshy (evaluar), Obsidian (evaluar); los dos con todo conectado → `skills/_shared/conectores.md` y `SETUP.md`. 👤 Instalar en cada máquina.
- ✅ Creador de campañas de publicidad (cómo funciona, qué rinde, cuánto poner, cómo llevarlas) → `roblox-campaigns`, `tools/campaigns.py`.
- ✅ Imágenes, miniaturas y descripción para que hagan clic → `skills/_shared/vitrina-hits.md`, `tools/thumbs.py`, `tools/imagegen.py`.
- ✅ "Anotá todo lo que estamos planteando para armar los juegos" → `skills/_shared/como-son-nuestros-juegos.md` (al día al 2026-11-03).
- ✅ Anuncios con premio a menores de 13: se ofrecen cada vez que Roblox lo permite, sin buscar vacíos (protección infantil) → decisión del 2026-10-28.

**2026-10-29**
- ✅ Las miniaturas estaban malas → IA con referencias del juego (`vitrina-hits.md` §6).
- ✅ Íconos y sonidos: los mejores, estilo hit → `assets/ui/hud-icons` (36), `assets/ui/icons-flat` (59), `hit-vfx`, `hit-sfx`, `hit-voices`. 👤 Elegir las tomas de sonido.
- ✅ Evaluar VFX Studio → `conectores.md` (opcional, solo para diseñar).
- ✅ Herramientas: GPT Image y Nano Banana por API (no por suscripción), Meshy directo, Blender, ElevenLabs; ForgeGUI no. 👤 Claves (sección 8).
- ✅ "Se ve muy IA... analizá el HUD de todos los top hits y replicalo" → `hud-hits.md` y UIKit v3. Pidió una muestra → enviada y aprobada como modelo: "El juego tiene que verse 10 veces mejor que eso. Pero está bien como modelo." "Tené cuidado con los espacios y las cosas superpuestas."
- ✅ Íconos como los de los hits (sin dedos mal, no emoji 3D) → render propio + GPT Image 2.5. Los que faltaban se hicieron con la clave de OpenAI (2026-11-02).
- ✅ Investigar Chicken Farm y Ride a Dino → `hud-hits.md`. Sus mecánicas quedaron en las recetas MergeTycoon y RunAndCatch.
- 👤 "Quizás habría que conectarte ChatGPT y Gemini" → claves `OPENAI_API_KEY` y `GEMINI_API_KEY` (sección 8).

**2026-10-30**
- ✅ Tabla de tareas visible.
- ✅ "Qué tiene la app, qué falta?" → respondido; el plan está en la sección 4.
- 🔄 Armador genérico para cualquier top hit, terminar todo, analizarlo y reportar qué conectar → armador hecho; faltan la revisión completa y el reporte final (sección 4).
- 🔄 Traspaso completo y push en cada hito → este archivo.
- ✅ "Añadí también las cosas que hay que hacer después: qué API keys necesitás (como ChatGPT y Google), qué conectores hay que poner, etc." → `team/pendientes.md` (tarea #71; se repite en el reporte final).
- ✅ "Enumerame (únicamente) las tareas" → cuando pida la tabla, mostrar solo la lista de tareas, sin comentarios.
- ✅ "Cuando termines algo importante... mandame alguna pequeña foto" → sección 2.
- ✅ "Acordate de los push en los hitos" → push por hito y por bloque.
- ✅ "Terminá este hito y dejá todo listo para el traspaso... para que pueda continuar en el Claude de Luciano sin problemas y de la misma forma que hacemos acá" + "No continúes luego de esto" + "Dejá también las instrucciones para que pueda seguir trabajando" → se cortó después de los bloques Plots, Sell y Equip; este archivo quedó listo para retomar (sección 0).

**2026-11-02**
- ✅ "Decime si necesitás ChatGPT, Google o Higgsfield para la UI" → para el código no; para íconos y miniaturas, la clave de OpenAI. Paso a paso en `team/claves-ia.md`.
- ✅ Clave de OpenAI: el usuario la cargó en el entorno de la nube y, para probarla en esta sesión, la pegó en el chat por decisión propia ("solo tiene 5 dólares"); se guardó solo en un archivo temporal fuera del repo y se probó (modelos y una hoja de prueba).
- 👤 Gemini: la facturación de Google dio OR_BACR2_59 (sin arreglo oficial): queda para después, es opcional.
- ✅ "Probá hacer una miniatura completa, tipo foto final con texto, como los top hits" → `skills/_shared/vitrina/ejemplos/despues-robo-dragon-gpt.jpg` (GPT Image 2.5 + `thumbs.py`).
- ✅ UI de los bloques (#61) y íconos con ChatGPT (#68): ver la sección 5.
- ✅ "Ahora que tenés ChatGPT, esforzate con la UI, los íconos y toda la GUI" + "Que todo sea lo más completo y lindo posible, como los top hits" + "Cuando hagas algo relevante, pasame una prueba" → arte de la tienda, pantalla de carga, íconos de unidades, fotos de zonas e insignias (sección 5), con una prueba de cada tanda.
- ✅ "Estos íconos así son muy malos, todos los que sean así rehacelos" → eran los renders base sin pasar por GPT; se rehicieron todos con ChatGPT. Regla: un render base nunca es un ícono final.
- ✅ "Esto es solo un ejemplo, no? Después cada juego puede ser de cualquier cosa" → sí: las unidades, zonas e íconos de las recetas son muestras; cada juego trae los suyos.

**2026-11-03**
- 🔄 "Continuá con todo lo que falta" → MapKit, recetas, juego de prueba, skills y docs ✅; siguen la revisión y el reporte final (sección 4).
- ✅ "Los mapas están muy básicos, investigá por ejemplo el de Steal An Egg. Pero bueno, si es una base únicamente, quizás tiene sentido" + "Buscá videos de gameplay si hace falta" + "Buscá del de pescar también" → miniaturas oficiales y fotogramas de videos de Steal An Egg, Steal a Brainrot y Fish It! (con `roblox_research.py` y `i.ytimg.com/vi/<id>/hq1-3.jpg`), y MapPlan rehecho con ese estilo (sección 5). Antes y después enviado al usuario.
- ✅ "Esto sería simplemente un ejemplo, no? Después cada juego usa esto mucho más preparado y personalizado" → sí: las recetas y los mapas son muestras; cada juego copia la receta, la hace propia y fija el mapa en Studio para editarlo (decisión del 2026-11-03).
- 🔄 "Continuá" → juegos al día con la plantilla (`tools/sync_template.py`) y documentación al día ✅; siguen la revisión completa y el reporte final.

## 4. Plan en curso

Mismo orden que la tabla de tareas. Un hito = varias filas; al cerrar cada hito se hace push.

| # | Tarea | Hito | Estado |
|---|---|---|---|
| 40 | Diseñar el armador: bloques, recetas, etiquetas del mapa (`skills/roblox-game-kits/references/bloques.md`) | 0 | ✅ |
| 41 | Base del armador: tipos, validación de recetas, cargador de bloques (servidor y cliente), ayudas del mundo, despachador de premios, estado del kit | 1 | ✅ |
| 42 | Bloque Units | 1 | ✅ (el inventario en ventana va con la UI de los bloques, #61) |
| 43 | Bloque Plots | 2 | ✅ |
| 44 | Bloque Belt | 2 | ✅ servidor |
| 45 | Bloque Steal (hecho de cero) | 2 | ✅ servidor |
| 46 | Bloque Rolls | 2 | ✅ servidor |
| 47 | Bloque Merge | 2 | ✅ servidor |
| 48 | Bloque Sell | 2 | ✅ servidor (su UI va en #61) |
| 49 | Bloque Equip | 2 | ✅ servidor (mascotas que siguen y su UI van en #61) |
| 50 | Bloque Stats | 3 | ✅ servidor |
| 51 | Bloque Zones | 3 | ✅ servidor |
| 52 | Bloque Stages | 3 | ✅ servidor |
| 53 | Bloque Fishing | 3 | ✅ servidor |
| 54 | Bloque Garden | 3 | ✅ servidor |
| 55 | Bloque Search | 3 | ✅ servidor |
| 56 | Bloque Wild | 3 | ✅ servidor |
| 57 | Bloque Upgrades | 3 | ✅ servidor |
| 58 | Bloque Tycoon | 3 | ✅ servidor |
| 59 | Bloque Items | 3 | ✅ servidor |
| 60 | Productos de cada bloque en la tienda | 4 | ✅ |
| 61 | UI de los bloques | 4 | ✅ (2026-11-02; falta probarla en Studio) |
| 62 | MapKit | 5 | ✅ (2026-11-03; falta probarlo en Studio) |
| 63 | Nueve recetas con objetivos, misiones y mapa | 5 | ✅ (2026-11-03) |
| 64 | Rehacer `games/prueba` con el armador | 6 | ✅ (2026-11-03; falta probarlo en Studio) |
| 65 | Skill del armador y skills que lo usan | 7 | ✅ (2026-11-03) |
| 66 | Skill de game feel | 7 | ✅ (2026-11-03) |
| 66b | Juegos al día con la plantilla (`tools/sync_template.py`, `iconFallbacks`) | 7 | ✅ (2026-11-03) |
| 67 | Poner al día CLAUDE.md, ROADMAP, guía central, hits-2026, README, tablero | 7 | ✅ (2026-11-03) |
| 68 | Íconos que faltan | 7 | ✅ 27 de la UI y 9 mascotas con GPT Image (falta subirlos a Roblox) |
| 69 | Revisión completa | 8 | ✅ (2026-11-03): chequeo cruzado, seguridad, voces, aleatorio pago, backlog del juego |
| 70 | Push y reporte final: qué conectar, claves, cuentas, pruebas | 8 | ✅ (2026-11-03): `team/pendientes.md` al día; lo que sigue depende de las personas (sección 8) |
| 71 | Lista de lo que hay que hacer después: claves, conectores, cuentas y pruebas (`team/pendientes.md`) | 1 | ✅ (mantenerla al día) |
| 72 | Guía paso a paso para las personas: qué hacer, instalar y correr, en orden (`team/paso-a-paso.md`) | 8 | ✅ (2026-11-03; mantenerla al día junto con `team/pendientes.md`) |

### Próximo paso: modelos 3D de los critters (cuando esté `MESHY_API_KEY`)

Hoy cada unidad sin modelo se ve como una bola de su color. El usuario pidió conectar Meshy y Blender (2026-11-03).

1. Comprobar la clave solo por el nombre (`printenv | cut -d= -f1 | grep MESHY`). Si no está: `skills/_shared/conectores.md`, Meshy, "En la nube".
2. Ver el costo sin gastar:
   `python tools/meshy.py batch assets/ui/unit-icons/critters --out meshy_output/critters --only pebble_pup,mossling,bubblebug,zapfrog,cloud_kitty,lava_lizard,star_owl,crystal_dragon --dry-run`.
   Son 8 × 15 créditos con Smart Topology y 5.000 caras.
3. Contarle el costo al usuario y generar sin `--dry-run`. Primero conviene uno solo de prueba (`image`).
4. Mandarle al usuario las vistas previas (`<id>_preview.png` y las cuatro vistas) para que elija.
5. Lo elegido pasa a `assets/3d/meshy/<id>/` (GLB, FBX, textura y el `.json` de la tarea). Se registra en `assets/index.json` con:
   - `source: "ai-generated"`;
   - `license: "Meshy Pro (propio)"`;
   - `commercialUse: true`.

   También va en `assets/LICENSES.md`. Al final, `python assets/catalog.py validate`.
6. Si el entorno instaló Blender (`blender -b --version`): revisar la escala, poner el pivote abajo al centro y comprobar los triángulos (Roblox acepta hasta 20.000 por malla).
7. Para el juego:
   - en la receta, `model = "<Id>"` en cada unidad;
   - en Studio, importar cada modelo con el 3D Importer (Scale Unit: Studs) y dejarlo en `ReplicatedStorage.Assets.Units` con ese nombre. Eso lo hacen ellos, o una sesión en su PC.

Las mascotas de cuatro patas no se rigean con Meshy, porque su rig es para humanoides: se animan con código (saltitos y balanceo).

## 5. Bitácora de hitos

- **Antes del armador (hasta el 2026-10-30, commit `0a79d17`):** UI estilo hit completa (UIKit v3, HUD de PC y táctil, tienda en una lista, índice por zonas con premio validado, carteles y flechas en el mundo, ventanas revisadas para el teléfono). Chequeo en verde en GitHub.
- **Hito 0 (2026-10-30):** diseño del armador (`skills/roblox-game-kits/references/bloques.md`), este traspaso y la tabla de tareas #40 a #70.
- **Hito 1, parte 1 (2026-10-30): base del armador.** Chequeo en verde.
  - `shared/Kits/Types.luau` (tipos de la receta), `shared/Kits/Tags.luau` (etiquetas del mapa), `shared/Config/KitConfig.luau` (receta activa; `{ name = "None" }` = solo núcleo).
  - `shared/Lib/KitCheck.luau` + `tests/KitCheck.spec.luau` (12 casos) + `tests/KitKnown.luau` (listas del núcleo para los tests): revisa ids, rarezas, monedas, pases, impulsos, referencias entre bloques, bloques que necesitan otros (`NEEDS`), premios por ítem (`KitCheck.ITEMS`: Unit, Roll, Item, Upgrade, Zone, Stat, Rod, Tool, Seed, Garden:Skip, Merge:Skip, Stages:Revive) y efectos de mejoras (`KitCheck.EFFECTS`). `KitCheck.BLOCKS` = orden de arranque.
  - `server/Kits/Kits.luau`: cargador. `BLOCKS` vacío hasta que cada bloque se suma con `{ key, init, start, snapshot?, income?, items? }`. Revisa la receta con las listas reales y avisa con `warn("[Kits] ...")`; registra un solo `setItemHandler` (despacha por prefijo), `setIncomeProvider` (suma) y `setKitProvider` (`state.kit.<key>`). `Main.server`: `Kits.init()` después de `Remotes.start()`, `Kits.start()` justo antes de `DataService.start()`.
  - `server/Kits/KitWorld.luau`: `tagged`, `text`/`number`/`inherited` (atributos), `part`, `position`, `ancestor`, `humanoid`, `root`, `near` (con margen de 8 studs), `playerFromPart`, `sign` (cartel HitSign desde el servidor), `prompt` + `onPrompt` (mide distancia y frena repeticiones), `onTouch` (pads).
  - Cliente: `client/Kits/Kits.luau` (cargador de UI por bloque, `start(hud)`), `KitState.luau` (`get`/`on` de `state.kit.<bloque>`), `ActionBar.luau` (botones grandes abajo al centro; se reparten el ancho, atajo de teclado, mantener apretado repite). `Main.client` llama `Kits.start(hud)` (ya no hay campo KIT en GameConfig).
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

- **Hito 2 terminado (2026-11-02): bloques Belt, Rolls, Merge y Steal.** Chequeo en verde. Se retomó en esta misma sesión ("Continuá donde te quedaste"): el Claude de Luciano no llegó a tomarlo.
  - `server/Kits/Belt.luau`: cinta con el diseño de la sección 7 (sorteo, modelo que cruza la parte por su eje X con `Heartbeat`, precio con variantes, prompt "Buy", el primero se lo lleva, devuelve la plata si algo falla).
  - `server/Kits/Rolls.luau`: `RequestRoll(id, count, auto?)` con todas las reglas de la sección 7; `Rolls.draw(player, def, count, force)`; premio "Roll:<id>"; cartel y prompt "Open" (atributo `Roll`) en cada `KitRollStation`: el prompt solo abre la ventana de la tirada en el cliente (#61).
  - `server/Kits/Merge.luau`: modos "tier" y "variant"; `Merge.nextKind`; fusión pendiente con entrega automática; premio "Merge:Skip" (si no hay nada esperando, queda guardado en `skips` para la próxima: una compra nunca se pierde); cartel en `KitMergeMachine`.
  - `server/Kits/Steal.luau`: prompt "Steal" en cada unidad colocada (atributo `Owner` para que el cliente del dueño lo esconda), llevarla sobre la cabeza (soldada con `WeldConstraint`), velocidad `carrySpeed`, atributo `BeingStolen` en el modelo de la base, entrega al entrar a la propia base, se cae si muere/se va/lo empujan/pasan 90 s, empujón `PushPlayer(userId)` con `ApplyImpulse`, aviso al servidor desde `announceFrom`. `Steal.isCarrying(player)`.
  - `KitWorld.applySpeed` / `setSpeedFactor(player, fuente, factor?)`: velocidad = `BaseWalkSpeed` (o la de StarterPlayer) × factores. **Para Stats (#50):** poner el atributo `BaseWalkSpeed` y volver a aplicar con `KitWorld.applySpeed` en cada `CharacterAdded`.
  - `Units.transfer` ya no avisa "got a SECRET" (el robo avisa lo suyo).

- **Hito 3, parte 1 (2026-11-02): bloque Stats.** Chequeo en verde.
  - `server/Kits/Stats.luau`: ganancia por stud caminado (medido cada 0.25 s, tope 1.5 × WalkSpeed: los saltos de posición no cuentan; señal "Steps"), por segundo, por toque (`TapStat(id)`, como mucho `clickRate` por segundo por estadística; el pase `autoPass` toca solo; señal "Tap"), sobre `KitTreadmill` (atributos Stat y Gain, respeta la zona con `Gates`); todo × `BoostService.multiplier(player, multiplier or id)` (se registran los "Mult_<stat>"); con `currency` va a esa moneda; con `walkSpeed` pone `BaseWalkSpeed` y `KitWorld.applySpeed` (también al reaparecer); `SetStatCap(id, 0..1)`; `resetOnRebirth`; atributo del jugador con el id (tabla de jugadores); `Stats.value(player, id)` y `Stats.add` para Zones, Stages y Wild; premio "Stat:<id>"; señal "<id>Gained". Tipo `StatsState`.
  - El cuadro de tareas de Claude se rehízo en esta sesión (el usuario no lo veía): hitos 0–2 como tareas hechas y una tarea por cada fila pendiente de la sección 4.
  - El usuario pidió de nuevo: "Acordate de mandarme cada tanto una prueba, tipo foto, audio, etc. con lo que aplique y tenga sentido mostrar" (sección 2).

- **Hito 3 terminado (2026-11-02): bloques Zones, Stages, Fishing, Garden, Search, Wild, Upgrades, Tycoon e Items.** Chequeo en verde, un push por bloque. Todos con el diseño de `bloques.md` (tabla del catálogo puesta al día con los remotes y premios reales).
  - **Zones:** en orden, la primera abierta; abiertas para siempre; se compran (`UnlockZone`, prompt en la puerta) o se abren solas al llegar a la estadística o los renacimientos; regiones `KitZone` vigiladas (quien entra sin tenerla vuelve a su base); `KitTeleport`; registra `Gates`; premio "Zone:<id>". Tipo `ZonesState`.
  - **Stages:** obby con checkpoints que validan el requisito de la estadística, reaparecer en la etapa, meta con premio × multiplicador de su moneda, `returnToStart`; corrida (`run`) con muerte, `Revive()` gratis o comprado ("Stages:Revive" se guarda si no está muerto) y `EndRun()` con resumen (premio × etapas). Reaparece en la etapa 0.15 s después que la base. Tipo `StagesState`.
  - **Fishing:** `CastLine()` cerca del borde del agua (castRange 40), picada al azar / velocidad de caña × (1 − "reel"), `ReelLine()` en la ventana; suerte = caña × Luck; `BuyRod`; "Rod:<id>". Tipo `FishingState`.
  - **Garden:** `Lib/GardenShop.luau` + test (reposición por reloj real igual en todos los servidores); parcelas en la base con prompt que cambia (Plant / Growing... / Harvest); crecimiento por `readyAt` (sin conexión); mutación con `mutationChance`; "Seed:<id>" y "Garden:Skip". Tipos `Plant`, `GardenState`.
  - **Search:** `DigPile()` o el prompt de la pila; mochila; depósito al inventario o vendido con `depositCurrency`; "Tool:<id>". Tipos `Found`, `SearchState`.
  - **Wild:** criaturas que deambulan por área con `Heartbeat`; captura midiendo en el servidor el tiempo apretado (`PromptButtonHoldBegan`); requisito de estadística; `toBase`.
  - **Upgrades:** `BuyUpgrade(id)`, "stat:" en BoostService (add/mult por nivel), efectos de bloques por `Bonus` (registrado en `init`); robux solo por "Upgrade:<id>". Tipo `UpgradesState`.
  - **Tycoon:** botones que se pisan, edificios escondidos en `ServerStorage` hasta comprarse, ingreso por `Plots.addStored` (nuevo). Tipo `TycoonState`.
  - **Items:** `UseItem(id)`: impulso (`boost`, ahora opcional) y/o `walkSpeed` (campo nuevo) por `seconds`; "Item:<id>" sin tope. Tipo `ItemsState`.
  - Imagen de prueba enviada al usuario con la lógica real (100.000 huevos con y sin suerte, mutaciones, espacios, robo).

- **Hito 4, parte 1 (2026-11-02): productos de los bloques en la tienda.** Chequeo en verde.
  - `ShopConfig`: campo `kit` en productos y pases (sin ese bloque en la receta no se ofrecen: `ShopConfig.inRecipe(kit)`, usado por `ShopController`). Pases nuevos del núcleo: `SellAnywhere` (sell) y `AutoClicker` (stats); `AutoCollect` y `ExtraSlots` marcados plots. Productos nuevos: `FinishMerge` ("Merge:Skip"), `GrowAll` ("Garden:Skip"), `Revive` ("Stages:Revive"), sección "Kit" (Special).
  - La receta vende lo suyo en `shop = { products, passes }` (tipos `ShopProduct`, `ShopPass`, `KitShop`): se suma a `ShopConfig`; `KitCheck` lo revisa (claves que no choquen con el núcleo, secciones válidas, premios que existan) y sus pases cuentan para el resto de la receta (x3/x8 huevos, auto tirada). Test nuevo en `KitCheck.spec`.

- **Hito 4, parte 2 (2026-11-02): UI de los bloques (#61).** Chequeo en verde, un push por tanda.
  - `client/Kits/KitUi.luau`: `invoke`/`ask`/`fire`, avisos de error en inglés por código (`UiText.ERR_*`, sin repetir el mismo en 1,2 s), `unitName`/`unitLine`/`showUnit`/`toast`/`announce` (popup desde Epic o si es nueva), precios y `notEnough` (abre la tienda si la moneda se vende), `ownsPass`, `productFor("<Prefijo>:<id>")`, `buyProduct`/`buyPass` (Bus de `ShopController`: `BuyProduct`, `BuyPass`, `RobuxPrice`), `listWindow` (filas con ícono, título, detalle o barra de nivel, calcomanía y 1–2 botones; **se actualizan en el lugar** si no cambia la forma, para no rehacer botones bajo el dedo), `menuButton` (no agrega botón si la ventana está en `map.shops`: el teléfono tiene 8 lugares), reglas de prompts (Steal propio; SlotShop y GardenTile ajenos: se esconden con distancia 0, sin pisar el `Enabled` del servidor) y puestos que abren ventanas (`RollStation`, `KitShopStand` con `Window`/`Label`, `KitUpgradeStation` con `Upgrade`).
  - `Inventory` (grilla con lo mejor primero, fichas que se crean una vez por unidad; panel con Equip/Unequip, Place/Pick Up, Sell con el valor real, Merge con "2/3", candado; Equip Best, Sell All con oferta del pase, Finish Now, comprar espacio), `Units` (carteles sobre cada unidad del mundo: nombre, rareza, $/s, precio en la cinta, requisito, "Being stolen!"), `Followers` (mascotas que siguen a todos los jugadores, locales y con gráficos bajos solo las propias), `Base` (lo cobrado vuela al contador), `Rolls` (probabilidades con la suerte y las mutaciones, x1/x3/x8 con pase, gratis con reloj, Auto, revelado con temblor, destello, NEW! y rayos), `Stats` (columna del HUD, TAP! con "+N", Auto Clicker, tope de velocidad), `Zones` (puertas locales, ventana Worlds), `Stages` (etapa en el HUD, YOU WIN!, revivir y resumen), `Fishing` (Cast/REEL! con "!" sobre la cabeza, cañas), `Search` (Dig al ritmo de la herramienta, mochila, flechas al depósito), `Wild`, `Garden` (Seed Shop con reposición calculada en el cliente, elegir semilla, Grow All, parcela; relojes sobre las parcelas), `Upgrades`, `Items` (teclas 1–9), `Steal` (flechas a la base, alarma, Push), `Extras` (cinta y tycoon), `Gear` (filas de cañas y herramientas).
  - Teclas: F toque, R pesca, G cavar, Q empujar, 1–9 objetos (E es de los prompts).
  - Servidor: `SellUnits`/`SellAll` devuelven `SELL_FAR` o `EMPTY`; la cinta pone `Price` en cada unidad para su cartel.
  - Maqueta con los íconos nuevos (HTML con el material del kit) enviada al usuario; la captura real sale de Studio.
- **Íconos con ChatGPT (#68, 2026-11-02).**
  - 27 íconos nuevos en `assets/ui/hud-icons` (63 en total): los que usa la UI y no tenían imagen (merge, tap, steps, pad, seed, base, map, battle, shield, check, spin, codes, luck, money_boost, friends, search, notifications, egg_gold) y los 9 huevos por rareza. 5 modelos nuevos en `tools/render3d/icons/models.js`; recetas `hud-e-armador`, `hud-f-armador`, `hud-g-huevos`.
  - 9 mascotas cúbicas en `assets/ui/pet-icons` (receta `mascotas.json`, base: renders de Kenney Cube Pets, CC0) para los íconos de unidad de las recetas.
  - Todo con la API de OpenAI (`tools/imagegen.py`, `gpt-image-2.5-flare`, calidad alta). Falta subirlos a Roblox (`tools/roblox_upload.py`, con la clave de Open Cloud): mientras tanto la UI muestra el emoji de respaldo.
- **Más arte con ChatGPT (2026-11-02).** Cada tanda con su prueba enviada al usuario.
  - **Tienda:**
    - 27 imágenes para pases y productos en `assets/ui/store-art`; el campo `uses` de su `manifest.json` dice cuál va con cuál.
    - `tools/storeart.py` corta las hojas y les pone el rótulo.
  - **Pantalla de carga:**
    - Código en `template/src/first/` (ReplicatedFirst): fondo, título dorado, progreso real, consejos y Skip.
    - Fondo hecho con IA en `assets/ui/loading`.
  - **Unidades y zonas:**
    - 54 íconos de unidades de muestra de las nueve recetas en `assets/ui/unit-icons`.
    - 9 fotos de zona en `assets/ui/zone-art`.
  - **Insignias:**
    - Código: `Config/BadgeConfig` (9 insignias con reglas) y `server/Social/Badges` (`AwardBadgeAsync`, marca en `data.badges`).
    - 9 imágenes en `assets/ui/badge-art`.
- **MapKit (#62, 2026-11-03).** Chequeo en verde.
  - **Plan del mapa como datos:** `shared/Lib/MapPlan.luau`, probado en `tests/MapPlan.spec.luau` (10 casos con cuatro recetas de prueba). Dibuja:
    - plaza con spawn y pasos en cruz;
    - puestos, tablas, ruleta y cofre en anillos, mirando al centro;
    - arco NEXT UPDATE;
    - fila de venta, mejoras y fusión;
    - bases a los lados de una avenida con la cinta, de tamaño según lo que llevan (espacios, parcelas y edificios del tycoon);
    - islas de zonas con puentes, puertas, estaciones de tiradas y cuatro lotes para cintas de correr, agua, pilas y salvajes;
    - etapas sobre el vacío con huecos que se saltan caminando;
    - pisos flotantes con barranco, temas y biomas por nombre de zona, y decoración donde quede libre.
  - **Huellas en el piso:** cada pieza reserva su lugar como un rectángulo girado. Los tests revisan:
    - que nada choque y que lo que se usa esté sobre un piso;
    - que cada bloque encuentre sus etiquetas y atributos;
    - que no haya avisos y que el mismo nombre dé el mismo mapa.
  - **`server/Map/MapKit.luau`:**
    - arma el plan, con grupos por clave única, elipses con SpecialMesh y luz de hit;
    - solo si la receta trae `map` y no hay una carpeta `Map` hecha a mano;
    - sin `GameConfig.GROUP_ID` no pone el cofre.
  - **Tablas de posiciones del mundo:**
    - `server/Social/GlobalLeaderboardService` usa OrderedDataStore y guarda solo si el valor cambió, mirando el presupuesto antes de escribir. Los límites están verificados en creator-docs. En Studio sin acceso a la API muestra a los del servidor.
    - Los valores se codifican con `Lib/Ranking`, que tiene su test.
    - `client/Controllers/LeaderboardController` dibuja la tabla con medallas, foto (`rbxthumb`), nombre y valor, y resalta la fila propia.
  - **Cofre del grupo:** prompt local en `SocialController` (`Bus "ClaimGroup"`). Ya cobrado, el cofre dice CLAIMED.
  - **Puestos:** el de "Robux" abre la tienda en la sección Currency.
  - **Zonas:** el teletransporte llega a la cara de abajo de la región `KitZone`; antes caía desde arriba de la caja.
  - **Vista previa sin Studio:**
    - Comando: `node tools/render3d/mapview.cjs --recipe <receta.luau> --out <prefijo>`. Vuelca el plan con `map/dump.luau` y lo dibuja con three.js, con los carteles del juego.
    - Ejemplos en `skills/roblox-game-kits/references/mapa/`; se mandaron al usuario.
  - **Documentación:** sección "El mapa" de `bloques.md`.
- **Mapa estilo hit (2026-11-03, pedido del usuario).** Chequeo en verde.
  - **Investigación:** miniaturas oficiales y fotogramas de videos de gameplay de Steal An Egg, Steal a Brainrot y Fish It! (las capturas de otros juegos no se guardan en el repo ni se usan de referencia para la IA). Notas en `bloques.md`, "El mapa".
  - **MapPlan:**
    - piso y caminos de plástico con studs, paletas más saturadas y plaza con anillo de color;
    - corrales con cerco o edificios (`map.bases`), con pedestales, placa de cobro verde y cartel de madera;
    - puestos de madera con toldo a rayas y aro brillante, y tabla con corona;
    - alfombra roja con arco como cinta y máquina de fusión de bloques de colores;
    - faroles, arbustos y flores;
    - cerros en terrazas o mar (`map.backdrop`);
    - islas con cerco de madera y arco con el nombre de la zona, carpa sobre las cintas de correr, muelle de tablas y corral para los salvajes;
    - vitrina con la unidad gigante (`map.showcase`, etiqueta `KitShowcase`, `server/Map/Showcase`).
  - **Tests:** `MapPlan.audit` (la revisión común), vitrina, arcos y estilos de base: 12 casos.
  - **Vista previa:** dibuja los studs y la unidad de la vitrina. Ejemplos nuevos en `references/mapa/`.
- **Nueve recetas (#63, 2026-11-03).** Chequeo en verde, un push cada tres.
  - **Archivos:** `template/src/shared/Kits/Presets/`:
    - StealAndPlace, HatchAndCollect, PlusOneEscape;
    - Fishing, SearchAndDig, GrowGarden;
    - MergeTycoon, RunAndCatch, CozyTycoon.
  - **Cada receta trae:**
    - unidades de muestra con ícono (unit-icons y pet-icons) y emoji de respaldo en `Icons.luau`;
    - economía que arranca con $10;
    - de 8 a 9 objetivos que enseñan el loop y 5 misiones;
    - tienda propia y mapa.
  - **Núcleo:**
    - la receta puede traer su `rebirth` (moneda, costo y lo que multiplica; los textos del renacer lo dicen) y su `endless` (objetivo sin fin);
    - KitCheck valida los eventos de objetivos y misiones contra `KitCheck.SIGNALS`.
  - **Tests:**
    - `tests/Presets.spec.luau`: KitCheck, objetivos y misiones, mapa sano y completo, íconos con respaldo y que lo primero se pague;
    - `tests/MapExpect.luau`: lo que cada bloque busca en el mapa (compartido con MapPlan.spec).
  - **Vista previa** de los nueve mapas en `skills/roblox-game-kits/references/mapa/recetas.jpg`; se mandó al usuario.
  - **Pedido del usuario:** "Esto sería simplemente un ejemplo, ¿no? Después cada juego usa esto mucho más preparado y personalizado, ¿no?". Respuesta: sí. Las recetas y su mapa son muestras de cada fórmula. Cada juego copia la receta, hace propio el contenido y fija el mapa en Studio para editarlo (`bloques.md`). Este flujo va en el skill del armador (#65).
- **Juego de prueba rehecho con el armador (#64, 2026-11-03).** Chequeo en verde.
  - `games/prueba`, "Steal & Fuse Critters", es ahora la plantilla actual con su receta en `src/shared/Config/KitConfig.luau`:
    - 8 critters en niveles, con fusión de a 2;
    - bases con traba, cinta con pesos de la spec, robo con empujón;
    - el onboarding de la spec como objetivos;
    - renacer propio y mapa con vitrina del Crystal Dragon.
  - La versión anterior (servicio `Critters`, hitos 1 y 2) quedó en el historial de git.
  - Cada mecánica de la spec y lo que el armador todavía no tiene está en `games/prueba/docs/decisiones.md`: cinta VIP, Lucky Fuse, Long Lock, Fast Thief, fusionador por base y renacer por critter.
  - **Plantilla:** test nuevo `tests/KitConfig.spec.luau`. Revisa la receta activa de cada juego (KitCheck, mapa e íconos); en la plantilla, con "None", no hay nada que revisar.
  - **Íconos:** 8 critters y un huevo con ChatGPT (receta `unidades-critters.json`) en `assets/ui/unit-icons/critters`; unit-icons queda con 63. Con emoji de respaldo en el `Icons.luau` del juego.
  - **Docs:** `games/prueba/README.md` (cómo probarlo en Studio y cómo fijar el mapa) y vista previa del mapa en `games/prueba/docs/`.
- **Skill del armador (#65, 2026-11-03).**
  - **`skills/roblox-game-kits/SKILL.md`:**
    - cuándo usarlo;
    - flujo de nueve pasos: elegir la fórmula, copiar la receta, hacerla propia en orden (tema, unidades, economía, objetivos, tienda y mapa), validar, ver el mapa, arte con IA, probar en Studio, fijar el mapa y mostrar;
    - cómo agregar una opción, un bloque o una receta;
    - reglas y salida.
  - **Sección "Con el armador"** en los demás skills: ideación, clonación, UI, monetización, seguridad, QA, publicación, live ops, métricas, cumplimiento y campañas.
  - **`CLAUDE.md`:** la fase 2 del pipeline nombra al armador.
  - **`template/README.md`:** las recetas, lo que reemplazan del núcleo y el mapa.
- **Skill de game feel (#66, 2026-11-03).**
  - **`skills/roblox-game-feel/SKILL.md`:**
    - la escalera de respuesta: toque, ganancia, logro, celebración y error, con su sonido, pantalla, mundo y cámara;
    - el flujo de un momento nuevo: `KitFx` → `Bus.on("Kit:X")` → las piezas de KitUi, Juice, Effects y Sound;
    - reglas: el efecto celebra y el servidor da; sin urgencia falsa; medida; Low Graphics; música a 0,25.
  - **`references/momentos.md`:** qué hace hoy cada momento del núcleo y de los bloques (sacado del código), e ideas para el próximo pase.
  - **Código:**
    - `Effects` respeta Low Graphics: un tercio de las partículas (`Effects.setLowGraphics`, conectado en `Main.client`);
    - `KitUi.coinsTo` (la plata vuela al contador) en cobrar, vender y depositar;
    - el empujón ahora suena y sacude.
  - **Juego de prueba:** se le pasaron a mano los mismos cambios de la plantilla.

    Trampa: cada juego es una copia y no recibe solo las mejoras de la plantilla. Resuelto con `tools/sync_template.py` (ver §9).
- **Juegos al día con la plantilla (2026-11-03).**
  - **`tools/sync_template.py games/<juego>`:** compara el núcleo (`src/` y `tests/`, menos `src/shared/Config/`) con la plantilla.
    - Copia lo nuevo o cambiado con `--apply` y borra lo que la plantilla borró (lo sabe por el historial de git); sin `--apply`, solo lo muestra.
    - `--diff` muestra los cambios de la configuración de la plantilla (sin la receta) para pasarlos a mano.
    - Nunca toca la configuración del juego: la lista para revisarla a mano y dice qué claves nuevas de `UiText` le faltan.
    - Avisa los archivos que el juego tiene y la plantilla no, sin borrarlos.
    - Respeta los archivos del núcleo que el juego hizo suyos a propósito: una ruta o patrón por línea en `games/<juego>/sync-ignore.txt`.
  - **`tools/check.py`:** corre su selftest y avisa, sin fallar, los juegos con el núcleo atrasado.
  - **Emojis de respaldo en la receta:** `iconFallbacks` (`{ pebble_pup = "🐶" }`), validado por KitCheck. Así `Icons.luau` es igual en todos los juegos y el juego de prueba quedó sin diferencias de núcleo.
- **Documentación al día (#67, 2026-11-03).**
  - **`CLAUDE.md`:** la estructura del juego con el armador y el mapa, el paso 9 de "Empezar un juego nuevo" (`sync_template.py`) y la herramienta nueva.
  - **`ROADMAP.md`:** la fase D (juegos estilo top hit) con su estado, y C2 al día.
  - **`como-son-nuestros-juegos.md`:** los mapas con MapKit, la plantilla con el armador, la fase 2 con el armador, el pase de jugo y los pedidos del 30/10 al 3/11.
  - **`hits-2026.md`:** lo visto en los mapas de los hits, cada fórmula con su receta, y tres referencias que ya no existían (un skill `roblox-retention`, `client/Juice` y `ProductService`).
  - **`README.md`:** la guía central, el armador, el traspaso y los pendientes.
  - **`team/`:** tablero al día (Chicken Farm, Ride a Dino e íconos con OpenAI, hechos) y decisiones con la más nueva arriba.
- **Revisión completa (#69), parte 1 (2026-11-03).**
  - **Chequeo cruzado nuevo** (`tools/xref.py`, paso de `tools/check.py`): lo que los tipos no ven porque se nombra con un texto.
    - Eventos KitFx con quien los escuche, remotes que el cliente usa y que existen, `Bus.call` con su `Bus.handle`, `Bus.on` con su `Bus.emit`.
    - Sonidos, voces y música que existen en `AudioConfig`; íconos con emoji de respaldo.
    - En los `.md`: rutas y funciones citadas que existen.
  - **Seguridad:** `PlantSeed` y `HarvestPlant` dejaban plantar y cosechar desde cualquier lugar, sin medir la distancia. Se sacaron: se planta y se cosecha con el prompt de la parcela, que la mide en el servidor.
  - **Botón LOCK** en la barra de acción, estando en la base, con la traba y la espera a la vista. Lo pedía la spec del juego de prueba y el remote `LockBase` existía sin pantalla.
  - **Compras con monedas de ShopConfig.ITEMS** (con InventoryService y data.inventory): no tenían pantalla ni efecto desde que se rehízo la tienda, así que se sacaron. Lo que se compra con monedas lo dan los bloques.
  - **Docs con nombres viejos**, corregidos: OnboardingConfig, GameplayConfig, ShopService.hasPass (es `ShopService.ownsPass`), GAME_PASSES (es `PASSES`) y el ejemplo de RequestPurchase. Lo que ya no existe se escribe sin formato de código: el chequeo de los docs revisa lo que va entre comillas invertidas.
  - **`sync_template.py`:** borra lo que la plantilla borró, `--diff` muestra la configuración y la receta no se compara. `games/prueba` quedó al día con la herramienta.
- **Revisión completa (#69), parte 2: voces de anunciador (2026-11-03).** Solo sonaban 2 de las 10 ("REBIRTH!" y "JACKPOT!").
  - `KitUi.cheer`: la rareza desde `units.announceFrom` ("LEGENDARY!") o una mutación desde x3 ("SO LUCKY!"), en cada popup de unidad y en el mejor resultado de un huevo.
  - "NEW RECORD!" la primera vez que una corrida pasa el mejor anterior; "DOUBLE MONEY!" cuando arranca un x2 de plata.
  - `Sound.voice` espera `AudioConfig.VOICE_COOLDOWN` (2,5 s) entre voces. Tabla de qué voz suena dónde: `skills/roblox-game-feel/references/momentos.md`.
- **Revisión completa (#69), parte 3: compras, robo, datos y aleatorio pago (2026-11-03).**
  - **Recibos:** bien. Se otorgan una sola vez, se confirman solo si quedaron guardados, y el canal de anuncios con premio (`ProductPurchaseChannel.AdReward`) está verificado en la documentación oficial.
  - **Robo y regalos:** después de un robo se guarda ya a la víctima, y después de un regalo de pase, al que lo recibe. Antes, una caída del servidor justo ahí podía duplicar una unidad o perder un regalo pagado.
  - **Fusión:** bien. Consume las unidades antes de dar el resultado.
  - **Aleatorio pago** (regla oficial releída hoy). La plata del núcleo se vende por Robux, así que un huevo pagado con plata es aleatorio pago, y el chequeo solo lo pedía para monedas de la receta. Nuevo `Lib/PaidRandom` (con tests):
    - las tiradas con precio en una moneda que se vende son aleatorio pago solas;
    - la fusión con `mutationChance` muestra "Merge Odds" y, a quien PolicyService se lo restringe, nunca le da mutación;
    - la tienda de semillas muestra las probabilidades de mutación y tamaño de la cosecha, y la cosecha de quien está restringido sale sin azar (`Units.add` con `fixed`).
    Detalle en `roblox-compliance`, "Con el armador".
- **Revisión completa (#69), parte 4: lo que el juego de prueba pedía y el armador no tenía (2026-11-03).**
  - `plots.lock.pass` + `passSeconds` ("Long Lock") y `steal.fastPass` + `fastSpeed` ("Fast Thief").
  - Fusión: `merge.odds` (la probabilidad de cada mutación), `keepMutation` (no se pierde la mejor) y `merge.lucky` con el premio `"Merge:Lucky"` ("Lucky Fuse", cargas guardadas en los datos).
  - `games/prueba` los usa, junto con "Buy a Zapfrog" (compra directa).
  - Queda en su backlog: la cinta VIP, el escudo de 15 min, un fusionador por base, el renacer que pide una unidad y el álbum de variantes.
  - Tabla de lo que se vende desde los bloques: `skills/roblox-game-kits/references/bloques.md`.
  - **Cierre de la revisión:** `tools/check.py` en verde con el paso nuevo de referencias cruzadas, y la plantilla y `games/prueba` sin diferencias de núcleo.
- **Meshy y Blender para la nube (2026-11-03).** El usuario preguntó cómo conectarlos.
  - **Meshy:** la red de la nube llega a `api.meshy.ai` (probado). Falta la clave como secreto del entorno.
    - El MCP de `.mcp.json` es para Windows (`cmd /c`), así que en la nube se usa `tools/meshy.py`: Image to 3D con el ícono como referencia.
    - La herramienta espera con `Retry-After`, baja enseguida el modelo, la textura y las vistas, y siempre pide una malla que entra en Roblox (5.000 caras por defecto, máximo 20.000).
    - Tiene selftest sin red en `check.py`.
  - **Blender:** el MCP necesita el Blender de una PC. En la nube va sin pantalla, instalado por el *setup script* del entorno (script en `conectores.md`). El modo automático no dejó bajarlo y ejecutarlo desde la sesión.
  - **Próximo paso con la clave:** la sección 4, "Próximo paso: modelos 3D de los critters".
- **Guía paso a paso para las personas (#72, 2026-11-03).** El usuario pidió "un archivo con qué tengo que hacer, qué instalar y qué correr": `team/paso-a-paso.md`.
  - Nueve pasos en orden (nube, PC, Studio, grupo, Dashboard, subidas, lanzamiento, después del lanzamiento y PR), con quién, tiempo, comandos y la frase para pedirle cada cosa a Claude.
  - Verificado en `Roblox/creator-docs` ese día: Server & Clients y el botón Client/Server para probar, Experience Settings → Security para el acceso a API, grupo de 100 Robux, insignias en Engagement → Badges, y la venta fuera del juego (Monetization → Shop → Listed; ver `roblox-monetization`).
  - Al resolver un punto, marcarlo en los dos archivos.

## 6. Qué existe hoy (mapa)

- **Pipeline:** 11 skills en `skills/` (idea, diseño, UI, monetización, seguridad, QA, cumplimiento, publicación, campañas, métricas, live ops) y guías en `skills/_shared/`.
- **Herramientas** (`tools/`): `check.py`, `sync_template.py`, `roblox_research.py`, `assets_import.py`, `roblox_upload.py`, `imagegen.py`, `thumbs.py`, `iconsheet.py`, `vfx_textures.py`, `ui_textures.py`, `flat_icons.py`, `render3d/`, `campaigns.py`, `analytics.py`.
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

### UI de los bloques (#61): hecha el 2026-11-02 con este plan (detalle en la sección 5)

- `client/Kits/KitUi.luau` primero: `invoke`/`fire` a los remotes, avisos de error en inglés por código (`KitFx "Error"`: FULL, NOT_ENOUGH, LOCKED, PROTECTED, ZONE, FAR, BAG_FULL, WEAK...), `Bus.call("ShowReward", popup)` para lo conseguido, una ventana de lista para tiendas de bloque (mejoras, cañas, herramientas, semillas; filas como `QuestController`: `UIKit.fitHeight(fila, 7.4, 64)`) y reglas de prompts (el dueño no ve "Steal" en lo suyo; en bases ajenas no se ven SlotShop ni GardenTile; volver a aplicarlas si el servidor cambia `Enabled` o el `Owner` de la base). Abrir ventanas con `ProximityPromptService.PromptTriggered` (prompt "RollStation" con atributo Roll) y prompts locales en `KitShopStand` (atributo Window).
- Después, un módulo por bloque en `client/Kits/` sumado a `BLOCKS` de `client/Kits/Kits.luau`: inventario de Units (tarjetas con ícono, nombre con su variante, lo que da; acciones Equip, Place/Store, Sell, Lock, Merge; "Equip Best" y "Sell All"), ventana de tiradas con probabilidades (`Rarity.percentages` con la suerte) y animación de revelado, mascotas que siguen (atributo `Equipped`), barra de acción (TAP, Cast/Reel, Dig, Sell All, Push, Lock, objetos con teclas 1–9), tienda de semillas con reloj, puertas y barreras con choque local, etapa en el HUD y popup de revivir/resumen. Al terminar, mandar una imagen (sección 2).

## 8. Lo que depende de las personas

En orden y con los comandos en **`team/paso-a-paso.md`**; lista completa y con casillas en **`team/pendientes.md`** (al marcar un punto, marcarlo en los dos) (pedido del usuario del 2026-10-30: "que api keys necesitás, qué conectores hay que poner, etc."). Mantenerla al día en cada hito y repetirla en el reporte final (#70). En resumen:

- **Claves** (variables de entorno de cada PC o *Network secrets* del entorno de la nube; nunca en el repo ni en el chat): `OPENAI_API_KEY` (obligatoria para íconos y miniaturas), `GEMINI_API_KEY` (recomendada), `MESHY_API_KEY` (plan Pro), `ROBLOX_OPEN_CLOUD_API_KEY` + `ROBLOX_CREATOR_GROUP_ID`, `ROBLOX_ANALYTICS_API_KEY` y `ROBLOX_ADS_API_KEY`. En la nube: `OPENAI_API_KEY` cargada en el entorno el 2026-11-02 (probada); las demás, no. Gemini dio OR_BACR2_59 al activar la facturación.
- **Conectores:** MCP de Roblox Studio, Rojo, MCP de Blender y MCP de Meshy en cada PC; ElevenLabs, Higgsfield y GitHub ya conectados en la cuenta de Leonel (Luciano los conecta en claude.ai). Meshy no arranca en la nube (`.mcp.json` usa `cmd`).
- **Roblox:** grupo dueño (`GameConfig.GROUP_ID`), 2FA y documento verificado, productos y pases con sus ids en `ShopConfig`, suscripción en Robux, anuncio con premio recién cuando se cumplan sus requisitos, cuestionario de madurez, traducción automática, *Max Players* = bases de la receta.
- **Pruebas en Studio:** UI v3 (Luciano), los bloques del armador con su UI (2026-11-02) y el juego de prueba rehecho.
- **Subir a Roblox** los 63 íconos y las 9 mascotas (`tools/roblox_upload.py`) y poner los ids en `AssetIds.icons`.
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
- **Chequeo antes de subir:** `python tools/check.py | grep ... && git commit` sube aunque falle (el código de salida es el del último comando del caño). Guardar la salida en un archivo, mirar `$?` y recién ahí commitear (el 2026-11-02 se subió un commit con el chequeo en rojo y se arregló en el siguiente).
- **Heredoc sin comillas:** `python3 - <<EOF` ejecuta lo que esté entre comillas invertidas (`tools/x.py`) y lo borra del texto. Para escribir Markdown desde un script, `<<'EOF'` (con comillas).
- **Recetas de íconos:** el autotest de `imagegen.py` cuenta los objetos por ") " en el prompt: nada de paréntesis dentro de las descripciones.
- **ActionBar:** cada botón con su tecla; la misma tecla en dos botones visibles dispara los dos.
- **Forma Ball:** Roblox la deja siempre pareja. Para una elipse (copa de árbol, huevo, roca): bloque con `SpecialMesh` tipo Sphere (`mesh = "Sphere"` en MapPlan); choca como caja.
- **Cuñas:** la `WedgePart` es alta atrás (+Z) y baja hacia su frente (−Z). Un techo que baje hacia quien mira al puesto va girado 180 más que el mostrador.
- **Huellas giradas:** para ver si dos cosas giradas chocan, comparar rectángulos girados (ejes separadores, `MapPlan.overlaps`), no las cajas que los contienen. Las cajas dan falsos choques y dejaban sin lugar a la mitad de los puestos.
- **`require` del CLI de Luau:**
  - la ruta tiene que empezar con `./` o `../`;
  - no puede salir de la carpeta de arriba del todo;
  - para leer una receta de afuera del repo, `mapview.cjs` la copia a `tools/render3d/map/.preview/`.
- **Tests con tipos:** `tools/check.py` también revisa los tipos de `tests/`, así que valen las mismas trampas de luau-lsp.
- **Comparar textos ya refinados:** después de `a.kind == "decor"`, luau-lsp toma `a.kind` como el literal "decor" y marca error al compararlo con otro ("Type "area" cannot be compared with "decor""). Juntarlos en un texto o usar variables nuevas.
- **Los docs también se chequean:** `tools/check.py` revisa las rutas y funciones citadas entre comillas invertidas en todos los `.md`. Correrlo después del último cambio, también si es solo de docs, y recién ahí commitear (el 2026-11-03 un commit quedó en rojo en GitHub por escribir en el traspaso un nombre recién borrado). Lo que ya no existe se escribe sin formato de código.
- **Juegos que se quedan atrás:** cada `games/<juego>` es una copia de la plantilla y no recibe solo sus mejoras.
  - `python tools/sync_template.py games/<juego>` muestra qué cambió y `--apply` copia el núcleo; nunca toca `src/shared/Config/`.
  - `tools/check.py` avisa los juegos atrasados.
  - Lo propio de un juego va en su `Config/` (la receta, con `iconFallbacks` para sus emojis). Un cambio del núcleo hecho solo en un juego se pierde en la próxima sincronización: llevarlo a la plantilla.
- **Investigar un hit sin navegador:**
  - miniaturas oficiales: `thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=<id>`;
  - ids de videos: `curl` de `youtube.com/results?search_query=...` con `"videoRenderer":{"videoId"`;
  - fotogramas de esos videos: `i.ytimg.com/vi/<id>/hq1.jpg` a `hq3.jpg`.
- **En la nube de Claude:**
  - create.roblox.com está bloqueado: la documentación sale del repo `Roblox/creator-docs`, por `raw.githubusercontent.com`;
  - las imágenes de esa documentación están en Git LFS y se bajan de `media.githubusercontent.com`;
  - Playwright está instalado global en `/opt/node22/lib/node_modules`.
