--!strict
local TestKit = require("./TestKit")
local Format = require("../src/shared/Lib/Format")

local equal = TestKit.equal

TestKit.run("Format", {
	["números chicos con comas, grandes con sufijo"] = function()
		equal(Format.number(0), "0")
		equal(Format.number(9861), "9,861")
		equal(Format.number(56261), "56,261")
		equal(Format.number(356600), "356.6K")
		equal(Format.number(1430000000), "1.43B")
		equal(Format.number(533.5e12), "533.5T")
		equal(Format.number(36.76e15), "36.76Qa")
		equal(Format.number(-2500000), "-2.5M")
	end,

	["redondeo que cambia de sufijo"] = function()
		equal(Format.number(999960), "1M", "no '1000K'")
		equal(Format.number(1e6), "1M")
	end,

	["valores raros no rompen"] = function()
		equal(Format.number(0 / 0), "0")
		equal(Format.number(math.huge), "∞")
		equal(Format.number(1e80):find("e") ~= nil, true, "científica arriba de los sufijos")
	end,

	["plata, por segundo y multiplicador"] = function()
		equal(Format.money(997151167), "$997.2M")
		equal(Format.money(99715116), "$99.72M")
		equal(Format.perSecond(18e6), "$18M/s")
		equal(Format.multiplier(2), "x2")
		equal(Format.multiplier(1.5), "x1.5")
	end,

	["porcentajes y 1 in N"] = function()
		equal(Format.percent(0.0525), "5.25%")
		equal(Format.percent(0.000012), "0.0012%")
		equal(Format.oneIn(1 / 9342584), "1 in 9,342,584")
		equal(Format.oneIn(0), "—")
	end,

	["tiempos"] = function()
		equal(Format.duration(8922), "2h 28m 42s")
		equal(Format.duration(248), "4m 8s")
		equal(Format.duration(19), "19s")
		equal(Format.duration(3 * 86400 + 7200), "3d 2h")
		equal(Format.clock(33637), "09:20:37")
		equal(Format.clock(17), "00:17")
		equal(Format.duration(-5), "0s")
	end,

	["duración corta de premios"] = function()
		equal(Format.short(3600), "1h")
		equal(Format.short(5400), "1h 30m")
		equal(Format.short(900), "15m")
		equal(Format.short(45), "45s")
		equal(Format.short(2 * 86400), "2d")
		equal(Format.short(90), "1m 30s")
	end,
})
