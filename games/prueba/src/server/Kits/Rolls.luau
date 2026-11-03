--!strict
-- Bloque Rolls del armador: huevos, dados, cofres y puestos de compra (Pet Simulator 99, Chicken Farm
-- "Buy 1/5/25/100"). RequestRoll(id, cantidad, auto) cobra o usa la tirada gratis, sortea con la
-- suerte del jugador y entrega con Units.add; el cliente recibe lo que salió para la animación
-- (KitFx "Rolled"). Lo que se paga con una moneda que se compra con Robux es aleatorio pago
-- (`paidRandom`): se rechaza a quien PolicyService se lo prohíbe y el cliente muestra las
-- probabilidades. Si en el mapa hay KitRollStation con ese `Roll`, hay que estar cerca de una.
-- Premio "Roll:<id>" = tiradas gratis de esa (puede venir de Robux: se entrega aunque no haya lugar).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Rarity = require(ReplicatedStorage.Shared.Lib.Rarity)
local RollRules = require(ReplicatedStorage.Shared.Lib.RollRules)
local PaidRandom = require(ReplicatedStorage.Shared.Lib.PaidRandom)
local UnitMath = require(ReplicatedStorage.Shared.Lib.UnitMath)
local Types = require(ReplicatedStorage.Shared.Types)
local BoostService = require("../Boosts/BoostService")
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local ShopService = require("../Shop/ShopService")
local Signals = require("../Signals")
local Gates = require("./Gates")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")
local Units = require("./Units")

type RollsData = { nextFree: { [string]: number } }

local Rolls = {}

local MAX_COUNT = 100
local STATION_RANGE = 20

local config: KitTypes.RollsConfig? = nil
local unitsConfig: KitTypes.UnitsConfig? = nil
local byId: { [string]: KitTypes.RollDef } = {}
local rng = Random.new()

local function data(player: Player): RollsData?
	local d = DataService.get(player)
	return if d then d.kits.rolls :: RollsData else nil
end

local function random(): number
	return rng:NextNumber()
end

local function nearStation(player: Player, id: string): boolean
	local any = false
	for _, station in CollectionService:GetTagged(Tags.ROLL_STATION) do
		if KitWorld.text(station, "Roll") == id then
			any = true
			if KitWorld.near(player, station, STATION_RANGE) then
				return true
			end
		end
	end
	return not any
end

-- Hace `count` tiradas de `def` y entrega lo que sale (no cobra). `force` = aunque no haya lugar.
function Rolls.draw(player: Player, def: KitTypes.RollDef, count: number, force: boolean): { KitTypes.RollResult }
	local cfg = config
	local units = unitsConfig
	local results: { KitTypes.RollResult } = {}
	if not cfg then
		return results
	end
	local entries = UnitMath.entries(def.pool, Units.defs(), Units.rarities(), if units then units.luckyFrom else nil)
	if #entries == 0 then
		return results
	end
	local luck = BoostService.multiplier(player, cfg.luckStat or "Luck")
	for _ = 1, count do
		local picked = Rarity.roll(entries, luck, random)
		local unit, _, isNew = Units.add(player, picked.id, { source = "Roll", roll = true, force = force })
		if unit then
			table.insert(results, { uid = unit.uid, kind = unit.kind, variant = unit.variant, size = unit.size, isNew = isNew })
		end
	end
	if #results > 0 then
		Signals.track(player, "Roll", #results)
		if def.look == nil or def.look == "egg" then
			Signals.track(player, "Hatch", #results)
		end
		KitFx.send(player, "Rolled", { roll = def.id, results = results })
	end
	return results
end

local function request(player: Player, id: string, count: number, auto: boolean?): (boolean, any)
	local cfg = config
	local def = byId[id]
	local d = data(player)
	if not cfg or not def then
		return false, "UNKNOWN"
	end
	if not d then
		return false, "LOADING"
	end
	local function owns(pass: string): boolean
		return ShopService.ownsPass(player, pass)
	end
	if not RollRules.amount(def, count, owns) then
		return false, "AMOUNT"
	end
	local autoPass = cfg.autoPass
	if auto and autoPass and not owns(autoPass) then
		return false, "AUTO"
	end
	if PaidRandom.roll(def, EconomyConfig.isPurchasable) and Units.restricted(player) then
		return false, "RESTRICTED"
	end
	if not Gates.open(player, def.zone) then
		return false, "ZONE"
	end
	if not nearStation(player, id) then
		return false, "FAR"
	end
	if Units.count(player) + count > Units.max(player) then
		return false, "FULL"
	end
	local price = def.price
	local cost = RollRules.cost(def, count)
	if price and cost then
		if not CurrencyService.spend(player, cost, Enum.AnalyticsEconomyTransactionType.Shop, "Roll_" .. id, price.currency) then
			return false, "NOT_ENOUGH"
		end
	else
		local now = os.time()
		if not RollRules.freeReady(d.nextFree[id], now) then
			return false, "COOLDOWN"
		end
		d.nextFree[id] = now + (def.cooldown or 0)
	end
	return true, Rolls.draw(player, def, count, false)
end

-- Premio "Roll:<id>": `count` tiradas gratis de esa.
local function give(player: Player, value: string, count: number): (boolean, Types.RewardLine?)
	local def = byId[value]
	if not def then
		return false, nil
	end
	local amount = math.clamp(count, 1, MAX_COUNT)
	local results = Rolls.draw(player, def, amount, true)
	if #results == 0 then
		return false, nil
	end
	return true, { icon = def.look or "egg", text = (if amount > 1 then amount .. "x " else "") .. def.name, kind = "item" }
end

function Rolls.init(recipe: KitTypes.KitConfig)
	local cfg = recipe.rolls
	if not cfg then
		return
	end
	config = cfg
	unitsConfig = recipe.units
	for _, def in cfg.list do
		byId[def.id] = def
	end
	DataService.registerKit("rolls", { nextFree = {} })
end

function Rolls.start(_recipe: KitTypes.KitConfig)
	local cfg = config
	if not cfg then
		return
	end
	local ids = {}
	for _, def in cfg.list do
		table.insert(ids, def.id)
	end
	Remotes.onInvoke("RequestRoll", {
		args = { Validate.oneOf(ids), Validate.number({ integer = true, min = 1, max = MAX_COUNT }), Validate.optional(Validate.boolean()) },
		rate = { count = 6, perSeconds = 1 },
	}, request)
	-- Cartel sobre cada estación con el nombre de lo que se abre.
	KitWorld.tagged(Tags.ROLL_STATION, function(instance: Instance)
		local def = byId[KitWorld.text(instance, "Roll") or ""]
		if def then
			KitWorld.sign(instance, def.name, "Purple", def.look or "egg", 10)
			local prompt = KitWorld.prompt(instance, { action = UiText.PROMPT_OPEN, object = def.name, name = "RollStation" })
			if prompt then
				-- El prompt solo abre la ventana de la tirada en el cliente (con precio y probabilidades).
				prompt:SetAttribute("Roll", def.id)
			end
		end
	end)
end

function Rolls.snapshot(player: Player): KitTypes.RollsState?
	local d = data(player)
	return if d then { nextFree = d.nextFree } else nil
end

Rolls.items = { Roll = give }

return Rolls
