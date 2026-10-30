# Lo que hay que hacer después: claves, conectores, cuentas y pruebas

Lo que el programa necesita de las personas y que Claude no puede hacer solo. Al resolver un punto, marcarlo `[x]` en el PR de la tarea. Pasos detallados de instalación: `SETUP.md` (los números de paso de abajo son los suyos).

**Regla de las claves:** nunca en el repo ni pegadas en el chat. Van en variables de entorno de cada PC (en CMD: `setx NOMBRE valor`, y después cerrar y abrir la terminal y Claude Code) o, para que Claude las use en las sesiones en la nube, en la configuración del entorno: menú del entorno en la barra de título de la sesión → **Edit** → **Network secrets** (en apps viejas, *API credentials*) o, si esa sección no está, como variable de entorno con el mismo nombre. La sesión siguiente las toma. Las claves de Roblox nunca se cargan en servicios de terceros (ForgeGUI, webs de IA).

**Estado en la nube (revisado el 2026-10-30, solo por nombre de variable, nunca por valor):** el entorno no tiene ninguna de estas claves. Conectados en la cuenta de Leonel: ElevenLabs, Higgsfield y GitHub. El MCP de Meshy no arranca en la nube porque `.mcp.json` lo lanza con `cmd` (solo existe en Windows): en la nube, los modelos 3D con IA salen de Higgsfield (`generate_3d`).

## Lo mínimo para arrancar

- [ ] `OPENAI_API_KEY` en las dos PCs y en el entorno de la nube (íconos y miniaturas).
- [ ] MCP de Roblox Studio y plugin de Rojo en las dos PCs (`SETUP.md` §4 y §5).
- [ ] Grupo de Roblox dueño de los juegos, con los dos como miembros con permiso de crear.
- [ ] Prueba en Studio de la UI y de los bloques del armador (tarea de Luciano en `team/tareas.md`).
- [ ] Productos y pases creados en el Creator Dashboard para el primer juego, con sus ids en `ShopConfig`.

## 1. Claves de API

| Clave (variable) | Para qué | Dónde se crea | Permisos y costo | Quién |
|---|---|---|---|---|
| `OPENAI_API_KEY` | Íconos, miniaturas y anuncios con GPT Image (`tools/imagegen.py`) | https://platform.openai.com/api-keys → *Create new secret key* | Saldo cargado en *Billing* (la suscripción de ChatGPT no sirve). Puede pedir verificar la organización para los modelos de imagen | Los dos y la nube |
| `GEMINI_API_KEY` | Nano Banana Pro (Google), para comparar miniaturas | https://aistudio.google.com/apikey → *Create API key* | Proyecto con facturación activa; se paga por uso. Recomendada, no obligatoria | Los dos y la nube |
| `MESHY_API_KEY` | Modelos y criaturas 3D con IA (MCP de Meshy) | https://www.meshy.ai/developers/keys (empieza con `msy_`) | Plan Pro, 20 USD/mes (la API no anda en el plan gratis) | Los dos (en Windows) |
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

Lo que se registra con `claude mcp add` en una PC no viaja a la nube: en la nube solo andan los conectores de claude.ai y lo que está en `.mcp.json`. ForgeGUI se evaluó y no se usa (`skills/_shared/conectores.md`).

## 3. Roblox: cuenta dueña y Creator Dashboard

**Una vez:**
- [ ] Decidir la cuenta dueña de los juegos: un grupo (recomendado). Poner su id en `GameConfig.GROUP_ID` de cada juego (da el premio y el bono por unirse) y darles a los dos un rol que pueda crear experiencias y assets.
- [ ] 2FA y verificación con documento en la cuenta que publica: la piden los anuncios con premio y llegar a menores de 16, y sube el cupo de audio de 10 a 100 subidas por mes.
- [ ] Elegir las tomas de sonido (`assets/audio/hit-sfx` y `hit-voices`) y subirlas.

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
- [ ] El juego de prueba rehecho con el armador (`games/prueba`).
- [ ] Guardado con dos ventanas de Studio a la vez (la segunda queda en "errored" mientras la primera tiene el bloqueo).

## 5. Decisiones que esperan al usuario

- [ ] Qué receta usar para el primer juego real.
- [ ] Abrir el PR de la rama a `main` y hacer el merge (cuando lo pida).
- [ ] Si Claude en la nube debe tener también claves de Roblox (recomendación: no; solo OpenAI y Gemini).

Requisitos de suscripciones y anuncios con premio verificados el 2026-10-30 en `Roblox/creator-docs` (`production/monetization/subscriptions.md` y `production/promotion/rewarded-video-ads.md`).
