# Cómo son nuestros juegos

Es la guía central del hub: qué juegos hacemos, para quién, con qué trucos y qué no hacemos nunca. Todo lo que el equipo fue pidiendo está acá, para que cualquier sesión de Claude que diseñe o construya un juego tenga el contexto completo sin preguntar de nuevo.

- **Orden de prioridad:** pedido explícito del usuario > este documento > cada skill.
- Si algo choca con una regla oficial de Roblox, gana la regla, y se dice.
- Al cambiar algo de fondo, anotarlo en `team/decisiones.md` y actualizar este archivo en el mismo PR.

Detalle y fuentes:
- `skills/_shared/hits-2026.md`: cómo funcionan los hits, con datos.
- `skills/_shared/algoritmo-descubrimiento.md`: qué premia Home.
- `skills/_shared/vitrina-hits.md`: ícono, miniaturas, título y descripción.
- `skills/_shared/anuncios-2026.md`: publicidad y lanzamiento.
- `skills/_shared/conectores.md`: herramientas.

## 1. Qué hacemos

- **Juegos estilo top hit de Roblox**, hechos para ganar mucho dinero:
  - Modelos: *Steal a Brainrot*, *Steal An Egg*, *Break and Steal an Egg*, *Grow a Garden*, *Fish It!*, *+1 Speed Keyboard Escape*, *Pet Simulator 99*, *Tap Simulator*, *Anime Dice*.
  - Coloridos, adictivos, divertidos y con "cosas en pantalla" todo el tiempo.
  - Animaciones de dopamina, objetivos diarios y todos los trucos de retención de los juegos actuales.
- **Cash grab, sin vueltas:** muchas microtransacciones, pay-to-win y todos los multiplicadores, bonos y ofertas que usan los hits, siempre dentro de las reglas oficiales (sección 6). El dinero es el objetivo; las reglas son el límite.
- **Para chicos.** Son el público que mueve el dinero de los hits. Se diseña para que un chico de 8 a 12 años entienda qué hacer en 10 segundos, sin leer.
- **Dos fuentes de ideas:**
  1. Las fórmulas que hoy están arriba en los Charts, con un giro propio.
  2. Ideas de juegos de fuera de Roblox adaptadas al formato hit, como "la aguja en un pajar" convertida en *Search For The Needle*.

  En los dos casos se copia el diseño de los hits sin culpa (mecánicas, sistemas, HUD, monetización, fórmula del título) y se hace propio lo que tiene dueño: criaturas, arte, sonidos, nombres y miniaturas (sección 2). Roblox baja la exposición de los juegos "no únicos".
- **Inglés, internacional, con foco en EE. UU.:** todo lo que ve el jugador está en inglés, con traducción automática de Roblox. El público es de todo el mundo, pero **el dinero está en EE. UU.**:
  - inglés de EE. UU. y voces con acento estadounidense;
  - eventos y updates en el horario pico de EE. UU.;
  - campañas que arrancan por EE. UU.;
  - Charts mirados en "Todas las ubicaciones" y en EE. UU.

  Docs y equipo en español.
- **Móvil primero:** la mayoría juega en el teléfono. Teléfono base de QA: Samsung Galaxy A06.

## 2. Reglas de oro (todo juego las cumple)

**Por encima de todo, el máximo estándar posible.** Cada pieza (imagen, ícono, sonido, efecto, mapa, UI) se pone al lado de la de los hits. Se elige la más llamativa, la que más hace entrar y la que más vende. Si no está al nivel de un hit, no está terminada.

**Copiar de los hits todo lo que se puede copiar.** Se copia sin culpa:
- mecánicas, loop y sistemas;
- layout del HUD y de los menús;
- monetización, ritmo y tácticas de retención;
- la fórmula del título ("Steal a ___") y el género entero.

Es lo que hacen los hits entre ellos. Lo que tiene dueño no se copia literal: arte, modelos, íconos, sonidos, música, personajes, nombres, marcas y miniaturas. Eso se hace propio, al mismo nivel o mejor. Copiarlo trae un reclamo de copyright (DMCA), strikes en la cuenta y la baja del juego, y Home recomienda menos los juegos "no únicos".

1. **Primer minuto:**
   - Algo bueno pasa en los primeros 10 s.
   - A los 30 s el jugador ya ganó algo y ve un número que sube.
   - Sin tutoriales de texto: una flecha y un objetivo arriba al centro enseñan el juego.
   - Rebotar antes de 60 s es lo que más castiga Home.
2. **Dopamina constante:**
   - Números grandes que suben y ganancia por segundo visible.
   - Monedas que vuelan al contador, "+1", pop-ups de recompensa con brillo y sonido.
   - Rarezas con color propio, revelaciones con suspenso, temblor de cámara en lo grande.
   - Todo movimiento de UI tiene animación (tween con rebote) y sonido.
3. **Siempre un próximo objetivo visible:** la cadena de objetivos, la próxima mejora, el próximo renacer, el próximo regalo. Nunca un momento de "¿y ahora qué?".
4. **Razones para volver:**
   - Diario con racha (el día 7 es el grande).
   - Regalos por tiempo jugado.
   - 3 misiones diarias, ruleta con tirada gratis cada 4 h y eventos con hora fija.
   - Ganancias offline, renacer, índice de colección, códigos, temporadas y updates semanales.
5. **Social:**
   - Robar, mostrar y comparar, con anuncios cuando alguien saca algo raro.
   - Boost por amigos en el servidor, invitar con recompensa para los dos y bono del grupo.
   - Jugar con amigos es señal del algoritmo.
6. **Monetizar en cada momento de deseo:**
   - El producto aparece justo cuando el jugador lo quiere: le falta plata, se le escapa un robo, sale un huevo raro, termina un boost.
   - Detalle en la sección 6.
7. **Se ve como un hit:**
   - Low-poly "cute": cabezas grandes, ojos brillantes y formas redondas.
   - Colores saturados y luz cálida.
   - Partículas y UI con borde grueso, degradé y sombra.
   - Nada gris, nada realista, nada oscuro salvo el terror.
8. **Servidor autoritativo:** el cliente pide y muestra; plata, compras, robos y tiradas los decide el servidor (`roblox-security`).
9. **Rendimiento en gama baja:** si no corre fluido en el A06, no se publica (`roblox-qa-performance`).

## 3. La pantalla (HUD estilo hit)

Referencia completa con capturas de los hits en `hits-2026.md` §3.7. Lo que lleva siempre:

- **Columna izquierda:** botones grandes con ícono y nombre (Shop, Index, Rebirth, Quests, FREE!) y globito rojo con número cuando hay algo para reclamar.
- **Abajo a la izquierda:** monedas con +$/s y el detalle de multiplicadores al tocar ("x2 Gamepass", "+10% Friends", "x3 Event").
- **Arriba al centro:** el objetivo actual con barra de progreso, y debajo los eventos con cuenta regresiva real ("LUCKY HOUR 09:20").
- **Derecha:** ofertas de Robux chicas ("2x Money 10 min — R$5"), regalos por tiempo y misiones.
- **Abajo al centro:** botones de producto contextuales ("+150K SPEED", "Auto Collect") y barra de nivel.
- **Popups:** tienda con pestañas (Featured, Boosts, Currency, Passes, Server), diario, ruleta, índice, renacer, regalo de pases a otro jugador y bienvenida con ganancias offline y oferta x2.
- **Táctil:** botones de 44 px como mínimo. Esquina inferior izquierda (joystick) e inferior derecha (salto) libres.

## 4. Mapas

- Una isla o base por jugador cerca del spawn, el centro de acción a 5–10 s caminando y todo a la vista desde el spawn.
- Caminos de color, carteles grandes con ícono y zonas por rareza (más lejos y más brillante = mejor).
- Decoración con el catálogo (Kenney: naturaleza, fantasía, comida, navidad, cementerio...).
- Iluminación cálida, cielo claro y niebla suave.
- Temporada: Halloween, Navidad o verano se aplican como capa encima del mapa, sin rehacerlo.

## 5. Recursos

- **Catálogo** (`assets/index.json`, `python assets/catalog.py find <palabra>`):
  - Miles de modelos 3D low-poly CC0, 127 de ellos animados.
  - Sonidos de UI, monedas, voces de anunciador ("level up", "you win"), 249 SFX de Roblox y 497 temas de música con licencia.
- **Estilo hit propio (2026-10-29),** reemplaza a los emojis 3D de Fluent, que quedan solo como relleno de prueba:
  - `hit-icons`: 45 íconos de HUD, tienda, boosts y huevos. Para hacer más del mismo estilo: `skills/_shared/iconos/README.md`.
  - `hit-vfx`: 20 texturas de partículas, beams y trails hechas con `tools/vfx_textures.py`.
  - `hit-sfx`: 12 efectos con 4 tomas cada uno, hechos con ElevenLabs. Se publican solo con plan pago confirmado.
  - `hit-voices`: 20 anuncios en inglés ("LEGENDARY!", "LEVEL UP!") en voz grave y voz caricatura.
- **Generar lo que falta** (herramientas elegidas en `conectores.md`, "Qué usamos"):
  - la criatura estrella: imagen con IA → Meshy → Blender;
  - imágenes e íconos: GPT Image con `tools/imagegen.py`;
  - sonidos y voces: ElevenLabs.

  Todo asset nuevo se registra con su licencia en el mismo cambio.
- **Plantilla:** `template/` trae la economía, la retención, la tienda, los boosts y la UI estilo hit. Cada juego copia la plantilla y elige su kit de género.

## 6. Monetización

**Qué hacemos (como los hits):**

- **Muchos Developer Products de compra repetida:**
  - Boosts de tiempo (2x Money 10 min por 5 R$, 30 min por 14 R$, 1 h por 25 R$) y boosts de servidor (119 R$ por 15 min: todos lo ven).
  - Paquetes de moneda en minutos de ganancia, tiradas de ruleta, pack de inicio de 9 R$ (una sola vez), duplicar las ganancias offline y saltear la espera.
  - Regalar pases a otro jugador.
- **Pocos pases fuertes:** 2x Money, 2x Luck, 2x Speed, VIP, Auto Collect y +Slots. Escalera de precios: impulso 9–99, base 99–399, premium 400–999 y ballena 1 000+.
- **Suscripción mensual VIP** y anuncio con premio ("Watch ad" → boost corto), donde Roblox lo permite.
- **Pay-to-win permitido:** pagar da ventajas grandes (multiplicadores, suerte, velocidad, espacios, protección).
  - Criterio de negocio: el que no paga igual progresa, porque su retención es la que hace que Home recomiende el juego.
- **Doble precio** en cosméticos: moneda del juego o Robux, más botón de regalo.

**Reglas oficiales que nunca se rompen** (`roblox-monetization`):

- **Probabilidades** en todo lo aleatorio que se paga con Robux o con moneda comprada con Robux:
  - Se muestran **chicas, como los hits**: texto pequeño bajo cada resultado, o un botón "Odds" con la palabra (solo un ícono "i" no alcanza).
  - Suman 100 %. Un boost de suerte se explica con números y actualiza las probabilidades mientras dura.
  - Lo aleatorio gratis no las necesita.
- **`PolicyService`:** quien no puede comprar aleatorio pago no lo ve.
- **Sin urgencia falsa:**
  - Sin cuentas regresivas que se reinician.
  - Sin descuentos inventados ni escasez falsa.
  - Sin lenguaje de presión con menores ("BUY NOW!"). `tools/check.py` lo busca.
- **Transparencia:** cada producto dice su efecto exacto.
- **Prohibido:** premiar el like o el favorito, links a Discord dentro del juego y notificaciones engañosas.
- **Anuncios con premio:** sin premio aleatorio.
  - El botón "Watch ad" se ofrece **cada vez que Roblox lo permite**: se pregunta a `AdService:GetAdAvailabilityNowAsync` al abrir la tienda o el popup, y si responde `IsAvailable` se muestra.
  - Si el jugador no puede (`PlayerIneligible`, por ejemplo menores de 13, a quienes Roblox prohíbe los formatos con recompensa), en ese lugar va la alternativa permitida: el mismo boost por pocos Robux o un regalo gratis por tiempo jugado.
  - No se buscan vacíos para saltear esa prohibición. Es de protección infantil (COPPA) y saltarla suspende el juego y la cuenta (decisión del 2026-10-28).

## 7. Vitrina: ícono, miniaturas, título y descripción

Detalle, plantillas y herramientas en `skills/_shared/vitrina-hits.md`. Lo esencial:

- **Cómo se hacen:** la imagen con IA (Nano Banana Pro o GPT Image) a partir de referencias del juego: renders de los modelos y capturas del mapa. El texto va encima con `tools/thumbs.py` (`vitrina-hits.md` §6). Nunca emojis sobre un degradé: al lado de los hits parecen stickers.
- **Ícono:** un sujeto gigante y brillante (el huevo, la mascota, el pez), el avatar con cara exagerada si entra, fondo de color saturado y limpio. Se tiene que leer a 150 px.
- **Miniaturas (de 3 a 5 activas):** una escena con tensión o deseo ("robale el huevo al T-Rex dormido"):
  - Flecha y "YOU!" sobre el avatar, "!!" de peligro.
  - Número enorme de valor ("$997,151,167/s") y rareza en arcoíris ("SECRET").
  - Nada importante en el 20 % de abajo.
  - Una variante por hipótesis, para la personalización de miniaturas de Roblox.
- **Texto en ícono y miniaturas:** números y símbolos siempre; palabras, como mucho 3, en inglés simple ("SECRET", "YOU!", "NEW"). El resto de la UI no lleva texto dentro de imágenes (`CLAUDE.md`).
- **Título:**
  - Corto, con la fórmula a la vista ("Steal a ___", "+1 ___ Every Step").
  - Etiqueta de temporada o update al principio con emoji ("[🎃 UPD]"). Uno o dos emojis como mucho.
  - Estable: no renombrar seguido.
- **Descripción:**
  - Primera línea con el gancho ("🥚 Welcome to …!") y "How to Play" con 4 a 7 líneas de emoji + verbo.
  - El gancho que vende ("Money generates while you're offline!"), novedades del update y plataformas.
  - Nada que prometa Robux ni listas de palabras sueltas.
- **Video de gameplay:** el loop real en los primeros segundos. Sin voz ni texto de oferta.

## 8. Publicidad y lanzamiento

Skill `roblox-campaigns` (fuentes en `anuncios-2026.md`). Lo esencial:

- **Lanzar a 16+ y llegar a menores de 16** (Kids y Select) cuanto antes. Hay dos caminos:
  - Juntar los jugadores muy comprometidos que pide la evaluación, con campañas Plays o Engagement.
  - Pagar la revisión rápida de 100 000 Robux, que se devuelve a los 90 días.
- **Ads Manager:**
  - Empezar chico, probar hasta 10 miniaturas por campaña y arrancar un jueves para que el aprendizaje (24–48 h) termine antes del pico del sábado.
  - No pausar a cada rato: cada pausa reinicia el aprendizaje.
  - Medir costo por partida, retención D7 de los que llegan por anuncio y retorno del gasto.
- **Recompensa exclusiva para quien entra por un anuncio o link** (LaunchData), anunciada en el juego. Roblox dice que sube la conversión.
- **Fuera de Roblox:**
  - Clips cortos del loop (TikTok, Shorts, Reels) con *share links* por canal para medir.
  - Creadores de contenido chicos, con su pago y su aviso de publicidad.
  - Momentos dentro del juego que invitan a grabar.
- **Gratis dentro de Roblox:** eventos con "Notify Me", anuncios de update a los suscriptos (cada 3 días, 60 caracteres), notificaciones del juego y personalización de miniaturas.

## 9. Cómo se construye un juego con Claude

1. Leer este documento, `CLAUDE.md` y `team/tareas.md`.
2. Fase 1, idea (`roblox-ideation`): fórmula hit + giro propio, o idea externa adaptada; puntuar; decidir el público (chicos = plan para Kids y Select desde el día 1).
3. Fase 2 (`roblox-game-cloner`): spec + copiar la plantilla + kit de género + mapa.
4. Fases 3 a 7: UI estilo hit, monetización, seguridad, QA y cumplimiento, con sus skills.
5. Fase 8, publicación (`roblox-publishing` + `vitrina-hits.md`): ícono, miniaturas, título, descripción y video.
6. Campañas (`roblox-campaigns`): plan de lanzamiento con presupuesto, creatividades y reglas para cortar o escalar.
7. Fases 9 y 10, métricas y live ops: un update por semana, eventos, temporadas y ofertas nuevas.

Cada fase termina mostrando el resultado y esperando el visto bueno (`CLAUDE.md`).

## 10. Lo que no hacemos

Cada punto cuesta plata: moderación, juego dado de baja o menos exposición.

- Clonar un juego o usar arte, nombres o personajes de otros (incluidos los "brainrots" de otros juegos).
- Metadata engañosa: prometer algo que no está, "free Robux", miniaturas que muestran otro juego o arte que parece IA. La comunidad castiga los anuncios con cara de IA; se usan capturas y renders reales.
- Premiar likes, favoritos o suscripciones a canales externos, y links a Discord dentro del juego.
- Aleatorio pago sin probabilidades, urgencia falsa o presión a menores.
- Bots, tráfico falso o cualquier trampa con anuncios (suspensión de cuenta).
- Darle claves de Roblox a servicios de terceros. Las claves van solo en variables de entorno de cada máquina.

## 11. Lo que pidió el equipo (historial)

Para entender la intención detrás de cada regla:

- **2026-10-26 (Luciano):**
  - Juegos en inglés para todo el mundo.
  - Ventajas pagas permitidas con las reglas oficiales.
  - Estilo *Steal a Brainrot* / *Grow a Garden* sin clonar.
  - Criaturas propias.
- **2026-10-28 (Leonel):**
  - Pasar todo a juegos "más cash grab", hechos para la retención, con animaciones de dopamina, coloridos, adictivos y divertidos, pensados para chicos.
  - Cosas en pantalla y objetivos diarios.
  - Estudiar los hits del momento (Steal An Egg, Fish It, Break and Steal an Egg, +1 Speed Keyboard Escape).
  - Sumar skills, animaciones, conectores (Blender) y código reutilizable.
  - Poder adaptar ideas de juegos existentes (la aguja en un pajar).
- **2026-10-28, misma tanda (Leonel):**
  - Rediseñar todo si hace falta y dejarlo lo más avanzado posible.
  - Usar todos los trucos: x2, bonos, retención y ruleta.
  - Muchísimas microtransacciones y pay-to-win, "lo más cash grab posible".
  - Probabilidades chicas como los hits, no gigantes.
  - Estudiar HUDs y mapas de los hits.
  - No escatimar en recursos: los mejores íconos, sonidos y mapas, siempre en estilo hit.
- **2026-10-28, conectores (Leonel):**
  - Conectar Rojo, Blender, ForgeGUI, Meshy y Obsidian, evaluando cada uno.
  - Los dos integrantes con todo conectado.
- **2026-10-28, campañas (Leonel):**
  - Sumar un creador de campañas para publicitar los juegos: cómo funciona, qué campañas rinden, cuánto poner, cómo llevarlas.
  - Pensar las imágenes de juegos y campañas, y dejar todo listo para las mejores miniaturas y descripciones, para que la gente haga clic y entre.
- **2026-10-28 (Leonel):** anotar todo lo que se define (cómo queremos los juegos y cómo tienen que ser) para que Claude tenga todo el contexto al construir. Este documento es esa respuesta.
- **2026-10-29 (Leonel):**
  - Las miniaturas estaban malas al lado de las de los hits: investigar cómo hacerlas bien, quizá con ChatGPT. Respuesta: IA con referencias del juego (`vitrina-hits.md` §6).
  - Los íconos y las partículas se ven "muy emojis 3D": copiar los de los hits. Revisar también los sonidos y mandarle los mejores para opinar.
  - "Buscar siempre el mayor estándar de calidad posible, enfocado en lo que buscamos: lo más cash grab, llamativo y que la gente entre." Es la primera regla de la sección 2.
  - "Que se asemeje a los top hits, sin ser copias literales, pero que use todo lo que usan ellos en tácticas, mecánicas y estándares", y enseguida: "no necesariamente evitando copiarlos". Es la segunda regla: se copia el diseño entero, no los assets con dueño.
  - "Apuntamos a público internacional, en USA está el dinero": inglés siempre, también en las voces (sección 1).
  - Herramientas: preguntó por Meshy, ForgeGUI, Blender y ChatGPT. Quedó: API de OpenAI para imágenes, Meshy directo y Blender para 3D, ElevenLabs para sonidos y voces, ForgeGUI no (`conectores.md`, "Qué usamos").
