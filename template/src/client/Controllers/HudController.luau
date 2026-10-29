--!strict
-- HUD estilo hit (skills/_shared/hits-2026.md §3.7):
-- - Arriba al centro, en columna: monedas (con "+" a la tienda), ingreso por segundo, objetivo con
--   barra, impulsos activos con reloj y el evento del momento ("LUCKY HOUR 12:34").
-- - Izquierda: botones de menú (tienda, índice, renacer, misiones...). Derecha: regalos, ofertas,
--   grupo, anuncio, invitar. Los demás controladores y los kits agregan los suyos con Hud.addButton.
-- - Abajo al centro: lugar libre para el kit (barra de nivel, botón de acción).
-- Las monedas llegan como atributos del jugador (cambian cada segundo); el resto, del estado.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local EventConfig = require(ReplicatedStorage.Shared.Config.EventConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Schedule = require(ReplicatedStorage.Shared.Lib.Schedule)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local PlayerState = require("../PlayerState")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")

export type Side = "left" | "right"

export type Hud = {
	screen: ScreenGui,
	top: Frame,
	left: Frame,
	right: Frame,
	bottom: Frame,
	addButton: (side: Side, props: UIKit.HudButtonProps) -> TextButton,
	currencyPill: (currency: string) -> GuiObject?,
}

local HudController = {}

local player = Players.LocalPlayer

local function serverNow(): number
	return Workspace:GetServerTimeNow()
end

local function sortedCurrencies(): { string }
	local list = {}
	for id in EconomyConfig.CURRENCIES do
		table.insert(list, id)
	end
	table.sort(list, function(a, b)
		if a == EconomyConfig.MAIN then
			return true
		elseif b == EconomyConfig.MAIN then
			return false
		end
		return a < b
	end)
	return list
end

function HudController.start(screen: ScreenGui): Hud
	-- Columna de arriba al centro.
	local top = UIKit.new("Frame", {
		Name = "Top",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.01),
		Size = UDim2.fromScale(0.62, 0.4),
	}, screen) :: Frame
	UIKit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0.02, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, top)

	-- Monedas
	local bar = UIKit.currencyBar(top)
	bar.Position = UDim2.new()
	bar.AnchorPoint = Vector2.zero
	bar.Size = UDim2.fromScale(1, 0.2)
	bar.LayoutOrder = 1
	local amounts: { [string]: TextLabel } = {}
	local pills: { [string]: GuiObject } = {}
	for i, id in sortedCurrencies() do
		local currency = EconomyConfig.CURRENCIES[id]
		local amount, plus = UIKit.currency(bar, id, nil, currency.icon, true)
		local pill = amount.Parent :: Frame
		pill.LayoutOrder = i
		amount.TextColor3 = Color3.new(1, 1, 1)
		amounts[id] = amount
		pills[id] = pill
		if plus then
			plus.Activated:Connect(function()
				Sound.play("Click")
				Bus.call("OpenShop", "Currency")
			end)
		end
		local last = 0
		local function refresh()
			local value = player:GetAttribute(id)
			if typeof(value) ~= "number" then
				return
			end
			amount.Text = Format.money(value, currency.symbol)
			-- Las subidas grandes saltan; el goteo de cada segundo no (cansaría).
			if value > last and last > 0 and (value - last) / math.max(last, 1) > 0.02 then
				Juice.pop(pill, 0.08)
			end
			last = value
		end
		player:GetAttributeChangedSignal(id):Connect(refresh)
		refresh()
	end

	-- Ingreso por segundo debajo de la plata.
	local income = UIKit.label(top, "Income", "", { Size = UDim2.fromScale(0.4, 0.07), LayoutOrder = 2, Visible = false }, 26)
	income.TextColor3 = Color3.fromRGB(140, 255, 120)
	local function refreshIncome()
		local value = player:GetAttribute("Income")
		local main = EconomyConfig.CURRENCIES[EconomyConfig.MAIN]
		if typeof(value) == "number" and value > 0 then
			income.Text = string.format(UiText.INCOME, Format.money(value, main.symbol))
			income.Visible = true
		else
			income.Visible = false
		end
	end
	player:GetAttributeChangedSignal("Income"):Connect(refreshIncome)
	refreshIncome()

	-- Objetivo actual con barra (enseña el juego sin tutorial).
	local objective = UIKit.new("Frame", {
		Name = "Objective",
		Size = UDim2.fromScale(0.55, 0.12),
		LayoutOrder = 3,
		Visible = false,
	}, top) :: Frame
	UIKit.style(objective, "Neutral", 0.4, 3)
	UIKit.new("UIAspectRatioConstraint", { AspectRatio = 6.5 }, objective)
	UIKit.icon(objective, "star", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.05, 0.45),
		Size = UDim2.fromScale(1.3, 1.3),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		ZIndex = 3,
	})
	local objectiveText = UIKit.label(objective, "Text", "", {
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0.12, 0.06),
		Size = UDim2.fromScale(0.84, 0.48),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}, 28)
	local objectiveBar = UIKit.progressBar(objective, "Progress", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0.12, 0.9),
		Size = UDim2.fromScale(0.84, 0.32),
		ZIndex = 3,
	})
	local lastObjective = ""

	-- Impulsos activos ("2x Money 12:30"): tocarlos abre el detalle de multiplicadores.
	local boosts = UIKit.new("TextButton", {
		Name = "Boosts",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.1),
		LayoutOrder = 4,
	}, top) :: TextButton
	UIKit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0.015, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, boosts)
	boosts.Activated:Connect(function()
		Sound.play("Click")
		Bus.call("OpenBoosts")
	end)
	local chips: { [string]: { frame: Frame, label: TextLabel, endsAt: number } } = {}

	local function chip(id: string, icon: string, endsAt: number, server: boolean)
		local existing = chips[id]
		if existing then
			existing.endsAt = endsAt
			return
		end
		local frame = UIKit.new("Frame", { Name = id, Size = UDim2.fromScale(0.2, 1) }, boosts) :: Frame
		UIKit.style(frame, if server then "Purple" else "Accept", 0.5, 2)
		UIKit.new("UIAspectRatioConstraint", { AspectRatio = 2.6 }, frame)
		UIKit.icon(frame, icon, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.12, 0.5),
			Size = UDim2.fromScale(1.25, 1.25),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			ZIndex = 3,
		})
		local label = UIKit.label(frame, "Time", "", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(0.95, 0.5),
			Size = UDim2.fromScale(0.68, 0.8),
			ZIndex = 3,
		}, 24)
		chips[id] = { frame = frame, label = label, endsAt = endsAt }
		Juice.bounceIn(frame)
	end

	-- Evento con horario real.
	local event = UIKit.new("Frame", {
		Name = "Event",
		Size = UDim2.fromScale(0.5, 0.1),
		LayoutOrder = 5,
		Visible = false,
	}, top) :: Frame
	UIKit.style(event, "Premium", 0.5, 3)
	UIKit.new("UIAspectRatioConstraint", { AspectRatio = 6 }, event)
	local eventText = UIKit.label(event, "Text", "", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.92, 0.78),
		ZIndex = 3,
	}, 30, UIKit.TitleFont)
	local stopEventPulse: Juice.Stop? = nil

	local function tickClocks()
		local now = serverNow()
		for id, info in chips do
			local left = info.endsAt - now
			if left <= 0 then
				info.frame:Destroy()
				chips[id] = nil
			else
				info.label.Text = Format.clock(left)
			end
		end
		local active = Schedule.active(EventConfig.EVENTS, now)
		if #active > 0 then
			local window = active[1]
			eventText.Text = string.format(UiText.EVENT_NOW, window.event.title, Format.clock(window.endsAt - now))
			event.Visible = true
			if not stopEventPulse then
				stopEventPulse = Juice.pulse(event, 0.05, 1.2)
			end
		else
			local soon = Schedule.upcoming(EventConfig.EVENTS, now)
			local window = soon[1]
			if window and window.startsAt - now <= EventConfig.ANNOUNCE_BEFORE * 3 then
				eventText.Text = string.format(UiText.EVENT_SOON, window.event.title, Format.clock(window.startsAt - now))
				event.Visible = true
			else
				event.Visible = false
			end
			if stopEventPulse then
				stopEventPulse()
				stopEventPulse = nil
			end
		end
	end
	task.spawn(function()
		while screen.Parent do
			tickClocks()
			task.wait(1)
		end
	end)

	-- Columnas de botones y lugar del kit abajo.
	local left = UIKit.sideBar(screen, "Left", false)
	local right = UIKit.sideBar(screen, "Right", true)
	local bottom = UIKit.new("Frame", {
		Name = "Bottom",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.98),
		Size = UDim2.fromScale(0.5, 0.16),
	}, screen) :: Frame

	local warned = false
	PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
		if not state.savesProgress and not warned then
			warned = true
			UIKit.notify(screen, UiText.NOT_SAVING, "Close")
		end
		-- Objetivo
		local o = state.objective
		if o then
			local target = if o.money then Format.money(o.target, EconomyConfig.CURRENCIES[EconomyConfig.MAIN].symbol) else Format.number(o.target)
			local text = string.format(o.text, target)
			if text ~= lastObjective and lastObjective ~= "" then
				Sound.play("LevelUp")
				Juice.pop(objective, 0.15)
			end
			lastObjective = text
			objectiveText.Text = text
			local progress = if o.money then Format.number(o.progress) .. " / " .. Format.number(o.target) else math.floor(o.progress) .. " / " .. o.target
			UIKit.setProgress(objectiveBar, o.progress / math.max(o.target, 1), progress)
			objective.Visible = true
		else
			objective.Visible = false
		end
		-- Impulsos
		local seen: { [string]: boolean } = {}
		for _, b in state.boosts do
			local key = (if b.server then "S_" else "P_") .. b.id
			seen[key] = true
			chip(key, b.icon, b.endsAt, b.server)
		end
		for key, info in chips do
			if not seen[key] then
				info.frame:Destroy()
				chips[key] = nil
			end
		end
	end)

	local function addButton(side: Side, props: UIKit.HudButtonProps): TextButton
		local button = UIKit.hudButton(props)
		button.Parent = if side == "left" then left else right
		Juice.bounceIn(button, (props.layoutOrder or 0) * 0.04)
		return button
	end

	return {
		screen = screen,
		top = top,
		left = left,
		right = right,
		bottom = bottom,
		addButton = addButton,
		currencyPill = function(currency: string): GuiObject?
			return pills[currency]
		end,
	}
end

return HudController
