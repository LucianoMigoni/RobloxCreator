--!strict
-- Bloque Stats del armador: estadísticas que crecen jugando, como "+1 Speed por paso" (+1 Speed
-- Keyboard Escape), la fuerza de un simulador o los toques de un Tap Simulator. Cada una gana:
-- - por stud caminado (`perStep`), medido en el servidor con tope de velocidad: los saltos de posición
--   (teletransportes, reaparecer) no cuentan;
-- - por segundo (`perSecond`);
-- - por toque del botón de acción (`perClick`, como mucho `clickRate` por segundo; con el pase
--   `autoPass` toca solo);
-- - parado sobre una cinta KitTreadmill (atributos Stat y Gain = cuánto por segundo).
-- Todo por el multiplicador de BoostService (`multiplier` o su id). Con `currency`, lo ganado va a esa
-- moneda (toques que se gastan). Con `walkSpeed`, la estadística mueve al personaje (atributo
-- BaseWalkSpeed + KitWorld.applySpeed) y el jugador le puede poner un tope (SetStatCap). Cada valor
-- queda en un atributo del jugador con su id (tabla de jugadores, zonas, etapas). Premio
-- "Stat:<id>" = suma `count` tal cual.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Types = require(ReplicatedStorage.Shared.Types)
local BoostService = require("../Boosts/BoostService")
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local RebirthService = require("../Retention/RebirthService")
local ShopService = require("../Shop/ShopService")
local Signals = require("../Signals")
local Gates = require("./Gates")
local KitWorld = require("./KitWorld")

type StatsData = { values: { [string]: number }, caps: { [string]: number } }

local Stats = {}

local STEP_TICK = 0.25
local STEP_SLACK = 1.5 -- se acepta hasta 1.5 veces la velocidad de caminar (empujones, pendientes)
local TREADMILL_HEIGHT = 8
local MAX_CLICK_RATE = 20

local defs: { KitTypes.StatDef } = {}
local byId: { [string]: KitTypes.StatDef } = {}
local lastPosition: { [Player]: Vector3 } = {}
local taps: { [Player]: { [string]: { window: number, count: number } } } = {}

local function data(player: Player): StatsData?
	local d = DataService.get(player)
	return if d then d.kits.stats :: StatsData else nil
end

function Stats.def(id: string): KitTypes.StatDef?
	return byId[id]
end

-- Valor actual (de la moneda, si la estadística gana en una moneda).
function Stats.value(player: Player, id: string): number
	local def = byId[id]
	if not def then
		return 0
	end
	local currency = def.currency
	if currency then
		return CurrencyService.get(player, currency)
	end
	local d = data(player)
	return if d then d.values[id] or 0 else 0
end

-- Velocidad de caminar de la estadística que mueve al personaje, con el tope que eligió el jugador.
local function updateSpeed(player: Player)
	for _, def in defs do
		local walk = def.walkSpeed
		if walk then
			local d = data(player)
			local full = math.min(walk.max, walk.base + Stats.value(player, def.id) * walk.per)
			local cap = if d then d.caps[def.id] or 1 else 1
			player:SetAttribute("BaseWalkSpeed", walk.base + (full - walk.base) * math.clamp(cap, 0, 1))
			KitWorld.applySpeed(player)
			return
		end
	end
end

local function publish(player: Player, def: KitTypes.StatDef)
	if not def.currency then
		player:SetAttribute(def.id, Stats.value(player, def.id))
	end
	if def.walkSpeed then
		updateSpeed(player)
	end
end

-- Suma tal cual (sin multiplicador). Devuelve si pudo.
function Stats.add(player: Player, id: string, amount: number): boolean
	local def = byId[id]
	local d = data(player)
	if not def or not d or amount ~= amount or amount <= 0 or amount == math.huge then
		return false
	end
	local currency = def.currency
	if currency then
		if not CurrencyService.add(player, amount, Enum.AnalyticsEconomyTransactionType.Gameplay, "Stat_" .. id, currency, true) then
			return false
		end
	else
		d.values[id] = (d.values[id] or 0) + amount
	end
	Signals.track(player, id .. "Gained", amount)
	publish(player, def)
	return true
end

-- Gana jugando: `base` por el multiplicador de la estadística.
local function gain(player: Player, def: KitTypes.StatDef, base: number)
	if base > 0 then
		Stats.add(player, def.id, base * BoostService.multiplier(player, def.multiplier or def.id))
	end
end

local function tap(player: Player, id: string)
	local def = byId[id]
	local perClick = if def then def.perClick else nil
	if not def or not perClick then
		return
	end
	local now = math.floor(os.clock())
	local mine = taps[player] or {}
	taps[player] = mine
	local counter = mine[id]
	if not counter or counter.window ~= now then
		counter = { window = now, count = 0 }
		mine[id] = counter
	end
	if counter.count >= (def.clickRate or 1) then
		return
	end
	counter.count += 1
	gain(player, def, perClick)
	Signals.track(player, "Tap", 1)
end

local function onTreadmill(root: BasePart, part: BasePart): boolean
	local relative = part.CFrame:PointToObjectSpace(root.Position)
	return math.abs(relative.X) <= part.Size.X / 2
		and math.abs(relative.Z) <= part.Size.Z / 2
		and relative.Y >= 0
		and relative.Y <= part.Size.Y / 2 + TREADMILL_HEIGHT
end

local function everySecond()
	for _, player in Players:GetPlayers() do
		if data(player) then
			for _, def in defs do
				local perSecond = def.perSecond
				if perSecond then
					gain(player, def, perSecond)
				end
				local autoPass = def.autoPass
				local perClick = def.perClick
				if autoPass and perClick and ShopService.ownsPass(player, autoPass) then
					gain(player, def, perClick * (def.clickRate or 1))
				end
			end
			local root = KitWorld.root(player)
			if root then
				for _, treadmill in CollectionService:GetTagged(Tags.TREADMILL) do
					local part = KitWorld.part(treadmill)
					local def = byId[KitWorld.text(treadmill, "Stat") or ""]
					if part and def and onTreadmill(root, part) and Gates.open(player, KitWorld.inherited(treadmill, "Zone")) then
						gain(player, def, KitWorld.number(treadmill, "Gain") or 1)
					end
				end
			end
		end
	end
end

local function everyStep(stepDefs: { KitTypes.StatDef })
	for _, player in Players:GetPlayers() do
		local root = KitWorld.root(player)
		local humanoid = KitWorld.humanoid(player)
		if not root or not humanoid or not data(player) then
			lastPosition[player] = nil
			continue
		end
		local position = root.Position * Vector3.new(1, 0, 1)
		local last = lastPosition[player]
		lastPosition[player] = position
		if last then
			local studs = (position - last).Magnitude
			if studs > 0.05 and studs <= humanoid.WalkSpeed * STEP_TICK * STEP_SLACK + 1 then
				for _, def in stepDefs do
					gain(player, def, studs * (def.perStep :: number))
				end
				Signals.track(player, "Steps", studs)
			end
		end
	end
end

-- Premio "Stat:<id>": suma `count` (los productos "+10K Speed").
local function give(player: Player, value: string, count: number): (boolean, Types.RewardLine?)
	local def = byId[value]
	if not def or not Stats.add(player, value, count) then
		return false, nil
	end
	return true, { icon = def.icon or "boost", text = "+" .. Format.number(count) .. " " .. def.label, kind = "item" }
end

function Stats.init(recipe: KitTypes.KitConfig)
	local list = recipe.stats
	if not list then
		return
	end
	defs = list
	for _, def in list do
		byId[def.id] = def
	end
	DataService.registerKit("stats", { values = {}, caps = {} })
end

function Stats.start(_recipe: KitTypes.KitConfig)
	if #defs == 0 then
		return
	end
	-- Atributos "Mult_<stat>" de cada multiplicador que usan (BoostService publica los registrados).
	local multipliers = {}
	local stepDefs: { KitTypes.StatDef } = {}
	local tapIds = {}
	for _, def in defs do
		table.insert(multipliers, def.multiplier or def.id)
		if def.perStep then
			table.insert(stepDefs, def)
		end
		if def.perClick then
			table.insert(tapIds, def.id)
		end
	end
	BoostService.registerProvider(multipliers, function()
		return {}
	end)
	if #tapIds > 0 then
		Remotes.onEvent("TapStat", {
			args = { Validate.oneOf(tapIds) },
			rate = { count = MAX_CLICK_RATE, perSeconds = 1 },
		}, tap)
	end
	local walkIds = {}
	for _, def in defs do
		if def.walkSpeed then
			table.insert(walkIds, def.id)
		end
	end
	if #walkIds > 0 then
		Remotes.onEvent("SetStatCap", {
			args = { Validate.oneOf(walkIds), Validate.number({ min = 0, max = 1 }) },
			rate = { count = 5, perSeconds = 1 },
		}, function(player: Player, id: string, fraction: number)
			local d = data(player)
			if d then
				d.caps[id] = fraction
				updateSpeed(player)
				Signals.dirty(player)
			end
		end)
	end
	DataService.StateChanged:Connect(function(player: Player, state: string)
		if state ~= "loading" then
			for _, def in defs do
				publish(player, def)
			end
		end
	end)
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function()
			lastPosition[player] = nil
			task.defer(function()
				updateSpeed(player)
				KitWorld.applySpeed(player)
			end)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		lastPosition[player] = nil
		taps[player] = nil
	end)
	RebirthService.onRebirth(function(player: Player)
		local d = data(player)
		if not d then
			return
		end
		for _, def in defs do
			if def.resetOnRebirth then
				local currency = def.currency
				if currency then
					CurrencyService.set(player, currency, 0)
				else
					d.values[def.id] = 0
				end
				publish(player, def)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			everySecond()
		end
	end)
	if #stepDefs > 0 then
		task.spawn(function()
			while true do
				task.wait(STEP_TICK)
				everyStep(stepDefs)
			end
		end)
	end
end

function Stats.snapshot(player: Player): KitTypes.StatsState?
	local d = data(player)
	if not d then
		return nil
	end
	local values: { [string]: number } = {}
	for _, def in defs do
		values[def.id] = Stats.value(player, def.id)
	end
	return { values = values, caps = d.caps }
end

Stats.items = { Stat = give }

return Stats
