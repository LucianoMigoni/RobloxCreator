--!strict
-- Todo lo que se vende por Robux, como en los hits: muchas compras repetibles (Developer Products),
-- pocos pases fuertes, una suscripción VIP y el anuncio con premio. Los ids se crean en el Creator
-- Dashboard; 0 o "" = todavía sin crear (no se ofrece). El precio real lo pone el Dashboard y el
-- cliente lo lee con GetProductInfoAsync; `robux` es solo la referencia del diseño (precios de los
-- hits en skills/_shared/hits-2026.md: impulso 9–99, base 99–399, premium 400–999, ballenas 1 000+).
-- Cada producto dice su efecto exacto en `desc` (regla oficial) y en inglés.

local Types = require("../Types")

export type Category = "Featured" | "Boosts" | "Currency" | "Passes" | "Server" | "Spins" | "Kit"

export type Product = {
	key: string,
	productId: number,
	name: string,
	desc: string,
	icon: string, -- nombre de ícono (shared/Icons)
	robux: number,
	category: Category,
	grant: { Types.Reward },
	-- Es o alimenta azar pago (tiradas, suerte): se oculta a quien PolicyService no se lo permite.
	random: boolean?,
	once: boolean?, -- solo una vez por jugador (Starter Pack)
	tag: string?, -- "BEST VALUE" solo si es cierto
	-- Regalo: el producto da a otro jugador del servidor el pase `giftOf`.
	giftOf: string?,
}

export type Effect = { stat: string, kind: "mult" | "add", value: number }

export type Pass = {
	key: string,
	passId: number,
	name: string,
	desc: string,
	icon: string,
	robux: number,
	effects: { Effect },
	-- Atributo que queda en el jugador mientras lo tiene (los kits lo miran para sus ventajas).
	attribute: string,
}

export type Subscription = {
	key: string,
	subscriptionId: string,
	name: string,
	desc: string,
	icon: string,
	effects: { Effect },
	attribute: string,
}

export type Item = { name: string, price: number, currency: string? }

return {
	PRODUCTS = {
		-- Impulsos baratos de compra repetida ("10 MINUTOS 5 R$, 30 MINUTOS 14 R$, 1 HORA 25 R$").
		{ key = "Money2x10", productId = 0, name = "2x Money (10 min)", desc = "Doubles all money you earn for 10 minutes", icon = "money_boost", robux = 5, category = "Boosts", grant = { { boost = "Money2x", seconds = 600 } } },
		{ key = "Money2x30", productId = 0, name = "2x Money (30 min)", desc = "Doubles all money you earn for 30 minutes", icon = "money_boost", robux = 14, category = "Boosts", grant = { { boost = "Money2x", seconds = 1800 } } },
		{ key = "Money2x60", productId = 0, name = "2x Money (1 hour)", desc = "Doubles all money you earn for 1 hour", icon = "money_boost", robux = 25, category = "Boosts", grant = { { boost = "Money2x", seconds = 3600 } } },
		{ key = "Luck2x30", productId = 0, name = "2x Luck (30 min)", desc = "Rare results are 2x more likely for 30 minutes", icon = "luck", robux = 19, category = "Boosts", random = true, grant = { { boost = "Luck2x", seconds = 1800 } } },
		-- Para todo el servidor: el que compra queda como héroe y todos lo ven.
		{ key = "ServerLuck", productId = 0, name = "Server Luck x2 (15 min)", desc = "Everyone in this server gets 2x Luck for 15 minutes", icon = "luck", robux = 119, category = "Server", random = true, grant = { { serverBoost = "ServerLuck2x", seconds = 900 } } },
		{ key = "ServerMoney", productId = 0, name = "Server Money x2 (15 min)", desc = "Everyone in this server earns 2x money for 15 minutes", icon = "money_boost", robux = 99, category = "Server", grant = { { serverBoost = "ServerMoney2x", seconds = 900 } } },
		-- Plata: N minutos de las ganancias actuales (sigue valiendo a medida que el jugador crece).
		{ key = "CashS", productId = 0, name = "Stack of Cash", desc = "Get 30 minutes of your earnings", icon = "cash", robux = 29, category = "Currency", grant = { { currency = "Money", incomeMinutes = 30 } } },
		{ key = "CashM", productId = 0, name = "Bag of Cash", desc = "Get 2 hours of your earnings", icon = "cash", robux = 99, category = "Currency", grant = { { currency = "Money", incomeMinutes = 120 } } },
		{ key = "CashL", productId = 0, name = "Vault of Cash", desc = "Get 10 hours of your earnings", icon = "chest", robux = 399, category = "Currency", tag = "BEST VALUE", grant = { { currency = "Money", incomeMinutes = 600 } } },
		{ key = "Gems100", productId = 0, name = "100 Gems", desc = "Get 100 Gems", icon = "gem", robux = 49, category = "Currency", grant = { { currency = "Gems", amount = 100 } } },
		{ key = "Gems1000", productId = 0, name = "1,000 Gems", desc = "Get 1,000 Gems", icon = "gem", robux = 399, category = "Currency", grant = { { currency = "Gems", amount = 1000 } } },
		-- Tiradas de la ruleta (aleatorio pago: probabilidades en cada casilla).
		{ key = "Spins3", productId = 0, name = "3 Spins", desc = "3 spins of the prize wheel", icon = "spin", robux = 49, category = "Spins", random = true, grant = { { spins = 3 } } },
		{ key = "Spins10", productId = 0, name = "10 Spins", desc = "10 spins of the prize wheel", icon = "spin", robux = 149, category = "Spins", random = true, grant = { { spins = 10 } } },
		-- Una sola vez, precio de impulso: la primera compra rompe la barrera de pagar.
		{ key = "StarterPack", productId = 0, name = "Starter Pack", desc = "1 hour of earnings + 100 Gems + 2x Money for 30 minutes", icon = "gift", robux = 9, category = "Featured", once = true, grant = { { currency = "Money", incomeMinutes = 60 }, { currency = "Gems", amount = 100 }, { boost = "Money2x", seconds = 1800 } } },
		-- Duplicar lo ganado sin conexión (se ofrece en el cartel de bienvenida).
		{ key = "OfflineDouble", productId = 0, name = "Double Offline Earnings", desc = "Doubles the money you made while away", icon = "timer", robux = 25, category = "Featured", grant = {} },
		-- Regalos de pases para otro jugador del servidor (botón de regalo junto a cada pase).
		{ key = "GiftMoney2x", productId = 0, name = "Gift: 2x Money", desc = "Give the 2x Money pass to a player in this server", icon = "gift", robux = 399, category = "Passes", giftOf = "Money2x", grant = {} },
	} :: { Product },

	PASSES = {
		{ key = "Money2x", passId = 0, name = "2x Money", desc = "Earn 2x money forever", icon = "money_boost", robux = 399, effects = { { stat = "Money", kind = "mult", value = 2 } }, attribute = "PassMoney2x" },
		{ key = "Luck2x", passId = 0, name = "2x Luck", desc = "Rare results are 2x more likely forever", icon = "luck", robux = 499, effects = { { stat = "Luck", kind = "mult", value = 2 } }, attribute = "PassLuck2x" },
		{ key = "Speed2x", passId = 0, name = "2x Speed", desc = "Move 2x faster forever", icon = "speed", robux = 249, effects = { { stat = "Speed", kind = "mult", value = 2 } }, attribute = "PassSpeed2x" },
		{ key = "VIP", passId = 0, name = "VIP", desc = "+25% money, VIP tag and VIP-only perks", icon = "crown", robux = 349, effects = { { stat = "Money", kind = "add", value = 0.25 } }, attribute = "PassVIP" },
		{ key = "AutoCollect", passId = 0, name = "Auto Collect", desc = "Your money is collected automatically", icon = "magnet", robux = 149, effects = {}, attribute = "PassAutoCollect" },
		{ key = "ExtraSlots", passId = 0, name = "+4 Slots", desc = "4 more slots in your base", icon = "base", robux = 299, effects = {}, attribute = "PassExtraSlots" },
	} :: { Pass },

	-- Suscripción mensual (oficial de Roblox, se cobra cada mes). Precio y nombre en el Dashboard.
	SUBSCRIPTIONS = {
		{ key = "VIPClub", subscriptionId = "", name = "VIP Club (monthly)", desc = "x1.5 money and a daily VIP gift while subscribed", icon = "crown", effects = { { stat = "Money", kind = "mult", value = 1.5 } }, attribute = "SubVIPClub" },
	} :: { Subscription },

	-- Anuncio con premio ("¡Ver anuncio!"): el premio es un Developer Product propio, nunca aleatorio.
	-- Requisitos del creador y del juego en /production/promotion/rewarded-video-ads.
	AD_REWARD = { productId = 0, grant = { { boost = "Money2x", seconds = 600 } } :: { Types.Reward } },

	-- Compras con monedas del juego (cosméticos simples); los kits tienen sus propias tiendas.
	ITEMS = {} :: { [string]: Item },

	PURCHASE_RATE = { count = 3, perSeconds = 1 },
	-- PurchaseIds recientes que se guardan para no otorgar dos veces la misma compra de Robux.
	MAX_RECEIPTS = 100,
}
