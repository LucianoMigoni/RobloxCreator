--!strict
local TestKit = require("./TestKit")
local CritterRules = require("../src/server/Critters/CritterRules")

local equal = TestKit.equal

local INCOME = { 1, 3, 7, 18 }
local MUTATIONS = { Normal = 1, Gold = 2, Rainbow = 5 }

local function critter(uid: string, tier: number, mutation: string?, pedestal: number?): CritterRules.Critter
	return { uid = uid, tier = tier, mutation = mutation or "Normal", pedestal = pedestal or 1 }
end

TestKit.run("CritterRules", {
	["income multiplica nivel, mutación y multiplicador"] = function()
		equal(CritterRules.income(INCOME, MUTATIONS, critter("a", 2), 1), 3, "nivel 2 normal")
		equal(CritterRules.income(INCOME, MUTATIONS, critter("a", 2, "Gold"), 1), 6, "nivel 2 gold")
		equal(CritterRules.income(INCOME, MUTATIONS, critter("a", 4, "Rainbow"), 1.5), 135, "con multiplicador")
	end,

	["income devuelve nil con datos que no existen"] = function()
		equal(CritterRules.income(INCOME, MUTATIONS, critter("a", 9), 1), nil, "nivel inexistente")
		equal(CritterRules.income(INCOME, MUTATIONS, critter("a", 1, "Shiny"), 1), nil, "mutación inexistente")
	end,

	["rollTier respeta los pesos acumulados"] = function()
		local weights = { { tier = 1, weight = 70 }, { tier = 2, weight = 25 }, { tier = 3, weight = 5 } }
		equal(CritterRules.rollTier(weights, 0), 1, "inicio")
		equal(CritterRules.rollTier(weights, 0.699), 1, "antes del 70 %")
		equal(CritterRules.rollTier(weights, 0.70), 2, "desde el 70 %")
		equal(CritterRules.rollTier(weights, 0.949), 2, "antes del 95 %")
		equal(CritterRules.rollTier(weights, 0.95), 3, "desde el 95 %")
		equal(CritterRules.rollTier(weights, 0.999999), 3, "final")
	end,

	["freePedestal da el primer hueco o nil"] = function()
		equal(CritterRules.freePedestal({}, 8), 1, "base vacía")
		equal(CritterRules.freePedestal({ critter("a", 1, nil, 1), critter("b", 1, nil, 3) }, 8), 2, "hueco en el medio")
		local full = {}
		for i = 1, 8 do
			table.insert(full, critter("c" .. i, 1, nil, i))
		end
		equal(CritterRules.freePedestal(full, 8), nil, "llena")
	end,

	["pickFusePair elige el nivel más bajo con par"] = function()
		local list = { critter("a", 2), critter("b", 1), critter("c", 2), critter("d", 1) }
		local i, j = CritterRules.pickFusePair(list, 8)
		equal(list[i :: number].tier, 1, "primer elegido de nivel 1")
		equal(list[j :: number].tier, 1, "segundo elegido de nivel 1")
	end,

	["pickFusePair prefiere los Normal y no fusiona el nivel máximo"] = function()
		local list = { critter("gold", 1, "Gold"), critter("n1", 1), critter("n2", 1) }
		local i, j = CritterRules.pickFusePair(list, 8)
		equal(list[i :: number].mutation, "Normal", "primero normal")
		equal(list[j :: number].mutation, "Normal", "segundo normal")
		local top = { critter("x", 8), critter("y", 8) }
		local a, b = CritterRules.pickFusePair(top, 8)
		equal(a, nil, "nivel máximo sin par")
		equal(b, nil, "nivel máximo sin par (2)")
		equal((CritterRules.pickFusePair({ critter("solo", 3) }, 8)), nil, "uno solo")
	end,
})
