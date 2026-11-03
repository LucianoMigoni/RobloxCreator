# Paso a paso: qué hacer, qué instalar y qué correr

Lo que falta del lado de las personas, en orden y con los comandos. Los detalles (permisos y costo de cada clave, conectores, requisitos de Roblox) están en `team/pendientes.md`, y la instalación explicada en `SETUP.md`. Al terminar un paso, marcá su casilla también en `team/pendientes.md` (o pedíselo a Claude, que marca las dos).

Actualizado el 2026-11-03. **Todo el trabajo está en la rama `leonelblumberg/quirky-dijkstra-2kxnwz`:** `main` sigue vacío hasta el PR (paso 9). Si algo falla, copiá el error y pegáselo a Claude (nunca una clave).

## Antes de empezar: las claves

- **Nunca** en el chat ni en un archivo del repo.
- **En tu PC:** en CMD, `setx NOMBRE valor`. Después cerrá y volvé a abrir la terminal y Claude Code.
- **En la nube** (Claude en la web o en la app): tocá el nombre del entorno en la barra de título de la sesión → **Edit** → **Network secrets** (en apps viejas, *API credentials*; si no aparece, *Environment variables*). La toma la sesión siguiente, no la abierta.
- Las de Roblox van solo en las PCs, y nunca se cargan en servicios de terceros.

## El orden

| Paso | Qué | Dónde | Quién | Tiempo aprox. | Para qué |
|---|---|---|---|---|---|
| 1 | Meshy (y Blender) en la nube | Claude en la web | Leonel | 15 min | Que Claude haga los modelos 3D de los critters |
| 2 | Instalar todo en la PC | Windows | Los dos | 1 h | Studio, Rojo y Claude Code en tu PC |
| 3 | Probar el juego en Studio | Studio | Los dos | 2 h | Saber qué arreglar antes de publicar |
| 4 | Grupo de Roblox y cuenta | Roblox | Leonel | 30 min | Que los juegos sean de los dos |
| 5 | Publicar en privado y cargar la tienda | Creator Dashboard | Leonel | 2 h | Pases, productos e insignias con sus ids |
| 6 | Subir íconos y sonidos | PC, con Claude | Leonel | 1 h | Arte y sonido propios en vez de emojis |
| 7 | Lanzar para 16+ | Studio y Dashboard | Los dos | 1 h | Jugadores reales y métricas |
| 8 | Después del lanzamiento | Dashboard y Ads Manager | Los dos | — | Métricas, campañas y menores de 16 |
| 9 | PR de la rama a `main` | GitHub | Leonel lo abre, Luciano lo aprueba | 15 min | Que el trabajo quede en `main` |

Los pasos 1 y 2 no dependen uno del otro. Mientras tanto, Claude puede seguir con lo suyo (al final: "Lo que le podés pedir a Claude").

## 1. Meshy en la nube (15 min) — Leonel

- [ ] Plan **Pro** de Meshy (20 USD/mes): https://www.meshy.ai/pricing. La API no anda en el plan gratis. Al pagar, confirmá que los créditos del plan sirven para la API; si no, comprá créditos de API. Los 8 critters cuestan unos **120 créditos**.
- [ ] Clave solo para la nube en https://www.meshy.ai/developers/keys (empieza con `msy_`). Ponele un límite mensual de créditos (por ejemplo, 300) y **ninguna** lista de IPs: en la nube cambian.
- [ ] Cargala en el entorno de la nube con el nombre `MESHY_API_KEY` (ver "Antes de empezar").
- [ ] Opcional: Blender sin pantalla, para revisar y exportar los modelos. En la misma pantalla del entorno, en **Setup script**, pegá esto (es el mismo de `skills/_shared/conectores.md`). Todavía no se pudo probar, y suma unos minutos al arranque de cada sesión:
  ```bash
  if [ ! -x /opt/blender/blender ]; then
    (apt-get update -qq && apt-get install -y -qq libegl1) || true
    curl -fsSL -o /tmp/blender.tar.xz https://download.blender.org/release/Blender5.2/blender-5.2.3-linux-x64.tar.xz \
      && mkdir -p /opt/blender && tar -xf /tmp/blender.tar.xz -C /opt/blender --strip-components=1 \
      && ln -sf /opt/blender/blender /usr/local/bin/blender && rm -f /tmp/blender.tar.xz \
      || echo "No se pudo instalar Blender"
  fi
  ```
- [ ] Abrí una **sesión nueva** y escribile: *"Leé team/traspaso.md y hacé los modelos 3D de los critters"*. Primero te muestra el costo sin gastar, después prueba con uno y te manda las vistas previas para que elijas.

## 2. Instalar en tu PC (1 h, una sola vez) — los dos

Cada punto está explicado en `SETUP.md`; el número entre paréntesis es su paso.

**Programas** (en este orden):
- [ ] Git for Windows: https://git-scm.com/downloads/win (1)
- [ ] GitHub CLI: https://cli.github.com (1)
- [ ] Python 3: https://www.python.org/downloads/, marcando **Add python.exe to PATH** (1)
- [ ] Node.js LTS: `winget install OpenJS.NodeJS.LTS` (1)
- [ ] Roblox Studio: https://create.roblox.com → descargar Studio (1)
- [ ] Claude Code: en PowerShell, `irm https://claude.ai/install.ps1 | iex` (1)
- [ ] Rokit: en PowerShell, `Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression`. Después cerrá y volvé a abrir la terminal (2).
- [ ] Opcionales: Blender 5.1 o más nuevo (https://www.blender.org/download/), uv (`winget install --id=astral-sh.uv -e`) y Obsidian (https://obsidian.md/download).

**Comandos** (en PowerShell):
```powershell
git config --global user.name "Tu Nombre"
git config --global user.email "tu@mail"          # el de tu cuenta de GitHub
gh auth login

# Si todavía no tenés el repo:
git clone https://github.com/LucianoMigoni/RobloxCreator.git
cd RobloxCreator
# Si ya lo tenías: entrá a la carpeta y corré "git fetch origin"

git switch leonelblumberg/quirky-dijkstra-2kxnwz     # la rama con todo el trabajo
git pull
powershell -ExecutionPolicy Bypass -File .\setup.ps1   # Rojo, luau-lsp, Luau, plugin de Rojo y skills (3, 4 y 11)
python -m pip install pillow
cd tools/render3d; npm install; npx playwright install chromium; cd ../..
python tools/check.py                                    # tiene que terminar en "Chequeo OK"
```

**Studio con Claude** (5):
- [ ] En Studio: **Assistant** → **…** → **Manage MCP Servers** → activar **Enable Studio as MCP server**.
- [ ] En **CMD** (no en PowerShell), una sola vez:
  ```bat
  claude mcp add Roblox_Studio --scope user -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
  ```
- [ ] Reiniciá Claude Code. Con Studio abierto, pedile *"llamá a list_roblox_studios"*: tiene que aparecer tu Studio.

**Claves en la PC** (en CMD; la de Meshy, distinta de la de la nube):
```bat
setx OPENAI_API_KEY "sk-..."
setx MESHY_API_KEY "msy_..."
```
Cómo sacar la de OpenAI: `team/claves-ia.md`. Las de Roblox van en el paso 6.

- [ ] Abrí Claude Code en la carpeta del repo y **aprobá** el servidor `meshy` cuando lo pida (7). `/mcp` tiene que mostrarlo conectado.
- [ ] Opcional, Blender con Claude (6): el add-on `mcp-1.0.3.zip` de https://www.blender.org/lab/mcp-server/ y el servidor en Claude (forma A o B de `SETUP.md`).
- [ ] Verificación final: `powershell -ExecutionPolicy Bypass -File .\setup.ps1 -CheckOnly` termina en **Todo listo**.

## 3. Probar el juego en Studio (2 h) — los dos

**Arrancar** (en PowerShell, desde la carpeta del repo):
```powershell
cd games/prueba
rokit install
rojo serve
```
En Studio: abrí una **Baseplate** nueva → **Plugins** → **Rojo** → **Connect** → **Play**. El servidor arma el mapa solo.

**Con ayuda:** con Claude Code abierto en tu PC y Studio conectado, pedile *"Probá games/prueba en Studio siguiendo la parte 3 de team/paso-a-paso.md y anotá lo que falle en team/pruebas/"*. Lo que él no puede juzgar (cómo se siente, cómo se ve en el teléfono) lo mirás vos.

**Qué mirar:**
- [ ] El loop, siguiendo el objetivo de arriba: comprar en la cinta, juntar en la placa verde, fusionar dos iguales, trabar la base y renacer.
- [ ] El botón **LOCK** (tecla L): aparece estando en tu base y cuenta la traba ("LOCKED 0:45") y la espera ("LOCK IN 1:30").
- [ ] **Merge Odds**, en el inventario: Normal 94 %, Gold 5 %, Rainbow 1 % y la línea de Lucky Fuse.
- [ ] El robo con dos jugadores: pestaña **Test** → menú desplegable → **Server & Clients**, con 2 clientes → **Play**. Robar de la otra base, empujar, la traba y las protecciones.
- [ ] Los pases, sin crearlos todavía: durante **Play**, pasá el botón **Client/Server** a Server y escribí en la barra de comandos:
  ```lua
  local p = game.Players:GetPlayers()[1]; p:SetAttribute("PassLongLock", true); p:SetAttribute("PassFastThief", true)
  ```
  La traba tiene que durar 120 s y llevar lo robado tiene que ser más rápido.
- [ ] Un jugador con los aleatorios pagos restringidos (también en Server):
  ```lua
  game.Players:GetPlayers()[1]:SetAttribute("PaidRandomRestricted", true)
  ```
  La fusión sale siempre Normal, Merge Odds muestra 100 % Normal y Lucky Fuse x10 no aparece en la tienda. Si eso ya pasa **sin** forzar nada, es que PolicyService falló en Studio (ante un error el juego restringe): anotalo y probá el resto con el atributo en `false`.
- [ ] El teléfono, con el emulador de dispositivos de Studio (Galaxy A06, iPhone con notch y tablet): el HUD táctil como `hud-hits/muestra-telefono.jpg`, nada en la zona del joystick y el ícono de Robux sin cuadrado. Sin Play, en la barra de comandos: `require(game.ReplicatedStorage.Shared.UIKit).selfTest()`.
- [ ] El mapa: que se parezca a `games/prueba/docs/mapa-hero.jpg` y que cada puesto abra lo suyo.
- [ ] El guardado, en una **copia de prueba** (nunca en el juego en vivo):
  1. **File** → **Publish As** → juego nuevo de prueba.
  2. **File** → **Experience Settings** → **Security** → activar **Enable Studio Access to API Services** → **Save**.
  3. Jugar, comprar algo, salir y volver a entrar: tiene que seguir ahí.
  4. Con dos ventanas de Studio a la vez, la segunda queda en "errored" mientras la primera tiene el bloqueo.
- [ ] Anotá lo que falle en `team/pruebas/`, un archivo por día como `team/pruebas/2026-10-26-plantilla-en-studio.md`, o pasáselo a Claude para que lo anote y lo arregle.

## 4. Grupo de Roblox y cuenta (30 min) — Leonel, con Luciano

- [ ] Crear el grupo (100 Robux): Creator Dashboard → selector de cuenta, arriba a la izquierda → **+** → logo y nombre → **Purchase**.
- [ ] Sumar a Luciano con un rol que pueda editar y publicar los juegos del grupo y manejar la monetización (pases, productos y suscripciones).
- [ ] Pasarle a Claude el id del grupo (no es secreto) para `GameConfig.GROUP_ID`: activa el premio por unirse al grupo.
- [ ] 2FA y verificación con documento en la cuenta que publica (y en la del dueño del grupo). Las piden el anuncio con premio y llegar a menores de 16, y suben el cupo de audio de 10 a 100 subidas por mes.

## 5. Publicar en privado y cargar la tienda (2 h) — Leonel

- [ ] Publicar `games/prueba` a nombre del grupo: con Rojo conectado, **File** → **Publish As** → el grupo → juego nuevo. Todavía sin hacerlo público.
- [ ] **Max Players** del lugar: 8, una base por jugador (`plots.count` de la receta).
- [ ] **Pases** (Monetization → Passes → **Create pass**) y **productos** (Monetization → Developer Products → **Create developer product**): son 8 pases y 19 productos. Los de bloques que la receta no usa (Grow All Plants, Extra Life, Sell Anywhere y Auto Clicker) no se ofrecen y no hace falta crearlos. El nombre, la descripción y el precio de cada uno están en `ShopConfig.luau` y en el bloque `shop` de `KitConfig.luau` (los dos en `games/prueba/src/shared/Config/`). La imagen sale de `assets/ui/store-art` (qué va con cuál: el campo `uses` de su `manifest.json`; ya tienen 512×512, el máximo). Más fácil: pedile a Claude *"armame la lista de pases y productos de games/prueba para cargar en el Dashboard"*.
- [ ] Copiar cada id (**…** → **Copy Asset ID**) y pasárselos a Claude: *"estos son los ids de los pases y productos: …"*. Él los pone en `passId` y `productId`; con id 0 no se ofrecen.
- [ ] **Insignias** (Engagement → Badges): las 9 de `BadgeConfig.luau`, con su imagen de `assets/ui/badge-art`. Son 5 gratis cada 24 h; las demás, al día siguiente (o 100 Robux cada una). Los ids, a Claude.
- [ ] **Suscripción VIP** (Monetization → Subscriptions), cobrada en Robux. Antes de crear la primera se elige un nombre corto del juego que **no se puede cambiar**. Su id, a Claude.
- [ ] **Venta fuera del juego:** en Monetization → Shop, marcar **Listed** los pases, las gemas y Zapfrog. Así también se venden en la página de inicio, en la búsqueda y después de comprar Robux, y quien compra entra con lo comprado. **No** listar:
  - los aleatorios (Lucky Fuse, Spins, 2x Luck): sus probabilidades se muestran en el juego, antes de pagar;
  - los que dependen de la partida (Finish Merge, el regalo) ni los de una sola vez (Starter Pack);
  - la plata: se calcula por lo que gana cada jugador, y a uno nuevo le rinde poco.
- [ ] Anuncio con premio: **todavía no**. Pide el juego público, el cuestionario de madurez aprobado y 2.000 visitantes únicos por mes; hasta entonces queda `ShopConfig.AD_REWARD.productId = 0`.

## 6. Subir íconos y sonidos (1 h) — Leonel, con Claude en la PC

- [ ] Clave de Open Cloud: Creator Dashboard → **Open Cloud** → **API Keys** → **Create API Key**, con el permiso **assets** (Read y Write), tu IP en *Accepted IP Addresses* y vencimiento. Después, en CMD:
  ```bat
  setx ROBLOX_OPEN_CLOUD_API_KEY "TU_CLAVE"
  setx ROBLOX_CREATOR_GROUP_ID "ID_DEL_GRUPO"
  ```
- [ ] Probar sin subir nada:
  ```powershell
  python tools/roblox_upload.py upload assets/audio/kenney/ui-audio/click1.ogg --lock games/prueba/assets.lock.json --dry-run
  ```
- [ ] Elegir los sonidos: escuchá las cuatro tomas (A a D) de cada efecto en `assets/audio/hit-sfx` y las voces de `assets/audio/hit-voices`, y decile a Claude cuáles quedan; él borra el resto.
- [ ] ElevenLabs con plan pago antes de publicar: lo hecho con el plan gratis no se puede usar en un juego publicado. Con el plan pago, pedile a Claude que rehaga los sonidos elegidos.
- [ ] Con Studio abierto, pedile a Claude en tu PC: *"Subí a Roblox los íconos, texturas, sonidos y la pantalla de carga de games/prueba con tools/roblox_upload.py, resolvé los ids de imagen con el MCP de Studio y completá AssetIds y LoadingConfig"*. Hasta entonces el juego muestra emojis y sonidos de la biblioteca de Roblox.
- [ ] Cuando estén los modelos 3D de los critters (paso 1): importarlos en Studio con el 3D Importer (Scale Unit: Studs) y dejarlos en `ReplicatedStorage.Assets.Units` con el nombre de cada unidad. Esto también se lo podés pedir a Claude en la PC.

## 7. Lanzar para 16+ (1 h) — los dos

- [ ] Pedirle a Claude las fases que faltan de `games/prueba` (ver el final): ícono, miniaturas, descripción, auditorías de seguridad y QA, y las respuestas del cuestionario de madurez.
- [ ] **Cuestionario de madurez** (Maturity & Compliance) completo. El juego sale primero solo para 16+.
- [ ] Traducción automática activada (18 idiomas; la explica el skill `roblox-publishing`).
- [ ] Ícono, miniaturas y descripción cargados (los arma Claude con `tools/imagegen.py` y `tools/thumbs.py`).
- [ ] Hacerlo público.

## 8. Después del lanzamiento — los dos

- [ ] Clave de analíticas (Open Cloud, permiso `universe.analytics:read`) en `ROBLOX_ANALYTICS_API_KEY` y pedirle a Claude *"hacé la fase de métricas de games/prueba"*.
- [ ] Campañas: clave de anuncios **de tu usuario** (`ad.campaign:read`, `ad.campaign:write` y `ad.billing:read`) en `ROBLOX_ADS_API_KEY` y medio de pago en Ads Manager. Gasta dinero real: Claude no lanza nada sin tu presupuesto aprobado.
- [ ] Anuncio con premio, cuando se cumplan sus requisitos (paso 5).
- [ ] Llegar a menores de 16: la cuenta dueña necesita verificación, 2FA y Roblox Plus o Premium durante 2 meses seguidos (o 1.000 Robux reembolsables por juego). El juego pasa una evaluación: 250 jugadas únicas de jugadores 16+ en 60 días y una revisión de seguridad; se sigue en el panel **Audience Reach** (`roblox-compliance`).

## 9. Git y equipo

- [ ] Abrir el PR de `leonelblumberg/quirky-dijkstra-2kxnwz` a `main` (lo puede abrir Claude: *"abrí el PR de la rama a main"*). Conviene que la prueba del paso 3 esté hecha.
- [ ] Luciano lo revisa y aprueba; merge a `main`. Después, cada uno: `git switch main` y `git pull`, y las tareas nuevas en ramas `<persona>/<tarea>` (`team/README.md`).
- [ ] Luciano: proteger `main` en GitHub (Settings → Rules).

## Decisiones que te esperan — Leonel

- [ ] Visto bueno al concepto de `games/prueba` (*Steal & Fuse Critters*, `games/prueba/docs/concepto.md`), o elegir otra receta para el primer juego real.
- [ ] Las tomas de sonido (paso 6).
- [ ] Si Claude en la nube tiene también claves de Roblox. Recomendación: no; solo OpenAI y Meshy.
- [ ] Cuándo abrir el PR (paso 9).

## Lo de Luciano

Además de los pasos 2, 3 y 9 (ver `team/tareas.md`):
- [ ] La prueba de la UI en Studio: cada ventana con `audit_ui.luau` en PC y en el emulador.
- [ ] Importar la moneda `assets/3d/props/coin-gold-lowpoly-01.fbx` (Scale Unit: Studs), confirmar que mide 2 studs, subirla y anotar su id en `assets/index.json`.
- [ ] Conectar ElevenLabs y Higgsfield en https://claude.ai/customize/connectors, si los quiere usar desde su cuenta.

## Costos

| Qué | Cuánto | Cuándo |
|---|---|---|
| Meshy Pro | 20 USD/mes (1.000 créditos); los 8 critters, unos 120 | Paso 1 |
| OpenAI (íconos, miniaturas) | Saldo prepago: quedaban unos USD 2,4 el 2026-11-03; una hoja de 9 íconos en calidad media cuesta unos USD 0,03 | Cuando haga falta |
| Grupo de Roblox | 100 Robux | Paso 4 |
| Insignias | 5 gratis cada 24 h; después, 100 Robux cada una | Paso 5 |
| ElevenLabs | El plan pago más barato | Antes de publicar sonidos |
| Menores de 16 | Plus o Premium 2 meses, o 1.000 Robux reembolsables por juego | Paso 8 |
| Campañas | El presupuesto que apruebes | Paso 8 |

## Lo que le podés pedir a Claude

En la nube (sin Studio), cuando quieras:
- *"Leé team/traspaso.md y hacé los modelos 3D de los critters"* (con la clave de Meshy cargada).
- *"Seguí el pipeline de games/prueba desde la fase 3"*: UI, monetización, seguridad, QA, cumplimiento y lanzamiento, cada una con su documento y tu visto bueno.
- *"Hacé el ícono y las miniaturas de games/prueba"*.
- *"Armame la lista de pases y productos de games/prueba para cargar en el Dashboard"*.
- Lo que quedó para después en `games/prueba/docs/decisiones.md`: el escudo de 15 minutos, la cinta VIP, el fusionador por base, el renacer que pide unidades y el álbum de variantes.

En tu PC, con Studio abierto: la prueba del paso 3, la subida del paso 6 y la importación de los modelos.
