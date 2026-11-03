--!strict
-- Las recetas listas de Kits/Presets: sanas para KitCheck (con las listas del núcleo), con objetivos y
-- misiones que enseñan su loop, mapa sano y completo, íconos con respaldo y una economía que arranca
-- (lo primero se puede pagar con la plata inicial).
local TestKit = require("./TestKit")
local KNOWN = require("./KitKnown")
local MapExpect = require("./MapExpect")
local Icons = require("../src/shared/Icons")
local KitCheck = require("../src/shared/Lib/KitCheck")
local MapPlan = require("../src/shared/Lib/MapPlan")
local Types = require("../src/shared/Kits/Types")

local equal = TestKit.equal
local truthy = TestKit.truthy

-- EconomyConfig.CURRENCIES.Money.start (EconomyConfig usa Color3: el CLI no lo puede cargar).
local START_MONEY = 10

local PRESETS: { [string]: Types.KitConfig } = {
	StealAndPlace = require("../src/shared/Kits/Presets/StealAndPlace"),
	HatchAndCollect = require("../src/shared/Kits/Presets/HatchAndCollect"),
	PlusOneEscape = require("../src/shared/Kits/Presets/PlusOneEscape"),
}

-- Plata con la que arranca un jugador en una moneda (las de la receta traen su `start`).
local function startOf(recipe: Types.KitConfig, currency: string): number
	if currency == "Money" then
		return START_MONEY
	end
	for _, c in recipe.currencies or ({} :: { Types.CurrencyDef }) do
		if c.id == currency then
			return c.start
		end
	end
	return 0
end

local function unitById(recipe: Types.KitConfig, id: string): Types.UnitDef?
	local units = recipe.units
	if units then
		for _, u in units.list do
			if u.id == id then
				return u
			end
		end
	end
	return nil
end

TestKit.run("Presets", {
	["cada receta pasa KitCheck"] = function()
		for name, recipe in PRESETS do
			equal(recipe.name, name, "el nombre de la receta es el del archivo")
			local errors = KitCheck.check(recipe, KNOWN)
			equal(#errors, 0, name .. ": " .. table.concat(errors, "; "))
		end
	end,

	["objetivos y misiones que enseñan el juego"] = function()
		for name, recipe in PRESETS do
			truthy(recipe.objectives and #recipe.objectives >= 5, name .. ": al menos 5 objetivos (el tutorial)")
			truthy(recipe.quests and #recipe.quests >= 4, name .. ": al menos 4 misiones (se eligen 3 por día)")
		end
	end,

	["mapa sano y completo"] = function()
		for name, recipe in PRESETS do
			truthy(recipe.map ~= nil, name .. ": trae mapa")
			local plan = MapPlan.build(recipe)
			local problems = MapPlan.audit(plan)
			equal(#problems, 0, name .. ": " .. table.concat(problems, "; "))
			local missing = MapExpect.check(recipe, plan)
			equal(#missing, 0, name .. ": " .. table.concat(missing, "; "))
			truthy(#plan.parts < 5000, name .. ": " .. #plan.parts .. " partes")
		end
	end,

	["cada unidad con ícono que se ve antes de subir las imágenes"] = function()
		for name, recipe in PRESETS do
			local units = recipe.units
			local list: { Types.UnitDef } = if units then units.list else {}
			for _, u in list do
				local icon = u.icon
				truthy(icon ~= nil, name .. ": " .. u.id .. " sin ícono")
				if icon then
					truthy(Icons.hasFallback(icon), name .. ": el ícono '" .. icon .. "' no tiene emoji de respaldo (Icons.luau)")
				end
			end
		end
	end,

	["lo primero se paga con la plata inicial"] = function()
		for name, recipe in PRESETS do
			local cheapest = math.huge
			local currency = "Money"
			local belt = recipe.belt
			if belt then
				for _, entry in belt.pool do
					local u = unitById(recipe, entry.unit)
					if u then
						cheapest = math.min(cheapest, u.price or u.value or math.huge)
					end
				end
			end
			local rolls = recipe.rolls
			if rolls then
				for _, roll in rolls.list do
					local price = roll.price
					if price == nil then
						cheapest = 0 -- gratis cada tanto
					elseif price.amount <= startOf(recipe, price.currency) then
						cheapest = math.min(cheapest, price.amount)
						currency = price.currency
					end
				end
			end
			local garden = recipe.garden
			if garden then
				for _, seed in garden.seeds do
					if seed.price.amount <= startOf(recipe, seed.price.currency) then
						cheapest = math.min(cheapest, seed.price.amount)
					end
				end
			end
			local tycoon = recipe.tycoon
			if tycoon then
				cheapest = math.min(cheapest, tycoon.buildings[1].price.amount)
			end
			-- Pescar, revolver, capturar y correr no cuestan nada.
			if recipe.fishing or recipe.search or recipe.wild or recipe.stats then
				cheapest = 0
			end
			truthy(cheapest <= startOf(recipe, currency), name .. ": lo primero cuesta " .. tostring(cheapest))
		end
	end,
})
