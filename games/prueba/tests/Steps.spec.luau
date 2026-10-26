--!strict
local TestKit = require("./TestKit")
local Steps = require("../src/server/Onboarding/Steps")

local equal = TestKit.equal

local STEPS: { Steps.Step } = {
	{ name = "Joined", source = "server" },
	{ name = "OpenedShop", source = "client" },
	{ name = "Tutorial", source = "client" },
	{ name = "BoughtFirstItem", source = "server" },
}

TestKit.run("Steps", {
	["avanza en orden"] = function()
		equal(Steps.advance(STEPS, 0, "Joined", "server"), 1, "primer paso")
		equal(Steps.advance(STEPS, 1, "OpenedShop", "client"), 2, "siguiente de cliente")
	end,

	["un paso de cliente solo cuenta si es el siguiente"] = function()
		equal(Steps.advance(STEPS, 1, "Tutorial", "client"), nil, "saltea uno")
		equal(Steps.advance(STEPS, 2, "OpenedShop", "client"), nil, "ya hecho")
	end,

	["un paso de servidor puede saltear pasos de cliente"] = function()
		equal(Steps.advance(STEPS, 1, "BoughtFirstItem", "server"), 4, "saltea los de cliente")
	end,

	["la fuente tiene que coincidir"] = function()
		equal(Steps.advance(STEPS, 0, "Joined", "client"), nil, "cliente no puede marcar un paso de servidor")
		equal(Steps.advance(STEPS, 1, "OpenedShop", "server"), nil, "servidor con paso de cliente")
	end,

	["nombres desconocidos o pasos ya hechos no avanzan"] = function()
		equal(Steps.advance(STEPS, 0, "Nope", "server"), nil, "desconocido")
		equal(Steps.advance(STEPS, 4, "BoughtFirstItem", "server"), nil, "ya terminado")
		equal(Steps.advance(STEPS, 1, "Joined", "server"), nil, "volver atrás")
	end,
})
