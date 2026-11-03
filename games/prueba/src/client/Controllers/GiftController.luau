--!strict
-- Regalar un pase a otro jugador del servidor, como en los hits (botón de regalo en cada pase):
-- se elige a quién (foto y nombre de cada jugador) y se paga el producto `giftOf`; si el comprador ya
-- tiene regalos guardados (pagó y el otro se fue), se manda uno sin pagar de nuevo.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Net = require(ReplicatedStorage.Shared.Net)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local PlayerState = require("../PlayerState")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local GiftController = {}

local player = Players.LocalPlayer

local function giftProduct(passKey: string): ShopConfig.Product?
	for _, product in ShopConfig.PRODUCTS do
		if product.giftOf == passKey and product.productId ~= 0 then
			return product
		end
	end
	return nil
end

local function attributeOf(passKey: string): string?
	for _, pass in ShopConfig.PASSES do
		if pass.key == passKey then
			return pass.attribute
		end
	end
	return nil
end

function GiftController.start(hud: Hud.Hud)
	local window, body = UIKit.window(hud.screen, { name = "Gift", title = UiText.GIFT_TITLE, icon = "gift", variant = "Pink" })
	local info = UIKit.label(body, "Info", UiText.GIFT_CHOOSE, {
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromScale(0.9, 0.1),
		Position = UDim2.fromScale(0.5, 0),
		ZIndex = 22,
	}, 32)
	local holder = UIKit.new("Frame", {
		Name = "Holder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(1, 0.86),
		ZIndex = 21,
	}, body) :: Frame
	local grid: ScrollingFrame? = nil

	local function send(target: Player, passKey: string)
		local state = PlayerState.get()
		local tokens = if state then state.giftTokens[passKey] or 0 else 0
		if tokens > 0 then
			local ok, result = pcall(function()
				return Net.func("SendGiftToken"):InvokeServer(target.UserId, passKey)
			end)
			if ok and result == true then
				Sound.play("Purchase")
				UIKit.notify(hud.screen, UiText.GIFT_SENT, "Accept", "gift")
				UIKit.close(window)
			else
				Sound.play("Error")
			end
			return
		end
		local product = giftProduct(passKey)
		if not product then
			return
		end
		-- Primero se avisa a quién va (el servidor lo recuerda un rato) y después se paga.
		local ok, result = pcall(function()
			return Net.func("SetGiftTarget"):InvokeServer(target.UserId, passKey)
		end)
		if ok and result == true then
			MarketplaceService:PromptProductPurchase(player, product.productId)
			UIKit.close(window)
		else
			Sound.play("Error")
		end
	end

	local function open(passKey: string)
		if grid then
			grid:Destroy()
		end
		local list = UIKit.grid(holder, "Grid", UDim2.fromScale(0.22, 0), 0.8)
		list.ZIndex = 21
		grid = list
		local attribute = attributeOf(passKey)
		local count = 0
		for _, other in Players:GetPlayers() do
			if other ~= player and not (attribute and other:GetAttribute(attribute) == true) then
				count += 1
				local card = UIKit.new("TextButton", { Name = other.Name, Text = "", LayoutOrder = count, ZIndex = 22 }, list) :: TextButton
				UIKit.style(card, "Pink", 0.15, 0.035)
				local photo = UIKit.new("ImageLabel", {
					Name = "Photo",
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.06),
					Size = UDim2.fromScale(0.75, 0.6),
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 24,
				}, card) :: ImageLabel
				task.spawn(function()
					local ok, image = pcall(Players.GetUserThumbnailAsync, Players, other.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
					if ok then
						photo.Image = image
					end
				end)
				UIKit.label(card, "Name", other.DisplayName, {
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.fromScale(0.5, 0.96),
					Size = UDim2.fromScale(0.92, 0.25),
					ZIndex = 24,
				}, 24)
				card.Activated:Connect(function()
					Sound.play("Click")
					send(other, passKey)
				end)
			end
		end
		info.Text = if count == 0 then UiText.GIFT_NOBODY else UiText.GIFT_CHOOSE
		UIKit.open(window)
	end

	Bus.handle("OpenGift", open)
end

return GiftController
