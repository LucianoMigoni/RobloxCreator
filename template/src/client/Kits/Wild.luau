--!strict
-- UI del bloque Wild (criaturas que andan sueltas y se capturan): la captura se hace con el prompt del
-- servidor (mantener apretado); acá se muestra lo capturado (popup si es nuevo o raro). Lo que pide
-- cada criatura ("Needs 500 Strength") está en su cartel (Units) y los errores (WEAK, ZONE, FULL) los
-- avisa KitUi.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local KitUi = require("./KitUi")

local Wild = {}

function Wild.start(_hud: HudController.Hud)
	if not KitConfig.wild then
		return
	end
	Bus.on("Kit:Captured", function(payload: any)
		if typeof(payload) == "table" and typeof(payload.kind) == "string" then
			KitUi.announce({ kind = payload.kind, variant = payload.variant, size = payload.size, isNew = payload.isNew == true }, "Capture")
		end
	end)
end

return Wild
