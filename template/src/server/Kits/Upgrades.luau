--!strict
-- Bloque Upgrades del armador: mejoras por niveles con escalera de precios (`prices` o base × growth^n).
-- Cada una mejora:
-- - "stat:<Stat>": el multiplicador de BoostService ("add": +per por nivel; "mult": ×per por nivel),
--   como "+25% Money" o la escalera de multiplicadores de Chicken Farm;
-- - o un efecto de otro bloque por Bonus (Lib/KitCheck.EFFECTS): "slots", "equip", "inventory", "bag",
--   "power", "tiles", "grow", "walkSpeed", "reel", "capture" (per por nivel).
-- BuyUpgrade(id) cobra en `currency` (o la principal); las `robux` suben solo con productos
-- "Upgrade:<id>". Las estaciones KitUpgradeStation llevan cartel; la ventana es del cliente.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Ladder = require(ReplicatedStorage.Shared.Lib.Ladder)
local Multipliers = require(ReplicatedStorage.Shared.Lib.Multipliers)
local Types = require(ReplicatedStorage.Shared.Types)
local BoostService = require("../Boosts/BoostService")
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local Signals = require("../Signals")
local Bonus = require("./Bonus")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")

type UpgradesData = { levels: { [string]: number } }

local Upgrades = {}

local list: { KitTypes.UpgradeDef } = {}
local byId: { [string]: KitTypes.UpgradeDef } = {}

local function data(player: Player): UpgradesData?
	local d = DataService.get(player)
	return if d then d.kits.upgrades :: UpgradesData else nil
end

function Upgrades.level(player: Player, id: string): number
	local d = data(player)
	return if d then d.levels[id] or 0 else 0
end

-- Precio del próximo nivel (nil = al máximo o solo por Robux).
function Upgrades.nextPrice(player: Player, id: string): number?
	local def = byId[id]
	if not def or def.robux then
		return nil
	end
	local level = Upgrades.level(player, id)
	if level >= def.maxLevel then
		return nil
	end
	return Ladder.price(level + 1, def.prices, def.base, def.growth)
end

local function statOf(def: KitTypes.UpgradeDef): string?
	return string.match(def.effect, "^stat:([%w_]+)$")
end

local function changed(player: Player, def: KitTypes.UpgradeDef)
	if statOf(def) then
		BoostService.refresh(player)
	else
		Bonus.notify(player, def.effect)
	end
	Signals.dirty(player)
end

local function raise(player: Player, def: KitTypes.UpgradeDef, levels: number): number
	local d = data(player)
	if not d then
		return 0
	end
	local before = d.levels[def.id] or 0
	local after = math.min(def.maxLevel, before + levels)
	d.levels[def.id] = after
	if after > before then
		Signals.track(player, "Upgrade", after - before)
		KitFx.send(player, "Upgraded", { id = def.id, level = after })
		changed(player, def)
	end
	return after - before
end

function Upgrades.buy(player: Player, id: string): (boolean, string?)
	local def = byId[id]
	if not def or not data(player) then
		return false, "UNKNOWN"
	end
	if def.robux then
		return false, "ROBUX"
	end
	local price = Upgrades.nextPrice(player, id)
	if not price then
		return false, "MAX"
	end
	if not CurrencyService.spend(player, price, Enum.AnalyticsEconomyTransactionType.Shop, "Upgrade_" .. id, def.currency) then
		return false, "NOT_ENOUGH"
	end
	raise(player, def, 1)
	return true
end

-- Premio "Upgrade:<id>": `count` niveles (los productos por Robux de la escalera).
local function give(player: Player, value: string, count: number): (boolean, Types.RewardLine?)
	local def = byId[value]
	if not def or not data(player) then
		return false, nil
	end
	raise(player, def, count)
	return true, { icon = def.icon or "boost", text = string.format(UiText.UPGRADE_LEVEL, def.name, Upgrades.level(player, value)), kind = "item" }
end

function Upgrades.init(recipe: KitTypes.KitConfig)
	local defs = recipe.upgrades
	if not defs then
		return
	end
	list = defs
	for _, def in defs do
		byId[def.id] = def
	end
	DataService.registerKit("upgrades", { levels = {} })
	-- Efectos de otros bloques: suma per × nivel de las mejoras con ese efecto.
	Bonus.register(function(player: Player, effect: string): number
		local total = 0
		for _, def in list do
			if def.effect == effect then
				total += def.per * Upgrades.level(player, def.id)
			end
		end
		return total
	end)
end

function Upgrades.start(_recipe: KitTypes.KitConfig)
	if #list == 0 then
		return
	end
	local stats: { string } = {}
	for _, def in list do
		local stat = statOf(def)
		if stat and not table.find(stats, stat) then
			table.insert(stats, stat)
		end
	end
	if #stats > 0 then
		BoostService.registerProvider(stats, function(player: Player): { Multipliers.Source }
			local sources: { Multipliers.Source } = {}
			for _, def in list do
				local stat = statOf(def)
				local level = Upgrades.level(player, def.id)
				if stat and level > 0 then
					if def.kind == "mult" then
						table.insert(sources, { stat = stat, kind = "mult", value = def.per ^ level, label = def.name })
					else
						table.insert(sources, { stat = stat, kind = "add", value = def.per * level, label = def.name })
					end
				end
			end
			return sources
		end)
	end
	local ids = {}
	for id in byId do
		table.insert(ids, id)
	end
	Remotes.onInvoke("BuyUpgrade", { args = { Validate.oneOf(ids) }, rate = { count = 6, perSeconds = 1 } }, Upgrades.buy)
	KitWorld.tagged(Tags.UPGRADE_STATION, function(instance: Instance)
		KitWorld.sign(instance, UiText.UPGRADES_SIGN, "Orange", "boost", 11)
	end)
	DataService.StateChanged:Connect(function(player: Player, state: string)
		if state ~= "loading" then
			BoostService.refresh(player)
			for _, def in list do
				if not statOf(def) then
					Bonus.notify(player, def.effect)
				end
			end
		end
	end)
end

function Upgrades.snapshot(player: Player): KitTypes.UpgradesState?
	local d = data(player)
	return if d then { levels = d.levels } else nil
end

Upgrades.items = { Upgrade = give }

return Upgrades
