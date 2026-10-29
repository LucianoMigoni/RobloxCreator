--!strict
-- Ofertas de Robux que los hits ponen a la vista, siempre con precio y contenido reales:
-- - Pack inicial (StarterPack, una sola vez): botón con calcomanía "R$ 9" a la derecha; se esconde
--   al comprarlo.
-- - Duplicar lo ganado sin conexión (OfflineDouble): se ofrece al cerrar el cartel "WELCOME BACK!".
-- Nada de relojes inventados ni "LAST CHANCE" (reglas oficiales de monetización).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local RewardText = require(ReplicatedStorage.Shared.Lib.RewardText)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local PlayerState = require("../PlayerState")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local OfferController = {}

local player = Players.LocalPlayer

local function product(key: string): ShopConfig.Product?
	for _, p in ShopConfig.PRODUCTS do
		if p.key == key and p.productId ~= 0 then
			return p
		end
	end
	return nil
end

-- Ventana de una oferta: lo que trae, en filas con ícono, y el precio grande.
local function offerWindow(hud: Hud.Hud, name: string, title: string, info: string, lines: { RewardText.Part }, offer: ShopConfig.Product): Frame
	local window, body = UIKit.window(hud.screen, { name = name, title = title, icon = offer.icon, variant = "Orange", aspectRatio = 1.3, widthScale = 0.6 })
	UIKit.label(body, "Info", info, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.01),
		Size = UDim2.fromScale(0.9, 0.11),
		ZIndex = 22,
	}, 30)
	local list = UIKit.new("Frame", {
		Name = "Lines",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.15),
		Size = UDim2.fromScale(0.85, 0.58),
		ZIndex = 21,
	}, body) :: Frame
	UIKit.new("UIListLayout", {
		Padding = UDim.new(0.04, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)
	for i, part in lines do
		local row = UIKit.new("Frame", { Name = "Line" .. i, LayoutOrder = i, Size = UDim2.fromScale(1, math.min(0.3, 0.9 / #lines)), ZIndex = 22 }, list) :: Frame
		UIKit.style(row, "Info", 0.45, 3)
		UIKit.icon(row, part.icon, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.08, 0.5),
			Size = UDim2.fromScale(1.3, 1.3),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			ZIndex = 24,
		})
		UIKit.label(row, "Text", part.text, {
			Position = UDim2.fromScale(0.2, 0.12),
			Size = UDim2.fromScale(0.76, 0.76),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 24,
		}, 40, UIKit.TitleFont)
	end
	local buy = UIKit.pricePill(body, "Buy", tostring(offer.robux), nil, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.98),
		Size = UDim2.fromScale(0.42, 0.19),
		ZIndex = 22,
	})
	Juice.shine(buy, 2.2)
	buy.Activated:Connect(function()
		Sound.play("Click")
		MarketplaceService:PromptProductPurchase(player, offer.productId)
	end)
	task.spawn(function()
		local ok, info2 = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, offer.productId, Enum.InfoType.Product)
		if ok and typeof(info2) == "table" and typeof(info2.PriceInRobux) == "number" then
			UIKit.setText(buy, "R$ " .. Format.commas(info2.PriceInRobux))
		end
	end)
	return window
end

function OfferController.start(hud: Hud.Hud)
	local income = function(): number
		local value = player:GetAttribute("Income")
		return if typeof(value) == "number" then value else 0
	end

	-- Pack inicial
	local starter = product("StarterPack")
	if starter then
		local lines: { RewardText.Part } = {}
		for _, reward in starter.grant do
			for _, part in RewardText.parts(reward, income()) do
				table.insert(lines, part)
			end
		end
		local window = offerWindow(hud, "StarterPack", UiText.STARTER_TITLE, UiText.STARTER_INFO, lines, starter)
		local button = hud.addButton("right", { name = "StarterPack", label = UiText.OFFER, icon = starter.icon, variant = "Orange", layoutOrder = 2 })
		UIKit.ribbon(button, "R$ " .. starter.robux, "Accept")
		Juice.wiggle(button, 6)
		button.Activated:Connect(function()
			Sound.play("Click")
			UIKit.toggle(window)
		end)
		PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
			local bought = state.boughtOnce[starter.key] == true
			button.Visible = not bought
			if bought and UIKit.isOpen(window) then
				UIKit.close(window)
			end
		end)
	end

	-- Duplicar lo ganado sin conexión
	local double = product("OfflineDouble")
	if double then
		Bus.on("RewardClosed", function(popup: Types.RewardPopup)
			local state = PlayerState.get()
			if popup.source ~= "Offline" or not state or state.pendingOffline <= 0 then
				return
			end
			local main = EconomyConfig.CURRENCIES[EconomyConfig.MAIN]
			local lines = { { icon = main.icon, text = "+" .. Format.money(state.pendingOffline, main.symbol) } }
			local window = offerWindow(hud, "OfflineDouble", UiText.OFFLINE_TITLE, UiText.OFFLINE_DOUBLE, lines, double)
			UIKit.open(window)
			-- La ventana es de un solo uso: se descarta al cerrarse.
			UIKit.PopupToggled:Connect(function(popupFrame: GuiObject, isOpen: boolean)
				if popupFrame == window and not isOpen then
					task.delay(0.3, function()
						window:Destroy()
					end)
				end
			end)
		end)
	end
end

return OfferController
