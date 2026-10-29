# La vitrina de un hit: ícono, miniaturas, título, descripción y video

Para que la gente haga clic y entre. Investigado el 2026-10-28 con:
- Las imágenes oficiales de 15 hits: 15 íconos y 76 miniaturas, bajadas con `tools/roblox_research.py images`.
- Los títulos y descripciones de 23 juegos de los Charts.
- La documentación oficial (`/production/publishing/thumbnails`, `/experience-icons` y `/discovery`).
- Los anuncios del DevForum de 2026.

Lo usan `roblox-publishing` (fase 8) y `roblox-campaigns` (creatividades). Herramienta: `tools/thumbs.py`.

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

Cada receta es un JSON por capas que arma `tools/thumbs.py`. Las partes variables van entre `{{ }}` y se completan con `--set`.

| Receta | Para | Valores |
|---|---|---|
| `robo-tension.json` | Juegos de robar (Steal ___) | `creature`, `avatar`, `hero`, `name`, `value` |
| `numero-gigante.json` | Ganancia por segundo enorme | `creature`, `avatar`, `value`, `name`, `rarity` |
| `objeto-gigante.json` | Huevos, cofres, el pez dorado | `hero`, `avatar`, `label` |
| `rareza-secret.json` | Revelación rara / gacha | `creature`, `sparkle`, `odds`, `rarity` |
| `mas-uno.json` | "+1 por paso" | `avatar`, `speed` |
| `evento-temporada.json` | Update de Halloween, Navidad o verano | `hero`, `prop`, `label` |
| `icono-heroe.json` | Ícono 512×512 | `hero`, `top` (vacío si no lleva texto) |

```bash
python tools/thumbs.py compose skills/_shared/vitrina/recetas/robo-tension.json --out games/<juego>/marketing/thumb-robo-trex.png \
  --set creature=games/<juego>/marketing/renders/trex.png --set avatar=games/<juego>/marketing/renders/avatar-run.png \
  --set hero=games/<juego>/marketing/renders/egg-gold.png --set "name=GOLDEN EGG" --set "value=\$89,121/s"
python tools/thumbs.py check games/<juego>/marketing/thumb-robo-trex.png --kind thumbnail --previews games/<juego>/marketing/previews
python tools/thumbs.py sheet games/<juego>/marketing/thumb-*.png --out games/<juego>/marketing/hoja.jpg
```

- Capas: fondo (degradé o captura desenfocada), rayos, imágenes (con brillo, borde y sombra), texto (fuentes del catálogo, relleno de color, degradé o `"rainbow"`, contorno y sombra) y flechas curvas.
- Fuentes del catálogo (OFL o Apache, uso comercial): `luckiest-guy`, `titan-one`, `lilita-one`, `bangers` y `fredoka`. Los emojis no se dibujan con estas fuentes: un emoji va como imagen (`assets/ui/fluent-emoji-3d/`).

## 6. Cómo se producen las imágenes

Las imágenes de entrada son **del juego**: así lo que promete la vitrina coincide con lo que hay adentro, que es regla oficial y señal del algoritmo.

1. **Renders** de la criatura, el objeto y el avatar con fondo transparente:
   - En **Blender** (MCP): escena con luz de tres puntos cálida y luz de contorno fuerte, cámara un poco desde abajo para que el sujeto se vea gigante, PNG con transparencia a 2048 px. `render_thumbnail_to_path` para una prueba rápida y `render_viewport_to_path` para la final.
   - En **Studio** (MCP): `screen_capture` en playtest con la cámara libre (Shift + P). Sirve para fondos reales y escenas con el mapa.
2. **El avatar:** el clásico de Roblox (el que los chicos reconocen) con pose de acción: correr cargando el premio, levantarlo, asustarse. Se posa en Studio o en Blender.
3. **Componer** con una receta. Hacer **de 3 a 5 variantes con hipótesis distintas:**
   - la mecánica (robar);
   - el premio (la criatura SECRET);
   - el número (la ganancia);
   - la temporada;
   - jugar con amigos.
4. **Revisar** con `check`:
   - El ícono se tiene que entender a 150 px.
   - En el mosaico de Home, nada importante tapado abajo.
   - Saturación y contraste cerca de los hits.
5. **Hoja de contacto** con `sheet` para elegir en el PR, que es la puerta de revisión.
6. **Subir:**
   - Las miniaturas desde Creator Hub → Places → Thumbnails (pestaña Home Page para la personalización).
   - El ícono desde Places → Icon.
   - Las creatividades de anuncios a la biblioteca de Ads Manager o con la Assets API (`roblox-campaigns`).
7. **Medir:** tabla *Thumbnail Performance* de Creator Hub, o `python tools/campaigns.py thumbs --universe <id>` con la Analytics API. Se deja jugar a la personalización. **Con cada update grande se suman miniaturas nuevas** y no se tocan hasta el siguiente (guía oficial).

**IA para imágenes:**
- Meshy (`meshy_text_to_image`) o el generador de Ads Manager sirven para **bocetos y fondos**, nunca para mostrar algo que no está en el juego.
- La comunidad de Roblox castiga lo que "parece IA": en el DevForum, a los juegos con miniaturas de IA les señalan CTR bajo y desconfianza (temas 4920507 y 4806311).
- La imagen final sale de renders y capturas del juego.

## 7. Video de gameplay

- Mostrar **el loop real en los primeros 2 segundos:** robar, revelar o ver subir el número. Clips cortos encadenados; 30 s alcanzan.
- Se puede: cámara libre, cortes, leve corrección de color, el logo del juego, música del catálogo de Roblox **sin letra**, y textos de la propia UI.
- No se puede: voz, narración, imágenes reales, gráficos mejorados ni textos de oferta.
- Grabar en Studio a 1920×1080 en un servidor con varios jugadores de prueba, para que se vea vivo.

## 8. Checklist de la vitrina

- [ ] Ícono 512×512: un sujeto gigante y saturado, entendible a 150 px; texto solo número o una palabra.
- [ ] De 3 a 5 miniaturas 16:9 de 1920×1080 y menos de 3 MB, una por hipótesis, sin nada esencial abajo, activas en la personalización.
- [ ] Todo lo que muestran existe en el juego (criaturas, número, mecánica).
- [ ] Título: fórmula clara + etiqueta de temporada o update con un emoji; nombre base estable.
- [ ] Descripción: bienvenida o novedad, "How to Play" con 4 a 7 líneas de emoji + verbo, gancho, plataformas; sin listas de palabras ni premios en dinero.
- [ ] Video auténtico sin voz ni música con letra.
- [ ] `tools/thumbs.py check` sin avisos de tamaño ni proporción. Los de saturación o contraste se justifican o se arreglan.
