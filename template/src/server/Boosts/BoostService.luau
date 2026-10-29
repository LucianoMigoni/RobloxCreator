--!strict
-- Multiplicadores de cada jugador, como en los hits: pases, suscripción del juego, amigos en el
-- servidor, grupo, suscripción de Roblox, impulsos con tiempo (propios y de servidor), eventos con
-- horario, renacer y lo que agreguen los kits. Se combinan con Lib/Multipliers: (1 + Σ add) × Π mult.
-- Cada total queda en el atributo "Mult_<stat>" del jugador: el HUD y los kits lo leen sin pedirlo.
-- Los impulsos propios se pausan sin conexión (en los datos queda el tiempo que les falta).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BoostConfig = require(ReplicatedStorage.Shared.Config.BoostConfig)
local EventConfig = require(ReplicatedStorage.Shared.Config.EventConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local Multipliers = require(ReplicatedStorage.Shared.Lib.Multipliers)
local Progression = require(ReplicatedStorage.Shared.Lib.Progression)
local Schedule = require(ReplicatedStorage.Shared.Lib.Schedule)
local DataService = require("../Data/DataService")
local Signals = require("../Signals")

type Source = Multipliers.Source
export type Active = { id: string, label: string, icon: string, endsAt: number, server: boolean }
type Provider = (Player) -> { Source }

local BoostService = {}

local TICK_SECONDS = 1

-- Estadísticas con atributo "Mult_<stat>": las de la configuración más las que registren los kits.
local stats: { [string]: boolean } = { Money = true }
for _, def in BoostConfig.TIMED do
	stats[def.stat] = true
end
for _, def in BoostConfig.SERVER do
	stats[def.stat] = true
end
for _, pass in ShopConfig.PASSES do
	for _, effect in pass.effects do
		stats[effect.stat] = true
	end
end
for _, event in EventConfig.EVENTS do
	for stat in event.effects do
		stats[stat] = true
	end
end

local providers: { Provider } = {}
local active: { [Player]: { [string]: number } } = {} -- impulso propio → os.time() en que termina
local serverActive: { [string]: number } = {} -- impulso de servidor → os.time() en que termina
local friendCount: { [Player]: number } = {}
local inGroup: { [Player]: boolean } = {}

local function eventSources(now: number): { Source }
	local out: { Source } = {}
	for _, window in Schedule.active(EventConfig.EVENTS, now) do
		for stat, value in window.event.effects do
			table.insert(out, { stat = stat, kind = "mult", value = value, label = window.event.title })
		end
	end
	return out
end

function BoostService.sources(player: Player): { Source }
	local now = os.time()
	local out: { Source } = {}
	for _, pass in ShopConfig.PASSES do
		if player:GetAttribute(pass.attribute) == true then
			for _, effect in pass.effects do
				table.insert(out, { stat = effect.stat, kind = effect.kind, value = effect.value, label = pass.name })
			end
		end
	end
	for _, sub in ShopConfig.SUBSCRIPTIONS do
		if player:GetAttribute(sub.attribute) == true then
			for _, effect in sub.effects do
				table.insert(out, { stat = effect.stat, kind = effect.kind, value = effect.value, label = sub.name })
			end
		end
	end
	local friends = friendCount[player] or 0
	if friends > 0 then
		local f = BoostConfig.FRIENDS
		table.insert(out, { stat = f.stat, kind = "add", value = math.min(f.max, friends * f.perFriend), label = f.label })
	end
	if inGroup[player] then
		local g = BoostConfig.GROUP
		table.insert(out, { stat = g.stat, kind = "add", value = g.value, label = g.label })
	end
	if player.HasRobloxSubscription then
		local s = BoostConfig.SUBSCRIPTION
		table.insert(out, { stat = s.stat, kind = "add", value = s.value, label = s.label })
	end
	for id, endsAt in active[player] or ({} :: { [string]: number }) do
		local def = BoostConfig.TIMED[id]
		if def and endsAt > now then
			table.insert(out, { stat = def.stat, kind = "mult", value = def.value, label = def.label })
		end
	end
	for id, endsAt in serverActive do
		local def = BoostConfig.SERVER[id]
		if def and endsAt > now then
			table.insert(out, { stat = def.stat, kind = "mult", value = def.value, label = def.label })
		end
	end
	for _, source in eventSources(now) do
		table.insert(out, source)
	end
	local data = DataService.get(player)
	if data and data.rebirths > 0 then
		table.insert(out, {
			stat = "Money",
			kind = "mult",
			value = Progression.rebirthMultiplier(RetentionConfig.REBIRTH.perRebirth, data.rebirths),
			label = "Rebirth",
		})
	end
	for _, provider in providers do
		local ok, result = pcall(provider, player)
		if ok then
			for _, source in result do
				table.insert(out, source)
			end
		else
			warn("[BoostService] error en un proveedor de multiplicadores: " .. tostring(result))
		end
	end
	return out
end

function BoostService.multiplier(player: Player, stat: string): number
	return Multipliers.total(BoostService.sources(player), stat)
end

-- Impulsos con tiempo que tiene el jugador ahora (propios y del servidor), para el HUD.
function BoostService.active(player: Player): { Active }
	local now = os.time()
	local out: { Active } = {}
	for id, endsAt in active[player] or ({} :: { [string]: number }) do
		local def = BoostConfig.TIMED[id]
		if def and endsAt > now then
			table.insert(out, { id = id, label = def.label, icon = def.icon, endsAt = endsAt, server = false })
		end
	end
	for id, endsAt in serverActive do
		local def = BoostConfig.SERVER[id]
		if def and endsAt > now then
			table.insert(out, { id = id, label = def.label, icon = def.icon, endsAt = endsAt, server = true })
		end
	end
	table.sort(out, function(a, b)
		return a.endsAt < b.endsAt
	end)
	return out
end

local function publish(player: Player)
	local sources = BoostService.sources(player)
	for stat in stats do
		player:SetAttribute("Mult_" .. stat, Multipliers.total(sources, stat))
	end
end

-- Suma tiempo a un impulso propio (BoostConfig.TIMED). Si ya estaba activo, se acumula.
function BoostService.grant(player: Player, id: string, seconds: number): boolean
	local data = DataService.get(player)
	if not data or BoostConfig.TIMED[id] == nil or seconds <= 0 then
		return false
	end
	local now = os.time()
	local mine = active[player] or {}
	active[player] = mine
	mine[id] = math.max(now, mine[id] or 0) + seconds
	data.boosts[id] = mine[id] - now
	publish(player)
	Signals.dirty(player)
	return true
end

-- Suma tiempo a un impulso de todo el servidor (BoostConfig.SERVER).
function BoostService.grantServer(id: string, seconds: number): boolean
	if BoostConfig.SERVER[id] == nil or seconds <= 0 then
		return false
	end
	local now = os.time()
	serverActive[id] = math.max(now, serverActive[id] or 0) + seconds
	for _, player in Players:GetPlayers() do
		publish(player)
		Signals.dirty(player)
	end
	return true
end

-- Un kit suma sus fuentes (mascotas equipadas, mejoras): `provider` devuelve Lib/Multipliers.Source.
function BoostService.registerProvider(newStats: { string }, provider: Provider)
	for _, stat in newStats do
		stats[stat] = true
	end
	table.insert(providers, provider)
end

-- Recalcula los atributos ya (después de comprar un pase o renacer).
function BoostService.refresh(player: Player)
	publish(player)
	Signals.dirty(player)
end

local function countFriends(player: Player)
	local count = 0
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local ok, isFriend = pcall(player.IsFriendsWithAsync, player, other.UserId)
			if ok and isFriend then
				count += 1
			end
		end
	end
	friendCount[player] = count
	publish(player)
	Signals.dirty(player)
end

local function onDataLoaded(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	-- El tiempo guardado vuelve a correr desde ahora (pausado mientras no jugaba).
	local now = os.time()
	local mine = {}
	for id, remaining in data.boosts do
		if BoostConfig.TIMED[id] and remaining > 0 then
			mine[id] = now + remaining
		else
			data.boosts[id] = nil
		end
	end
	active[player] = mine
	if GameConfig.GROUP_ID ~= 0 then
		local ok, member = pcall(player.IsInGroupAsync, player, GameConfig.GROUP_ID)
		inGroup[player] = ok and member == true
	end
	publish(player)
	Signals.dirty(player)
end

local function tick()
	local now = os.time()
	for player, mine in active do
		local data = DataService.get(player)
		local expired = false
		for id, endsAt in mine do
			local remaining = endsAt - now
			if remaining <= 0 then
				mine[id] = nil
				expired = true
				if data then
					data.boosts[id] = nil
				end
			elseif data then
				data.boosts[id] = remaining
			end
		end
		if expired then
			Signals.dirty(player)
		end
	end
	for id, endsAt in serverActive do
		if endsAt <= now then
			serverActive[id] = nil
			for _, player in Players:GetPlayers() do
				Signals.dirty(player)
			end
		end
	end
	for _, player in Players:GetPlayers() do
		publish(player)
	end
end

function BoostService.start()
	DataService.StateChanged:Connect(function(player: Player, state: string)
		if state ~= "loading" then
			onDataLoaded(player)
		end
	end)
	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(countFriends, player)
		-- Los demás suman un amigo si el que entró lo es.
		for _, other in Players:GetPlayers() do
			if other ~= player then
				task.spawn(countFriends, other)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		active[player] = nil
		friendCount[player] = nil
		inGroup[player] = nil
		-- Al disparar PlayerRemoving el jugador sigue en la lista: se recuenta un momento después.
		task.delay(1, function()
			for _, other in Players:GetPlayers() do
				task.spawn(countFriends, other)
			end
		end)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(countFriends, player)
	end
	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)
			tick()
		end
	end)
end

return BoostService
