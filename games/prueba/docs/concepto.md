# Concepto: juego de prueba (C2)

Fecha: 2026-10-26 · Autor: Luciano (con Claude) · Estado: **aprobado por Luciano** (2026-10-26): Roba y Fusiona; falta el visto bueno de Leonel

## Pedido
Juego de prueba de punta a punta para la fase C2 del hub (`ROADMAP.md`).

Luciano pidió (2026-10-26) el **estilo** de *Steal a Brainrot*, *Grow a Garden* y los simuladores sencillos que atraen a muchos jugadores. **No un clon:** el mismo tipo de juego, con mecánica, tema y arte propios. Este documento reemplaza la propuesta anterior ("Cocina en Cadena"), que iba por los tycoons de cooperación.

Restricciones del hub:
- se construye sobre la plantilla (datos, monedas, tienda, inventario, onboarding y UI);
- equipo de dos, MVP en 3–4 semanas;
- sale primero solo para 16+, pero el núcleo no debe dejar afuera a menores de 16.

**Idioma y público:** el juego va enteramente en inglés y apunta a jugadores de todo el mundo (regla del hub, `CLAUDE.md`). Este documento es interno y está en español; los nombres y textos que ve el jugador se escriben en inglés.

## El estilo, en una línea
**Conseguí algo rápido → ponelo en tu base → te paga por segundo → buscá rarezas y mutaciones → mostrálo o defendelo → mejorá y renacé.** Los servidores son chicos para que todos vean las bases de todos, y hay updates semanales con criaturas y eventos nuevos.

## Investigación

Fuentes, todas vistas el **2026-10-26**:
- **Charts:** https://www.roblox.com/charts con el filtro "PC · Todas las ubicaciones". El filtro de teléfono no se pudo fijar desde la sesión.
- **Página del juego:** https://www.roblox.com/games/<id>. Visitas, favoritos, jugadores en ese momento, fechas, género y máximo por servidor salen de la API pública que usa esa página (`games.roblox.com/v1/games`). Los nombres se buscaron con el buscador de roblox.com.

| Juego de referencia | Género / subgénero | Dato observado | Fuente | Fecha |
|---|---|---|---|---|
| Steal An Egg (Robar un huevo) | Simulation / Tycoon | 1.º en "Más jugadas ahora": 696K jugadores; 9 563 M de visitas desde 2026-07-25; servidores de 7 | [juego](https://www.roblox.com/games/107778070777162) | 2026-10-26 |
| Steal a Brainrot | Simulation / Tycoon | 209K jugadores; 74 177 M de visitas y 29,6 M de favoritos desde 2025-05-16; servidores de 8 | [juego](https://www.roblox.com/games/109983668079237) | 2026-10-26 |
| Grow a Garden | Simulation / Tycoon | 14,8K jugadores; 35 992 M de visitas y 11,5 M de favoritos desde 2025-03-25; servidores de 4 | [juego](https://www.roblox.com/games/126884695634066) | 2026-10-26 |
| Steal A Pet And Ride It! | Simulation / Tycoon | En "Prometedoras", 93 %, 10,3K jugadores; 2,6 M de visitas en 22 días (creado el 2026-10-04) | [juego](https://www.roblox.com/games/95168737547508) | 2026-10-26 |
| Escala para conseguir huevos de animales | Simulation / Tycoon | En tendencia, 98 %, 17K jugadores; 56,9 M de visitas desde 2026-09-06 | [juego](https://www.roblox.com/games/85738654635245) | 2026-10-26 |
| Monta un dinosaurio | Simulation / Tycoon | En tendencia, 97 %, 25,6K jugadores; 20,8 M de visitas desde 2026-08-24 | [juego](https://www.roblox.com/games/93523763376122) | 2026-10-26 |
| Fish It! | Simulation / Incremental Simulator | 71,2K jugadores; 4 801 M de visitas desde 2024-10-21 | [juego](https://www.roblox.com/games/121864768012064) | 2026-10-26 |
| Dig & Clean | Simulation / Tycoon | 1,1K jugadores; 128,8 M de visitas y 1,77 M de favoritos desde 2026-07-09 (excavar, limpiar, museo propio) | [juego](https://www.roblox.com/games/83038462357724) | 2026-10-26 |
| Build a Zoo | Simulation / Tycoon | 1,2K jugadores; 531,6 M de visitas desde 2025-07-04 | [juego](https://www.roblox.com/games/105555311806207) | 2026-10-26 |
| Plants & Brainrots | Simulation / Tycoon | 2,1K jugadores; 4 720 M de visitas desde 2025-08-01 | [juego](https://www.roblox.com/games/127742093697776) | 2026-10-26 |
| Grow a Garden 2 | Simulation / Tycoon | 976 jugadores; 1 680 M de visitas desde 2026-05-21 (suma robo de noche a la fórmula de cultivo) | [juego](https://www.roblox.com/games/97598239454123) | 2026-10-26 |
| Plant Brainrot Simulator | Simulation / Incremental Simulator | 31 jugadores; 41,9 M de visitas desde 2025-11-28 | [juego](https://www.roblox.com/games/92814019058536) | 2026-10-26 |
| Drill Blocks for Brainrots | Simulation | 652 jugadores; 66,6 M de visitas desde 2026-05-12 | [juego](https://www.roblox.com/games/78177131121429) | 2026-10-26 |
| Break a Lucky Block! | Simulation / Tycoon | 605 jugadores; 591,7 M de visitas desde 2025-12-12; última actualización 2026-05-09 | [juego](https://www.roblox.com/games/124311897657957) | 2026-10-26 |

### Tendencias
1. **"Roba un X" es lo más jugado hoy.** Los dos primeros de "Más jugadas ahora" son de robar (Steal An Egg y Steal a Brainrot), y siguen saliendo nuevos que crecen (Steal A Pet And Ride It!).
2. **El cultivo tuvo el pico más grande, pero hoy juega menos gente.** Grow a Garden tiene 36 000 M de visitas y hoy 14,8K jugadores; sus derivados también bajaron (Grow a Garden 2: 976; Plants & Brainrots: 2,1K).
3. **Las copias casi literales se vacían.** Plant Brainrot Simulator (31), Drill Blocks for Brainrots (652) y Break a Lucky Block! (605, sin update desde mayo) consiguieron visitas, pero hoy casi no tienen jugadores. Coincide con lo que dice la guía oficial: el algoritmo baja la exposición de los juegos "no únicos" (`skills/_shared/algoritmo-descubrimiento.md`).
4. **Los que siguen arriba actualizan seguido.** Todos los grandes tienen update entre el 2026-10-21 y el 2026-10-26, con eventos de Halloween.
5. **Variantes que funcionan:** montar lo que robaste (Steal A Pet And Ride It!), escalar para conseguir huevos, excavar y exhibir en un museo (Dig & Clean), pescar (Fish It!).

### Huecos
- **Combinar criaturas** dentro de la fórmula de robar: en las referencias, las criaturas se compran, roban, eclosionan o mutan, pero no se fusionan entre sí.
- **Coleccionar armando** (piezas que juntas valen más) en vez de solo sumar unidades sueltas.

### Hipótesis (sin verificar; no suman en el criterio de evidencia)
- Cuál fue el máximo histórico de jugadores de cada juego; solo se ve la cifra de hoy.
- Que las tendencias sean iguales en teléfono.
- Que no exista ya un juego de robar con fusión de criaturas muy jugado; solo se revisaron los Charts y la búsqueda por nombre.
- Cuántos jugadores tienen menos de 16.

## Reglas para no ser un clon
- **Criaturas, arte, nombres y mapa propios.** En este juego no se usan personajes "brainrot": decisión de Luciano (2026-10-26) para diferenciarse. Existen packs de brainrots gratis o con licencia comercial; si otro juego los quiere usar, entran como cualquier asset de terceros, con su licencia en `assets/LICENSES.md`.
- **Título propio.** Puede usar el patrón "Roba un…", que los jugadores ya entienden, pero no el nombre ni las imágenes de un juego existente.
- **Al menos una mecánica central que las referencias no tengan.**

## Monetización: como los juegos del estilo, dentro de las reglas
Pagar **da ventajas importantes**, como en las referencias: multiplicadores, más espacios, velocidad, suerte, protección y compra directa (decisión del 2026-10-26, `roblox-monetization`). Lo que sigue prohibido son las reglas oficiales de Roblox:
- Suerte o resultados aleatorios pagados con Robux: mostrar **todos** los resultados y sus **probabilidades** (con y sin el impulso), y bloquearlos con `PolicyService` a quien tenga `ArePaidRandomItemsRestricted`.
- Ninguna urgencia falsa ni cuenta regresiva que se reinicia. Si la tienda del juego se repone cada X minutos, el temporizador es real y no se reinicia al entrar.
- Cada producto dice su efecto exacto, y el servidor da exactamente eso.

Criterio del hub: el que no paga sigue pudiendo jugar y progresar; si se va, cae la retención, que es lo que más pesa en el algoritmo.

## Conceptos

### 1. Roba y Fusiona
- **Nombre de trabajo en inglés:** *Steal & Fuse Critters*. El título final se decide en `roblox-publishing`; los bichos se llaman *critters* en el juego.
- **Gancho:** "Steal critters, fuse two of a kind, get a rarer one!" (robá bichos, fusioná dos iguales y sacá uno más raro). Thumbnail: dos bichos chocando en una máquina y saliendo uno dorado.
- **Loop central:**
  - Pasan bichos por una cinta; comprás uno con monedas.
  - Lo ponés en tu base y genera monedas por segundo.
  - Con dos iguales en el fusionador sale el del nivel siguiente.
  - Con más monedas, mejores bichos.
  - Renacer multiplica las ganancias.
- **El giro propio:** la **fusión**. Dos del mismo nivel dan uno superior. Al fusionar hay probabilidad de mutación (dorado, arcoíris), con el porcentaje **siempre visible en pantalla**. Robar ayuda a juntar el par que te falta.
- **Primer minuto:**
  - 10 s: comprás el primer bicho, que ya va hacia tu base.
  - 30 s: está generando monedas.
  - 60 s: primera fusión, guiada por el onboarding.
- **Volver D2–7 / D8–28:** un álbum de bichos por nivel y mutación, ganancias aunque no estés conectado (con tope), un bicho nuevo cada semana y renacer.
- **Con amigos:**
  - Robar y defender: entrás a otra base, agarrás un bicho y volvés más lento mientras lo llevás; el dueño puede empujarte para que lo sueltes.
  - Los amigos se defienden entre ellos.
  - Servidores de 8.
- **Anti-frustración (gratis para todos):**
  - Los jugadores nuevos no pueden ser robados durante los primeros minutos.
  - La base tiene una traba de 60 s.
  - El bicho más valioso de cada jugador no se puede robar.
- **Monetización:**
  - *Game Passes:* x2 monedas; +4 pedestales en la base; traba de base de 120 s en vez de 60; x1,5 de velocidad al llevar un bicho robado; VIP (cinta propia con bichos un nivel más alto y x1,5 monedas).
  - *Developer Products:* packs de monedas; compra directa de un bicho de nivel alto con precio a la vista; escudo de 15 min (nadie te roba); "fusión con suerte", que sube la probabilidad de mutación y muestra los porcentajes con y sin el impulso, con `PolicyService`.
  - *Cosméticos:* skins de base y de cinta, que los demás ven.
  - *Pack de inicio:* una sola vez.
- **Género / subgénero oficial:** Simulation / Tycoon.
- **Público y etiqueta esperada:** todas las edades. El robo es un juego de atrapar, sin violencia; el "empujón" es cómico.
- **Alcance:**
  - Ya está en la plantilla: monedas, tienda (compras validadas en el servidor), inventario, onboarding y HUD.
  - Hay que construir: bases por jugador, cinta de bichos, ganancia por segundo, fusión, robar y llevar con validación de distancia en el servidor, traba de base y renacer.
  - Los bichos son modelos low-poly propios hechos con Blender MCP (el pipeline de C1).
  - MVP estimado: 3–4 semanas.
- **Riesgos:**
  - Es la fórmula más competida.
  - Que te roben puede hacer rebotar a los nuevos (de ahí las reglas anti-frustración).
  - La economía puede inflacionarse con las ganancias sin conexión.
  - Hace falta mucho contenido semanal.

### 2. Jardín de Bichos
- **Nombre de trabajo en inglés:** *Critter Garden*.
- **Gancho:** "Plant seeds that hatch into critters that pay you!"
- **Loop central:** comprar semillas en la tienda del juego (se reponen cada pocos minutos, solo con moneda del juego) → plantarlas → crecen en tiempo real y nace el bicho → el bicho genera monedas → mejores semillas.
- **El giro propio:** de la planta **nace una criatura**. El clima del servidor cambia cómo nace (bicho de lluvia, de tormenta), y eso se ve en el álbum.
- **Primer minuto:** a los 10 s plantás; la primera semilla está hecha para crecer en 20 s y el primer bicho nace antes del minuto.
- **Volver D2–7 / D8–28:** lo que crece en tiempo real hace volver al día siguiente; además, climas raros, álbum y temporadas.
- **Con amigos:** regar el jardín de un amigo acelera su crecimiento, y se pueden visitar y mostrar los jardines. Servidores de 4–6.
- **Monetización:**
  - *Game Passes:* x2 velocidad de crecimiento; +6 parcelas; regadera automática; VIP con semillas exclusivas.
  - *Developer Products:* semilla rara concreta con precio a la vista; reponer la tienda de semillas ya (el temporizador es real); abono de suerte con las probabilidades de clima o mutación visibles y `PolicyService`; packs de monedas.
  - *Cosméticos:* decoración de jardín.
  - *Pack de inicio:* una sola vez.
- **Género / subgénero oficial:** Simulation / Tycoon.
- **Público y etiqueta esperada:** todas las edades.
- **Alcance:** parcelas, temporizadores de crecimiento, clima por servidor y bichos. No necesita la física de robar. MVP de 3 semanas.
- **Riesgos:** la demanda del cultivo bajó (tendencia 2); hay que esperar a que crezca y eso puede hacer rebotar; puede parecerse demasiado a Grow a Garden si el giro no se nota en el thumbnail.

### 3. Excava un Fósil
- **Nombre de trabajo en inglés:** *Dig a Fossil*.
- **Gancho:** "Dig up bones, build dinosaurs, fill your museum!"
- **Loop central:** excavar en tu zona → limpiar la pieza → armar el esqueleto → el dinosaurio completo se exhibe en tu museo y paga por segundo (completo paga mucho más que las piezas sueltas) → mejores palas y zonas.
- **El giro propio:** **armar colecciones**: cada dinosaurio necesita sus piezas, y una pieza rara cambia la variante.
- **Primer minuto:** a los 5 s excavás y antes de 30 s tenés el primer hueso; el primer esqueleto chico se completa en el primer minuto.
- **Volver D2–7 / D8–28:** completar especies, dinosaurios de temporada y el museo como vitrina.
- **Con amigos:** excavar juntos en zonas grandes, visitar museos, regalar piezas repetidas.
- **Monetización:**
  - *Game Passes:* pala x2; zona de excavación VIP con más piezas raras; +espacio en el museo.
  - *Developer Products:* comprar la pieza exacta que te falta; suerte de pieza rara con probabilidades visibles y `PolicyService`.
  - *Cosméticos:* cosméticos de museo.
  - *Pack de inicio:* una sola vez.
  - Sin robo hay menos motivo social para pagar.
- **Género / subgénero oficial:** Simulation / Tycoon.
- **Público y etiqueta esperada:** todas las edades.
- **Alcance:** excavación (puntos de excavación, no terreno libre), piezas en el inventario de la plantilla, armado y museo. MVP de 3–4 semanas.
- **Riesgos:** menos evidencia de demanda que robar o cultivar; armar puede ser confuso en el teléfono.

### 4. Roba un Pez
- **Nombre de trabajo en inglés:** *Steal a Fish*.
- **Gancho:** "Catch rare fish, fill your aquarium… and guard it from thieves!"
- **Loop central:** pescar con un toque → poner el pez en el acuario → paga por segundo → mejor caña → robar peces de otros acuarios.
- **El giro propio:** juntar pesca y robo; en las referencias van por separado.
- **Primer minuto:** a los 10 s lanzás y antes de 30 s sale el primer pez.
- **Volver D2–7 / D8–28:** colección por rareza, peces de temporada y ganancias sin estar conectado.
- **Con amigos:** robar y defender, pescar en el mismo lago.
- **Monetización:**
  - *Game Passes:* x2 monedas; caña de suerte, con las probabilidades de rareza visibles; +espacio en el acuario; traba de acuario más larga.
  - *Developer Products:* cebo raro con probabilidades visibles y `PolicyService`; packs de monedas.
  - *Cosméticos:* cañas y acuarios cosméticos.
  - *Pack de inicio:* una sola vez.
- **Género / subgénero oficial:** Simulation / Tycoon.
- **Público y etiqueta esperada:** todas las edades.
- **Alcance:** dos sistemas grandes (pesca y robo). MVP de 4 semanas o más.
- **Riesgos:** compite con Fish It! (71K jugadores) y con los juegos de robar a la vez, y es el de mayor alcance.

## Puntuación
Pesos de `skills/roblox-ideation/references/scoring.md`. Puntos de 0 a 5; aporte = puntos / 5 × peso.

| Criterio (peso) | 1 Roba y Fusiona | 2 Jardín de Bichos | 3 Excava un Fósil | 4 Roba un Pez |
|---|---|---|---|---|
| 1 Primer minuto (15) | 5 — compra a los 10 s y monedas a los 30 s | 4 — plantás enseguida, pero hay espera | 4 — primer hueso antes de 30 s | 4 — primer pez antes de 30 s |
| 2 Loop central (15) | 5 — comprar, colocar, cobrar y fusionar | 5 — plantar, nacer y cobrar | 4 — excavar, armar y exhibir | 5 — pescar, colocar y cobrar |
| 3 Volver D2–7 / D8–28 (15) | 4 — álbum, bicho semanal, renacer | 5 — el crecimiento en tiempo real trae de vuelta | 4 — completar especies | 4 — colección y temporadas |
| 4 Con amigos (10) | 4 — robar y defender juntos | 3 — regar y visitar | 3 — excavar juntos y visitar | 4 — robar y defender |
| 5 Diferenciación (10) | 3 — la fusión es nueva en la fórmula, pero la fórmula está muy usada | 3 — bichos en vez de frutas, y el clima | 4 — armar colecciones de esqueletos | 2 — mezcla dos fórmulas muy cubiertas |
| 6 Evidencia (10) | 5 — los dos primeros de "Más jugadas" son de robar, y sigue habiendo nuevos que crecen | 4 — el pico más grande, pero hoy con menos jugadores | 4 — Dig & Clean y Monta un dinosaurio con datos | 5 — Fish It! y los de robar con datos |
| 7 Monetización (10) | 5 — multiplicadores, espacios, traba y escudo, suerte con probabilidades, VIP y compra directa | 5 — crecimiento x2, parcelas, reposición, suerte con probabilidades | 4 — pala, zona VIP y piezas, pero sin robo hay menos motivo social para pagar | 5 — multiplicadores, suerte, espacio y traba |
| 8 Alcance (10) | 3 — robo, fusión y bases nuevos | 4 — sin física de robo | 3 — excavación y armado | 2 — dos sistemas grandes |
| 9 Móvil (5) | 4 — tocar para comprar y fusionar; perseguir es simple | 5 — todo con toques | 5 — todo con toques | 5 — pesca con un toque |
| **Total /100** | **86** | **85** | **77** | **80** |

Cortes duros (0 en primer minuto, diferenciación o monetización): ninguno. Ningún concepto tiene en su núcleo algo que deje afuera a menores de 16.

## Recomendación
**Concepto 1, Roba y Fusiona (86/100).** Es el estilo que hoy tiene más jugadores (tendencia 1) y tiene un giro propio, la fusión. Además es el que más formas tiene de venderse: el robo le da al jugador motivos para querer protegerse, defender su base y apurar su progreso.

Queda casi empatado con **Jardín de Bichos (85)**. Este es más fácil de construir y retiene mejor, pero apuesta a un estilo que hoy juega menos gente. Si el prototipo del 1 falla, es el plan B.

**Hipótesis a validar primero en el prototipo** (guía oficial *Prototyping*): ¿la fusión se entiende sola en el primer minuto y hace que la sesión dure más que solo comprar y robar? ¿Y que te roben no hace irse a los nuevos?

Prototipo mínimo:
- cinta con 3 bichos y 2 niveles;
- fusionador;
- robo entre dos cuentas de prueba en Studio;
- medir con el embudo de onboarding de la plantilla cuántos llegan a la primera fusión.

Siguiente paso, si se aprueba: `roblox-game-cloner` escribe `games/prueba/docs/spec.md`, que toma el estilo y las mecánicas sin copiar título, arte ni mapa, y copia la plantilla en `games/prueba/`.
