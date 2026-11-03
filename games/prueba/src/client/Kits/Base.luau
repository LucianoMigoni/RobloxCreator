--!strict
-- UI del bloque Plots (la base): lo cobrado vuela al contador de plata con su sonido, aviso del
-- espacio nuevo y de la traba con su tiempo. Los carteles del mundo (dueño, "Collect $X", "LOCK") los
-- dibuja UI/World con lo que pone el servidor; el inventario coloca y compra espacios.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local KitUi = require("./KitUi")

local Base = {}

local COINS = 8

function Base.start(hud: HudController.Hud)
	local main = EconomyConfig.CURRENCIES[EconomyConfig.MAIN]
	Bus.on("Kit:Collect", function(payload: any)
		local amount = if typeof(payload) == "table" and typeof(payload.amount) == "number" then payload.amount else 0
		if amount <= 0 then
			return
		end
		Sound.play("CoinsBurst")
		KitUi.notify(string.format(UiText.COLLECTED, Format.money(amount, main.symbol)), "Accept", main.icon)
		local pill = hud.currencyPill(EconomyConfig.MAIN)
		local screen = hud.screen
		if pill then
			local size = screen.AbsoluteSize
			Juice.flyTo(screen, Vector2.new(size.X / 2, size.Y * 0.6), pill, function(): GuiObject
				return UIKit.icon(screen, main.icon, { Size = UDim2.fromOffset(36, 36), ZIndex = 70 })
			end, COINS, function()
				Sound.play("Coin")
			end)
		end
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
end

return Base
