--!strict
-- Bloque Items del armador: consumibles que se usan con una tecla o un botón (pociones de suerte o
-- plata, habilidades como "Sprint" de Ride a Dino). Cada uno activa su impulso de BoostConfig.TIMED
-- (`boost`) y/o multiplica la velocidad de caminar (`walkSpeed`) durante `seconds`. Se juntan hasta
-- `maxStack` jugando; lo que llega por premio o compra ("Item:<id>") entra igual, aunque pase el tope
-- (lo pagado nunca se pierde).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Types = require(ReplicatedStorage.Shared.Types)
local BoostService = require("../Boosts/BoostService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local Signals = require("../Signals")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")

type ItemsData = { counts: { [string]: number } }

local Items = {}

local config: KitTypes.ItemsConfig? = nil
local byId: { [string]: KitTypes.ItemDef } = {}
local speedEnds: { [Player]: { [string]: number } } = {}

local function data(player: Player): ItemsData?
	local d = DataService.get(player)
	return if d then d.kits.items :: ItemsData else nil
end

function Items.count(player: Player, id: string): number
	local d = data(player)
	return if d then d.counts[id] or 0 else 0
end

-- Suma `count`. Jugando respeta el tope (`force` = sin tope, para premios y compras). Devuelve cuántos.
function Items.add(player: Player, id: string, count: number, force: boolean?): number
	local cfg = config
	local d = data(player)
	if not cfg or not d or not byId[id] or count <= 0 then
		return 0
	end
	local have = d.counts[id] or 0
	local amount = if force then count else math.max(0, math.min(count, cfg.maxStack - have))
	if amount > 0 then
		d.counts[id] = have + amount
		Signals.dirty(player)
	end
	return amount
end

function Items.use(player: Player, id: string): (boolean, string?)
	local def = byId[id]
	local d = data(player)
	if not def or not d then
		return false, "UNKNOWN"
	end
	local have = d.counts[id] or 0
	if have <= 0 then
		return false, "NONE"
	end
	if have > 1 then
		d.counts[id] = have - 1
	else
		d.counts[id] = nil
	end
	local boost = def.boost
	if boost then
		BoostService.grant(player, boost, def.seconds)
	end
	local walk = def.walkSpeed
	if walk then
		local source = "Item_" .. id
		local ends = speedEnds[player] or {}
		speedEnds[player] = ends
		ends[source] = os.clock() + def.seconds
		KitWorld.setSpeedFactor(player, source, walk)
	end
	Signals.track(player, "ItemUsed", 1)
	KitFx.send(player, "ItemUsed", { id = id, seconds = def.seconds })
	Signals.dirty(player)
	return true
end

local function give(player: Player, value: string, count: number): (boolean, Types.RewardLine?)
	local def = byId[value]
	if not def or Items.add(player, value, count, true) <= 0 then
		return false, nil
	end
	return true, { icon = def.icon, text = (if count > 1 then count .. "x " else "") .. def.name, kind = "item" }
end

function Items.init(recipe: KitTypes.KitConfig)
	local cfg = recipe.items
	if not cfg then
		return
	end
	config = cfg
	for _, def in cfg.list do
		byId[def.id] = def
	end
	DataService.registerKit("items", { counts = {} })
end

function Items.start(_recipe: KitTypes.KitConfig)
	if not config then
		return
	end
	local ids = {}
	for id in byId do
		table.insert(ids, id)
	end
	Remotes.onInvoke("UseItem", { args = { Validate.oneOf(ids) }, rate = { count = 4, perSeconds = 1 } }, Items.use)
	-- Las habilidades de velocidad se apagan solas.
	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = os.clock()
			for player, ends in speedEnds do
				for source, endsAt in ends do
					if now >= endsAt then
						ends[source] = nil
						KitWorld.setSpeedFactor(player, source, nil)
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		speedEnds[player] = nil
	end)
end

function Items.snapshot(player: Player): KitTypes.ItemsState?
	local d = data(player)
	return if d then { counts = d.counts } else nil
end

Items.items = { Item = give }

return Items
