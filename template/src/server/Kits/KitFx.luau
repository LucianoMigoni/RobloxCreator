--!strict
-- Efectos de los bloques del armador para el cliente, por un solo remote ("KitFx"): "+$1.2K" al cobrar,
-- el resultado de un huevo para la animación, "Stolen!", la picada de un pez. El cliente los reparte
-- con Bus.emit("Kit:<nombre>", datos) (client/Kits/Kits.luau). Solo muestran: lo que vale ya lo hizo
-- el servidor.

local Remotes = require("../Net/Remotes")

local KitFx = {}

local remote: RemoteEvent? = nil

function KitFx.start()
	if not remote then
		remote = Remotes.toClient("KitFx")
	end
end

function KitFx.send(player: Player, name: string, payload: any?)
	local r = remote
	if r then
		r:FireClient(player, name, payload)
	end
end

function KitFx.all(name: string, payload: any?)
	local r = remote
	if r then
		r:FireAllClients(name, payload)
	end
end

return KitFx
