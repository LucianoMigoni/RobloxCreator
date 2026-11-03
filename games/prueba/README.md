# Steal & Fuse Critters (`games/prueba`)

Juego de prueba del hub. Concepto: `docs/concepto.md`; spec: `docs/spec.md`.

**Rehecho con el armador el 2026-11-03.** Es una copia de la plantilla actual con su receta propia en `src/shared/Config/KitConfig.luau`. La receta usa estos bloques: unidades (8 critters en niveles), bases con traba, cinta compartida, robo y empujón, y fusión de dos iguales.

- **Lo que pedía la spec y todavía no está en el armador:** `docs/decisiones.md`.
- **Íconos de los critters:** hechos con ChatGPT, en `assets/ui/unit-icons/critters`. Mientras no se suban a Roblox, la UI muestra el emoji de respaldo de `src/shared/Icons.luau`.
- **Mapa:** lo arma MapKit al arrancar. La vista previa sin Studio está en `docs/mapa-hero.jpg` y `docs/mapa-top.jpg`, y se genera así:
  ```
  node tools/render3d/mapview.cjs --recipe games/prueba/src/shared/Config/KitConfig.luau --out games/prueba/docs/mapa
  ```

## Probar en Studio

1. `rokit install` y `rojo serve` en esta carpeta. En Studio: Plugins → Rojo → Connect.
2. Play. El servidor arma el mapa: plaza, bases, cinta y cerros.
3. Mirar el loop de la spec en orden:
   - el objetivo de arriba guía cada paso;
   - comprar en la cinta;
   - juntar en la placa verde;
   - fusionar dos iguales;
   - robar de otra base (con dos jugadores: pestaña Test → menú desplegable → Server & Clients, con 2 clientes);
   - trabar la base y renacer.
4. Para editar el mapa a mano:
   1. Durante Play, copiar `Workspace.Map`.
   2. Parar y pegarlo en Workspace.
   3. MapKit ya no arma otro y se puede decorar libremente; basta con mantener las etiquetas.

El guardado de datos se prueba solo en una copia del lugar con *Enable Studio Access to API Services* (`skills/roblox-security`).

## Qué trae

Todo lo de la plantilla (`template/README.md`): núcleo de economía, retención, tienda, UI estilo hit y los 18 bloques del armador. Este juego activa solo los de su receta. Para cambiar números, nombres o el mapa, se edita `KitConfig.luau`; `tools/check.py` la valida con `tests/KitConfig.spec.luau`.
