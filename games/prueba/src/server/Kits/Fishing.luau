--!strict
-- Bloque Fishing del armador: pescar como Fish It! o Fisch.
-- 1. CastLine(): cerca de una parte KitWater (atributo Pool = id de fishing.pools), con la zona
--    abierta y lugar en el inventario. La picada llega a los `wait` segundos (al azar), dividido por la
--    velocidad de la caña y menos la mejora "reel".
-- 2. Al picar, el cliente recibe "Bite" y tiene `reelSeconds` para ReelLine() (antes es "TooEarly";
--    después, "Escaped"). El minijuego de recoger es del cliente; el servidor valida los tiempos.
-- 3. Lo que sale se sortea con la suerte de la caña × la del jugador, con peso (kilos) y variantes.
-- Cañas: la primera se tiene al empezar; las demás se compran (BuyRod) o se ganan ("Rod:<id>").

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Rarity = require(ReplicatedStorage.Shared.Lib.Rarity)
local UnitMath = require(ReplicatedStorage.Shared.Lib.UnitMath)
local Types = require(ReplicatedStorage.Shared.Types)
local BoostService = require("../Boosts/BoostService")
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local Signals = require("../Signals")
local Bonus = require("./Bonus")
local Gates = require("./Gates")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")
local Units = require("./Units")

type FishingData = { rod: string, owned: { [string]: boolean } }
type Cast = { pool: KitTypes.FishingPool, castAt: number, biteAt: number, bit: boolean }

local Fishing = {}

local DEFAULT_RANGE = 40
local TICK = 0.1
local MAX_REEL_BONUS = 0.9

local config: KitTypes.FishingConfig? = nil
local unitsConfig: KitTypes.UnitsConfig? = nil
local pools: { [string]: KitTypes.FishingPool } = {}
local rods: { [string]: KitTypes.FishingRod } = {}
local casts: { [Player]: Cast } = {}
local rng = Random.new()

local function data(player: Player): FishingData?
	local d = DataService.get(player)
	return if d then d.kits.fishing :: FishingData else nil
end

function Fishing.rod(player: Player): KitTypes.FishingRod?
	local cfg = config
	local d = data(player)
	if not cfg then
		return nil
	end
	return (if d then rods[d.rod] else nil) or cfg.rods[1]
end

-- El agua más cercana a su alcance y su sorteo.
local function nearestPool(player: Player): KitTypes.FishingPool?
	local cfg = config
	local root = KitWorld.root(player)
	if not cfg or not root then
		return nil
	end
	local best: KitTypes.FishingPool? = nil
	local bestDistance = math.huge
	for _, water in CollectionService:GetTagged(Tags.WATER) do
		local part = KitWorld.part(water)
		local pool = pools[KitWorld.text(water, "Pool") or ""]
		if part and pool then
			-- Distancia al borde del agua (no al centro: los lagos son grandes).
			local relative = part.CFrame:PointToObjectSpace(root.Position)
			local clamped = Vector3.new(
				math.clamp(relative.X, -part.Size.X / 2, part.Size.X / 2),
				math.clamp(relative.Y, -part.Size.Y / 2, part.Size.Y / 2),
				math.clamp(relative.Z, -part.Size.Z / 2, part.Size.Z / 2)
			)
			local distance = (relative - clamped).Magnitude
			local zone = pool.zone or KitWorld.inherited(water, "Zone")
			if distance <= (cfg.castRange or DEFAULT_RANGE) and distance < bestDistance and Gates.open(player, zone) then
				best = pool
				bestDistance = distance
			end
		end
	end
	return best
end

function Fishing.cast(player: Player): (boolean, string?)
	local cfg = config
	local rod = Fishing.rod(player)
	if not cfg or not rod or not data(player) then
		return false, "LOADING"
	end
	if casts[player] then
		return false, "BUSY"
	end
	if Units.isFull(player) then
		return false, "FULL"
	end
	local pool = nearestPool(player)
	if not pool then
		return false, "FAR"
	end
	local now = os.clock()
	local reel = math.clamp(Bonus.get(player, "reel"), 0, MAX_REEL_BONUS)
	local seconds = (cfg.wait.min + rng:NextNumber() * (cfg.wait.max - cfg.wait.min)) / math.max(0.1, rod.speed) * (1 - reel)
	casts[player] = { pool = pool, castAt = now, biteAt = now + seconds, bit = false }
	Signals.track(player, "Cast", 1)
	return true
end

local function catch(player: Player, cast: Cast)
	local cfg = config
	local units = unitsConfig
	local rod = Fishing.rod(player)
	if not cfg or not rod then
		return
	end
	local entries = UnitMath.entries(cast.pool.entries, Units.defs(), Units.rarities(), if units then units.luckyFrom else nil)
	if #entries == 0 then
		return
	end
	local luck = rod.luck * BoostService.multiplier(player, "Luck")
	local picked = Rarity.roll(entries, luck, function()
		return rng:NextNumber()
	end)
	local unit, reason, isNew = Units.add(player, picked.id, { source = "Catch", roll = true })
	if not unit then
		KitFx.send(player, "Error", { code = reason })
		return
	end
	Signals.track(player, "Catch", 1)
	KitFx.send(player, "Caught", { uid = unit.uid, kind = unit.kind, variant = unit.variant, size = unit.size, weight = unit.weight, isNew = isNew })
end

function Fishing.reel(player: Player): (boolean, string?)
	local cfg = config
	local cast = casts[player]
	if not cfg or not cast then
		return false, "NO_CAST"
	end
	casts[player] = nil
	local now = os.clock()
	if now < cast.biteAt then
		KitFx.send(player, "TooEarly", {})
		return false, "TOO_EARLY"
	end
	if now > cast.biteAt + cfg.reelSeconds then
		KitFx.send(player, "Escaped", {})
		return false, "ESCAPED"
	end
	catch(player, cast)
	return true
end

local function own(player: Player, rod: KitTypes.FishingRod)
	local d = data(player)
	if d then
		d.owned[rod.id] = true
		d.rod = rod.id
		Signals.dirty(player)
	end
end

function Fishing.buyRod(player: Player, id: string): (boolean, string?)
	local rod = rods[id]
	local d = data(player)
	if not rod or not d then
		return false, "UNKNOWN"
	end
	if d.owned[id] then
		d.rod = id
		Signals.dirty(player)
		return true
	end
	local price = rod.price
	if not price then
		return false, "NOT_FOR_SALE"
	end
	if not CurrencyService.spend(player, price.amount, Enum.AnalyticsEconomyTransactionType.Shop, "Rod_" .. id, price.currency) then
		return false, "NOT_ENOUGH"
	end
	own(player, rod)
	Signals.track(player, "RodBought", 1)
	KitFx.send(player, "RodBought", { id = id })
	return true
end

local function give(player: Player, value: string, _count: number): (boolean, Types.RewardLine?)
	local rod = rods[value]
	if not rod or not data(player) then
		return false, nil
	end
	own(player, rod)
	return true, { icon = "fishing", text = rod.name, kind = "item" }
end

function Fishing.init(recipe: KitTypes.KitConfig)
	local cfg = recipe.fishing
	if not cfg then
		return
	end
	config = cfg
	unitsConfig = recipe.units
	for _, pool in cfg.pools do
		pools[pool.id] = pool
	end
	for _, rod in cfg.rods do
		rods[rod.id] = rod
	end
	local first = cfg.rods[1]
	DataService.registerKit("fishing", { rod = if first then first.id else "", owned = if first then { [first.id] = true } else {} })
end

function Fishing.start(_recipe: KitTypes.KitConfig)
	local cfg = config
	if not cfg then
		return
	end
	local rodIds = {}
	for id in rods do
		table.insert(rodIds, id)
	end
	Remotes.onInvoke("CastLine", { args = {}, rate = { count = 3, perSeconds = 1 } }, Fishing.cast)
	Remotes.onInvoke("ReelLine", { args = {}, rate = { count = 3, perSeconds = 1 } }, Fishing.reel)
	Remotes.onInvoke("BuyRod", { args = { Validate.oneOf(rodIds) }, rate = { count = 3, perSeconds = 1 } }, Fishing.buyRod)
	Players.PlayerRemoving:Connect(function(player: Player)
		casts[player] = nil
	end)
	-- Avisa la picada y suelta los lances olvidados.
	task.spawn(function()
		while true do
			task.wait(TICK)
			local now = os.clock()
			for player, cast in casts do
				if not cast.bit and now >= cast.biteAt then
					cast.bit = true
					KitFx.send(player, "Bite", { reelSeconds = cfg.reelSeconds })
				elseif now > cast.biteAt + cfg.reelSeconds + 1 then
					casts[player] = nil
					KitFx.send(player, "Escaped", {})
				end
			end
		end
	end)
end

function Fishing.snapshot(player: Player): KitTypes.FishingState?
	local d = data(player)
	local rod = Fishing.rod(player)
	if not d or not rod then
		return nil
	end
	return { rod = rod.id, owned = d.owned }
end

Fishing.items = { Rod = give }

return Fishing
