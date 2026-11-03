--!strict
-- Datos persistentes de cada jugador con bloqueo de sesión, según la guía oficial "Implement player data
-- and purchasing systems" (create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing).
-- Los datos viven en memoria y se escriben con UpdateAsync: al entrar (toma el bloqueo), cada
-- AUTOSAVE_SECONDS (lo renueva), al salir y al cerrar el servidor (lo libera).
-- Si la carga falla, el jugador juega con datos por defecto marcados "errored" que nunca se guardan:
-- así un fallo de DataStore no pisa el progreso real. Las compras deben chequear canSave().

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataConfig = require(ReplicatedStorage.Shared.Config.DataConfig)
local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local Reconcile = require("./Reconcile")
local SessionLock = require("./SessionLock")

export type State = "loading" | "loaded" | "errored"
export type Data = typeof(DataConfig.DEFAULT_DATA)

type Profile = {
	data: Data,
	state: State,
	lockId: string,
	saving: boolean,
	released: boolean,
}

local DataService = {}

local profiles: { [Player]: Profile } = {}
local stateChanged = Instance.new("BindableEvent")
-- (player, state) cuando la carga termina, bien o mal.
DataService.StateChanged = stateChanged.Event

local store: DataStore? = nil
local started = false
-- Valores por defecto efectivos: DEFAULT_DATA + saldo inicial de cada moneda + datos de los kits.
local defaults: { [string]: any } = Reconcile.deepCopy(DataConfig.DEFAULT_DATA) :: any
for id, currency in EconomyConfig.CURRENCIES do
	defaults.currencies[id] = currency.start
end

local function keyFor(player: Player): string
	return DataConfig.KEY_PREFIX .. player.UserId
end

local function fail(player: Player, profile: Profile, reason: string)
	profile.state = "errored"
	warn(string.format("[DataService] %s: %s. Sus datos no se guardan en esta sesión.", player.Name, reason))
end

-- UpdateAsync con reintentos y espera exponencial. El callback puede correr más de una vez (si otro
-- servidor escribió en el medio), así que no debe tener efectos fuera de lo que devuelve.
local function update(key: string, transform: (any, DataStoreKeyInfo?) -> ...any): (boolean, string)
	local dataStore = store
	if not dataStore then
		return false, "DataStore no disponible"
	end
	local lastError = ""
	for attempt = 1, DataConfig.MAX_ATTEMPTS do
		local ok, err = pcall(function()
			dataStore:UpdateAsync(key, transform)
		end)
		if ok then
			return true, ""
		end
		lastError = tostring(err)
		if attempt < DataConfig.MAX_ATTEMPTS then
			task.wait(DataConfig.RETRY_BASE_SECONDS * 2 ^ (attempt - 1))
		end
	end
	return false, lastError
end

local function load(player: Player, profile: Profile)
	local userIds = { player.UserId }
	for _ = 1, DataConfig.LOCKED_RETRY_ATTEMPTS do
		local status: SessionLock.Status = "locked"
		local loaded: Data? = nil
		local ok, err = update(keyFor(player), function(current: any, keyInfo: DataStoreKeyInfo?)
			local metadata = if keyInfo then keyInfo:GetMetadata() else nil
			local now = os.time()
			status = SessionLock.check(metadata, profile.lockId, now, DataConfig.LOCK_EXPIRY_SECONDS, false)
			if status ~= "ok" then
				return nil
			end
			local base = if typeof(current) == "table" then Reconcile.deepCopy(current) else {}
			loaded = Reconcile.fill(base, defaults) :: Data
			return loaded, userIds, SessionLock.apply(metadata, profile.lockId, now, false)
		end)
		if not ok then
			fail(player, profile, "error de DataStore al cargar (" .. err .. ")")
			return
		end
		if status == "ok" and loaded then
			if loaded.firstPlayedAt == 0 then
				loaded.firstPlayedAt = os.time()
			end
			profile.data = loaded
			profile.state = "loaded"
			return
		end
		task.wait(DataConfig.LOCKED_RETRY_SECONDS)
	end
	fail(player, profile, "sus datos siguen bloqueados por otro servidor")
end

-- Escribe los datos en memoria; `release` libera el bloqueo. Devuelve true si quedaron guardados.
local function save(player: Player, profile: Profile, release: boolean): boolean
	while profile.saving do
		task.wait()
	end
	if profile.state ~= "loaded" or profile.released then
		return false
	end
	profile.saving = true
	local snapshot = Reconcile.deepCopy(profile.data)
	local status: SessionLock.Status = "lost"
	local ok, err = update(keyFor(player), function(_current: any, keyInfo: DataStoreKeyInfo?)
		local metadata = if keyInfo then keyInfo:GetMetadata() else nil
		local now = os.time()
		status = SessionLock.check(metadata, profile.lockId, now, DataConfig.LOCK_EXPIRY_SECONDS, true)
		if status ~= "ok" then
			return nil
		end
		return snapshot, { player.UserId }, SessionLock.apply(metadata, profile.lockId, now, release)
	end)
	profile.saving = false
	if not ok then
		warn(string.format("[DataService] no se pudo guardar a %s: %s", player.Name, err))
		return false
	end
	if status ~= "ok" then
		fail(player, profile, "otro servidor tomó su bloqueo; se deja de guardar para no pisar datos más nuevos")
		return false
	end
	if release then
		profile.released = true
	end
	return true
end

local function autosave(player: Player, profile: Profile)
	-- Desfase al azar para que los servidores no escriban todos a la vez (recomendación de la guía).
	task.wait(math.random() * DataConfig.AUTOSAVE_SECONDS)
	while profiles[player] == profile and profile.state == "loaded" and not profile.released do
		save(player, profile, false)
		task.wait(DataConfig.AUTOSAVE_SECONDS)
	end
end

local function onPlayerAdded(player: Player)
	local profile: Profile = {
		data = Reconcile.deepCopy(defaults) :: Data,
		state = "loading",
		lockId = HttpService:GenerateGUID(false),
		saving = false,
		released = false,
	}
	profiles[player] = profile
	load(player, profile)
	if profiles[player] ~= profile then
		-- Se fue mientras cargaba: liberar el bloqueo recién tomado.
		save(player, profile, true)
	elseif profile.state == "loaded" then
		task.spawn(autosave, player, profile)
	end
	stateChanged:Fire(player, profile.state)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	profiles[player] = nil
	if profile.state == "loaded" then
		save(player, profile, true)
	end
end

local function onClose()
	local pending = 0
	for player, profile in profiles do
		if profile.state == "loaded" then
			pending += 1
			task.spawn(function()
				save(player, profile, true)
				pending -= 1
			end)
		end
	end
	local deadline = os.clock() + DataConfig.CLOSE_TIMEOUT_SECONDS
	while pending > 0 and os.clock() < deadline do
		task.wait()
	end
end

-- Un kit agrega sus datos en data.kits[name]. Llamar antes de start(): con jugadores ya cargados no se
-- completarían sus datos.
function DataService.registerKit(name: string, kitDefaults: { [string]: any })
	assert(not started, "DataService.registerKit después de start: registrar el kit antes")
	defaults.kits[name] = Reconcile.deepCopy(kitDefaults)
end

function DataService.start()
	if started then
		return
	end
	started = true
	local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, DataConfig.STORE_NAME)
	if ok then
		store = result
	else
		warn("[DataService] DataStore no disponible: " .. tostring(result))
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	game:BindToClose(onClose)
end

-- Datos en memoria del jugador (se modifican directo; el autoguardado los escribe). nil mientras carga.
-- Con estado "errored" son datos por defecto que no se guardan.
function DataService.get(player: Player): Data?
	local profile = profiles[player]
	if not profile or profile.state == "loading" then
		return nil
	end
	return profile.data
end

function DataService.getState(player: Player): State?
	local profile = profiles[player]
	return if profile then profile.state else nil
end

-- Solo con datos cargados sin error se puede dar algo que valga Robux: si no, se pierde al salir.
function DataService.canSave(player: Player): boolean
	return DataService.getState(player) == "loaded"
end

-- Espera a que termine la carga. nil si el jugador se fue.
function DataService.waitForData(player: Player): Data?
	while true do
		local profile = profiles[player]
		if not profile then
			return nil
		end
		if profile.state ~= "loading" then
			return profile.data
		end
		stateChanged.Event:Wait()
	end
end

-- Guarda ya (después de una compra, antes de confirmarla). Devuelve true si quedó escrito.
function DataService.saveAsync(player: Player): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	return save(player, profile, false)
end

return DataService
