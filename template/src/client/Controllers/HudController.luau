--!strict
-- HUD: monedas arriba al centro y barra de botones de menú arriba a la izquierda (fuera de las zonas
-- táctiles reservadas). Avisa una vez si los datos no cargaron y el progreso no se guarda.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local PlayerState = require("../PlayerState")

local HudController = {}

-- Devuelve la barra lateral para que los demás controladores agreguen sus botones.
function HudController.start(screen: ScreenGui): Frame
	local coins = UIKit.currency(UIKit.currencyBar(screen), "Coins")
	local sideBar = UIKit.sideBar(screen)
	local warned = false
	PlayerState.Changed:Connect(function(state)
		UIKit.setCurrency(coins, state.coins)
		if not state.savesProgress and not warned then
			warned = true
			UIKit.notify(screen, UiText.NOT_SAVING, "Close")
		end
	end)
	return sideBar
end

return HudController
