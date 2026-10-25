# RobloxCreator — Orquestador

Centro para crear juegos de Roblox rápido y con buenas probabilidades de éxito. Este archivo dice qué skill usar en cada fase, cómo empezar un juego y las convenciones. Los detalles viven en cada `skills/<skill>/SKILL.md`.

## Reglas generales

- **No inventes APIs.** Toda API de Roblox que uses o menciones se verifica en https://create.roblox.com/docs (WebFetch de la página `.md`, o `http_get` del MCP de Studio). Si ese sitio no es accesible (p. ej. en sesiones en la nube), la misma documentación está en el repo oficial `Roblox/creator-docs`: guías en `content/en-us/<ruta>.md` y referencia de la API en `content/en-us/reference/engine/classes/<Clase>.yaml` (vía `raw.githubusercontent.com`). Si no se pudo verificar, dilo.
- **Diseñar para el algoritmo.** Home recomienda según lo que hacen los jugadores que llegan desde ahí: si juegan tras ver el juego, si rebotan antes de 60 o 180 s, y cuánto vuelven, juegan, juegan con amigos y gastan en D1, D2–7 y D8–28. Castiga la metadata engañosa y los juegos no únicos. Resumen verificado y qué implica en cada fase: `skills/_shared/algoritmo-descubrimiento.md`.
- **No inventes herramientas MCP.** Detecta qué hay instalado y usa los nombres exactos: `skills/_shared/mcp-tools.md`.
- **Servidor autoritativo.** Monedas, daño, compras, inventario y progreso se calculan y validan en el servidor. El cliente solo pide y muestra.
- **Móvil primero.** La mayoría juega en teléfono: toda UI y todo control se diseña para dedo y pantallas chicas.
- **Público menor de edad.** Monetización honesta (ver `roblox-monetization`), contenido apto (ver `roblox-compliance`).
- **Puerta de revisión:** al terminar cada fase, mostrar el resultado al usuario y esperar su visto bueno antes de seguir.

## Pipeline: qué skill usar y cuándo

| # | Fase | Skill | Entrada | Salida en `games/<juego>/docs/` |
|---|---|---|---|---|
| 1 | Ideación y validación | `roblox-ideation` | Idea, género o nada | `concepto.md` (conceptos puntuados + recomendado) |
| 2 | Clonación / diseño | `roblox-game-cloner` | Juego de referencia o descripción | `spec.md`, juego armado en Studio |
| 3 | UI | `roblox-ui-designer` | `spec.md` (pantallas), assets del usuario | UI en Studio, `ui.md` |
| 4 | Monetización | `roblox-monetization` | `spec.md`, economía | `monetizacion.md`, tienda auditada |
| 5 | Seguridad | `roblox-security` | Código del juego | `seguridad.md` (auditoría) |
| 6 | QA y rendimiento | `roblox-qa-performance` | Build jugable | `qa.md` (checklist + resultados) |
| 7 | Cumplimiento | `roblox-compliance` | Juego completo | `cumplimiento.md` |
| 8 | Publicación | `roblox-publishing` | Juego aprobado | `lanzamiento.md`, icono/miniaturas |
| 9 | Métricas | `roblox-metrics-growth` | Juego publicado (o pre-lanzamiento en modo mejora) | `metricas.md` |
| 10 | Live ops | `roblox-liveops` | Métricas + roadmap | `liveops.md`, changelogs |

**Skills que existen hoy:** `roblox-ideation`, `roblox-game-cloner`, `roblox-ui-designer`, `roblox-monetization`, `roblox-security` y `roblox-metrics-growth`. Los demás están planificados en `ROADMAP.md` (Fase B). Si una fase todavía no tiene skill, avisarlo al usuario y trabajar con las reglas de este archivo y `skills/_shared/` (no inventar el contenido del skill que falta).

Saltos permitidos: un juego existente puede entrar en la fase 9 (modo mejora). `roblox-ui-designer` y `roblox-security` se vuelven a llamar cada vez que otra fase cree UI o RemoteEvents nuevos.

### Cómo invocar un skill

Los skills están en `skills/` (y enlazados en `.claude/skills/` por `setup.ps1` para que Claude Code los descubra solo). Si no se cargan automáticamente: leer `skills/<skill>/SKILL.md` y seguir su flujo. Leer `references/` solo cuando el SKILL.md lo indique.

## Empezar un juego nuevo

El juego es una carpeta dentro de este repo, no un repo aparte (ver **Git y trabajo en equipo**).

1. Rama desde `main` actualizado: `git switch main && git pull && git switch -c <persona>/<nombre-juego>`.
2. Nombre en kebab-case: `games/<nombre-juego>/` (ej. `games/pet-tycoon`).
3. Copiar la plantilla:
   ```bash
   cp -r template games/<nombre-juego>
   mkdir -p games/<nombre-juego>/docs
   ```
4. Cambiar `name` en `default.project.json`.
5. `rokit install` en la carpeta del juego (instala la versión de Rojo fijada en `rokit.toml`; la primera vez pide confiar en `rojo-rbx/rojo`).
6. Conectar: `rojo serve` en la carpeta del juego → en Studio, pestaña Plugins → Rojo → **Connect** (localhost:34872). Activar el MCP de Studio (ver `skills/_shared/mcp-tools.md`).
7. Commit, `git push -u origin <rama>` y Pull Request a `main` para que el otro integrante lo revise.
8. Arrancar el pipeline en la fase 1 (o 2 si el concepto ya está decidido), cada fase en su rama y su PR.

### Herramientas
Instalación en cada máquina: `SETUP.md` (y `setup.ps1`, que crea el enlace de skills y verifica todo). Versiones del equipo:
- **Rokit 1.2.0** en `~/.rokit/bin` (en el PATH de usuario). Gestiona versiones de herramientas por proyecto.
- **Rojo 7.7.1**, **luau-lsp 1.70.1** (análisis de tipos) y **Luau 0.742** (intérprete para los tests de `template/tests/`): fijados en `rokit.toml` de la raíz; Rojo también en `template/rokit.toml` (y en cada juego). Para actualizar, cambiar la versión en todos a la vez: `tools/check.py` exige que coincidan.
- **Plugin de Rojo** en `%LOCALAPPDATA%\Roblox\Plugins\RojoManagedPlugin.rbxm` (reinstalar tras actualizar Rojo: `rojo plugin install`).
- **MCP de Roblox Studio** registrado como `Roblox_Studio` (scope usuario).

Mapeo de Rojo en la plantilla: `src/shared` → `ReplicatedStorage.Shared`, `src/server` → `ServerScriptService.Server`, `src/client` → `StarterPlayer.StarterPlayerScripts.Client`. Sufijos: `.server.luau` = Script, `.client.luau` = LocalScript, `.luau` = ModuleScript.

## Catálogo de assets

**Consultar siempre el índice antes de abrir o generar archivos.**

- Índice: `assets/index.json`. Licencias: `assets/LICENSES.md`.
- Buscar: `python assets/catalog.py search --type model3d --tag lowpoly --tag fantasy --commercial`
- Validar tras agregar assets: `python assets/catalog.py validate`
- Si no hay un asset adecuado: generarlo (Blender MCP o `generate_mesh` del MCP de Studio), guardarlo en `assets/3d` o `assets/ui`, y **registrarlo en el índice y en LICENSES.md en el mismo cambio**.
- Para juegos publicados solo se usan assets con `commercialUse: true`.

## Estructura de un proyecto de juego

```
games/<juego>/
├── default.project.json      # Rojo
├── rokit.toml                # versión de Rojo (igual a la de la raíz)
├── src/
│   ├── server/               # ServerScriptService: Main.server.luau arranca Data, Net, Economy, Shop, Onboarding
│   ├── client/               # StarterPlayerScripts: Main.client.luau + Controllers/ (UI, input, cámara)
│   └── shared/               # ReplicatedStorage: Config/, UIKit, Net, Types
├── tests/                    # lógica pura probada con el CLI de Luau (la corre tools/check.py)
└── docs/                     # spec.md, decisiones.md, métricas, auditorías
```

Qué trae la plantilla y cómo extenderla (un remote nuevo, un campo de datos, una moneda): `template/README.md`.

## Convenciones

**Nombres**
- Carpetas de juego y skills: `kebab-case`.
- Módulos y scripts Luau: `PascalCase` (`DataService.luau`, `ShopController.luau`). Un solo `Main.server.luau` y un solo `Main.client.luau` arrancan los módulos.
- Servicios del servidor terminan en `Service`; controladores del cliente en `Controller`.
- Variables y funciones: `camelCase`. Constantes: `UPPER_SNAKE_CASE`.
- RemoteEvents/Functions: verbo + objeto (`RequestPurchase`, `EquipItem`), creados por el servidor dentro de `ReplicatedStorage.Remotes`.
- Instancias de UI: `PascalCase` con sufijo de tipo cuando ayude (`ShopButton`, `CoinsLabel`, `ShopPopup`).

**Estilo Luau**
- `--!strict` en todo módulo nuevo; tipar parámetros públicos.
- `game:GetService("X")` arriba del archivo; nunca `game.X`.
- `task.wait/spawn/delay`, nunca `wait/spawn/delay` heredados.
- Configuración (precios, tiempos, tablas de drops) en `src/shared/Config/`, nunca números mágicos en la lógica.
- Un módulo, una responsabilidad. Sin frameworks externos salvo que el usuario lo pida.
- `pcall` alrededor de toda llamada que pueda fallar por red: DataStores, MarketplaceService, HttpService, TextService.
- Comentarios solo para el *por qué*.

**Git y trabajo en equipo** (monorepo)
- **Antes de empezar, leer `team/tareas.md`; al terminar, mover la tarea y anotar las decisiones** (`team/decisiones.md`, o `games/<juego>/docs/decisiones.md` si son de un juego). Flujo completo: `team/README.md`.
- Todo vive en este repo: hub, plantilla y juegos. Nunca `git init` dentro de `games/<juego>/`: un repo anidado no viaja con el resto.
- Nunca trabajar directo en `main`. Una rama por tarea, `<persona>/<tarea>` (ej. `luciano/tienda`, `leonel/ui-inventario`), creada desde `main` actualizado.
- Se integra por Pull Request y lo aprueba el otro integrante antes del merge. El PR es la puerta de revisión: su descripción lleva el resultado de la fase (qué se hizo, cómo se probó, capturas si hay UI).
- Ramas cortas: un PR por tarea. Si `main` avanzó, `git merge main` en la rama antes de pedir revisión.
- Antes de pedir revisión, `python tools/check.py` sin errores (rojo build, tipos de Luau con luau-lsp, tests de Luau, reglas de seguridad, catálogo, JSON, PowerShell). GitHub Actions lo corre en cada push: un PR con el chequeo en rojo no se aprueba.
- Commits pequeños y descriptivos. Nunca subir claves, cookies ni `.ROBLOSECURITY` (la API key de analíticas va solo en la variable de entorno `ROBLOX_ANALYTICS_API_KEY`).
