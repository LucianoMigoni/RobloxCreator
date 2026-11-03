--!strict
-- UI del bloque Items (consumibles: pociones, habilidades): un botón por objeto que tiene en la barra
-- de acción, con cuántos le quedan ("x3") y su tecla (1 a 9 en PC); se ocultan los que no tiene. Al
-- usar uno (KitFx "ItemUsed"), aviso con su duración. El efecto (impulso o velocidad) lo pone el
-- servidor y el impulso aparece en el HUD con su reloj.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local Sound = require("../UI/Sound")
local ActionBar = require("./ActionBar")
local KitState = require("./KitState")
local KitUi = require("./KitUi")

local Items = {}

local KEYS = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
}

function Items.start(_hud: HudController.Hud)
	local cfg = KitConfig.items
	if not cfg or #cfg.list == 0 then
		return
	end
	local byId: { [string]: KitTypes.ItemDef } = {}
	for i, def in cfg.list do
		byId[def.id] = def
		ActionBar.add("Item" .. def.id, {
			text = "x0",
			icon = def.icon,
			variant = "Purple",
			order = 10 + i,
			key = KEYS[i],
			onClick = function()
				local ok, reason = KitUi.invoke("UseItem", def.id)
				if not ok then
					KitUi.error(reason)
				end
			end,
		})
		ActionBar.show("Item" .. def.id, false)
	end
	KitState.on("items", function(state: KitTypes.ItemsState)
		local counts = state.counts or {}
		for _, def in cfg.list do
			local count = counts[def.id] or 0
			ActionBar.setText("Item" .. def.id, "x" .. count)
			ActionBar.show("Item" .. def.id, count > 0)
		end
	end)
	Bus.on("Kit:ItemUsed", function(payload: any)
		local def = if typeof(payload) == "table" then byId[payload.id] else nil
		if def then
			Sound.play("Reward")
			KitUi.notify(string.format(UiText.ITEM_ACTIVE, def.name, Format.clock(payload.seconds or def.seconds)), "Purple", def.icon)
		end
	end)
end

return Items
