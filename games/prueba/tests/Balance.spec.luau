--!strict
local TestKit = require("./TestKit")
local Balance = require("../src/server/Economy/Balance")

local equal = TestKit.equal
local MAX = 1000

TestKit.run("Balance", {
	["add suma y respeta el tope"] = function()
		local ok, balance = Balance.add(10, 5, MAX)
		equal(ok, true, "ok")
		equal(balance, 15, "saldo")
		ok, balance = Balance.add(990, 50, MAX)
		equal(ok, true, "ok con tope")
		equal(balance, MAX, "no pasa el tope")
	end,

	["add rechaza montos inválidos sin cambiar el saldo"] = function()
		for _, amount in { 0, -5, 2.5, 0 / 0, math.huge, -math.huge } do
			local ok, balance = Balance.add(10, amount, MAX)
			equal(ok, false, "monto " .. tostring(amount))
			equal(balance, 10, "saldo intacto con " .. tostring(amount))
		end
	end,

	["spend descuenta solo si alcanza"] = function()
		local ok, balance = Balance.spend(100, 40)
		equal(ok, true, "alcanza")
		equal(balance, 60, "saldo")
		ok, balance = Balance.spend(100, 100)
		equal(ok, true, "justo")
		equal(balance, 0, "queda en cero")
		ok, balance = Balance.spend(100, 101)
		equal(ok, false, "no alcanza")
		equal(balance, 100, "saldo intacto")
	end,

	["spend rechaza montos inválidos sin cambiar el saldo"] = function()
		for _, amount in { 0, -5, 2.5, 0 / 0, math.huge } do
			local ok, balance = Balance.spend(100, amount)
			equal(ok, false, "monto " .. tostring(amount))
			equal(balance, 100, "saldo intacto con " .. tostring(amount))
		end
	end,
})
