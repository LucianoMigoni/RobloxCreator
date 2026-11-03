--!strict
-- Valores de las tablas de posiciones: enteros que conservan el orden y vuelven al leerlos.
local TestKit = require("./TestKit")
local Ranking = require("../src/shared/Lib/Ranking")

local equal = TestKit.equal
local truthy = TestKit.truthy

TestKit.run("Ranking", {
	["siempre un entero no negativo, exacto en un double"] = function()
		for _, value in { 0, 1, 7, 999, 123456789, 1e15, 1e30, 1e100, 1e308, math.huge } do
			local stored = Ranking.encode(value)
			equal(stored, math.floor(stored), "entero para " .. tostring(value))
			truthy(stored >= 0 and stored < 2 ^ 53, "entra en 2^53 para " .. tostring(value))
		end
		equal(Ranking.encode(0), 0)
		equal(Ranking.encode(-5), 0, "negativo")
		equal(Ranking.encode(0 / 0), 0, "NaN")
	end,

	["conserva el orden, también entre vecinos"] = function()
		local values = { 0, 1, 2, 3, 10, 11, 99, 100, 101, 5000, 5001, 1e6, 1e6 + 1, 999999999, 1e9, 1e11, 1e11 + 1, 1e20, 2e20, 1e50, 1e300 }
		for i = 2, #values do
			truthy(Ranking.encode(values[i]) > Ranking.encode(values[i - 1]), tostring(values[i]) .. " arriba de " .. tostring(values[i - 1]))
		end
	end,

	["vuelve exacto hasta 1e12"] = function()
		for _, value in { 0, 1, 2, 9, 10, 42, 1000, 65535, 1234567, 987654321, 999999999999 } do
			equal(Ranking.decode(Ranking.encode(value)), value, "ida y vuelta de " .. tostring(value))
		end
	end,

	["los grandes vuelven con 12 cifras"] = function()
		for _, value in { 1.5e13, 7.77e18, 1.25e33, 4.2e100 } do
			local back = Ranking.decode(Ranking.encode(value))
			truthy(math.abs(back - value) / value < 1e-11, "error relativo chico para " .. tostring(value))
		end
	end,

	["lo raro de la tabla no rompe"] = function()
		equal(Ranking.decode(0), 0)
		equal(Ranking.decode(-3), 0)
		equal(Ranking.decode(0 / 0), 0)
		equal(Ranking.decode("x" :: any), 0, "no es un número")
		equal(Ranking.userId("12345"), 12345)
		equal(Ranking.userId("-1"), nil)
		equal(Ranking.userId("1.5"), nil)
		equal(Ranking.userId("abc"), nil)
	end,
})
