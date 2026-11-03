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
		lock = { seconds = 60, cooldown = 90, pass = "LongLock", passSeconds = 120 }, -- M9 y el pase "Long Lock"
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
	-- "Fast Thief": 1.5x más rápido llevando lo robado (0.7 → 1.05).
	steal = { holdSeconds = 1.5, carrySpeed = 0.7, protectNewSeconds = 300, recentSeconds = 30, pushRange = 10, protectBest = true, fastPass = "FastThief", fastSpeed = 1.05 },
	-- M6: dos del mismo nivel dan uno del siguiente. Mutaciones de la spec: Gold 5 % y Rainbow 1 % (con
	-- "Lucky Fuse", 15 % y 3 %), y nunca se pierde la mejor de las que se fusionan. "Merge Odds" las muestra.
	merge = {
		mode = "tier",
		count = 2,
		odds = { Gold = 0.05, Rainbow = 0.01 },
		lucky = { Gold = 0.15, Rainbow = 0.03 },
		keepMutation = true,
	},
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
	-- Lo que vende este juego además de la tienda del núcleo, con el texto exacto de la spec. Los precios son
	-- de referencia (los fija roblox-monetization en la fase 4) y los ids se completan en el Creator Dashboard.
	shop = {
		passes = {
			{ key = "LongLock", passId = 0, name = "Long Lock", desc = "Your base lock lasts 120s instead of 60s", icon = "lock", robux = 149, effects = {}, attribute = "PassLongLock" },
			{ key = "FastThief", passId = 0, name = "Fast Thief", desc = "Carry stolen critters 1.5x faster", icon = "speed", robux = 199, effects = {}, attribute = "PassFastThief" },
		} :: { Types.ShopPass },
		products = {
			-- Aleatorio pago (cambia las probabilidades de la fusión): `random` lo esconde a quien PolicyService se lo restringe.
			{ key = "LuckyFuse10", productId = 0, name = "Lucky Fuse x10", desc = "Your next 10 fuses: Gold 15% · Rainbow 3%", icon = "luck", robux = 49, category = "Kit", random = true, grant = { { item = "Merge:Lucky", count = 10 } } },
			-- Compra directa (no es azar).
			{ key = "BuyZapfrog", productId = 0, name = "Zapfrog", desc = "Get 1 Zapfrog now", icon = "zapfrog", robux = 99, category = "Kit", grant = { { item = "Unit:Zapfrog" } } },
		} :: { Types.ShopProduct },
	},
	-- Emoji de los critters hasta subir sus íconos (assets/ui/unit-icons/critters).
	iconFallbacks = {
		pebble_pup = "🐶",
		mossling = "🌿",
		bubblebug = "🐞",
		zapfrog = "🐸",
		cloud_kitty = "🐱",
		lava_lizard = "🦎",
		star_owl = "🦉",
		crystal_dragon = "🐉",
	},
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
