--!strict
-- Lo que KitCheck necesita saber del núcleo, para los tests (el CLI de Luau no puede cargar los Config
-- que usan Color3). Mantener igual a RarityConfig, EconomyConfig, BoostConfig y ShopConfig: el
-- servidor vuelve a revisar la receta al arrancar con las listas reales (server/Kits/Kits.luau).
local KitCheck = require("../src/shared/Lib/KitCheck")

local known: KitCheck.Known = {
	rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" },
	mutations = { "Normal", "Gold", "Diamond", "Rainbow", "Galaxy" },
	sizes = { "Normal", "Big", "Huge" },
	currencies = { "Money", "Gems" },
	boosts = { "Money2x", "Luck2x", "Speed2x", "Wins2x" },
	passes = { "Money2x", "Luck2x", "Speed2x", "VIP", "AutoCollect", "ExtraSlots" },
}

return known
