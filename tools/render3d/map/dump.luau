--!strict
-- Vuelca a JSON (salida estándar) el plan del mapa de una receta del armador, para la vista previa
-- (tools/render3d/mapview.cjs). La ruta del módulo de la receta va relativa a este archivo:
--   luau tools/render3d/map/dump.luau -a ../../../template/src/shared/Config/KitConfig

local MapPlan = require("../../../template/src/shared/Lib/MapPlan")

local args = { ... }
local path = args[1]
if typeof(path) ~= "string" then
	error("falta la ruta de la receta (relativa a tools/render3d/map/)")
end
local recipe = (require :: any)(path)

local function encode(value: any, out: { string })
	local kind = typeof(value)
	if kind == "nil" then
		table.insert(out, "null")
	elseif kind == "boolean" then
		table.insert(out, if value then "true" else "false")
	elseif kind == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			table.insert(out, "0")
		elseif value == math.floor(value) and math.abs(value) < 1e15 then
			table.insert(out, string.format("%d", value))
		else
			table.insert(out, string.format("%.4f", value))
		end
	elseif kind == "string" then
		local escaped = string.gsub(value, '[%c"\\]', function(c: string): string
			if c == '"' or c == "\\" then
				return "\\" .. c
			end
			return string.format("\\u%04x", string.byte(c))
		end)
		table.insert(out, '"' .. escaped .. '"')
	elseif kind == "table" then
		if #value > 0 or next(value) == nil then
			table.insert(out, "[")
			for i, item in value do
				if i > 1 then
					table.insert(out, ",")
				end
				encode(item, out)
			end
			table.insert(out, "]")
		else
			table.insert(out, "{")
			local first = true
			for key, item in value do
				if not first then
					table.insert(out, ",")
				end
				first = false
				encode(tostring(key), out)
				table.insert(out, ":")
				encode(item, out)
			end
			table.insert(out, "}")
		end
	else
		table.insert(out, "null")
	end
end

local plan = MapPlan.build(recipe)
local out = {}
encode({ recipe = recipe.name, theme = plan.theme, palette = plan.palette, groups = plan.groups, parts = plan.parts, warnings = plan.warnings }, out)
print(table.concat(out))
