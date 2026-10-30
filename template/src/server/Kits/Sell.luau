--!strict
-- Bloque Sell del armador: vender unidades por su valor (peces en Fish It, cultivos, mascotas
-- repetidas). Desde el inventario con los uid elegidos (SellUnits), "vender todo" (SellAll: ni
-- cuidadas, ni equipadas, ni colocadas, y por debajo de `keepFrom`) o pisando el puesto KitSellPad.
-- Paga valor × sell.multiplier × el multiplicador de BoostService de sell.stat (Money si falta).
-- Con `anywherePass` (y puestos en el mapa) se vende desde la UI solo cerca de un puesto o con el pase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local UnitPick = require(ReplicatedStorage.Shared.Lib.UnitPick)
local BoostService = require("../Boosts/BoostService")
local CurrencyService = require("../Economy/CurrencyService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local ShopService = require("../Shop/ShopService")
local Signals = require("../Signals")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")
local Units = require("./Units")

local Sell = {}

local MAX_BATCH = 200
local PAD_RANGE = 25

local config: KitTypes.SellConfig? = nil
local keepRank = 0

-- Lo que paga esa unidad ahora (con los multiplicadores del jugador).
function Sell.value(player: Player, unit: Units.Unit): number
	local cfg = config
	if not cfg then
		return 0
	end
	return Units.value(unit) * (cfg.multiplier or 1) * BoostService.multiplier(player, cfg.stat or "Money")
end

-- ¿Puede vender desde la UI? Sin pase configurado o sin puestos en el mapa, siempre.
function Sell.anywhere(player: Player): boolean
	local cfg = config
	local pass = if cfg then cfg.anywherePass else nil
	if pass == nil or #CollectionService:GetTagged(Tags.SELL_PAD) == 0 then
		return true
	end
	return ShopService.ownsPass(player, pass)
end

local function nearPad(player: Player): boolean
	for _, pad in CollectionService:GetTagged(Tags.SELL_PAD) do
		if KitWorld.near(player, pad, PAD_RANGE) then
			return true
		end
	end
	return false
end

-- Vende las unidades pedidas que se pueden vender. Devuelve cuántas y cuánto pagó.
function Sell.units(player: Player, uids: { number }): (number, number)
	local cfg = config
	if not cfg then
		return 0, 0
	end
	local mult = (cfg.multiplier or 1) * BoostService.multiplier(player, cfg.stat or "Money")
	local total, count = 0, 0
	for _, uid in uids do
		local unit = Units.find(player, uid)
		if unit and not unit.locked and not unit.equipped then
			local value = Units.value(unit) * mult
			if value > 0 and Units.remove(player, uid, "Sell") then
				total += value
				count += 1
			end
		end
	end
	if count == 0 then
		return 0, 0
	end
	local currency = cfg.currency or EconomyConfig.MAIN
	CurrencyService.add(player, total, Enum.AnalyticsEconomyTransactionType.Gameplay, "Sell", currency)
	Signals.track(player, "Sell", count)
	KitFx.send(player, "Sold", { count = count, amount = math.floor(total), currency = currency })
	return count, math.floor(total)
end

function Sell.all(player: Player): (number, number)
	return Sell.units(player, UnitPick.sellAll(Units.list(player), Units.rank, keepRank))
end

local function allowed(player: Player): boolean
	return Sell.anywhere(player) or nearPad(player)
end

function Sell.init(recipe: KitTypes.KitConfig)
	local cfg = recipe.sell
	if not cfg then
		return
	end
	config = cfg
	local rarities = Units.rarities()
	keepRank = if cfg.keepFrom then (table.find(rarities, cfg.keepFrom) or 0) else 0
end

function Sell.start(_recipe: KitTypes.KitConfig)
	if not config then
		return
	end
	KitWorld.tagged(Tags.SELL_PAD, function(instance: Instance)
		local part = KitWorld.part(instance)
		if part then
			KitWorld.sign(instance, UiText.PROMPT_SELL, "Accept", "cash", 10)
			KitWorld.onTouch(part, function(player: Player)
				Sell.all(player)
			end, 1.5)
		end
	end)
	Remotes.onInvoke("SellUnits", {
		args = { Validate.array(Validate.number({ integer = true, min = 1 }), MAX_BATCH) },
		rate = { count = 4, perSeconds = 1 },
	}, function(player: Player, uids: { number }): (boolean, number?)
		if not allowed(player) then
			return false, nil
		end
		local count, amount = Sell.units(player, uids)
		return count > 0, amount
	end)
	Remotes.onInvoke("SellAll", { args = {}, rate = { count = 2, perSeconds = 1 } }, function(player: Player): (boolean, number?)
		if not allowed(player) then
			return false, nil
		end
		local count, amount = Sell.all(player)
		return count > 0, amount
	end)
end

function Sell.snapshot(player: Player): KitTypes.SellState
	return { anywhere = Sell.anywhere(player) }
end

return Sell
