---
name: roblox-game-feel
description: Le da "jugo" a un juego. Cada acción responde al instante con sonido y animación, las ganancias se ven subir y lo raro se celebra en grande y se anuncia a todo el servidor, sin molestar (respeta Low Graphics, con sonidos que no cansan y sacudidas cortas). Usar al crear un momento o un bloque nuevo, en el pase de pulido antes de publicar, o cuando el usuario dice que el juego "se siente vacío", "aburrido" o "sin dopamina".
---

# roblox-game-feel

## Objetivo
Que cada segundo se sienta bien, como en los hits (`skills/_shared/como-son-nuestros-juegos.md`, retención y dopamina):
- **Respuesta inmediata:** toda acción responde en menos de 0,1 s con sonido y animación.
- **Ganancias visibles:** las monedas vuelan al contador, los números suben contando y aparece "+$1.2K" sobre la cosa.
- **Lo raro se celebra:** sacudida, destello, confeti, voz, y el servidor lo anuncia a todos.
- **Nada molesta:** sonidos con variación y espera, sacudidas cortas, menos partículas con Low Graphics.

## Cuándo usarlo
- Al crear un momento nuevo (un bloque, una mecánica, una compra): elegir su nivel en la escalera de abajo.
- En el pase de pulido antes de publicar (`roblox-qa-performance`): recorrer `references/momentos.md` y jugar en el emulador de teléfono.
- Cuando el usuario dice que el juego se siente vacío o aburrido.

**Lo llaman:** `roblox-game-kits` (bloques y momentos nuevos), `roblox-ui-designer`, `roblox-qa-performance`, el usuario.
**Llama a:** `roblox-ui-designer` (ventanas y popups) y `roblox-security` (el premio lo decide el servidor, nunca el efecto).

## La escalera (de menos a más)

| Nivel | Cuándo | Sonido (`AudioConfig.SOUNDS`) | Pantalla | Mundo y cámara |
|---|---|---|---|---|
| 1. Toque | Botón, paso, golpe a la pila | `Click`, `Pickup` (con variación de tono) | `Juice.pop` del botón | — |
| 2. Ganancia | Cobrar, vender, comprar, depositar | `Coin`, `Cash`, `CoinsBurst`, `Purchase` | Aviso (`KitUi.notify`) y monedas que vuelan al contador (`KitUi.coinsTo`) | `Effects.floatingText` "+$X" |
| 3. Logro | Nivel, mejora, zona abierta, misión, nuevo en el índice | `LevelUp`, `Reward` | Popup (`Bus "ShowReward"`: rayos, confeti y entrada con rebote) | `Effects.worldBurst` "sparkle" |
| 4. Celebración | Legendary o más, Secret, renacer, jackpot, victoria | `Legendary`, `Rebirth`, `Victory` y voz (`Sound.voice`) | Popup con título arcoíris, `Effects.confetti` y `Juice.flash` | `Effects.worldBurst` "rare", `Juice.cameraShake` y `Juice.fovPunch`; anuncio a todo el servidor desde `units.announceFrom` |
| Error | Falta plata, lejos, lleno | `Error` | `KitUi.error(código)`: aviso en inglés, sin repetir en 1,2 s; `Juice.shake` del botón | — |

## Flujo
1. **El servidor decide.** El servidor manda el momento con `KitFx.send(player, "<Nombre>", datos)`. Nunca se muestra un premio que el servidor no dio; el toque sí responde al instante en el cliente (sonido y animación del botón).
2. **El cliente escucha** con `Bus.on("Kit:<Nombre>")` en `client/Kits/<Bloque>.luau`.
3. **Elegir el nivel** en la escalera y usar las piezas:
   - `KitUi.notify`, `KitUi.toast` y `KitUi.announce` (popup si es nuevo o desde Epic; si no, aviso corto);
   - `KitUi.showUnit`, `KitUi.error` y `KitUi.coinsTo`;
   - `UI/Juice` (`pop`, `bounceIn`, `pulse`, `wiggle`, `shake`, `countUp`, `rainbow`, `shine`, `flash`, `flyTo`, `cameraShake` y `fovPunch`);
   - `UI/Effects` (`burst`, `rays`, `confetti`, `worldBurst`, `floatingText` y `highlight`);
   - `UI/Sound` (`play`, `voice`, `playMusic`).
4. **Sonido nuevo:**
   - agregarlo a `AudioConfig.SOUNDS`, con respaldo de la biblioteca de Roblox (`id`), volumen, variación de tono y `cooldown` si se repite seguido;
   - la toma propia se elige de `assets/audio/hit-sfx` y se sube (`tools/roblox_upload.py`).
5. **Probar en el emulador de teléfono**, con y sin Low Graphics (Ajustes): que se vea, que se escuche y que no tape la UI.

## Reglas
- **El efecto celebra, el servidor da.** Primero el resultado del servidor y después la fiesta (`roblox-security`).
- **Sin urgencia falsa:** los efectos celebran lo conseguido; no presionan para comprar (nada de temblores ni relojes sobre una oferta). Reglas oficiales: `roblox-monetization`.
- **Medida:**
  - sacudidas de cámara de 0,5 s como mucho;
  - un popup grande por logro y nada que se repita cada frame;
  - `cooldown` en los sonidos que llegan seguidos (monedas, pasos).
- **Low Graphics:** con "Low Graphics" (Ajustes), `Effects` saca un tercio de las partículas (`Effects.setLowGraphics`, conectado en `Main.client.luau`) y las mascotas de otros no se dibujan.
- **Música:**
  - volumen 0,25 (`AudioConfig.MUSIC_VOLUME`), así no tapa los efectos;
  - ambiente por zona o evento con `Sound.playMusic`.
- **Textos:** los de los avisos van en inglés (`UiText`) y sin texto dentro de imágenes.
- **Voces:** las anunciadoras ("LEGENDARY!", "REBIRTH!") son de `assets/audio/hit-voices`. Sin subir, no suenan y el efecto alcanza.

## Checklist
- [ ] Cada acción del jugador tiene sonido y animación.
- [ ] Cada ganancia muestra el número que sube o la plata que vuela al contador.
- [ ] Las rarezas altas tienen celebración, y anuncio desde `announceFrom`.
- [ ] Cada error dice qué falta, en inglés, y ofrece la salida (la tienda si falta plata que se compra).
- [ ] Probado en teléfono con y sin Low Graphics, sin caída de FPS en los momentos grandes.
- [ ] `references/momentos.md` al día con cada momento nuevo.

## Límites
- No reemplaza las animaciones de personajes (Animation Editor) ni los modelos con efectos propios: esos se hacen en Studio o en Blender.
- Las texturas de partículas propias (`assets/vfx/hit`, `tools/vfx_textures.py`) se ven recién subidas (`AssetIds.vfx`). Antes se usan las de Roblox.
