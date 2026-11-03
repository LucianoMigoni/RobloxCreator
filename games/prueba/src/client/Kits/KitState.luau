--!strict
-- Lo de cada bloque del armador en el estado del jugador (state.kit.<bloque>, que arma
-- server/Kits/Kits.luau). Solo lectura, como PlayerState: para cambiar algo se le pide al servidor.

local PlayerState = require("../PlayerState")

local KitState = {}

function KitState.get(key: string): any
	local state = PlayerState.get()
	local kit = if state then state.kit else nil
	return if typeof(kit) == "table" then kit[key] else nil
end

-- Llama `callback(estadoDelBloque, estadoCompleto)` con cada estado que trae ese bloque (y ya mismo si
-- el primero llegó antes de conectarse).
function KitState.on(key: string, callback: (any, any) -> ())
	PlayerState.Changed:Connect(function(state: any)
		local kit = state.kit
		if typeof(kit) == "table" and kit[key] ~= nil then
			callback(kit[key], state)
		end
	end)
	local current = KitState.get(key)
	if current ~= nil then
		task.spawn(callback, current, PlayerState.get())
	end
end

return KitState
