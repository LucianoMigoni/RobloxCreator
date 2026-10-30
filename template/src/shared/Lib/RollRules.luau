--!strict
-- Reglas de las tiradas (huevos, dados, puestos de compra): cantidades permitidas con sus pases,
-- precio total y tiradas gratis con espera. Sin Roblox (tests/RollRules.spec.luau).

local Types = require("../Kits/Types")

local RollRules = {}

-- ¿Puede tirar `count` de una vez? Cada cantidad puede pedir un pase (x3, x8).
function RollRules.amount(def: Types.RollDef, count: number, owns: (string) -> boolean): boolean
	for _, amount in def.amounts do
		if amount.count == count then
			local pass = amount.pass
			return pass == nil or owns(pass)
		end
	end
	return false
end

-- Precio total en la moneda de la tirada (nil = gratis con espera).
function RollRules.cost(def: Types.RollDef, count: number): number?
	local price = def.price
	return if price then price.amount * count else nil
end

-- La gratis está lista si ya pasó su hora (`nextFree`, os.time).
function RollRules.freeReady(nextFree: number?, now: number): boolean
	return nextFree == nil or now >= nextFree
end

-- La mayor cantidad que el jugador puede tirar de una vez (para "Auto" y el botón grande).
function RollRules.best(def: Types.RollDef, owns: (string) -> boolean): number
	local best = 0
	for _, amount in def.amounts do
		local pass = amount.pass
		if amount.count > best and (pass == nil or owns(pass)) then
			best = amount.count
		end
	end
	return best
end

return RollRules
