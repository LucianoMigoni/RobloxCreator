# Hoja de ruta: terminar RobloxCreator

Pasos que faltan para cerrar la carpeta y el entorno de trabajo en equipo. Cada paso tiene entregables y un criterio de "hecho". Regla del hub: **al terminar cada paso, mostrar el resultado y esperar revisión antes del siguiente.**

Marcar `[x]` al completar. La IA que trabaje en un paso lo marca en el mismo commit.

---

## Estado actual (hecho)

- [x] Estructura de carpetas (`skills/`, `template/`, `assets/`, `games/`).
- [x] `CLAUDE.md` orquestador: pipeline de 10 fases, convenciones, cómo empezar un juego, catálogo.
- [x] Catálogo de assets: `assets/index.json` (formato), `assets/LICENSES.md`, `assets/catalog.py` (search / validate / selftest).
- [x] Referencia de MCPs con nombres reales: `skills/_shared/mcp-tools.md` + `studio-mcp-tools.json` (28 tools del MCP de Studio, lista real del servidor).
- [x] Skill `roblox-ui-designer` (SKILL.md, references, `UIKit.luau`, `audit_ui.luau`). `UIKit.selfTest()` y la auditoría probados en Studio. El 2026-10-24 cambió el layout de `UIKit.sideBar` (zonas táctiles reservadas): verificado con `luau-lsp`, falta re-probarlo en Studio.
- [x] Entorno local de Luciano: Rokit 1.2.0, Rojo 7.7.1 (global + `template/rokit.toml`), plugin de Rojo, MCP de Studio registrado como `Roblox_Studio`.
- [x] `template/default.project.json` (Rojo compila: `.server.luau`/`.client.luau`/`.luau` verificados).
- [x] Repo privado en GitHub con todo el hub.

---

## Fase A — Entorno compartido (hacer primero: el compañero se suma acá)

### A1. Invitar al compañero al repo
- GitHub → repo → Settings → Collaborators → Add people (permiso *Write*).
  O por CLI: `gh api -X PUT repos/LucianoMigoni/RobloxCreator/collaborators/<usuario> -f permission=push`
- **Hecho cuando:** el compañero clona el repo.

### A2. Pasar a monorepo (un solo repo para todo)
Hoy `CLAUDE.md` dice "un repo por juego" y "git init dentro del juego": con dos personas eso crea repos anidados. Cambiar a:
- Todo vive en este repo; `games/<juego>/` es una carpeta, no un repo.
- Ramas: `<persona>/<tarea>` (ej. `luciano/tienda`, `leonel/ui-inventario`). Nunca trabajar directo en `main`.
- Integración por Pull Request revisado por el otro (es la "puerta de revisión" del pipeline).
- Opcional: proteger `main` (Settings → Branches/Rulesets). En repos privados puede requerir plan pago de GitHub; si no, la regla es de palabra.
- **Editar:** sección "Empezar un juego nuevo" y "Git" de `CLAUDE.md`.
- **Hecho cuando:** `CLAUDE.md` describe el flujo de ramas y PR, sin `git init` por juego.

### A3. Reemplazar el enlace `.claude/skills`
El enlace (junction de Windows) que hace que Claude Code descubra los skills **no viaja por Git** (está en `.gitignore`).
- Elegido: script `setup.ps1` que lo crea en cada máquina como junction (`New-Item -ItemType Junction`, equivalente a `mklink /J`). Mantiene la estructura `skills/` pedida.
- Descartado por ahora: mover los skills a `.claude/skills/` real y dejar `skills/` como acceso. Cambia la estructura; solo si molesta el script.
- **Hecho cuando:** en una máquina recién clonada, tras `setup.ps1`, Claude Code lista los skills.

### A4. `SETUP.md` + `setup.ps1` (instalación para cada integrante)
Documentar y automatizar lo que se hizo a mano en la máquina de Luciano:
1. Requisitos: Git, GitHub CLI (`gh auth login`), Python 3, Roblox Studio, Claude Code, Obsidian, Blender (opcional).
2. Rokit: instalador oficial en PowerShell (`install.ps1` del repo `rojo-rbx/rokit`) o descargar `rokit-<versión>-windows-x86_64.zip` del release → `rokit.exe self-install`. Reabrir la terminal.
3. Rojo: `rokit trust rojo-rbx/rojo` y `rokit install` dentro de `template/` (y de cada juego).
4. Plugin de Rojo: `rojo plugin install` y reiniciar Studio.
5. MCP de Studio: `claude mcp add Roblox_Studio --scope user -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`. En Studio: Assistant → … → Manage MCP Servers → **Enable Studio as MCP server**. No usar además el botón Quick connect de Claude Code (duplica el registro). Reiniciar Claude Code.
6. Blender MCP: activar el add-on MCP en Blender y registrarlo en Claude Code (documentar el comando exacto del add-on instalado).
7. REA (opcional, para ingeniería inversa): `npx -y rea-agents@<versión> setup` y aprobar los cambios (el README actual del paquete documenta `setup`, no `doctor`).
8. Enlace de skills (A3).
9. Verificación: `python assets/catalog.py selftest`, `rojo --version`, `claude mcp get Roblox_Studio` → Connected, y `list_roblox_studios` devuelve el Studio abierto.
- **Hecho cuando:** el compañero instala todo solo con `SETUP.md` y la verificación pasa.

### A5. Vault de Obsidian
- Abrir la carpeta `RobloxCreator` como vault (Obsidian → Open folder as vault).
- En Settings → Files and links → **Excluded files**: `template/src`, `games/<juego>/src` (expresión regular), `assets/3d`, `.claude` (código y binarios fuera de la búsqueda).
- Compartir solo la config común: `.obsidian/app.json`, `community-plugins.json` y la config de plugins (`.gitignore` en modo lista blanca). Lo personal (workspace, tema, caché, código de plugins) no se sube.
- Plugin **Obsidian Git**: pull automático al abrir, commit y push manuales (en automático podría subir a `main`), mensaje con el nombre del equipo.
- **Hecho cuando:** los dos ven las mismas notas y un cambio hecho en Obsidian por uno le llega al otro con un pull.

### A6. Carpeta `team/` (coordinación entre personas e IAs)
- `team/README.md`: el flujo diario (pull → tomar tarea → rama → IA trabaja → nota actualizada → PR → revisión → merge).
- `team/tareas.md`: tablero con formato fijo que las IAs puedan leer y editar:
  ```
  ## En curso
  - [ ] Sistema de mascotas — servidor · @luciano · rama luciano/mascotas · juego: pet-tycoon
  ## Pendiente
  ## Hecho
  ```
- `team/decisiones.md`: fecha, decisión, por qué, quién.
- Agregar a `CLAUDE.md`: "Antes de empezar, leer `team/tareas.md`; al terminar, mover la tarea y anotar decisiones."
- **Hecho cuando:** una IA puede recibir "haz la tarea X de team/tareas.md" y completarla dejando el tablero actualizado.

### A7. Instrucciones para otras IAs y por persona
- `AGENTS.md` (Codex, Antigravity y otras) y, si hace falta, `GEMINI.md`: una línea que remita a `CLAUDE.md` como fuente única.
- `CLAUDE.local.md` (ya en `.gitignore`): preferencias personales de cada uno.
- **Hecho cuando:** la IA del compañero, sea cual sea, sigue las mismas reglas.

---

## Fase B — Skills y plantilla (orden de construcción original)

Para cada skill: `SKILL.md` (frontmatter `name`/`description`, objetivo, cuándo usarlo, flujo, checklist, límites, qué skills llama), `references/` y `scripts/` si hacen falta. **Verificar toda API en create.roblox.com/docs** (o en el repo `Roblox/creator-docs` si el sitio no es accesible) y usar solo tools reales de `skills/_shared/mcp-tools.md`. Cada skill aplica las reglas de `skills/_shared/algoritmo-descubrimiento.md` que le tocan.

Quién prueba qué: el código se puede escribir y verificar estáticamente desde cualquier lado (B0); lo que necesita Studio (autotests con `execute_luau`, auditorías, capturas, playtest) lo corre quien tenga Studio + MCP, y queda anotado en el PR.

### B0. Verificación automática en cada PR (nuevo, antes de B1)
Lo que se usó para revisar el hub el 2026-10-24, convertido en un chequeo que corre solo:
- GitHub Action en cada PR: `rojo build` de `template/` y de cada `games/<juego>/`, `luau-lsp analyze` con las definiciones de tipos de Roblox sobre `template/src`, `games/*/src` y `skills/*/scripts`, y `python assets/catalog.py selftest` + `validate`.
- El mismo chequeo para correr a mano antes del PR: `python tools/check.py` (Python, que ya es requisito: corre igual en Windows y en Linux).
- Fijar versiones: Rojo y `luau-lsp` en `rokit.toml` de la raíz (fuente única para la PC de cada uno y para GitHub); las definiciones de tipos, del tag de esa versión de `luau-lsp`.
- **Hecho cuando:** un PR con un error de tipos o una propiedad inexistente falla el chequeo, y uno correcto pasa.

### B1. Plantilla de código base + `roblox-security` (paso 3)
Plantilla (`template/src/`), todo lo sensible en el servidor:
- `server/`: `DataService` (bloqueo de sesión escrito en la metadata de la clave dentro del mismo `UpdateAsync`, cola y reintentos con backoff, liberar el bloqueo en el guardado final de `PlayerRemoving` y de `BindToClose`; seguir la guía oficial "Implement player data and purchasing systems", `/cloud-services/data-stores/player-data-purchasing`), `CurrencyService`, `ShopService` (compras con monedas del juego + `MarketplaceService.ProcessReceipt` idempotente para Developer Products, verificación de Game Passes), `InventoryService`, `OnboardingService` (primer minuto jugable; registra cada paso con `AnalyticsService:LogOnboardingFunnelStepEvent` para medir dónde rebotan), `Remotes` (crea `ReplicatedStorage.Remotes`, validación de argumentos y rate limiting).
- `shared/`: `Config/` (precios, economía, productos), `UIKit.luau` (mover desde el skill de UI), tipos comunes.
- `client/`: controladores de HUD, tienda e inventario usando `UIKit`; input.
- Autotests ejecutables vía `execute_luau` (como `UIKit.selfTest`).
- APIs (existencia verificada el 2026-10-24 en la referencia oficial, ninguna deprecada; revisar firmas y límites al implementar): `DataStoreService:GetDataStore`, `GlobalDataStore:UpdateAsync`, `DataStoreService:GetRequestBudgetForRequestType` y los límites de DataStores, `MarketplaceService.ProcessReceipt`, `MarketplaceService:UserOwnsGamePassAsync`, `MarketplaceService:PromptGamePassPurchase`, `MarketplaceService:PromptProductPurchase`, `Players.PlayerRemoving`, `DataModel:BindToClose`, `AnalyticsService:LogOnboardingFunnelStepEvent`. `MemoryStoreService` solo si hace falta algo que la guía oficial no cubre.

`roblox-security`: reglas (nunca confiar en el cliente), módulo de validación de argumentos, rate limiter por jugador y remote, checklist de auditoría, script de auditoría que liste remotes y sus validaciones.
- **Hecho cuando:** un juego copiado de `template/` pasa el chequeo de B0 y corre en Studio con datos persistentes, monedas, tienda e inventario; los autotests pasan; la auditoría de seguridad no marca errores.

### B2. `roblox-game-cloner` + `roblox-ideation` (paso 4)
- Cloner (tomar mecánicas, nunca título, thumbnails, mapa ni place file: un clon reconocible es "no único" y Roblox le baja la exposición): análisis → RE opcional con REA (tools reales de `mcp-tools.md`) → `docs/spec.md` (plantilla en `references/`) → adaptación a Roblox → assets (Blender MCP: escala, pivote, export FBX para Studio; o catálogo) → construcción con MCP de Studio → llamada a `roblox-ui-designer` → verificación mecánica por mecánica contra la spec.
- Ideation: géneros en crecimiento, huecos, gancho, matriz de puntuación, recomendación en `docs/concepto.md`. Indicar fuentes de datos verificables (charts de Roblox, Creator Hub) y no inventar cifras. La matriz puntúa también lo que mide el algoritmo (`skills/_shared/algoritmo-descubrimiento.md`): primer minuto jugable, motivo para volver en D2–7 y D8–28, juego con amigos.
- **Hecho cuando:** ambos skills producen sus documentos para un juego de prueba y la spec es construible.

### B3. `roblox-monetization` + `roblox-metrics-growth` (paso 5)
- Monetization: tácticas honestas (pack de inicio único, ofertas en el momento justo, anclaje con ahorro real, cosméticos visibles, pase de temporada con pista gratis, pases que ahorran tiempo), auditoría de tienda que marque escasez falsa, cuentas regresivas que se reinician y cajas pagas sin probabilidades. Política oficial de ítems aleatorios pagos (`/production/monetization/paid-random-items`): si se compran con Robux o con moneda comprada con Robux, mostrar todos los resultados posibles y sus probabilidades numéricas; un Game Pass no puede dar ítems aleatorios pagos; con `PolicyService:GetPolicyInfoForPlayerAsync`, si `ArePaidRandomItemsRestricted` es true, ese jugador no puede usarlos.
- Metrics-growth: modo mejora con las señales del algoritmo (PTR, bounce < 60 s y 61–180 s, play days y playtime en D1/D2–7/D8–28, co-play, spend days; ver `skills/_shared/algoritmo-descubrimiento.md`) más retención D1/D7/D30 y conversión, y modo análisis. Hay API oficial: **Open Cloud Analytics** (`/cloud/guides/analytics`), con API key de permiso `universe.analytics:read` (retención D1/D7/D30, playtime, sesiones, DAU/MAU, ingresos, benchmarks); las señales de Home Recommendations (PTR, bounce) no figuran en su lista de métricas, así que se leen del Creator Dashboard (export o captura). La API key nunca va al repo. Instrumentación con `AnalyticsService` (`LogOnboardingFunnelStepEvent`, `LogFunnelStepEvent`, `LogEconomyEvent`, `LogCustomEvent`) en la plantilla.
- **Hecho cuando:** la tienda de la plantilla pasa la auditoría ética y la plantilla registra embudo de onboarding y eventos de economía.

### B4. `roblox-qa-performance`, `roblox-compliance`, `roblox-publishing`, `roblox-liveops` (paso 6)
- QA: pruebas en móvil de gama baja (memoria, partes, `Workspace.StreamingEnabled`, scripts costosos), checklist antes de cada update, uso de `start_stop_play`, `get_console_output` e input simulado. Medir el tiempo hasta poder jugar: el algoritmo castiga el rebote antes de 60 s.
- Compliance: **Maturity & Compliance Questionnaire** antes de publicar (sin él, Roblox restringe el juego para todos los jugadores; completo, si se apunta a Roblox Kids and Select), filtrado con `TextService:FilterStringAsync` de todo texto de jugadores que vean otros, `PolicyService` para restricciones por región, revisión contra las Community Standards.
- Publishing: icono, miniaturas, título, descripción, plan de lanzamiento (ads de Roblox, TikTok, Discord); thumbnail propio (sin él no hay impresiones de Home) y metadata sin promesas de Robux; coordina PTR con metrics-growth.
- Liveops: cadencia de updates, eventos temporales, changelogs, planificación de contenido.
- **Hecho cuando:** los cuatro skills existen y están enlazados desde el pipeline de `CLAUDE.md`.

---

## Fase C — Cierre

- [ ] C1. Primer asset real en el catálogo (modelo low-poly hecho con Blender MCP, exportado, registrado en `index.json` + `LICENSES.md`, `catalog.py validate` OK).
- [ ] C2. Juego de prueba de punta a punta en `games/prueba/` recorriendo las 10 fases con los dos integrantes (uno en servidor, otro en cliente/mapa), integrando por PR.
- [ ] C3. Repasar `CLAUDE.md` con lo aprendido en C2 y cerrar esta hoja de ruta.

## Progreso

| Paso | Estado | Responsable |
|---|---|---|
| A1 | Hecho: el compañero tiene acceso de escritura (ya sube ramas al repo) | luciano |
| A2 | Hecho: `CLAUDE.md` con monorepo, ramas y PR. Opcional pendiente: proteger `main` en GitHub | leonel (IA) |
| A3 | Implementado: `setup.ps1` crea `.claude\skills` (junction). Probado con PowerShell 7 en Linux (Rokit y Rojo simulados). Falta el criterio: correrlo en un Windows recién clonado | leonel (IA) |
| A4 | Implementado: `SETUP.md` (pasos 1–9, comandos verificados). Falta: Luciano documenta el MCP de Blender (paso 6) y el compañero instala todo solo con la guía | leonel (IA) |
| A5 | Implementado: config común de Obsidian y pasos en `SETUP.md`. Falta la prueba entre los dos | leonel (IA) |
| A6 | Implementado: `team/` (flujo, tablero, decisiones) y regla en `CLAUDE.md`. Se valida con la primera tarea que una IA tome del tablero | leonel (IA) |
| A7 | Implementado: `AGENTS.md` y `GEMINI.md` remiten a `CLAUDE.md`; `CLAUDE.local.md` explicado en `SETUP.md`. Falta probarlo con la IA del compañero | leonel (IA) |
| B0 | Implementado: `tools/check.py`, `.github/workflows/check.yml` y `rokit.toml` en la raíz. Verificado localmente: falla con 6 errores inyectados (incluido un `require` mal usado) y pasa en el repo. Falta ver el primer run en GitHub | leonel (IA) |
| B1 | Pendiente | |
| B2 | Pendiente | |
| B3 | Pendiente | |
| B4 | Pendiente | |
| C1–C3 | Pendiente | |
