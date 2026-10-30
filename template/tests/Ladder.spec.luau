--!strict
-- Escaleras de precios: lista explícita o crecimiento geométrico.
local TestKit = require("./TestKit")
local Ladder = require("../src/shared/Lib/Ladder")

local equal = TestKit.equal

TestKit.run("Ladder", {
	["la lista manda y se termina"] = function()
		equal(Ladder.price(1, { 100, 500 }), 100)
		equal(Ladder.price(2, { 100, 500 }), 500)
		equal(Ladder.price(3, { 100, 500 }), nil)
		equal(Ladder.price(0, { 100 }), nil)
	end,

	["sin lista crece con base y growth"] = function()
		equal(Ladder.price(1, nil, 100, 1.5), 100)
		equal(Ladder.price(3, nil, 100, 1.5), 225)
		equal(Ladder.price(2, nil, nil, 2), nil)
	end,

	["el total suma niveles seguidos"] = function()
		equal(Ladder.total(1, 3, nil, 100, 2), 700)
		equal(Ladder.total(2, 2, { 1, 2, 3 }), 5)
		equal(Ladder.total(3, 2, { 1, 2, 3 }), nil, "el 4 no existe")
	end,
})
