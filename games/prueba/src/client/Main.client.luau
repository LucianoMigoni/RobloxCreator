--!strict
-- Arranque del cliente: arma la UI con UIKit y conecta los controladores al estado que manda el servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(ReplicatedStorage.Shared.UIKit)
local BaseController = require("./Controllers/BaseController")
local HudController = require("./Controllers/HudController")
local InventoryController = require("./Controllers/InventoryController")
local ShopController = require("./Controllers/ShopController")
local PlayerState = require("./PlayerState")

local screen = UIKit.screen("Hud", Players.LocalPlayer:WaitForChild("PlayerGui"))
local sideBar = HudController.start(screen)
ShopController.start(screen, sideBar)
InventoryController.start(screen, sideBar)
BaseController.start(screen)
-- Al final: así los controladores ya escuchan cuando llega el primer estado.
PlayerState.start()
