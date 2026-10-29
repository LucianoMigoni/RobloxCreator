--!strict
-- Renacer (RetentionConfig.REBIRTH): muestra el multiplicador actual → el siguiente, el costo con
-- barra de progreso y el botón grande. Globito "!" en el HUD cuando alcanza la plata. Al renacer:
-- confeti en toda la pantalla, voz "REBIRTH!" y destello (lo confirma el servidor).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Progression = require(ReplicatedStorage.Shared.Lib.Progression)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local PlayerState = require("../PlayerState")
local Effects = require("../UI/Effects")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local RebirthController = {}

local player = Players.LocalPlayer

function RebirthController.start(hud: Hud.Hud)
	local cfg = RetentionConfig.REBIRTH
	local currency = EconomyConfig.CURRENCIES[cfg.currency]
	local window, body = UIKit.window(hud.screen, { name = "Rebirth", title = UiText.REBIRTH_TITLE, icon = "rebirth", variant = "Purple", aspectRatio = 1.45 })
	UIKit.icon(body, "rebirth", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.02),
		Size = UDim2.fromScale(0.3, 0.3),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		ZIndex = 22,
	})
	local fromTo = UIKit.label(body, "FromTo", "", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.34),
		Size = UDim2.fromScale(0.9, 0.16),
		ZIndex = 22,
	}, 64, UIKit.TitleFont)
	fromTo.TextColor3 = Color3.fromRGB(140, 255, 120)
	UIKit.label(body, "Info", UiText.REBIRTH_INFO, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.85, 0.09),
		ZIndex = 22,
	}, 28)
	local progress = UIKit.progressBar(body, "Progress", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.62),
		Size = UDim2.fromScale(0.75, 0.1),
		ZIndex = 22,
	}, "Purple")
	local button = UIKit.button({
		name = "RebirthButton",
		text = UiText.REBIRTH_NOW,
		variant = "Purple",
		anchorPoint = Vector2.new(0.5, 1),
		position = UDim2.fromScale(0.5, 0.98),
		size = UDim2.fromScale(0.4, 0.18),
		aspectRatio = 3.2,
		parent = body,
	})
	button.ZIndex = 22
	local count = UIKit.label(body, "Count", "", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(0.99, 0.98),
		Size = UDim2.fromScale(0.25, 0.08),
		ZIndex = 22,
	}, 24)

	local hudButton = hud.addButton("left", { name = "Rebirth", label = UiText.REBIRTH, icon = "rebirth", variant = "Purple", layoutOrder = 3 })
	local rebirths = 0
	local cost = math.huge
	local lastRebirths: number? = nil

	local function refresh()
		local money = player:GetAttribute(cfg.currency)
		local have = if typeof(money) == "number" then money else 0
		local now = Progression.rebirthMultiplier(cfg.perRebirth, rebirths)
		local nextMult = Progression.rebirthMultiplier(cfg.perRebirth, rebirths + 1)
		fromTo.Text = string.format(UiText.REBIRTH_FROM_TO, Format.multiplier(now), Format.multiplier(nextMult))
		UIKit.setProgress(progress, have / cost, Format.money(math.min(have, cost), currency.symbol) .. " / " .. Format.money(cost, currency.symbol))
		local can = have >= cost
		UIKit.recolor(button, if can then "Accept" else "Neutral")
		UIKit.setBadge(hudButton, if can then "!" else nil)
		count.Text = string.format(UiText.REBIRTH_DONE, rebirths)
	end

	PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
		rebirths = state.rebirths
		cost = state.rebirthCost
		if lastRebirths and rebirths > lastRebirths then
			-- Festejo grande: es el momento de mayor "dopamina" del loop.
			Sound.play("Rebirth")
			Sound.voice("Rebirth")
			Juice.flash(hud.screen, Color3.fromRGB(200, 140, 255))
			Effects.confetti(hud.screen, 90)
			Juice.cameraShake(0.5, 0.5)
		end
		lastRebirths = rebirths
		refresh()
	end)
	player:GetAttributeChangedSignal(cfg.currency):Connect(refresh)

	button.Activated:Connect(function()
		local money = player:GetAttribute(cfg.currency)
		if typeof(money) ~= "number" or money < cost then
			Sound.play("Error")
			Juice.shake(button)
			UIKit.notify(hud.screen, UiText.NOT_ENOUGH, "Close", currency.icon)
			return
		end
		Sound.play("Click")
		local ok, result = pcall(function()
			return Net.func("RequestRebirth"):InvokeServer()
		end)
		if ok and result == true then
			UIKit.close(window)
		else
			Sound.play("Error")
		end
	end)
	hudButton.Activated:Connect(function()
		Sound.play("Click")
		UIKit.toggle(window)
	end)
	Bus.handle("OpenRebirth", function()
		UIKit.open(window)
	end)
end

return RebirthController
