--!strict
-- Qué toman "vender todo", "fusionar" y "equipar lo mejor".
local TestKit = require("./TestKit")
local UnitPick = require("../src/shared/Lib/UnitPick")
local Types = require("../src/shared/Kits/Types")

local equal = TestKit.equal

local RANK: { [string]: number } = { Kitty = 1, Owl = 3, Dragon = 7 }

local function list(): { Types.Unit }
	return {
		{ uid = 1, kind = "Kitty" },
		{ uid = 2, kind = "Kitty", locked = true },
		{ uid = 3, kind = "Kitty", slot = 1 },
		{ uid = 4, kind = "Owl", equipped = true },
		{ uid = 5, kind = "Dragon" },
		{ uid = 6, kind = "Kitty", variant = "Gold" },
		{ uid = 7, kind = "Kitty" },
	}
end

local function rank(unit: Types.Unit): number
	return RANK[unit.kind] or 0
end

TestKit.run("UnitPick", {
	["vender todo respeta lo cuidado, lo equipado, lo colocado y lo raro"] = function()
		equal(table.concat(UnitPick.sellAll(list(), rank, 7), ","), "1,6,7")
		equal(table.concat(UnitPick.sellAll(list(), rank, 0), ","), "1,5,6,7", "0 = sin límite de rareza")
	end,

	["fusionar toma iguales, primero las sueltas"] = function()
		equal(table.concat(UnitPick.group(list(), "Kitty", nil, 3) :: { number }, ","), "1,6,7")
		equal(table.concat(UnitPick.group(list(), "Kitty", "Normal", 3) :: { number }, ","), "1,7,3", "la colocada al final")
		equal(UnitPick.group(list(), "Kitty", "Gold", 2), nil, "no alcanzan")
		equal(UnitPick.group(list(), "Owl", nil, 1), nil, "la equipada no entra")
	end,

	["las mejores por puntaje y, empatadas, la más vieja"] = function()
		local best = UnitPick.best(list(), 3, rank)
		equal(table.concat(best, ","), "5,4,1")
		equal(#UnitPick.best({}, 3, rank), 0)
	end,
})
