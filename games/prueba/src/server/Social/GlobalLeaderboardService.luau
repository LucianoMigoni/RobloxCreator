--!strict
-- Tablas de posiciones del mundo (etiqueta KitLeaderboard con atributo Stat: una moneda, "Rebirths" o
-- una estadística del armador): los mejores de todos los servidores, con OrderedDataStore. Cada
-- CYCLE_SECONDS se guarda lo de cada jugador (solo si cambió) y se leen los primeros; la lista va en
-- el atributo "Top" del modelo (JSON: { { id, name, value } }) y la dibuja
-- cada cliente (Controllers/LeaderboardController). Los valores van codificados con Lib/Ranking.
--
-- Límites verificados en creator-docs (cloud-services/data-stores/error-codes-and-limits.md,
-- 2026-11-03), por servidor y por minuto: OrderedWrite 30 + 5 × jugadores y OrderedList 5 + 2 ×
-- jugadores. Con dos tablas, guardar y leer cada 120 s gasta una escritura por jugador y una lectura
-- por minuto. Antes de escribir se mira el presupuesto (GetRequestBudgetForRequestType). Sin acceso a
-- la API (Studio sin "Enable Studio Access to API Services") muestra a los de este servidor.

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataConfig = require(ReplicatedStorage.Shared.Config.DataConfig)
local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local Ranking = require(ReplicatedStorage.Shared.Lib.Ranking)
local DataService = require("../Data/DataService")

local GlobalLeaderboardService = {}

local CYCLE_SECONDS = 120 -- guardar lo de cada uno y leer los primeros
local FIRST_REFRESH = 8 -- primera vuelta, apenas arranca el servidor
local SIZE = 10 -- filas de cada tabla

type Row = { id: number, name: string, value: number }

local boards: { [string]: { Instance } } = {} -- estadística → modelos que la muestran
local stores: { [string]: OrderedDataStore } = {}
local unavailable: { [string]: boolean } = {} -- sin acceso a la API (Studio): no se vuelve a pedir
local saved: { [Player]: { [string]: number } } = {}
local names: { [number]: string } = {}

local function valueOf(player: Player, stat: string): number?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	if EconomyConfig.CURRENCIES[stat] then
		return data.currencies[stat] or 0
	elseif stat == "Rebirths" then
		return data.rebirths
	end
	local attribute = player:GetAttribute(stat)
	return if typeof(attribute) == "number" then attribute else nil
end

local function storeFor(stat: string): OrderedDataStore?
	if unavailable[stat] then
		return nil
	end
	local cached = stores[stat]
	if cached then
		return cached
	end
	-- La versión de los datos va en el nombre: si se borran los datos (v2), las tablas empiezan de cero.
	local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, "Top_" .. stat .. "_" .. DataConfig.STORE_NAME)
	if not ok then
		unavailable[stat] = true
		return nil
	end
	stores[stat] = store
	return store
end

local function writeBudget(): number
	local ok, budget = pcall(DataStoreService.GetRequestBudgetForRequestType, DataStoreService, Enum.DataStoreRequestType.OrderedWrite)
	return if ok then budget else 1
end

local function save(player: Player, stat: string)
	local value = valueOf(player, stat)
	local store = storeFor(stat)
	if not value or not store then
		return
	end
	local encoded = Ranking.encode(value)
	local mine = saved[player]
	if not mine or mine[stat] == encoded or writeBudget() < 1 then
		return
	end
	local ok = pcall(store.SetAsync, store, tostring(player.UserId), encoded)
	if ok then
		mine[stat] = encoded
	end
end

local function nameOf(userId: number): string
	local player = Players:GetPlayerByUserId(userId)
	if player then
		return player.Name
	end
	local cached = names[userId]
	if cached then
		return cached
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	local result = if ok and typeof(name) == "string" then name else "Player"
	names[userId] = result
	return result
end

-- Los de este servidor, cuando no hay data stores.
local function localRows(stat: string): { Row }
	local rows: { Row } = {}
	for _, player in Players:GetPlayers() do
		local value = valueOf(player, stat)
		if value then
			table.insert(rows, { id = player.UserId, name = player.Name, value = value })
		end
	end
	table.sort(rows, function(a, b)
		return a.value > b.value
	end)
	while #rows > SIZE do
		table.remove(rows)
	end
	return rows
end

local function refresh(stat: string)
	local rows: { Row } = {}
	local store = storeFor(stat)
	local ok, pages = false, nil :: DataStorePages?
	if store then
		ok, pages = pcall(store.GetSortedAsync, store, false, SIZE)
	end
	if ok and pages then
		for _, entry in pages:GetCurrentPage() do
			local id = Ranking.userId(entry.key)
			if id then
				table.insert(rows, { id = id, name = nameOf(id), value = Ranking.decode(entry.value) })
			end
		end
	else
		rows = localRows(stat)
	end
	local json = HttpService:JSONEncode(rows)
	local list = boards[stat]
	if list then
		for _, board in list do
			board:SetAttribute("Top", json)
		end
	end
end

local function track(board: Instance)
	local stat = board:GetAttribute("Stat")
	if typeof(stat) ~= "string" then
		warn("[GlobalLeaderboard] " .. board:GetFullName() .. " tiene KitLeaderboard sin el atributo Stat")
		return
	end
	local list = boards[stat]
	if not list then
		list = {}
		boards[stat] = list
	end
	if not table.find(list, board) then
		table.insert(list, board)
	end
end

function GlobalLeaderboardService.start()
	-- Sin tablas en el mapa el ciclo no hace nada (no gasta pedidos); si aparecen después, se llenan.
	for _, board in CollectionService:GetTagged(Tags.LEADERBOARD) do
		track(board)
	end
	CollectionService:GetInstanceAddedSignal(Tags.LEADERBOARD):Connect(track)
	local function join(player: Player)
		saved[player] = {}
	end
	for _, player in Players:GetPlayers() do
		join(player)
	end
	Players.PlayerAdded:Connect(join)
	Players.PlayerRemoving:Connect(function(player: Player)
		for stat in boards do
			save(player, stat)
		end
		saved[player] = nil
	end)
	task.spawn(function()
		task.wait(FIRST_REFRESH)
		while true do
			for _, player in Players:GetPlayers() do
				for stat in boards do
					save(player, stat)
				end
			end
			for stat in boards do
				refresh(stat)
			end
			task.wait(CYCLE_SECONDS)
		end
	end)
end

return GlobalLeaderboardService
