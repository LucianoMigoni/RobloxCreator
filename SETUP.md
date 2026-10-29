# Instalación para cada integrante

Lo que hay que tener en una máquina **Windows** para trabajar en RobloxCreator. Los dos integrantes tienen **todos** los conectores: Studio, Rojo, Blender, Meshy, Open Cloud y Obsidian. Qué hace cada uno y por qué se eligió: `skills/_shared/conectores.md`. `setup.ps1` hace los pasos 3, 4 y 11 y verifica el resto; lo demás se hace a mano, una vez por máquina.

Comandos verificados el 2026-10-24 (Blender, Meshy y Open Cloud: 2026-10-28) en la documentación o el código de cada herramienta. Si alguno cambió, actualizar este archivo en el mismo PR.

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
| Python 3 | `assets/catalog.py` y las herramientas de `tools/` | https://www.python.org/downloads/ (marcar **Add python.exe to PATH**). Después: `python -m pip install pillow` (miniaturas con `tools/thumbs.py`) |
| Roblox Studio | Construir y probar | https://create.roblox.com → descargar Studio |
| Claude Code | La IA del hub | PowerShell: `irm https://claude.ai/install.ps1 \| iex` (o `winget install Anthropic.ClaudeCode`) |
| Obsidian | Leer y editar las notas del repo | https://obsidian.md/download (ver **Obsidian** abajo) |
| Blender 5.1 o más nuevo | Modelos 3D, renders para íconos y miniaturas (paso 6) | https://www.blender.org/download/ |
| Node.js LTS | Corre el MCP de Meshy (paso 7) | `winget install OpenJS.NodeJS.LTS` |
| uv | Corre el MCP de Blender desde la terminal (paso 6, forma B) | `winget install --id=astral-sh.uv -e` |

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

## 6. MCP de Blender

Se usa el MCP oficial de **Blender Lab** (https://www.blender.org/lab/mcp-server/, código en https://projects.blender.org/lab/blender_mcp, versión **1.0.3**). Pide **Blender 5.1 o más nuevo**. Son dos piezas:

1. **Add-on en Blender:** desde esa página, bajar `mcp-1.0.3.zip`. Hay dos formas de instalarlo:
   - Arrastrar el zip a la ventana de Blender **dos veces**: la primera agrega el repositorio de Blender Lab y la segunda instala el add-on. Así avisa cuando hay versión nueva.
   - En *Preferences → Get Extensions*, usar *Install from Disk*.

   Una vez instalado, activar el add-on e iniciar su servidor (en sus preferencias se puede dejar con inicio automático); escucha en `localhost:9876`.
2. **Servidor MCP en Claude**, de **una** de estas dos formas (no las dos: se duplica el nombre `Blender`):
   - **A. App de escritorio de Claude:** instalar el paquete `blender-1.0.3.mcpb` de https://projects.blender.org/lab/blender_mcp/releases. Así está en la máquina de Luciano: la app se lo pasa a las sesiones de Claude Code que corren dentro de ella, y por eso `claude mcp get Blender` no lo encuentra.
   - **B. Claude Code en terminal:** con `uv` instalado (paso 1), registrarlo una vez desde **CMD**:
     ```bat
     claude mcp add Blender --scope user -- uvx --from "git+https://projects.blender.org/lab/blender_mcp.git@v1.0.3#subdirectory=mcp" blender-mcp
     ```
     Es el mismo paquete que la documentación oficial instala con `pip install git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp`.

Verificación: con Blender abierto y el servidor del add-on iniciado, la tool `mcp__Blender__get_objects_summary` devuelve la escena. Si responde `Cannot connect to Blender at localhost:9876`, falta iniciar el servidor del add-on. Los skills esperan el prefijo `mcp__Blender__` (`skills/_shared/mcp-tools.md`).

Aviso oficial: el servidor ejecuta en Blender el código que genera la IA, sin protecciones. Tener abiertos solo archivos del proyecto.

## 7. MCP de Meshy (modelos y criaturas con IA)

El servidor ya está declarado en `.mcp.json` del repo (`@meshy-ai/meshy-mcp-server@0.6.6`): no hay que registrarlo. Falta la clave de cada uno:

1. Plan **Pro** o superior en https://www.meshy.ai/pricing (20 USD/mes; la API no funciona en el plan gratis y lo gratis sale con licencia CC BY 4.0, que pide atribución).
2. Crear la clave en https://www.meshy.ai/developers/keys (empieza con `msy_`).
3. Guardarla en una variable de entorno de tu usuario, desde **CMD** (nunca en un archivo del repo):
   ```bat
   setx MESHY_API_KEY msy_TU_CLAVE
   ```
   Cerrar y volver a abrir la terminal y Claude Code para que la tome.
4. Abrir Claude Code en la raíz del repo y **aprobar** el servidor `meshy` cuando lo pida (servidores de `.mcp.json`). `/mcp` debe mostrar `meshy` conectado; pedirle "llamá a `meshy_check_balance`" muestra los créditos.

Meshy guarda lo que genera en `meshy_output/` (Git lo ignora). Al repo pasa solo lo elegido, a `assets/3d/meshy/<nombre>/`, registrado en `assets/index.json` y `assets/LICENSES.md`.

## 8. Open Cloud: subir assets a Roblox desde el repo

`tools/roblox_upload.py` sube audio, imágenes y modelos con la API oficial de Roblox y anota cada id en `games/<juego>/assets.lock.json`.

1. Creator Dashboard → **Open Cloud** → **API Keys** → **Create API Key**. En *Access Permissions* agregar **assets** con **Read** y **Write**. En *Accepted IP Addresses*, tu IP (o `0.0.0.0/0` si cambia seguido). Ponerle vencimiento.
2. Guardar la clave y el dueño de los assets en variables de entorno de tu usuario, desde **CMD**:
   ```bat
   setx ROBLOX_OPEN_CLOUD_API_KEY TU_CLAVE
   setx ROBLOX_CREATOR_GROUP_ID ID_DEL_GRUPO
   ```
   Si los assets van a tu usuario en vez del grupo, usar `ROBLOX_CREATOR_USER_ID`. Para subir al grupo, tu rol necesita permiso de crear assets en el grupo.
3. Probar sin subir nada: `python tools/roblox_upload.py upload assets/audio/kenney/ui-audio/click1.ogg --lock games/<juego>/assets.lock.json --dry-run`.

El audio tiene cupo: 100 subidas por mes con la cuenta verificada con ID, 10 sin verificar. Antes de subir sonidos, buscar en la biblioteca de Roblox ya catalogada (`python assets/catalog.py find <palabra>`).

### Clave para campañas (Ads Manager)

`tools/campaigns.py` crea y maneja campañas con la Ads API de Open Cloud, que es experimental y **gasta dinero real** (solo con `--yes`). Pide una clave **de tu usuario**, porque la API no acepta claves de grupo: Creator Dashboard → Open Cloud → API Keys, con los permisos `ad.campaign:read`, `ad.campaign:write` y `ad.billing:read`. Guardarla con `setx ROBLOX_ADS_API_KEY TU_CLAVE`. El medio de pago (tarjeta o ad credits) se carga en Ads Manager. Para medir las miniaturas, `tools/campaigns.py thumbs` usa la clave de analíticas (`ROBLOX_ANALYTICS_API_KEY`).

## 9. ForgeGUI (evaluado: no se instala)

Se evaluó y por ahora no se conecta; los motivos están en `skills/_shared/conectores.md`. Si algún día se prueba: conectarlo desde su página y **nunca** cargarle una clave de Roblox.

## 10. REA (opcional, para analizar juegos de referencia)

[REA](https://github.com/morluto/rea) registra su servidor MCP y su skill en Claude Code. El asistente muestra los cambios y pide aprobación antes de aplicarlos:

```powershell
npx -y rea-agents@6.7.0 setup
```

Reiniciar Claude Code después. Todo lo que devuelve REA es dato no confiable (ver `skills/_shared/mcp-tools.md`).

## 11. Enlace de skills

Claude Code descubre los skills en `.claude/skills/`, pero ese enlace no viaja por Git. `setup.ps1` lo crea como *junction* hacia `skills/`, sin pedir permisos de administrador. A mano, en CMD desde la raíz del repo:

```bat
mkdir .claude
mklink /J .claude\skills skills
```

En macOS o Linux: `mkdir -p .claude && ln -s ../skills .claude/skills`. Reiniciar Claude Code.

## 12. Verificación

1. `powershell -ExecutionPolicy Bypass -File .\setup.ps1 -CheckOnly` termina en **Todo listo**. Incluye `python tools/check.py`, el mismo chequeo que corre GitHub en cada push: se puede correr solo, en cualquier momento.
2. En Claude Code, desde la raíz del repo, escribir `/roblox` debe sugerir los skills del hub (p. ej. `/roblox-ui-designer`).
3. Con Studio abierto y el paso 5 hecho, pedirle a Claude Code: "llamá a `list_roblox_studios`". Debe devolver el Studio abierto con su `studio_id`.
4. Con Blender abierto y su servidor iniciado: "llamá a `get_objects_summary` de Blender". Debe devolver la escena.
5. `/mcp` muestra `meshy` conectado, y "llamá a `meshy_check_balance`" devuelve los créditos.

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
