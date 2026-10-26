--!strict
-- Reglas de los critters sin Roblox (se prueban en tests/CritterRules.spec.luau). Reciben la
-- configuración por parámetro porque el CLI de Luau no puede leer ReplicatedStorage.

export type Critter = { uid: string, tier: number, mutation: string, pedestal: number }
export type Weight = { tier: number, weight: number }

local CritterRules = {}

-- Monedas por segundo de un critter. nil si el nivel o la mutación no existen.
function CritterRules.income(incomeByTier: { number }, mutations: { [string]: number }, critter: Critter, multiplier: number): number?
	local base = incomeByTier[critter.tier]
	local mutation = mutations[critter.mutation]
	if not base or not mutation then
		return nil
	end
	return base * mutation * multiplier
end

-- Nivel que sale en la cinta: `roll` en [0, 1) recorre los pesos acumulados.
function CritterRules.rollTier(weights: { Weight }, roll: number): number
	local total = 0
	for _, entry in weights do
		total += entry.weight
	end
	local target = roll * total
	for _, entry in weights do
		target -= entry.weight
		if target < 0 then
			return entry.tier
		end
	end
	return weights[#weights].tier
end

-- Primer pedestal libre (1..count), o nil si están todos ocupados.
function CritterRules.freePedestal(critters: { Critter }, count: number): number?
	local used = {}
	for _, critter in critters do
		used[critter.pedestal] = true
	end
	for pedestal = 1, count do
		if not used[pedestal] then
			return pedestal
		end
	end
	return nil
end

-- Par a fusionar del nivel más bajo que tenga dos (prefiere los "Normal" para no gastar mutaciones).
-- Devuelve los dos índices en `critters`, o nil si no hay par por debajo de maxTier.
function CritterRules.pickFusePair(critters: { Critter }, maxTier: number): (number?, number?)
	for tier = 1, maxTier - 1 do
		local pool = {}
		for index, critter in critters do
			if critter.tier == tier then
				if critter.mutation == "Normal" then
					table.insert(pool, 1, index)
				else
					table.insert(pool, index)
				end
			end
		end
		if #pool >= 2 then
			return pool[1], pool[2]
		end
	end
	return nil, nil
end

return CritterRules
