--!strict
-- UI del bloque Stats (+1 por paso, por segundo o por toque):
-- - Cada estadística que no es moneda va en la columna de la plata del HUD, con su ícono y un golpe al
--   subir mucho. La que mueve al personaje se toca para cambiar el tope de velocidad (100 %, 50 %,
--   25 %): para los saltos finos de un obby (SetStatCap).
-- - "TAP!" en la barra de acción para las que ganan por toque: mantener apretado repite al ritmo que
--   permite el servidor, y cada toque hace subir "+N" desde el botón. Con `autoPass`, al lado se
--   ofrece el pase que toca solo (y muestra "Auto: ON" cuando ya lo tiene).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local HudController = require("../Controllers/HudController")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local ActionBar = require("./ActionBar")
local KitState = require("./KitState")
local KitUi = require("./KitUi")

local Stats = {}

local player = Players.LocalPlayer

local CAPS = { 1, 0.5, 0.25 }
local STAT_COLOR = Color3.fromRGB(255, 225, 90)
local FLOAT_RISE = 70 -- píxeles que sube el "+N"

-- Valor de una estadística: la moneda si gana en una, si no el atributo que publica el servidor.
function Stats.value(id: string): number
	for _, def in KitConfig.stats or ({} :: { KitTypes.StatDef }) do
		if def.id == id then
			local currency = def.currency
			if currency then
				return KitUi.balance(currency)
			end
			local value = player:GetAttribute(id)
			return if typeof(value) == "number" then value else 0
		end
	end
	return 0
end

function Stats.label(id: string): string
	for _, def in KitConfig.stats or ({} :: { KitTypes.StatDef }) do
		if def.id == id then
			return def.label
		end
	end
	return id
end

local function floatGain(screen: Instance, button: GuiObject, text: string)
	local center = Juice.center(button)
	local label = UIKit.label(screen, "Gain", text, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(center.X + math.random(-30, 30), center.Y - button.AbsoluteSize.Y * 0.6),
		Size = UDim2.fromOffset(120, 40),
		ZIndex = 70,
	}, 40, UIKit.TitleFont)
	label.TextColor3 = STAT_COLOR
	local goal = label.Position - UDim2.fromOffset(0, FLOAT_RISE)
	local tween = TweenService:Create(label, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = goal,
		TextTransparency = 1,
	})
	tween.Completed:Once(function()
		label:Destroy()
	end)
	tween:Play()
end

function Stats.start(hud: HudController.Hud)
	local defs = KitConfig.stats
	if not defs then
		return
	end
	local caps: { [string]: number } = {}
	KitState.on("stats", function(state: KitTypes.StatsState)
		caps = state.caps or {}
	end)

	for i, def in defs do
		-- En la columna del HUD (las que ganan en una moneda ya están ahí).
		if not def.currency then
			local row, amount = UIKit.stat(hud.stats, def.id, def.icon or "boost", STAT_COLOR, 0.17)
			row.LayoutOrder = 30 + i
			local last = 0
			local function refresh()
				local value = Stats.value(def.id)
				local text = Format.number(value)
				local cap = caps[def.id]
				if def.walkSpeed and cap and cap < 1 then
					text = string.format(UiText.SPEED_CAP, text, math.floor(cap * 100 + 0.5))
				end
				amount.Text = text
				if value > last and last > 0 and (value - last) / math.max(last, 1) > 0.05 then
					Juice.pop(row, 0.08)
				end
				last = value
			end
			player:GetAttributeChangedSignal(def.id):Connect(refresh)
			KitState.on("stats", function()
				refresh()
			end)
			refresh()
			-- La que mueve al personaje: tocarla cambia el tope de velocidad.
			if def.walkSpeed then
				local toggle = UIKit.new("TextButton", {
					Name = "SpeedCap",
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 5,
				}, row) :: TextButton
				toggle.Activated:Connect(function()
					local current = caps[def.id] or 1
					local index = 1
					for k, value in CAPS do
						if math.abs(value - current) < 0.01 then
							index = k
						end
					end
					local nextCap = CAPS[index % #CAPS + 1]
					caps[def.id] = nextCap
					Sound.play("Click")
					Juice.pop(row, 0.1)
					KitUi.fire("SetStatCap", def.id, nextCap)
					refresh()
				end)
			end
		end

		-- TAP! (y el pase que toca solo).
		local perClick = def.perClick
		if perClick then
			local every = 1 / math.max(def.clickRate or 1, 1)
			local id = "Tap" .. def.id
			local button: TextButton? = nil
			button = ActionBar.add(id, {
				text = UiText.TAP,
				icon = def.icon or "tap",
				variant = "Accept",
				order = 1,
				key = Enum.KeyCode.F,
				repeatEvery = every,
				onClick = function()
					KitUi.fire("TapStat", def.id)
					local b = button
					if b then
						Juice.pop(b, 0.06)
						local mult = player:GetAttribute("Mult_" .. (def.multiplier or def.id))
						floatGain(hud.screen, b, string.format(UiText.GAIN, Format.number(perClick * (if typeof(mult) == "number" then mult else 1))))
					end
				end,
			})
			local autoPass = def.autoPass
			if autoPass then
				local autoId = "Auto" .. def.id
				local function refreshAuto()
					local owned = KitUi.ownsPass(autoPass)
					ActionBar.add(autoId, {
						text = if owned then UiText.AUTO_ON else UiText.AUTO,
						icon = if owned then "check" else "lock",
						variant = if owned then "Premium" else "Info",
						order = 2,
						onClick = function()
							if not KitUi.ownsPass(autoPass) then
								KitUi.buyPass(autoPass)
							end
						end,
					})
				end
				refreshAuto()
				player.AttributeChanged:Connect(function(name: string)
					if string.sub(name, 1, 4) == "Pass" then
						refreshAuto()
					end
				end)
			end
		end
	end
end

return Stats
