--!strict
-- Receta "+1 por paso y escape" (+1 Speed Keyboard Escape): cada paso suma velocidad (y mueve más
-- rápido), las etapas piden velocidad para seguir, al final se gana una victoria, las cintas de correr
-- suben la velocidad sin moverse, las victorias abren mundos y compran mascotas que multiplican la
-- velocidad, y renacer (con victorias) multiplica lo que se gana por paso. Es una muestra: cada juego
-- trae sus etapas, mundos, mascotas y mapa.

local Types = require("../Types")

local recipe: Types.KitConfig = {
	name = "PlusOneEscape",
	currencies = {
		{ id = "Wins", symbol = "", icon = "trophy", color = "#FFD23A", start = 0, purchasable = false },
	} :: { Types.CurrencyDef },
	leaderstats = { "Speed", "Wins" },
	stats = {
		{ id = "Speed", label = "Speed", icon = "speed", perStep = 1, walkSpeed = { base = 16, per = 0.02, max = 160 }, resetOnRebirth = true },
	} :: { Types.StatDef },
	units = {
		label = "Pets",
		maxInventory = 60,
		mutations = true,
		announceFrom = "Legendary",
		luckyFrom = "Rare",
		list = {
			{ id = "Cat", name = "Zoom Cat", rarity = "Common", power = 0.2, icon = "cat", color = "#FFB21A" },
			{ id = "Dog", name = "Dash Dog", rarity = "Common", power = 0.3, icon = "dog", color = "#C98B4F" },
			{ id = "Bunny", name = "Hop Bunny", rarity = "Uncommon", power = 0.6, icon = "bunny", color = "#FFFFFF" },
			{ id = "Fox", name = "Flash Fox", rarity = "Rare", power = 1.2, icon = "fox", color = "#FF9F1A" },
			{ id = "Penguin", name = "Slide Penguin", rarity = "Epic", power = 2.5, icon = "penguin", color = "#2D2F3A" },
			{ id = "Panda", name = "Turbo Panda", rarity = "Legendary", power = 5, icon = "panda", color = "#F2F4F8" },
			{ id = "Tiger", name = "Rocket Tiger", rarity = "Mythic", power = 12, icon = "tiger", color = "#FF7A1A" },
		} :: { Types.UnitDef },
	},
	rolls = {
		luckStat = "Luck",
		list = {
			{ id = "Grass", name = "Grass Egg", price = { currency = "Wins", amount = 1 }, zone = "Grass", look = "egg", pool = { { unit = "Cat", weight = 60 }, { unit = "Dog", weight = 30 }, { unit = "Bunny", weight = 10 } } :: { Types.PoolEntry }, amounts = { { count = 1 }, { count = 3, pass = "TripleHatch" } } :: { Types.RollAmount } },
			{ id = "Desert", name = "Desert Egg", price = { currency = "Wins", amount = 6 }, zone = "Desert", look = "egg", pool = { { unit = "Bunny", weight = 50 }, { unit = "Fox", weight = 40 }, { unit = "Penguin", weight = 10 } } :: { Types.PoolEntry }, amounts = { { count = 1 }, { count = 3, pass = "TripleHatch" } } :: { Types.RollAmount } },
			{ id = "Space", name = "Space Egg", price = { currency = "Wins", amount = 30 }, zone = "Space", look = "egg", pool = { { unit = "Penguin", weight = 55 }, { unit = "Panda", weight = 40 }, { unit = "Tiger", weight = 5 } } :: { Types.PoolEntry }, amounts = { { count = 1 }, { count = 3, pass = "TripleHatch" } } :: { Types.RollAmount } },
		} :: { Types.RollDef },
	},
	equip = { slots = 3, maxSlots = 6, stat = "Speed", follow = true },
	zones = {
		list = {
			{ id = "Grass", name = "Grass World", order = 1 },
			{ id = "Desert", name = "Desert World", difficulty = "😐", order = 2, price = { currency = "Wins", amount = 10 } },
			{ id = "Space", name = "Space World", difficulty = "😱", order = 3, price = { currency = "Wins", amount = 50 } },
		} :: { Types.ZoneDef },
	},
	stages = {
		count = 20,
		reward = { currency = "Wins", amount = 1 },
		stat = "Speed",
		-- Velocidad que pide cada checkpoint: las primeras salen solas, las últimas piden entrenar.
		requirements = { 0, 50, 120, 220, 350, 520, 750, 1_000, 1_300, 1_700, 2_200, 2_800, 3_500, 4_300, 5_200, 6_300, 7_600, 9_000, 10_600, 12_500 },
		returnToStart = true,
	},
	rebirth = { currency = "Wins", base = 25, growth = 2.5, stat = "Speed" },
	endless = { text = "Win %s times", stat = "Win", base = 10, growth = 2 },
	objectives = {
		{ id = "walk", text = "Walk %s steps", stat = "Steps", target = 100 },
		{ id = "checkpoint", text = "Reach the first checkpoint", stat = "Stage", target = 1 },
		{ id = "win", text = "Reach the end and WIN", stat = "Win", target = 1 },
		{ id = "hatch", text = "Hatch a pet with your Wins", stat = "Hatch", target = 1 },
		{ id = "equip", text = "Equip your pet", stat = "Equip", target = 1 },
		{ id = "train", text = "Gain %s Speed", stat = "SpeedGained", target = 2_000 },
		{ id = "zone", text = "Unlock Desert World", stat = "ZoneUnlocked", target = 1 },
		{ id = "rebirth", text = "Rebirth once", stat = "Rebirth", target = 1 },
	} :: { Types.ObjectiveDef },
	quests = {
		{ id = "win", text = "Win %s times", stat = "Win", target = 3, reward = { currency = "Gems", amount = 10 } },
		{ id = "walk", text = "Walk %s steps", stat = "Steps", target = 5_000, reward = { boost = "Speed2x", seconds = 600 } },
		{ id = "hatch", text = "Hatch %s pets", stat = "Hatch", target = 10, reward = { currency = "Gems", amount = 5 } },
		{ id = "checkpoints", text = "Pass %s checkpoints", stat = "Stage", target = 30, reward = { spins = 1 } },
		{ id = "speed", text = "Gain %s Speed", stat = "SpeedGained", target = 20_000, reward = { boost = "Luck2x", seconds = 600 } },
	} :: { Types.Quest },
	shop = {
		passes = {
			{ key = "TripleHatch", passId = 0, name = "x3 Hatch", desc = "Open 3 eggs at once", icon = "egg", robux = 149, effects = {}, attribute = "PassTripleHatch" },
		} :: { Types.ShopPass },
		products = {
			{ key = "Speed10K", productId = 0, name = "+10K Speed", desc = "Get +10,000 Speed instantly", icon = "speed", robux = 49, category = "Kit", grant = { { item = "Stat:Speed", count = 10_000 } } },
			{ key = "Speed100K", productId = 0, name = "+100K Speed", desc = "Get +100,000 Speed instantly", icon = "speed", robux = 299, category = "Kit", tag = "BEST VALUE", grant = { { item = "Stat:Speed", count = 100_000 } } },
		} :: { Types.ShopProduct },
	},
	map = {
		theme = "candy",
		shops = { "Shop", "Index" },
		treadmills = { stat = "Speed", gains = { 1, 5, 25 } },
		leaderboard = true,
		groupChest = true,
		spin = true,
		nextUpdate = "Saturday 3PM EST",
	},
}

return recipe
