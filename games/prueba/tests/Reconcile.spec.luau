--!strict
local TestKit = require("./TestKit")
local Reconcile = require("../src/server/Data/Reconcile")

local equal, truthy = TestKit.equal, TestKit.truthy

TestKit.run("Reconcile", {
	["deepCopy no comparte tablas"] = function()
		local original = { a = { b = 1 }, list = { 1, 2 } }
		local copy = Reconcile.deepCopy(original)
		copy.a.b = 99
		table.insert(copy.list, 3)
		equal(original.a.b, 1, "anidada")
		equal(#original.list, 2, "lista")
		equal(Reconcile.deepCopy(5), 5, "valor simple")
	end,

	["fill agrega lo que falta y no pisa lo existente"] = function()
		local data: { [string]: any } = { coins = 50 }
		Reconcile.fill(data, { coins = 0, gems = 0, settings = { music = true, sfx = true } })
		equal(data.coins, 50, "no pisa")
		equal(data.gems, 0, "agrega número")
		equal(data.settings.music, true, "agrega tabla")
	end,

	["fill completa diccionarios anidados"] = function()
		local data: { [string]: any } = { settings = { music = false } }
		Reconcile.fill(data, { settings = { music = true, sfx = true } })
		equal(data.settings.music, false, "respeta la preferencia")
		equal(data.settings.sfx, true, "agrega la clave nueva")
	end,

	["fill no rellena listas: no devuelve ítems vendidos"] = function()
		local data: { [string]: any } = { inventory = {} }
		Reconcile.fill(data, { inventory = { "Sword" } })
		equal(#data.inventory, 0, "inventario vacío se respeta")
	end,

	["los valores por defecto no se comparten entre jugadores"] = function()
		local defaults = { inventory = {} }
		local a = Reconcile.fill({}, defaults)
		local b = Reconcile.fill({}, defaults)
		table.insert(a.inventory, "Sword")
		equal(#b.inventory, 0, "b no ve lo de a")
		equal(#defaults.inventory, 0, "defaults intactos")
		truthy(a.inventory ~= defaults.inventory, "copia distinta")
	end,
})
