--!strict
local TestKit = require("./TestKit")
local Receipts = require("../src/server/Shop/Receipts")

local equal, truthy, falsy = TestKit.equal, TestKit.truthy, TestKit.falsy

local function count(log: Receipts.Log): number
	local n = 0
	for _ in log do
		n += 1
	end
	return n
end

TestKit.run("Receipts", {
	["registra y reconoce compras"] = function()
		local log: Receipts.Log = {}
		falsy(Receipts.has(log, "A"), "antes")
		Receipts.record(log, "A", 100, 10)
		truthy(Receipts.has(log, "A"), "después")
	end,

	["descarta las más viejas por encima del máximo"] = function()
		local log: Receipts.Log = {}
		Receipts.record(log, "A", 1, 2)
		Receipts.record(log, "B", 2, 2)
		Receipts.record(log, "C", 3, 2)
		equal(count(log), 2, "tamaño")
		falsy(Receipts.has(log, "A"), "la más vieja salió")
		truthy(Receipts.has(log, "B"), "B queda")
		truthy(Receipts.has(log, "C"), "C queda")
	end,

	["nunca descarta la recién anotada, aunque empate en hora"] = function()
		local log: Receipts.Log = {}
		Receipts.record(log, "A", 5, 1)
		Receipts.record(log, "B", 5, 1)
		truthy(Receipts.has(log, "B"), "la nueva queda")
		equal(count(log), 1, "tamaño")
	end,

	["volver a anotar la misma compra no duplica"] = function()
		local log: Receipts.Log = {}
		Receipts.record(log, "A", 1, 5)
		Receipts.record(log, "A", 2, 5)
		equal(count(log), 1, "una sola")
	end,
})
