--!strict
-- Receta "cultivo" (Grow a Garden): la tienda de semillas se repone cada 5 minutos (igual en todos los
-- servidores, las raras aparecen poco), se plantan en las parcelas de la base, crecen aunque el
-- jugador no esté y se cosechan para vender; algunas salen con mutación (Gold, Rainbow) o gigantes. Es
-- una muestra: cada juego trae sus cultivos, tiempos, precios y mapa.

local Types = require("../Types")

local recipe: Types.KitConfig = {
	name = "GrowGarden",
	leaderstats = { "Money", "Rebirths" },
	units = {
		label = "Crops",
		maxInventory = 120,
		mutations = true,
		sizes = true,
		announceFrom = "Legendary",
		luckyFrom = "Rare",
		list = {
			{ id = "Carrot", name = "Carrot", rarity = "Common", value = 18, icon = "carrot", color = "#FF9F1A" },
			{ id = "Tomato", name = "Tomato", rarity = "Common", value = 75, icon = "tomato", color = "#FF3B4F" },
			{ id = "Corn", name = "Corn", rarity = "Uncommon", value = 220, icon = "corn", color = "#FFD23A" },
			{ id = "Strawberry", name = "Strawberry", rarity = "Uncommon", value = 600, icon = "strawberry", color = "#FF5C8A" },
			{ id = "Pumpkin", name = "Pumpkin", rarity = "Rare", value = 2_000, icon = "pumpkin", color = "#FF7A1A" },
			{ id = "Watermelon", name = "Watermelon", rarity = "Epic", value = 6_500, icon = "watermelon", color = "#46D64B" },
			{ id = "DragonFruit", name = "Dragon Fruit", rarity = "Legendary", value = 25_000, icon = "dragon_fruit", color = "#FF5CE1" },
			{ id = "GoldenApple", name = "Golden Apple", rarity = "Mythic", value = 120_000, icon = "golden_apple", color = "#FFD23A" },
			{ id = "RainbowMelon", name = "Rainbow Melon", rarity = "Secret", value = 900_000, icon = "rainbow_melon", color = "#A35CFF" },
		} :: { Types.UnitDef },
	},
	garden = {
		restock = 300,
		tiles = 4,
		maxTiles = 12,
		tilePrices = { 500, 2_000, 8_000, 30_000, 100_000, 400_000, 1_500_000, 6_000_000 },
		mutationChance = 0.05,
		seeds = {
			{ id = "Carrot", name = "Carrot Seed", unit = "Carrot", price = { currency = "Money", amount = 10 }, grow = 20, stock = { min = 4, max = 10 } },
			{ id = "Tomato", name = "Tomato Seed", unit = "Tomato", price = { currency = "Money", amount = 40 }, grow = 45, stock = { min = 3, max = 8 } },
			{ id = "Corn", name = "Corn Seed", unit = "Corn", price = { currency = "Money", amount = 120 }, grow = 90, stock = { min = 2, max = 6 } },
			{ id = "Strawberry", name = "Strawberry Seed", unit = "Strawberry", price = { currency = "Money", amount = 300 }, grow = 150, stock = { min = 2, max = 5 } },
			{ id = "Pumpkin", name = "Pumpkin Seed", unit = "Pumpkin", price = { currency = "Money", amount = 1_000 }, grow = 300, stock = { min = 1, max = 4 } },
			{ id = "Watermelon", name = "Watermelon Seed", unit = "Watermelon", price = { currency = "Money", amount = 3_000 }, grow = 600, stock = { min = 1, max = 3 } },
			{ id = "DragonFruit", name = "Dragon Fruit Seed", unit = "DragonFruit", price = { currency = "Money", amount = 11_000 }, grow = 1_200, stock = { min = 1, max = 2 }, chance = 0.4 },
			{ id = "GoldenApple", name = "Golden Apple Seed", unit = "GoldenApple", price = { currency = "Money", amount = 50_000 }, grow = 2_400, stock = { min = 1, max = 1 }, chance = 0.15 },
			{ id = "RainbowMelon", name = "Rainbow Melon Seed", unit = "RainbowMelon", price = { currency = "Money", amount = 300_000 }, grow = 3_600, stock = { min = 1, max = 1 }, chance = 0.05 },
		} :: { Types.Seed },
	},
	-- La base es la huerta: sin espacios para unidades, solo parcelas.
	plots = { label = "Garden", count = 6, slots = 0, maxSlots = 0, collect = "auto" },
	sell = { keepFrom = "Legendary", anywherePass = "SellAnywhere" },
	upgrades = {
		{ id = "Grow", name = "Fertilizer", desc = "Plants grow 5% faster per level", icon = "seed", effect = "grow", per = 0.05, maxLevel = 10, base = 500, growth = 1.9 },
		{ id = "Tiles", name = "Extra Tiles", desc = "+1 garden tile per level", icon = "base", effect = "tiles", per = 1, maxLevel = 4, prices = { 10_000, 150_000, 2_000_000, 25_000_000 } },
		{ id = "Cash", name = "Better Prices", desc = "+15% Money per level", icon = "money_boost", effect = "stat:Money", per = 0.15, kind = "add", maxLevel = 20, base = 800, growth = 1.7 },
	} :: { Types.UpgradeDef },
	objectives = {
		{ id = "seed", text = "Buy a seed", stat = "SeedBought", target = 1 },
		{ id = "plant", text = "Plant it in your garden", stat = "Plant", target = 1 },
		{ id = "harvest1", text = "Harvest your crop", stat = "Harvest", target = 1 },
		{ id = "sell", text = "Sell your crops", stat = "Sell", target = 1 },
		{ id = "earn1", text = "Earn %s", stat = "MoneyEarned", target = 300, money = true },
		{ id = "tile", text = "Buy a new tile", stat = "TileBought", target = 1 },
		{ id = "harvest2", text = "Harvest %s crops", stat = "Harvest", target = 25 },
		{ id = "rare", text = "Grow a Rare crop", stat = "RareFound", target = 1 },
		{ id = "rebirth", text = "Rebirth once", stat = "Rebirth", target = 1 },
	} :: { Types.ObjectiveDef },
	quests = {
		{ id = "plant", text = "Plant %s seeds", stat = "Plant", target = 20, reward = { currency = "Gems", amount = 5 } },
		{ id = "harvest", text = "Harvest %s crops", stat = "Harvest", target = 20, reward = { currency = "Money", incomeMinutes = 5 } },
		{ id = "sell", text = "Sell %s times", stat = "Sell", target = 5, reward = { spins = 1 } },
		{ id = "earn", text = "Earn %s", stat = "MoneyEarned", target = 25_000, money = true, reward = { boost = "Luck2x", seconds = 600 } },
		{ id = "rare", text = "Grow %s Rare crops", stat = "RareFound", target = 2, reward = { currency = "Gems", amount = 15 } },
	} :: { Types.Quest },
	shop = {
		products = {
			{ key = "GoldenAppleSeeds", productId = 0, name = "3 Golden Apple Seeds", desc = "Get 3 Golden Apple seeds (Mythic crop)", icon = "golden_apple", robux = 149, category = "Featured", grant = { { item = "Seed:GoldenApple", count = 3 } } },
		} :: { Types.ShopProduct },
	},
	map = {
		theme = "farm",
		shops = { "Shop", "Seeds", "Sell", "Upgrades", "Index" },
		leaderboard = true,
		groupChest = true,
		spin = true,
		nextUpdate = "Saturday 3PM EST",
	},
}

return recipe
