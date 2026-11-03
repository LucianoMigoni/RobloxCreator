--!strict
-- Misiones diarias (panel fijo de los hits): cada día UTC tocan `count` misiones del pool, las mismas en
-- todos los servidores para ese jugador. Avanzan con eventos ("Collect", "Hatch"...) y se reclaman una
-- vez; completar todas da un bono. Sin Roblox (tests/Quests.spec.luau).

local Days = require("./Days")
local Prng = require("./Prng")

local Quests = {}

export type Def = {
	id: string,
	text: string, -- en inglés, con %s para el objetivo: "Collect %s coins"
	stat: string, -- evento que la hace avanzar
	target: number,
}

export type State = {
	day: number,
	ids: { string },
	progress: { [string]: number },
	claimed: { [string]: boolean },
	bonusClaimed: boolean,
}

local function find(pool: { Def }, id: string): Def?
	for _, def in pool do
		if def.id == id then
			return def
		end
	end
	return nil
end

-- Si cambió el día, elige las misiones nuevas. Devuelve true si las cambió.
function Quests.refresh(state: State, pool: { Def }, now: number, userId: number, count: number): boolean
	local today = Days.index(now)
	if state.day == today and #state.ids > 0 then
		return false
	end
	local random = Prng.new(today * 7919 + userId)
	state.day = today
	state.ids = {}
	for _, i in Prng.pick(random, #pool, count) do
		table.insert(state.ids, pool[i].id)
	end
	state.progress = {}
	state.claimed = {}
	state.bonusClaimed = false
	return true
end

-- Suma `amount` a las misiones de hoy que miran ese evento. Devuelve las que se completaron ahora.
function Quests.track(state: State, pool: { Def }, stat: string, amount: number): { string }
	local done = {}
	for _, id in state.ids do
		local def = find(pool, id)
		if def and def.stat == stat then
			local before = state.progress[id] or 0
			local after = math.min(def.target, before + math.max(0, amount))
			state.progress[id] = after
			if before < def.target and after >= def.target then
				table.insert(done, id)
			end
		end
	end
	return done
end

function Quests.isComplete(state: State, pool: { Def }, id: string): boolean
	local def = find(pool, id)
	return def ~= nil and (state.progress[id] or 0) >= def.target
end

function Quests.claim(state: State, pool: { Def }, id: string): boolean
	if not table.find(state.ids, id) or state.claimed[id] or not Quests.isComplete(state, pool, id) then
		return false
	end
	state.claimed[id] = true
	return true
end

-- El bono se reclama cuando todas las misiones de hoy fueron reclamadas.
function Quests.claimBonus(state: State): boolean
	if state.bonusClaimed or #state.ids == 0 then
		return false
	end
	for _, id in state.ids do
		if not state.claimed[id] then
			return false
		end
	end
	state.bonusClaimed = true
	return true
end

return Quests
