--!strict
-- Receta del juego: qué bloques de juego usa y cómo (qué hace cada uno:
-- skills/roblox-game-kits/references/bloques.md). Todo lo demás (diario, tienda, ruleta, índice...)
-- es el núcleo y está siempre.
--
-- Para armar un juego, devolver una receta de Kits/Presets (StealAndPlace, HatchAndCollect,
-- PlusOneEscape, Fishing, SearchAndDig, GrowGarden, MergeTycoon, RunAndCatch, CozyTycoon):
--   return require("../Kits/Presets/StealAndPlace")
-- o, mejor, copiar su contenido acá y hacerlo propio (nombres, unidades, precios, zonas, mapa): las
-- recetas son muestras de cada fórmula. Es solo datos: colores en hex, sin Color3 ni Vector3.
-- tools/check.py valida cada receta (tests/Presets.spec.luau) y el servidor la vuelve a validar al
-- arrancar con las monedas, rarezas y pases reales. Vista previa del mapa sin Studio:
--   node tools/render3d/mapview.cjs --recipe template/src/shared/Config/KitConfig.luau --out mapa
-- Sin bloques ({ name = "None" }), la plantilla corre solo con el núcleo.

local Types = require("../Kits/Types")

local recipe: Types.KitConfig = { name = "None" }

return recipe
