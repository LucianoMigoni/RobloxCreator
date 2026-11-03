--!strict
local TestKit = require("./TestKit")
local PaidRandom = require("../src/shared/Lib/PaidRandom")
local Rarity = require("../src/shared/Lib/Rarity")
local Types = require("../src/shared/Kits/Types")

local equal = TestKit.equal

local MUTATIONS: { PaidRandom.Variant } = {
	{ id = "Normal", weight = 1000, mult = 1 },
	{ id = "Gold", weight = 60, mult = 2, lucky = true },
	{ id = "Diamond", weight = 15, mult = 3, lucky = true },
	{ id = "Rainbow", weight = 4, mult = 5, lucky = true },
	{ id = "Galaxy", weight = 1, mult = 10, lucky = true },
}

local function sum(odds: { Rarity.Entry }): number
	local total = 0
	for _, o in odds do
		total += o.weight
	end
	return total
end

local function chance(odds: { Rarity.Entry }, id: string): number
	for _, o in odds do
		if o.id == id then
			return o.weight
		end
	end
	return -1
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

local function egg(price: Types.Price?, paidRandom: boolean?): Types.RollDef
	return { id = "Egg", name = "Egg", price = price, paidRandom = paidRandom, pool = {}, amounts = { { count = 1 } } }
end

local function purchasable(id: string): boolean
	return id == "Money"
end

TestKit.run("PaidRandom", {
	["un huevo pagado con una moneda que se vende por Robux es aleatorio pago"] = function()
		equal(PaidRandom.roll(egg({ currency = "Money", amount = 10 }), purchasable), true, "plata del núcleo")
		equal(PaidRandom.roll(egg({ currency = "Wins", amount = 1 }), purchasable), false, "victorias")
		equal(PaidRandom.roll(egg(nil), purchasable), false, "gratis con espera")
		equal(PaidRandom.roll(egg({ currency = "Wins", amount = 1 }, true), purchasable), true, "marcado a mano")
	end,

	["la fusión: sin mutación 1 - chance y el resto según el peso"] = function()
		local odds = PaidRandom.mergeOdds(0.06, MUTATIONS)
		equal(#odds, 5)
		equal(near(sum(odds), 1), true, "suman 1")
		equal(near(chance(odds, "Normal"), 0.94), true, "Normal 94 %")
		equal(near(chance(odds, "Gold"), 0.06 * 60 / 80), true, "Gold 4.5 %")
		equal(near(chance(odds, "Galaxy"), 0.06 / 80), true, "Galaxy")
	end,

	["la cosecha mezcla la chance de mutación con la tirada con suerte"] = function()
		local plain = PaidRandom.harvestOdds(nil, MUTATIONS, 1)
		equal(near(chance(plain, "Gold"), 60 / 1080), true, "sin mutationChance es la tirada de siempre")
		local odds = PaidRandom.harvestOdds(0.05, MUTATIONS, 2)
		equal(near(sum(odds), 1), true, "suman 1")
		-- Con suerte x2: total = 1000 + 2 * 80 = 1160.
		equal(near(chance(odds, "Normal"), 0.95 * 1000 / 1160), true, "Normal")
		equal(near(chance(odds, "Gold"), 0.05 * 60 / 80 + 0.95 * 120 / 1160), true, "Gold")
	end,

	["la línea muestra todo y suma 100 %"] = function()
		local line = PaidRandom.line(PaidRandom.mergeOdds(0.06, MUTATIONS))
		equal(line, "Normal 94% · Gold 4.5% · Diamond 1.125% · Rainbow 0.3% · Galaxy 0.075%")
	end,
})
