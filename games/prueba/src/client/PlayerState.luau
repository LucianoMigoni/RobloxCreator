--!strict
-- Copia en el cliente de lo que el servidor confirmó (monedas, inventario). Solo lectura: para cambiar
-- algo se le pide al servidor y se espera el StateChanged.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)

local PlayerState = {}

local changed = Instance.new("BindableEvent")
-- Se dispara con el estado nuevo (Types.PlayerSnapshot).
PlayerState.Changed = changed.Event

local current: Types.PlayerSnapshot? = nil

function PlayerState.get(): Types.PlayerSnapshot?
	return current
end

local function set(state: any)
	if typeof(state) ~= "table" then
		return
	end
	current = state
	changed:Fire(state)
end

-- Llamar después de conectar los controladores a Changed, para que reciban el primer estado.
function PlayerState.start()
	Net.event("StateChanged").OnClientEvent:Connect(set)
	local ok, state = pcall(function()
		return Net.func("GetPlayerState"):InvokeServer()
	end)
	if ok then
		set(state)
	end
end

return PlayerState
