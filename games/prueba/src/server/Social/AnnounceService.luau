--!strict
-- Avisos grandes ("Leo got a SECRET Dragon!", "LUCKY HOUR started!"): a un jugador, a todo el servidor
-- o a todos los servidores (MessagingService). El cliente los muestra como banner y en el chat. Los
-- textos son nombres de Roblox y textos de la configuración: nada que escriba un jugador.

local MessagingService = game:GetService("MessagingService")

local Remotes = require("../Net/Remotes")

export type Announcement = {
	text: string,
	color: Color3?,
	rainbow: boolean?, -- texto arcoíris animado (rarezas Secret)
	sound: string?, -- clave de SoundConfig ("Reveal", "Victory")
}

local AnnounceService = {}

local TOPIC = "Announce"
-- MessagingService tiene cupo por servidor (150 + 60 × jugadores por minuto): un global cada tanto.
local GLOBAL_MIN_SECONDS = 5

local remote: RemoteEvent? = nil
local lastGlobal = 0

function AnnounceService.player(player: Player, announcement: Announcement)
	if remote then
		remote:FireClient(player, announcement)
	end
end

function AnnounceService.server(announcement: Announcement)
	if remote then
		remote:FireAllClients(announcement)
	end
end

-- A todos los servidores. Si el cupo no alcanza, queda solo en este servidor.
function AnnounceService.global(announcement: Announcement)
	AnnounceService.server(announcement)
	local now = os.clock()
	if now - lastGlobal < GLOBAL_MIN_SECONDS then
		return
	end
	lastGlobal = now
	local color = announcement.color
	local payload = {
		text = announcement.text,
		color = if color then color:ToHex() else nil,
		rainbow = announcement.rainbow,
		sound = announcement.sound,
		from = game.JobId,
	}
	task.spawn(function()
		local ok, err = pcall(MessagingService.PublishAsync, MessagingService, TOPIC, payload)
		if not ok then
			warn("[AnnounceService] no se pudo publicar el aviso global: " .. tostring(err))
		end
	end)
end

function AnnounceService.start()
	remote = Remotes.toClient("Announced")
	task.spawn(function()
		local ok, err = pcall(MessagingService.SubscribeAsync, MessagingService, TOPIC, function(message: { Data: any, Sent: number })
			local data = message.Data
			if typeof(data) ~= "table" or data.from == game.JobId or typeof(data.text) ~= "string" then
				return
			end
			local color: Color3? = nil
			if typeof(data.color) == "string" then
				local parsed, value = pcall(Color3.fromHex, data.color)
				color = if parsed then value else nil
			end
			AnnounceService.server({ text = data.text, color = color, rainbow = data.rainbow == true, sound = data.sound })
		end)
		if not ok then
			warn("[AnnounceService] sin avisos entre servidores: " .. tostring(err))
		end
	end)
end

return AnnounceService
