--!strict
-- Bloque Units del armador: todo lo coleccionable (mascotas, criaturas, peces, cultivos, dados). Lleva
-- el inventario de cada jugador (data.kits.units), tira mutación, tamaño y peso con la suerte del
-- jugador, anota el índice, anuncia lo raro y entrega los premios "Unit:<unidad>[:<mutación>[:<tamaño>]]".
-- Los demás bloques consiguen, colocan, venden, fusionan, equipan o roban unidades por acá, y escuchan
-- Added, Removed y Changed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RarityConfig = require(ReplicatedStorage.Shared.Config.RarityConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local UnitMath = require(ReplicatedStorage.Shared.Lib.UnitMath)
local Types = require(ReplicatedStorage.Shared.Types)
local BoostService = require("../Boosts/BoostService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local IndexService = require("../Retention/IndexService")
local AnnounceService = require("../Social/AnnounceService")
local Signals = require("../Signals")
local Bonus = require("./Bonus")

export type Unit = KitTypes.Unit

export type AddOptions = {
	source: string, -- de dónde vino ("Roll", "Belt", "Steal", "Catch", "Reward"): señales y avisos
	variant: string?,
	size: string?,
	weight: number?,
	roll: boolean?, -- tirar mutación, tamaño y peso al azar con la suerte del jugador
	force: boolean?, -- aunque el inventario esté lleno (lo comprado con Robux siempre se entrega)
	quiet: boolean?, -- sin aviso al servidor
}

type Data = { list: { Unit }, nextId: number, orphans: { Unit } }

local Units = {}

local added = Instance.new("BindableEvent")
-- (player, unit, source)
Units.Added = added.Event
local removed = Instance.new("BindableEvent")
-- (player, unit, reason)
Units.Removed = removed.Event
local changed = Instance.new("BindableEvent")
-- (player, unit)
Units.Changed = changed.Event

local MAX_REWARD_COUNT = 100
local RARE = "Rare" -- desde acá cuenta para "Get 3 Rare or better" (RareFound)
local ANNOUNCE_MULT = 5 -- mutaciones que multiplican esto o más se anuncian siempre (Rainbow, Galaxy)

local config: KitTypes.UnitsConfig? = nil
local defs: { [string]: KitTypes.UnitDef } = {}
local rarities: { string } = {}
local tiers: { [string]: RarityConfig.Tier } = {}
for _, tier in RarityConfig.TIERS do
	table.insert(rarities, tier.id)
	tiers[tier.id] = tier
end
local mutations: { UnitMath.Variant } = {}
for _, v in RarityConfig.MUTATIONS do
	table.insert(mutations, { id = v.id, weight = v.weight, mult = v.mult, lucky = v.lucky })
end
local sizes: { UnitMath.Variant } = {}
for _, v in RarityConfig.SIZES do
	table.insert(sizes, { id = v.id, weight = v.weight, mult = v.mult, lucky = v.lucky })
end

local rng = Random.new()
local function random(): number
	return rng:NextNumber()
end

local function data(player: Player): Data?
	local d = DataService.get(player)
	return if d then d.kits.units :: Data else nil
end

local function normal(id: string?): string?
	return if id == "Normal" then nil else id
end

function Units.def(kind: string): KitTypes.UnitDef?
	return defs[kind]
end

-- Rarezas en orden (RarityConfig.TIERS), mutaciones y tamaños como los usa Lib/UnitMath.
function Units.rarities(): { string }
	return rarities
end

function Units.variants(): ({ UnitMath.Variant }, { UnitMath.Variant })
	return mutations, sizes
end

-- La lista viva del jugador (vacía mientras carga). Para cambiarla, usar las funciones de este módulo.
function Units.list(player: Player): { Unit }
	local d = data(player)
	return if d then d.list else {}
end

function Units.find(player: Player, uid: number): Unit?
	for _, unit in Units.list(player) do
		if unit.uid == uid then
			return unit
		end
	end
	return nil
end

function Units.count(player: Player): number
	return #Units.list(player)
end

-- Lugar en el inventario: el de la receta más las mejoras ("inventory").
function Units.max(player: Player): number
	local cfg = config
	return (if cfg then cfg.maxInventory else 0) + math.floor(Bonus.get(player, "inventory"))
end

function Units.isFull(player: Player): boolean
	return Units.count(player) >= Units.max(player)
end

-- $/s de la unidad colocada en una base, sin los multiplicadores del jugador.
function Units.income(unit: Unit): number
	local def = defs[unit.kind]
	return if def then UnitMath.income(def, unit, mutations, sizes) else 0
end

function Units.value(unit: Unit): number
	local def = defs[unit.kind]
	return if def then UnitMath.value(def, unit, mutations, sizes) else 0
end

function Units.power(unit: Unit): number
	local def = defs[unit.kind]
	return if def then UnitMath.power(def, unit, mutations, sizes) else 0
end

function Units.name(unit: { kind: string, variant: string?, size: string? }): string
	local def = defs[unit.kind]
	return if def then UnitMath.name(def, unit) else unit.kind
end

-- Lugar de su rareza (1 = la más común).
function Units.rank(unit: { kind: string }): number
	local def = defs[unit.kind]
	return UnitMath.rank(rarities, if def then def.rarity else nil)
end

function Units.tier(kind: string): RarityConfig.Tier?
	local def = defs[kind]
	return if def then tiers[def.rarity] else nil
end

-- Mutación y tamaño al azar con la suerte del jugador (lo que la receta usa).
function Units.rollVariants(player: Player): (string?, string?)
	local cfg = config
	if not cfg then
		return nil, nil
	end
	local luck = BoostService.multiplier(player, "Luck")
	local variant = if cfg.mutations then UnitMath.rollVariant(mutations, luck, random) else nil
	local size = if cfg.sizes then UnitMath.rollVariant(sizes, luck, random) else nil
	return variant, size
end

local function announce(player: Player, def: KitTypes.UnitDef, unit: Unit)
	local cfg = config
	local from = if cfg then cfg.announceFrom else nil
	if not from then
		return
	end
	local mutation = 1
	for _, v in mutations do
		if v.id == unit.variant then
			mutation = v.mult
		end
	end
	if UnitMath.rank(rarities, def.rarity) < UnitMath.rank(rarities, from) and mutation < ANNOUNCE_MULT then
		return
	end
	local tier = tiers[def.rarity]
	local phrase = string.upper(def.rarity) .. " " .. UnitMath.name(def, unit)
	local announcement: AnnounceService.Announcement = {
		text = string.format(UiText.UNIT_ANNOUNCE, player.DisplayName, UnitMath.article(phrase), phrase),
		color = if tier then tier.color else nil,
		rainbow = if tier then tier.rainbow else nil,
		sound = "Legendary",
	}
	if tier and tier.global then
		AnnounceService.global(announcement)
	else
		AnnounceService.server(announcement)
	end
end

-- Agrega una unidad. Devuelve la unidad (o nil y el motivo: "LOADING", "UNKNOWN", "FULL") y si es
-- nueva en el índice (para el "NEW!" del popup).
function Units.add(player: Player, kind: string, opts: AddOptions): (Unit?, string?, boolean)
	local d = data(player)
	if not d then
		return nil, "LOADING", false
	end
	local def = defs[kind]
	if not def then
		return nil, "UNKNOWN", false
	end
	if not opts.force and #d.list >= Units.max(player) then
		return nil, "FULL", false
	end
	local variant, size, weight = normal(opts.variant), normal(opts.size), opts.weight
	if opts.roll then
		local rolledVariant, rolledSize = Units.rollVariants(player)
		variant = variant or rolledVariant
		size = size or rolledSize
		weight = weight or UnitMath.rollWeight(def, random)
	end
	local unit: Unit = { uid = d.nextId, kind = kind, variant = variant, size = size, weight = weight }
	d.nextId += 1
	table.insert(d.list, unit)
	local isNew = IndexService.discover(player, UnitMath.key(kind, variant))
	Signals.track(player, "UnitGot", 1)
	if UnitMath.rank(rarities, def.rarity) >= UnitMath.rank(rarities, RARE) then
		Signals.track(player, "RareFound", 1)
	end
	if not opts.quiet then
		announce(player, def, unit)
	end
	added:Fire(player, unit, opts.source)
	Signals.dirty(player)
	return unit, nil, isNew
end

-- Saca una unidad del inventario (vendida, fusionada, robada...). Devuelve la que sacó.
function Units.remove(player: Player, uid: number, reason: string): Unit?
	local d = data(player)
	if not d then
		return nil
	end
	for i, unit in d.list do
		if unit.uid == uid then
			table.remove(d.list, i)
			removed:Fire(player, unit, reason)
			Signals.dirty(player)
			return unit
		end
	end
	return nil
end

-- Pasa una unidad de un jugador a otro con su mutación, tamaño y peso (robos). nil si el que recibe
-- no tiene lugar o la unidad ya no está.
function Units.transfer(from: Player, to: Player, uid: number, source: string): Unit?
	local unit = Units.find(from, uid)
	if not unit or Units.isFull(to) or data(to) == nil then
		return nil
	end
	Units.remove(from, uid, source)
	local copy = Units.add(to, unit.kind, { source = source, variant = unit.variant, size = unit.size, weight = unit.weight, force = true })
	return copy
end

local function touch(player: Player, unit: Unit)
	changed:Fire(player, unit)
	Signals.dirty(player)
end

-- Coloca la unidad en un espacio de su base (nil = vuelve al inventario).
function Units.place(player: Player, unit: Unit, slot: number?)
	if unit.slot ~= slot then
		unit.slot = slot
		touch(player, unit)
	end
end

function Units.equip(player: Player, unit: Unit, on: boolean)
	local value = if on then true else nil
	if unit.equipped ~= value then
		unit.equipped = value
		touch(player, unit)
	end
end

function Units.lock(player: Player, unit: Unit, on: boolean)
	local value = if on then true else nil
	if unit.locked ~= value then
		unit.locked = value
		touch(player, unit)
	end
end

-- Premio "Unit:Dragon[:Gold[:Huge]]": se entrega aunque el inventario esté lleno (puede venir de una
-- compra con Robux).
local function give(player: Player, value: string, count: number): (boolean, Types.RewardLine?)
	local parts = string.split(value, ":")
	local def = defs[parts[1]]
	if not def then
		return false, nil
	end
	local amount = math.clamp(count, 1, MAX_REWARD_COUNT)
	local given: Unit? = nil
	for _ = 1, amount do
		local unit = Units.add(player, def.id, { source = "Reward", variant = parts[2], size = parts[3], force = true })
		given = unit or given
	end
	if not given then
		return false, nil
	end
	local tier = tiers[def.rarity]
	local name = UnitMath.name(def, given)
	return true, {
		icon = def.icon or "gift",
		text = if amount > 1 then amount .. "x " .. name else name,
		kind = "unit",
		color = if tier then tier.color else nil,
	}
end

function Units.init(recipe: KitTypes.KitConfig)
	local cfg = recipe.units
	if not cfg then
		return
	end
	config = cfg
	for _, def in cfg.list do
		defs[def.id] = def
	end
	DataService.registerKit("units", { list = {}, nextId = 1, orphans = {} })
end

function Units.start(_recipe: KitTypes.KitConfig)
	local cfg = config
	if not cfg then
		return
	end
	-- Índice: cada unidad en cada mutación (pestañas de la ventana); las zonas premian las normales.
	local variants = if cfg.mutations then #mutations else 1
	IndexService.setTotal(#cfg.list * variants)
	local zones = cfg.zones
	if zones then
		local list: { IndexService.Zone } = {}
		for _, zone in zones do
			local keys = {}
			for _, def in cfg.list do
				if def.zone == zone.id then
					table.insert(keys, UnitMath.key(def.id, nil))
				end
			end
			table.insert(list, { id = zone.id, name = zone.name, keys = keys, reward = zone.reward, image = zone.image })
		end
		IndexService.setZones(list)
	end
	Remotes.onEvent("LockUnit", {
		args = { Validate.number({ integer = true, min = 1 }), Validate.boolean() },
		rate = { count = 10, perSeconds = 1 },
	}, function(player: Player, uid: number, on: boolean)
		local unit = Units.find(player, uid)
		if unit then
			Units.lock(player, unit, on)
		end
	end)
	-- Al cargar: las unidades que la receta ya no tiene se apartan (no se borran: si vuelven, se
	-- pueden recuperar) y el contador queda por encima de todo uid.
	DataService.StateChanged:Connect(function(player: Player, state: string)
		local d = data(player)
		if state ~= "loaded" or not d then
			return
		end
		local kept: { Unit } = {}
		local highest = 0
		for _, unit in d.list do
			highest = math.max(highest, unit.uid)
			if defs[unit.kind] then
				table.insert(kept, unit)
			else
				table.insert(d.orphans, unit)
				warn(string.format("[Units] %s tenía '%s', que no está en la receta: se aparta", player.Name, unit.kind))
			end
		end
		d.list = kept
		d.nextId = math.max(d.nextId, highest + 1)
	end)
	Bonus.Changed:Connect(function(player: Player, effect: string)
		if effect == "inventory" then
			Signals.dirty(player)
		end
	end)
end

function Units.snapshot(player: Player): KitTypes.UnitsState?
	local d = data(player)
	if not d then
		return nil
	end
	return { list = d.list, max = Units.max(player) }
end

Units.items = { Unit = give }

return Units
