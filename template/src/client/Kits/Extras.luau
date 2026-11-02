--!strict
-- Avisos chicos de dos bloques sin ventana propia:
-- - Belt (cinta de compra): lo comprado (KitFx "Bought"), popup si es nuevo o raro.
-- - Tycoon (edificios en la base): lo construido (KitFx "Built"), con sonido y confeti.
-- Los carteles y botones de los dos están en el mundo (los pone el servidor).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local Effects = require("../UI/Effects")
local Sound = require("../UI/Sound")
local KitUi = require("./KitUi")

local Extras = {}

function Extras.belt(_hud: HudController.Hud)
	if not KitConfig.belt then
		return
	end
	Bus.on("Kit:Bought", function(payload: any)
		if typeof(payload) == "table" and typeof(payload.kind) == "string" then
			Sound.play("Purchase")
			KitUi.announce({ kind = payload.kind, variant = payload.variant, size = payload.size, isNew = payload.isNew == true }, "Belt")
		end
	end)
end

function Extras.tycoon(hud: HudController.Hud)
	if not KitConfig.tycoon then
		return
	end
	Bus.on("Kit:Built", function(payload: any)
		if typeof(payload) == "table" and typeof(payload.name) == "string" then
			Sound.play("Purchase")
			Effects.confetti(hud.screen, 30)
			KitUi.notify(string.format(UiText.BUILT, payload.name), "Accept", "base")
		end
	end)
end

return Extras
