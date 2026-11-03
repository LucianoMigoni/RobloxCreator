--!strict
-- Receta "fusión en la granja" (Chicken Farm): se compran pollitos en los puestos (1, 5, 25 o 100 a la
-- vez) que van directo a la base, tres iguales se fusionan en el nivel siguiente (que paga mucho más),
-- se compran más nidos y el multiplicador de plata se sube por Robux (la escalera de los hits). Es una
-- muestra: cada juego trae sus criaturas, niveles, precios y mapa.

local Types = require("../Types")

local recipe: Types.KitConfig = {
	name = "MergeTycoon",
	leaderstats = { "Money", "Rebirths" },
	units = {
		label = "Chickens",
		maxInventory = 60,
		mutations = true,
		announceFrom = "Legendary",
		luckyFrom = "Rare",
		list = {
			{ id = "Chick", name = "Chick", rarity = "Common", tier = 1, income = 1, icon = "chick", color = "#FFE14D" },
			{ id = "Hen", name = "Hen", rarity = "Common", tier = 2, income = 4, icon = "hen", color = "#FFFFFF" },
			{ id = "Rooster", name = "Rooster", rarity = "Uncommon", tier = 3, income = 15, icon = "rooster", color = "#FF5C3A" },
			{ id = "GoldenHen", name = "Golden Hen", rarity = "Rare", tier = 4, income = 60, icon = "golden_hen", color = "#FFD23A" },
			{ id = "RoboHen", name = "Robo Hen", rarity = "Epic", tier = 5, income = 250, icon = "robo_hen", color = "#9AA0AD" },
			{ id = "NinjaHen", name = "Ninja Hen", rarity = "Legendary", tier = 6, income = 1_000, icon = "ninja_hen", color = "#2D2F3A" },
			{ id = "WizardHen", name = "Wizard Hen", rarity = "Mythic", tier = 7, income = 4_500, icon = "wizard_hen", color = "#A35CFF" },
			{ id = "KingRooster", name = "King Rooster", rarity = "Mythic", tier = 8, income = 20_000, icon = "king_rooster", color = "#FFB21A" },
			{ id = "CosmicHen", name = "Cosmic Hen", rarity = "Secret", tier = 9, income = 100_000, icon = "cosmic_hen", color = "#4B3A8B" },
		} :: { Types.UnitDef },
	},
	plots = {
		label = "Farm",
		count = 6,
		slots = 8,
		maxSlots = 20,
		slotPrices = { 100, 400, 1_500, 5_000, 15_000, 50_000, 150_000, 500_000, 1_500_000, 5_000_000, 15_000_000, 50_000_000 },
		collect = "pad",
		autoCollectPass = "AutoCollect",
	},
	rolls = {
		list = {
			{ id = "Chick", name = "Chick Crate", price = { currency = "Money", amount = 10 }, look = "pad", toBase = true, pool = { { unit = "Chick", weight = 100 } } :: { Types.PoolEntry }, amounts = { { count = 1 }, { count = 5 }, { count = 25, pass = "BulkBuy" }, { count = 100, pass = "BulkBuy" } } :: { Types.RollAmount } },
			{ id = "Golden", name = "Golden Crate", price = { currency = "Money", amount = 2_500 }, look = "chest", toBase = true, pool = { { unit = "Chick", weight = 60 }, { unit = "Hen", weight = 30 }, { unit = "Rooster", weight = 9 }, { unit = "GoldenHen", weight = 1 } } :: { Types.PoolEntry }, amounts = { { count = 1 }, { count = 5 }, { count = 25, pass = "BulkBuy" } } :: { Types.RollAmount } },
		} :: { Types.RollDef },
	},
	merge = { mode = "tier", count = 3, mutationChance = 0.03 },
	upgrades = {
		-- La escalera de los hits: cada nivel se compra con Robux ("Upgrade:Multiplier").
		{ id = "Multiplier", name = "Money Multiplier", desc = "+50% Money per level", icon = "money_boost", effect = "stat:Money", per = 0.5, kind = "add", maxLevel = 10, robux = true },
		{ id = "Slots", name = "More Nests", desc = "+1 nest per level", icon = "base", effect = "slots", per = 1, maxLevel = 4, prices = { 2_000, 40_000, 800_000, 15_000_000 } },
		{ id = "Cash", name = "Egg Prices", desc = "+10% Money per level", icon = "cash", effect = "stat:Money", per = 0.1, kind = "add", maxLevel = 20, base = 500, growth = 1.8 },
	} :: { Types.UpgradeDef },
	objectives = {
		{ id = "buy", text = "Buy a chick", stat = "Roll", target = 1 },
		{ id = "buy3", text = "Buy %s chicks", stat = "Roll", target = 3 },
		{ id = "merge1", text = "Merge 3 chicks into a Hen", stat = "Merge", target = 1 },
		{ id = "collect", text = "Collect your cash", stat = "Collect", target = 1 },
		{ id = "earn1", text = "Earn %s", stat = "MoneyEarned", target = 1_000, money = true },
		{ id = "slot", text = "Buy a new nest", stat = "SlotBought", target = 1 },
		{ id = "merge2", text = "Merge %s times", stat = "Merge", target = 10 },
		{ id = "rebirth", text = "Rebirth once", stat = "Rebirth", target = 1 },
	} :: { Types.ObjectiveDef },
	quests = {
		{ id = "merge", text = "Merge %s times", stat = "Merge", target = 15, reward = { currency = "Gems", amount = 10 } },
		{ id = "buy", text = "Buy %s chicks", stat = "Roll", target = 30, reward = { currency = "Money", incomeMinutes = 5 } },
		{ id = "collect", text = "Collect cash %s times", stat = "Collect", target = 20, reward = { spins = 1 } },
		{ id = "earn", text = "Earn %s", stat = "MoneyEarned", target = 100_000, money = true, reward = { boost = "Money2x", seconds = 600 } },
		{ id = "upgrade", text = "Buy %s upgrades", stat = "Upgrade", target = 3, reward = { currency = "Gems", amount = 5 } },
	} :: { Types.Quest },
	shop = {
		passes = {
			{ key = "BulkBuy", passId = 0, name = "Bulk Buy", desc = "Buy chicks 25 and 100 at a time", icon = "pad", robux = 199, effects = {}, attribute = "PassBulkBuy" },
		} :: { Types.ShopPass },
		products = {
			{ key = "MultiplierUp", productId = 0, name = "+50% Money", desc = "Raises your Money Multiplier by one level (+50% money)", icon = "money_boost", robux = 99, category = "Kit", grant = { { item = "Upgrade:Multiplier" } } },
		} :: { Types.ShopProduct },
	},
	map = {
		theme = "farm",
		shops = { "Shop", "Upgrades", "Index" },
		leaderboard = true,
		groupChest = true,
		spin = true,
		nextUpdate = "Saturday 3PM EST",
	},
}

return recipe
