# Íconos estilo hit (HUD, tienda, Game Passes)

Los hits usan dos familias de íconos (`skills/roblox-ui-designer/references/hud-hits.md` §Íconos):

1. **Objetos 3D** (plata, gemas, regalo, huevos, corona, trébol, botones grandes del menú):
   - 3D de juguete con sombreado de dibujo, colores muy saturados y brillos blancos duros;
   - contorno azul muy oscuro y grueso;
   - formas gordas que se leen a 48 px.
   - Están en `assets/ui/hud-icons/` (36, del 2026-10-29).
2. **Íconos planos** (carrito, libro, engranaje, calendario) para botones chicos y la barra de Roblox.
   - Están en `assets/ui/icons-flat/` y los hace `tools/flat_icons.py` desde Material Symbols.

| Archivo | Qué es |
|---|---|
| `hoja.jpg` | Los 36 de `hud-icons` |
| `referencia-estilo.png` | La hoja A de `hud-icons`. Se adjunta para que un ícono nuevo salga con el mismo estilo |
| `recetas/hud-*.json` | Las 4 hojas de `hud-icons` (modo `redraw`), con los nombres para cortar |
| `recetas/*.json` (el resto) | Las hojas de la primera tanda (`hit-icons`). Siguen sirviendo como lista de objetos |

## Por qué así

- **Emojis 3D (Fluent):** el equipo los descartó por genéricos.
- **IA sola, con nuestra referencia de estilo** (`hit-icons`, primera tanda): salió clip-art plano con degradé. Mejor, pero lejos de los hits.
- **Render 3D propio con sombreado de dibujo** (`tools/render3d/icons.cjs`): formas y colores bajo control y sin límite, pero con detalles flojos (los dedos del puño, por ejemplo).
- **Lo que funcionó: render propio + terminación con IA.**
  1. El render da la forma, el color y el encuadre de cada objeto.
  2. GPT Image 2.5 lo redibuja con el acabado de los hits.
  3. Salen parejos, con buena anatomía y propios: la referencia es arte nuestro, nunca el de otro juego.

## Hacer íconos nuevos

1. **Base 3D.** Si el objeto no está en `tools/render3d/icons/models.js`, agregar una función con su nombre: piezas simples, colores saturados, ángulo de cámara. Después:
   `node tools/render3d/icons.cjs render <9 nombres> --out <carpeta>`
   Hace falta `npm install` en `tools/render3d` una vez.
2. **Hoja de referencia:**
   `python tools/iconsheet.py compose <los 9 png en orden> --out base.png`
3. **Receta.** Copiar una de `recetas/hud-*.json` y cambiar `names` y la lista del prompt: objeto, color y detalles, en inglés y en el mismo orden. Siempre 9 por hoja: así el estilo sale parejo.
4. **Generar** (1:1, calidad alta, fondo transparente, `base.png` adjunta):
   - **Con la clave de OpenAI:**
     `python tools/imagegen.py generate <receta> --ref base.png --quality high --n 1 --out <carpeta>`
   - **Desde Claude con Higgsfield** (si hay créditos):
     - `generate_image` con `gpt_image_2_5`, `quality: high`, `resolution: 2k` (o `1k`, más barato), `aspect_ratio: 1:1`, `background: transparent` y `base.png` subida como `image_references`.
     - El prompt sale de `python tools/imagegen.py prompt <receta> --ref base.png`.
     - Cuesta 2,75 créditos en 2k y 1,5 en 1k.
   - **Sin claves:** pegar ese prompt en ChatGPT, adjuntar `base.png` y pedir fondo transparente.
5. **Cortar:**
   `python tools/iconsheet.py slice <hoja.png> --grid 3x3 --names <names de la receta> --out <carpeta> --size 512`
6. **Revisar:** `python tools/iconsheet.py preview <carpeta> --sheet revision.jpg`. Se rehace la hoja si un ícono:
   - tiene letras o números;
   - es de otro tamaño o tiene otro contorno que el resto;
   - deja halo blanco;
   - tiene manos o patas mal;
   - no se entiende a 48 px.
7. **Al repo:**
   1. Copiar los buenos a `assets/ui/hud-icons/`.
   2. Agregarlos a `items` de su `manifest.json`.
   3. Subir `count` ahí y en `assets/index.json`.
   4. Correr `python assets/catalog.py validate`.

## Lo que se aprendió

- **El modelo:** GPT Image 2.5 respeta la base y devuelve fondo transparente. Nano Banana Pro sirve con fondo blanco: `iconsheet.py` lo saca desde los bordes.
- **El tamaño:**
  - Una hoja de 2K da íconos de unos 680 px; una de 1K, de unos 340 px.
  - Las dos alcanzan para el HUD (los botones muestran el ícono a 60–130 px).
  - Para íconos que van grandes en la tienda, 2K.
- **La anatomía:** pedirla explícita en el prompt ("closed fist with four curled fingers and a thumb").

## Reglas

- La referencia es solo nuestra: nuestros renders o nuestras hojas. Nunca capturas ni íconos de otros juegos: el estilo se copia, el arte no (`como-son-nuestros-juegos.md` §2).
- Sin texto adentro, porque no se traduce: la palabra va en un `TextLabel` encima, en inglés.
- Hacer las imágenes en un plan pago o con API, para que sean nuestras (`skills/_shared/conectores.md`).
