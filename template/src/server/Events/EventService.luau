--!strict
-- Eventos con horario real (EventConfig, Lib/Schedule): BoostService ya aplica sus efectos; este servicio
-- avisa con banner unos minutos antes y al empezar ("LUCKY HOUR started!"), que es cuando más gente se
-- queda. Los relojes los calcula cada cliente con la hora del servidor: son los mismos en todos lados.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventConfig = require(ReplicatedStorage.Shared.Config.EventConfig)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Schedule = require(ReplicatedStorage.Shared.Lib.Schedule)
local AnnounceService = require("../Social/AnnounceService")

local EventService = {}

local TICK_SECONDS = 5
local announced: { [string]: boolean } = {}

local function tick()
	local now = os.time()
	for _, window in Schedule.active(EventConfig.EVENTS, now) do
		local key = window.event.id .. "|" .. window.startsAt .. "|start"
		if not announced[key] then
			announced[key] = true
			AnnounceService.server({ text = window.event.title .. " started!", color = Color3.fromRGB(255, 215, 60), sound = "Riser" })
		end
	end
	for _, window in Schedule.upcoming(EventConfig.EVENTS, now) do
		local untilStart = window.startsAt - now
		local key = window.event.id .. "|" .. window.startsAt .. "|soon"
		if untilStart <= EventConfig.ANNOUNCE_BEFORE and not announced[key] then
			announced[key] = true
			AnnounceService.server({ text = window.event.title .. " in " .. Format.duration(untilStart) .. "!", sound = "Notify" })
		end
	end
end

function EventService.start()
	task.spawn(function()
		while true do
			tick()
			task.wait(TICK_SECONDS)
		end
	end)
end

return EventService
