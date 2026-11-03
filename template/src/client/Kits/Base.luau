--!strict
-- UI del bloque Plots (la base): lo cobrado vuela al contador de plata con su sonido, aviso del
-- espacio nuevo y de la traba con su tiempo. Los carteles del mundo (dueño, "Collect $X", "LOCK") los
-- dibuja UI/World con lo que pone el servidor; el inventario coloca y compra espacios.
-- Con `plots.lock`, "LOCK" en la barra de acción mientras se está en la base propia (en el teléfono no
-- hace falta caminar hasta el botón): cuenta la traba ("LOCKED 0:45") y la espera ("LOCK IN 1:30").

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local ActionBar = require("./ActionBar")
local KitState = require("./KitState")
local KitUi = require("./KitUi")

local Base = {}

local COINS = 8
local LOCK_BUTTON = "Lock"
local LOCK_RANGE = 80 -- studs desde la base; el servidor acepta hasta 90 (server/Kits/Plots, NEAR_BASE)
local LOCK_REFRESH = 0.5

local player = Players.LocalPlayer

-- "LOCK" en la barra de acción, con la traba y la espera a la vista.
local function lockButton()
	local state: KitTypes.PlotsState? = nil
	ActionBar.add(LOCK_BUTTON, {
		text = UiText.PLOT_LOCK,
		icon = "lock",
		variant = "Info",
		order = 4,
		key = Enum.KeyCode.L,
		onClick = function()
			local s = state
			if not s then
				return
			end
			if os.time() < s.lockReadyAt then
				KitUi.error("COOLDOWN")
				return
			end
			KitUi.fire("LockBase")
			local button = ActionBar.get(LOCK_BUTTON)
			if button then
				Juice.pop(button, 0.12)
			end
		end,
	})
	ActionBar.show(LOCK_BUTTON, false)
	KitState.on("plots", function(s: KitTypes.PlotsState)
		state = s
	end)
	local function ownPlot(name: string?): Model?
		if not name then
			return nil
		end
		for _, plot in CollectionService:GetTagged(Tags.PLOT) do
			if plot:IsA("Model") and plot.Name == name then
				return plot
			end
		end
		return nil
	end
	task.spawn(function()
		while true do
			task.wait(LOCK_REFRESH)
			local s = state
			local plot = ownPlot(if s then s.plot else nil)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local near = plot ~= nil and root ~= nil and root:IsA("BasePart")
				and (root.Position - plot:GetPivot().Position).Magnitude <= LOCK_RANGE
			ActionBar.show(LOCK_BUTTON, near)
			if near and s then
				local now = os.time()
				if now < s.lockedUntil then
					ActionBar.setText(LOCK_BUTTON, string.format(UiText.PLOT_LOCKED, Format.clock(s.lockedUntil - now)))
				elseif now < s.lockReadyAt then
					ActionBar.setText(LOCK_BUTTON, string.format(UiText.LOCK_READY_IN, Format.clock(s.lockReadyAt - now)))
				else
					ActionBar.setText(LOCK_BUTTON, UiText.PLOT_LOCK)
				end
			end
		end
	end)
end

function Base.start(hud: HudController.Hud)
	local main = EconomyConfig.CURRENCIES[EconomyConfig.MAIN]
	Bus.on("Kit:Collect", function(payload: any)
		local amount = if typeof(payload) == "table" and typeof(payload.amount) == "number" then payload.amount else 0
		if amount <= 0 then
			return
		end
		Sound.play("CoinsBurst")
		KitUi.notify(string.format(UiText.COLLECTED, Format.money(amount, main.symbol)), "Accept", main.icon)
		KitUi.coinsTo(EconomyConfig.MAIN, COINS)
	end)
	Bus.on("Kit:SlotBought", function()
		Sound.play("Purchase")
		KitUi.notify(UiText.SLOT_BOUGHT, "Accept", "base")
	end)
	Bus.on("Kit:Locked", function(payload: any)
		local endsAt = if typeof(payload) == "table" and typeof(payload.endsAt) == "number" then payload.endsAt else os.time()
		Sound.play("Equip")
		KitUi.notify(string.format(UiText.BASE_LOCKED, Format.clock(endsAt - os.time())), "Info", "lock")
	end)
	local plots = KitConfig.plots
	if plots and plots.lock then
		lockButton()
	end
end

return Base
