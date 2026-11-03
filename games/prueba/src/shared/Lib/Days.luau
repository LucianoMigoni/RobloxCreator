--!strict
-- Días UTC a partir de os.time(): todos los servidores cambian de día a la vez (00:00 UTC), así las
-- recompensas diarias y las misiones se reinician igual para todos. Sin Roblox.

local Days = {}

Days.SECONDS = 86400

function Days.index(time: number): number
	return time // Days.SECONDS
end

function Days.secondsUntilNext(time: number): number
	return Days.SECONDS - (time % Days.SECONDS)
end

return Days
