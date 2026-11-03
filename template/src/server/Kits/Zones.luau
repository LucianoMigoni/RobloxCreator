--!strict
-- Bloque Zones del armador: mundos o biomas que se abren pagando (`price`), al llegar a una estadística
-- (`stat`, "Required ⚡ 3.7M") o con renacimientos (`rebirths`), en orden: cada zona pide la anterior.
-- La primera (menor `order`) está siempre abierta. Una vez abierta, queda abierta (aunque la
-- estadística baje al renacer).
-- Partes (Kits/Tags): KitGate (atributo Zone) = la puerta, con cartel y prompt "Unlock" si se compra;
-- el cliente de quien la tiene abierta la atraviesa (choque local). KitZone (Zone) = la región (una
-- caja que cubre la zona, con su cara de abajo en el piso: ahí se llega): quien entra sin tenerla
-- abierta vuelve a su base (por si el cliente mintió). KitTeleport (Zone) = pad que
-- lleva a esa zona si está abierta. Registra Gates: tiradas, pesca, búsqueda, salvajes, cintas de
-- correr y el índice preguntan por acá. Premio "Zone:<id>" = la abre.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Types = require(ReplicatedStorage.Shared.Types)
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local Signals = require("../Signals")
local Gates = require("./Gates")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")
local Plots = require("./Plots")
local Stats = require("./Stats")

type ZonesData = { unlocked: { [string]: boolean } }

local Zones = {}

local CHECK_SECONDS = 1
local ARRIVAL_HEIGHT = 4

local ordered: { KitTypes.ZoneDef } = {}
local byId: { [string]: KitTypes.ZoneDef } = {}

local function data(player: Player): ZonesData?
	local d = DataService.get(player)
	return if d then d.kits.zones :: ZonesData else nil
end

local function previous(zone: KitTypes.ZoneDef): KitTypes.ZoneDef?
	local index = table.find(ordered, zone)
	return if index and index > 1 then ordered[index - 1] else nil
end

-- ¿Cumple lo que pide la zona (sin contar el precio)?
local function meets(player: Player, zone: KitTypes.ZoneDef): boolean
	local stat = zone.stat
	if stat and Stats.value(player, stat.id) < stat.value then
		return false
	end
	local rebirths = zone.rebirths
	if rebirths then
		local d = DataService.get(player)
		if not d or d.rebirths < rebirths then
			return false
		end
	end
	return true
end

function Zones.isUnlocked(player: Player, id: string): boolean
	local zone = byId[id]
	if not zone then
		return true
	end
	if zone == ordered[1] then
		return true
	end
	local d = data(player)
	return d ~= nil and d.unlocked[id] == true
end

local function open(player: Player, zone: KitTypes.ZoneDef, source: string)
	local d = data(player)
	if not d or d.unlocked[zone.id] then
		return
	end
	d.unlocked[zone.id] = true
	Signals.track(player, "ZoneUnlocked", 1)
	KitFx.send(player, "ZoneOpened", { id = zone.id, name = zone.name, source = source })
	Signals.dirty(player)
end

-- Compra o abre la zona si cumple todo (en orden). Devuelve si quedó abierta.
function Zones.unlock(player: Player, id: string): (boolean, string?)
	local zone = byId[id]
	if not zone or not data(player) then
		return false, "UNKNOWN"
	end
	if Zones.isUnlocked(player, id) then
		return true
	end
	local before = previous(zone)
	if before and not Zones.isUnlocked(player, before.id) then
		return false, "ORDER"
	end
	if not meets(player, zone) then
		return false, "REQUIREMENT"
	end
	local price = zone.price
	if price and not CurrencyService.spend(player, price.amount, Enum.AnalyticsEconomyTransactionType.Shop, "Zone_" .. id, price.currency) then
		return false, "NOT_ENOUGH"
	end
	open(player, zone, "Unlock")
	return true
end

-- Las que no se compran (estadística, renacimientos o nada) se abren solas al llegar, en orden.
local function autoOpen(player: Player)
	for _, zone in ordered do
		if not Zones.isUnlocked(player, zone.id) then
			local before = previous(zone)
			if zone.price == nil and (not before or Zones.isUnlocked(player, before.id)) and meets(player, zone) then
				open(player, zone, "Auto")
			else
				return -- en orden: si esta no se abre, las siguientes tampoco
			end
		end
	end
end

local function requirement(zone: KitTypes.ZoneDef): string
	local price = zone.price
	if price then
		local currency = EconomyConfig.CURRENCIES[price.currency]
		return string.format(UiText.ZONE_PRICE, zone.name, Format.money(price.amount, if currency then currency.symbol else ""))
	end
	local stat = zone.stat
	if stat then
		local def = Stats.def(stat.id)
		return string.format(UiText.ZONE_NEEDS_STAT, zone.name, Format.number(stat.value), if def then def.label else stat.id)
	end
	local rebirths = zone.rebirths
	if rebirths then
		return string.format(UiText.ZONE_NEEDS_REBIRTHS, zone.name, rebirths)
	end
	return zone.name
end

-- Punto de llegada de una zona: arriba de su región KitZone.
local function arrival(id: string): CFrame?
	for _, region in CollectionService:GetTagged(Tags.ZONE) do
		local part = KitWorld.part(region)
		if part and KitWorld.text(region, "Zone") == id then
			-- Al centro de la cara de abajo de la región (el piso de la zona), un poco arriba.
			return part.CFrame * CFrame.new(0, -part.Size.Y / 2 + ARRIVAL_HEIGHT, 0)
		end
	end
	return nil
end

-- A su base (su KitSpawn) o, sin base, a la primera zona.
local function sendHome(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local plot = Plots.plotOf(player)
	if plot then
		for _, part in plot:GetDescendants() do
			if part:IsA("BasePart") and part:HasTag(Tags.SPAWN) then
				character:PivotTo(part.CFrame + Vector3.new(0, ARRIVAL_HEIGHT, 0))
				return
			end
		end
	end
	local target = arrival(if ordered[1] then ordered[1].id else "")
	if target then
		character:PivotTo(target)
	end
end

-- Quien está adentro de una región que no tiene abierta vuelve (la puerta la abre su cliente).
local function patrol()
	local regions = CollectionService:GetTagged(Tags.ZONE)
	for _, player in Players:GetPlayers() do
		local root = KitWorld.root(player)
		if root and data(player) then
			autoOpen(player)
			for _, region in regions do
				local part = KitWorld.part(region)
				local id = KitWorld.text(region, "Zone")
				if part and id and not Zones.isUnlocked(player, id) then
					local relative = part.CFrame:PointToObjectSpace(root.Position)
					if math.abs(relative.X) <= part.Size.X / 2 and math.abs(relative.Y) <= part.Size.Y / 2 and math.abs(relative.Z) <= part.Size.Z / 2 then
						sendHome(player)
						KitFx.send(player, "Error", { code = "ZONE" })
						break
					end
				end
			end
		end
	end
end

-- Premio "Zone:<id>": la abre (aunque falten las anteriores: es una compra).
local function give(player: Player, value: string, _count: number): (boolean, Types.RewardLine?)
	local zone = byId[value]
	if not zone or not data(player) then
		return false, nil
	end
	open(player, zone, "Reward")
	return true, { icon = "teleport", text = string.format(UiText.ZONE_OPENED, zone.name), kind = "item" }
end

function Zones.init(recipe: KitTypes.KitConfig)
	local cfg = recipe.zones
	if not cfg then
		return
	end
	ordered = table.clone(cfg.list)
	table.sort(ordered, function(a, b)
		return a.order < b.order
	end)
	for _, zone in ordered do
		byId[zone.id] = zone
	end
	DataService.registerKit("zones", { unlocked = {} })
	Gates.register(Zones.isUnlocked)
end

function Zones.start(_recipe: KitTypes.KitConfig)
	if #ordered == 0 then
		return
	end
	local ids = {}
	for _, zone in ordered do
		table.insert(ids, zone.id)
	end
	Remotes.onInvoke("UnlockZone", { args = { Validate.oneOf(ids) }, rate = { count = 3, perSeconds = 1 } }, Zones.unlock)
	KitWorld.tagged(Tags.GATE, function(gate: Instance)
		local zone = byId[KitWorld.text(gate, "Zone") or ""]
		if not zone then
			return
		end
		KitWorld.sign(gate, requirement(zone), if zone.price then "Premium" else "Info", if zone.price then "lock" else "teleport", 14)
		if zone.price then
			local prompt = KitWorld.prompt(gate, { action = UiText.PROMPT_UNLOCK, object = zone.name, name = "ZoneGate", distance = 14 })
			if prompt then
				KitWorld.onPrompt(prompt, function(player: Player)
					local ok, reason = Zones.unlock(player, zone.id)
					if not ok then
						KitFx.send(player, "Error", { code = reason })
					end
				end, 0.5)
			end
		end
	end)
	KitWorld.tagged(Tags.TELEPORT, function(pad: Instance)
		local part = KitWorld.part(pad)
		local id = KitWorld.text(pad, "Zone")
		if not part or not id then
			return
		end
		local zone = byId[id]
		if zone then
			KitWorld.sign(pad, zone.name, "Cyan", "teleport", 9)
		end
		KitWorld.onTouch(part, function(player: Player)
			if not Zones.isUnlocked(player, id) then
				KitFx.send(player, "Error", { code = "ZONE" })
				return
			end
			local target = arrival(id)
			local character = player.Character
			if target and character then
				character:PivotTo(target)
				Signals.track(player, "Teleport", 1)
			end
		end, 2)
	end)
	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			patrol()
		end
	end)
end

function Zones.snapshot(player: Player): KitTypes.ZonesState?
	if not data(player) then
		return nil
	end
	local unlocked: { [string]: boolean } = {}
	for _, zone in ordered do
		unlocked[zone.id] = Zones.isUnlocked(player, zone.id)
	end
	return { unlocked = unlocked }
end

Zones.items = { Zone = give }

return Zones
