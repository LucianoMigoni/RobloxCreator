# Concepto: juego de prueba (C2)

Fecha: 2026-10-26 · Autor: Luciano (con Claude) · Estado: **propuesta** (falta el visto bueno de Luciano y Leonel)

## Pedido
Juego de prueba de punta a punta para la fase C2 del hub (`ROADMAP.md`). El usuario no trajo idea ni género ("proponé vos"). Restricciones del hub:
- se construye sobre la plantilla (datos, monedas, tienda, inventario, onboarding y UI ya hechos);
- equipo de dos personas, MVP en 2–3 semanas;
- sale primero solo para 16+ (`team/decisiones.md`, 2026-10-25), pero el núcleo no debe dejar afuera a menores de 16 para poder abrirlo después.

## Investigación

Fuentes, todas vistas el **2026-10-26**:
- **Charts:** https://www.roblox.com/charts con los filtros "PC · Todas las ubicaciones" y "PC · Argentina". En los Charts, el % es la valoración positiva y la cifra con K son los jugadores conectados en ese momento. El filtro de teléfono no se pudo fijar desde la sesión: el sitio volvía a PC.
- **Página del juego:** https://www.roblox.com/games/<id>. Las visitas, favoritos, fechas, género y máximo de jugadores salen de la API pública que usa esa página (`games.roblox.com/v1/games`).

| Juego de referencia | Género / subgénero | Dato observado | Fuente | Fecha |
|---|---|---|---|---|
| Robar un huevo | Simulation / Tycoon | 1.º en "Más jugadas ahora" con 692,3K jugadores y 91 % de valoración; 9 562 M de visitas desde que se creó, el 2026-07-25 | [juego](https://www.roblox.com/games/107778070777162), Charts | 2026-10-26 |
| Roba un Brainrot | Simulation / Tycoon | 250K jugadores, 85 %; 74 176 M de visitas desde 2025-05-16 | [juego](https://www.roblox.com/games/109983668079237), Charts | 2026-10-26 |
| Monta un dinosaurio | Simulation / Tycoon | En tendencia, 97 %, 25,6K jugadores; 20,8 M de visitas desde 2026-08-24 | [juego](https://www.roblox.com/games/93523763376122), Charts | 2026-10-26 |
| Escala para conseguir huevos de animales | Simulation / Tycoon | En tendencia, 98 %, 17,2K jugadores; 56,9 M de visitas desde 2026-09-06; sus animales dan ingresos aunque el jugador no esté conectado | [juego](https://www.roblox.com/games/85738654635245), Charts | 2026-10-26 |
| Lavar el coche | Simulation / Tycoon | En tendencia, 88 %, 12,9K jugadores; 18,5 M de visitas y 653K favoritos desde 2026-08-16; servidores de 6 | [juego](https://www.roblox.com/games/70733580049633), Charts | 2026-10-26 |
| ¡Haz alfombras! | Simulation / Tycoon | En tendencia, 94 %, 7,3K jugadores; 6,5 M de visitas en 19 días (creado el 2026-10-07); fabricar, vender, contratar empleados | [juego](https://www.roblox.com/games/123184865562509), Charts | 2026-10-26 |
| Construye un imperio de teléfonos | Simulation / Tycoon | En tendencia, 87 %, 12,6K jugadores; 11,3 M de visitas desde 2026-09-22; los amigos aparecen como empleados | [juego](https://www.roblox.com/games/101914705206759), Charts | 2026-10-26 |
| Vender Limones | Simulation / Tycoon | En tendencia, 94 %, 10,4K jugadores; 490 M de visitas desde 2025-03-17; ingresos aunque el jugador no esté conectado | [juego](https://www.roblox.com/games/79268393072444), Charts | 2026-10-26 |
| +1 Evolución de Veneno | Simulation / Incremental Simulator | En tendencia, 96 %, 18,1K jugadores; 15,1 M de visitas desde 2026-10-05 | [juego](https://www.roblox.com/games/116448925875915), Charts | 2026-10-26 |
| Tap Simulator REBORN | Simulation / Incremental Simulator | En tendencia, 94 %, 46K jugadores; 21,8 M de visitas desde 2026-08-04 | [juego](https://www.roblox.com/games/72858262610964), Charts | 2026-10-26 |
| Hospital de Animales (anomalía) | Survival | 93 %, 21,6K jugadores; 2 472 M de visitas desde 2026-05-10 | [juego](https://www.roblox.com/games/78515283254292), Charts | 2026-10-26 |
| ¡Vende papas fritas! (anomalía) | Survival | 83 %, 30,4K jugadores; 74 M de visitas desde 2026-09-21 | [juego](https://www.roblox.com/games/94891079210424), Charts | 2026-10-26 |
| Seguridad del aeropuerto (anomalía) | Survival | En tendencia, 92 %, 9,6K jugadores; 3,5 M de visitas desde 2026-09-30 | [juego](https://www.roblox.com/games/108334808788078), Charts | 2026-10-26 |
| Solo en casa: Anomalías | Survival | En tendencia, 94 %, 16,3K jugadores; 222 M de visitas desde 2026-05-04 | [juego](https://www.roblox.com/games/87468080405188), Charts | 2026-10-26 |
| Pedos Juntos [OBBY de 1-4 jugadores] | Obby & platformer | En tendencia y "Prometedoras", 95 %, 6K jugadores; 1,3 M de visitas en 14 días (creado el 2026-10-12); obby cooperativo con física compartida | [juego](https://www.roblox.com/games/100047964036957), Charts | 2026-10-26 |
| ¡Lleva el cristal juntos! [Obby de 2 jugadores] | Obby & platformer | En "Diversión con amigos", 89 %, 4,6K jugadores; 35,9 M de visitas desde 2026-06-29 | [juego](https://www.roblox.com/games/81734857983173), Charts | 2026-10-26 |

### Tendencias
1. **"Hacé X y vendelo".** Simuladores-tycoon de una tarea satisfactoria: lavar coches, hacer alfombras, armar teléfonos, vender limones. Crecen rápido, por ejemplo 6,5 M de visitas en 19 días. Todos son Simulation / Tycoon, con servidores chicos de 6 a 10 jugadores.
2. **Juntar y colocar para ganar ingresos.** Robar o eclosionar criaturas, ponerlas en la base, ganar aunque no estés conectado y coleccionar. Es lo más jugado ahora (Robar un huevo, Roba un Brainrot), pero también lo más saturado.
3. **Trabajo con anomalías (Survival).** Revisar, detectar lo raro y decidir. Atrae mucho (2 472 M de visitas en Hospital de Animales), aunque casi todos tienen tono de terror.
4. **Obbies cooperativos de 1 a 4 jugadores con un truco físico compartido.** Valoración alta (89–95 %) y crecimiento rápido, pero se terminan.
5. **Incrementales "+1".** Valoración alta, pero muy parecidos entre sí.

### Huecos
- **Producción en equipo dentro de un tycoon de tarea satisfactoria.** En las referencias de la tendencia 1, los amigos están presentes como empleados o compartiendo servidor, pero el trabajo es de uno solo (fila "Construye un imperio de teléfonos"). Un taller donde los amigos realmente se reparten los pasos no aparece en los Charts revisados.
- **Anomalías sin terror,** aptas para cualquier edad. Las cuatro de la tabla usan el miedo como gancho.

### Hipótesis (sin verificar; no suman en el criterio de evidencia)
- Que no exista ya un tycoon cooperativo de cocina o fabricación muy jugado. Solo se revisaron las listas de Charts del 2026-10-26, no la búsqueda.
- Que las tendencias se mantengan igual en teléfono. No se pudo fijar el filtro de dispositivo.
- Que existan juegos de "escalada atados con cuerda" en Roblox (concepto 2). Es un formato conocido fuera de Roblox; no se buscó.
- Cuántos jugadores tienen menos de 16. Las cifras de Charts no dan edades.

## Conceptos

### 1. Cocina en Cadena (nombre de trabajo)
- **Gancho:** "Tu puesto de comida con amigos: cada uno hace un paso y los pedidos vuelan". Thumbnail: tres avatares pasándose una pizza humeante en una cinta.
- **Loop central:** tocar una estación (amasar, hornear, decorar, entregar) → el plato avanza → el cliente paga → con las monedas se mejoran estaciones y se desbloquean recetas.
- **Primer minuto:**
  - 10 s: ya hay un pedido y una estación brillando; un toque, y la masa sale.
  - 30 s: primer plato entregado y monedas.
  - 60 s: primera mejora comprada.
- **Volver D2–7 / D8–28:** recetas nuevas por nivel del puesto, un libro de recetas para completar, pedidos especiales diarios y ganancias del puesto aunque no estés conectado (con tope).
- **Con amigos:**
  - Cada amigo toma una estación y la producción se multiplica.
  - El puesto es del dueño, pero los amigos ganan lo mismo por pedido.
  - Se puede jugar solo: las estaciones libres se usan en orden.
- **Diferenciación:** las referencias de la tendencia 1 (lavar coches, alfombras, teléfonos) son de un solo jugador; acá la cadena de producción es el juego en equipo.
- **Monetización honesta:**
  - Cosméticos del puesto y gorros de cocinero, que los demás ven.
  - Un pase que ahorra tiempo: una estación que trabaja sola.
  - Un pack de inicio único.
  - Sin cajas pagas.
- **Género / subgénero oficial:** Simulation / Tycoon.
- **Público y etiqueta esperada:** todas las edades (comida, sin violencia ni terror). Sale primero a 16+ y puede abrirse después sin cambiar el núcleo.
- **Alcance:**
  - Ya está en la plantilla: monedas, tienda, inventario (recetas y cosméticos), onboarding y HUD.
  - Hay que construir: estaciones con ProximityPrompt validadas en el servidor, cola de pedidos, puesto por jugador y reparto de ganancias.
  - MVP estimado: 3 semanas.
- **Riesgos:**
  - Que coordinarse en el teléfono sea confuso.
  - Que solo sea aburrido (la mayoría llega sola).
  - Que la ganancia sin estar conectado inflacione la economía.

### 2. Escalada Encordada
- **Gancho:** "2 a 4 amigos atados con una cuerda: si uno cae, tira a todos".
- **Loop central:** saltar juntos → checkpoint → más altura → récord del grupo.
- **Primer minuto:** se salta en 5 s; la primera caída compartida llega antes de los 30 s.
- **Volver D2–7 / D8–28:** tramos nuevos por update y récords semanales. Se termina rápido.
- **Con amigos:** es el núcleo; solo casi no tiene sentido.
- **Diferenciación:** baja, porque el formato existe fuera de Roblox y en la tendencia 4 ya hay "llevar algo juntos".
- **Monetización honesta:** solo cosméticos. Un "saltar tramo" pago sería una ventaja injusta, así que no se hace.
- **Género / subgénero oficial:** Obby & platformer / Tower Obby.
- **Público y etiqueta esperada:** todas las edades.
- **Alcance:** física de cuerda entre jugadores, nueva y difícil de que se sienta bien con lag. La plantilla aporta poco.
- **Riesgos:** física en móvil de gama baja, poco motivo para volver e ingresos bajos.

### 3. Aduana de Mascotas (anomalías sin terror)
- **Gancho:** "Revisá los pasaportes de las mascotas: ¿es un perro… o algo que se hace pasar por perro?".
- **Loop central:** revisar a la mascota que llega y sus papeles → aprobar o rechazar → paga por acierto → mejorar el puesto y el escáner.
- **Primer minuto:** la primera mascota llega en 10 s y una tarjeta muestra una regla; la primera decisión, antes de 30 s.
- **Volver D2–7 / D8–28:** un turno diario con anomalías nuevas, rangos de inspector y un álbum de anomalías encontradas.
- **Con amigos:** dos cabinas en paralelo con una fila compartida. Es un co-op leve.
- **Diferenciación:** el formato de anomalías existe (4 referencias); el giro es sin terror y con mascotas.
- **Monetización honesta:** cosméticos de uniforme y cabina, y un pase de "lupa rápida" que ahorra tiempo sin dar respuestas.
- **Género / subgénero oficial:** Survival es el que usan las referencias, aunque sin terror quizás encaje mejor en Simulation; decidirlo con el prototipo.
- **Público y etiqueta esperada:** todas las edades si las anomalías son graciosas y no dan miedo.
- **Alcance:** mucho contenido (variantes de mascota, papeles, reglas) y mucho arte. La plantilla aporta monedas y tienda.
- **Riesgos:** sin el miedo puede perder el gancho que hace funcionar a las referencias; además, el contenido se agota.

### 4. Pesca de Acuario
- **Gancho:** "Pescá peces raros y llená tu acuario: cada pez te paga".
- **Loop central:** lanzar y recoger con un minijuego de un toque → poner el pez en el acuario → ingresos → mejor caña y nuevas zonas.
- **Primer minuto:** se lanza en menos de 10 s y el primer pez sale antes de 30 s.
- **Volver D2–7 / D8–28:** colección por rareza, peces de temporada e ingresos aunque no estés conectado (con tope).
- **Con amigos:** visitar acuarios y pescar en el mismo lago. Sin intercambio en el MVP, por el riesgo de estafas.
- **Diferenciación:** media o baja; en "Más jugadas ahora" ya están ¡Atrapa peces! (71,4K) y Pez (63,5K).
- **Monetización honesta:** acuarios y cañas cosméticas, y un pase de cebo que ahorra tiempo.
- **Género / subgénero oficial:** Simulation / Incremental Simulator.
- **Público y etiqueta esperada:** todas las edades.
- **Alcance:** encaja perfecto con el inventario de la plantilla, y el minijuego es simple. MVP de 2 a 3 semanas.
- **Riesgos:** competir con juegos de pesca grandes y ya instalados.

## Puntuación
Pesos de `skills/roblox-ideation/references/scoring.md`. Puntos de 0 a 5; aporte = puntos / 5 × peso.

| Criterio (peso) | 1 Cocina en Cadena | 2 Escalada Encordada | 3 Aduana de Mascotas | 4 Pesca de Acuario |
|---|---|---|---|---|
| 1 Primer minuto (15) | 4 — un toque a los 10 s, aunque hay que caminar a la estación | 4 — se salta enseguida | 3 — hay que leer una regla antes de decidir | 4 — lanzar es inmediato |
| 2 Loop central (15) | 5 — cocinar, cobrar y mejorar, con progreso visible | 3 — la altura es el único motor | 4 — revisar, cobrar y mejorar el escáner | 5 — pescar, colocar, cobrar y mejorar |
| 3 Volver D2–7 / D8–28 (15) | 3 — recetas, libro, pedidos diarios | 2 — se termina | 4 — turnos diarios, álbum, rangos | 4 — colección y temporadas |
| 4 Con amigos (10) | 5 — la cadena es mejor con amigos | 5 — es el núcleo | 3 — cabinas en paralelo | 3 — visitar y pescar juntos |
| 5 Diferenciación (10) | 4 — tycoon de tarea en cooperación | 2 — formato conocido | 4 — anomalías sin terror | 2 — pesca muy cubierta |
| 6 Evidencia (10) | 4 — 4 referencias de la tendencia 1 con datos | 4 — 2 referencias cooperativas con datos | 5 — 4 referencias con datos fuertes | 4 — 2 juegos de pesca en el top con datos |
| 7 Monetización honesta (10) | 4 — cosméticos visibles y un pase que ahorra tiempo | 2 — solo cosméticos | 4 — cosméticos y pase de tiempo | 4 — cosméticos y pase de cebo |
| 8 Alcance (10) | 3 — estaciones, pedidos y reparto nuevos | 3 — física de cuerda riesgosa | 2 — mucho contenido y arte | 4 — encaja con la plantilla |
| 9 Móvil (5) | 4 — un toque por estación | 2 — saltos precisos y física | 4 — toques y UI grande | 5 — un toque |
| **Total /100** | **80** | **61** | **73** | **78** |

Cortes duros (0 en primer minuto, diferenciación o monetización): ninguno. Ningún concepto tiene en su núcleo algo que deje afuera a menores de 16.

## Recomendación
**Concepto 1, Cocina en Cadena (80/100).** Es el que mejor combina la tendencia que crece más rápido (tycoons de tarea satisfactoria) con un hueco claro: hacerlo en equipo. Además suma co-play, que el algoritmo mide desde junio de 2026. Le sigue Pesca de Acuario (78), que es más fácil de construir pero se diferencia menos.

**Hipótesis a validar primero en el prototipo** (guía oficial *Prototyping*): ¿la cadena de estaciones es divertida **solo** en los primeros 60 s, y se nota que es mejor con un amigo? Prototipo mínimo: 3 estaciones, 1 receta, pedidos que llegan solos y dos cuentas de prueba en Studio. Si solo aburre, el concepto 4 pasa a ser el plan B.

Siguiente paso, si se aprueba: `roblox-game-cloner` escribe `games/prueba/docs/spec.md` y copia la plantilla en `games/prueba/`.
