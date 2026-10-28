--!strict
local TestKit = require("./TestKit")
local Rarity = require("../src/shared/Lib/Rarity")

local equal = TestKit.equal

local EGG: { Rarity.Entry } = {
	{ id = "Common", weight = 70 },
	{ id = "Rare", weight = 25 },
	{ id = "Epic", weight = 4.9, lucky = true },
	{ id = "Secret", weight = 0.1, lucky = true },
}

local function fixed(value: number): () -> number
	return function()
		return value
	end
end

TestKit.run("Rarity", {
	["sin suerte, las probabilidades son el peso"] = function()
		local odds = Rarity.odds(EGG)
		equal(odds[1].chance, 0.7)
		equal(odds[4].id, "Secret")
		equal(math.abs(odds[4].chance - 0.001) < 1e-12, true, "secret 0.1%")
	end,

	["la suerte multiplica solo las marcadas"] = function()
		local odds = Rarity.odds(EGG, 2)
		-- total = 70 + 25 + 9.8 + 0.2 = 105
		equal(math.abs(odds[3].chance - 9.8 / 105) < 1e-12, true, "epic con x2")
		equal(math.abs(odds[1].chance - 70 / 105) < 1e-12, true, "common baja al normalizar")
	end,

	["roll recorre los pesos en orden"] = function()
		equal(Rarity.roll(EGG, 1, fixed(0)).id, "Common")
		equal(Rarity.roll(EGG, 1, fixed(0.69)).id, "Common")
		equal(Rarity.roll(EGG, 1, fixed(0.71)).id, "Rare")
		equal(Rarity.roll(EGG, 1, fixed(0.9995)).id, "Secret")
		equal(Rarity.roll(EGG, 1, fixed(0.99999999)).id, "Secret", "borde superior")
	end,

	["percentages suma exactamente 100 y no muestra 0% para algo posible"] = function()
		local entries: { Rarity.Entry } = {
			{ id = "A", weight = 1 },
			{ id = "B", weight = 1 },
			{ id = "C", weight = 1 },
			{ id = "Z", weight = 0.0001, lucky = true },
		}
		local list = Rarity.percentages(entries, 1, 2)
		local sum = 0
		for _, p in list do
			sum += tonumber((p.text:gsub("%%", ""))) :: number
			equal(p.text ~= "0%", true, p.id .. " no es 0%")
		end
		equal(math.abs(sum - 100) < 1e-9, true, "suma 100, dio " .. sum)
	end,

	["oneIn del más raro"] = function()
		equal(Rarity.oneIn(EGG, "Secret"), 1000)
		equal(Rarity.oneIn(EGG, "Nope"), math.huge)
	end,
})
