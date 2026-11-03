--!strict
-- Tiradas con peso y suerte, y probabilidades para mostrar. Sin Roblox (tests/Rarity.spec.luau).
-- La suerte multiplica el peso de las entradas marcadas `lucky` (las raras): "x2 Luck" duplica sus
-- chances antes de normalizar. Las reglas oficiales de aleatorios pagos piden mostrar todas las
-- probabilidades (también con el impulso) y que sumen exactamente 100 %: eso hace `percentages`.

local Rarity = {}

export type Entry = {
	id: string,
	weight: number,
	lucky: boolean?, -- la suerte la afecta
}

export type Chance = { id: string, chance: number }

local function weightOf(entry: Entry, luck: number): number
	local w = math.max(0, entry.weight)
	if entry.lucky then
		w *= math.max(1, luck)
	end
	return w
end

function Rarity.total(entries: { Entry }, luck: number?): number
	local total = 0
	for _, entry in entries do
		total += weightOf(entry, luck or 1)
	end
	return total
end

-- Probabilidad de cada entrada (0..1), en el orden de la tabla.
function Rarity.odds(entries: { Entry }, luck: number?): { Chance }
	local l = luck or 1
	local total = Rarity.total(entries, l)
	local out = {}
	for _, entry in entries do
		table.insert(out, { id = entry.id, chance = if total > 0 then weightOf(entry, l) / total else 0 })
	end
	return out
end

-- `random` devuelve un número en [0, 1): en Roblox, `function() return rng:NextNumber() end`.
function Rarity.roll(entries: { Entry }, luck: number?, random: () -> number): Entry
	assert(#entries > 0, "Rarity.roll sin entradas")
	local l = luck or 1
	local total = Rarity.total(entries, l)
	local pick = random() * total
	local acc = 0
	for _, entry in entries do
		acc += weightOf(entry, l)
		if pick < acc then
			return entry
		end
	end
	-- Por redondeo `pick` puede igualar al total: devuelve la última entrada con peso.
	for i = #entries, 1, -1 do
		if weightOf(entries[i], l) > 0 then
			return entries[i]
		end
	end
	return entries[#entries]
end

-- Porcentajes como texto que suman exactamente 100 (método del mayor resto). Usa al menos `decimals`
-- decimales y más si hace falta para que ninguna probabilidad mayor que cero se muestre como "0%".
function Rarity.percentages(entries: { Entry }, luck: number?, decimals: number?): { { id: string, text: string, chance: number } }
	local odds = Rarity.odds(entries, luck)
	local d = decimals or 2
	for _, o in odds do
		if o.chance > 0 then
			d = math.max(d, math.min(10, math.ceil(-math.log10(o.chance * 100)) + 1))
		end
	end
	local unit = 10 ^ d
	local scaled, floors, sum = {}, {}, 0
	for i, o in odds do
		scaled[i] = o.chance * 100 * unit
		floors[i] = math.floor(scaled[i])
		sum += floors[i]
	end
	local remaining = math.floor(100 * unit + 0.5) - sum
	local order = {}
	for i in odds do
		table.insert(order, i)
	end
	table.sort(order, function(a, b)
		return (scaled[a] - floors[a]) > (scaled[b] - floors[b])
	end)
	for k = 1, math.max(0, remaining) do
		local i = order[((k - 1) % #order) + 1]
		floors[i] += 1
	end
	local out = {}
	for i, o in odds do
		-- Mismo valor sin ceros de más: "94%" en vez de "94.00000000%".
		local text = string.format("%." .. d .. "f", floors[i] / unit)
		if text:find("%.") then
			text = text:gsub("0+$", ""):gsub("%.$", "")
		end
		table.insert(out, { id = o.id, text = text .. "%", chance = o.chance })
	end
	return out
end

-- "1 in N" de una entrada (para lo más raro).
function Rarity.oneIn(entries: { Entry }, id: string, luck: number?): number
	for _, o in Rarity.odds(entries, luck) do
		if o.id == id then
			return if o.chance > 0 then math.floor(1 / o.chance + 0.5) else math.huge
		end
	end
	return math.huge
end

return Rarity
