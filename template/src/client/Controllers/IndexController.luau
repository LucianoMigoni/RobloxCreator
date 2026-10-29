--!strict
-- Índice de colección ("Index" de los hits): grilla con todo lo que se puede conseguir, lo descubierto
-- a color y lo que falta como silueta con "?", y el progreso "12 / 80". Las entradas las da el kit
-- (Bus.handle("IndexEntries", ...)); sin kit, se muestra solo el conteo del servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local PlayerState = require("../PlayerState")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local IndexController = {}

-- Lo que el kit devuelve por cada cosa coleccionable.
export type Entry = {
	key: string, -- el mismo que usa IndexService.discover ("Dragon|Gold")
	name: string,
	icon: string?, -- nombre de shared/Icons o rbxassetid de su imagen
	rarity: string?, -- RarityConfig.TIERS[].id
	color: Color3?,
	order: number?,
}

function IndexController.start(hud: Hud.Hud)
	local window, body = UIKit.window(hud.screen, { name = "Index", title = UiText.INDEX_TITLE, icon = "index", variant = "Info" })
	local progress = UIKit.progressBar(body, "Progress", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(0.6, 0.08),
		ZIndex = 22,
	}, "Info")
	local holder = UIKit.new("Frame", {
		Name = "Holder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(1, 0.88),
		ZIndex = 21,
	}, body) :: Frame
	local grid: ScrollingFrame? = nil
	local hudButton = hud.addButton("left", { name = "Index", label = UiText.INDEX, icon = "index", variant = "Info", layoutOrder = 2 })
	local lastFound = -1

	local function render(state: Types.PlayerSnapshot)
		local index = state.index
		UIKit.setProgress(progress, index.found / math.max(index.total, 1), string.format(UiText.INDEX_PROGRESS, index.found, index.total))
		if grid then
			grid:Destroy()
		end
		local entries = Bus.call("IndexEntries")
		if typeof(entries) ~= "table" then
			grid = nil
			return
		end
		local list = UIKit.grid(holder, "Grid", UDim2.fromScale(0.15, 0), 0.82)
		list.ZIndex = 21
		grid = list
		for i, entry: Entry in entries do
			local found = index.keys[entry.key] == true
			local cell = UIKit.new("Frame", { Name = entry.key, LayoutOrder = entry.order or i, ZIndex = 22 }, list) :: Frame
			UIKit.style(cell, if found then "Light" else "Neutral", 0.15, 3)
			local icon = UIKit.icon(cell, entry.icon, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.06),
				Size = UDim2.fromScale(0.82, 0.62),
				ZIndex = 24,
			})
			local image = icon:FindFirstChild("Image") :: ImageLabel
			if not found then
				-- Silueta: se ve qué falta sin revelar el color.
				image.ImageColor3 = Color3.new(0, 0, 0)
				image.ImageTransparency = 0.35
				local glyph = icon:FindFirstChild("Glyph") :: TextLabel
				glyph.Text = "?"
			end
			local name = UIKit.label(cell, "Name", if found then entry.name else "???", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.97),
				Size = UDim2.fromScale(0.95, 0.26),
				ZIndex = 24,
			}, 22, UIKit.TitleFont)
			if found and entry.color then
				name.TextColor3 = entry.color
			end
		end
	end

	PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
		local found = state.index.found
		if lastFound >= 0 and found > lastFound then
			UIKit.setBadge(hudButton, "NEW")
		end
		lastFound = found
		if UIKit.isOpen(window) then
			render(state)
		end
	end)
	hudButton.Activated:Connect(function()
		Sound.play("Click")
		UIKit.setBadge(hudButton, nil)
		local state = PlayerState.get()
		if state then
			render(state)
		end
		UIKit.toggle(window)
	end)
	Bus.handle("OpenIndex", function()
		local state = PlayerState.get()
		if state then
			render(state)
		end
		UIKit.open(window)
	end)
end

return IndexController
