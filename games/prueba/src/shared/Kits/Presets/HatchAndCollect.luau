--!strict
-- Receta "huevos y mascotas" (Pet Simulator 99, Tap Simulator): tocar da plata, la plata abre huevos
-- (1, 3 u 8 a la vez con pase), las mascotas equipadas multiplican los toques y te siguen, cada mundo
-- se abre pagando y trae huevos mejores, y el índice premia completar cada mundo. Es una muestra: cada
-- juego trae sus propias mascotas, mundos, precios y mapa.

local Types = require("../Types")

local recipe: Types.KitConfig = {
	name = "HatchAndCollect",
	leaderstats = { "Money", "Rebirths" },
	stats = {
		-- Cada toque da plata, multiplicada por las mascotas equipadas (estadística "Taps" de BoostService).
		{ id = "Taps", label = "Taps", icon = "tap", currency = "Money", perClick = 1, clickRate = 8, autoPass = "AutoClicker" },
	} :: { Types.StatDef },
	units = {
		label = "Pets",
		maxInventory = 100,
		mutations = true,
		sizes = true,
		announceFrom = "Legendary",
		luckyFrom = "Rare",
		list = {
			{ id = "Cat", name = "Cat", rarity = "Common", power = 0.1, zone = "Spawn", icon = "cat", color = "#FFB21A" },
			{ id = "Dog", name = "Dog", rarity = "Common", power = 0.15, zone = "Spawn", icon = "dog", color = "#C98B4F" },
			{ id = "Bunny", name = "Bunny", rarity = "Uncommon", power = 0.35, zone = "Forest", icon = "bunny", color = "#FFFFFF" },
			{ id = "Fox", name = "Fox", rarity = "Rare", power = 0.7, zone = "Forest", icon = "fox", color = "#FF9F1A" },
			{ id = "Penguin", name = "Penguin", rarity = "Rare", power = 1, zone = "Snow", icon = "penguin", color = "#2D2F3A" },
			{ id = "Panda", name = "Panda", rarity = "Epic", power = 2, zone = "Snow", icon = "panda", color = "#F2F4F8" },
			{ id = "Tiger", name = "Tiger", rarity = "Legendary", power = 4.5, zone = "Volcano", icon = "tiger", color = "#FF7A1A" },
			{ id = "Elephant", name = "Elephant", rarity = "Mythic", power = 10, zone = "Volcano", icon = "elephant", color = "#9AA0AD" },
		} :: { Types.UnitDef },
		zones = {
			{ id = "Spawn", name = "Spawn Meadow", reward = { currency = "Gems", amount = 25 } },
			{ id = "Forest", name = "Mystic Forest", reward = { currency = "Gems", amount = 50 } },
			{ id = "Snow", name = "Snowy Peaks", reward = { currency = "Gems", amount = 100 } },
			{ id = "Volcano", name = "Lava Volcano", reward = { currency = "Gems", amount = 250, spins = 2 } },
		} :: { Types.IndexZone },
	},
	rolls = {
		autoPass = "AutoHatch",
		luckStat = "Luck",
		list = {
			{ id = "Basic", name = "Basic Egg", price = { currency = "Money", amount = 10 }, zone = "Spawn", look = "egg", pool = { { unit = "Cat", weight = 60 }, { unit = "Dog", weight = 35 }, { unit = "Bunny", weight = 5 } } :: { Types.PoolEntry }, amounts = { { count = 1 }, { count = 3, pass = "TripleHatch" }, { count = 8, pass = "OctoHatch" } } :: { Types.RollAmount } },
			{ id = "Forest", name = "Forest Egg", price = { currency = "Money", amount = 300 }, zone = "Forest", look = "egg", pool = { { unit = "Bunny", weight = 55 }, { unit = "Fox", weight = 35 }, { unit = "Penguin", weight = 10 } } :: { Types.PoolEntry }, amounts = { { count = 1 }, { count = 3, pass = "TripleHatch" }, { count = 8, pass = "OctoHatch" } } :: { Types.RollAmount } },
			{ id = "Snow", name = "Snow Egg", price = { currency = "Money", amount = 7_500 }, zone = "Snow", look = "egg", pool = { { unit = "Penguin", weight = 60 }, { unit = "Panda", weight = 35 }, { unit = "Tiger", weight = 5 } } :: { Types.PoolEntry }, amounts = { { count = 1 }, { count = 3, pass = "TripleHatch" }, { count = 8, pass = "OctoHatch" } } :: { Types.RollAmount } },
			{ id = "Lava", name = "Lava Egg", price = { currency = "Money", amount = 200_000 }, zone = "Volcano", look = "egg", pool = { { unit = "Panda", weight = 50 }, { unit = "Tiger", weight = 45 }, { unit = "Elephant", weight = 5 } } :: { Types.PoolEntry }, amounts = { { count = 1 }, { count = 3, pass = "TripleHatch" }, { count = 8, pass = "OctoHatch" } } :: { Types.RollAmount } },
		} :: { Types.RollDef },
	},
	equip = { slots = 3, maxSlots = 8, stat = "Taps", follow = true, slotPass = "ExtraPets", passSlots = 2 },
	zones = {
		list = {
			{ id = "Spawn", name = "Spawn Meadow", order = 1 },
			{ id = "Forest", name = "Mystic Forest", difficulty = "😐", order = 2, price = { currency = "Money", amount = 2_500 } },
			{ id = "Snow", name = "Snowy Peaks", difficulty = "😟", order = 3, price = { currency = "Money", amount = 60_000 } },
			{ id = "Volcano", name = "Lava Volcano", difficulty = "😱", order = 4, price = { currency = "Money", amount = 1_500_000 }, rebirths = 1 },
		} :: { Types.ZoneDef },
	},
	upgrades = {
		{ id = "TapPower", name = "Tap Power", desc = "+25% Taps per level", icon = "tap", effect = "stat:Taps", per = 0.25, kind = "add", maxLevel = 25, base = 50, growth = 1.55 },
		{ id = "Luck", name = "Hatch Luck", desc = "+10% Luck per level", icon = "luck", effect = "stat:Luck", per = 0.1, kind = "add", maxLevel = 10, base = 500, growth = 2 },
		{ id = "PetSlots", name = "Pet Slots", desc = "+1 pet equipped per level", icon = "pets", effect = "equip", per = 1, maxLevel = 3, prices = { 5_000, 100_000, 2_000_000 } },
		{ id = "Storage", name = "Pet Storage", desc = "+25 pet storage per level", icon = "inventory", effect = "inventory", per = 25, maxLevel = 4, prices = { 1_000, 20_000, 400_000, 8_000_000 } },
	} :: { Types.UpgradeDef },
	objectives = {
		{ id = "tap1", text = "Tap %s times", stat = "Tap", target = 25 },
		{ id = "hatch1", text = "Hatch an egg", stat = "Hatch", target = 1 },
		{ id = "equip", text = "Equip your pet", stat = "Equip", target = 1 },
		{ id = "tap2", text = "Tap %s times", stat = "Tap", target = 500 },
		{ id = "hatch2", text = "Hatch %s eggs", stat = "Hatch", target = 10 },
		{ id = "zone", text = "Unlock the Mystic Forest", stat = "ZoneUnlocked", target = 1 },
		{ id = "rare", text = "Hatch a Rare pet", stat = "RareFound", target = 1 },
		{ id = "rebirth", text = "Rebirth once", stat = "Rebirth", target = 1 },
	} :: { Types.ObjectiveDef },
	quests = {
		{ id = "hatch", text = "Hatch %s eggs", stat = "Hatch", target = 25, reward = { currency = "Gems", amount = 10 } },
		{ id = "tap", text = "Tap %s times", stat = "Tap", target = 1_000, reward = { boost = "Luck2x", seconds = 600 } },
		{ id = "rare", text = "Hatch %s Rare pets", stat = "RareFound", target = 3, reward = { currency = "Gems", amount = 15 } },
		{ id = "upgrade", text = "Buy %s upgrades", stat = "Upgrade", target = 3, reward = { spins = 1 } },
		{ id = "play", text = "Play for %s minutes", stat = "Minutes", target = 15, reward = { currency = "Gems", amount = 5 } },
	} :: { Types.Quest },
	shop = {
		passes = {
			{ key = "TripleHatch", passId = 0, name = "x3 Hatch", desc = "Open 3 eggs at once", icon = "egg", robux = 149, effects = {}, attribute = "PassTripleHatch" },
			{ key = "OctoHatch", passId = 0, name = "x8 Hatch", desc = "Open 8 eggs at once", icon = "egg_gold", robux = 449, effects = {}, attribute = "PassOctoHatch" },
			{ key = "AutoHatch", passId = 0, name = "Auto Hatch", desc = "Keep opening eggs automatically", icon = "egg", robux = 199, effects = {}, attribute = "PassAutoHatch" },
			{ key = "ExtraPets", passId = 0, name = "+2 Pet Slots", desc = "Equip 2 more pets", icon = "pets", robux = 249, effects = {}, attribute = "PassExtraPets" },
		} :: { Types.ShopPass },
		products = {
			{ key = "HugeElephant", productId = 0, name = "Huge Elephant", desc = "Get a Huge Elephant (Mythic) in your inventory", icon = "elephant", robux = 499, category = "Featured", grant = { { item = "Unit:Elephant:Normal:Huge" } } },
		} :: { Types.ShopProduct },
	},
	map = {
		theme = "meadow",
		shops = { "Shop", "Upgrades", "Index" },
		leaderboard = true,
		groupChest = true,
		spin = true,
		nextUpdate = "Saturday 3PM EST",
	},
}

return recipe
