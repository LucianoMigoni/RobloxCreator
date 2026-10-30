--!strict
-- Arranque del cliente: arma el HUD estilo hit y conecta cada ventana al estado que manda el servidor.
-- Los bloques del armador que usa la receta (Config/KitConfig) agregan su UI desde client/Kits con la
-- misma interfaz: start(hud). Al final se pide el primer estado, cuando todos ya escuchan.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(ReplicatedStorage.Shared.UIKit)
local AnnounceController = require("./Controllers/AnnounceController")
local BoostsController = require("./Controllers/BoostsController")
local CodesController = require("./Controllers/CodesController")
local DailyController = require("./Controllers/DailyController")
local GiftController = require("./Controllers/GiftController")
local GiftsController = require("./Controllers/GiftsController")
local HudController = require("./Controllers/HudController")
local IndexController = require("./Controllers/IndexController")
local OfferController = require("./Controllers/OfferController")
local QuestController = require("./Controllers/QuestController")
local RebirthController = require("./Controllers/RebirthController")
local RewardController = require("./Controllers/RewardController")
local SettingsController = require("./Controllers/SettingsController")
local ShopController = require("./Controllers/ShopController")
local SocialController = require("./Controllers/SocialController")
local SpinController = require("./Controllers/SpinController")
local Kits = require("./Kits/Kits")
local Bus = require("./Bus")
local PlayerState = require("./PlayerState")
local Sound = require("./UI/Sound")
local Windows = require("./UI/Windows")
local World = require("./UI/World")

local screen = UIKit.screen("Hud", Players.LocalPlayer:WaitForChild("PlayerGui"))
Windows.start(screen)
World.start()
-- Flechas en el piso hasta el objetivo: el kit llama Bus.call("ShowPath", parte) y nil para sacarlas.
Bus.handle("ShowPath", World.path)
local hud = HudController.start(screen)

RewardController.start(hud)
AnnounceController.start(hud)
ShopController.start(hud)
IndexController.start(hud)
RebirthController.start(hud)
QuestController.start(hud)
DailyController.start(hud)
SpinController.start(hud)
CodesController.start(hud)
SettingsController.start(hud)
GiftsController.start(hud)
OfferController.start(hud)
SocialController.start(hud)
GiftController.start(hud)
BoostsController.start(hud)

Kits.start(hud)

Sound.preload({ "Click", "Open", "Close", "Coin", "Reward", "Purchase", "SpinTick" })
Sound.playMusic("Lobby")
-- Al final: así los controladores ya escuchan cuando llega el primer estado.
PlayerState.start()
