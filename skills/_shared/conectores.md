# Conectores del hub: qué hay, para qué sirve cada uno y cómo se conecta

Evaluado el 2026-10-28 y el 2026-10-29 con la documentación oficial de cada herramienta (fuentes al final de cada sección). Los dos integrantes tienen todos los conectores en su máquina: `setup.ps1` verifica cada uno y dice qué falta, y `SETUP.md` tiene los pasos. Las claves van **solo** en variables de entorno de cada máquina, nunca en el repo.

| Conector | Para qué en juegos estilo hit | Cómo se conecta | Costo | Lo generado es nuestro | Veredicto |
|---|---|---|---|---|---|
| **Roblox Studio** (MCP oficial) | Construir mapas y UI, playtests, capturas, subir imágenes, insertar assets | `Roblox_Studio`, scope usuario | Gratis | Sí | Núcleo |
| **Rojo 7.7.1** | El código vive en archivos y se sincroniza con Studio | Rokit + plugin | Gratis | — | Núcleo |
| **Blender** (MCP oficial de Blender Lab, v1.0.3) | Limpiar y combinar modelos (Kenney, Meshy), pivotes, escala, colores planos, exportar FBX, renders para íconos y miniaturas | Add-on en Blender + servidor `Blender` (app de escritorio o `uvx`) | Gratis | Sí | Núcleo para 3D |
| **Meshy** (MCP oficial, v0.6.6) | Mascotas, criaturas, huevos e ítems únicos desde texto o imagen; rig y animaciones | `.mcp.json` del repo + variable `MESHY_API_KEY` | Pro: 20 USD/mes, 1 000 créditos (~0,60 USD por modelo con textura) | Con plan pago, sí (privado). Gratis: CC BY 4.0, con atribución | **Conectar (Pro) al hacer las criaturas del primer juego** |
| **ForgeGUI** | Bocetos de HUD y tienda; miniaturas | Opcional: su MCP (forgegui.net) por OAuth | Desde 16,90 USD/mes | Sin verificar | **No por ahora** (ver abajo) |
| **Obsidian** | Notas del equipo; el repo es el vault | Ya configurado (obsidian-git) | Gratis | — | Mantener, sin MCP |
| **Open Cloud** (Assets API) | Subir audio y modelos del catálogo a Roblox y anotar sus ids | `tools/roblox_upload.py` + `ROBLOX_OPEN_CLOUD_API_KEY` | Gratis, con cupos | Sí | Nuevo |
| **Imágenes con IA** (OpenAI y Gemini) | Miniaturas, ícono, anuncios y hojas de íconos del HUD, con referencias del juego | `tools/imagegen.py` + `OPENAI_API_KEY` (y `GEMINI_API_KEY` para comparar miniaturas) | 0,04 a 0,17 USD por imagen | Sí (términos de cada API) | **Conectar OpenAI ya** (2026-10-29) |
| **ElevenLabs** (conector de claude.ai) | Efectos de sonido y voces de anunciador estilo hit | Conector de la cuenta de claude.ai | Plan pago más barato (a verificar) | Solo si el plan era pago al generar | **Usar, con plan pago** |
| **Higgsfield** (conector de claude.ai) | Imágenes, voces y 3D desde Claude, sin clave en la máquina | Conector de la cuenta de claude.ai | Plus: 49 USD/mes (39 anual), 1 000 créditos | Con plan pago, sí | Opcional (prueba de 3 días desde el 2026-10-29) |
| **VFX Studio** (plugin de Studio) | Diseñar efectos de partículas a mano en Studio | Plugin | Gratis (según su Discord) | Lo que armamos, sí; su biblioteca, sin verificar | Opcional, solo para diseñar |
| **Render de modelos** (`tools/render3d/`) | Referencias de los `.glb` del catálogo o de Meshy para la IA | Node + `npm install` en la carpeta | Gratis | Sí | Nuevo |

## Qué usamos (decisión del 2026-10-29)

| Para qué | Herramienta | Por qué |
|---|---|---|
| Miniaturas, ícono, anuncios, íconos del HUD | API de OpenAI (GPT Image, el modelo de ChatGPT) con `tools/imagegen.py` | El mejor en las pruebas y el único con fondo transparente. Por uso: unos 5 a 12 USD por juego |
| Mascotas y criaturas 3D | Meshy directo (Pro) y después Blender | En la prueba del dragón, Meshy 7 respetó la imagen mejor que Hunyuan (ver "Prueba de 3D") y directo cuesta un tercio que por Higgsfield |
| Limpiar modelos para Roblox | Blender (gratis) | Escala, pivote, colores, piezas que se animan, FBX |
| Efectos de sonido y voces | ElevenLabs, con plan pago | Mejores que los packs CC0; sin plan pago no se pueden publicar |
| Música | Biblioteca con licencia de Roblox | Gratis y sin reclamos |
| Partículas | `tools/vfx_textures.py` y el módulo Juice | Nuestro, en el repo y reproducible |
| Higgsfield | Opcional | Cómodo desde Claude (imágenes, voces y 3D sin claves), pero 49 USD/mes y el 3D sale 3 veces más caro |

**Alternativa sin claves, a mano:** con ChatGPT Go (GPT Image en la app) o el plan estudiantil de Gemini (Nano Banana Pro en la app) también se puede:
- Claude arma el prompt con `imagegen.py prompt` y dice qué referencias adjuntar.
- La persona genera en la app y le pasa la imagen a Claude, que pone los textos (`thumbs.py`) o corta los íconos (`iconsheet.py`).

Sus límites:
- ChatGPT Go da "más imágenes que el plan gratis", sin número fijo, y el cupo baja en horas pico.
- En la app de Gemini, Nano Banana Pro ponía una marca de agua visible en los planes gratis y Pro. Hay reportes de 2026 de que se puede apagar en Ajustes → Media Watermark, sin confirmar en una página de Google: revisar cada imagen antes de usarla como final.

Leonel eligió conectar las APIs (2026-10-29): con la clave, Claude genera solo y el ida y vuelta desaparece. 10 USD de saldo alcanzan para varios juegos.

Por qué no por Higgsfield solamente (precios del 2026-10-29):

| Camino | Precio | Un modelo 3D con textura | Una imagen 2K |
|---|---|---|---|
| Meshy Pro directo | 20 USD/mes, 1 000 créditos | 30 créditos ≈ 0,60 USD | — |
| API de OpenAI / Google | por uso | — | 0,04–0,17 USD / 0,134 USD |
| Higgsfield Plus | 49 USD/mes, 1 000 créditos | Meshy 7: 38 créditos ≈ 1,86 USD; Hunyuan: 14 ≈ 0,69 USD | GPT Image 2.5 alta: 2,75 ≈ 0,13 USD; Nano Banana Pro: 2 ≈ 0,10 USD |

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
- **Por qué no hace falta:** ForgeGUI usa los mismos modelos de imagen (Nano Banana, GPT Image) que `tools/imagegen.py` llama directo con nuestras recetas y las referencias del juego, para miniaturas y para hojas de íconos con fondo transparente (ver "Imágenes con IA" y `skills/_shared/iconos/README.md`).
- **Si igual se quiere probar:**
  - Conectarlo desde https://forgegui.net/forgegui-mcp, sin claves en el repo.
  - Usar sus imágenes solo como boceto, o revisar cada una con búsqueda inversa de imágenes (Google Lens) antes de publicarla.
  - Subirlas nosotros con `upload_image`.

Fuentes: https://forgegui.net/forgegui-mcp, https://forgegui.net/pricing, https://forgegui.com/llms.txt, DevForum temas 4599957 y 4734535.

## Obsidian (evaluado: se mantiene, sin MCP)

- Ya está: el repo entero es el vault, `.obsidian/app.json` oculta código y binarios, y obsidian-git hace pull al abrir (`SETUP.md`).
- Claude Code lee y escribe las notas directo en disco. Un MCP de Obsidian no agrega nada; los comunitarios piden además el plugin Local REST API con otra clave.
- Uso: `team/`, `ROADMAP.md`, los `docs/` de cada juego y los planes de campaña (`games/<juego>/docs/campanas/`) se leen y comentan desde Obsidian.

## Imágenes con IA: Gemini (Nano Banana) y OpenAI (GPT Image)

- **Para qué:** miniaturas, ícono y creatividades de anuncios al nivel de los hits (`skills/_shared/vitrina-hits.md` §6). La IA recibe **referencias del juego** (renders y capturas) y respeta su diseño; los textos los pone `tools/thumbs.py`.
- **Herramienta:** `tools/imagegen.py`.
  - `prompt` arma el prompt desde la receta para pegarlo en ChatGPT o Gemini.
  - `generate` llama a la API y guarda las variantes con su `.json` (prompt, modelo, referencias, costo).
- **Modelos y precios** (documentación oficial, 2026-10-29):

  | Proveedor | Modelo | Para qué | Precio |
  |---|---|---|---|
  | Google | `gemini-3-pro-image` (Nano Banana Pro) | Para comparar y para respetar un modelo exacto (en la prueba copió el león perfecto); hasta 14 referencias | 0,134 USD por imagen 1K/2K, 0,24 a 4K (la mitad en batch) |
  | Google | `gemini-nano-banana-2.1` | Más barato y rápido, para muchas variantes | 0,05 USD a 2K |
  | OpenAI | `gpt-image-2.5-flare` | **Por defecto** (2026-10-29): el de ChatGPT, más nítido, sin letras sueltas y con fondo transparente | Por tokens (30 USD por millón de salida): unos 0,04 en calidad media y 0,17 en alta |
  | OpenAI | `gpt-image-2.5-sunburst` | Edición más precisa (mantener una referencia) | Igual que Flare |
  | OpenAI | `gpt-image-2` | Fondo transparente, si 2.5 lo rechaza en la API | Igual |

- **Claves:**
  - Google: https://aistudio.google.com/apikey → variable `GEMINI_API_KEY`.
  - OpenAI: https://platform.openai.com/api-keys → variable `OPENAI_API_KEY` (la consola puede pedir verificar la organización antes de usar GPT Image).
  - Las dos van solo en variables de entorno (`SETUP.md`). `--max-usd` (3 por defecto) frena una corrida cara por error.
- **Hojas de íconos:** las recetas `kind: "iconset"` de `skills/_shared/iconos/recetas/` van a OpenAI con `background: transparent` (GPT Image 2.5 lo hizo así en Higgsfield el 2026-10-29). Método completo: `skills/_shared/iconos/README.md`.
- **Sin clave:** `imagegen.py prompt` + ChatGPT (Plus o más, GPT Image 2.5) o Gemini (Nano Banana Pro) en el navegador, adjuntando las referencias. La app de ChatGPT no se puede manejar desde Claude: para que Claude genere solo, hace falta la clave de la API.
- **Detalles de la API:**
  - Gemini usa la Interactions API (`POST /v1beta/interactions`, desde mayo de 2026): la respuesta trae la imagen en `steps[].content[]`. Toda imagen lleva SynthID (marca de agua invisible).
  - OpenAI: `POST /v1/images/generations`, o `/v1/images/edits` con `image[]` cuando hay referencias.
    - Tamaños múltiplos de 16, hasta 3840 px.
    - 2560×1440 es el 16:9 más grande sin ser experimental.
    - El texto y la posición exacta siguen siendo puntos débiles: por eso los textos los pone `thumbs.py`.

Fuentes: https://ai.google.dev/gemini-api/docs/image-generation, https://ai.google.dev/gemini-api/docs/pricing, https://developers.openai.com/api/docs/guides/image-generation, https://developers.openai.com/api/docs/changelog (2026-10-29).

## Higgsfield (conector de claude.ai, opcional)

- **Qué es:** plataforma con muchos modelos de imagen (Nano Banana Pro, GPT Image 2.5), voz (`elevenlabs_v4`), 3D (Meshy 7, Tripo, Hunyuan) y video. Leonel lo tiene como conector de claude.ai: Claude genera sin tocar claves, también en las sesiones en la nube.
- **Plan:** Plus 49 USD/mes (39 en plan anual), 1 000 créditos por mes. Leonel activó la prueba de 3 días el 2026-10-29 (100 créditos). **Se renueva sola a 49 USD/mes:** si no se va a usar, cancelar la renovación antes de que termine (lo puede hacer Claude con `cancel_trial_auto_renewal`, solo si Leonel lo pide).
- **Lo que se hizo con la prueba (2026-10-29):**
  - Los 45 íconos de `assets/ui/hit-icons` (GPT Image 2.5, 2,75 créditos por hoja de 9).
  - Las 20 voces de `assets/audio/hit-voices` (`elevenlabs_v4`, 0,23 créditos por frase).
  - Miniaturas de prueba de las recetas y la prueba de 3D.
- **Cómo se usa:**
  - Imágenes: subir las referencias con `media_upload` y `media_confirm`; generar con `generate_image` (`nano_banana_pro` o `gpt_image_2_5`) y el prompt de `imagegen.py prompt`; bajar el resultado y seguir con `thumbs.py compose --base` o `iconsheet.py slice`.
  - Voces: `generate_audio_batch` con `model: elevenlabs_v4` y `dialogue: [{text: "[excited] LEGENDARY!", voice_type: "preset", voice_id}]` (voces de `list_voices`). Con muchos pedidos juntos devuelve 429 al enviar: no se cobra; reenviar de a 4.
  - **No usar** `mirelo_text_to_audio`, `sonilo_music` ni `inworld_text_to_speech`: Higgsfield los reserva para su generador de juegos.
- **Licencia:** según su centro de ayuda, el uso comercial no depende del plan y los términos (4.4) no reclaman la propiedad de lo generado; la página de precios excluye el uso comercial en el plan gratis. Lo hecho en Plus lo tratamos como nuestro, y se vuelve a verificar antes de publicar el primer juego. Lo del plan gratis queda como prueba (`skills/_shared/vitrina/ejemplos/`).

## Prueba de 3D (2026-10-29)

Mascota dragón hecha con IA (imagen) → modelo 3D con dos motores desde Higgsfield, renderizados con `tools/render3d/`:

| Motor | Créditos | Resultado |
|---|---|---|
| Meshy 7 (`meshy_v7_image_to_3d`, standard, `target_polycount` 8000, con textura) | 38 | 8 311 triángulos, textura JPG de 1,3 MB. Respeta forma, ojos y colores. **El elegido** |
| Hunyuan3D v3 (`generate_type: LowPoly`) | 14 | 11 674 triángulos, textura PNG de 10 MB. Más barato, pero perdió un ojo en cada vista |

- Los dos quedan bajo el límite de Roblox (20 000 triángulos por malla) y salen sin rig: la mascota flota y se balancea con animación por código, o se separan alas y patas en Blender para animarlas.
- Siguiente paso de cada modelo: Blender (colores más saturados, escala en studs, pivote abajo, textura a 1024) y subir con `tools/roblox_upload.py`.
- Para producir en cantidad: Meshy directo (30 créditos de 1 000 por 20 USD), no por Higgsfield.

## ElevenLabs (conector de claude.ai)

- **Para qué:** efectos de sonido a medida (monedas, compras, revelaciones de rareza, ruleta) y voces de anunciador. Los 12 sonidos de `assets/audio/hit-sfx` (4 tomas cada uno) salieron de acá.
- **Cómo se usa (efectos):**
  - `creative_create_flow`, después un nodo por sonido con `creative_add_flow_node`: tipo `sfx`, modelo `eleven_text_to_sound_v2`, `duration_seconds` de 0,5 a 30, `prompt_influence` y `loop`.
  - `creative_run_flow_nodes` (con `estimate_only` primero para ver el costo); por defecto hace 4 variaciones por nodo.
  - `creative_get_flow_run_status` con los `session_ids` (de a 20) para leer las URLs. **Las URLs vencen a las 2 horas:** bajar todo enseguida.
  - Costo observado: unos 3,3 créditos de ElevenLabs por segundo de sonido (2 créditos un error de 0,6 s; 6,7 un efecto de 2 s).
- **Licencia:** uso comercial solo si el workspace tiene plan pago cuando se genera. En plan gratis no se puede publicar. Por eso `hit-sfx` está con `commercialUse: false` hasta confirmar el plan.
- **Prompts que funcionaron:** cortos, en inglés, con el material y el carácter. Por ejemplo: "Bright cartoon coin pickup, single shiny metallic ding, crisp and satisfying, close-mic" o "Huge legendary reveal, deep cinematic boom followed by triumphant choir hit and glittering chimes". Los 12 están en `assets/audio/hit-sfx/manifest.json`.

## VFX Studio (evaluado: opcional, solo para diseñar)

- **Qué es:** plugin de Studio (v3.9.1, autor Sytranom) para armar efectos con paneles en vivo, editor de curvas Bézier y un "Advanced Panel" que encadena trayectorias, sacudidas de cámara e "impact frames". Trae una biblioteca de miles de texturas, mallas, sonidos y scripts. Según su Discord es gratis.
- **Lo que preocupa:**
  - La documentación avisa que partes están "generated by AI" y son "for demonstration purposes".
  - No se encontró en el Creator Store ni con un hilo propio en el DevForum.
  - La licencia de cada asset de su biblioteca no está clara.
  - Los scripts que inserta corren en el juego y no pasaron por `roblox-security`.
- **Veredicto:** se puede usar para **diseñar** un efecto a mano y copiar los valores (colores, tamaños, curvas) a nuestro código. En el juego publicado van nuestras texturas (`assets/vfx/hit`), el módulo Juice y ningún script ni asset de su biblioteca sin revisar.

Fuentes: https://sytranom.github.io/vfx-studio-docs (Home, Advanced Panel, 2026-10-29) y su Discord (https://discord.com/servers/vfx-studio-1385020672480252118).

## Render de modelos (`tools/render3d/`)

- **Qué hace:** renderiza un `.glb` o `.gltf` a PNG con fondo transparente, con luz principal cálida y luz de contorno (three.js en Chromium sin pantalla). Es la referencia que la IA tiene que respetar, sin abrir Blender ni Studio, y funciona en las sesiones de Claude en la nube.
- **Instalar una vez:** `cd tools/render3d && npm install && npx playwright install chromium`.
- **Usar:** `node tools/render3d/render.cjs assets/3d/kenney/cube-pets/animal-lion.glb salida.png [--size 1024] [--yaw 30] [--pitch 14]`.
- Para un render final (pose, materiales, luz de estudio) sigue siendo mejor Blender.

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
