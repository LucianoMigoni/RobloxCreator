--!strict
-- Escaleras de precios (espacios de la base, parcelas, mejoras, edificios): una lista explícita o
-- base × growth^(nivel − 1), como los hits que suben cada compra. Sin Roblox (tests/Ladder.spec.luau).

local Ladder = {}

-- Precio del nivel `level` (1 = el primero que se compra). nil si la escalera no llega.
function Ladder.price(level: number, prices: { number }?, base: number?, growth: number?): number?
	if level < 1 then
		return nil
	end
	if prices then
		return prices[level]
	end
	if base and growth then
		return math.floor(base * growth ^ (level - 1) + 0.5)
	end
	return nil
end

-- Lo que cuestan `count` niveles seguidos desde el nivel `from`. nil si alguno no existe.
function Ladder.total(from: number, count: number, prices: { number }?, base: number?, growth: number?): number?
	local total = 0
	for level = from, from + count - 1 do
		local price = Ladder.price(level, prices, base, growth)
		if price == nil then
			return nil
		end
		total += price
	end
	return total
end

return Ladder
