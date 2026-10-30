--!strict
-- Lado cliente del armador: arranca la UI de cada bloque que usa la receta (Config/KitConfig), todos
-- con la misma interfaz, start(hud), y la barra de acción de abajo al centro que comparten. Lo que
-- cada bloque muestra llega en state.kit.<bloque> (KitState); lo que pide va por sus remotes.
-- Cada bloque nuevo se suma a BLOCKS (references/bloques.md).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local KitCheck = require(ReplicatedStorage.Shared.Lib.KitCheck)
local Net = require(ReplicatedStorage.Shared.Net)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local ActionBar = require("./ActionBar")
local Units = require("./Units")

type Block = { key: string, start: (HudController.Hud) -> () }

local Kits = {}

-- Un bloque por fila, en el orden de KitCheck.BLOCKS.
local BLOCKS: { Block } = {
	{ key = "units", start = Units.start },
}

function Kits.start(hud: HudController.Hud)
	if #KitCheck.blocks(KitConfig) == 0 then
		return
	end
	ActionBar.start(hud)
	-- Efectos que manda el servidor (server/Kits/KitFx): cada bloque los escucha con Bus.on("Kit:<nombre>").
	task.spawn(function()
		Net.event("KitFx").OnClientEvent:Connect(function(name: any, payload: any)
			if typeof(name) == "string" then
				Bus.emit("Kit:" .. name, payload)
			end
		end)
	end)
	for _, block in BLOCKS do
		if (KitConfig :: any)[block.key] ~= nil then
			-- El cast deja leer el error: pcall de una función sin retorno solo tipa el booleano.
			local ok, err = pcall(block.start :: (HudController.Hud) -> ...any, hud)
			if not ok then
				warn("[Kits] la UI del bloque " .. block.key .. " no arrancó: " .. tostring(err))
			end
		end
	end
end

return Kits
