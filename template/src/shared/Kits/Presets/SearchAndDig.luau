--!strict
-- Receta "buscar y cavar" (Search For The Needle, Dig & Clean): se revuelve una pila enorme con la
-- herramienta (más poder, más chances), lo que aparece va a la mochila y se vende al depositarla; las
-- herramientas y la mochila se mejoran, y cada zona esconde tesoros más raros (la aguja de oro). Es una
-- muestra: cada juego trae sus tesoros, pilas, herramientas y mapa.

local Types = require("../Types")

local recipe: Types.KitConfig = {
	name = "SearchAndDig",
	leaderstats = { "Money", "Rebirths" },
	units = {
		label = "Treasures",
		maxInventory = 80,
		announceFrom = "Legendary",
		luckyFrom = "Rare",
		list = {
			{ id = "OldBoot", name = "Old Boot", rarity = "Common", value = 4, zone = "Barn", icon = "old_boot", color = "#8A5A2B" },
			{ id = "RubberDuck", name = "Rubber Duck", rarity = "Common", value = 10, zone = "Barn", icon = "rubber_duck", color = "#FFD23A" },
			{ id = "ToyRobot", name = "Toy Robot", rarity = "Uncommon", value = 40, zone = "Barn", icon = "toy_robot", color = "#9AA0AD" },
			{ id = "Pearl", name = "Pearl", rarity = "Rare", value = 150, zone = "Beach", icon = "pearl", color = "#F2F4F8" },
			{ id = "GoldRing", name = "Gold Ring", rarity = "Rare", value = 300, zone = "Beach", icon = "gold_ring", color = "#FFD23A" },
			{ id = "AncientCoin", name = "Ancient Coin", rarity = "Epic", value = 1_200, zone = "Beach", icon = "ancient_coin", color = "#E3A54C" },
			{ id = "MagicCrystal", name = "Magic Crystal", rarity = "Legendary", value = 6_000, zone = "Frozen", icon = "magic_crystal", color = "#A35CFF" },
			{ id = "GoldenNeedle", name = "Golden Needle", rarity = "Mythic", value = 50_000, zone = "Frozen", icon = "golden_needle", color = "#FFD23A" },
			{ id = "RainbowNeedle", name = "Rainbow Needle", rarity = "Secret", value = 1_000_000, zone = "Frozen", icon = "rainbow_needle", color = "#FF5C8A" },
		} :: { Types.UnitDef },
		zones = {
			{ id = "Barn", name = "Old Barn", reward = { currency = "Gems", amount = 25 } },
			{ id = "Beach", name = "Sandy Beach", reward = { currency = "Gems", amount = 75 } },
			{ id = "Frozen", name = "Frozen Cave", reward = { currency = "Gems", amount = 250, spins = 2 } },
		} :: { Types.IndexZone },
	},
	search = {
		piles = {
			{ id = "Hay", zone = "Barn", findChance = 0.35, coins = { currency = "Money", amount = 1 }, entries = { { unit = "OldBoot", weight = 55 }, { unit = "RubberDuck", weight = 32 }, { unit = "ToyRobot", weight = 12 }, { unit = "GoldenNeedle", weight = 0.02 } } :: { Types.PoolEntry } },
			{ id = "Sand", zone = "Beach", findChance = 0.3, coins = { currency = "Money", amount = 10 }, entries = { { unit = "Pearl", weight = 55 }, { unit = "GoldRing", weight = 32 }, { unit = "AncientCoin", weight = 13 } } :: { Types.PoolEntry } },
			{ id = "Snow", zone = "Frozen", findChance = 0.25, coins = { currency = "Money", amount = 100 }, entries = { { unit = "MagicCrystal", weight = 85 }, { unit = "GoldenNeedle", weight = 14 }, { unit = "RainbowNeedle", weight = 1 } } :: { Types.PoolEntry } },
		} :: { Types.Pile },
		tools = {
			{ id = "Hands", name = "Bare Hands", power = 1, cooldown = 0.6 },
			{ id = "Shovel", name = "Shovel", power = 2, cooldown = 0.5, price = { currency = "Money", amount = 300 } },
			{ id = "Drill", name = "Drill", power = 5, cooldown = 0.35, price = { currency = "Money", amount = 20_000 } },
			{ id = "Laser", name = "Laser Digger", power = 12, cooldown = 0.25, price = { currency = "Money", amount = 600_000 } },
		} :: { Types.SearchTool },
		bag = 10,
		depositCurrency = "Money",
	},
	zones = {
		list = {
			{ id = "Barn", name = "Old Barn", order = 1 },
			{ id = "Beach", name = "Sandy Beach", difficulty = "😐", order = 2, price = { currency = "Money", amount = 15_000 } },
			{ id = "Frozen", name = "Frozen Cave", difficulty = "😱", order = 3, price = { currency = "Money", amount = 300_000 } },
		} :: { Types.ZoneDef },
	},
	upgrades = {
		{ id = "Bag", name = "Bigger Bag", desc = "+5 bag space per level", icon = "inventory", effect = "bag", per = 5, maxLevel = 10, base = 200, growth = 1.8 },
		{ id = "Power", name = "Dig Power", desc = "+1 dig power per level", icon = "pickaxe", effect = "power", per = 1, maxLevel = 10, base = 500, growth = 2 },
		{ id = "Cash", name = "Better Prices", desc = "+15% Money per level", icon = "money_boost", effect = "stat:Money", per = 0.15, kind = "add", maxLevel = 20, base = 800, growth = 1.7 },
	} :: { Types.UpgradeDef },
	objectives = {
		{ id = "dig", text = "Dig in the haystack", stat = "Dig", target = 1 },
		{ id = "found", text = "Find a treasure", stat = "Found", target = 1 },
		{ id = "deposit", text = "Deposit your bag", stat = "Deposit", target = 1 },
		{ id = "earn1", text = "Earn %s", stat = "MoneyEarned", target = 500, money = true },
		{ id = "tool", text = "Buy a Shovel", stat = "ToolBought", target = 1 },
		{ id = "found2", text = "Find %s treasures", stat = "Found", target = 25 },
		{ id = "zone", text = "Unlock the Sandy Beach", stat = "ZoneUnlocked", target = 1 },
		{ id = "rare", text = "Find a Rare treasure", stat = "RareFound", target = 1 },
		{ id = "rebirth", text = "Rebirth once", stat = "Rebirth", target = 1 },
	} :: { Types.ObjectiveDef },
	quests = {
		{ id = "dig", text = "Dig %s times", stat = "Dig", target = 150, reward = { currency = "Gems", amount = 10 } },
		{ id = "found", text = "Find %s treasures", stat = "Found", target = 30, reward = { currency = "Money", incomeMinutes = 5 } },
		{ id = "deposit", text = "Deposit %s times", stat = "Deposit", target = 5, reward = { boost = "Luck2x", seconds = 600 } },
		{ id = "earn", text = "Earn %s", stat = "MoneyEarned", target = 40_000, money = true, reward = { spins = 1 } },
		{ id = "rare", text = "Find %s Rare treasures", stat = "RareFound", target = 2, reward = { currency = "Gems", amount = 15 } },
	} :: { Types.Quest },
	shop = {
		products = {
			{ key = "LaserPack", productId = 0, name = "Laser Digger", desc = "Unlock the Laser Digger (12 dig power)", icon = "pickaxe", robux = 399, category = "Featured", grant = { { item = "Tool:Laser" } } },
		} :: { Types.ShopProduct },
	},
	map = {
		theme = "farm",
		shops = { "Shop", "Tools", "Upgrades", "Index" },
		leaderboard = true,
		groupChest = true,
		spin = true,
		nextUpdate = "Saturday 3PM EST",
	},
}

return recipe
