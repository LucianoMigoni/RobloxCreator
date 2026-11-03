--!strict
-- Receta "correr y atrapar" (Ride a Dino): se entrena la fuerza tocando (o en las cintas), los dinos
-- salvajes se atrapan si la fuerza alcanza, van a los corrales de la base y pagan por segundo, tres
-- iguales se fusionan, la pista de corrida da plata por etapa (con revivir) y las habilidades se usan
-- con tecla. Es una muestra: cada juego trae sus criaturas, zonas, pista y mapa.

local Types = require("../Types")

local recipe: Types.KitConfig = {
	name = "RunAndCatch",
	leaderstats = { "Money", "Strength" },
	stats = {
		{ id = "Strength", label = "Strength", icon = "strength", perClick = 1, clickRate = 8, autoPass = "AutoClicker" },
	} :: { Types.StatDef },
	units = {
		label = "Dinos",
		maxInventory = 60,
		mutations = true,
		announceFrom = "Legendary",
		luckyFrom = "Rare",
		list = {
			{ id = "BabyRaptor", name = "Baby Raptor", rarity = "Common", tier = 1, income = 2, requirement = 0, zone = "Jungle", icon = "baby_raptor", color = "#46D64B" },
			{ id = "Stego", name = "Stego", rarity = "Common", tier = 2, income = 6, requirement = 50, zone = "Jungle", icon = "stego", color = "#7EE35F" },
			{ id = "Trike", name = "Trike", rarity = "Uncommon", tier = 3, income = 20, requirement = 200, zone = "Jungle", icon = "trike", color = "#2EC5F5" },
			{ id = "Ankylo", name = "Ankylo", rarity = "Rare", tier = 4, income = 70, requirement = 800, zone = "Valley", icon = "ankylo", color = "#C98B4F" },
			{ id = "Ptero", name = "Ptero", rarity = "Rare", tier = 5, income = 150, requirement = 2_000, zone = "Valley", icon = "ptero", color = "#FF9F1A" },
			{ id = "Parasaur", name = "Parasaur", rarity = "Epic", tier = 6, income = 400, requirement = 5_000, zone = "Valley", icon = "parasaur", color = "#A35CFF" },
			{ id = "Spino", name = "Spino", rarity = "Legendary", tier = 7, income = 1_500, requirement = 15_000, zone = "Volcano", icon = "spino", color = "#FF3B4F" },
			{ id = "Trex", name = "T-Rex", rarity = "Mythic", tier = 8, income = 6_000, requirement = 50_000, zone = "Volcano", icon = "trex", color = "#8B5A2B" },
			{ id = "CrystalRex", name = "Crystal Rex", rarity = "Secret", tier = 9, income = 40_000, requirement = 200_000, zone = "Volcano", icon = "crystal_rex", color = "#2FE0C8" },
		} :: { Types.UnitDef },
		zones = {
			{ id = "Jungle", name = "Dino Jungle", reward = { currency = "Gems", amount = 25 } },
			{ id = "Valley", name = "Desert Valley", reward = { currency = "Gems", amount = 75 } },
			{ id = "Volcano", name = "Lava Volcano", reward = { currency = "Gems", amount = 250, spins = 2 } },
		} :: { Types.IndexZone },
	},
	wild = {
		stat = "Strength",
		captureSeconds = 2.5,
		toBase = true,
		spawns = {
			{ zone = "Jungle", max = 6, respawn = 8, entries = { { unit = "BabyRaptor", weight = 50 }, { unit = "Stego", weight = 35 }, { unit = "Trike", weight = 15 } } :: { Types.PoolEntry } },
			{ zone = "Valley", max = 6, respawn = 10, entries = { { unit = "Ankylo", weight = 45 }, { unit = "Ptero", weight = 35 }, { unit = "Parasaur", weight = 20 } } :: { Types.PoolEntry } },
			{ zone = "Volcano", max = 5, respawn = 15, entries = { { unit = "Spino", weight = 60 }, { unit = "Trex", weight = 35 }, { unit = "CrystalRex", weight = 5 } } :: { Types.PoolEntry } },
		} :: { Types.WildSpawn },
	},
	plots = {
		label = "Pen",
		count = 8,
		slots = 4,
		maxSlots = 12,
		slotPrices = { 300, 1_500, 6_000, 25_000, 100_000, 400_000, 1_500_000, 6_000_000 },
		collect = "pad",
		autoCollectPass = "AutoCollect",
	},
	merge = { mode = "tier", count = 3, mutationChance = 0.02 },
	stages = {
		count = 15,
		reward = { currency = "Money", amount = 500 },
		run = { freeRevives = 1, reviveProduct = "Revive" },
	},
	items = {
		maxStack = 10,
		list = {
			{ id = "Sprint", name = "Sprint", icon = "speed", seconds = 10, walkSpeed = 1.6 },
			{ id = "LuckyCharm", name = "Lucky Charm", icon = "luck", seconds = 60, boost = "Luck2x" },
		} :: { Types.ItemDef },
	},
	zones = {
		list = {
			{ id = "Jungle", name = "Dino Jungle", order = 1 },
			{ id = "Valley", name = "Desert Valley", difficulty = "😐", order = 2, price = { currency = "Money", amount = 50_000 } },
			{ id = "Volcano", name = "Lava Volcano", difficulty = "😱", order = 3, price = { currency = "Money", amount = 2_000_000 }, rebirths = 1 },
		} :: { Types.ZoneDef },
	},
	upgrades = {
		{ id = "Grip", name = "Strong Grip", desc = "Catch 10% faster per level", icon = "strength", effect = "capture", per = 0.1, maxLevel = 5, prices = { 1_000, 10_000, 100_000, 1_000_000, 10_000_000 } },
		{ id = "Training", name = "Training", desc = "+25% Strength per level", icon = "strength", effect = "stat:Strength", per = 0.25, kind = "add", maxLevel = 20, base = 200, growth = 1.7 },
		{ id = "Cash", name = "Dino Fans", desc = "+15% Money per level", icon = "money_boost", effect = "stat:Money", per = 0.15, kind = "add", maxLevel = 20, base = 800, growth = 1.7 },
	} :: { Types.UpgradeDef },
	objectives = {
		{ id = "train", text = "Tap to train %s times", stat = "Tap", target = 20 },
		{ id = "catch", text = "Catch a dino", stat = "Capture", target = 1 },
		{ id = "place", text = "Put it in your pen", stat = "Place", target = 1 },
		{ id = "collect", text = "Collect your cash", stat = "Collect", target = 1 },
		{ id = "run", text = "Run the dino track", stat = "RunStarted", target = 1 },
		{ id = "stages", text = "Pass %s stages", stat = "Stage", target = 5 },
		{ id = "merge", text = "Merge 3 dinos", stat = "Merge", target = 1 },
		{ id = "ability", text = "Use an ability", stat = "ItemUsed", target = 1 },
		{ id = "rebirth", text = "Rebirth once", stat = "Rebirth", target = 1 },
	} :: { Types.ObjectiveDef },
	quests = {
		{ id = "catch", text = "Catch %s dinos", stat = "Capture", target = 10, reward = { currency = "Gems", amount = 10 } },
		{ id = "tap", text = "Tap %s times", stat = "Tap", target = 500, reward = { boost = "Luck2x", seconds = 600 } },
		{ id = "stages", text = "Pass %s stages", stat = "Stage", target = 20, reward = { spins = 1 } },
		{ id = "merge", text = "Merge %s times", stat = "Merge", target = 3, reward = { currency = "Gems", amount = 10 } },
		{ id = "ability", text = "Use %s abilities", stat = "ItemUsed", target = 3, reward = { currency = "Money", incomeMinutes = 5 } },
	} :: { Types.Quest },
	shop = {
		products = {
			{ key = "SprintPack", productId = 0, name = "5 Sprints", desc = "Get 5 Sprint abilities (1.6x speed for 10s)", icon = "speed", robux = 29, category = "Kit", grant = { { item = "Item:Sprint", count = 5 } } },
			{ key = "TrexPack", productId = 0, name = "T-Rex", desc = "Get a T-Rex (Mythic, $6K/s) in your inventory", icon = "trex", robux = 499, category = "Featured", grant = { { item = "Unit:Trex" } } },
		} :: { Types.ShopProduct },
	},
	map = {
		theme = "jungle",
		shops = { "Shop", "Upgrades", "Index" },
		treadmills = { stat = "Strength", gains = { 1, 5, 25 } },
		leaderboard = true,
		groupChest = true,
		spin = true,
		nextUpdate = "Saturday 3PM EST",
	},
}

return recipe
