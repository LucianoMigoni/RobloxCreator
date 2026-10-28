--!strict
-- Eventos globales con horario real ("ADMIN ABUSE 09:20:37", "Lucky Hour", "Server Race In: 00:17"):
-- todos los servidores calculan lo mismo con la hora UTC, sin coordinarse. Los temporizadores son
-- reales (regla oficial: nada de cuentas regresivas falsas). Sin Roblox (tests/Schedule.spec.luau).

local Schedule = {}

export type Event = {
	id: string,
	title: string, -- en inglés, se ve en el HUD
	duration: number, -- segundos
	-- Recurrente: empieza cada `every` segundos desde `offset` (UTC). Ej.: every = 7200, offset = 0 →
	-- a las 00:00, 02:00, 04:00... UTC.
	every: number?,
	offset: number?,
	-- O fechas fijas (os.time UTC de cada inicio), para eventos anunciados.
	starts: { number }?,
	-- Efectos que el servidor aplica mientras dura: { Luck = 2, Money = 3 }.
	effects: { [string]: number },
}

export type Window = { event: Event, startsAt: number, endsAt: number }

-- La ventana de un evento que contiene `now`, o la próxima que empieza después.
local function window(event: Event, now: number): Window?
	if event.every and event.every > 0 then
		local offset = event.offset or 0
		local cycle = math.floor((now - offset) / event.every)
		local start = offset + cycle * event.every
		if now < start + event.duration then
			return { event = event, startsAt = start, endsAt = start + event.duration }
		end
		local nextStart = start + event.every
		return { event = event, startsAt = nextStart, endsAt = nextStart + event.duration }
	end
	local best: Window? = nil
	local starts: { number } = event.starts or {}
	for _, start in starts do
		if now < start + event.duration and (best == nil or start < best.startsAt) then
			best = { event = event, startsAt = start, endsAt = start + event.duration }
		end
	end
	return best
end

function Schedule.active(events: { Event }, now: number): { Window }
	local out = {}
	for _, event in events do
		local w = window(event, now)
		if w and w.startsAt <= now then
			table.insert(out, w)
		end
	end
	return out
end

-- Próximos eventos que todavía no empezaron, ordenados por inicio.
function Schedule.upcoming(events: { Event }, now: number): { Window }
	local out = {}
	for _, event in events do
		local w = window(event, now)
		if w and w.startsAt > now then
			table.insert(out, w)
		end
	end
	table.sort(out, function(a, b)
		return a.startsAt < b.startsAt
	end)
	return out
end

-- Multiplicador total de una estadística por los eventos activos (se multiplican entre sí).
function Schedule.effect(events: { Event }, now: number, stat: string): number
	local m = 1
	for _, w in Schedule.active(events, now) do
		m *= w.event.effects[stat] or 1
	end
	return m
end

return Schedule
