--!strict
-- Recompensa diaria con racha (calendario de N días, como los hits). Sin Roblox
-- (tests/DailyRewards.spec.luau). Una por día UTC; reclamar el día siguiente suma racha y saltear un
-- día la reinicia. El calendario vuelve a empezar después del último día.

local Days = require("./Days")

local DailyRewards = {}

export type State = { lastClaimDay: number, streak: number }

export type Status = {
	canClaim: boolean,
	slot: number, -- qué día del calendario se reclama ahora (o el próximo), 1..length
	streak: number, -- racha si reclama ahora
	nextIn: number, -- segundos hasta poder reclamar (0 si ya puede)
}

local function nextStreak(state: State, today: number): number
	if state.lastClaimDay == today - 1 then
		return state.streak + 1
	end
	return 1
end

function DailyRewards.status(state: State, now: number, length: number): Status
	local today = Days.index(now)
	if state.lastClaimDay == today then
		local tomorrowStreak = state.streak + 1
		return {
			canClaim = false,
			slot = ((tomorrowStreak - 1) % length) + 1,
			streak = state.streak,
			nextIn = Days.secondsUntilNext(now),
		}
	end
	local streak = nextStreak(state, today)
	return { canClaim = true, slot = ((streak - 1) % length) + 1, streak = streak, nextIn = 0 }
end

-- Devuelve (true, slot) y deja el estado actualizado, o (false, nil) si hoy ya reclamó.
function DailyRewards.claim(state: State, now: number, length: number): (boolean, number?)
	local status = DailyRewards.status(state, now, length)
	if not status.canClaim then
		return false, nil
	end
	state.lastClaimDay = Days.index(now)
	state.streak = status.streak
	return true, status.slot
end

return DailyRewards
