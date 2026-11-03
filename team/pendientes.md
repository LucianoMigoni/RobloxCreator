# Lo que hay que hacer después: claves, conectores, cuentas y pruebas

Lo que el programa necesita de las personas y que Claude no puede hacer solo. Al resolver un punto, marcarlo `[x]` en el PR de la tarea. Pasos detallados de instalación: `SETUP.md` (los números de paso de abajo son los suyos).

**Regla de las claves:** nunca en el repo ni pegadas en el chat. Van en variables de entorno de cada PC (en CMD: `setx NOMBRE valor`, y después cerrar y abrir la terminal y Claude Code) o, para que Claude las use en las sesiones en la nube, en la configuración del entorno: menú del entorno en la barra de título de la sesión → **Edit** → **Network secrets** (en apps viejas, *API credentials*) o, si esa sección no está, como variable de entorno con el mismo nombre. La sesión siguiente las toma. Las claves de Roblox nunca se cargan en servicios de terceros (ForgeGUI, webs de IA).

**Estado en la nube (revisado el 2026-10-30, solo por nombre de variable, nunca por valor):** el entorno no tiene ninguna de estas claves. Conectados en la cuenta de Leonel: ElevenLabs, Higgsfield y GitHub. El MCP de Meshy no arranca en la nube porque `.mcp.json` lo lanza con `cmd` (solo existe en Windows): en la nube, los modelos 3D con IA salen de Higgsfield (`generate_3d`).

## Lo mínimo para arrancar

- [ ] `OPENAI_API_KEY` en las dos PCs y en el entorno de la nube (íconos y miniaturas). Saldo cargado (USD 5, 2026-11-02). Clave creada y cargada en el entorno de la nube (la toman las sesiones nuevas) y probada el 2026-11-02: lista los modelos de imagen y una hoja de 9 íconos en calidad media costó USD 0,03. Falta en las PCs (`team/claves-ia.md`). Gemini queda para después: la facturación de Google dio OR_BACR2_59.
- [ ] MCP de Roblox Studio y plugin de Rojo en las dos PCs (`SETUP.md` §4 y §5).
- [ ] Grupo de Roblox dueño de los juegos, con los dos como miembros con permiso de crear.
- [ ] Prueba en Studio de la UI y de los bloques del armador (tarea de Luciano en `team/tareas.md`).
- [ ] Productos y pases creados en el Creator Dashboard para el primer juego, con sus ids en `ShopConfig`.
- [ ] Imágenes de esos pases y productos: las de `assets/ui/store-art` (qué va con cuál: `uses` de su `manifest.json`).
- [ ] Insignias creadas en el Dashboard (Monetization → Badges; 5 gratis cada 24 h, después 100 Robux cada una) con nombre, descripción e imagen de `assets/ui/badge-art`, y sus ids en `BadgeConfig`.
- [ ] Subir a Roblox los íconos (`hud-icons`, `pet-icons`, `unit-icons`), las fotos de zona y el fondo de carga (`tools/roblox_upload.py`, con `ROBLOX_OPEN_CLOUD_API_KEY`) y poner los ids en `AssetIds` y `LoadingConfig.IMAGE`; mientras tanto el juego muestra emojis de respaldo.

## 1. Claves de API

Paso a paso corto para las de OpenAI y Google: `team/claves-ia.md`.

| Clave (variable) | Para qué | Dónde se crea | Permisos y costo | Quién |
|---|---|---|---|---|
| `OPENAI_API_KEY` | Íconos, miniaturas y anuncios con GPT Image (`tools/imagegen.py`) | https://platform.openai.com/api-keys → *Create new secret key* | Saldo cargado en *Billing* (la suscripción de ChatGPT no sirve). Puede pedir verificar la organización para los modelos de imagen | Los dos y la nube |
| `GEMINI_API_KEY` | Nano Banana Pro (Google), para comparar miniaturas | https://aistudio.google.com/apikey → *Create API key* | Proyecto con facturación activa; se paga por uso. Recomendada, no obligatoria | Los dos y la nube |
| `MESHY_API_KEY` | Modelos y criaturas 3D con IA (MCP de Meshy en las PCs; `tools/meshy.py` en la nube) | https://www.meshy.ai/developers/keys (empieza con `msy_`) | Plan Pro, 20 USD/mes, y créditos de API prepagos (la API no anda en el plan gratis). Los 8 critters: unos 120 créditos con Smart Topology | Los dos (en Windows) y la nube, como secreto del entorno (`skills/_shared/conectores.md`, Meshy) |
| `ROBLOX_OPEN_CLOUD_API_KEY` y `ROBLOX_CREATOR_GROUP_ID` (o `ROBLOX_CREATOR_USER_ID`) | Subir íconos, texturas, sonidos y modelos (`tools/roblox_upload.py`) | Creator Dashboard → Open Cloud → API Keys | *assets* Read y Write, tu IP en *Accepted IP Addresses* y vencimiento. Gratis | Los dos |
| `ROBLOX_ANALYTICS_API_KEY` | Métricas (`tools/analytics.py`) y rendimiento de miniaturas (`tools/campaigns.py thumbs`) | Creator Dashboard → Open Cloud → API Keys | `universe.analytics:read`. Gratis | Quien mire métricas |
| `ROBLOX_ADS_API_KEY` | Campañas de Ads Manager (`tools/campaigns.py`): **gasta dinero real** con `--yes` | Creator Dashboard → Open Cloud → API Keys, **de tu usuario** (la API no acepta claves de grupo) | `ad.campaign:read`, `ad.campaign:write` y `ad.billing:read`; medio de pago en Ads Manager | Quien maneje campañas |

Las claves de Roblox conviene dejarlas solo en las PCs: con IP restringida no funcionan desde la nube, y abrirlas a cualquier IP las expone más.

## 2. Conectores y programas

| Conector | Para qué | Qué hacer | Leonel | Luciano |
|---|---|---|---|---|
| MCP de Roblox Studio (`Roblox_Studio`) | Que Claude construya y pruebe dentro de Studio | En Studio, *Enable Studio as MCP server*; registrarlo una vez (`SETUP.md` §5) | [ ] | [ ] |
| Rojo + plugin | Pasar el código del repo a Studio | `setup.ps1` (§3 y §4) | [ ] | [ ] |
| MCP de Blender (Blender Lab 1.0.3) | Modelos, renders para íconos y miniaturas | Add-on en Blender 5.1+ y servidor en Claude (§6) | [ ] | [ ] |
| MCP de Meshy | Modelos 3D con IA | Ya está en `.mcp.json`; falta la clave y aprobarlo en Claude Code (§7) | [ ] | [ ] |
| ElevenLabs (conector de claude.ai) | Efectos de sonido y voces | Conectarlo en https://claude.ai/customize/connectors y abrir una sesión nueva. Plan pago antes de publicar sonidos | conectado | [ ] |
| Higgsfield (conector de claude.ai) | Imágenes, 3D y video con IA | Igual que ElevenLabs; usa créditos de su cuenta | conectado | [ ] |
| GitHub | PRs y revisiones | `gh auth login` en cada PC; la app de Claude ya tiene acceso al repo | conectado | [ ] |
| Obsidian + plugin Git | Leer y editar las notas del repo | Abrir el repo como vault e instalar *Git* (sección Obsidian de `SETUP.md`) | [ ] | [ ] |
| REA (opcional) | Analizar juegos de referencia | `npx -y rea-agents@6.7.0 setup` (§10) | [ ] | [ ] |
| Meshy en la nube | Que Claude en la web haga los modelos 3D | `MESHY_API_KEY` como secreto del entorno (menú del entorno → Edit → Network secrets) y créditos de API; usa `tools/meshy.py` | [ ] | — |
| Blender en la nube | Que Claude en la web limpie y exporte modelos sin pantalla | El script de la sección Blender de `skills/_shared/conectores.md` en el *setup script* del entorno | [ ] | — |

Lo que se registra con `claude mcp add` en una PC no viaja a la nube: en la nube solo andan los conectores de claude.ai y lo que está en `.mcp.json`. El MCP de Meshy de `.mcp.json` está armado para Windows (`cmd /c`): en la nube se usa `tools/meshy.py`. ForgeGUI se evaluó y no se usa (`skills/_shared/conectores.md`).

## 3. Roblox: cuenta dueña y Creator Dashboard

**Una vez:**
- [ ] Decidir la cuenta dueña de los juegos: un grupo (recomendado). Poner su id en `GameConfig.GROUP_ID` de cada juego (da el premio y el bono por unirse) y darles a los dos un rol que pueda crear experiencias y assets.
- [ ] 2FA y verificación con documento en la cuenta que publica: la piden los anuncios con premio y llegar a menores de 16, y sube el cupo de audio de 10 a 100 subidas por mes.
- [ ] Elegir las tomas de sonido (`assets/audio/hit-sfx` y `hit-voices`) y subirlas. Las voces de anunciador ("LEGENDARY!", "SO LUCKY!", "NEW RECORD!", "DOUBLE MONEY!") ya están conectadas a sus momentos: suenan en cuanto sus ids estén en `AssetIds.voices`.

**En cada juego:**
- [ ] *Max Players* del lugar = `plots.count` de la receta, si usa bases (una base por jugador).
- [ ] Crear los Developer Products y Game Passes de `ShopConfig` (y los de los bloques activos) y pegar cada id en `productId` o `passId`. Con id 0 no se ofrecen. El precio real se pone en el Dashboard; `robux` es la referencia del diseño.
- [ ] Suscripción VIP (Monetization → Subscriptions): cobrarla **en Robux** (desde 49). La de moneda local pide cuenta verificada y no se ofrece en algunos países (Argentina entre ellos). Antes de activarla por primera vez se elige un nombre corto del juego que **no se puede cambiar**. Pegar el id en `ShopConfig.SUBSCRIPTIONS`.
- [ ] Anuncio con premio: Roblox lo permite recién con el juego público, el cuestionario de madurez aprobado, un promedio de 2 000 visitantes únicos por mes y quien publica con 13+, 2FA y documento verificado. El premio es un Developer Product propio y nunca aleatorio. Hasta entonces, `ShopConfig.AD_REWARD.productId = 0`.
- [ ] Cuestionario de madurez (Maturity & Compliance) completo. El juego sale primero solo para 16+; para menores de 16, los requisitos de la cuenta dueña y la evaluación de `roblox-compliance`.
- [ ] Traducción automática activada al publicar (18 idiomas; `roblox-publishing`).
- [ ] Para probar el guardado de datos: *Enable Studio Access to API Services* solo en una **copia de prueba** del lugar, nunca en el juego en vivo (`roblox-security`).

## 4. Pruebas en Studio

- [ ] UI v3: ventanas, HUD táctil (emulador de teléfono de Studio) y carteles del mundo (tarea de Luciano en `team/tareas.md`).
- [ ] Cada bloque del armador, a medida que se terminan los hitos (`team/traspaso.md` §4).
- [ ] El mapa que arma MapKit con una receta: que se vea como la vista previa (`skills/roblox-game-kits/references/mapa/`), que cada bloque encuentre lo suyo y que los puestos, la ruleta y el cofre abran lo que corresponde. Las tablas de posiciones del mundo se llenan con datos de todos los servidores solo con el lugar publicado (en una copia de prueba con *Enable Studio Access to API Services*); sin eso muestran a los jugadores del servidor.
- [ ] El juego de prueba rehecho con el armador (`games/prueba`): seguir el loop de su README (comprar, juntar, fusionar, robar con dos jugadores, trabar, renacer) y anotar lo que falte en `games/prueba/docs/decisiones.md`.
- [ ] Guardado con dos ventanas de Studio a la vez (la segunda queda en "errored" mientras la primera tiene el bloqueo).
- [ ] Lo que sumó la revisión del 2026-11-03, en `games/prueba`:
  - el botón "LOCK" de la barra de acción: aparece estando en la base y cuenta la traba ("LOCKED 0:45") y la espera ("LOCK IN 1:30");
  - "Merge Odds" en el inventario: Normal 94 %, Gold 5 %, Rainbow 1 % y la línea de Lucky Fuse;
  - los pases Long Lock (traba de 120 s) y Fast Thief (más rápido llevando lo robado), con ids de prueba;
  - con un jugador restringido (forzar el atributo `PaidRandomRestricted` en la barra de comandos): los huevos pagados con plata no se venden, y la fusión y la cosecha salen siempre Normal.

## 5. Decisiones que esperan al usuario

- [ ] Qué receta usar para el primer juego real.
- [ ] Abrir el PR de la rama a `main` y hacer el merge (cuando lo pida).
- [ ] Si Claude en la nube debe tener también claves de Roblox (recomendación: no; solo OpenAI y Gemini).

Requisitos de suscripciones y anuncios con premio verificados el 2026-10-30 en `Roblox/creator-docs` (`production/monetization/subscriptions.md` y `production/promotion/rewarded-video-ads.md`).
