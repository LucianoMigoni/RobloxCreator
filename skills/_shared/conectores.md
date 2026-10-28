# Conectores del hub: qué hay, para qué sirve cada uno y cómo se conecta

Evaluado el 2026-10-28 con la documentación oficial de cada herramienta (fuentes al final de cada sección). Los dos integrantes tienen todos los conectores en su máquina: `setup.ps1` verifica cada uno y dice qué falta, y `SETUP.md` tiene los pasos. Las claves van **solo** en variables de entorno de cada máquina, nunca en el repo.

| Conector | Para qué en juegos estilo hit | Cómo se conecta | Costo | Lo generado es nuestro | Veredicto |
|---|---|---|---|---|---|
| **Roblox Studio** (MCP oficial) | Construir mapas y UI, playtests, capturas, subir imágenes, insertar assets | `Roblox_Studio`, scope usuario | Gratis | Sí | Núcleo |
| **Rojo 7.7.1** | El código vive en archivos y se sincroniza con Studio | Rokit + plugin | Gratis | — | Núcleo |
| **Blender** (MCP oficial de Blender Lab, v1.0.3) | Limpiar y combinar modelos (Kenney, Meshy), pivotes, escala, colores planos, exportar FBX, renders para íconos y miniaturas | Add-on en Blender + servidor `Blender` (app de escritorio o `uvx`) | Gratis | Sí | Núcleo para 3D |
| **Meshy** (MCP oficial, v0.6.6) | Mascotas, criaturas, huevos e ítems únicos desde texto o imagen; rig y animaciones; íconos PNG con fondo transparente | `.mcp.json` del repo + variable `MESHY_API_KEY` | Pro: 20 USD/mes, 1 000 créditos | Con plan pago, sí (privado). Gratis: CC BY 4.0, con atribución | **Conectar (Pro)** |
| **ForgeGUI** | Bocetos de HUD y tienda; miniaturas | Opcional: su MCP (forgegui.net) por OAuth | Desde 16,90 USD/mes | Sin verificar | **No por ahora** (ver abajo) |
| **Obsidian** | Notas del equipo; el repo es el vault | Ya configurado (obsidian-git) | Gratis | — | Mantener, sin MCP |
| **Open Cloud** (Assets API) | Subir audio y modelos del catálogo a Roblox y anotar sus ids | `tools/roblox_upload.py` + `ROBLOX_OPEN_CLOUD_API_KEY` | Gratis, con cupos | Sí | Nuevo |

## De dónde sale cada asset (orden de preferencia)

1. **Catálogo del repo** (`python assets/catalog.py find <palabra>`): miles de modelos, sonidos, partículas e íconos ya revisados, CC0/MIT o de Roblox. Gratis y sin riesgo.
2. **Algo único que el juego necesita** (la mascota estrella, el huevo del evento, el jefe): Meshy → Blender → registrar en `assets/index.json` y `assets/LICENSES.md` en el mismo cambio.
3. **Props simples dentro de Studio**: `generate_mesh` / `generate_procedural_model` del MCP de Studio (gratis, ya quedan en Roblox).
4. **Subir a Roblox**: audio y modelos con `tools/roblox_upload.py`; imágenes de UI con `upload_image` del MCP de Studio. Después `insert_asset` (MCP) para ponerlos en el place.

## Roblox Studio

Ya documentado en `skills/_shared/mcp-tools.md` (28 tools) y `SETUP.md`. Lo nuevo para este estilo: `upload_image` para íconos y miniaturas, `insert_asset` para traer lo subido con Open Cloud, y `screen_capture` en playtest para sacar capturas reales para miniaturas y anuncios.

## Rojo

Fijado en `rokit.toml` (raíz, `template/` y cada juego; `tools/check.py` exige que coincidan). Sin cambios: `rojo serve` en la carpeta del juego y **Connect** en el plugin.

## Blender (MCP oficial de Blender Lab)

- **Qué es:** un add-on que corre dentro de Blender y un servidor MCP (`blender-mcp`) que habla con él por TCP (`localhost:9876`). Pide **Blender 5.1 o más nuevo**. Licencia GPL-3.0; lo que modelamos es nuestro.
- **Tools** (prefijo `mcp__Blender__`): `execute_blender_code`, `get_objects_summary`, `get_object_detail_summary`, `get_blendfile_summary_*`, `get_python_api_docs`, `search_api_docs`, `search_manual_docs`, `get_screenshot_of_window_as_image`, `get_screenshot_of_area_as_image`, `get_screenshot_of_window_as_json`, `jump_to_tab_by_name`, `jump_to_tab_by_space_type`, `jump_to_view3d_object_by_name`, `jump_to_view3d_object_data_by_name`, `render_thumbnail_to_path`, `render_viewport_to_path`; las variantes `*_for_cli` usan Blender sin ventana.
- **Conexión**, una de las dos formas (no las dos: el nombre se duplica):
  - App de escritorio de Claude: instalar `blender-1.0.3.mcpb` de las releases. Así lo tiene Luciano; `claude mcp get Blender` no lo ve, pero las sesiones de Claude Code dentro de la app sí.
  - Claude Code en terminal: con [uv](https://docs.astral.sh/uv/) instalado, desde CMD:
    `claude mcp add Blender --scope user -- uvx --from "git+https://projects.blender.org/lab/blender_mcp.git@v1.0.3#subdirectory=mcp" blender-mcp`.
    Es el mismo paquete que instala la documentación oficial con `pip install git+...#subdirectory=mcp`, y el `.mcpb` lo arranca con `uv run blender-mcp`.
- **Cuidado (aviso oficial):** el servidor ejecuta en Blender el código que genera la IA, sin protecciones. Abrir solo archivos del proyecto y no tener abiertos `.blend` ajenos con datos importantes.
- **Uso en el hub:** pasar modelos de Meshy o Kenney a estilo hit (colores planos saturados, contorno, escala de Roblox), fijar pivotes, partir en piezas animables, exportar FBX y renderizar fondos e íconos 3D. Pasos en el skill de assets 3D.

Fuentes: https://www.blender.org/lab/mcp-server/, `readme.md`, `readme_tools.rst` y `mcp/manifest.json` del repo https://projects.blender.org/lab/blender_mcp (release v1.0.3 del 2026-09-11).

## Meshy (MCP oficial)

- **Qué es:** generación 3D con IA: texto o imagen → modelo con textura, retopología, rig y animaciones, y también imágenes 2D. Servidor MCP oficial `@meshy-ai/meshy-mcp-server` (MIT, 28 tools, Node 18+).
- **Tools** (prefijo `mcp__meshy__`): `meshy_text_to_3d`, `meshy_text_to_3d_refine`, `meshy_image_to_3d`, `meshy_multi_image_to_3d`, `meshy_remesh`, `meshy_retexture`, `meshy_rig`, `meshy_animate`, `meshy_text_to_motion`, `meshy_list_animations`, `meshy_convert`, `meshy_resize`, `meshy_uv_unwrap`, `meshy_text_to_image`, `meshy_image_to_image`, `meshy_get_task_status`, `meshy_list_tasks`, `meshy_cancel_task`, `meshy_download_model`, `meshy_list_models`, `meshy_check_balance`, `meshy_list_usage`, `meshy_creative_lab` y 5 de impresión 3D que no usamos.
- **Conexión:** ya está declarado en `.mcp.json` del repo (versión fijada). Cada uno compra el plan, crea su clave en https://www.meshy.ai/developers/keys y la guarda en la variable `MESHY_API_KEY` de su usuario (`SETUP.md`). Claude Code pide aprobar el servidor la primera vez.
- **Costo (verificado 2026-10-28):** Free 0 USD (100 créditos/mes, salida CC BY 4.0, sin API); **Pro 20 USD/mes** (1 000 créditos/mes, "hasta 100 assets", licencia privada). La clave de API pide Pro o más y la API cobra en créditos prepagos que se cargan desde la suscripción: al comprar, confirmar que los créditos del plan sirven para la API.
- **Créditos por tarea** (docs.meshy.ai/en/api/pricing):
  - Smart Topology `meshy-t2.5`: 5 sin textura, 15 con textura 2K. Es el modelo para Roblox: malla limpia de 100 a 30 000 caras (Roblox acepta hasta 20 000 triángulos por malla).
  - Meshy 7.1: 20 sin textura y 30 con textura.
  - Rig: 5. Animación: 3 por acción.
  - Imagen: 3 a 12 según el modelo, con fondo transparente (`remove_background`).
  - Con Pro: unas **60 mascotas texturizadas o 150 íconos por mes**.
- **Licencia (términos de Meshy, 3.2):** en plan gratis Meshy es dueño de lo generado y lo licencia CC BY 4.0, con atribución obligatoria. En plan pago, el contenido es privado y del cliente. Para juegos publicados: **solo con plan pago**, y registrar cada asset con `license: "Meshy Pro (propio)"` y `commercialUse: true`.
- **Para el estilo hit:**
  - Prompt base: *"cute chibi toy, big head, big shiny eyes, simple rounded shapes, bright saturated colors, clean flat colors, game asset, no text"*.
  - `model_type: "smart-topology"`, `ai_model: "meshy-t2.5"`, `target_polycount` de 2 000 a 6 000 para mascotas y de 500 a 2 000 para props repetidos.
  - El rig de Meshy es para humanoides. Las mascotas de cuatro patas se animan con el animador procedural de la plantilla (piezas separadas, como Kenney Cube Pets) o en Blender.
- **Cuidado:** guarda todo en `meshy_output/` (ignorado por Git). Al repo solo pasa lo elegido, a `assets/3d/meshy/<nombre>/`. Revisar que cada criatura sea original: nada de personajes, marcas ni "brainrots" de otros juegos (`team/decisiones.md`).

Fuentes: README de https://github.com/meshy-dev/meshy-mcp-server (v0.6.6 en npm, 2026-10-26), https://www.meshy.ai/pricing, https://docs.meshy.ai/en/api/pricing, https://www.meshy.ai/terms-of-use.

## ForgeGUI (evaluado: no se conecta por ahora)

- **Qué es:** generadores web de imágenes con IA para juegos (miniaturas, "GUI", íconos, algunos también 3D). Devuelven **imágenes**, no UI que funcione: la UI real sigue saliendo de UIKit y `roblox-ui-designer`.
- **Hay al menos tres sitios distintos con ese nombre:** forgegui.com (el que se promociona en el DevForum), forgegui.net (tiene MCP para Claude y un plugin de Studio) y forgegui.xyz. No queda claro cuál es el original: verificar dónde se paga.
- **Antecedentes:**
  - En el hilo de presentación en el DevForum (2026-04-26), un desarrollador superpuso una miniatura de ejemplo con la de un juego existente y eran casi idénticas. El hilo se cerró.
  - En otro hilo (2026-07-13) lo llaman spam y estafa.
  - Para nosotros, el riesgo es copiar arte ajeno sin saberlo: un reclamo de copyright da de baja la imagen o el juego.
- **El MCP de forgegui.net:**
  - Se conecta por OAuth desde su página; la dirección del servidor aparece solo con sesión iniciada.
  - Gasta los mismos créditos que la web: Starter 16,90 USD/mes (7,99 en plan anual) por 1 000 créditos, unas 100 imágenes.
  - Para publicar en Roblox pide **cargarle una clave personal de Roblox: no hacerlo nunca**.
  - Su página de precios usa cuenta regresiva y "53% OFF": la misma urgencia que nosotros no usamos.
  - Los términos se cargan por JavaScript y no se pudieron leer. Los planes pagos dicen "Private commercial-use workflow" y "No watermarks".
- **Por qué no hace falta:** Meshy `meshy_text_to_image` usa los mismos modelos de imagen que ofrece ForgeGUI (Nano Banana, GPT Image), con fondo transparente y licencia propia, dentro de la suscripción que ya pagamos. Para miniaturas, el kit del repo (render en Blender o Studio + composición) da más control.
- **Si igual se quiere probar:**
  - Conectarlo desde https://forgegui.net/forgegui-mcp, sin claves en el repo.
  - Usar sus imágenes solo como boceto, o revisar cada una con búsqueda inversa de imágenes (Google Lens) antes de publicarla.
  - Subirlas nosotros con `upload_image`.

Fuentes: https://forgegui.net/forgegui-mcp, https://forgegui.net/pricing, https://forgegui.com/llms.txt, DevForum temas 4599957 y 4734535.

## Obsidian (evaluado: se mantiene, sin MCP)

- Ya está: el repo entero es el vault, `.obsidian/app.json` oculta código y binarios, y obsidian-git hace pull al abrir (`SETUP.md`).
- Claude Code lee y escribe las notas directo en disco. Un MCP de Obsidian no agrega nada; los comunitarios piden además el plugin Local REST API con otra clave.
- Uso: `team/`, `ROADMAP.md`, los `docs/` de cada juego y los planes de campaña (`games/<juego>/docs/campanas/`) se leen y comentan desde Obsidian.

## Open Cloud: subir assets desde el repo

- **Qué es:** la Assets API oficial (`https://apis.roblox.com/assets/v1/assets`) sube un archivo y devuelve su `assetId`, sin pasar por Studio. `tools/roblox_upload.py` la usa, espera a que termine la moderación y anota cada id en `games/<juego>/assets.lock.json`. Si el archivo no cambió, no lo vuelve a subir: el cupo de audio es chico.
- **Tipos y límites:**
  - Hasta 20 MB por archivo.
  - Audio `.mp3/.ogg/.wav/.flac`: hasta 7 min; **100 subidas por mes con ID verificado**, 10 sin verificar.
  - Imagen `.png/.jpg/.bmp/.tga`: menor a 8000×8000; se sube como Decal.
  - Modelo `.fbx/.gltf/.glb/.rbxm/.rbxmx`: llega como paquete con MeshParts.
- **Clave:** Creator Dashboard → Open Cloud → API Keys, con permiso **assets** (lectura y escritura). Se guarda en `ROBLOX_OPEN_CLOUD_API_KEY`. Dueño: `ROBLOX_CREATOR_GROUP_ID` (recomendado: los juegos son del grupo) o `ROBLOX_CREATOR_USER_ID`.
- **Para sonidos**, primero usar la biblioteca de Roblox ya catalogada (`assets/audio/roblox-library`, `assets/audio/roblox-music`): no gasta cupo. Subir solo los sonidos propios que hagan falta.

Fuente: https://create.roblox.com/docs/cloud/guides/usage-assets (creator-docs, revisado el 2026-10-28).
