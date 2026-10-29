--!strict
-- Popup de premio estilo hit (RewardShown): título grande con rayos girando detrás, cada parte del
-- premio con su ícono, confeti, sonido y la plata volando al contador. Los premios llegan en fila y
-- se muestran de a uno. Otros controladores muestran los suyos con Bus.call("ShowReward", popup).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local Effects = require("../UI/Effects")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local RewardController = {}

local SHOW_SECONDS = 3.2

-- Qué sonido va con cada origen del premio.
local function soundFor(source: string): string
	if source:find("^Spin") then
		return "Reward"
	elseif source == "Rebirth" then
		return "Rebirth"
	elseif source == "Offline" then
		return "CoinsBurst"
	elseif source:find("Code") or source:find("Daily") or source:find("Playtime") or source:find("Quest") then
		return "Reward"
	end
	return "Purchase"
end

function RewardController.start(hud: Hud.Hud)
	local screen = hud.screen
	local queue: { Types.RewardPopup } = {}
	local busy = false

	local function currencyOf(line: Types.RewardLine): string?
		if line.kind ~= "currency" then
			return nil
		end
		for id, currency in EconomyConfig.CURRENCIES do
			if currency.icon == line.icon then
				return id
			end
		end
		return nil
	end

	local function showNext()
		local popup = table.remove(queue, 1)
		if not popup then
			busy = false
			return
		end
		busy = true
		local frame = UIKit.new("Frame", {
			Name = "Reward",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.48),
			Size = UDim2.fromScale(0.42, 0.62),
			ZIndex = 80,
		}, screen) :: Frame
		UIKit.new("UIAspectRatioConstraint", { AspectRatio = 1.05 }, frame)
		local stopRays = Effects.rays(frame, Color3.fromRGB(255, 225, 110), 1.6)
		local title = UIKit.label(frame, "Title", popup.title, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.02),
			Size = UDim2.fromScale(1.3, 0.2),
			ZIndex = 83,
		}, 90, UIKit.TitleFont)
		title.TextColor3 = Color3.fromRGB(255, 230, 90)
		local stopRainbow: Juice.Stop? = nil
		if popup.title == "JACKPOT" or popup.title:find("SECRET") then
			stopRainbow = Juice.rainbow(title)
		end
		local list = UIKit.new("Frame", {
			Name = "Lines",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.26),
			Size = UDim2.fromScale(1, 0.56),
			ZIndex = 82,
		}, frame) :: Frame
		UIKit.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0.04, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, list)
		local rows = math.max(#popup.lines, 1)
		local flights: { { row: Frame, currency: string } } = {}
		for i, line in popup.lines do
			local row = UIKit.new("Frame", {
				Name = "Line" .. i,
				LayoutOrder = i,
				Size = UDim2.fromScale(0.95, math.min(0.3, 0.9 / rows)),
				ZIndex = 82,
			}, list) :: Frame
			UIKit.style(row, if line.kind == "currency" then "Accept" elseif line.kind == "boost" then "Premium" else "Info", 0.45, 3)
			UIKit.icon(row, line.icon, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.1, 0.5),
				Size = UDim2.fromScale(1.35, 1.35),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 85,
			})
			local text = UIKit.label(row, "Text", line.text, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0.22, 0.5),
				Size = UDim2.fromScale(0.74, 0.72),
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 84,
			}, 46, UIKit.TitleFont)
			if line.color then
				text.TextColor3 = line.color
			end
			Juice.bounceIn(row, 0.12 + i * 0.1)
			local currency = currencyOf(line)
			if currency then
				table.insert(flights, { row = row, currency = currency })
			end
		end
		local ok = UIKit.button({
			name = "Awesome",
			text = UiText.AWESOME,
			variant = "Accept",
			anchorPoint = Vector2.new(0.5, 1),
			position = UDim2.fromScale(0.5, 1.02),
			size = UDim2.fromScale(0.55, 0.14),
			aspectRatio = 3.4,
			parent = frame,
		})
		ok.ZIndex = 86
		Juice.bounceIn(frame)
		Juice.bounceIn(ok, 0.5)
		Sound.play(soundFor(popup.source))
		Effects.burst(screen, Juice.center(frame), "confetti", 26)
		Effects.burst(screen, Juice.center(title), "sparkle", 14)

		local closed = false
		local function close()
			if closed then
				return
			end
			closed = true
			-- La plata vuela al contador al cerrar: se ve de dónde vino.
			for _, flight in flights do
				local target = hud.currencyPill(flight.currency)
				if target then
					local icon = EconomyConfig.CURRENCIES[flight.currency].icon
					Juice.flyTo(screen, Juice.center(flight.row), target, function()
						local holder = UIKit.new("Frame", { BackgroundTransparency = 1 }, nil) :: Frame
						UIKit.icon(holder, icon)
						return holder
					end, 10, function()
						Sound.play("Coin")
					end)
				end
			end
			stopRays()
			if stopRainbow then
				stopRainbow()
			end
			frame:Destroy()
			Bus.emit("RewardClosed", popup)
			task.delay(0.15, showNext)
		end
		ok.Activated:Connect(function()
			Sound.play("Click")
			close()
		end)
		task.delay(SHOW_SECONDS, close)
	end

	local function enqueue(popup: Types.RewardPopup)
		table.insert(queue, popup)
		if not busy then
			showNext()
		end
	end

	Bus.handle("ShowReward", enqueue)
	Net.event("RewardShown").OnClientEvent:Connect(function(popup: any)
		if typeof(popup) == "table" and typeof(popup.title) == "string" and typeof(popup.lines) == "table" then
			enqueue(popup)
		end
	end)
end

return RewardController
