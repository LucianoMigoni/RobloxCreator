# Tácticas honestas

Cada táctica dice en qué se apoya. Las marcadas **(hub)** son criterio nuestro y no texto de Roblox. Antes de monetizar fuerte, **retención primero**: el FAQ del algoritmo dice que, con retención baja, primero se arregla el gameplay; con retención sólida, mejorar la monetización suma impresiones de Home (`skills/_shared/algoritmo-descubrimiento.md`).

## Qué vender (guía oficial *Monetization foundations*)
Para cada ítem: **qué** se vende, **dónde** y **cómo**. Cada ítem tiene que tener un propósito que el jugador entienda enseguida (el ejemplo oficial es la linterna de *Doors*: se entiende para qué sirve antes de comprarla).
- **Durables** (usos ilimitados: skins, mascotas) → Game Pass o ítem permanente.
- **Consumibles** (usos limitados: impulsos temporales, revivir) → Developer Product.
- Por utilidad: **mejora** (velocidad, herramientas, acceso) o **expresión** (skins, emotes). La expresión es la que menos rompe el balance **(hub)**.

## Dónde y cómo (guías oficiales *Monetization foundations* y *Contextual purchases*)
- **Tienda integrada, contextual e invitante:** fácil de encontrar, explica qué hace cada ítem en relación con los demás, y vale la pena visitarla (contenido nuevo, rotación).
- **Compras contextuales:** ofrecer el ítem en el momento en que sirve: en juego (como el "continuar" de los arcades, dejando tiempo para decidir), antes de jugar, en el lobby, o como complemento de otra compra.
- **Pase de temporada** (guía *Season pass design*): pista **gratis** y pista **premium**, recompensas atractivas, duración manejable y misiones de varias categorías y dificultades. Es además un motivo para volver en D2–7 y D8–28.

## Productos de Roblox (`/production/monetization`)
| Producto | Para qué | Nota |
|---|---|---|
| Game Pass | Beneficio permanente (VIP, x2, área) | Se compra una vez; no puede dar ítems aleatorios pagos |
| Developer Product | Consumibles y packs de moneda | Se otorga solo en `ProcessReceipt` |
| Servidores privados | Jugar con amigos (pago mensual opcional) | Suma a la señal de co-play del algoritmo **(hub)** |
| Suscripciones | Beneficio recurrente | Respetar los términos de uso y la ley local; `PolicyService` |
| Anuncios inmersivos | Ingreso por anuncios | Requiere el cuestionario de madurez aprobado; los no elegibles no ven el anuncio |
| Optimización y precios regionales | Encontrar el precio y ajustarlo por región | Herramientas oficiales; preferirlas a adivinar precios |

## Tácticas del hub, con su límite ético
| Táctica | Hacerlo así | Nunca así |
|---|---|---|
| Pack de inicio | Una sola vez por jugador, con valor real comparado con comprar por separado | Con cuenta regresiva que se reinicia o "solo hoy" falso |
| Oferta en el momento justo | Cuando el jugador la necesita (contextual) | Interrumpiendo el juego ni con lenguaje de presión |
| Anclaje con ahorro real | Mostrar el pack junto al precio suelto, con el ahorro real | Inflar el precio de referencia o tener el mismo ítem "en oferta" siempre |
| Cosméticos visibles | Que se vean en el avatar o en el mundo (otros los ven) | Vender ventajas competitivas disfrazadas de cosmético |
| Pases que ahorran tiempo | Acelerar lo que igual se puede lograr jugando | Bloquear el contenido principal detrás de un pago |
| Pase de temporada | Pista gratis real y premium opcional | Pista gratis vacía para empujar a la premium |
| Cajas o sorteos | Mostrar todos los resultados y sus probabilidades; `PolicyService` | Sin probabilidades, o pagables con Robux sin bloqueo regional |
