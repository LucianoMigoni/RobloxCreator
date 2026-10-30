--!strict
-- Regalos por tiempo jugado en el día (RetentionConfig.PLAYTIME), el botón "FREE!" de los hits: el
-- reloj del próximo regalo en la etiqueta del botón, globito con los listos y una grilla de cajas con
-- su premio. El tiempo lo cuenta el servidor; el cliente solo adelanta el reloj entre estados.

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

local GiftsController = {}

type Cell = { card: Frame, button: TextButton, check: TextLabel }

function GiftsController.start(hud: Hud.Hud)
	local window, body = UIKit.window(hud.screen, { name = "Gifts", title = UiText.GIFTS_TITLE, icon = "gift", variant = "Accept" })
	-- En el teléfono, 2 columnas: el botón del pie llega a 44 px.
	local grid = UIKit.grid(body, "Grid", UDim2.fromScale(if UIKit.isSmallScreen() then 0.47 else 0.29, 0), 0.95)
	grid.ZIndex = 21
	local cells: { Cell } = {}

	local playtime: { seconds: number, claimed: { number }, day: number }? = nil
	local receivedAt = 0

	local function seconds(): number
		local p = playtime
		if not p then
			return 0
		end
		return p.seconds + (Workspace:GetServerTimeNow() - receivedAt)
	end

	local function isClaimed(index: number): boolean
		local p = playtime
		return p ~= nil and table.find(p.claimed, index) ~= nil
	end

	for i, gift in RetentionConfig.PLAYTIME do
		local parts = RewardText.parts(gift.reward, 0)
		local card = UIKit.card(grid, {
			name = "Gift" .. i,
			title = if parts[1] then parts[1].text else "Gift",
			desc = if parts[2] then parts[2].text else nil,
			icon = RewardText.icon(gift.reward),
			variant = if i % 3 == 0 then "Purple" elseif i % 3 == 1 then "Info" else "Pink",
			layoutOrder = i,
		})
		local footer = card:FindFirstChild("Footer") :: Frame
		local button = UIKit.button({ name = "Claim", text = "", variant = "Neutral", parent = footer, size = UDim2.fromScale(0.95, 1), aspectRatio = 3 })
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.Position = UDim2.fromScale(0.5, 0.5)
		button.ZIndex = 4
		local check = UIKit.label(card, "Check", "✔", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.35),
			Size = UDim2.fromScale(0.8, 0.5),
			ZIndex = 8,
			Visible = false,
		}, 100)
		check.TextColor3 = Color3.fromRGB(120, 255, 120)
		button.Activated:Connect(function()
			if isClaimed(i) or seconds() < gift.seconds then
				Sound.play("Error")
				Juice.shake(button)
				return
			end
			Sound.play("Click")
			local ok, result = pcall(function()
				return Net.func("ClaimPlaytimeGift"):InvokeServer(i)
			end)
			if not ok or result ~= true then
				Sound.play("Error")
			end
		end)
		cells[i] = { card = card, button = button, check = check }
	end

	local hudButton = hud.addButton("left", { name = "Gifts", label = UiText.GIFTS, icon = "gift", variant = "Orange", layoutOrder = 4 })
	local stopWiggle: Juice.Stop? = nil

	local function refresh()
		local now = seconds()
		local ready = 0
		local nextIn: number? = nil
		for i, gift in RetentionConfig.PLAYTIME do
			local cell = cells[i]
			local claimed = isClaimed(i)
			local left = gift.seconds - now
			cell.check.Visible = claimed
			if claimed then
				UIKit.setText(cell.button, UiText.CLAIMED)
				UIKit.recolor(cell.button, "Neutral")
			elseif left <= 0 then
				ready += 1
				UIKit.setText(cell.button, UiText.CLAIM)
				UIKit.recolor(cell.button, "Accept")
			else
				UIKit.setText(cell.button, Format.clock(left))
				UIKit.recolor(cell.button, "Neutral")
				nextIn = if nextIn then math.min(nextIn, left) else left
			end
		end
		UIKit.setBadge(hudButton, if ready > 0 then ready else nil)
		if ready > 0 then
			UIKit.setTimer(hudButton, nil)
			if not stopWiggle then
				stopWiggle = Juice.wiggle(hudButton, 7)
			end
		else
			UIKit.setTimer(hudButton, if nextIn then Format.clock(nextIn) else nil)
			if stopWiggle then
				stopWiggle()
				stopWiggle = nil
			end
		end
	end

	PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
		playtime = state.playtime
		receivedAt = Workspace:GetServerTimeNow()
		refresh()
	end)
	task.spawn(function()
		while hud.screen.Parent do
			refresh()
			task.wait(1)
		end
	end)
	hudButton.Activated:Connect(function()
		Sound.play("Click")
		UIKit.toggle(window)
	end)
	Bus.handle("OpenGifts", function()
		UIKit.open(window)
	end)
end

return GiftsController
