--!strict
-- Índice de colección ("Index" de los hits): qué unidades y variantes descubrió cada jugador. El kit
-- avisa cada hallazgo (discover) y define las zonas (setZones): cada una con sus piezas y un premio que
-- se reclama una vez al completarla (ClaimIndexZone), como Steal An Egg. Completar el índice es una meta
-- larga y la ventana muestra "Unlocked: 12/80".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Collection = require(ReplicatedStorage.Shared.Lib.Collection)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local RewardService = require("../Rewards/RewardService")
local Signals = require("../Signals")

local IndexService = {}

export type Zone = {
	id: string,
	name: string, -- se ve en el juego (inglés)
	keys: { string }, -- lo que hay que descubrir para el premio ("Kitty|Normal")
	reward: Types.Reward?,
	image: string?, -- rbxassetid de la foto de la zona
	isUnlocked: ((Player) -> boolean)?, -- sin esto, siempre abierta
}

local total = 0
local zones: { Zone } = {}
local byId: { [string]: Zone } = {}

-- Cuántas piezas hay en total, si el kit no usa zonas (con zonas se cuentan solas).
function IndexService.setTotal(count: number)
	total = math.max(0, count)
end

-- El kit define sus zonas en orden (la primera arriba). Se puede llamar de nuevo con todas.
function IndexService.setZones(list: { Zone })
	zones = table.clone(list)
	table.clear(byId)
	for _, zone in zones do
		byId[zone.id] = zone
	end
	total = math.max(total, Collection.total(zones :: { any }))
end

-- Anota un hallazgo ("Dragon|Gold"). Devuelve true si es nuevo (para el "NEW!" del popup).
function IndexService.discover(player: Player, key: string): boolean
	local data = DataService.get(player)
	if not data or data.index[key] then
		return false
	end
	data.index[key] = true
	Signals.track(player, "Discover", 1)
	Signals.dirty(player)
	return true
end

function IndexService.counts(player: Player): (number, number)
	local data = DataService.get(player)
	local found = 0
	if data then
		for _ in data.index do
			found += 1
		end
	end
	return found, math.max(total, found)
end

local function unlocked(player: Player, zone: Zone): boolean
	local check = zone.isUnlocked
	if not check then
		return true
	end
	local ok, result = pcall(check, player)
	return ok and result == true
end

-- Las zonas como las ve el jugador (PlayerSnapshot.index.zones).
function IndexService.zones(player: Player): { Types.IndexZone }
	local data = DataService.get(player)
	local out: { Types.IndexZone } = {}
	if not data then
		return out
	end
	for _, zone in zones do
		local found, count = Collection.progress(data.index, zone.keys)
		table.insert(out, {
			id = zone.id,
			name = zone.name,
			image = zone.image,
			found = found,
			total = count,
			unlocked = unlocked(player, zone),
			claimed = data.indexClaimed[zone.id] == true,
			reward = zone.reward,
		})
	end
	return out
end

local function claim(player: Player, id: string): (boolean, string?)
	local data = DataService.get(player)
	if not data then
		return false, "LOADING"
	end
	local zone = byId[id]
	if not zone or not zone.reward then
		return false, "UNKNOWN"
	end
	if not unlocked(player, zone) then
		return false, "LOCKED"
	end
	if not Collection.claim(data.index, data.indexClaimed, zone) then
		return false, "NOT_READY"
	end
	local reward = table.clone(zone.reward)
	reward.label = reward.label or "ZONE COMPLETE!"
	RewardService.grant(player, reward, Enum.AnalyticsEconomyTransactionType.Gameplay, "IndexZone_" .. zone.id, true)
	Signals.track(player, "IndexZone", 1)
	Signals.dirty(player)
	return true
end

function IndexService.start()
	-- Texto con tope y no oneOf: el kit puede definir las zonas después de start().
	Remotes.onInvoke("ClaimIndexZone", { args = { Validate.string({ maxLength = 64 }) }, rate = { count = 2, perSeconds = 1 } }, claim)
end

return IndexService
