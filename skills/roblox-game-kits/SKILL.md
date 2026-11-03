---
name: roblox-game-kits
description: Arma un juego estilo top hit con el armador de la plantilla. Se elige la fórmula (robar y colocar, huevos, +1 y escape, pesca, buscar, cultivo, fusión, correr y atrapar o tycoon), se copia su receta y se hace propia (unidades, números, tienda, objetivos y mapa). Después se valida, se mira el mapa sin Studio, se le pone arte con IA y se prueba. Usar en la fase 2 cuando el concepto encaja en una fórmula, para agregar una opción o un bloque nuevo al armador, o cuando el usuario pide "un juego como X" de un género conocido.
---

# roblox-game-kits (el armador)

## Objetivo
Pasar de un concepto aprobado a un juego jugable en horas, no en semanas.
- **El núcleo ya está hecho y probado:** datos, economía, retención, tienda y UI estilo hit.
- **El juego se arma eligiendo bloques** en una receta (`src/shared/Config/KitConfig.luau`), que es solo datos.
- **El mapa lo arma MapKit** con el estilo de los hits.
- **Lo que hace único al juego** va en la receta y en los assets: tema, unidades, arte, nombres, números y el giro propio.

Diseño completo de bloques, etiquetas del mapa y fórmulas: `references/bloques.md`.

## Cuándo usarlo
- Fase 2, cuando el concepto (`docs/concepto.md`) encaja en una de las fórmulas (`references/bloques.md`, "Las fórmulas, armadas").
- Para agregar una mecánica que falta: una opción nueva en un bloque o un bloque nuevo.
- No alcanza para géneros sin bloque (shooter, carreras con física, rol libre). Ahí, `roblox-game-cloner` sobre el núcleo.

**Lo llaman:** `roblox-game-cloner` (fase 2), `roblox-ideation` (qué fórmula usa cada concepto) o el usuario.
**Llama a:**
- `roblox-ui-designer`: solo si hay UI nueva;
- `roblox-game-feel`: sonido, animación y efectos de cada momento nuevo;
- `roblox-security`: remotes nuevos;
- `roblox-monetization`: precios y tienda;
- `roblox-qa-performance`: prueba en Studio;
- `roblox-publishing`: vitrina (íconos de las unidades y la unidad gigante del mapa).

## Flujo
1. **Elegir la fórmula.** Usar la tabla "Las fórmulas, armadas" de `references/bloques.md` y `skills/_shared/hits-2026.md`. Mostrarle al usuario la vista previa de los nueve mapas (`references/mapa/recetas.jpg`).
2. **Copiar la receta.** Pasar `template/src/shared/Kits/Presets/<Receta>.luau` a `games/<juego>/src/shared/Config/KitConfig.luau` y cambiar `name`. El juego es una copia de la plantilla: `CLAUDE.md`, "Empezar un juego nuevo".
3. **Hacerla propia**, en este orden:
   1. **Tema y giro:** `map.theme`, los nombres de las zonas (dan el bioma: "Snowy Peaks", "Coral Reef") y `units.label`.
   2. **Unidades:**
      - ids en PascalCase, que no cambian después de publicar;
      - nombres en inglés y rarezas;
      - números: ingreso, valor, poder, nivel, peso y requisito;
      - `icon`.
   3. **Economía:**
      - lo primero se paga con los $10 iniciales;
      - cuidar los primeros 10, 60 y 180 s (el algoritmo mira el rebote antes de 60 s: `skills/_shared/algoritmo-descubrimiento.md`);
      - el primer renacer, entre 25 y 40 min;
      - sin plata, `rebirth` propio.
   4. **Objetivos:**
      - el tutorial sin pantallas, un paso por cada acción del loop;
      - después, `endless` y al menos 4 misiones;
      - los eventos tienen que estar en `KitCheck.SIGNALS` o ser `"<Stat>Gained"`.
   5. **Tienda:** pases y productos propios en `shop`, con el efecto exacto en `desc` (regla oficial). Lo aleatorio que se paga con moneda comprada va con `paidRandom` (`roblox-monetization`).
   6. **Mapa:** `map.shops`, `bases` (`pen` o `building`), `backdrop`, `showcase`, `treadmills`, `leaderboard`, `groupChest`, `spin` y `nextUpdate`.
4. **Validar.** `python tools/check.py` corre `tests/KitConfig.spec.luau` del juego:
   - KitCheck con las listas del núcleo;
   - el mapa sano y completo;
   - los íconos con respaldo.

   Cada error dice el campo y qué falta.
5. **Ver el mapa sin Studio** y mostrarlo:
   `node tools/render3d/mapview.cjs --recipe games/<juego>/src/shared/Config/KitConfig.luau --out games/<juego>/docs/mapa`
6. **Arte con IA** (`skills/_shared/iconos/README.md`):
   - íconos de las unidades: receta `unidades-*.json`, 9 por hoja, con referencia de estilo propia;
   - fotos de las zonas y arte de la tienda;
   - todo registrado en el catálogo.

   Los modelos 3D de las unidades (Blender o Meshy) van en `ReplicatedStorage.Assets.Units[def.model]`; sin modelo, cada unidad es una bola de su color.
7. **Probar en Studio** (`roblox-qa-performance`). Seguir el loop paso a paso con los objetivos de arriba. Para robar hacen falta dos jugadores: Test → Clients and Servers.
8. **Hacer propio el mapa** cuando haga falta más que el generado:
   1. Play y copiar `Workspace.Map`.
   2. Stop y pegarlo en Workspace.
   3. Editarlo: agua de terreno, partículas, modelos y decorado.

   MapKit no arma otro si ya hay un `Map`. Hay que mantener las etiquetas y atributos (tabla de cada bloque en `references/bloques.md`).
9. **Mostrar** al usuario la receta, la vista previa y la captura de Studio, y esperar su visto bueno.

## Agregar al armador
- **Una opción en un bloque** (algo que pide un juego y le sirve a otros):
  - el tipo, en `Kits/Types.luau`;
  - la validación, en `Lib/KitCheck.luau`, con su test;
  - la lógica, en `server/Kits/<Bloque>.luau` (lo puro, en `Lib/` con test);
  - la UI, en `client/Kits/<Bloque>.luau`;
  - una línea en `references/bloques.md`.
- **Un bloque nuevo:** con las piezas comunes y la interfaz `init`/`start`/`snapshot`/`items` de `team/traspaso.md` §7. Además:
  - una fila en `KitCheck.BLOCKS` y en `NEEDS`;
  - el bloque en `server/Kits/Kits.luau` y en `client/Kits/Kits.luau`;
  - sus etiquetas en `Kits/Tags.luau`;
  - lo que necesite del mapa, en `Lib/MapPlan.luau` y en `tests/MapExpect.luau`;
  - sus productos con `kit = "<bloque>"` en `ShopConfig`;
  - sus eventos en `KitCheck.SIGNALS`.
- **Una receta nueva:**
  - el archivo en `Kits/Presets/`;
  - una entrada en `tests/Presets.spec.luau`;
  - los emojis de respaldo de sus íconos en `Icons.luau`;
  - su fila en "Las fórmulas, armadas".

## Reglas
- **Servidor autoritativo:** los bloques ya validan todo. Una opción nueva sigue igual: remote con validador y límite, y distancia medida en el servidor.
- **La receta es solo datos:** colores en hex, sin `Color3` ni `Vector3`, y ningún número suelto en la lógica.
- **Textos:** lo que ve el jugador va en inglés.
- **Nada de otros juegos:** nunca copiar su arte, sus nombres ni sus mapas; las fórmulas son mecánicas.
- **Arte:** íconos y arte siempre terminados con IA; un render base nunca es final.
- **Lo que falta va al backlog:** lo que la spec pide y el armador no tiene se anota en `games/<juego>/docs/decisiones.md`. Ese es el backlog del armador.

## Salida
- `games/<juego>/src/shared/Config/KitConfig.luau`, validada.
- `games/<juego>/docs/mapa-hero.jpg` y `mapa-top.jpg`.
- `games/<juego>/docs/decisiones.md`: cómo se cumple cada mecánica y lo que falta.

Ejemplo completo: `games/prueba` (Steal & Fuse Critters).
