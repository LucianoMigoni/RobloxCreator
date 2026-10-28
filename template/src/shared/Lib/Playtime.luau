--!strict
-- Regalos por tiempo jugado en el día ("FREE!" de los hits): cada regalo se desbloquea al llegar a sus
-- minutos de juego del día UTC y se reclama una vez. Sin Roblox (tests/Playtime.spec.luau).

local Days = require("./Days")

local Playtime = {}

export type State = { day: number, seconds: number, claimed: { number } }

-- Suma tiempo jugado; si cambió el día, empieza de cero.
function Playtime.add(state: State, now: number, seconds: number)
	local today = Days.index(now)
	if state.day ~= today then
		state.day = today
		state.seconds = 0
		state.claimed = {}
	end
	state.seconds += math.max(0, seconds)
end

-- Índices de regalos listos para reclamar (`gifts` son segundos de juego, en orden).
function Playtime.ready(state: State, gifts: { number }): { number }
	local out = {}
	for i, needed in gifts do
		if state.seconds >= needed and not table.find(state.claimed, i) then
			table.insert(out, i)
		end
	end
	return out
end

-- Segundos hasta el próximo regalo sin desbloquear (nil si ya están todos).
function Playtime.nextIn(state: State, gifts: { number }): number?
	for i, needed in gifts do
		if state.seconds < needed and not table.find(state.claimed, i) then
			return needed - state.seconds
		end
	end
	return nil
end

function Playtime.claim(state: State, gifts: { number }, index: number): boolean
	local needed = gifts[index]
	if needed == nil or state.seconds < needed or table.find(state.claimed, index) then
		return false
	end
	table.insert(state.claimed, index)
	return true
end

return Playtime
