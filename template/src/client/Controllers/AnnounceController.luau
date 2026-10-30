--!strict
-- Avisos grandes del servidor ("Leo got a SECRET Dragon!", "LUCKY HOUR started!"): banner que baja
-- arriba al centro con su color o arcoíris, el sonido que pide el aviso y una copia en el chat como
-- mensaje del sistema (solo la ve este jugador).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local AnnounceController = {}

local SHOW_SECONDS = 4

local function toChat(text: string)
	local channels = TextChatService:FindFirstChild("TextChannels")
	local general = channels and channels:FindFirstChild("RBXGeneral")
	if general and general:IsA("TextChannel") then
		pcall(general.DisplaySystemMessage, general, text)
	end
end

function AnnounceController.start(hud: Hud.Hud)
	local queue: { any } = {}
	local busy = false

	local function showNext()
		local item = table.remove(queue, 1)
		if not item then
			busy = false
			return
		end
		busy = true
		local hidden = UDim2.fromScale(0.5, -0.2)
		local banner = UIKit.new("Frame", {
			Name = "Announcement",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = hidden,
			Size = UDim2.fromScale(0.62, 0.09),
			ZIndex = 70,
		}, hud.screen) :: Frame
		UIKit.style(banner, "Neutral", 0.5, 0.06)
		UIKit.new("UIAspectRatioConstraint", { AspectRatio = 8 }, banner)
		local label = UIKit.label(banner, "Text", item.text, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.94, 0.78),
			ZIndex = 72,
		}, 40, UIKit.TitleFont)
		if typeof(item.color) == "Color3" then
			label.TextColor3 = item.color
		end
		local stopRainbow: Juice.Stop? = nil
		if item.rainbow == true then
			stopRainbow = Juice.rainbow(label)
		end
		if typeof(item.sound) == "string" then
			Sound.play(item.sound)
		end
		TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.42) }):Play()
		task.delay(SHOW_SECONDS, function()
			local out = TweenService:Create(banner, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = hidden })
			out.Completed:Once(function()
				if stopRainbow then
					stopRainbow()
				end
				banner:Destroy()
				showNext()
			end)
			out:Play()
		end)
	end

	Net.event("Announced").OnClientEvent:Connect(function(item: any)
		if typeof(item) ~= "table" or typeof(item.text) ~= "string" then
			return
		end
		toChat(item.text)
		table.insert(queue, item)
		if not busy then
			showNext()
		end
	end)
end

return AnnounceController
