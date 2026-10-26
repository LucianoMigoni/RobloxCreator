--!strict
-- Tienda:
-- - Ítems con monedas del juego (RequestPurchase): el servidor cobra y entrega; el cliente solo pide.
-- - Developer Products (Robux) por ProcessReceipt, según la guía oficial "Implement player data and
--   purchasing systems": solo con datos que se pueden guardar, sin otorgar dos veces el mismo
--   PurchaseId, y PurchaseGranted solo después de guardar.
-- - Game Passes: el servidor marca un atributo en el jugador (hasPass); se compra desde el cliente.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local DataService = require("../Data/DataService")
local CurrencyService = require("../Economy/CurrencyService")
local InventoryService = require("../Economy/InventoryService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local Receipts = require("./Receipts")

local ShopService = {}

local productsById: { [number]: ShopConfig.Product } = {}
for _, product in ShopConfig.PRODUCTS do
	if product.productId ~= 0 then
		productsById[product.productId] = product
	end
end

-- Devuelve (true) o (false, código) para que el cliente muestre el motivo.
local function buyItem(player: Player, itemId: string): (boolean, string?)
	local item = ShopConfig.ITEMS[itemId]
	if DataService.get(player) == nil then
		return false, "LOADING"
	end
	if InventoryService.has(player, itemId) then
		return false, "OWNED"
	end
	if not CurrencyService.spend(player, item.price, Enum.AnalyticsEconomyTransactionType.Shop, itemId) then
		return false, "NOT_ENOUGH"
	end
	InventoryService.add(player, itemId)
	return true
end

local function processReceipt(receiptInfo: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	local product = productsById[receiptInfo.ProductId]
	-- Sin jugador o sin producto configurado no se otorga: Roblox vuelve a llamar cuando el jugador entra.
	if not player or not product then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = DataService.waitForData(player)
	if not data or not DataService.canSave(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(receiptInfo.PurchaseId)
	if not Receipts.has(data.processedReceipts, purchaseId) then
		if not CurrencyService.add(player, product.coins, Enum.AnalyticsEconomyTransactionType.IAP, product.name) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		Receipts.record(data.processedReceipts, purchaseId, os.time(), ShopConfig.MAX_RECEIPTS)
	end
	-- Otorgada ahora o antes: se confirma solo si quedó guardada. Si no, Roblox la vuelve a mandar y
	-- el registro evita darla otra vez.
	if DataService.saveAsync(player) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function markPass(player: Player, passId: number)
	for _, pass in ShopConfig.GAME_PASSES do
		if pass.passId == passId then
			player:SetAttribute(pass.attribute, true)
		end
	end
end

local function refreshPasses(player: Player)
	for _, pass in ShopConfig.GAME_PASSES do
		if pass.passId ~= 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.passId)
			if ok and owns then
				player:SetAttribute(pass.attribute, true)
			elseif not ok then
				warn("[ShopService] no se pudo verificar el pase " .. pass.name .. ": " .. tostring(owns))
			end
		end
	end
end

-- Para que otros servicios den el beneficio del pase (`attribute` de ShopConfig.GAME_PASSES).
function ShopService.hasPass(player: Player, attribute: string): boolean
	return player:GetAttribute(attribute) == true
end

function ShopService.start()
	local itemIds = {}
	for id in ShopConfig.ITEMS do
		table.insert(itemIds, id)
	end
	Remotes.onInvoke("RequestPurchase", {
		args = { Validate.oneOf(itemIds) },
		rate = ShopConfig.PURCHASE_RATE,
	}, buyItem)

	MarketplaceService.ProcessReceipt = processReceipt
	-- Solo se escucha en el servidor: ahí `wasPurchased` es el resultado final (en el cliente no es confiable).
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Instance, passId: number, wasPurchased: boolean)
		if wasPurchased and player:IsA("Player") then
			markPass(player, passId)
		end
	end)
	Players.PlayerAdded:Connect(refreshPasses)
	for _, player in Players:GetPlayers() do
		task.spawn(refreshPasses, player)
	end
end

return ShopService
