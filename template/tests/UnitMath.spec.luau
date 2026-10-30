--!strict
-- Cuentas de las unidades: variantes que multiplican, nombre, índice, sorteos con suerte y peso.
local TestKit = require("./TestKit")
local KNOWN = require("./KitKnown")
local UnitMath = require("../src/shared/Lib/UnitMath")
local Types = require("../src/shared/Kits/Types")

local equal = TestKit.equal

-- Igual que RarityConfig (sin colores).
local MUTATIONS: { UnitMath.Variant } = {
	{ id = "Normal", weight = 1000, mult = 1 },
	{ id = "Gold", weight = 60, mult = 2, lucky = true },
	{ id = "Diamond", weight = 15, mult = 3, lucky = true },
	{ id = "Rainbow", weight = 4, mult = 5, lucky = true },
	{ id = "Galaxy", weight = 1, mult = 10, lucky = true },
}
local SIZES: { UnitMath.Variant } = {
	{ id = "Normal", weight = 900, mult = 1 },
	{ id = "Big", weight = 90, mult = 1.5, lucky = true },
	{ id = "Huge", weight = 10, mult = 3, lucky = true },
}

local DRAGON: Types.UnitDef = { id = "Dragon", name = "Dragon", rarity = "Secret", income = 100, value = 5000, power = 0.5 }
local TUNA: Types.UnitDef = { id = "Tuna", name = "Tuna", rarity = "Rare", value = 40, weight = { min = 10, max = 30 } }

local function fixed(value: number): () -> number
	return function()
		return value
	end
end

TestKit.run("UnitMath", {
	["la clave del índice lleva la mutación o Normal"] = function()
		equal(UnitMath.key("Dragon", "Gold"), "Dragon|Gold")
		equal(UnitMath.key("Dragon", nil), "Dragon|Normal")
	end,

	["mutación y tamaño multiplican ingreso, valor y poder"] = function()
		local unit: UnitMath.Unit = { uid = 1, kind = "Dragon", variant = "Gold", size = "Huge" }
		equal(UnitMath.multiplier(DRAGON, unit, MUTATIONS, SIZES), 6)
		equal(UnitMath.income(DRAGON, unit, MUTATIONS, SIZES), 600)
		equal(UnitMath.value(DRAGON, unit, MUTATIONS, SIZES), 30000)
		equal(UnitMath.power(DRAGON, unit, MUTATIONS, SIZES), 3)
		local plain: UnitMath.Unit = { uid = 2, kind = "Dragon" }
		equal(UnitMath.income(DRAGON, plain, MUTATIONS, SIZES), 100)
	end,

	["el peso medio vale x1 y el pesado más"] = function()
		equal(UnitMath.weightMult(TUNA, 20), 1)
		equal(UnitMath.weightMult(TUNA, 30), 1.5)
		equal(UnitMath.weightMult(DRAGON, 30), 1, "sin rango de peso no cambia")
		equal(UnitMath.value(TUNA, { uid = 3, kind = "Tuna", weight = 30 }, MUTATIONS, SIZES), 60)
	end,

	["nombre con tamaño y mutación, sin Normal"] = function()
		equal(UnitMath.name(DRAGON, { variant = "Gold", size = "Huge" }), "Huge Gold Dragon")
		equal(UnitMath.name(DRAGON, { variant = "Normal" }), "Dragon")
		equal(UnitMath.article("Epic"), "an")
		equal(UnitMath.article("SECRET"), "a")
	end,

	["el sorteo marca con suerte desde luckyFrom"] = function()
		local units: { [string]: Types.UnitDef } = {
			Kitty = { id = "Kitty", name = "Kitty", rarity = "Common" },
			Owl = { id = "Owl", name = "Owl", rarity = "Rare" },
			Dragon = DRAGON,
		}
		local pool: { Types.PoolEntry } = { { unit = "Kitty", weight = 90 }, { unit = "Owl", weight = 9 }, { unit = "Ghost", weight = 5 }, { unit = "Dragon", weight = 1 } }
		local entries = UnitMath.entries(pool, units, KNOWN.rarities, "Rare")
		equal(#entries, 3, "Ghost no existe")
		equal(entries[1].lucky, false)
		equal(entries[2].lucky, true)
		equal(entries[3].lucky, true)
		equal(UnitMath.rank(KNOWN.rarities, "Secret"), 7)
		equal(UnitMath.rank(KNOWN.rarities, nil), 0)
	end,

	["las variantes salen al azar con suerte"] = function()
		equal(UnitMath.rollVariant(MUTATIONS, 1, fixed(0)), nil, "lo primero es Normal")
		equal(UnitMath.rollVariant(MUTATIONS, 1, fixed(0.9999)), "Galaxy")
		-- Con suerte x10, Gold pesa 600 de 1000+600+150+40+10 = 1800: el 0.6 cae en Gold.
		equal(UnitMath.rollVariant(MUTATIONS, 10, fixed(0.6)), "Gold")
		equal(UnitMath.rollVariant({}, 1, fixed(0.5)), nil)
	end,

	["la mejor probabilidad sale de todos los sorteos"] = function()
		local recipe: Types.KitConfig = {
			name = "x",
			units = { label = "Pets", maxInventory = 10, list = { DRAGON, TUNA, { id = "Kitty", name = "Kitty", rarity = "Common" } } },
			rolls = {
				list = {
					{ id = "A", name = "A", cooldown = 1, pool = { { unit = "Kitty", weight = 3 }, { unit = "Dragon", weight = 1 } }, amounts = { { count = 1 } } },
					{ id = "B", name = "B", cooldown = 1, pool = { { unit = "Dragon", weight = 1 }, { unit = "Kitty", weight = 1 } }, amounts = { { count = 1 } } },
				},
			},
			fishing = { pools = { { id = "Sea", entries = { { unit = "Tuna", weight = 5 } } } }, wait = { min = 1, max = 2 }, reelSeconds = 2, rods = { { id = "Rod", name = "Rod", luck = 1, speed = 1 } } },
		}
		local chances = UnitMath.chances(recipe)
		equal(chances.Dragon, 0.5, "el huevo B es mejor")
		equal(chances.Kitty, 0.75)
		equal(chances.Tuna, 1)
		equal(UnitMath.variantChance(MUTATIONS, "Galaxy"), 1 / 1080)
		equal(UnitMath.variantChance(MUTATIONS, nil), 1000 / 1080)
	end,

	["el peso queda en el rango, con los pesados más raros"] = function()
		equal(UnitMath.rollWeight(TUNA, fixed(0)), 10)
		equal(UnitMath.rollWeight(TUNA, fixed(0.5)), 15)
		equal(UnitMath.rollWeight(TUNA, fixed(0.9999999)), 30)
		equal(UnitMath.rollWeight(DRAGON, fixed(0.5)), nil)
	end,
})
