# Imágenes de la tienda (Game Passes y Developer Products)

Cada pase y cada producto lleva una imagen en el Creator Dashboard: Roblox la muestra en la ventana de compra y en la pestaña Store de la página del juego. En los hits es un objeto 3D brillante sobre un degradé de color con rayos, y a veces una etiqueta corta ("2X", "VIP", "+4").

| Archivo | Qué es |
|---|---|
| `hoja.jpg` | Las 27 de `assets/ui/store-art` (2026-11-02) |
| `recetas/*.json` | Las hojas de 9 (`kind: artset`): cada cuadro con su objeto, su color y su etiqueta |

Cuál imagen va con cada pase o producto de `ShopConfig`: campo `uses` de `assets/ui/store-art/manifest.json`.

## Hacer imágenes nuevas

1. **Receta:** copiar una de `recetas/` y cambiar `names`, `items` (`icon` = un ícono de `assets/ui/hud-icons` o `pet-icons`, `color` en hex, `label`) y la lista del prompt, en inglés, en el mismo orden y sin paréntesis dentro de las descripciones. Siempre 9 por hoja.
2. **Boceto:** `python tools/storeart.py base <receta> --out base.png` (degradé del color con el ícono grande).
3. **IA:** `python tools/imagegen.py generate <receta> --ref base.png --quality high --n 1 --out <carpeta>` (clave `OPENAI_API_KEY`; USD 0,09 la hoja de 9).
4. **Cortar y etiquetar:** `python tools/storeart.py finish <receta> --sheet <hoja>.png --out assets/ui/store-art`. Corta los 9 cuadros, redondea las esquinas y estampa la etiqueta abajo al centro (Roblox recorta los pases en círculo).
5. **Revisar:** que no haya letras dibujadas por la IA, que el objeto se lea a 100 px y que el borde no traiga blanco. Si un cuadro sale flojo, se regenera la hoja y se elige.
6. **Al repo:** sumarlas a `items` del manifest, subir `count` ahí y en `assets/index.json`, y `python assets/catalog.py validate`.

## Reglas

- Etiquetas: números, símbolos o como mucho una palabra en inglés simple ("VIP", "AUTO"): las imágenes no se traducen.
- Nada de urgencia falsa ni de promesas que el producto no cumple: la imagen muestra lo que da.
- La referencia es solo nuestra (íconos propios y bocetos de `storeart.py`).
