--!strict
-- Tienda: ítems con monedas del juego (se le piden al servidor), packs de monedas (Developer Products) y
-- pases (aviso de compra de Roblox, desde el cliente para que cada jugador vea su precio). El saldo y el
-- inventario se actualizan cuando el servidor los confirma (PlayerState).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Net = require(ReplicatedStorage.Shared.Net)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local PlayerState = require("../PlayerState")

local ShopController = {}

local MESSAGES: { [string]: string } = {
	OWNED = UiText.OWNED,
	NOT_ENOUGH = UiText.NOT_ENOUGH,
}

local function row(name: string, text: string, variant: any, order: number, parent: Instance): TextButton
	return UIKit.button({
		name = name,
		text = text,
		variant = variant,
		size = UDim2.fromScale(1, 0.2),
		aspectRatio = 6,
		layoutOrder = order,
		parent = parent,
	})
end

function ShopController.start(screen: ScreenGui, sideBar: Frame)
	local player = Players.LocalPlayer
	local requestPurchase = Net.func("RequestPurchase")

	-- Con muchos productos, pasar `content` a un ScrollingFrame.
	local popup, content = UIKit.popup(screen, "ShopPopup", UiText.SHOP_TITLE)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.03, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content

	local ids = {}
	for id in ShopConfig.ITEMS do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return ShopConfig.ITEMS[a].price < ShopConfig.ITEMS[b].price
	end)

	local itemButtons: { [string]: TextButton } = {}
	local busy = false
	for order, id in ids do
		local item = ShopConfig.ITEMS[id]
		local button = row(id .. "Button", item.name .. "  " .. UIKit.formatNumber(item.price), "Accept", order, content)
		itemButtons[id] = button
		button.Activated:Connect(function()
			if busy then
				return
			end
			busy = true
			local sent, ok, code = pcall(requestPurchase.InvokeServer, requestPurchase, id)
			busy = false
			if sent and ok == true then
				UIKit.notify(screen, UiText.BOUGHT, "Accept")
			else
				UIKit.notify(screen, (if sent then MESSAGES[code] else nil) or UiText.TRY_AGAIN, "Close")
			end
		end)
	end

	local order = #ids
	for _, product in ShopConfig.PRODUCTS do
		if product.productId ~= 0 then
			order += 1
			local text = product.name .. "  +" .. UIKit.formatNumber(product.coins)
			row(product.name .. "Button", text, "Premium", order, content).Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(player, product.productId)
			end)
		end
	end
	for _, pass in ShopConfig.GAME_PASSES do
		if pass.passId ~= 0 then
			order += 1
			row(pass.name .. "Button", pass.name, "Premium", order, content).Activated:Connect(function()
				MarketplaceService:PromptGamePassPurchase(player, pass.passId)
			end)
		end
	end

	PlayerState.Changed:Connect(function(state)
		for id, button in itemButtons do
			if table.find(state.inventory, id) then
				UIKit.setText(button, ShopConfig.ITEMS[id].name .. "  " .. UiText.OWNED)
			end
		end
	end)

	local openButton = UIKit.sideButton(sideBar, "ShopButton", UiText.SHOP, "Info")
	openButton.LayoutOrder = 1
	openButton.Activated:Connect(function()
		UIKit.toggle(popup)
	end)
end

return ShopController
