--!strict
-- Receta de "Steal & Fuse Critters" (games/prueba): robar y colocar con fusión de dos iguales, armada
-- con el armador desde la receta StealAndPlace y la spec del juego (docs/spec.md). Lo que la spec pide
-- y el armador todavía no tiene está en docs/decisiones.md.

local Types = require("../Kits/Types")

local recipe: Types.KitConfig = {
	name = "StealAndFuseCritters",
	leaderstats = { "Money", "Rebirths" },
	units = {
		label = "Critters",
		maxInventory = 40,
		mutations = true,
		announceFrom = "Legendary",
		luckyFrom = "Rare",
		-- Un nivel por critter: dos iguales se fusionan en el siguiente (ingreso ×2,5 por nivel).
		list = {
			{ id = "PebblePup", name = "Pebble Pup", rarity = "Common", tier = 1, income = 1, price = 10, icon = "pebble_pup", color = "#A3A9B8" },
			{ id = "Mossling", name = "Mossling", rarity = "Common", tier = 2, income = 3, price = 60, icon = "mossling", color = "#46D64B" },
			{ id = "Bubblebug", name = "Bubblebug", rarity = "Uncommon", tier = 3, income = 7, price = 400, icon = "bubblebug", color = "#2EC5F5" },
			{ id = "Zapfrog", name = "Zapfrog", rarity = "Rare", tier = 4, income = 18, icon = "zapfrog", color = "#FFD23A" },
			{ id = "CloudKitty", name = "Cloud Kitty", rarity = "Epic", tier = 5, income = 45, icon = "cloud_kitty", color = "#F2F4F8" },
			{ id = "LavaLizard", name = "Lava Lizard", rarity = "Legendary", tier = 6, income = 110, icon = "lava_lizard", color = "#FF5A1A" },
			{ id = "StarOwl", name = "Star Owl", rarity = "Mythic", tier = 7, income = 275, icon = "star_owl", color = "#A35CFF" },
			{ id = "CrystalDragon", name = "Crystal Dragon", rarity = "Secret", tier = 8, income = 700, icon = "crystal_dragon", color = "#2FE0C8" },
		} :: { Types.UnitDef },
	},
	plots = {
		label = "Base",
		count = 8,
		slots = 8,
		maxSlots = 12,
		slotPrices = { 1_000, 5_000, 25_000, 100_000 },
		collect = "pad",
		autoCollectPass = "AutoCollect",
		autoPlace = true, -- lo comprado camina solo a un pedestal libre (M3)
		lock = { seconds = 60, cooldown = 90 },
		slotPass = "ExtraSlots", -- "+4 Pedestals"
		passSlots = 4,
	},
	belt = {
		spawnEvery = 4,
		walkSeconds = 20,
		maxOnBelt = 6,
		pool = {
			{ unit = "PebblePup", weight = 70 },
			{ unit = "Mossling", weight = 25 },
			{ unit = "Bubblebug", weight = 5 },
		} :: { Types.PoolEntry },
	},
	steal = { holdSeconds = 1.5, carrySpeed = 0.7, protectNewSeconds = 300, recentSeconds = 30, pushRange = 10, protectBest = true },
	-- M6: dos del mismo nivel dan uno del siguiente, con chance de mutación (se muestra en la ventana).
	merge = { mode = "tier", count = 2, mutationChance = 0.06 },
	rebirth = { currency = "Money", base = 150_000, growth = 3 },
	-- El onboarding de la spec, como cadena de objetivos.
	objectives = {
		{ id = "buy", text = "Buy a critter from the belt!", stat = "UnitBought", target = 1 },
		{ id = "collect", text = "Step on the pad to collect coins", stat = "Collect", target = 1 },
		{ id = "buy2", text = "Buy %s critters", stat = "UnitBought", target = 3 },
		{ id = "fuse", text = "Fuse two of the same critter!", stat = "Merge", target = 1 },
		{ id = "steal", text = "Steal a critter from another base!", stat = "Steal", target = 1 },
		{ id = "lock", text = "Lock your base", stat = "Lock", target = 1 },
		{ id = "earn", text = "Earn %s", stat = "MoneyEarned", target = 10_000, money = true },
		{ id = "rebirth", text = "Rebirth once", stat = "Rebirth", target = 1 },
	} :: { Types.ObjectiveDef },
	quests = {
		{ id = "buy", text = "Buy %s critters", stat = "UnitBought", target = 10, reward = { currency = "Gems", amount = 5 } },
		{ id = "fuse", text = "Fuse %s times", stat = "Merge", target = 5, reward = { currency = "Gems", amount = 10 } },
		{ id = "steal", text = "Steal %s critters", stat = "Steal", target = 3, reward = { boost = "Luck2x", seconds = 600 } },
		{ id = "collect", text = "Collect coins %s times", stat = "Collect", target = 20, reward = { currency = "Money", incomeMinutes = 5 } },
		{ id = "push", text = "Push %s thieves", stat = "Push", target = 5, reward = { boost = "Money2x", seconds = 600 } },
	} :: { Types.Quest },
	map = {
		theme = "meadow",
		bases = "pen",
		shops = { "Shop", "Index" },
		leaderboard = true,
		groupChest = true,
		spin = true,
		nextUpdate = "Saturday 3PM EST",
		showcase = "CrystalDragon",
	},
}

return recipe
