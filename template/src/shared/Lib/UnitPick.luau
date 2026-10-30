--!strict
-- Qué unidades toma cada acción en grupo: "vender todo", "fusionar" y "equipar lo mejor". Nunca toca
-- las que el jugador cuidó (locked). Sin Roblox (tests/UnitPick.spec.luau).

local Types = require("../Kits/Types")

type Unit = Types.Unit

local UnitPick = {}

-- "Vender todo": ni cuidadas, ni equipadas, ni colocadas en la base, y por debajo de la rareza
-- `keepFromRank` (0 = vende todas). Devuelve los uid.
function UnitPick.sellAll(list: { Unit }, rankOf: (Unit) -> number, keepFromRank: number): { number }
	local out = {}
	for _, unit in list do
		if not unit.locked and not unit.equipped and unit.slot == nil then
			if keepFromRank <= 0 or rankOf(unit) < keepFromRank then
				table.insert(out, unit.uid)
			end
		end
	end
	return out
end

-- `count` unidades iguales para fusionar: mismo `kind` y, si `variant` no es nil, misma mutación
-- ("Normal" = sin mutación). Primero las del inventario y después las colocadas. nil si no alcanzan.
function UnitPick.group(list: { Unit }, kind: string, variant: string?, count: number): { number }?
	local loose: { number }, placed: { number } = {}, {}
	for _, unit in list do
		local sameVariant = variant == nil or (unit.variant or "Normal") == variant
		if unit.kind == kind and sameVariant and not unit.locked and not unit.equipped then
			table.insert(if unit.slot == nil then loose else placed, unit.uid)
		end
	end
	local out: { number } = {}
	for _, source in { loose, placed } do
		for _, uid in source do
			if #out >= count then
				return out
			end
			table.insert(out, uid)
		end
	end
	return if #out >= count then out else nil
end

-- Las `n` mejores según `score` (equipar lo mejor). Empates: la más vieja primero.
function UnitPick.best(list: { Unit }, n: number, score: (Unit) -> number): { number }
	local sorted = table.clone(list)
	table.sort(sorted, function(a, b)
		local sa, sb = score(a), score(b)
		if sa ~= sb then
			return sa > sb
		end
		return a.uid < b.uid
	end)
	local out = {}
	for i = 1, math.min(n, #sorted) do
		table.insert(out, sorted[i].uid)
	end
	return out
end

return UnitPick
