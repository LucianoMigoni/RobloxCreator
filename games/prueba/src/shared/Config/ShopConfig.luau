--!strict
-- Tienda: ítems con monedas del juego, Developer Products y Game Passes.
-- Los ids de productos y pases se crean en el Creator Dashboard; 0 = todavía sin crear (se ignora).
-- Precios y ofertas los decide roblox-monetization: estos son de ejemplo.

export type Item = { name: string, price: number }
export type Product = { productId: number, name: string, coins: number }
export type GamePass = { passId: number, name: string, attribute: string }

local ShopConfig = {
	ITEMS = {
		SpeedBoots = { name = "Speed Boots", price = 100 },
		Sword = { name = "Sword", price = 250 },
	} :: { [string]: Item },

	PRODUCTS = {
		{ productId = 0, name = "Coin Pack", coins = 500 },
	} :: { Product },

	-- Al tener el pase, el servidor pone `attribute = true` en el jugador (ShopService.hasPass).
	GAME_PASSES = {
		{ passId = 0, name = "VIP", attribute = "PassVip" },
	} :: { GamePass },

	PURCHASE_RATE = { count = 3, perSeconds = 1 },
	-- PurchaseIds recientes que se guardan para no otorgar dos veces la misma compra de Robux.
	MAX_RECEIPTS = 100,
}

return ShopConfig
