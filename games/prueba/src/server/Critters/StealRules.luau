--!strict
-- Reglas del robo sin Roblox (se prueban en tests/StealRules.spec.luau).

export type Critter = { uid: string, tier: number, mutation: string, pedestal: number }

export type Attempt = {
	isOwner: boolean, -- el ladrón es el dueño de la base
	carrying: boolean, -- el ladrón ya lleva un critter
	thiefHasRoom: boolean, -- el ladrón tiene un pedestal libre
	locked: boolean, -- base trabada (o con escudo)
	protected: boolean, -- dueño nuevo, en sus primeros minutos
	mostValuable: boolean, -- es el critter más valioso del dueño
	recentlyStolen: boolean,
}

local StealRules = {}

-- Por qué no se puede robar, o nil si se puede. El orden importa: es el motivo que se le muestra al ladrón.
function StealRules.blockReason(attempt: Attempt): string?
	if attempt.isOwner then
		return "OWN_BASE"
	elseif attempt.carrying then
		return "ALREADY_CARRYING"
	elseif attempt.locked then
		return "LOCKED"
	elseif attempt.protected then
		return "PROTECTED"
	elseif attempt.mostValuable then
		return "MOST_VALUABLE"
	elseif attempt.recentlyStolen then
		return "RECENTLY_STOLEN"
	elseif not attempt.thiefHasRoom then
		return "NO_ROOM"
	end
	return nil
end

-- uid del critter que más gana (en empate, el primero de la lista), o nil sin critters.
function StealRules.mostValuable(critters: { Critter }, incomeOf: (Critter) -> number): string?
	local best: string?, bestIncome = nil, -math.huge
	for _, critter in critters do
		local income = incomeOf(critter)
		if income > bestIncome then
			best, bestIncome = critter.uid, income
		end
	end
	return best
end

-- ¿Un punto (en coordenadas locales de la base) está dentro de una base cuadrada de lado `size`?
function StealRules.inside(localX: number, localZ: number, size: number): boolean
	local half = size / 2
	return math.abs(localX) <= half and math.abs(localZ) <= half
end

return StealRules
