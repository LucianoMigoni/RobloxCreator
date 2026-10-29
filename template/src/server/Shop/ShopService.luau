--!strict
-- Todo lo que se vende, como en los hits (ShopConfig):
-- - Developer Products (Robux) por ProcessReceipt, según la guía oficial "Implement player data and
--   purchasing systems": solo con datos que se pueden guardar, sin otorgar dos veces el mismo
--   PurchaseId y PurchaseGranted solo después de guardar. Cada producto entrega su `grant` con
--   RewardService (impulsos, plata en minutos de ganancia, tiradas, impulsos de servidor...).
-- - Regalos: el comprador elige a otro jugador (SetGiftTarget) y paga el producto `giftOf`; si el otro
--   ya no está, el regalo queda guardado para mandarlo después (SendGiftToken).
-- - Game Passes y la suscripción del juego: atributos en el jugador que BoostService y los kits leen.
-- - Anuncio con premio (WatchRewardedAd): el premio llega por ProcessReceipt con el canal AdReward.
-- - Ítems con monedas del juego (RequestPurchase).
-- - Aleatorio pago: quien no puede comprarlo (PolicyService) queda con el atributo
--   "PaidRandomRestricted" y el cliente no se lo ofrece.

local AdService = game:GetService("AdService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local BoostService = require("../Boosts/BoostService")
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local InventoryService = require("../Economy/InventoryService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local OfflineService = require("../Retention/OfflineService")
local RewardService = require("../Rewards/RewardService")
local Signals = require("../Signals")
local AnnounceService = require("../Social/AnnounceService")
local Receipts = require("./Receipts")

local ShopService = {}

local GIFT_TARGET_SECONDS = 120 -- cuánto vale la elección de destinatario antes de pagar

local productsById: { [number]: ShopConfig.Product } = {}
local passesByKey: { [string]: ShopConfig.Pass } = {}
for _, product in ShopConfig.PRODUCTS do
	if product.productId ~= 0 then
		productsById[product.productId] = product
	end
end
for _, pass in ShopConfig.PASSES do
	passesByKey[pass.key] = pass
end

local pendingGift: { [Player]: { target: number, pass: string, at: number } } = {}

function ShopService.ownsPass(player: Player, key: string): boolean
	local pass = passesByKey[key]
	return pass ~= nil and player:GetAttribute(pass.attribute) == true
end

local function setPass(player: Player, pass: ShopConfig.Pass)
	player:SetAttribute(pass.attribute, true)
	BoostService.refresh(player)
end

-- Entrega un pase regalado: queda en los datos del que lo recibe (no es un pase de Roblox).
local function deliverGift(from: Player, target: Player, pass: ShopConfig.Pass): boolean
	local data = DataService.get(target)
	if not data or not DataService.canSave(target) then
		return false
	end
	data.giftedPasses[pass.key] = true
	setPass(target, pass)
	AnnounceService.server({ text = from.DisplayName .. " gifted " .. pass.name .. " to " .. target.DisplayName .. "!", sound = "Victory" })
	return true
end

local function grantProduct(player: Player, product: ShopConfig.Product)
	local data = DataService.get(player)
	if not data then
		return
	end
	if product.once then
		data.boughtOnce[product.key] = true
	end
	if product.giftOf then
		local pass = passesByKey[product.giftOf]
		local gift = pendingGift[player]
		pendingGift[player] = nil
		local target = gift and Players:GetPlayerByUserId(gift.target)
		if not (gift and target and gift.pass == product.giftOf and deliverGift(player, target, pass)) then
			-- Sin destinatario válido el regalo se guarda: el comprador lo manda después a quien quiera.
			data.giftTokens[pass.key] = (data.giftTokens[pass.key] or 0) + 1
			RewardService.show(player, { title = "GIFT SAVED!", lines = { { icon = "gift", text = pass.name .. " gift ready to send", kind = "info" } }, source = product.key })
		end
		return
	end
	if product.key == "OfflineDouble" and not OfflineService.double(player) then
		-- Ya no había ganancias pendientes: se da el equivalente en minutos de ganancia.
		RewardService.grant(player, { currency = EconomyConfig.MAIN, incomeMinutes = 30 }, Enum.AnalyticsEconomyTransactionType.IAP, product.key, true)
		return
	end
	for _, reward in product.grant do
		local shown = table.clone(reward)
		shown.label = shown.label or "THANK YOU!"
		RewardService.grant(player, shown, Enum.AnalyticsEconomyTransactionType.IAP, product.key, true)
		if reward.serverBoost then
			AnnounceService.server({ text = player.DisplayName .. " activated " .. product.name .. " for everyone!", sound = "Victory" })
		end
	end
end

local function processReceipt(receiptInfo: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	local isAd = receiptInfo.ProductPurchaseChannel == Enum.ProductPurchaseChannel.AdReward
	local product = productsById[receiptInfo.ProductId]
	local adReward = isAd or (ShopConfig.AD_REWARD.productId ~= 0 and receiptInfo.ProductId == ShopConfig.AD_REWARD.productId)
	-- Sin jugador o sin producto configurado no se otorga: Roblox vuelve a llamar cuando el jugador entra
	-- (también para compras hechas desde la página del juego).
	if not player or (not product and not adReward) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = DataService.waitForData(player)
	if not data or not DataService.canSave(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(receiptInfo.PurchaseId)
	if not Receipts.has(data.processedReceipts, purchaseId) then
		if adReward then
			for _, reward in ShopConfig.AD_REWARD.grant do
				RewardService.grant(player, reward, Enum.AnalyticsEconomyTransactionType.TimedReward, "AdReward", true)
			end
		elseif product then
			grantProduct(player, product)
		end
		Receipts.record(data.processedReceipts, purchaseId, os.time(), ShopConfig.MAX_RECEIPTS)
		Signals.track(player, "Purchase", 1)
		Signals.dirty(player)
	end
	-- Otorgada ahora o antes: se confirma solo si quedó guardada. Si no, Roblox la vuelve a mandar y
	-- el registro evita darla otra vez.
	if DataService.saveAsync(player) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
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
	local currency = item.currency or EconomyConfig.MAIN
	if not CurrencyService.spend(player, item.price, Enum.AnalyticsEconomyTransactionType.Shop, itemId, currency) then
		return false, "NOT_ENOUGH"
	end
	InventoryService.add(player, itemId)
	Signals.track(player, "Upgrade", 1)
	Signals.dirty(player)
	return true
end

local function validTarget(player: Player, targetId: number, passKey: string): (Player?, string?)
	local target = Players:GetPlayerByUserId(targetId)
	if not target or target == player then
		return nil, "NO_TARGET"
	end
	if ShopService.ownsPass(target, passKey) then
		return nil, "ALREADY_OWNED"
	end
	if not DataService.canSave(target) then
		return nil, "TARGET_LOADING"
	end
	return target
end

local function setGiftTarget(player: Player, targetId: number, passKey: string): (boolean, string?)
	local _, err = validTarget(player, targetId, passKey)
	if err then
		return false, err
	end
	pendingGift[player] = { target = targetId, pass = passKey, at = os.clock() }
	task.delay(GIFT_TARGET_SECONDS, function()
		local gift = pendingGift[player]
		if gift and os.clock() - gift.at >= GIFT_TARGET_SECONDS then
			pendingGift[player] = nil
		end
	end)
	return true
end

local function sendGiftToken(player: Player, targetId: number, passKey: string): (boolean, string?)
	local data = DataService.get(player)
	if not data or (data.giftTokens[passKey] or 0) <= 0 then
		return false, "NO_GIFT"
	end
	local target, err = validTarget(player, targetId, passKey)
	if not target then
		return false, err
	end
	data.giftTokens[passKey] -= 1
	if data.giftTokens[passKey] <= 0 then
		data.giftTokens[passKey] = nil
	end
	if not deliverGift(player, target, passesByKey[passKey]) then
		data.giftTokens[passKey] = (data.giftTokens[passKey] or 0) + 1
		return false, "TARGET_LOADING"
	end
	Signals.dirty(player)
	return true
end

local function watchAd(player: Player): string
	if ShopConfig.AD_REWARD.productId == 0 then
		return "NOT_CONFIGURED"
	end
	local ok, result = pcall(function()
		local reward = AdService:CreateAdRewardFromDevProductId(ShopConfig.AD_REWARD.productId)
		return AdService:ShowRewardedVideoAdAsync(player, reward)
	end)
	if not ok then
		warn("[ShopService] no se pudo mostrar el anuncio: " .. tostring(result))
		return "ERROR"
	end
	-- El premio no se da acá: llega por ProcessReceipt (canal AdReward), como pide la documentación.
	return result.Name
end

local function refreshPasses(player: Player)
	for _, pass in ShopConfig.PASSES do
		if pass.passId ~= 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.passId)
			if ok and owns then
				player:SetAttribute(pass.attribute, true)
			elseif not ok then
				warn("[ShopService] no se pudo verificar el pase " .. pass.name .. ": " .. tostring(owns))
			end
		end
	end
	BoostService.refresh(player)
end

local function refreshSubscription(player: Player, subscriptionId: string?)
	for _, sub in ShopConfig.SUBSCRIPTIONS do
		if sub.subscriptionId ~= "" and (subscriptionId == nil or subscriptionId == sub.subscriptionId) then
			local ok, status = pcall(MarketplaceService.GetUserSubscriptionStatusAsync, MarketplaceService, player, sub.subscriptionId)
			if ok and typeof(status) == "table" then
				player:SetAttribute(sub.attribute, status.IsSubscribed == true)
			elseif not ok then
				warn("[ShopService] no se pudo verificar la suscripción " .. sub.name .. ": " .. tostring(status))
			end
		end
	end
	BoostService.refresh(player)
end

local function refreshPolicy(player: Player)
	local ok, policy = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
	-- Ante un error se restringe: es preferible no ofrecer de más.
	player:SetAttribute("PaidRandomRestricted", not ok or policy.ArePaidRandomItemsRestricted == true)
end

local function onPlayerAdded(player: Player)
	task.spawn(refreshPolicy, player)
	task.spawn(refreshPasses, player)
	task.spawn(refreshSubscription, player)
end

function ShopService.start()
	local itemIds = {}
	for id in ShopConfig.ITEMS do
		table.insert(itemIds, id)
	end
	local giftable = {}
	for _, product in ShopConfig.PRODUCTS do
		if product.giftOf then
			table.insert(giftable, product.giftOf)
		end
	end
	local passKeys = {}
	for key in passesByKey do
		table.insert(passKeys, key)
	end
	local userId = Validate.number({ min = 1, integer = true })
	Remotes.onInvoke("RequestPurchase", { args = { Validate.oneOf(itemIds) }, rate = ShopConfig.PURCHASE_RATE }, buyItem)
	Remotes.onInvoke("SetGiftTarget", { args = { userId, Validate.oneOf(giftable) }, rate = { count = 3, perSeconds = 2 } }, setGiftTarget)
	Remotes.onInvoke("SendGiftToken", { args = { userId, Validate.oneOf(passKeys) }, rate = { count = 3, perSeconds = 2 } }, sendGiftToken)
	Remotes.onInvoke("WatchRewardedAd", { args = {}, rate = { count = 1, perSeconds = 10 } }, watchAd)

	MarketplaceService.ProcessReceipt = processReceipt
	-- Solo se escucha en el servidor: ahí `wasPurchased` es el resultado final (en el cliente no es confiable).
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Instance, passId: number, wasPurchased: boolean)
		if wasPurchased and player:IsA("Player") then
			for _, pass in ShopConfig.PASSES do
				if pass.passId == passId then
					setPass(player, pass)
					AnnounceService.server({ text = player.DisplayName .. " bought " .. pass.name .. "!", sound = "Purchase" })
				end
			end
		end
	end)
	Players.UserSubscriptionStatusChanged:Connect(function(player: Player, subscriptionId: string)
		refreshSubscription(player, subscriptionId)
	end)
	DataService.StateChanged:Connect(function(player: Player, state: string)
		local data = DataService.get(player)
		if state ~= "loading" and data then
			for key in data.giftedPasses do
				local pass = passesByKey[key]
				if pass then
					player:SetAttribute(pass.attribute, true)
				end
			end
			BoostService.refresh(player)
		end
	end)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player: Player)
		pendingGift[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return ShopService
