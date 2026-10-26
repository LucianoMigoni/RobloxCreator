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
local StealService = require("./Critters/StealService")

Remotes.start()
DataService.start()
PlayerStateService.start()
OnboardingService.start()
ShopService.start()
-- Antes de PlotService: escuchan las bases que se asignan al arrancar.
CritterService.start()
StealService.start()
PlotService.start()
BeltService.start()
