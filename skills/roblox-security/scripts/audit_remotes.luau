-- Auditoría de remotes. Pegar en `execute_luau` del MCP de Studio con datamodel Server, durante un
-- playtest (los remotes los crea el servidor al arrancar). Devuelve un reporte.
-- ERROR = corregir antes de seguir; WARN = revisar a mano.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_CLASSES = { RemoteEvent = true, RemoteFunction = true, UnreliableRemoteEvent = true }
-- Carpetas de remotes que crea Roblox (chat heredado), no el juego.
local ROBLOX_OWNED = { DefaultChatSystemChatEvents = true }

local report = {}
local counts = { ERROR = 0, WARN = 0, OK = 0 }

local function add(level: string, inst: Instance, msg: string)
	counts[level] += 1
	table.insert(report, string.format("%s %s: %s", level, inst:GetFullName(), msg))
end

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	add("ERROR", ReplicatedStorage, "no existe Remotes: ¿se corrió en datamodel Server durante un playtest?")
end

for _, service in game:GetChildren() do
	local listed, descendants = pcall(service.GetDescendants, service)
	if not listed then
		continue -- servicios protegidos de Roblox
	end
	for _, inst in descendants do
		if not REMOTE_CLASSES[inst.ClassName] or (inst.Parent and ROBLOX_OWNED[inst.Parent.Name]) then
			continue
		end
		local direction = inst:GetAttribute("Direction")
		if direction == nil then
			add("ERROR", inst, "creado fuera de server/Net/Remotes.luau: sin validación ni límite de frecuencia")
		elseif direction == "ClientToServer" and inst:GetAttribute("RateLimit") == nil then
			add("ERROR", inst, "cliente→servidor sin límite de frecuencia")
		elseif inst.Parent ~= remotesFolder then
			add("WARN", inst, "fuera de ReplicatedStorage.Remotes")
		else
			counts.OK += 1
		end
	end
end

table.insert(report, 1, string.format("Auditoría de remotes: %d ERROR, %d WARN, %d OK", counts.ERROR, counts.WARN, counts.OK))
return table.concat(report, "\n")
