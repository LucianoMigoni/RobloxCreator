--!strict
-- Detalle de multiplicadores, como en los hits: cada estadística con su total grande ("x6.5 Money") y
-- cada fuente en una fila ("x2 (Gamepass)", "+10% (Friends)", "x2.5 (Rebirth)"). El jugador ve qué le
-- falta comprar o conseguir; las que no tiene aparecen apagadas con botón a la tienda.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Multipliers = require(ReplicatedStorage.Shared.Lib.Multipliers)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local PlayerState = require("../PlayerState")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local BoostsController = {}

local player = Players.LocalPlayer

local STAT_ICON: { [string]: string } = {
	Money = "money_boost",
	Luck = "luck",
	Speed = "speed",
	Wins = "trophy",
	Gems = "gem",
	Strength = "strength",
}

function BoostsController.start(hud: Hud.Hud)
	local window, body = UIKit.window(hud.screen, { name = "Boosts", title = UiText.BOOSTS_TITLE, icon = "money_boost", variant = "Accept" })
	local list = UIKit.list(body, "List")
	list.ZIndex = 21

	local function render(state: Types.PlayerSnapshot)
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local sources: { Multipliers.Source } = {}
		local stats: { string } = {}
		local seen: { [string]: boolean } = {}
		for _, view in state.multipliers do
			table.insert(sources, { stat = view.stat, kind = if view.kind == "add" then "add" else "mult", value = view.value, label = view.label })
			if not seen[view.stat] then
				seen[view.stat] = true
				table.insert(stats, view.stat)
			end
		end
		table.sort(stats)
		local order = 0
		for _, stat in stats do
			order += 1
			local header = UIKit.new("Frame", { Name = stat, LayoutOrder = order, Size = UDim2.new(0.96, 0, 0, 60), ZIndex = 22 }, list) :: Frame
			UIKit.fitHeight(header, 10, 48)
			UIKit.style(header, "Premium", 0.3, 0.05)
			UIKit.icon(header, STAT_ICON[stat] or "star", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.06, 0.5),
				Size = UDim2.fromScale(1.3, 1.3),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 24,
			})
			UIKit.label(header, "Total", Format.multiplier(Multipliers.total(sources, stat)) .. " " .. stat, {
				Position = UDim2.fromScale(0.14, 0.1),
				Size = UDim2.fromScale(0.8, 0.8),
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 24,
			}, 44, UIKit.TitleFont)
			for _, source in Multipliers.breakdown(sources, stat) do
				order += 1
				local row = UIKit.new("Frame", { Name = source.label, LayoutOrder = order, Size = UDim2.new(0.9, 0, 0, 44), ZIndex = 22 }, list) :: Frame
				UIKit.fitHeight(row, 13.5, 36)
				UIKit.style(row, if source.kind == "add" then "Info" else "Accept", 0.4, 0.045)
				UIKit.label(row, "Text", Multipliers.describe(source), {
					Position = UDim2.fromScale(0.04, 0.12),
					Size = UDim2.fromScale(0.92, 0.76),
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 24,
				}, 30)
			end
		end
		-- Lo que todavía puede conseguir: pases que no tiene, apagados, con atajo a la tienda.
		for _, pass in ShopConfig.PASSES do
			if #pass.effects > 0 and player:GetAttribute(pass.attribute) ~= true then
				order += 1
				local row = UIKit.new("TextButton", { Name = "Get" .. pass.key, Text = "", LayoutOrder = order, Size = UDim2.new(0.9, 0, 0, 44), ZIndex = 22 }, list) :: TextButton
				UIKit.fitHeight(row, 13.5, 48)
				UIKit.style(row, "Neutral", 0.4, 0.045)
				UIKit.label(row, "Text", pass.name .. "  ·  " .. pass.desc, {
					Position = UDim2.fromScale(0.04, 0.12),
					Size = UDim2.fromScale(0.92, 0.76),
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 24,
				}, 26)
				row.Activated:Connect(function()
					Sound.play("Click")
					Bus.call("OpenShop", "Passes")
				end)
			end
		end
		if order == 0 then
			UIKit.fitHeight(UIKit.label(list, "Empty", UiText.BOOSTS_EMPTY, { Size = UDim2.new(0.9, 0, 0, 80), ZIndex = 22 }, 30), 7.5)
		end
	end

	Bus.handle("OpenBoosts", function()
		local state = PlayerState.get()
		if state then
			render(state)
		end
		UIKit.open(window)
	end)
	PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
		if UIKit.isOpen(window) then
			render(state)
		end
	end)
end

return BoostsController
