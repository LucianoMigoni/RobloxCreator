--!strict
-- Códigos (RetentionConfig.CODES): caja de texto, botón REDEEM y el resultado en color. Los códigos se
-- publican en la página del juego y en el grupo (nunca links a Discord dentro del juego).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Net = require(ReplicatedStorage.Shared.Net)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local CodesController = {}

local MESSAGES = {
	OK = UiText.CODE_OK,
	INVALID = UiText.CODE_INVALID,
	EXPIRED = UiText.CODE_EXPIRED,
	USED = UiText.CODE_USED,
}

function CodesController.start(hud: Hud.Hud)
	local window, body = UIKit.window(hud.screen, { name = "Codes", title = UiText.CODES_TITLE, icon = "codes", variant = "Cyan", aspectRatio = 1.7, widthScale = 0.62 })
	local box = UIKit.new("TextBox", {
		Name = "CodeBox",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.12),
		Size = UDim2.fromScale(0.8, 0.24),
		PlaceholderText = UiText.CODE_PLACEHOLDER,
		Text = "",
		ClearTextOnFocus = false,
		ZIndex = 22,
	}, body) :: TextBox
	UIKit.style(box, "Light", 0.3, 0.05)
	box.FontFace = UIKit.TitleFont
	box.TextScaled = true
	box.TextColor3 = UIKit.STROKE_COLOR
	box.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
	local result = UIKit.label(body, "Result", UiText.CODE_HINT, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.85, 0.14),
		ZIndex = 22,
	}, 30)
	local redeem = UIKit.button({
		name = "Redeem",
		text = UiText.REDEEM,
		variant = "Accept",
		anchorPoint = Vector2.new(0.5, 1),
		position = UDim2.fromScale(0.5, 0.95),
		size = UDim2.fromScale(0.42, 0.26),
		aspectRatio = 3.2,
		parent = body,
	})
	redeem.ZIndex = 22
	local busy = false
	redeem.Activated:Connect(function()
		local text = box.Text
		if busy or #text == 0 then
			Juice.shake(box)
			return
		end
		busy = true
		Sound.play("Click")
		local ok, status = pcall(function()
			return Net.func("RedeemCode"):InvokeServer(text)
		end)
		busy = false
		local key = if ok and typeof(status) == "string" then status else "ERROR"
		result.Text = MESSAGES[key] or UiText.TRY_AGAIN
		result.TextColor3 = if key == "OK" then Color3.fromRGB(140, 255, 120) else Color3.fromRGB(255, 120, 120)
		if key == "OK" then
			box.Text = ""
			UIKit.close(window)
		else
			Sound.play("Error")
			Juice.shake(box)
		end
	end)
	local hudButton = hud.addTopbarButton({ name = "Codes", label = UiText.CODES, icon = "codes", layoutOrder = 3 })
	hudButton.Activated:Connect(function()
		Sound.play("Click")
		result.Text = UiText.CODE_HINT
		result.TextColor3 = Color3.new(1, 1, 1)
		UIKit.toggle(window)
	end)
	Bus.handle("OpenCodes", function()
		UIKit.open(window)
	end)
end

return CodesController
