--!strict
local TestKit = require("./TestKit")
local RateLimiter = require("../src/server/Net/RateLimiter")

local truthy, falsy = TestKit.truthy, TestKit.falsy

local function fakeClock()
	local t = 0
	return function()
		return t
	end, function(seconds: number)
		t += seconds
	end
end

TestKit.run("RateLimiter", {
	["permite la ráfaga inicial y después corta"] = function()
		local clock = fakeClock()
		local limiter = RateLimiter.new(3, 1, clock)
		truthy(limiter:allow("a"), "1")
		truthy(limiter:allow("a"), "2")
		truthy(limiter:allow("a"), "3")
		falsy(limiter:allow("a"), "4 sin esperar")
	end,

	["recarga con el tiempo sin pasar la capacidad"] = function()
		local clock, advance = fakeClock()
		local limiter = RateLimiter.new(2, 1, clock)
		limiter:allow("a")
		limiter:allow("a")
		falsy(limiter:allow("a"), "vacío")
		advance(1)
		truthy(limiter:allow("a"), "recargó una ficha")
		falsy(limiter:allow("a"), "solo una")
		advance(100)
		truthy(limiter:allow("a"), "1 tras mucho tiempo")
		truthy(limiter:allow("a"), "2 tras mucho tiempo")
		falsy(limiter:allow("a"), "no acumula más que la capacidad")
	end,

	["cada clave tiene su propio balde"] = function()
		local clock = fakeClock()
		local limiter = RateLimiter.new(1, 1, clock)
		truthy(limiter:allow("a"), "a")
		truthy(limiter:allow("b"), "b no depende de a")
		falsy(limiter:allow("a"), "a agotado")
	end,

	["remove reinicia la clave"] = function()
		local clock = fakeClock()
		local limiter = RateLimiter.new(1, 1, clock)
		limiter:allow("a")
		limiter:remove("a")
		truthy(limiter:allow("a"), "balde nuevo")
	end,

	["rechaza configuraciones sin sentido"] = function()
		falsy((pcall(RateLimiter.new, 0, 1)), "capacidad 0")
		falsy((pcall(RateLimiter.new, 1, 0)), "recarga 0")
	end,
})
