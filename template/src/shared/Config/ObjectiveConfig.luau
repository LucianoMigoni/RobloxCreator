--!strict
-- Cadena de objetivos arriba al centro: enseña el juego sin pantallas de tutorial y después sigue con
-- metas que crecen. Los primeros FUNNEL_STEPS se registran como embudo de onboarding en Creator
-- Analytics (dónde se van los nuevos). La receta del armador (Config/KitConfig) reemplaza CHAIN con
-- los pasos de su fórmula en `objectives`.

local Objectives = require("../Lib/Objectives")
local Types = require("../Types")
local KitConfig = require("./KitConfig")

return {
	CHAIN = (KitConfig.objectives or {
		{ id = "earn1", text = "Earn %s", stat = "MoneyEarned", target = 100, money = true },
		{ id = "daily", text = "Claim your daily gift", stat = "DailyClaimed", target = 1 },
		{ id = "spin", text = "Spin the wheel", stat = "Spin", target = 1 },
		{ id = "earn2", text = "Earn %s", stat = "MoneyEarned", target = 2_500, money = true },
		{ id = "quest", text = "Complete a quest", stat = "QuestClaimed", target = 1 },
		{ id = "rebirth", text = "Rebirth once", stat = "Rebirth", target = 1 },
	}) :: { Objectives.Def },
	ENDLESS = { text = "Earn %s", stat = "MoneyEarned", base = 50_000, growth = 3, money = true } :: Objectives.Endless,
	-- Premio de cada objetivo cumplido (chico: el premio real es la sensación de avanzar).
	REWARD = { currency = "Money", incomeMinutes = 1 } :: Types.Reward,
	FUNNEL_STEPS = 6,
}
