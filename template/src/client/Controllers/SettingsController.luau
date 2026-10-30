--!strict
-- Ajustes: música, efectos y gráficos bajos (menos partículas y sin desenfoque en teléfonos lentos).
-- Se guardan con los datos del jugador (SaveSettings) y se aplican al cargar.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local PlayerState = require("../PlayerState")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local SettingsController = {}

type Settings = { music: boolean, sfx: boolean, lowGraphics: boolean }

function SettingsController.start(hud: Hud.Hud)
	local window, body = UIKit.window(hud.screen, { name = "Settings", title = UiText.SETTINGS_TITLE, icon = "settings", variant = "Neutral", aspectRatio = 1.5, widthScale = 0.55 })
	local list = UIKit.list(body, "List")
	list.ZIndex = 21
	local settings: Settings = { music = true, sfx = true, lowGraphics = false }
	local toggles: { [string]: TextButton } = {}

	local function apply()
		Sound.setVolumes(if settings.sfx then 1 else 0, if settings.music then 1 else 0)
		local blur = Lighting:FindFirstChild("WindowBlur")
		if blur and blur:IsA("BlurEffect") then
			blur.Enabled = not settings.lowGraphics
		end
		Bus.emit("LowGraphics", settings.lowGraphics)
		for key, button in toggles do
			local on = (settings :: any)[key] == true
			UIKit.setText(button, if on then UiText.ON else UiText.OFF)
			UIKit.recolor(button, if on then "Accept" else "Close")
		end
	end

	local function save()
		task.spawn(function()
			pcall(function()
				return Net.func("SaveSettings"):InvokeServer(settings.music, settings.sfx, settings.lowGraphics)
			end)
		end)
	end

	for i, item in { { key = "music", label = UiText.SETTINGS_MUSIC }, { key = "sfx", label = UiText.SETTINGS_SFX }, { key = "lowGraphics", label = UiText.SETTINGS_LOW } } do
		local row = UIKit.new("Frame", { Name = item.key, LayoutOrder = i, Size = UDim2.new(0.95, 0, 0, 80), ZIndex = 22 }, list) :: Frame
		UIKit.fitHeight(row, 6.9, 64)
		UIKit.style(row, "Info", 0.3, 0.05)
		UIKit.label(row, "Label", item.label, {
			Position = UDim2.fromScale(0.05, 0.15),
			Size = UDim2.fromScale(0.6, 0.7),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 24,
		}, 40, UIKit.TitleFont)
		local toggle = UIKit.button({
			name = "Toggle",
			text = UiText.ON,
			variant = "Accept",
			anchorPoint = Vector2.new(1, 0.5),
			position = UDim2.fromScale(0.96, 0.5),
			size = UDim2.fromScale(0.25, 0.7),
			aspectRatio = 2.2,
			parent = row,
		})
		toggle.ZIndex = 25
		toggles[item.key] = toggle
		toggle.Activated:Connect(function()
			(settings :: any)[item.key] = not (settings :: any)[item.key]
			Sound.play("Click")
			apply()
			save()
		end)
	end

	local loaded = false
	PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
		if not loaded and state.settings then
			loaded = true
			settings = table.clone(state.settings)
			apply()
		end
	end)
	local hudButton = hud.addTopbarButton({ name = "Settings", icon = "settings", layoutOrder = 9 })
	hudButton.Activated:Connect(function()
		Sound.play("Click")
		UIKit.toggle(window)
	end)
	apply()
end

return SettingsController
