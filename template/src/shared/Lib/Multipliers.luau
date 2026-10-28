--!strict
-- Multiplicadores que se apilan, como en los hits: "x2 (Gamepass)", "x2.5 (Rebirth)", "+10% (Friends)".
-- Total de una estadística = (1 + suma de los "add") × producto de los "mult". Sin Roblox
-- (tests/Multipliers.spec.luau). El desglose se muestra en el HUD para que el jugador vea qué le falta.

local Multipliers = {}

export type Kind = "mult" | "add"

export type Source = {
	stat: string, -- "Money", "Luck", "Speed"...
	kind: Kind,
	value: number, -- mult: 2 = x2 · add: 0.1 = +10 %
	label: string, -- en inglés, se ve en el HUD: "Gamepass", "Rebirth", "Friends"
}

function Multipliers.total(sources: { Source }, stat: string): number
	local add, mult = 0, 1
	for _, s in sources do
		if s.stat == stat then
			if s.kind == "add" then
				add += s.value
			else
				mult *= s.value
			end
		end
	end
	return math.max(0, (1 + add) * mult)
end

-- Las fuentes de una estadística, sin las neutras (x1, +0), ordenadas de mayor a menor efecto.
function Multipliers.breakdown(sources: { Source }, stat: string): { Source }
	local out = {}
	for _, s in sources do
		if s.stat == stat and not ((s.kind == "mult" and s.value == 1) or (s.kind == "add" and s.value == 0)) then
			table.insert(out, s)
		end
	end
	table.sort(out, function(a, b)
		local ea = if a.kind == "mult" then a.value - 1 else a.value
		local eb = if b.kind == "mult" then b.value - 1 else b.value
		return ea > eb
	end)
	return out
end

-- Texto de una fuente: "x2 (Gamepass)", "+10% (Friends)".
function Multipliers.describe(source: Source): string
	local value
	if source.kind == "add" then
		value = string.format("+%g%%", math.floor(source.value * 1000 + 0.5) / 10)
	else
		value = string.format("x%g", math.floor(source.value * 100 + 0.5) / 100)
	end
	return value .. " (" .. source.label .. ")"
end

return Multipliers
