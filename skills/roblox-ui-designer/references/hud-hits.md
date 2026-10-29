# HUD y UI de los hits (2026-10-29)

Qué tienen en común el HUD, las ventanas y los íconos de los juegos que más juegan y más ganan hoy, por qué funciona, qué no puede faltar y cómo lo replica nuestro kit (`template/src/shared/UIKit.luau`). Es la base de `roblox-ui-designer`: antes de diseñar una pantalla, mirar la muestra y las capturas de `hud-hits/`.

- **Muestra del kit:** `hud-hits/muestra-kit.jpg` (HUD en dos variantes, tienda e índice). Es el modelo base: cada juego lo sube de nivel con su tema, sus mascotas y más efectos.
- **Capturas de los hits:** `hud-hits/*.jpg`. Son solo para mirar: nunca como asset ni como referencia para la IA (el estilo se copia, el arte no; `skills/_shared/como-son-nuestros-juegos.md` §2). Salen en español porque Roblox traduce solo la UI de esos juegos: confirma que conviene escribir en inglés con `AutoLocalize`.

## Fuentes

- **Charts del 2026-10-29** (`python tools/roblox_research.py charts`), jugando en ese momento:

  | Juego | Jugando | Notas |
  |---|---|---|
  | Steal An Egg | 974k | #1 de Roblox y #4 en ganancias |
  | Steal a Brainrot | 227k | |
  | Adopt Me | 198k | |
  | 99 Nights in the Forest | 186k | |
  | Break and Steal an Egg | 84k | |
  | Pet Simulator 99 | 74k | |
  | Anime Dice | 69k | 99% de me gusta |
  | Fish It | 68k | |
  | Throw Food For Animals | 52k | |
  | +1 Speed Keyboard Escape | 46k | |
  | Tap Simulator REBORN | 40k | #12 en ganancias |
  | Ride a Dino | 17k | 706k favoritos en 2 meses |
  | Chicken Farm | 2,6k | #1 en "Top Rated": 99% y 131 M de visitas |

- **Capturas del equipo:** Steal An Egg, Anime Dice, Fish It, PS99, Throw Food For Animals y +1 Speed.
- **Fotogramas de gameplay de YouTube:** 12 juegos el 2026-10-29, más Chicken Farm y Ride a Dino.
- **Documentación de Roblox:** creator-docs, revisada el 2026-10-29: ScreenInsets, GuiService.TopbarInset, ImageLabel, regional-pricing y price-optimization.

## Lo que tienen en común y por qué funciona

| Zona | Qué va | Visto en | Por qué |
|---|---|---|---|
| Arriba al centro | El objetivo de ahora en una línea ("Steal an egg!"), sobre una franja oscura translúcida. Debajo o arriba, un aviso en amarillo o la barra de un evento | Steal An Egg, Anime Dice, Chicken Farm ("Egg Multiplier 1.5x, updating in 20s") | El jugador nuevo siempre sabe qué hacer: es lo que decide si se va antes de los 60 y 180 s que mide el algoritmo |
| Barra de Roblox, a la derecha | Botones con el mismo estilo que los de Roblox ("Daily", "Claim", "Quests") con globito rojo, y el engranaje | Anime Dice, Fish It, +1 Speed | Recuerdan premios sin tapar el juego. Van con `ScreenInsets = TopbarSafeInsets` |
| Izquierda | De 2 a 6 botones de menú grandes, cada uno de un color fijo: Shop verde o arcoíris, Index celeste, Rebirth rosa, Trade violeta | Steal An Egg (anchos), Anime Dice y +1 Speed (cuadrados), Steal a Brainrot (chicos) | Los chicos encuentran la tienda primero y recuerdan el color. Pocos y grandes: nunca una grilla de 9 iguales |
| Abajo a la izquierda | La plata enorme en verde, sin fondo, con ícono 3D de billetes. Arriba, la estadística del juego (velocidad, fuerza, agarre) con "+" para comprar. Debajo, "Friend Boost +10%" con "+" para invitar | Todos | El número que sube es la dopamina del juego. Invitar da jugadores con amigos, que el algoritmo premia |
| Derecha | Ofertas flotando sobre rayos que giran: VIP, 2x Cash, giro del premio mayor, con "OP!" inclinado y el precio en Robux. O una columna de botones cuadrados (huevo, mascotas, evento) | Anime Dice, Steal An Egg, +1 Speed | La monetización se ve todo el tiempo sin interrumpir. La primera compra es barata (45 a 139 R$) |
| Abajo a la derecha | Relojes de evento (noche, Halloween), impulsos activos con su tiempo, suerte "x1", "Invite friends! FREE reward" | Steal An Egg, Steal a Brainrot, Anime Dice, PS99, Ride a Dino | Razones reales para quedarse y volver. No es urgencia falsa: el evento existe |
| Abajo al centro | La barra de herramientas de Roblox, una fila de íconos grandes (PS99) o la acción del momento ("Drop", "Auto Open", canasta "Eggs 15") | Steal An Egg, PS99, Chicken Farm | La acción principal al alcance del pulgar |
| En el mundo | Carteles gigantes ("EGG SHOP", "SELL DINOS"), flechas rojas en el piso hacia el objetivo, carteles flotantes sobre cada mascota (nombre, rareza, $/s, "Required ⚡ 3.7M"), "+12/step", "Collect $X", "Free Spin in 2m 10s", "Free money every 10 minutes! Claim now!" | Todos | La información vive donde se usa y la pantalla queda limpia. Las flechas enseñan sin texto, en cualquier idioma |

Al abrir una ventana, el mundo se desenfoca (`BlurEffect`) y el HUD sigue a la vista.

## Lo que no puede faltar

- [ ] Objetivo de una línea arriba al centro, que cambia con el progreso.
- [ ] Menú de pocos botones grandes con color por función, y globito de aviso.
- [ ] Plata enorme abajo a la izquierda, sin fondo, con ícono 3D, y "Friend Boost" con "+".
- [ ] Al menos dos ofertas flotando a la derecha (una barata y el VIP), con precio leído en vivo.
- [ ] Un reloj de evento o de premio gratis a la vista.
- [ ] Botones propios en la barra de Roblox (Daily o Claim) con globito.
- [ ] Flechas en el piso hasta el primer objetivo, y carteles en el mundo para lo que se compra o se junta.
- [ ] Tienda en una sola lista con oferta destacada, probabilidades, regalo y ancla.
- [ ] Índice con siluetas, probabilidad, progreso por zona y premio.
- [ ] Nada encimado ni pegado al borde. Todo se tiene que leer en un teléfono acostado.

## Material visual

- **Contornos:** oscuros y gruesos en todo, bordes y texto.
  - Botones: unos 4 px a 1080p.
  - Ventanas: 6 px.
  - Texto: de 3 a 8 px según el tamaño.
  - El color es casi negro azulado (`UIKit.STROKE_COLOR`).
- **Botones:**
  - Color plano saturado, con un bisel claro por dentro, un labio oscuro abajo y una textura suave (studs o damero).
  - Esquinas de 12 a 22 px.
  - El menú nunca va en píldoras.
- **Ventanas:**
  - Cabecera de color con franjas diagonales de brillo.
  - Título a la izquierda, con un ícono que se sale del marco.
  - X roja cuadrada en la esquina.
  - Cuerpo gris carbón con studs.
  - Secciones con el título centrado entre dos líneas.
  - PS99 es la excepción: cuerpo blanco y mascota asomando.
- **Letra:**
  - Fredoka One para títulos, botones y números.
  - La barra de Roblox usa Builder Sans.
  - Nada de cursiva: Roblox no inclina Fredoka.
- **Color por función:**
  - Verde: comprar y plata.
  - Celeste: índice.
  - Rosa: renacer.
  - Violeta: regalo e intercambio.
  - Rojo: cerrar u oferta especial.
  - Amarillo y naranja: premio y evento.
- **Texturas** (`assets/ui/hit-skin`, `tools/ui_textures.py`):
  - studs, damero y lunares en mosaico;
  - franjas de brillo para las cabeceras;
  - rayos de sol detrás de ofertas y premios;
  - destellos;
  - sombra de 9 cortes;
  - flechas para el `Beam` del camino.

## Medidas de referencia (1920×1080)

Todo va en escala respecto del alto de pantalla, con 44 px como mínimo para el dedo.

| Pieza | Medida |
|---|---|
| Botón ancho del menú | 230 a 262 × 80 px, ícono de 66 px, texto de 42 px, 16 px entre botones, 24 px del borde |
| Botón cuadrado | 142 × 136 px, ícono de 128 px que se sale, etiqueta de 30 px montada en el borde de abajo |
| Plata | 84 a 116 px de alto, ícono de 96 a 110 px; "Friend Boost" de 38 a 42 px |
| Objetivo | 58 px |
| Oferta flotante | 230 × 230 px con rayos, ícono de 150 px, precio de 40 px; 30 px de aire entre ofertas |
| Ventana grande | unos 1240 × 830 a 900 px, cabecera de 104 px, X de 92 px montada en la esquina; no tapa la plata |
| Tarjeta del índice | 168 × 184 px; fila de probabilidades de 124 × 138 px |

## Tienda

Así la arman Steal An Egg, Anime Dice, Throw Food For Animals, PS99 y +1 Speed:

- **Una sola lista con secciones, sin pestañas:** destacado, giros o paquetes, impulsos y pases.
- **Oferta destacada:**
  - Arte temático de fondo, "NEW!", título y "Limited time!" (solo si lo es).
  - Reloj y el producto 3D sobre rayos.
  - La probabilidad de cada resultado: es obligatoria en los aleatorios pagos.
  - Cantidades (1, 3, 10 y 50) con el precio en Robux, botón de regalo al lado de cada compra y precio tachado de ancla.
- **Etiquetas inclinadas** ("BEST VALUE!", "OP!") y "Watch ad!" en el paquete más barato, solo donde se permiten anuncios con premio.
- **Impulsos:**
  - Personal en 10 min, 30 min y 1 hora.
  - Para todo el servidor ("1x → 2x, 15 minutes, boosts everyone").
  - Membresía mensual.
- **Paquetes de plata que crecen con el progreso** (Chicken Farm): tres botones a la izquierda del HUD, de +875$ al principio a +376Qd$ más adelante.
- **Multiplicador permanente en escalones** (Chicken Farm): "PERMANENT! 2x Cash", después 4x, 7x, 20x, 50x, 75x y 100x, cada uno más caro.
- **Pases de comodidad muy baratos** (Chicken Farm): "Auto Collect" a 29 R$ y "Auto Collect Eggs" a 79 R$.
- **Precios siempre leídos en vivo:** Roblox los ajusta por región (hasta 70% menos) y con pruebas de precio. Por eso en las capturas el VIP de Anime Dice sale 139 y no 249. `ShopController` ya los lee con `GetProductInfoAsync`.

## Índice

Así lo arman Steal An Egg y Anime Dice:

- **Zonas a la izquierda:** imagen del mundo, con candado si falta desbloquearla.
- **Variantes arriba** (Normal, Golden, Rainbow, o Huge y Titanic) y mutaciones al costado.
- **Tarjetas con degradé de rareza:**
  - Lo encontrado se muestra con su modelo.
  - Lo que falta va en silueta negra con "???". Es un `ViewportFrame` sin luz, y no hace falta dibujar nada.
  - Cada tarjeta lleva la probabilidad "1 in X".
- **Barra de progreso de la zona** y premio por completarla, con "CLAIM".
- **Total abajo:** "Unlocked: 3/112".

## Íconos

Hay dos familias, y los hits usan las dos:

1. **Objetos 3D** (plata, gemas, regalo, huevos, corona, trébol, botones grandes): 3D de juguete con sombreado de dibujo, brillos duros y contorno oscuro grueso.
   - Están en `assets/ui/hud-icons/` (36).
   - Se hacen con base 3D propia más terminación con IA (`skills/_shared/iconos/README.md`).
2. **Íconos planos** (carrito, libro, engranaje, calendario): blancos con contorno, para botones chicos como los de Steal An Egg, y blancos lisos para la barra de Roblox.
   - Están en `assets/ui/icons-flat/` (Material Symbols, Apache 2.0).

Lo que no: emoji 3D (Fluent), clip-art plano con degradé (`hit-icons`, la primera tanda) ni renders de plástico sin terminar.

## Juegos analizados

- **Steal An Egg:**
  - Botones Shop (verde) e Index (celeste) anchos, con ícono plano y texto.
  - Velocidad y plata abajo a la izquierda, y una columna de botones cuadrados a la derecha (huevo, mascotas, evento).
  - Objetivo arriba, reloj de la noche abajo a la derecha, flechas rojas en el piso y cartel gigante de la tienda.
  - Tienda e índice como los descritos arriba.
- **Break and Steal an Egg:** el mismo HUD que Steal An Egg, más:
  - "RUN!" en rojo mientras robás y "Drop" abajo;
  - eventos con reloj ("The Phantom Express has arrived!").
- **Steal a Brainrot:** HUD mínimo de botones chicos con texto, plata verde con "Friend Boost" y casi todo en el mundo ("COLLECT", "CASH MULTI x18", "Free Spin in 1m 48s"). Abajo a la derecha, los impulsos activos con su reloj.
- **Anime Dice:**
  - Botones cuadrados con ícono 3D (Shop arcoíris, Rebirth, Index), plata gigante y "Friend Boost" con "+".
  - Ofertas "OP!" flotando (VIP, giro del premio mayor), "Daily" y "Claim" en la barra y suerte "x1".
  - Índice con "1 in X", variantes Huge y Titanic, y mutaciones.
- **Fish It:**
  - Misiones a la derecha y la suerte de amigos abajo.
  - Evento de Halloween con marco temático (calabazas y calaveras), "SKIP ALL", moneda del evento y pase de batalla.
- **PS99:**
  - Ventanas blancas con el ícono y la X montados en las esquinas.
  - Paquete de inicio con mascota asomando y cadena de ofertas (gratis → pago → gratis) con reloj.
  - Fila de íconos 3D grandes abajo y "Invite friends! FREE reward".
- **Throw Food For Animals:**
  - Fuerza (brazo) y plata abajo a la izquierda.
  - Tienda naranja con "Halloween Limited Edition", "BEST VALUE!", "900% of your best animal" y "GIFT!".
- **+1 Speed Keyboard Escape:**
  - HUD cargado: 6 botones cuadrados con studs, velocidad gigante abajo al centro con barra de nivel y botones para comprar velocidad (+150K, +1M, +10M).
  - Ofertas anchas a la derecha (Shop "NEW!", "2x Speed only 3 R$", Trade).
  - Tienda de impulsos con "Watch ad!".
- **Tap Simulator REBORN:**
  - Shop y Trade cuadrados a la izquierda.
  - Rebirths, monedas y gemas abajo, con lo que se gana por segundo.
  - Botón grande de tocar abajo al centro.
  - Huevo con la probabilidad de cada mascota ("46.33%", "1 in 2,000") y "Auto Open!".
- **Chicken Farm (tycoon de fusión):**
  - **El ciclo:**
    1. Se compran gallinas en tandas pisando carteles en el piso (Buy 1, 5, 25 y 100).
    2. Ponen huevos.
    3. Se llevan a "Deposit Eggs" y aparecen números flotando ("Deposited 63 Eggs!", "+1,200 [x2]!").
    4. Se fusionan para subir de nivel (Basic → Duck → Dirt → Bee → … → Robot, nivel 16). Cada nivel tiene su cartel gigante en el nido.
  - **El HUD:**
    - "Home" arriba.
    - "Your chickens lay 3.48M/day offline!".
    - Multiplicador permanente y paquetes de plata a la izquierda.
    - Canasta "Eggs" con el contador abajo al centro.
    - "Total Chickens" abajo a la derecha.
    - Index, Settings y Rebirth en botones chicos a la derecha.
  - **En el mundo:** "Finish Now 19 R$" para saltar la espera, "Collect Cash", tablero "Selling Eggs 571Sx (1.02Sx per second)" y bloque de la suerte.
- **Ride a Dino (corrida y captura):**
  - **El ciclo:**
    1. Saltás sobre dinosaurios en estampida, que en el mundo muestran rareza, tamaño ("TINY", "GIANT", "SILVER GIANT") y "Required ⚡ 3.7M".
    2. Juntás capturas ("9 SECURED").
    3. Al terminar sale "GREAT RUN! You caught 9 dinos!".
    4. Si caés, "Keep riding? Revive FREE".
  - **Progreso:** entrenás el agarre en máquinas ("+148") y las etapas piden fuerza ("Recommended Strength 3.8M. Train more to outrun this stage's parent").
  - **El HUD:**
    - Shop e Index anchos como Steal An Egg.
    - Agarre y plata con "+" abajo a la izquierda.
    - Barra de dinos capturados abajo al centro.
    - Habilidades consumibles con tecla a la derecha (Flame, Magnet, Stride, Ninja, con contador).
    - Relojes de evento y de la noche abajo a la derecha.
  - **Además:**
    - Corrales con nivel que dan $/s, "Equip Best" y máquina de fusión.
    - Auras y tienda de evento ("SPOOKY SHOP") con su moneda y un panel "GOAL".

## Lo que hacíamos mal (no repetir)

- Doce botones iguales en grilla 3×3.
- La plata en píldoras arriba.
- Tres barras y relojes apilados arriba al centro.
- La tienda con pestañas, textos largos y "R$" escrito en vez del ícono de Robux.
- El título de la ventana flotando afuera.
- Íconos emoji o clip-art.
- Nada en el mundo.
- La muestra sobre un fondo hecho con IA (ahora la escena es 3D con piezas de Kenney).
