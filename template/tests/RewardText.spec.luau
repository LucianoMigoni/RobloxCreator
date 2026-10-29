--!strict
-- Cómo se describe un premio antes de reclamarlo (calendario, regalos, ruleta, ofertas).
local TestKit = require("./TestKit")
local RewardText = require("../src/shared/Lib/RewardText")

local equal = TestKit.equal

local CATALOG: RewardText.Catalog = {
	currencies = { Money = { symbol = "$", icon = "cash" }, Gems = { symbol = "", icon = "gem" } },
	timed = { Money2x = { label = "2x Money", icon = "money_boost" } },
	server = { ServerLuck2x = { label = "Server Luck", icon = "luck" } },
	minIncome = 5,
}

TestKit.run("RewardText", {
	["moneda fija con símbolo"] = function()
		local parts = RewardText.parts({ currency = "Gems", amount = 25 }, 0, CATALOG)
		equal(#parts, 1)
		equal(parts[1].icon, "gem")
		equal(parts[1].text, "25")
	end,
	["minutos de ganancia usan el ingreso, con piso"] = function()
		equal(RewardText.parts({ currency = "Money", incomeMinutes = 2 }, 100, CATALOG)[1].text, "$12,000")
		equal(RewardText.parts({ currency = "Money", incomeMinutes = 1 }, 0, CATALOG)[1].text, "$300", "piso de 5/s")
	end,
	["premio combinado en orden: moneda, impulso, servidor, tiradas"] = function()
		local parts = RewardText.parts({ currency = "Gems", amount = 50, boost = "Money2x", seconds = 3600, serverBoost = "ServerLuck2x", spins = 3 }, 0, CATALOG)
		equal(#parts, 4)
		equal(parts[2].text, "2x Money 1h")
		equal(parts[3].icon, "luck")
		equal(parts[4].text, "+3 Spins")
	end,
	["una tirada en singular y el ícono principal"] = function()
		equal(RewardText.parts({ spins = 1 }, 0, CATALOG)[1].text, "+1 Spin")
		equal(RewardText.icon({ spins = 1 }, CATALOG), "spin")
		equal(RewardText.icon({}, CATALOG), "gift", "sin partes: regalo")
	end,
	["moneda o impulso desconocidos se ignoran"] = function()
		equal(#RewardText.parts({ currency = "Nope", amount = 3, boost = "Nope", seconds = 5 }, 0, CATALOG), 0)
	end,
})
