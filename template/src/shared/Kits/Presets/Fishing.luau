--!strict
-- Receta "pesca" (Fish It!, Fisch): se tira la caña al agua, se espera la picada y se recoge a tiempo;
-- cada pez tiene peso (vale más cuanto más pesa), se vende en el puesto, las cañas mejores dan suerte y
-- velocidad, y cada isla trae peces nuevos. Es una muestra: cada juego trae sus peces, islas y mapa.

local Types = require("../Types")

local recipe: Types.KitConfig = {
	name = "Fishing",
	leaderstats = { "Money", "Rebirths" },
	units = {
		label = "Fish",
		maxInventory = 80,
		mutations = true,
		announceFrom = "Legendary",
		luckyFrom = "Rare",
		list = {
			{ id = "Sardine", name = "Sardine", rarity = "Common", value = 5, weight = { min = 0.1, max = 0.5 }, zone = "Beach", icon = "sardine", color = "#9FC5E8" },
			{ id = "Clownfish", name = "Clownfish", rarity = "Common", value = 9, weight = { min = 0.2, max = 0.8 }, zone = "Beach", icon = "clownfish", color = "#FF9F1A" },
			{ id = "Pufferfish", name = "Pufferfish", rarity = "Uncommon", value = 30, weight = { min = 0.5, max = 2 }, zone = "Reef", icon = "pufferfish", color = "#FFD23A" },
			{ id = "Salmon", name = "Salmon", rarity = "Uncommon", value = 45, weight = { min = 2, max = 8 }, zone = "Frozen", icon = "salmon", color = "#FF7A6A" },
			{ id = "Swordfish", name = "Swordfish", rarity = "Rare", value = 250, weight = { min = 30, max = 90 }, zone = "Reef", icon = "swordfish", color = "#2EC5F5" },
			{ id = "Octopus", name = "Octopus", rarity = "Epic", value = 800, weight = { min = 5, max = 25 }, zone = "Reef", icon = "octopus", color = "#A35CFF" },
			{ id = "Shark", name = "Shark", rarity = "Legendary", value = 4_000, weight = { min = 100, max = 400 }, zone = "Frozen", icon = "shark", color = "#7D8B9A" },
			{ id = "GoldenKoi", name = "Golden Koi", rarity = "Mythic", value = 25_000, weight = { min = 3, max = 10 }, zone = "Lava", icon = "golden_koi", color = "#FFD23A" },
			{ id = "BabyKraken", name = "Baby Kraken", rarity = "Secret", value = 250_000, weight = { min = 200, max = 800 }, zone = "Lava", icon = "baby_kraken", color = "#FF3B4F" },
		} :: { Types.UnitDef },
		zones = {
			{ id = "Beach", name = "Sunny Beach", reward = { currency = "Gems", amount = 25 } },
			{ id = "Reef", name = "Coral Reef", reward = { currency = "Gems", amount = 50 } },
			{ id = "Frozen", name = "Frozen Lake", reward = { currency = "Gems", amount = 100 } },
			{ id = "Lava", name = "Lava Lake", reward = { currency = "Gems", amount = 250, spins = 2 } },
		} :: { Types.IndexZone },
	},
	fishing = {
		pools = {
			{ id = "Beach", zone = "Beach", entries = { { unit = "Sardine", weight = 60 }, { unit = "Clownfish", weight = 35 }, { unit = "Pufferfish", weight = 5 } } :: { Types.PoolEntry } },
			{ id = "Reef", zone = "Reef", entries = { { unit = "Pufferfish", weight = 50 }, { unit = "Swordfish", weight = 35 }, { unit = "Octopus", weight = 15 } } :: { Types.PoolEntry } },
			{ id = "Frozen", zone = "Frozen", entries = { { unit = "Salmon", weight = 65 }, { unit = "Octopus", weight = 25 }, { unit = "Shark", weight = 10 } } :: { Types.PoolEntry } },
			{ id = "Lava", zone = "Lava", entries = { { unit = "Shark", weight = 55 }, { unit = "GoldenKoi", weight = 40 }, { unit = "BabyKraken", weight = 5 } } :: { Types.PoolEntry } },
		} :: { Types.FishingPool },
		wait = { min = 2, max = 5 },
		reelSeconds = 2.5,
		castRange = 40,
		rods = {
			{ id = "Starter", name = "Starter Rod", luck = 1, speed = 1 },
			{ id = "Lucky", name = "Lucky Rod", luck = 1.5, speed = 1.2, price = { currency = "Money", amount = 1_500 } },
			{ id = "Pro", name = "Pro Rod", luck = 2.5, speed = 1.6, price = { currency = "Money", amount = 40_000 } },
			{ id = "Mythic", name = "Mythic Rod", luck = 5, speed = 2.5, price = { currency = "Money", amount = 1_500_000 } },
		} :: { Types.FishingRod },
	},
	sell = { keepFrom = "Legendary", anywherePass = "SellAnywhere" },
	zones = {
		list = {
			{ id = "Beach", name = "Sunny Beach", order = 1 },
			{ id = "Reef", name = "Coral Reef", difficulty = "😐", order = 2, price = { currency = "Money", amount = 20_000 } },
			{ id = "Frozen", name = "Frozen Lake", difficulty = "😟", order = 3, price = { currency = "Money", amount = 400_000 } },
			{ id = "Lava", name = "Lava Lake", difficulty = "😱", order = 4, price = { currency = "Money", amount = 8_000_000 }, rebirths = 1 },
		} :: { Types.ZoneDef },
	},
	upgrades = {
		{ id = "Reel", name = "Quick Reel", desc = "Bites come 8% faster per level", icon = "fishing", effect = "reel", per = 0.08, maxLevel = 5, prices = { 500, 5_000, 50_000, 500_000, 5_000_000 } },
		{ id = "Luck", name = "Fishing Luck", desc = "+10% Luck per level", icon = "luck", effect = "stat:Luck", per = 0.1, kind = "add", maxLevel = 10, base = 1_000, growth = 2 },
		{ id = "Cash", name = "Better Prices", desc = "+15% Money per level", icon = "money_boost", effect = "stat:Money", per = 0.15, kind = "add", maxLevel = 20, base = 800, growth = 1.7 },
	} :: { Types.UpgradeDef },
	objectives = {
		{ id = "cast", text = "Cast your line", stat = "Cast", target = 1 },
		{ id = "catch1", text = "Catch a fish", stat = "Catch", target = 1 },
		{ id = "sell", text = "Sell your fish", stat = "Sell", target = 1 },
		{ id = "earn1", text = "Earn %s", stat = "MoneyEarned", target = 1_000, money = true },
		{ id = "rod", text = "Buy a better rod", stat = "RodBought", target = 1 },
		{ id = "catch2", text = "Catch %s fish", stat = "Catch", target = 25 },
		{ id = "zone", text = "Unlock the Coral Reef", stat = "ZoneUnlocked", target = 1 },
		{ id = "rare", text = "Catch a Rare fish", stat = "RareFound", target = 1 },
		{ id = "rebirth", text = "Rebirth once", stat = "Rebirth", target = 1 },
	} :: { Types.ObjectiveDef },
	quests = {
		{ id = "catch", text = "Catch %s fish", stat = "Catch", target = 30, reward = { currency = "Gems", amount = 10 } },
		{ id = "sell", text = "Sell %s times", stat = "Sell", target = 5, reward = { currency = "Money", incomeMinutes = 5 } },
		{ id = "earn", text = "Earn %s", stat = "MoneyEarned", target = 50_000, money = true, reward = { spins = 1 } },
		{ id = "rare", text = "Catch %s Rare fish", stat = "RareFound", target = 3, reward = { boost = "Luck2x", seconds = 600 } },
		{ id = "play", text = "Play for %s minutes", stat = "Minutes", target = 20, reward = { currency = "Gems", amount = 5 } },
	} :: { Types.Quest },
	shop = {
		products = {
			{ key = "MythicRodPack", productId = 0, name = "Mythic Rod", desc = "Unlock the Mythic Rod (5x Luck, 2.5x reel speed)", icon = "fishing", robux = 399, category = "Featured", grant = { { item = "Rod:Mythic" } } },
		} :: { Types.ShopProduct },
	},
	map = {
		theme = "beach",
		shops = { "Shop", "Sell", "Rods", "Upgrades", "Index" },
		leaderboard = true,
		groupChest = true,
		spin = true,
		nextUpdate = "Saturday 3PM EST",
	},
}

return recipe
