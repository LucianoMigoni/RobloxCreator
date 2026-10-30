--!strict
-- Revisión de recetas del armador: lo sano pasa y cada error común se nombra.
local TestKit = require("./TestKit")
local KNOWN = require("./KitKnown")
local KitCheck = require("../src/shared/Lib/KitCheck")
local Types = require("../src/shared/Kits/Types")

local equal = TestKit.equal

local function mini(): Types.KitConfig
	return {
		name = "Mini",
		currencies = { { id = "Wins", symbol = "", icon = "trophy", color = "#FFD23A", start = 0, purchasable = false } },
		leaderstats = { "Money", "Wins", "Rebirths", "Speed" },
		units = {
			label = "Pets",
			maxInventory = 50,
			mutations = true,
			list = {
				{ id = "Kitty", name = "Kitty", rarity = "Common", income = 1, value = 10, tier = 1, zone = "Meadow" },
				{ id = "Doggo", name = "Doggo", rarity = "Rare", income = 5, value = 50, tier = 2, zone = "Meadow" },
				{ id = "Dragon", name = "Dragon", rarity = "Secret", income = 100, value = 5000, tier = 3, zone = "Snow" },
			},
			zones = { { id = "Meadow", name = "Meadow", reward = { currency = "Gems", amount = 10 } }, { id = "Snow", name = "Snow" } } :: { Types.IndexZone },
			announceFrom = "Legendary",
			luckyFrom = "Rare",
		},
		plots = { count = 8, slots = 4, maxSlots = 6, slotPrices = { 100, 500 }, collect = "pad", autoCollectPass = "AutoCollect" },
		rolls = {
			list = {
				{
					id = "Basic",
					name = "Basic Egg",
					price = { currency = "Money", amount = 50 },
					pool = { { unit = "Kitty", weight = 90 }, { unit = "Dragon", weight = 1 } },
					amounts = { { count = 1 }, { count = 3, pass = "Luck2x" } } :: { Types.RollAmount },
					zone = "Meadow",
				},
			},
		},
		merge = { mode = "tier", count = 3 },
		sell = { keepFrom = "Legendary" },
		stats = { { id = "Speed", label = "Speed", perStep = 1 } },
		zones = { list = { { id = "Meadow", name = "Meadow", order = 1 }, { id = "Snow", name = "Snow", order = 2, stat = { id = "Speed", value = 1000 } } } :: { Types.ZoneDef } },
		upgrades = {
			{ id = "Slots", name = "More Slots", desc = "+1 slot", effect = "slots", per = 1, maxLevel = 2, prices = { 100, 200 } },
			{ id = "Cash", name = "Cash", desc = "+10% Money", effect = "stat:Money", per = 0.1, maxLevel = 10, base = 100, growth = 1.5 },
		} :: { Types.UpgradeDef },
		quests = {
			{ id = "a", text = "Hatch %s eggs", stat = "Hatch", target = 10, reward = { item = "Unit:Kitty:Gold" } },
			{ id = "b", text = "Earn %s", stat = "MoneyEarned", target = 1000, money = true, reward = { currency = "Gems", amount = 5 } },
			{ id = "c", text = "Merge %s times", stat = "Merge", target = 3, reward = { item = "Roll:Basic", count = 3 } },
		} :: { Types.Quest },
		map = { theme = "meadow" },
	}
end

local function has(errors: { string }, fragment: string): boolean
	for _, e in errors do
		if string.find(e, fragment, 1, true) then
			return true
		end
	end
	return false
end

local function expect(errors: { string }, fragment: string)
	if not has(errors, fragment) then
		error("falta el problema '" .. fragment .. "' en:\n  " .. table.concat(errors, "\n  "), 2)
	end
end

TestKit.run("KitCheck", {
	["una receta sin bloques está bien"] = function()
		equal(#KitCheck.check({ name = "None" }, KNOWN), 0)
	end,

	["una receta completa y sana no tiene problemas"] = function()
		local errors = KitCheck.check(mini(), KNOWN)
		if #errors > 0 then
			error("problemas inesperados:\n  " .. table.concat(errors, "\n  "))
		end
	end,

	["los bloques salen en orden de arranque"] = function()
		equal(table.concat(KitCheck.blocks(mini()), ","), "upgrades,units,stats,zones,plots,sell,merge,rolls")
	end,

	["un bloque sin el bloque que necesita"] = function()
		local recipe = mini()
		recipe.units = nil
		local errors = KitCheck.check(recipe, KNOWN)
		expect(errors, "rolls: necesita el bloque units")
		expect(errors, "plots: espacios para unidades sin el bloque units")
		expect(errors, "unidad 'Kitty' no existe")
	end,

	["ids repetidos o con caracteres raros"] = function()
		local recipe = mini()
		local units = recipe.units :: Types.UnitsConfig
		table.insert(units.list, { id = "Kitty", name = "Kitty 2", rarity = "Common" })
		table.insert(units.list, { id = "Bad Id", name = "Bad", rarity = "Common" })
		local errors = KitCheck.check(recipe, KNOWN)
		expect(errors, "id repetido 'Kitty'")
		expect(errors, "'Bad Id' con caracteres no permitidos")
	end,

	["rarezas, monedas, pases e impulsos que no existen"] = function()
		local recipe = mini()
		local units = recipe.units :: Types.UnitsConfig
		units.list[1].rarity = "Mitic"
		local rolls = recipe.rolls :: Types.RollsConfig
		rolls.list[1].price = { currency = "Coins", amount = 5 }
		rolls.list[1].amounts[2].pass = "Octo"
		recipe.items = { maxStack = 10, list = { { id = "Potion", name = "Potion", icon = "luck", boost = "Luck9x", seconds = 60 } } }
		local errors = KitCheck.check(recipe, KNOWN)
		expect(errors, "rareza 'Mitic' no existe")
		expect(errors, "moneda 'Coins' no existe")
		expect(errors, "pase 'Octo' no existe")
		expect(errors, "impulso 'Luck9x' no existe")
	end,

	["premios por ítem"] = function()
		local recipe = mini()
		equal(KitCheck.item(recipe, KNOWN, "Unit:Kitty"), nil)
		equal(KitCheck.item(recipe, KNOWN, "Unit:Kitty:Gold:Huge"), nil)
		equal(KitCheck.item(recipe, KNOWN, "Roll:Basic"), nil)
		equal(KitCheck.item(recipe, KNOWN, "Upgrade:Slots"), nil)
		equal(KitCheck.item(recipe, KNOWN, "Merge:Skip"), nil)
		equal(KitCheck.item(recipe, KNOWN, "Zone:Snow"), nil)
		equal(KitCheck.item(recipe, KNOWN, "Stat:Speed"), nil)
		TestKit.truthy(KitCheck.item(recipe, KNOWN, "Unit:Nope"), "unidad que no existe")
		TestKit.truthy(KitCheck.item(recipe, KNOWN, "Unit:Kitty:Shiny"), "mutación que no existe")
		TestKit.truthy(KitCheck.item(recipe, KNOWN, "Egg:Basic"), "prefijo desconocido")
		TestKit.truthy(KitCheck.item(recipe, KNOWN, "Garden:Skip"), "bloque apagado")
		TestKit.truthy(KitCheck.item(recipe, KNOWN, "Merge:Now"), "solo Merge:Skip")
		TestKit.truthy(KitCheck.item(recipe, KNOWN, "Kitty"), "sin prefijo")
		recipe.quests = {
			{ id = "a", text = "x", stat = "Hatch", target = 1, reward = { item = "Seed:Carrot" } },
			{ id = "b", text = "x", stat = "Hatch", target = 1, reward = { currency = "Gems", amount = 1 } },
			{ id = "c", text = "x", stat = "Hatch", target = 1, reward = { boost = "Money2x" } },
		} :: { Types.Quest }
		local errors = KitCheck.check(recipe, KNOWN)
		expect(errors, "quests[1].reward.item: 'Seed:Carrot' necesita el bloque garden")
		expect(errors, "quests[3].reward.seconds")
	end,

	["la fusión por nivel no deja huecos"] = function()
		local recipe = mini()
		local units = recipe.units :: Types.UnitsConfig
		units.list[2].tier = 4
		expect(KitCheck.check(recipe, KNOWN), "falta una unidad de nivel 2")
		local variant = mini()
		variant.merge = { mode = "variant", count = 5, variantChain = { "Normal", "Platinum" } }
		expect(KitCheck.check(variant, KNOWN), "mutación 'Platinum' no existe")
	end,

	["lo que se paga con moneda comprada es aleatorio pago"] = function()
		local recipe = mini()
		recipe.currencies = { { id = "Tokens", symbol = "", icon = "gem", color = "#2EC5F5", start = 0, purchasable = true } }
		recipe.leaderstats = nil
		local rolls = recipe.rolls :: Types.RollsConfig
		rolls.list[1].price = { currency = "Tokens", amount = 10 }
		expect(KitCheck.check(recipe, KNOWN), "marcarla paidRandom")
		rolls.list[1].paidRandom = true
		equal(has(KitCheck.check(recipe, KNOWN), "paidRandom"), false)
	end,

	["la primera zona está abierta y las referencias existen"] = function()
		local recipe = mini()
		local zones = recipe.zones :: Types.ZonesConfig
		zones.list[1].price = { currency = "Money", amount = 100 }
		zones.list[2].stat = { id = "Strength", value = 5 }
		local errors = KitCheck.check(recipe, KNOWN)
		expect(errors, "la primera zona ('Meadow') tiene que estar abierta")
		expect(errors, "estadística 'Strength' no existe")
	end,

	["mejoras de bloques apagados y escaleras incompletas"] = function()
		local recipe = mini()
		local upgrades = recipe.upgrades :: { Types.UpgradeDef }
		table.insert(upgrades, { id = "Bag", name = "Bag", desc = "+5", effect = "bag", per = 5, maxLevel = 3, prices = { 1, 2 } })
		table.insert(upgrades, { id = "Odd", name = "Odd", desc = "?", effect = "fly", per = 1, maxLevel = 1, prices = { 1 } })
		local errors = KitCheck.check(recipe, KNOWN)
		expect(errors, "'bag' necesita el bloque search")
		expect(errors, "tiene 2 precios y 3 niveles")
		expect(errors, "efecto 'fly' no existe")
	end,

	["monedas de la receta, tabla de jugadores y tema"] = function()
		local recipe = mini()
		recipe.currencies = { { id = "Gems", symbol = "", icon = "gem", color = "blue", start = 0, purchasable = false } }
		recipe.leaderstats = { "Money", "Fame" }
		recipe.map = { theme = "underwater" }
		local errors = KitCheck.check(recipe, KNOWN)
		expect(errors, "'Gems' ya es una moneda del núcleo")
		expect(errors, "color en hex")
		expect(errors, "'Fame' no es una moneda")
		expect(errors, "tema 'underwater' no existe")
	end,
})
