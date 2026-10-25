--!strict
-- Acceso del cliente a los remotes que crea el servidor (server/Net/Remotes.luau). El cliente nunca
-- crea remotes: solo pide y muestra lo que el servidor confirma.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConfig = require("./Config/NetConfig")

local Net = {}

local function find(name: string, className: string): Instance
	local folder = ReplicatedStorage:WaitForChild("Remotes", NetConfig.WAIT_SECONDS)
	assert(folder, "no apareció ReplicatedStorage.Remotes: ¿arrancó el servidor?")
	local remote = folder:WaitForChild(name, NetConfig.WAIT_SECONDS)
	assert(remote and remote:IsA(className), string.format("no existe el %s '%s' en Remotes", className, name))
	return remote
end

function Net.event(name: string): RemoteEvent
	return find(name, "RemoteEvent") :: RemoteEvent
end

function Net.func(name: string): RemoteFunction
	return find(name, "RemoteFunction") :: RemoteFunction
end

return Net
