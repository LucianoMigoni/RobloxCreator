--!strict
-- Bloque Merge del armador: juntar iguales para subir, como Chicken Farm o la máquina dorada de los
-- simuladores.
-- - "tier": `count` unidades del mismo nivel → 1 del nivel siguiente (units.list[].tier); con
--   `mutationChance`, la nueva puede salir con mutación.
-- - "variant": `count` iguales de una mutación → 1 de la siguiente en `variantChain`
--   (Normal → Gold → Diamond...), con el tamaño de la primera.
-- Con `seconds`, el resultado tarda (un bucle lo entrega solo al estar listo; el producto "Merge:Skip"
-- lo adelanta, y si no había nada esperando queda guardado para la próxima). Con `machine`, se fusiona
-- cerca de una KitMergeMachine. Nunca toma unidades cuidadas ni equipadas (Lib/UnitPick).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local UnitMath = require(ReplicatedStorage.Shared.Lib.UnitMath)
local UnitPick = require(ReplicatedStorage.Shared.Lib.UnitPick)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local Signals = require("../Signals")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")
local Units = require("./Units")

type Pending = { kind: string, variant: string?, size: string?, readyAt: number }
type MergeData = { pending: Pending?, skips: number, lucky: number }

local Merge = {}

local MACHINE_RANGE = 20
local TICK = 1

local config: KitTypes.MergeConfig? = nil
local rng = Random.new()

local function data(player: Player): MergeData?
	local d = DataService.get(player)
	return if d then d.kits.merge :: MergeData else nil
end

local function nearMachine(player: Player): boolean
	local machines = CollectionService:GetTagged(Tags.MERGE_MACHINE)
	if #machines == 0 then
		return true
	end
	for _, machine in machines do
		if KitWorld.near(player, machine, MACHINE_RANGE) then
			return true
		end
	end
	return false
end

local function multOf(variant: string?): number
	for _, v in Units.variants() do
		if v.id == variant then
			return v.mult
		end
	end
	return 1
end

-- La mutación del resultado (modo "tier"). Es aleatorio pago (Lib/PaidRandom): a quien PolicyService se
-- lo restringe, nunca sale mutación (y no gasta cargas de Lucky Fuse).
local function rollMutation(player: Player, cfg: KitTypes.MergeConfig, d: MergeData): string?
	if Units.restricted(player) then
		return nil
	end
	local odds = cfg.odds
	local lucky = cfg.lucky
	if lucky and d.lucky > 0 then
		d.lucky -= 1
		odds = lucky
	end
	if odds then
		local r = rng:NextNumber()
		local acc = 0
		for _, v in Units.variants() do
			local p = odds[v.id]
			if p then
				acc += p
				if r < acc then
					return v.id
				end
			end
		end
		return nil
	end
	local chance = cfg.mutationChance
	if chance and rng:NextNumber() < chance then
		local pool = {}
		for _, v in Units.variants() do
			if v.id ~= "Normal" then
				table.insert(pool, v)
			end
		end
		return UnitMath.rollVariant(pool, 1, function()
			return rng:NextNumber()
		end)
	end
	return nil
end

-- La unidad del nivel siguiente (modo "tier"), o nil si es la última.
function Merge.nextKind(kind: string): string?
	local def = Units.def(kind)
	local tier = if def then def.tier else nil
	if not tier then
		return nil
	end
	for id, other in Units.defs() do
		if other.tier == tier + 1 then
			return id
		end
	end
	return nil
end

local function deliver(player: Player, d: MergeData)
	local pending = d.pending
	if not pending then
		return
	end
	d.pending = nil
	local unit, _, isNew = Units.add(player, pending.kind, { source = "Merge", variant = pending.variant, size = pending.size, force = true })
	if unit then
		KitFx.send(player, "Merged", { kind = unit.kind, variant = unit.variant, size = unit.size, isNew = isNew })
	end
	Signals.dirty(player)
end

function Merge.merge(player: Player, kind: string, variant: string?): (boolean, string?)
	local cfg = config
	local d = data(player)
	if not cfg or not d then
		return false, "LOADING"
	end
	if d.pending then
		return false, "BUSY"
	end
	if cfg.machine and not nearMachine(player) then
		return false, "FAR"
	end
	if not Units.def(kind) then
		return false, "UNKNOWN"
	end
	local result: Pending
	local group: { number }?
	if cfg.mode == "tier" then
		local target = Merge.nextKind(kind)
		if not target then
			return false, "MAX"
		end
		group = UnitPick.group(Units.list(player), kind, nil, cfg.count)
		if not group then
			return false, "NOT_ENOUGH"
		end
		local mutation = rollMutation(player, cfg, d)
		if cfg.keepMutation then
			for _, uid in group do
				local unit = Units.find(player, uid)
				if unit and multOf(unit.variant) > multOf(mutation) then
					mutation = unit.variant
				end
			end
		end
		result = { kind = target, variant = mutation, readyAt = 0 }
	else
		local chain = cfg.variantChain or {}
		local current = variant or "Normal"
		local index = table.find(chain, current)
		local nextVariant = if index then chain[index + 1] else nil
		if not nextVariant then
			return false, "MAX"
		end
		group = UnitPick.group(Units.list(player), kind, current, cfg.count)
		local first = if group then Units.find(player, group[1]) else nil
		result = { kind = kind, variant = if nextVariant == "Normal" then nil else nextVariant, size = if first then first.size else nil, readyAt = 0 }
	end
	if not group then
		return false, "NOT_ENOUGH"
	end
	for _, uid in group do
		Units.remove(player, uid, "Merge")
	end
	Signals.track(player, "Merge", 1)
	local seconds = cfg.seconds or 0
	if d.skips > 0 then
		d.skips -= 1
		seconds = 0
	end
	result.readyAt = os.time() + seconds
	d.pending = result
	if seconds <= 0 then
		deliver(player, d)
	else
		KitFx.send(player, "MergeStarted", { kind = result.kind, readyAt = result.readyAt })
		Signals.dirty(player)
	end
	return true
end

-- Premio "Merge:Skip": termina ya la fusión en curso; si no hay, queda guardado para la próxima.
-- Premio "Merge:Lucky": cargas de Lucky Fuse (las próximas fusiones usan `lucky`).
local function give(player: Player, value: string, count: number): (boolean, Types.RewardLine?)
	local d = data(player)
	if not d then
		return false, nil
	end
	if value == "Lucky" then
		d.lucky += count
		Signals.dirty(player)
		return true, { icon = "luck", text = string.format(UiText.LUCKY_FUSES, count), kind = "item" }
	end
	if d.pending then
		deliver(player, d)
		d.skips += math.max(0, count - 1)
	else
		d.skips += count
	end
	Signals.dirty(player)
	return true, { icon = "timer", text = UiText.MERGE_SKIPPED, kind = "item" }
end

function Merge.init(recipe: KitTypes.KitConfig)
	config = recipe.merge
	if config then
		DataService.registerKit("merge", { pending = nil, skips = 0, lucky = 0 })
	end
end

function Merge.start(_recipe: KitTypes.KitConfig)
	if not config then
		return
	end
	Remotes.onInvoke("MergeUnits", {
		args = { Validate.string({ maxLength = 64 }), Validate.optional(Validate.string({ maxLength = 32 })) },
		rate = { count = 3, perSeconds = 1 },
	}, Merge.merge)
	KitWorld.tagged(Tags.MERGE_MACHINE, function(instance: Instance)
		KitWorld.sign(instance, UiText.PROMPT_MERGE, "Premium", "merge", 10)
	end)
	task.spawn(function()
		while true do
			task.wait(TICK)
			local now = os.time()
			for _, player in Players:GetPlayers() do
				local d = data(player)
				local pending = if d then d.pending else nil
				if d and pending and now >= pending.readyAt then
					deliver(player, d)
				end
			end
		end
	end)
end

function Merge.snapshot(player: Player): KitTypes.MergeState?
	local d = data(player)
	return if d then { pending = d.pending, skips = d.skips, lucky = d.lucky } else nil
end

Merge.items = { Merge = give }

return Merge
