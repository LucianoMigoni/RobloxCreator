--!strict
-- Receta "robar y colocar" (Steal a Brainrot, Steal An Egg): las unidades pasan por una cinta con
-- precio, se compran y se colocan en la base, que paga por segundo; se cobra pisando la placa, se
-- fusionan tres iguales en una mutación mejor y se roba de las bases ajenas (con traba de láser).
-- Es una muestra: cada juego trae sus propias unidades, nombres, precios y mapa.

local Types = require("../Types")

local recipe: Types.KitConfig = {
	name = "StealAndPlace",
	leaderstats = { "Money", "Rebirths" },
	units = {
		label = "Snacks",
		maxInventory = 60,
		mutations = true,
		announceFrom = "Legendary",
		luckyFrom = "Rare",
		list = {
			{ id = "BananaBuddy", name = "Banana Buddy", rarity = "Common", price = 10, value = 5, income = 1, icon = "banana_buddy", color = "#FFD23A" },
			{ id = "ToastPal", name = "Toast Pal", rarity = "Common", price = 25, value = 12, income = 2, icon = "toast_pal", color = "#E0A060" },
			{ id = "CactusCowboy", name = "Cactus Cowboy", rarity = "Uncommon", price = 120, value = 60, income = 8, icon = "cactus_cowboy", color = "#46D64B" },
			{ id = "DiscoDonut", name = "Disco Donut", rarity = "Rare", price = 600, value = 300, income = 35, icon = "disco_donut", color = "#FF5C8A" },
			{ id = "PizzaPirate", name = "Pizza Pirate", rarity = "Epic", price = 3_000, value = 1_500, income = 150, icon = "pizza_pirate", color = "#FF9F1A" },
			{ id = "RoboPickle", name = "Robo Pickle", rarity = "Legendary", price = 18_000, value = 9_000, income = 800, icon = "robo_pickle", color = "#7EE35F" },
			{ id = "NinjaNoodle", name = "Ninja Noodle", rarity = "Mythic", price = 120_000, value = 60_000, income = 4_500, icon = "ninja_noodle", color = "#2D2F3A" },
			{ id = "AstroAvocado", name = "Astro Avocado", rarity = "Mythic", price = 500_000, value = 250_000, income = 16_000, icon = "astro_avocado", color = "#3FA944" },
			{ id = "TacoKing", name = "Taco King", rarity = "Secret", price = 3_000_000, value = 1_500_000, income = 90_000, icon = "taco_king", color = "#FFB21A" },
		} :: { Types.UnitDef },
	},
	plots = {
		label = "Base",
		count = 8,
		slots = 6,
		maxSlots = 16,
		slotPrices = { 500, 2_500, 10_000, 40_000, 150_000, 600_000, 2_000_000, 8_000_000, 30_000_000, 100_000_000 },
		collect = "pad",
		autoCollectPass = "AutoCollect",
		lock = { seconds = 60, cooldown = 30 },
		slotPass = "ExtraSlots",
		passSlots = 4,
	},
	belt = {
		spawnEvery = 2.5,
		walkSeconds = 24,
		maxOnBelt = 10,
		pool = {
			{ unit = "BananaBuddy", weight = 400 },
			{ unit = "ToastPal", weight = 280 },
			{ unit = "CactusCowboy", weight = 160 },
			{ unit = "DiscoDonut", weight = 80 },
			{ unit = "PizzaPirate", weight = 40 },
			{ unit = "RoboPickle", weight = 15 },
			{ unit = "NinjaNoodle", weight = 4 },
			{ unit = "AstroAvocado", weight = 1.5 },
			{ unit = "TacoKing", weight = 0.25 },
		} :: { Types.PoolEntry },
	},
	steal = { holdSeconds = 1.5, carrySpeed = 0.7, protectNewSeconds = 120, recentSeconds = 60, pushRange = 10, protectBest = true },
	merge = { mode = "variant", count = 3, variantChain = { "Normal", "Gold", "Diamond", "Rainbow" }, seconds = 30, machine = true },
	sell = { keepFrom = "Legendary", anywherePass = "SellAnywhere" },
	upgrades = {
		{ id = "Cash", name = "Cash Boost", desc = "+15% Money per level", icon = "money_boost", effect = "stat:Money", per = 0.15, kind = "add", maxLevel = 20, base = 1_000, growth = 1.7 },
		{ id = "Slots", name = "More Slots", desc = "+1 slot in your base per level", icon = "base", effect = "slots", per = 1, maxLevel = 4, prices = { 5_000, 50_000, 500_000, 5_000_000 } },
		{ id = "Luck", name = "Belt Luck", desc = "+10% Luck on the belt per level", icon = "luck", effect = "stat:Luck", per = 0.1, kind = "add", maxLevel = 10, base = 2_500, growth = 2 },
	} :: { Types.UpgradeDef },
	-- El tutorial sin pantallas: cada objetivo enseña el paso siguiente del loop.
	objectives = {
		{ id = "buy", text = "Buy a snack from the belt", stat = "UnitBought", target = 1 },
		{ id = "place", text = "Place it in your base", stat = "Place", target = 1 },
		{ id = "collect", text = "Collect your cash", stat = "Collect", target = 1 },
		{ id = "earn1", text = "Earn %s", stat = "MoneyEarned", target = 500, money = true },
		{ id = "steal", text = "Steal a snack from another base", stat = "Steal", target = 1 },
		{ id = "lock", text = "Lock your base", stat = "Lock", target = 1 },
		{ id = "merge", text = "Merge 3 snacks", stat = "Merge", target = 1 },
		{ id = "earn2", text = "Earn %s", stat = "MoneyEarned", target = 50_000, money = true },
		{ id = "rebirth", text = "Rebirth once", stat = "Rebirth", target = 1 },
	} :: { Types.ObjectiveDef },
	quests = {
		{ id = "buy", text = "Buy %s snacks", stat = "UnitBought", target = 10, reward = { currency = "Gems", amount = 5 } },
		{ id = "steal", text = "Steal %s snacks", stat = "Steal", target = 3, reward = { boost = "Luck2x", seconds = 600 } },
		{ id = "collect", text = "Collect cash %s times", stat = "Collect", target = 20, reward = { currency = "Money", incomeMinutes = 5 } },
		{ id = "merge", text = "Merge %s times", stat = "Merge", target = 2, reward = { currency = "Gems", amount = 10 } },
		{ id = "earn", text = "Earn %s", stat = "MoneyEarned", target = 100_000, money = true, reward = { spins = 1 } },
		{ id = "push", text = "Push %s thieves", stat = "Push", target = 5, reward = { boost = "Money2x", seconds = 600 } },
	} :: { Types.Quest },
	shop = {
		products = {
			-- Comprar la unidad más rara directo (no es aleatorio): el clásico "OP" de los hits.
			{ key = "TacoKingPack", productId = 0, name = "Taco King", desc = "Get a Taco King (Secret, $90K/s) in your inventory", icon = "taco_king", robux = 799, category = "Featured", grant = { { item = "Unit:TacoKing" } } },
			{ key = "GoldNoodle", productId = 0, name = "Gold Ninja Noodle", desc = "Get a Gold Ninja Noodle (Mythic) in your inventory", icon = "ninja_noodle", robux = 299, category = "Kit", grant = { { item = "Unit:NinjaNoodle:Gold" } } },
		} :: { Types.ShopProduct },
	},
	map = {
		theme = "meadow",
		shops = { "Shop", "Sell", "Upgrades", "Index" },
		leaderboard = true,
		groupChest = true,
		spin = true,
		nextUpdate = "Saturday 3PM EST",
		showcase = "TacoKing",
	},
}

return recipe
