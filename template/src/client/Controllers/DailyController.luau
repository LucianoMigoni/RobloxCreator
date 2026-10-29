--!strict
-- Calendario diario con racha (RetentionConfig.DAILY): 7 casillas, la de hoy brilla y late, las ya
-- cobradas con tilde, la última grande ("MEGA GIFT"). Botón del HUD con globito cuando hay premio.
-- El servidor decide si se puede cobrar (ClaimDailyReward); acá solo se muestra.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local RewardText = require(ReplicatedStorage.Shared.Lib.RewardText)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local PlayerState = require("../PlayerState")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local DailyController = {}

local player = Players.LocalPlayer

function DailyController.start(hud: Hud.Hud)
	local window, body = UIKit.window(hud.screen, { name = "Daily", title = UiText.DAILY_TITLE, icon = "daily", variant = "Pink" })
	local row = UIKit.new("Frame", {
		Name = "Days",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.62),
		ZIndex = 21,
	}, body) :: Frame
	UIKit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.012, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	local streakLabel = UIKit.label(body, "Streak", "", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.66),
		Size = UDim2.fromScale(0.8, 0.1),
		ZIndex = 21,
	}, 34)
	local claim = UIKit.button({
		name = "Claim",
		text = UiText.CLAIM,
		variant = "Accept",
		anchorPoint = Vector2.new(0.5, 1),
		position = UDim2.fromScale(0.5, 0.99),
		size = UDim2.fromScale(0.36, 0.17),
		aspectRatio = 3.4,
		parent = body,
	})
	claim.ZIndex = 22

	local cells: { Frame } = {}
	local days = #RetentionConfig.DAILY
	for i, reward in RetentionConfig.DAILY do
		local big = i == days
		local cell = UIKit.new("Frame", {
			Name = "Day" .. i,
			LayoutOrder = i,
			Size = UDim2.fromScale(if big then 0.17 else 0.12, if big then 0.95 else 0.82),
			ZIndex = 22,
		}, row) :: Frame
		UIKit.style(cell, if big then "Premium" else "Info", 0.15, 3)
		UIKit.label(cell, "Day", string.format(UiText.DAY, i), {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.03),
			Size = UDim2.fromScale(0.9, 0.18),
			ZIndex = 24,
		}, 26, UIKit.TitleFont)
		UIKit.icon(cell, RewardText.icon(reward), {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.48),
			Size = UDim2.fromScale(0.8, 0.42),
			ZIndex = 24,
		})
		local parts = RewardText.parts(reward, 0)
		UIKit.label(cell, "What", if parts[1] then parts[1].text else (reward.label or ""), {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.96),
			Size = UDim2.fromScale(0.92, 0.2),
			ZIndex = 24,
		}, 20)
		local check = UIKit.label(cell, "Check", "✔", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0.6),
			ZIndex = 26,
			Visible = false,
		}, 90)
		check.TextColor3 = Color3.fromRGB(120, 255, 120)
		cells[i] = cell
	end

	local hudButton = hud.addButton("left", { name = "Daily", label = UiText.DAILY, icon = "daily", variant = "Pink", layoutOrder = 5 })
	local status: { canClaim: boolean, slot: number, streak: number, nextIn: number }? = nil
	local receivedAt = 0
	local stopPulse: Juice.Stop? = nil
	local stopHudPulse: Juice.Stop? = nil

	local function refresh()
		local s = status
		if not s then
			return
		end
		for i, cell in cells do
			-- `slot` es el de hoy (si se puede cobrar) o el de mañana: los anteriores ya se cobraron.
			local claimed = i < s.slot
			local check = cell:FindFirstChild("Check") :: TextLabel
			check.Visible = claimed
			UIKit.recolor(cell, if i == s.slot and s.canClaim then "Accept" elseif i == days then "Premium" else "Info")
		end
		if stopPulse then
			stopPulse()
			stopPulse = nil
		end
		if stopHudPulse then
			stopHudPulse()
			stopHudPulse = nil
		end
		if s.canClaim then
			stopPulse = Juice.pulse(cells[s.slot], 0.07)
			stopHudPulse = Juice.pulse(hudButton, 0.06)
			UIKit.setText(claim, UiText.CLAIM)
			UIKit.recolor(claim, "Accept")
		else
			UIKit.recolor(claim, "Neutral")
		end
		UIKit.setBadge(hudButton, if s.canClaim then "!" else nil)
		streakLabel.Text = string.format(UiText.STREAK, s.streak)
	end

	PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
		status = state.daily
		receivedAt = Workspace:GetServerTimeNow()
		refresh()
	end)

	task.spawn(function()
		while hud.screen.Parent do
			local s = status
			if s and not s.canClaim then
				local left = s.nextIn - (Workspace:GetServerTimeNow() - receivedAt)
				UIKit.setText(claim, string.format(UiText.NEXT_DAILY, Format.clock(math.max(0, left))))
			end
			task.wait(1)
		end
	end)

	claim.Activated:Connect(function()
		local s = status
		if not s or not s.canClaim then
			Sound.play("Error")
			Juice.shake(claim)
			return
		end
		Sound.play("Click")
		local ok, result = pcall(function()
			return Net.func("ClaimDailyReward"):InvokeServer()
		end)
		if not ok or result ~= true then
			Sound.play("Error")
		end
		UIKit.close(window)
	end)

	hudButton.Activated:Connect(function()
		Sound.play("Click")
		UIKit.toggle(window)
	end)
	Bus.handle("OpenDaily", function()
		UIKit.open(window)
	end)

	-- Al entrar con el premio listo, se abre solo (los hits lo hacen: es la primera dopamina del día).
	task.delay(4, function()
		local s = status
		if s and s.canClaim and UIKit.current() == nil and player.Parent then
			UIKit.open(window)
		end
	end)
end

return DailyController
