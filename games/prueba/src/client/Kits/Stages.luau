--!strict
-- UI del bloque Stages (escape y obby por etapas, o corrida con resumen):
-- - En la columna del HUD: la etapa ("Stage 5/20"), con un golpe y aviso al pasar a otra.
-- - Meta (KitFx "Win"): popup "YOU WIN!" con lo ganado.
-- - Corrida: "GO GO GO!" al salir; al caer, ventana para revivir (gratis mientras queden, después con
--   los comprados o el producto "Extra Life") o terminar; al final, el resumen con la etapa, la mejor y
--   lo ganado.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local Effects = require("../UI/Effects")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local KitState = require("./KitState")
local KitUi = require("./KitUi")

local Stages = {}

local STAGE_COLOR = Color3.fromRGB(120, 220, 255)

function Stages.start(hud: HudController.Hud)
	local cfg = KitConfig.stages
	if not cfg then
		return
	end
	local currency = EconomyConfig.CURRENCIES[cfg.reward.currency] or EconomyConfig.CURRENCIES[EconomyConfig.MAIN]
	local state: KitTypes.StagesState? = nil

	-- Etapa en el HUD.
	local row, amount = UIKit.stat(hud.stats, "Stage", "trophy", STAGE_COLOR, 0.15)
	row.LayoutOrder = 45
	local function refresh()
		local s = state
		local run = if s then s.run else nil
		local stage = if run then run.stage elseif s then s.stage else 0
		amount.Text = string.format(UiText.STAGE_NOW, stage, cfg.count)
	end
	refresh()

	-- Ventana de revivir.
	local runCfg = cfg.run
	local window, body = UIKit.window(hud.screen, { name = "Revive", title = UiText.REVIVE_TITLE, icon = "heart", variant = "Pink", aspectRatio = 1.6, widthScale = 0.5 })
	local info = UIKit.label(body, "Info", "", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.06),
		Size = UDim2.fromScale(0.9, 0.3),
		ZIndex = 22,
	}, 60, UIKit.TitleFont)
	local revive = UIKit.button({
		name = "Revive",
		text = UiText.REVIVE,
		variant = "Accept",
		icon = "heart",
		aspectRatio = 0,
		anchorPoint = Vector2.new(0.5, 0),
		position = UDim2.fromScale(0.27, 0.5),
		size = UDim2.fromScale(0.44, 0.34),
		parent = body,
	})
	revive.ZIndex = 23
	local endRun = UIKit.button({
		name = "EndRun",
		text = UiText.END_RUN,
		variant = "Close",
		aspectRatio = 0,
		anchorPoint = Vector2.new(0.5, 0),
		position = UDim2.fromScale(0.73, 0.5),
		size = UDim2.fromScale(0.44, 0.34),
		parent = body,
	})
	endRun.ZIndex = 23
	local stopPulse: Juice.Stop? = nil
	local canRevive = false

	local function showRevive(stage: number, freeLeft: number, bought: number)
		info.Text = string.format(UiText.REVIVE_INFO, stage)
		canRevive = freeLeft > 0 or bought > 0
		if freeLeft > 0 then
			UIKit.setText(revive, string.format(UiText.REVIVE_FREE, freeLeft))
		else
			UIKit.setText(revive, UiText.REVIVE)
		end
		if stopPulse then
			stopPulse()
		end
		stopPulse = Juice.pulse(revive, 0.06)
		UIKit.open(window)
	end

	revive.Activated:Connect(function()
		Sound.play("Click")
		if not canRevive then
			-- Sin gratis ni comprados: el producto revive al entregarse (Stages:Revive).
			KitUi.buyProduct((if runCfg then runCfg.reviveProduct else nil) or "Revive")
			return
		end
		local ok, reason = KitUi.invoke("Revive")
		if ok then
			UIKit.close(window)
		elseif reason == "NO_REVIVES" then
			canRevive = false
			KitUi.buyProduct((if runCfg then runCfg.reviveProduct else nil) or "Revive")
		else
			KitUi.error(reason)
		end
	end)
	endRun.Activated:Connect(function()
		Sound.play("Click")
		KitUi.fire("EndRun")
		UIKit.close(window)
	end)
	UIKit.PopupToggled:Connect(function(popup: GuiObject, isOpen: boolean)
		if popup == window and not isOpen and stopPulse then
			stopPulse()
			stopPulse = nil
		end
	end)

	KitState.on("stages", function(s: KitTypes.StagesState)
		state = s
		refresh()
	end)

	-- Avisos del servidor.
	Bus.on("Kit:Stage", function(payload: any)
		local stage = if typeof(payload) == "table" and typeof(payload.stage) == "number" then payload.stage else nil
		if stage then
			Sound.play("LevelUp")
			Juice.pop(row, 0.15)
			if payload.record == true then
				Sound.voice("NewRecord")
				KitUi.notify(string.format(UiText.NEW_RECORD, stage), "Premium", "trophy")
			else
				KitUi.notify(string.format(UiText.STAGE_REACHED, stage), "Info", "trophy")
			end
		end
	end)
	Bus.on("Kit:Win", function(payload: any)
		local earned = if typeof(payload) == "table" and typeof(payload.earned) == "number" then payload.earned else 0
		Sound.play("Victory")
		Effects.confetti(hud.screen, 60)
		Bus.call("ShowReward", {
			title = UiText.YOU_WIN,
			lines = { { icon = currency.icon, text = "+" .. Format.money(earned, currency.symbol), kind = "currency" } },
			source = "Win",
		})
	end)
	Bus.on("Kit:RunStarted", function()
		Sound.play("Whoosh")
		KitUi.notify(UiText.RUN_GO, "Accept", "speed")
	end)
	Bus.on("Kit:RunDied", function(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		Sound.play("Error")
		showRevive(payload.stage or 0, payload.freeLeft or 0, payload.bought or 0)
	end)
	Bus.on("Kit:Revived", function()
		Sound.play("Reward")
		if UIKit.isOpen(window) then
			UIKit.close(window)
		end
		KitUi.notify(UiText.REVIVED, "Pink", "heart")
	end)
	Bus.on("Kit:RunEnded", function(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		if UIKit.isOpen(window) then
			UIKit.close(window)
		end
		local stage = payload.stage or 0
		local earned = payload.earned or 0
		Bus.call("ShowReward", {
			title = if payload.finished then UiText.YOU_WIN else UiText.RUN_OVER,
			lines = {
				{ icon = "trophy", text = string.format(UiText.STAGE_REACHED, stage), kind = "item" },
				{ icon = "star", text = string.format(UiText.BEST_STAGE, payload.best or stage), kind = "item" },
				{ icon = currency.icon, text = "+" .. Format.money(earned, currency.symbol), kind = "currency" },
			},
			source = "RunEnd",
		})
	end)
end

return Stages
