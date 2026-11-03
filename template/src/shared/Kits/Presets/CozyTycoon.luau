--!strict
-- Receta "tycoon de negocio" (My Small Business, Cook the Chicken): cocinar tocando da plata al toque,
-- los puestos del local se compran pisando su botón (cada uno abre el siguiente) y pagan por segundo,
-- se cobra en la placa y las mejoras suben la cocina y las ganancias. Es una muestra: cada juego trae
-- su negocio, sus puestos, precios y mapa.

local Types = require("../Types")

local recipe: Types.KitConfig = {
	name = "CozyTycoon",
	leaderstats = { "Money", "Rebirths" },
	stats = {
		-- La acción graciosa del juego: cada toque cocina y da plata.
		{ id = "Cooking", label = "Cooking", icon = "tap", currency = "Money", perClick = 1, clickRate = 8, autoPass = "AutoClicker" },
	} :: { Types.StatDef },
	plots = { label = "Shop", count = 6, slots = 0, maxSlots = 0, collect = "pad", autoCollectPass = "AutoCollect" },
	tycoon = {
		buildings = {
			{ id = "Lemonade", name = "Lemonade Stand", price = { currency = "Money", amount = 10 }, income = 1 },
			{ id = "Cookies", name = "Cookie Oven", price = { currency = "Money", amount = 60 }, income = 4, after = "Lemonade" },
			{ id = "Juice", name = "Juice Bar", price = { currency = "Money", amount = 300 }, income = 15, after = "Cookies" },
			{ id = "Pizza", name = "Pizza Oven", price = { currency = "Money", amount = 1_500 }, income = 60, after = "Juice" },
			{ id = "IceCream", name = "Ice Cream Cart", price = { currency = "Money", amount = 7_000 }, income = 250, after = "Pizza" },
			{ id = "Burgers", name = "Burger Grill", price = { currency = "Money", amount = 30_000 }, income = 1_000, after = "IceCream" },
			{ id = "Sushi", name = "Sushi Bar", price = { currency = "Money", amount = 120_000 }, income = 4_000, after = "Burgers" },
			{ id = "Cafe", name = "Fancy Cafe", price = { currency = "Money", amount = 500_000 }, income = 15_000, after = "Sushi" },
		} :: { Types.Building },
	},
	upgrades = {
		{ id = "Cooking", name = "Chef Skills", desc = "+50% cooking money per level", icon = "tap", effect = "stat:Cooking", per = 0.5, kind = "add", maxLevel = 20, base = 100, growth = 1.6 },
		{ id = "Cash", name = "Better Prices", desc = "+15% Money per level", icon = "money_boost", effect = "stat:Money", per = 0.15, kind = "add", maxLevel = 20, base = 800, growth = 1.7 },
	} :: { Types.UpgradeDef },
	objectives = {
		{ id = "cook", text = "Cook %s times", stat = "Tap", target = 20 },
		{ id = "build1", text = "Build the Lemonade Stand", stat = "Build", target = 1 },
		{ id = "collect", text = "Collect your cash", stat = "Collect", target = 1 },
		{ id = "earn1", text = "Earn %s", stat = "MoneyEarned", target = 500, money = true },
		{ id = "build2", text = "Build %s things", stat = "Build", target = 4 },
		{ id = "upgrade", text = "Buy an upgrade", stat = "Upgrade", target = 1 },
		{ id = "earn2", text = "Earn %s", stat = "MoneyEarned", target = 50_000, money = true },
		{ id = "rebirth", text = "Rebirth once", stat = "Rebirth", target = 1 },
	} :: { Types.ObjectiveDef },
	quests = {
		{ id = "cook", text = "Cook %s times", stat = "Tap", target = 300, reward = { currency = "Gems", amount = 5 } },
		{ id = "build", text = "Build %s things", stat = "Build", target = 3, reward = { spins = 1 } },
		{ id = "collect", text = "Collect cash %s times", stat = "Collect", target = 15, reward = { currency = "Money", incomeMinutes = 5 } },
		{ id = "earn", text = "Earn %s", stat = "MoneyEarned", target = 30_000, money = true, reward = { boost = "Money2x", seconds = 600 } },
		{ id = "upgrade", text = "Buy %s upgrades", stat = "Upgrade", target = 3, reward = { currency = "Gems", amount = 10 } },
	} :: { Types.Quest },
	shop = {
		passes = {
			{ key = "ChefHat", passId = 0, name = "Chef Hat", desc = "Cooking gives 2x money forever", icon = "crown", robux = 199, effects = { { stat = "Cooking", kind = "mult", value = 2 } }, attribute = "PassChefHat" },
		} :: { Types.ShopPass },
	},
	map = {
		theme = "city",
		bases = "building",
		shops = { "Shop", "Upgrades" },
		leaderboard = true,
		groupChest = true,
		spin = true,
		nextUpdate = "Saturday 3PM EST",
	},
}

return recipe
