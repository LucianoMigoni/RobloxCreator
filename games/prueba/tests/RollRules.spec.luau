--!strict
-- Cantidades con pase, precio y tiradas gratis.
local TestKit = require("./TestKit")
local RollRules = require("../src/shared/Lib/RollRules")
local Types = require("../src/shared/Kits/Types")

local equal = TestKit.equal

local EGG: Types.RollDef = {
	id = "Basic",
	name = "Basic Egg",
	price = { currency = "Money", amount = 50 },
	pool = { { unit = "Kitty", weight = 1 } },
	amounts = { { count = 1 }, { count = 3, pass = "Triple" }, { count = 8, pass = "Octo" } },
}

local function owns(list: { string }): (string) -> boolean
	return function(pass: string): boolean
		return table.find(list, pass) ~= nil
	end
end

TestKit.run("RollRules", {
	["cada cantidad pide su pase"] = function()
		equal(RollRules.amount(EGG, 1, owns({})), true)
		equal(RollRules.amount(EGG, 3, owns({})), false)
		equal(RollRules.amount(EGG, 3, owns({ "Triple" })), true)
		equal(RollRules.amount(EGG, 5, owns({ "Triple", "Octo" })), false, "5 no está en la lista")
	end,

	["el precio se multiplica y lo gratis no tiene"] = function()
		equal(RollRules.cost(EGG, 8), 400)
		local free = table.clone(EGG)
		free.price = nil
		equal(RollRules.cost(free, 1), nil)
	end,

	["la gratis espera su hora"] = function()
		equal(RollRules.freeReady(nil, 10), true)
		equal(RollRules.freeReady(20, 10), false)
		equal(RollRules.freeReady(20, 20), true)
	end,

	["la mayor cantidad con los pases que tiene"] = function()
		equal(RollRules.best(EGG, owns({})), 1)
		equal(RollRules.best(EGG, owns({ "Octo" })), 8)
	end,
})
