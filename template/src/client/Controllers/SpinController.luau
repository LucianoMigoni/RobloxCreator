--!strict
-- Ruleta de premios (RetentionConfig.SPIN), como en los hits: rueda de colores con el premio de cada
-- casilla y su probabilidad en letra chica (las tiradas se venden por Robux: es azar pago y la regla
-- oficial pide mostrarla), tirada gratis cada tantas horas y tiradas compradas o ganadas. El servidor
-- elige la casilla (SpinWheel) y el cliente gira la rueda hasta ella con un "tic" por casilla.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
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
local Effects = require("../UI/Effects")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local SpinController = {}

local SPIN_SECONDS = 4.2

function SpinController.start(hud: Hud.Hud)
	local segments = RetentionConfig.SPIN.SEGMENTS
	local count = #segments
	local step = 360 / count
	local totalWeight = 0
	for _, s in segments do
		totalWeight += s.weight
	end

	local window, body = UIKit.window(hud.screen, { name = "Spin", title = UiText.SPIN_TITLE, icon = "spin", variant = "Premium", aspectRatio = 1.3 })
	local wheelHolder = UIKit.new("Frame", {
		Name = "WheelHolder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.02, 0.5),
		Size = UDim2.fromScale(0.95, 0.95),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		ZIndex = 21,
	}, body) :: Frame
	local wheel = UIKit.new("Frame", {
		Name = "Wheel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 22,
	}, wheelHolder) :: Frame
	UIKit.style(wheel, "Panel", 1, 6)

	-- Cada casilla es un "pétalo" del centro al borde, girado a su ángulo, con el premio y la probabilidad.
	for i, segment in segments do
		local arm = UIKit.new("Frame", {
			Name = "Segment" .. i,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Rotation = (i - 1) * step,
			ZIndex = 23,
		}, wheel) :: Frame
		local slice = UIKit.new("Frame", {
			Name = "Slice",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(math.min(0.42, 2.9 / count), 0.47),
			BackgroundColor3 = segment.color,
			ZIndex = 23,
		}, arm) :: Frame
		UIKit.new("UICorner", { CornerRadius = UDim.new(0.35, 0) }, slice)
		UIKit.new("UIStroke", { Thickness = 3, Color = UIKit.STROKE_COLOR }, slice)
		UIKit.new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 190)),
		}, slice)
		UIKit.icon(slice, RewardText.icon(segment.reward), {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.05),
			Size = UDim2.fromScale(0.85, 0.3),
			ZIndex = 25,
		})
		UIKit.label(slice, "Label", segment.label, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.36),
			Size = UDim2.fromScale(1.1, 0.16),
			ZIndex = 25,
		}, 22, UIKit.TitleFont)
		-- Probabilidad en letra chica, como piden las reglas del azar pago.
		UIKit.label(slice, "Odds", Format.percent(segment.weight / totalWeight * 100), {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.53),
			Size = UDim2.fromScale(0.9, 0.1),
			ZIndex = 25,
		}, 14)
	end
	local hub = UIKit.new("Frame", {
		Name = "Hub",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.16, 0.16),
		ZIndex = 27,
	}, wheel) :: Frame
	UIKit.style(hub, "Premium", 1, 4)
	-- Puntero rojo arriba (no gira).
	local pointer = UIKit.new("Frame", {
		Name = "Pointer",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.03),
		Size = UDim2.fromScale(0.1, 0.1),
		Rotation = 45,
		ZIndex = 30,
	}, wheelHolder) :: Frame
	UIKit.style(pointer, "Close", 0.15, 4)

	-- Panel derecho: botón, tiradas y próxima gratis.
	local side = UIKit.new("Frame", {
		Name = "Side",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.99, 0.5),
		Size = UDim2.fromScale(0.36, 0.9),
		ZIndex = 21,
	}, body) :: Frame
	local spinButton = UIKit.button({
		name = "SpinButton",
		text = UiText.SPIN_NOW,
		variant = "Accept",
		anchorPoint = Vector2.new(0.5, 0),
		position = UDim2.fromScale(0.5, 0.18),
		size = UDim2.fromScale(0.95, 0.24),
		aspectRatio = 2.6,
		parent = side,
	})
	spinButton.ZIndex = 22
	local info = UIKit.label(side, "Info", "", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromScale(1, 0.12),
		ZIndex = 22,
	}, 30)
	local buy = UIKit.button({
		name = "BuySpins",
		text = UiText.TAB_SPINS,
		variant = "Info",
		icon = "spin",
		anchorPoint = Vector2.new(0.5, 0),
		position = UDim2.fromScale(0.5, 0.66),
		size = UDim2.fromScale(0.85, 0.17),
		aspectRatio = 3.2,
		parent = side,
	})
	buy.ZIndex = 22
	buy.Activated:Connect(function()
		Sound.play("Click")
		Bus.call("OpenShop", "Spins")
	end)

	local hudButton = hud.addButton("left", { name = "Spin", label = UiText.SPIN, icon = "spin", variant = "Premium", layoutOrder = 6 })
	local spins: { tickets: number, nextFreeAt: number } = { tickets = 0, nextFreeAt = math.huge }
	local spinning = false
	local stopButtonPulse: Juice.Stop? = nil

	local function refresh()
		local now = Workspace:GetServerTimeNow()
		local free = now >= spins.nextFreeAt
		local can = free or spins.tickets > 0
		UIKit.setText(spinButton, if free then UiText.SPIN_FREE else UiText.SPIN_NOW)
		UIKit.recolor(spinButton, if can and not spinning then "Accept" else "Neutral")
		local lines = {}
		if spins.tickets > 0 then
			table.insert(lines, string.format(UiText.SPINS_LEFT, spins.tickets))
		end
		if not free then
			table.insert(lines, string.format(UiText.NEXT_FREE_SPIN, Format.clock(spins.nextFreeAt - now)))
		end
		info.Text = table.concat(lines, "\n")
		UIKit.setBadge(hudButton, if free then "!" elseif spins.tickets > 0 then spins.tickets else nil)
		if can and not spinning and not stopButtonPulse then
			stopButtonPulse = Juice.pulse(spinButton, 0.06)
		elseif (not can or spinning) and stopButtonPulse then
			stopButtonPulse()
			stopButtonPulse = nil
		end
	end

	local function spinTo(index: number, lines: { Types.RewardLine })
		spinning = true
		Sound.play("SpinStart")
		-- La casilla i está girada (i-1)*step: para que quede arriba, la rueda gira -(i-1)*step.
		local start = wheel.Rotation % 360
		local target = -((index - 1) * step) + math.random(-12, 12) / 100 * step
		local turns = 5
		local goal = start + turns * 360 + ((target - start) % 360)
		local value = Instance.new("NumberValue")
		value.Value = start
		local lastTick = math.floor(start / step)
		local connection = RunService.RenderStepped:Connect(function()
			wheel.Rotation = value.Value
			local tick = math.floor((value.Value + step / 2) / step)
			if tick ~= lastTick then
				lastTick = tick
				Sound.play("SpinTick")
				Juice.pop(pointer, 0.15)
			end
		end)
		local tween = TweenService:Create(value, TweenInfo.new(SPIN_SECONDS, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Value = goal })
		tween.Completed:Once(function()
			connection:Disconnect()
			value:Destroy()
			wheel.Rotation = goal % 360
			spinning = false
			local segment = segments[index]
			Effects.burst(hud.screen, Juice.center(wheelHolder), "confetti", 30)
			if segment.id == "jackpot" then
				Sound.voice("Jackpot")
				Juice.flash(hud.screen, Color3.fromRGB(255, 230, 120))
				Effects.confetti(hud.screen, 80)
			end
			Bus.call("ShowReward", { title = segment.label, lines = lines, source = "Spin_" .. segment.id })
			refresh()
		end)
		tween:Play()
	end

	spinButton.Activated:Connect(function()
		if spinning then
			return
		end
		local now = Workspace:GetServerTimeNow()
		if now < spins.nextFreeAt and spins.tickets <= 0 then
			Sound.play("Error")
			Juice.shake(spinButton)
			UIKit.notify(hud.screen, UiText.NO_SPINS, "Close", "spin")
			return
		end
		Sound.play("Click")
		spinning = true
		refresh()
		local ok, index, lines = pcall(function()
			return Net.func("SpinWheel"):InvokeServer()
		end)
		if ok and typeof(index) == "number" and segments[index] and typeof(lines) == "table" then
			spinTo(index, lines)
		else
			spinning = false
			Sound.play("Error")
			refresh()
		end
	end)

	PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
		spins = state.spins
		if not spinning then
			refresh()
		end
	end)
	task.spawn(function()
		while hud.screen.Parent do
			if not spinning then
				refresh()
			end
			task.wait(1)
		end
	end)
	hudButton.Activated:Connect(function()
		Sound.play("Click")
		UIKit.toggle(window)
	end)
	Bus.handle("OpenSpin", function()
		UIKit.open(window)
	end)
end

return SpinController
