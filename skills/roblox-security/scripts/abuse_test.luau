-- Prueba de abuso: hace lo que haría un exploiter. Pegar en `execute_luau` del MCP de Studio con
-- datamodel Client, durante un playtest. A cada remote cliente→servidor le manda argumentos que ningún
-- validador acepta (NaN primero, que falla con todos) y una ráfaga para el límite de frecuencia.
-- RemoteFunction: debe responder (false, "REJECTED"); si responde otra cosa, aceptó basura (ERROR).
-- RemoteEvent: no responde; los rechazos se ven en `get_console_output` como "[Remotes] ... rechazado"
-- y el estado del jugador (monedas, inventario) no debe cambiar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NAN = 0 / 0
local HUGE_TEXT = string.rep("x", 100000)
local BURST = 60 -- más que cualquier ráfaga legítima configurada

local payloads: { { any } } = {
	{ NAN },
	{ NAN, HUGE_TEXT },
	{ NAN, { ClassName = "Part" } }, -- tabla que imita una instancia
}

local report = {}
local counts = { ERROR = 0, OK = 0, EVENT = 0 }

local folder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not folder then
	return "ERROR no existe ReplicatedStorage.Remotes: ¿se corrió en datamodel Client durante un playtest?"
end

for _, remote in folder:GetChildren() do
	if remote:GetAttribute("Direction") ~= "ClientToServer" then
		continue
	end
	if remote:IsA("RemoteFunction") then
		for _, args in payloads do
			local ok, first, second = pcall(remote.InvokeServer, remote, table.unpack(args))
			if ok and not (first == false and second == "REJECTED") then
				counts.ERROR += 1
				table.insert(report, string.format("ERROR %s aceptó argumentos inválidos y respondió %s", remote.Name, tostring(first)))
			else
				counts.OK += 1
			end
		end
	elseif remote:IsA("RemoteEvent") then
		for _, args in payloads do
			remote:FireServer(table.unpack(args))
		end
		for _ = 1, BURST do
			remote:FireServer(NAN)
		end
		counts.EVENT += 1
	end
end

table.insert(report, 1, string.format(
	"Prueba de abuso: %d ERROR, %d respuestas rechazadas OK, %d RemoteEvents disparados (revisar get_console_output)",
	counts.ERROR, counts.OK, counts.EVENT
))
return table.concat(report, "\n")
