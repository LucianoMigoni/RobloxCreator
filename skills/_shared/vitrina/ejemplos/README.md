# Ejemplos de la vitrina: antes y después (2026-10-29)

La vara de calidad para miniaturas e íconos. Se hicieron para comparar con los hits: no son de ningún juego nuestro y **no se publican**. Se generaron en el plan gratis de Higgsfield, que es solo para pruebas.

| Archivo | Qué es |
|---|---|
| `antes-despues.jpg` | Arriba el método viejo (emojis 3D sobre degradé); abajo el nuevo |
| `despues-robo-trex.jpg` | Receta `robo-tension`, sin referencias, con textos de `thumbs.py` |
| `despues-secret-leon.jpg` | Receta `rareza-secret`, con el render del león como referencia |
| `despues-icono-leon.png` | Receta `icono-heroe`, con la misma referencia |
| `referencia-leon.png` | Render de `assets/3d/kenney/cube-pets/animal-lion.glb` con `tools/render3d/` |

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

- **El modelo:** GPT Image 2.5 (el de ChatGPT) no se pudo probar en Higgsfield: pide plan pago. Queda para comparar con clave de OpenAI.
- **La composición:** la IA no siempre deja libre el cuarto de arriba. Por eso los textos se acomodan con `--at` mirando cada imagen.
- **El color:** la del león salió más pastel (saturación 114 contra 160 de los hits). Si se publica, subir `final.grade` o pedir "very saturated" en `world_desc`.
- **Las señales de IA:** el avatar del león tiene manos con dedos. Los avatares de Roblox tienen manos de bloque: al elegir, se descarta o se regenera (`vitrina-hits.md` §6, paso 3).
