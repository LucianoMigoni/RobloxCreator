--!strict
-- Arranque del servidor: cada servicio expone start() y se inicia acá, en orden.

local DataService = require("./Data/DataService")
local Remotes = require("./Net/Remotes")
local OnboardingService = require("./Onboarding/OnboardingService")
local PlayerStateService = require("./PlayerStateService")
local ShopService = require("./Shop/ShopService")
local BeltService = require("./Critters/BeltService")
local CritterService = require("./Critters/CritterService")
local PlotService = require("./Critters/PlotService")

Remotes.start()
DataService.start()
PlayerStateService.start()
OnboardingService.start()
ShopService.start()
CritterService.start() -- antes de PlotService: escucha las bases que se asignan al arrancar
PlotService.start()
BeltService.start()
