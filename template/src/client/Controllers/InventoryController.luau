--!strict
-- Inventario: lista los ítems que el servidor confirmó (PlayerState).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local PlayerState = require("../PlayerState")

local InventoryController = {}

local function addLabel(parent: Instance, text: string, order: number)
	local label = Instance.new("TextLabel")
	label.Name = "Entry"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 0.15)
	label.LayoutOrder = order
	UIKit.text(label, text, 32)
	label.Parent = parent
end

function InventoryController.start(screen: ScreenGui, sideBar: Frame)
	local popup, content = UIKit.popup(screen, "InventoryPopup", UiText.INVENTORY_TITLE)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.02, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content

	PlayerState.Changed:Connect(function(state)
		for _, child in content:GetChildren() do
			if child.Name == "Entry" then
				child:Destroy()
			end
		end
		if #state.inventory == 0 then
			addLabel(content, UiText.EMPTY_INVENTORY, 1)
			return
		end
		for order, id in state.inventory do
			local item = ShopConfig.ITEMS[id]
			addLabel(content, if item then item.name else id, order)
		end
	end)

	local openButton = UIKit.sideButton(sideBar, "InventoryButton", UiText.INVENTORY, "Info")
	openButton.LayoutOrder = 2
	openButton.Activated:Connect(function()
		UIKit.toggle(popup)
	end)
end

return InventoryController
