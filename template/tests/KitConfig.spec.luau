--!strict
-- La receta activa del juego (Config/KitConfig): sana para KitCheck, con mapa sano y completo si trae
-- `map`, e íconos con respaldo. En la plantilla la receta es "None" y no hay nada que revisar; en cada
-- juego (copia de la plantilla) revisa la suya.
local TestKit = require("./TestKit")
local KNOWN = require("./KitKnown")
local MapExpect = require("./MapExpect")
local Icons = require("../src/shared/Icons")
local KitConfig = require("../src/shared/Config/KitConfig")
local KitCheck = require("../src/shared/Lib/KitCheck")
local MapPlan = require("../src/shared/Lib/MapPlan")
local Types = require("../src/shared/Kits/Types")

local equal = TestKit.equal
local truthy = TestKit.truthy

local recipe: Types.KitConfig = KitConfig

TestKit.run("KitConfig", {
	["la receta del juego pasa KitCheck"] = function()
		local errors = KitCheck.check(recipe, KNOWN)
		equal(#errors, 0, recipe.name .. ": " .. table.concat(errors, "; "))
	end,

	["su mapa está sano y completo"] = function()
		if not recipe.map then
			return
		end
		local plan = MapPlan.build(recipe)
		local problems = MapPlan.audit(plan)
		equal(#problems, 0, table.concat(problems, "; "))
		local missing = MapExpect.check(recipe, plan)
		equal(#missing, 0, table.concat(missing, "; "))
	end,

	["sus íconos se ven antes de subir las imágenes"] = function()
		local units = recipe.units
		local list: { Types.UnitDef } = if units then units.list else {}
		for _, u in list do
			local icon = u.icon
			if icon then
				truthy(Icons.hasFallback(icon) or string.sub(icon, 1, 13) == "rbxassetid://", u.id .. ": el ícono '" .. icon .. "' no tiene emoji de respaldo (Icons.luau)")
			end
		end
	end,
})
