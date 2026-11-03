--!strict
-- Tienda de semillas: misma reposición en todos los servidores, cantidades en rango y semillas raras.
local TestKit = require("./TestKit")
local GardenShop = require("../src/shared/Lib/GardenShop")
local Types = require("../src/shared/Kits/Types")

local equal = TestKit.equal

local SEEDS: { Types.Seed } = {
	{ id = "Carrot", name = "Carrot", unit = "Carrot", price = { currency = "Money", amount = 10 }, grow = 60, stock = { min = 5, max = 10 } },
	{ id = "Mango", name = "Mango", unit = "Mango", price = { currency = "Money", amount = 5000 }, grow = 600, stock = { min = 1, max = 1 }, chance = 0.1 },
}

TestKit.run("GardenShop", {
	["la reposición sale del reloj y dice cuándo termina"] = function()
		local window, endsAt = GardenShop.window(1000, 300)
		equal(window, 3)
		equal(endsAt, 1200)
	end,

	["la misma reposición da lo mismo en todos los servidores"] = function()
		local a, b = GardenShop.stock(SEEDS, 42), GardenShop.stock(SEEDS, 42)
		equal(a.Carrot, b.Carrot)
		equal(a.Mango, b.Mango)
	end,

	["las cantidades quedan en su rango y la rara sale a veces"] = function()
		local mango = 0
		for window = 1, 2000 do
			local stock = GardenShop.stock(SEEDS, window)
			TestKit.truthy(stock.Carrot >= 5 and stock.Carrot <= 10, "Carrot en rango")
			TestKit.truthy(stock.Mango == 0 or stock.Mango == 1, "Mango 0 o 1")
			mango += stock.Mango
		end
		TestKit.truthy(mango > 100 and mango < 320, "Mango cerca del 10%: " .. mango)
	end,

	["la mejora acorta el crecimiento con tope"] = function()
		equal(GardenShop.growSeconds(SEEDS[1], 0.25), 45)
		equal(math.floor(GardenShop.growSeconds(SEEDS[1], 5) + 0.5), 6, "tope del 90%")
	end,
})
