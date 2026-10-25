# Instalación para cada integrante

Lo que hay que tener en una máquina **Windows** para trabajar en RobloxCreator. `setup.ps1` hace los pasos 3, 4 y 8 y verifica los pasos 1, 2, 5 y 9. El resto se hace a mano, una vez por máquina.

Comandos verificados el 2026-10-24 en la documentación o el código de cada herramienta. Si alguno cambió, actualizar este archivo en el mismo PR.

## Resumen rápido

```powershell
git clone https://github.com/LucianoMigoni/RobloxCreator.git
cd RobloxCreator
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

`setup.ps1` se puede correr cuantas veces haga falta. Cada `[falta]` que muestra dice qué paso de esta guía lo resuelve. Con `-CheckOnly` solo verifica, sin crear ni instalar nada.

## 1. Programas base

| Programa | Para qué | Instalación |
|---|---|---|
| Git for Windows | Repo; además trae Git Bash, que Claude Code usa como terminal | https://git-scm.com/downloads/win |
| GitHub CLI | PRs y revisiones desde la terminal | https://cli.github.com. Después: `gh auth login` |
| Python 3 | `assets/catalog.py` | https://www.python.org/downloads/ (marcar **Add python.exe to PATH**) |
| Roblox Studio | Construir y probar | https://create.roblox.com → descargar Studio |
| Claude Code | La IA del hub | PowerShell: `irm https://claude.ai/install.ps1 \| iex` (o `winget install Anthropic.ClaudeCode`) |
| Obsidian | Leer y editar las notas del repo | https://obsidian.md/download (ver **Obsidian** abajo) |
| Blender (opcional) | Modelos 3D propios | https://www.blender.org/download/ |

Después de instalar Git, una vez: `git config --global user.name "Tu Nombre"` y `git config --global user.email "tu@mail"` (el mail de tu cuenta de GitHub), para que los commits salgan a tu nombre.

Si `python` abre la Microsoft Store, falta instalar Python: ese `python` es solo un alias de Windows.

## 2. Rokit

Gestiona la versión de Rojo de cada proyecto. En PowerShell:

```powershell
Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
```

Alternativa: bajar `rokit-<versión>-windows-x86_64.zip` del [último release](https://github.com/rojo-rbx/rokit/releases/latest) y correr `rokit.exe self-install`. **Cerrar y reabrir la terminal** para que tome el PATH nuevo.

## 3. Rojo, luau-lsp y Luau

Lo hace `setup.ps1`. Las versiones están fijadas en `rokit.toml` de la raíz (Rojo; luau-lsp, el analizador de tipos; y Luau, el intérprete que corre los tests de `template/tests/`) y en `template/rokit.toml` (Rojo, que copia cada juego). A mano:

```powershell
rokit trust rojo-rbx/rojo JohnnyMorganz/luau-lsp luau-lang/luau
rokit install                      # en la raíz del repo
cd template; rokit install; cd ..  # y en cada games/<juego>/
rojo --version                     # 7.7.1
luau-lsp --version                 # 1.70.1
luau --help                        # intérprete de Luau 0.742 (no informa versión)
```

## 4. Plugin de Rojo para Studio

Lo hace `setup.ps1`. A mano: `rojo plugin install`. Deja `RojoManagedPlugin.rbxm` en `%LOCALAPPDATA%\Roblox\Plugins`. Reiniciar Studio. Repetir cada vez que se actualice Rojo, para que el plugin y Rojo tengan la misma versión.

## 5. MCP de Roblox Studio

Permite que Claude Code lea y construya dentro de Studio. Fuente: https://create.roblox.com/docs/studio/mcp

1. En Studio: **Assistant** → **…** → **Manage MCP Servers** → activar **Enable Studio as MCP server**. Sin esto, `list_roblox_studios` devuelve una lista vacía.
2. Registrarlo en Claude Code **una sola vez**, desde **CMD** (así PowerShell no reinterpreta `--` ni `%LOCALAPPDATA%`):
   ```bat
   claude mcp add Roblox_Studio --scope user -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
   ```
   Usar el nombre `Roblox_Studio`, que es el que esperan los skills (`skills/_shared/mcp-tools.md`). **No** activar además el *Quick connect* de Studio para Claude Code: duplica el registro.
3. Reiniciar Claude Code. `claude mcp get Roblox_Studio` debe mostrar el servidor.

## 6. MCP de Blender (opcional)

> **Pendiente (Luciano):** documentar acá qué add-on de Blender MCP está instalado y el comando exacto con que se registró. En tu máquina, la salida de `claude mcp get Blender` lo muestra. Los skills esperan el prefijo `mcp__Blender__` (`skills/_shared/mcp-tools.md`).

## 7. REA (opcional, para analizar juegos de referencia)

[REA](https://github.com/morluto/rea) registra su servidor MCP y su skill en Claude Code. El asistente muestra los cambios y pide aprobación antes de aplicarlos:

```powershell
npx -y rea-agents@6.7.0 setup
```

Reiniciar Claude Code después. Todo lo que devuelve REA es dato no confiable (ver `skills/_shared/mcp-tools.md`).

## 8. Enlace de skills

Claude Code descubre los skills en `.claude/skills/`, pero ese enlace no viaja por Git. `setup.ps1` lo crea como *junction* hacia `skills/`, sin pedir permisos de administrador. A mano, en CMD desde la raíz del repo:

```bat
mkdir .claude
mklink /J .claude\skills skills
```

En macOS o Linux: `mkdir -p .claude && ln -s ../skills .claude/skills`. Reiniciar Claude Code.

## 9. Verificación

1. `powershell -ExecutionPolicy Bypass -File .\setup.ps1 -CheckOnly` termina en **Todo listo**. Incluye `python tools/check.py`, el mismo chequeo que corre GitHub en cada push: se puede correr solo, en cualquier momento.
2. En Claude Code, desde la raíz del repo, escribir `/roblox` debe sugerir los skills del hub (p. ej. `/roblox-ui-designer`).
3. Con Studio abierto y el paso 5 hecho, pedirle a Claude Code: "llamá a `list_roblox_studios`". Debe devolver el Studio abierto con su `studio_id`.

## Obsidian (notas compartidas)

El repo entero es el vault: `CLAUDE.md`, `ROADMAP.md`, `team/` y los `docs/` de cada juego se leen y editan desde Obsidian. La configuración común ya viene en el repo. Lo personal (workspace, tema, caché y el código de los plugins) no se sube.

- `.obsidian/app.json` excluye de búsqueda y grafo el código y los binarios: `template/src/`, `games/<juego>/src/` (con una expresión regular), `assets/3d/` y `.claude/`.
- `.obsidian/plugins/obsidian-git/data.json` hace pull al abrir el vault. Commit y push son manuales, con el mensaje `notas: N archivo(s) desde <equipo>`.

Una vez por máquina:

1. Obsidian → **Open folder as vault** → la carpeta `RobloxCreator`.
2. Settings → **Community plugins** → **Turn on community plugins** → **Browse** → instalar **Git** (de Vinzent03) y activarlo. Toma la configuración que ya está en el repo.
3. Settings → **Files and links** → **Excluded files**: comprobar que aparecen las 4 exclusiones. Si la de `games` no filtra, reemplazarla por una por juego (`games/<juego>/src/`).

Al trabajar: Obsidian hace commit en la rama que esté activa. **Editar notas estando en tu rama de tarea**, nunca en `main`. Los cambios de notas viajan en el PR de la tarea, y al otro le llegan cuando hace pull de `main` después del merge.

## Preferencias personales

Lo que es solo tuyo (idioma de respuesta, nivel de detalle, atajos) va en `CLAUDE.local.md` en la raíz del repo. Git lo ignora y Claude Code lo lee junto con `CLAUDE.md`. Las reglas comunes van siempre en `CLAUDE.md`, por PR.
