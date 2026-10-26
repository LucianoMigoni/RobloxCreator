--!strict
-- Arranque del servidor: cada servicio expone start() y se inicia acá, en orden.

local DataService = require("./Data/DataService")
local Remotes = require("./Net/Remotes")
local OnboardingService = require("./Onboarding/OnboardingService")
local PlayerStateService = require("./PlayerStateService")
local ShopService = require("./Shop/ShopService")

Remotes.start()
DataService.start()
PlayerStateService.start()
OnboardingService.start()
ShopService.start()
