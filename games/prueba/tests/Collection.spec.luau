--!strict
-- Índice por zonas: progreso, premio una sola vez y total sin repetir claves.
local TestKit = require("./TestKit")
local Collection = require("../src/shared/Lib/Collection")

local equal = TestKit.equal

local MEADOW: Collection.Zone = { id = "Meadow", keys = { "Kitty|Normal", "Doggo|Normal", "Hopper|Normal" } }
local SNOW: Collection.Zone = { id = "Snow", keys = { "Penguin|Normal", "Kitty|Normal" } }

TestKit.run("Collection", {
	["progreso cuenta solo las claves de la zona"] = function()
		local found = { ["Kitty|Normal"] = true, ["Dragon|Gold"] = true }
		local count, total = Collection.progress(found, MEADOW.keys)
		equal(count, 1)
		equal(total, 3)
	end,

	["el premio se reclama una vez y solo con la zona completa"] = function()
		local found: { [string]: boolean } = { ["Kitty|Normal"] = true, ["Doggo|Normal"] = true }
		local claimed: { [string]: boolean } = {}
		equal(Collection.claim(found, claimed, MEADOW), false, "falta una")
		found["Hopper|Normal"] = true
		equal(Collection.claim(found, claimed, MEADOW), true)
		equal(claimed.Meadow, true)
		equal(Collection.claim(found, claimed, MEADOW), false, "no dos veces")
	end,

	["una zona vacía nunca está completa"] = function()
		local empty: Collection.Zone = { id = "Empty", keys = {} }
		equal(Collection.complete({}, empty), false)
		equal(Collection.claim({}, {}, empty), false)
	end,

	["el total no repite claves compartidas"] = function()
		equal(Collection.total({ MEADOW, SNOW }), 4)
		equal(Collection.total({}), 0)
	end,
})
