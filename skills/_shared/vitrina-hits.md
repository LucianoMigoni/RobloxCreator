# La vitrina de un hit: ícono, miniaturas, título, descripción y video

Para que la gente haga clic y entre. Investigado el 2026-10-28 con:
- Las imágenes oficiales de 15 hits: 15 íconos y 76 miniaturas, bajadas con `tools/roblox_research.py images`.
- Los títulos y descripciones de 23 juegos de los Charts.
- La documentación oficial (`/production/publishing/thumbnails`, `/experience-icons` y `/discovery`).
- Los anuncios del DevForum de 2026.

Lo usan `roblox-publishing` (fase 8) y `roblox-campaigns` (creatividades). Herramientas: `tools/imagegen.py` (la imagen, con IA y referencias del juego), `tools/thumbs.py` (textos, revisión y hoja de contacto) y `tools/render3d/` (referencias desde los modelos).

**Método desde el 2026-10-29 (§6):** la imagen la hace la IA con las referencias del juego y el texto se pone encima. El método anterior armaba emojis 3D sobre degradés: al lado de los hits parecían stickers. Ejemplos de antes y después en `skills/_shared/vitrina/ejemplos/`.

## 1. Por qué importa

- Home muestra el juego como **ícono o miniatura** con su título. La primera señal del algoritmo es el **play-through rate**: qué parte de los que lo ven entra a jugar (`algoritmo-descubrimiento.md`).
- **Sin miniatura propia no hay impresiones de Home** (desde el 2026-10-19).
- **Personalización de miniaturas:** con 2 a 5 activas, Roblox muestra a cada grupo la que mejor le funciona. En la prueba oficial dio **+8,5 % de jugadas que cuentan en promedio y hasta +50 %**.
- **En los anuncios, la miniatura decide el CTR:**
  - 2–2,5 % es lo normal, 3 % es bueno y 4 % es excelente.
  - Un desarrollador pasó de 1,8 % a 3,6 % después de probar unas 50 (DevForum, 2026-10-27).
- **Video de gameplay en Home:**
  - Superstar Baseball: +30 % de jugadas desde RFY.
  - Notoriety: +41 % de jugadas desde RFY (prueba oficial de junio de 2026).

## 2. Reglas oficiales (no negociables)

| | Ícono | Miniatura | Video |
|---|---|---|---|
| Formato | Cuadrado, **512×512** o más; se ve también a **150×150** | **16:9, ideal 1920×1080**; en Home menos de 3 MB | Auténtico, gameplay real; 3 subidas por mes (los rechazados cuentan) |
| Cantidad | Uno por idioma | Hasta 10 en la página; 2 a 5 activas para la personalización | Aparece primero en la página y puede salir en Home |
| Prohibido | Imagen ambigua o que no es del juego | Nada esencial en el **20 % de abajo** (lo tapa el contador de jugadores); imágenes de otro juego | Voz, narración, música con letra, imágenes reales, gráficos mejores que el juego, textos de oferta ("50% off", "Free UGC!") |

**Metadata (`/discovery`):**
- Nada que implique premios en dinero ("Robux! Play now!" pierde exposición).
- Nada que no coincida con el juego, y nada repetido de otros juegos (los "no únicos" se recomiendan menos).
- Seguir una tendencia está bien **con un giro propio** en el título, las imágenes y el juego.

## 3. Qué hacen los hits (lo que copiamos)

### Íconos

- **Un sujeto gigante, centrado:**
  - El objeto de deseo: huevo brillante, mascota, gema, pez gigante.
  - O el personaje con la cara exagerada: miedo, risa, determinación.
  - Ocupa del 60 al 75 % del cuadro.
- **Brillo, borde y luz de contorno**, para separarlo de un fondo saturado y limpio: degradé, rayos o cielo.
- **Colores:** saturación mediana de **169** (canal S de 0 a 255) en los íconos medidos. Complementarios: violeta y verde, naranja y azul.
- **Texto mínimo:**
  - Un número que vende ("1 in 9,342,584", "$997,151,167/s"), "+1" o una palabra ("CHAPTER 2", "GROW OFFLINE").
  - Letras gruesas con contorno oscuro y degradé arcoíris.
- **Temporada:** calabazas en octubre, nieve en diciembre. En octubre de 2026 varios usan el marco rojo de *The Hollow*, el evento de Halloween de la plataforma. Son juegos del evento: no usar logos ni marcos de eventos de Roblox sin estar invitado.

### Miniaturas

- **Una escena con tensión o deseo**, entendible en un segundo:
  - Robarle el huevo al T-Rex dormido ("zzz", "!!").
  - Escapar de la serpiente.
  - Mostrar la criatura SECRET junto a su ganancia por segundo.
- **El jugador se ve a sí mismo:** avatar clásico de Roblox, **flecha roja curva con "YOU!"** apuntándolo.
- **Números enormes arriba**, blancos con contorno negro ("$997,151,167/s"), y la rareza en arcoíris ("SECRET", "HALLOWEEN") bajo el nombre.
- **Serie:** 4 a 10 miniaturas con la misma composición y distinta criatura o bioma. Así arman la personalización: cada una es una hipótesis.
- Saturación mediana de **160** y contraste (desvío de luminancia) de **55** en las 76 medidas. `tools/thumbs.py check` compara contra esos valores.

### Cómo están hechas (lo que hay que igualar)

Son **escenas 3D de Roblox**, no dibujos planos ni stickers:
- **Steal a Brainrot:** escenas armadas con el mapa real (bases, alfombras, pasto con studs), avatares posados con la luz del juego y el número gigante arriba.
- **Fish It!:** GFX de Blender:
  - el avatar con la cara exagerada (llorando) tira de la caña;
  - una criatura gigante con brillo sale del agua pintada.
  - Toda la serie repite la composición y cambia la criatura.
- **Steal An Egg (ícono):** el avatar levanta el huevo del evento y detrás asoma la criatura gigante.

Lo que tienen en común:
- el avatar clásico con una **cara exagerada** (miedo, llanto, sorpresa);
- **acción en curso** (robar, pescar, levantar);
- el mundo del juego de fondo con desenfoque;
- luz de contorno blanca y brillo en el objeto deseado;
- cámara baja para que lo grande se vea gigante.

Las hacen artistas de GFX (render en Blender de los avatares y modelos del juego, retoque en Photoshop) que cobran de 500 a más de 50 000 Robux por miniatura. Hoy el mismo resultado sale con IA usando referencias del juego (§6).

### Títulos (23 juegos de los Charts, 2026-10-28)

- **Etiqueta al principio con emoji**, de temporada o update: `[🎃]`, `[🎃UPD]`, `[💀]`, `[👻]`, `[IMPOSSIBLE 😈]`, `🎉 [PSX]`. A veces otro emoji al final: "Grow a Garden 🌶️", "Fish It! 🐟".
- **La fórmula en el nombre:**
  - Verbo + objeto: "Steal An Egg", "Catch And Tame!", "Dig & Clean", "Cook the Chicken (by slapping it)".
  - Gancho numérico: "+1 Speed Keyboard Escape", "+1 Upgrade Per Kill".
- Corto: de 2 a 5 palabras sin contar la etiqueta. El nombre base no cambia; cambia la etiqueta con cada update.

### Descripciones

Estructura repetida en casi todos:

```
🥚 Welcome to <Name>!                       ← o la novedad del update en mayúsculas

How to Play:
🥚 <verbo> <qué>                            ← 4 a 7 líneas, emoji + verbo, el loop en orden
🐣 <verbo> <qué>
💰 <verbo> <qué>
⬆️ <verbo> <qué>
✨ Discover rarer <cosas>, sizes and mutations!

💵 MONEY GENERATES WHILE YOU ARE OFFLINE     ← el gancho que vende, si existe
👍 Like the game and join the group for updates!   ← sin premio por el like
🎮 Supports Desktop, Console, Mobile and Tablet
```

- **Updates:** la primera línea pasa a ser la novedad ("⚓🎃 FISHING CREWS + HALLOWEEN EXPANSION! 4 NEW SECRETS, 12 NEW FISH").
- **Números que impresionan:** "Collect from 1,000,000+ variations", "3,000+ pets".
- **Códigos:** "Use code \"release\" for a free boost".
- **El grupo:** se puede dar un premio por unirse al grupo. Por el like, no: solo se pide.
- **Lo que no copiamos:**
  - Las líneas "Tags: needle, hay, farm..." (listas de palabras sueltas).
  - "FREE" en mayúsculas al principio (parece promesa de premio).
  - Los links fuera de Roblox.

## 4. Política de texto en ícono y miniaturas

`CLAUDE.md` prohíbe texto dentro de imágenes, porque la traducción automática no lo traduce. Excepción del 2026-10-28, solo para ícono, miniaturas y creatividades de anuncios:

- **Siempre se permiten** números y símbolos: "$1,000,000/s", "x2", "+1", "1 in 9,342,584", "!!". Se leen en cualquier idioma.
- **Palabras: como mucho 3, en inglés simple** y de la jerga que los chicos de todo el mundo ya conocen ("YOU!", "SECRET", "NEW", "UPDATE", "EGG").
- **Nunca:** oraciones, instrucciones ni promesas ("FREE", "50% OFF").
- El ícono admite uno por idioma (`/experience-icons`). Si un idioma trae mucho tráfico, se le hace su versión.
- La UI del juego **sigue sin texto dentro de imágenes**.

## 5. Recetas (`skills/_shared/vitrina/recetas/`)

Cada receta es la composición de un hit en un JSON con tres partes:
- **`ia`:** la escena que se le pide a la IA, en inglés, con valores entre `{{ }}` (`creature_desc`, `world_desc`...). `tools/imagegen.py` la envuelve con el estilo de `skills/_shared/vitrina/estilo-ia.json`.
- **Textos y flechas** (`layers` de tipo `text` y `arrow`, cada uno con su `id`): el número, la rareza, "YOU!". Los pone `tools/thumbs.py` encima de la imagen de IA (`--base`), así el número queda exacto y la fuente es la misma en toda la serie.
- **Boceto** (`layers` de tipo `image`, `background`, `rays`): la composición armada con renders. Sirve como referencia de composición para la IA o para una prueba rápida sin IA.

| Receta | Para | Valores para la IA (en inglés) | Textos |
|---|---|---|---|
| `robo-tension.json` | Juegos de robar (Steal ___) | `creature_desc`, `prize_desc`, `world_desc` | `name`, `value` + YOU! |
| `numero-gigante.json` | Ganancia por segundo enorme | `creature_desc`, `world_desc` | `value`, `name`, `rarity` |
| `objeto-gigante.json` | Huevos, cofres, el pez dorado | `prize_desc`, `world_desc` | `label` |
| `rareza-secret.json` | Revelación rara / gacha | `creature_desc` | `odds`, `rarity` |
| `mas-uno.json` | "+1 por paso" | `world_desc` | `speed` + los "+1" |
| `evento-temporada.json` | Update de Halloween, Navidad o verano | `creature_desc`, `season_desc` | `label` |
| `icono-heroe.json` | Ícono 512×512 | `subject_desc`, `colors` | `top` (vacío si no lleva texto) |

El avatar sale de `estilo-ia.json`: `AVATAR` (el clásico de pelo "bacon", el que los chicos reconocen), `AVATAR_GIRL` o `AVATAR_NOOB` (`--avatar`). Variar el avatar entre miniaturas también es una hipótesis para la personalización.

## 6. Cómo se producen las imágenes

La imagen la genera la IA **a partir de referencias del juego**, y el texto se agrega después. Prueba del 2026-10-29 (`skills/_shared/vitrina/ejemplos/`):
- Con el estilo de `estilo-ia.json`, Nano Banana Pro hizo miniaturas al nivel de las de Steal a Brainrot y Fish It!.
- Con el render del león de Kenney Cube Pets como referencia, respetó su diseño exacto (melena de bloques, cara, ojos, colores) en la miniatura y en el ícono.

```bash
# 1. Referencias: render de cada modelo del juego (o captura de Studio / render de Blender)
node tools/render3d/render.cjs assets/3d/kenney/cube-pets/animal-lion.glb games/<juego>/marketing/refs/lion.png
# 2. Prompt (para ChatGPT, Gemini o Higgsfield) o generación directa con clave de API
python tools/imagegen.py prompt skills/_shared/vitrina/recetas/rareza-secret.json \
  --set "creature_desc=the lion pet from the reference, giant and glowing" --ref games/<juego>/marketing/refs/lion.png
python tools/imagegen.py generate skills/_shared/vitrina/recetas/rareza-secret.json --out games/<juego>/marketing/ia \
  --n 4 --set "creature_desc=..." --ref games/<juego>/marketing/refs/lion.png
# 3. Textos encima de la variante elegida (--at acomoda cada texto o flecha a esa imagen)
python tools/thumbs.py compose skills/_shared/vitrina/recetas/rareza-secret.json --base games/<juego>/marketing/ia/<variante>.png \
  --set "odds=1 in 1,000,000" --set rarity=SECRET --at odds=0.7,0.08 --at rarity=0.3,0.07 --out games/<juego>/marketing/thumb-secret.jpg
# 4. Revisar y elegir
python tools/thumbs.py check games/<juego>/marketing/thumb-secret.jpg --kind thumbnail --previews games/<juego>/marketing/previews
python tools/thumbs.py sheet games/<juego>/marketing/thumb-*.jpg --out games/<juego>/marketing/hoja.jpg
```

1. **Referencias del juego:**
   - Cada criatura, huevo u objeto que aparece:
     - `tools/render3d/render.cjs` desde el `.glb` (sin abrir Blender; funciona también en sesiones en la nube);
     - o un render en Blender (MCP), con luz de tres puntos y fondo transparente.
   - El escenario: una captura del mapa en Studio (`screen_capture` en playtest, cámara libre).
   - El avatar clásico lo conoce la IA. Si el juego tiene un personaje propio, va su render.
2. **Generar de 4 a 8 variantes por hipótesis** (mecánica, premio, número, temporada, amigos):

   | Camino | Cómo | Costo |
   |---|---|---|
   | API de Google | `imagegen.py generate --provider gemini` (Nano Banana Pro `gemini-3-pro-image`; más barato: `gemini-nano-banana-2.1`). Clave `GEMINI_API_KEY` | 0,134 USD por imagen 2K (0,05 con Nano Banana 2.1) |
   | API de OpenAI | `imagegen.py generate --provider openai` (`gpt-image-2.5-flare`; `-sunburst` edita con más precisión). Clave `OPENAI_API_KEY` | Por tokens: unos 0,04 USD en calidad media |
   | ChatGPT o Gemini a mano | `imagegen.py prompt`, pegar el prompt, adjuntar las referencias y pedir 16:9 o cuadrado | Incluido en la suscripción |
   | Desde Claude | Conector Higgsfield (`generate_image`, modelo `nano_banana_pro`, con las referencias subidas) o Meshy (`meshy_image_to_image`) | Higgsfield: 2 créditos por imagen; GPT Image 2.5 pide plan pago |

   Una serie de 4 hipótesis × 4 variantes son unas 16 imágenes: unos 2 USD con Nano Banana Pro.
3. **Filtro de calidad.** Se descarta la variante que tenga:
   - letras o números sueltos;
   - manos con dedos (los avatares de Roblox tienen manos de bloque);
   - un avatar con proporciones raras;
   - partes derretidas o duplicadas;
   - una criatura distinta de la referencia;
   - algo que no existe en el juego.

   La comunidad desconfía de lo que "parece IA" (DevForum, temas 4920507 y 4806311): estas son las señales que la delatan.
4. **Textos** con `thumbs.py compose ... --base` (el número exacto, la rareza, la flecha YOU!). `--at id=x,y` mueve un texto y `--at id=x0,y0,x1,y1` una flecha para que no tapen caras ni el objeto; `--hide id` saca una capa.
5. **Revisar** con `check`:
   - El ícono se tiene que entender a 150 px.
   - En el mosaico de Home, nada importante tapado abajo.
   - Saturación y contraste cerca de los hits; si la imagen salió apagada, subir `final.grade` en la receta.
6. **Hoja de contacto** con `sheet` para elegir en el PR, que es la puerta de revisión.
7. **Subir:**
   - Las miniaturas desde Creator Hub → Places → Thumbnails (pestaña Home Page para la personalización).
   - El ícono desde Places → Icon.
   - Las creatividades de anuncios a la biblioteca de Ads Manager o con la Assets API (`roblox-campaigns`).
8. **Medir:** tabla *Thumbnail Performance* de Creator Hub, o `python tools/campaigns.py thumbs --universe <id>` con la Analytics API. Se deja jugar a la personalización. **Con cada update grande se suman miniaturas nuevas** y no se tocan hasta el siguiente (guía oficial).

**Reglas de la IA:**
- **Todo lo que aparece existe en el juego.** Es regla oficial y señal del algoritmo; las referencias lo aseguran. Si la IA inventa algo (otra criatura, un arma, un lugar), la variante se descarta.
- **Nunca miniaturas de otros juegos como referencia**, ni siquiera de estilo: el estilo ya está en `estilo-ia.json`. Tampoco logos, personajes ni "brainrots" ajenos.
- **Las imágenes de Gemini llevan SynthID**, una marca de agua invisible. No se encontró una regla oficial de Roblox que obligue a declarar IA en miniaturas (revisado el 2026-10-29). Rige la de no engañar.
- **Lo generado en el plan gratis de un servicio** queda solo como prueba. Para publicar, el plan pago o la API (ver la licencia en `skills/_shared/conectores.md`).

## 7. Video de gameplay

- Mostrar **el loop real en los primeros 2 segundos:** robar, revelar o ver subir el número. Clips cortos encadenados; 30 s alcanzan.
- Se puede: cámara libre, cortes, leve corrección de color, el logo del juego, música del catálogo de Roblox **sin letra**, y textos de la propia UI.
- No se puede: voz, narración, imágenes reales, gráficos mejorados ni textos de oferta.
- Grabar en Studio a 1920×1080 en un servidor con varios jugadores de prueba, para que se vea vivo.

## 8. Checklist de la vitrina

- [ ] Imágenes hechas con referencias del juego y sin señales de IA (§6, paso 3).
- [ ] Ícono 512×512: un sujeto gigante y saturado, entendible a 150 px; texto solo número o una palabra.
- [ ] De 3 a 5 miniaturas 16:9 de 1920×1080 y menos de 3 MB, una por hipótesis, sin nada esencial abajo, activas en la personalización.
- [ ] Todo lo que muestran existe en el juego (criaturas, número, mecánica).
- [ ] Título: fórmula clara + etiqueta de temporada o update con un emoji; nombre base estable.
- [ ] Descripción: bienvenida o novedad, "How to Play" con 4 a 7 líneas de emoji + verbo, gancho, plataformas; sin listas de palabras ni premios en dinero.
- [ ] Video auténtico sin voz ni música con letra.
- [ ] `tools/thumbs.py check` sin avisos de tamaño ni proporción. Los de saturación o contraste se justifican o se arreglan.
