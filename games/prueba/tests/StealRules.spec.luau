--!strict
local TestKit = require("./TestKit")
local StealRules = require("../src/server/Critters/StealRules")

local equal = TestKit.equal

local function attempt(overrides: { [string]: boolean }): StealRules.Attempt
	local base: StealRules.Attempt = {
		isOwner = false,
		carrying = false,
		thiefHasRoom = true,
		locked = false,
		protected = false,
		mostValuable = false,
		recentlyStolen = false,
	}
	for key, value in overrides do
		(base :: any)[key] = value
	end
	return base
end

TestKit.run("StealRules", {
	["blockReason deja robar cuando nada lo impide"] = function()
		equal(StealRules.blockReason(attempt({})), nil, "robo válido")
	end,

	["blockReason da cada motivo"] = function()
		equal(StealRules.blockReason(attempt({ isOwner = true })), "OWN_BASE", "dueño")
		equal(StealRules.blockReason(attempt({ carrying = true })), "ALREADY_CARRYING", "ya carga")
		equal(StealRules.blockReason(attempt({ locked = true })), "LOCKED", "trabada")
		equal(StealRules.blockReason(attempt({ protected = true })), "PROTECTED", "protegido")
		equal(StealRules.blockReason(attempt({ mostValuable = true })), "MOST_VALUABLE", "más valioso")
		equal(StealRules.blockReason(attempt({ recentlyStolen = true })), "RECENTLY_STOLEN", "recién robado")
		equal(StealRules.blockReason(attempt({ thiefHasRoom = false })), "NO_ROOM", "sin lugar")
	end,

	["blockReason prioriza la traba sobre la falta de lugar"] = function()
		equal(StealRules.blockReason(attempt({ locked = true, thiefHasRoom = false })), "LOCKED", "trabada y sin lugar")
	end,

	["mostValuable elige el de mayor ingreso"] = function()
		local critters = {
			{ uid = "a", tier = 2, mutation = "Normal", pedestal = 1 },
			{ uid = "b", tier = 3, mutation = "Normal", pedestal = 2 },
			{ uid = "c", tier = 1, mutation = "Rainbow", pedestal = 3 },
		}
		local income = { 1, 3, 7 }
		local mult = { Normal = 1, Rainbow = 5 }
		equal(StealRules.mostValuable(critters, function(c)
			return income[c.tier] * mult[c.mutation]
		end), "b", "nivel 3 (7) gana a nivel 1 rainbow (5)")
		equal(StealRules.mostValuable({}, function()
			return 0
		end), nil, "sin critters")
	end,

	["inside mide contra la mitad del lado"] = function()
		equal(StealRules.inside(0, 0, 30), true, "centro")
		equal(StealRules.inside(15, -15, 30), true, "esquina")
		equal(StealRules.inside(15.1, 0, 30), false, "afuera en X")
		equal(StealRules.inside(0, -16, 30), false, "afuera en Z")
	end,
})
