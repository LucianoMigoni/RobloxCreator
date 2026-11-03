--!strict
-- Bloque Equip del armador: mascotas que siguen y multiplican (Pet Simulator, Tap Simulator). Hasta
-- `slots` equipadas (más las mejoras "equip" y el pase `slotPass`); cada una suma su poder
-- (UnitMath.power) al multiplicador de equip.stat en BoostService: "+25% Money". Lo colocado en una
-- base no se equipa. El cliente dibuja las equipadas siguiendo a su dueño con el atributo "Equipped"
-- del jugador ("Dragon|Gold|Huge;Kitty||").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local UnitPick = require(ReplicatedStorage.Shared.Lib.UnitPick)
local BoostService = require("../Boosts/BoostService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local ShopService = require("../Shop/ShopService")
local Signals = require("../Signals")
local Bonus = require("./Bonus")
local Units = require("./Units")

local Equip = {}

local config: KitTypes.EquipConfig? = nil
local label = "Pets"

function Equip.slots(player: Player): number
	local cfg = config
	if not cfg then
		return 0
	end
	local pass = 0
	if cfg.slotPass and ShopService.ownsPass(player, cfg.slotPass) then
		pass = cfg.passSlots or 0
	end
	return math.clamp(cfg.slots + pass + math.floor(Bonus.get(player, "equip")), 0, cfg.maxSlots)
end

local function equipped(player: Player): { Units.Unit }
	local out = {}
	for _, unit in Units.list(player) do
		if unit.equipped then
			table.insert(out, unit)
		end
	end
	return out
end

-- Lo que suman las equipadas al multiplicador (0.75 = +75 %).
function Equip.power(player: Player): number
	local total = 0
	for _, unit in equipped(player) do
		total += Units.power(unit)
	end
	return total
end

-- Atributo que el cliente usa para dibujar las mascotas que siguen a cada jugador.
local function publish(player: Player)
	local parts = {}
	for _, unit in equipped(player) do
		table.insert(parts, unit.kind .. "|" .. (unit.variant or "") .. "|" .. (unit.size or ""))
	end
	player:SetAttribute("Equipped", table.concat(parts, ";"))
	BoostService.refresh(player)
end

-- Saca de más si bajaron los espacios y lo que quedó colocado en una base.
local function tidy(player: Player)
	local slots = Equip.slots(player)
	local count = 0
	for _, unit in equipped(player) do
		count += 1
		if count > slots or unit.slot ~= nil then
			Units.equip(player, unit, false)
		end
	end
end

function Equip.equip(player: Player, uid: number): (boolean, string?)
	local unit = Units.find(player, uid)
	if not unit then
		return false, "UNKNOWN"
	end
	if unit.equipped then
		return true
	end
	if unit.slot ~= nil then
		return false, "PLACED"
	end
	if #equipped(player) >= Equip.slots(player) then
		return false, "FULL"
	end
	Units.equip(player, unit, true)
	Signals.track(player, "Equip", 1)
	return true
end

function Equip.unequip(player: Player, uid: number): boolean
	local unit = Units.find(player, uid)
	if not unit or not unit.equipped then
		return false
	end
	Units.equip(player, unit, false)
	return true
end

-- Equipa las de más poder entre las que no están colocadas.
function Equip.best(player: Player)
	local loose = {}
	for _, unit in Units.list(player) do
		if unit.slot == nil then
			table.insert(loose, unit)
		end
	end
	local chosen: { [number]: boolean } = {}
	for _, uid in UnitPick.best(loose, Equip.slots(player), Units.power) do
		chosen[uid] = true
	end
	for _, unit in loose do
		Units.equip(player, unit, chosen[unit.uid] == true)
	end
	Signals.track(player, "Equip", 1)
end

function Equip.init(recipe: KitTypes.KitConfig)
	local cfg = recipe.equip
	if not cfg then
		return
	end
	config = cfg
	local units = recipe.units
	label = if units then units.label else label
end

function Equip.start(_recipe: KitTypes.KitConfig)
	local cfg = config
	if not cfg then
		return
	end
	BoostService.registerProvider({ cfg.stat }, function(player: Player)
		local power = Equip.power(player)
		if power <= 0 then
			return {}
		end
		return { { stat = cfg.stat, kind = "add", value = power, label = label } }
	end)
	Units.Changed:Connect(function(player: Player)
		publish(player)
	end)
	Units.Removed:Connect(function(player: Player, unit: Units.Unit)
		if unit.equipped then
			publish(player)
		end
	end)
	Bonus.Changed:Connect(function(player: Player, effect: string)
		if effect == "equip" then
			tidy(player)
			Signals.dirty(player)
		end
	end)
	DataService.StateChanged:Connect(function(player: Player, state: string)
		if state ~= "loading" then
			tidy(player)
			publish(player)
		end
	end)
	local uid = Validate.number({ integer = true, min = 1 })
	Remotes.onInvoke("EquipUnit", { args = { uid }, rate = { count = 10, perSeconds = 1 } }, Equip.equip)
	Remotes.onInvoke("UnequipUnit", { args = { uid }, rate = { count = 10, perSeconds = 1 } }, Equip.unequip)
	Remotes.onInvoke("EquipBest", { args = {}, rate = { count = 2, perSeconds = 1 } }, function(player: Player): boolean
		Equip.best(player)
		return true
	end)
end

function Equip.snapshot(player: Player): KitTypes.EquipState
	return { slots = Equip.slots(player), power = Equip.power(player) }
end

return Equip
