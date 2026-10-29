# Íconos estilo hit (HUD, tienda, Game Passes)

Los íconos de los hits no son emojis 3D: tienen contorno oscuro grueso, colores muy saturados, brillo blanco arriba a la izquierda, sombreado en degradé más oscuro abajo, un poco de bisel y formas gordas que se leen a 48 px. Este es el método con que se hicieron los 45 de `assets/ui/hit-icons/` (2026-10-29). Reemplazan a Fluent Emoji en el HUD y la tienda.

| Archivo | Qué es |
|---|---|
| `hoja.jpg` | Los 45 íconos sobre fondo oscuro y claro, y a 96 y 48 px (el tamaño real en un botón) |
| `referencia-estilo.png` | Referencia de estilo: el set A en 3x3. Se adjunta a cada hoja nueva para que salga igual |
| `recetas/*.json` | Las 5 hojas (monedas y premios, menú, boosts, sistemas, huevos), con los nombres para cortar |

## Hacer íconos nuevos

1. **Receta:** copiar una de `recetas/` y cambiar `names` y la lista del prompt. Siempre 9 por hoja (3x3) y la misma forma de describirlos: objeto, color y para qué es, en inglés.
2. **Generar la hoja** (2K, 1:1, calidad alta, fondo transparente, con `referencia-estilo.png` adjunta):
   - **Con la clave de OpenAI:** `python tools/imagegen.py generate skills/_shared/iconos/recetas/<receta>.json --ref skills/_shared/iconos/referencia-estilo.png --quality high --n 1 --out <carpeta>`. Va a GPT Image 2.5 con fondo transparente.
   - **Desde Claude con Higgsfield** (si la suscripción sigue activa): `generate_image` con `gpt_image_2_5`, variante `flare`, `quality: high`, `resolution: 2k`, `aspect_ratio: 1:1`, `background: transparent` y la referencia subida como `image_references`. El prompt sale de `python tools/imagegen.py prompt <receta> --ref skills/_shared/iconos/referencia-estilo.png`. Cuesta 2,75 créditos por hoja.
   - **Sin claves:** pegar ese prompt en ChatGPT, adjuntar la referencia y pedir fondo transparente.
3. **Cortar:** `python tools/iconsheet.py slice <hoja.png> --grid 3x3 --names <names de la receta> --out <carpeta> --size 512`.
4. **Revisar:** `python tools/iconsheet.py preview <carpeta> --sheet revision.jpg`. Se descarta y se rehace la hoja si un ícono:
   - tiene letras o números;
   - es de otro tamaño o tiene otro contorno que el resto;
   - deja halo blanco;
   - no se entiende a 48 px.
5. **Al repo:** copiar los buenos a `assets/ui/hit-icons/`, agregarlos a `items` de su `manifest.json`, subir `count` en el manifest y en `assets/index.json`, y correr `python assets/catalog.py validate`.

## Lo que se aprendió

- **El modelo:** GPT Image 2.5 es el que mejor sale y el único que devuelve fondo transparente. Nano Banana Pro también sirve, pero con fondo blanco: `iconsheet.py` lo saca desde los bordes y limpia el halo.
- **Nueve por hoja:** con 9 íconos en la misma imagen el estilo sale parejo. Uno por imagen da 9 estilos distintos.
- **La referencia:** sin `referencia-estilo.png` cada hoja sale con otro grosor de contorno y otra luz.
- **El tamaño:** una hoja de 2K da íconos de unos 512 px, suficiente para el HUD y la tienda (Roblox muestra las imágenes a 1024 como máximo).

## Reglas

- La referencia es solo la nuestra. Nunca capturas ni íconos de otros juegos: el estilo se copia, el arte no (`como-son-nuestros-juegos.md` §2).
- Sin texto adentro (no se traduce): la palabra va en un `TextLabel` encima, en inglés.
- Hacer las imágenes en un plan pago o con API, para que sean nuestras (`skills/_shared/conectores.md`).
