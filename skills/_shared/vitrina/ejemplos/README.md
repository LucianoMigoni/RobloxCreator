# Ejemplos de la vitrina: antes y después (2026-10-29)

La vara de calidad para miniaturas e íconos. Se hicieron para comparar con los hits: no son de ningún juego nuestro y **no se publican**. Las primeras se generaron en el plan gratis de Higgsfield, que es solo para pruebas; la comparación de recetas, en la prueba del plan Plus.

| Archivo | Qué es |
|---|---|
| `antes-despues.jpg` | Arriba el método viejo (emojis 3D sobre degradé); abajo el nuevo |
| `despues-robo-trex.jpg` | Receta `robo-tension`, sin referencias, con textos de `thumbs.py` |
| `despues-secret-leon.jpg` | Receta `rareza-secret`, con el render del león como referencia |
| `despues-icono-leon.png` | Receta `icono-heroe`, con la misma referencia |
| `referencia-leon.png` | Render de `assets/3d/kenney/cube-pets/animal-lion.glb` con `tools/render3d/` |
| `despues-robo-dragon-gpt.jpg` | Receta `robo-tension` con GPT Image 2.5 (`gpt-image-2.5-flare`, calidad alta, sin referencias) desde `tools/imagegen.py` con la clave de OpenAI, y textos de `thumbs.py` (2026-11-02). USD 0,11 por imagen; `thumbs.py check`: saturación 158 y contraste 64 (hits: 160 y 55) |
| `recetas-nano-banana-vs-gpt.jpg` | Las recetas `numero-gigante` y `mas-uno` con Nano Banana Pro y con GPT Image 2.5, y `objeto-gigante` y `evento-temporada` con Nano Banana Pro, sin textos |

## Cómo se hicieron

- **Modelo:** Nano Banana Pro, desde el conector Higgsfield (`generate_image`, `nano_banana_pro`, 2K). Cada imagen costó 2 créditos.
- **Prompt:** el que arma `tools/imagegen.py prompt`: estilo de `estilo-ia.json`, la escena de la receta, luz, composición y "sin texto". La escena del T-Rex:
  - `creature_desc`: "a GIANT cartoon T-Rex (bright lime green, chunky toy-like shapes, cute but scary)"
  - `prize_desc`: "a huge glowing golden egg covered in sparkles"
  - `world_desc`: "a sunny, colorful Roblox world with a flat bright-green baseplate ground, blocky low-poly trees and a red-and-white player base in the background"
- **Con referencia:** el render del león se subió como `image_references`. El prompt pedía mantener su diseño exacto (cuerpo de bloque, melena naranja, cara amarilla, ojos redondos, colores). La IA lo respetó en la miniatura y en el ícono.
- **Textos:**
  ```bash
  python tools/thumbs.py compose skills/_shared/vitrina/recetas/robo-tension.json --base trex.png \
    --set "name=GOLDEN EGG" --set 'value=$89,121/s' --at name=0.6,0.09 --at value=0.6,0.2 \
    --at you=0.89,0.11 --at you_arrow=0.88,0.19,0.8,0.28 --at alert=0.06,0.2
  python tools/thumbs.py compose skills/_shared/vitrina/recetas/rareza-secret.json --base leon.png \
    --set "odds=1 in 1,000,000" --set rarity=SECRET --at odds=0.7,0.08 --at rarity=0.3,0.07
  ```

## Lo que se aprendió

- **GPT Image 2.5 con la API (2026-11-02):** las 2 variantes del dragón salieron listas para usar: avatar con manos de bloque, espacio libre arriba para el texto, saturación de hit y ninguna letra dibujada. Comando:
  ```bash
  python tools/imagegen.py generate skills/_shared/vitrina/recetas/robo-tension.json \
    --set "creature_desc=a GIANT cartoon dragon (bright purple with a lime-green belly, chunky toy-like shapes, cute but scary, tiny wings)" \
    --set "prize_desc=a huge glowing rainbow egg covered in sparkles and little stars" \
    --set "world_desc=a sunny, very saturated Roblox world with a flat bright-green baseplate ground, blocky low-poly trees, a blue sky with puffy clouds and colorful player bases in the background" \
    --quality high --n 2 --out <carpeta>
  python tools/thumbs.py compose skills/_shared/vitrina/recetas/robo-tension.json --base <variante>.png \
    --set "name=SECRET EGG" --set 'value=$1,000,000/s' --at name=0.7,0.08 --at value=0.7,0.19 \
    --at you=0.93,0.33 --at you_arrow=0.92,0.41,0.84,0.47 --at alert=0.07,0.23 --out final.png
  ```

- **El modelo:** con el plan Plus se comparó GPT Image 2.5 (el de ChatGPT) en las recetas. Salió un poco más nítido y saturado y no dibujó letras; Nano Banana Pro puso letras en las teclas de `mas-uno`. Desde entonces GPT Image 2.5 va primero (`vitrina-hits.md` §6).
- **La composición:** la IA no siempre deja libre el cuarto de arriba. Por eso los textos se acomodan con `--at` mirando cada imagen.
- **El color:** la del león salió más pastel (saturación 114 contra 160 de los hits). Si se publica, subir `final.grade` o pedir "very saturated" en `world_desc`.
- **Las señales de IA:** el avatar del león tiene manos con dedos. Los avatares de Roblox tienen manos de bloque: al elegir, se descarta o se regenera (`vitrina-hits.md` §6, paso 3).
