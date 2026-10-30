--!strict
-- Receta del juego: qué bloques de juego usa y cómo (qué hace cada uno:
-- skills/roblox-game-kits/references/bloques.md). Todo lo demás (diario, tienda, ruleta, índice...)
-- es el núcleo y está siempre.
--
-- Para armar un juego, devolver una receta de Kits/Presets:
--   return require("../Kits/Presets/StealAndPlace")
-- o copiar su contenido acá y editarlo (nombres, unidades, precios, zonas). Es solo datos: colores en
-- hex, sin Color3 ni Vector3. tools/check.py valida cada receta (tests/Presets.spec.luau) y el
-- servidor la vuelve a validar al arrancar con las monedas, rarezas y pases reales.
-- Sin bloques ({ name = "None" }), la plantilla corre solo con el núcleo.

local Types = require("../Kits/Types")

local recipe: Types.KitConfig = { name = "None" }

return recipe
