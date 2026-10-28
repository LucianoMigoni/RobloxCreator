--!strict
-- Cuentas de progresión de los simuladores: ganancias sin conexión, costo y premio de renacer, y curvas
-- de precio/ingreso para armar las tablas de unidades. Sin Roblox (tests/Progression.spec.luau).

local Progression = {}

-- Ganancias mientras no estaba: ingreso/s × segundos ausente × fracción, con tope de tiempo.
-- Devuelve (monto, segundos contados). Menos de `minSeconds` ausente no da nada (no premia relogear).
function Progression.offline(lastSeen: number, now: number, incomePerSecond: number, rate: number, capSeconds: number, minSeconds: number): (number, number)
	if lastSeen <= 0 or incomePerSecond <= 0 then
		return 0, 0
	end
	local away = math.clamp(now - lastSeen, 0, capSeconds)
	if away < minSeconds then
		return 0, 0
	end
	return math.floor(incomePerSecond * away * rate), away
end

-- Costo del próximo renacimiento: base × crecimiento^renacimientos.
function Progression.rebirthCost(base: number, growth: number, rebirths: number): number
	return math.floor(base * growth ^ rebirths)
end

-- Multiplicador permanente por renacimientos: 1 + porRenacimiento × renacimientos.
function Progression.rebirthMultiplier(perRebirth: number, rebirths: number): number
	return 1 + perRebirth * rebirths
end

-- Curva geométrica para precios o ingresos de N niveles: first, first×ratio, first×ratio²...
-- Redondea a 2 cifras significativas para que los números se vean "limpios" (1.2K, 35K, 1.4M).
function Progression.curve(first: number, ratio: number, count: number): { number }
	local out = {}
	for i = 1, count do
		local raw = first * ratio ^ (i - 1)
		local magnitude = 10 ^ math.max(0, math.floor(math.log10(math.max(raw, 1))) - 1)
		table.insert(out, math.floor(raw / magnitude + 0.5) * magnitude)
	end
	return out
end

-- Segundos que tarda una unidad en pagar su precio (para revisar el balance de una tabla).
function Progression.payback(price: number, incomePerSecond: number): number
	if incomePerSecond <= 0 then
		return math.huge
	end
	return price / incomePerSecond
end

return Progression
