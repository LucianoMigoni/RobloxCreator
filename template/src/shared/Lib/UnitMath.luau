--!strict
-- Cuentas de las unidades del armador (mascotas, criaturas, peces, cultivos): valor, ingreso y poder
-- con su mutación, tamaño y peso; nombre que se muestra; clave del índice; tiradas de variantes y de
-- sorteos con suerte. Sin Roblox (tests/UnitMath.spec.luau): las variantes llegan como datos
-- (RarityConfig.MUTATIONS y SIZES), así servidor y cliente calculan lo mismo.

local Rarity = require("./Rarity")
local Types = require("../Kits/Types")

local UnitMath = {}

export type Unit = Types.Unit

export type Variant = { id: string, weight: number, mult: number, lucky: boolean? }

local NORMAL = "Normal"

local function find(list: { Variant }, id: string?): Variant?
	if id == nil then
		return nil
	end
	for _, variant in list do
		if variant.id == id then
			return variant
		end
	end
	return nil
end

-- Clave del índice: "Dragon|Gold" (sin mutación: "Dragon|Normal").
function UnitMath.key(kind: string, variant: string?): string
	return kind .. "|" .. (variant or NORMAL)
end

-- Multiplicador por el peso: un pez del peso medio vale ×1, el más pesado más.
function UnitMath.weightMult(def: Types.UnitDef, weight: number?): number
	local range = def.weight
	if not range or not weight then
		return 1
	end
	local average = (range.min + range.max) / 2
	return if average > 0 then math.max(0.1, weight / average) else 1
end

-- Lo que multiplican su mutación, su tamaño y su peso.
function UnitMath.multiplier(def: Types.UnitDef, unit: Unit, mutations: { Variant }, sizes: { Variant }): number
	local mult = 1
	local mutation = find(mutations, unit.variant)
	if mutation then
		mult *= mutation.mult
	end
	local size = find(sizes, unit.size)
	if size then
		mult *= size.mult
	end
	return mult * UnitMath.weightMult(def, unit.weight)
end

-- $/s colocada en una base (sin los multiplicadores del jugador).
function UnitMath.income(def: Types.UnitDef, unit: Unit, mutations: { Variant }, sizes: { Variant }): number
	return (def.income or 0) * UnitMath.multiplier(def, unit, mutations, sizes)
end

-- Precio de venta (sin los multiplicadores del jugador).
function UnitMath.value(def: Types.UnitDef, unit: Unit, mutations: { Variant }, sizes: { Variant }): number
	return (def.value or 0) * UnitMath.multiplier(def, unit, mutations, sizes)
end

-- Lo que suma equipada al multiplicador de equip.stat (0.25 = +25 %).
function UnitMath.power(def: Types.UnitDef, unit: Unit, mutations: { Variant }, sizes: { Variant }): number
	return (def.power or 0) * UnitMath.multiplier(def, unit, mutations, sizes)
end

-- "Huge Gold Dragon": tamaño y mutación delante del nombre (Normal no se escribe).
function UnitMath.name(def: Types.UnitDef, unit: { variant: string?, size: string? }): string
	local parts = {}
	if unit.size and unit.size ~= NORMAL then
		table.insert(parts, unit.size)
	end
	if unit.variant and unit.variant ~= NORMAL then
		table.insert(parts, unit.variant)
	end
	table.insert(parts, def.name)
	return table.concat(parts, " ")
end

-- "a" o "an" delante de una palabra en inglés ("an Epic", "a SECRET").
function UnitMath.article(word: string): string
	return if string.match(string.sub(word, 1, 1), "[AEIOUaeiou]") then "an" else "a"
end

-- Lugar de la rareza en RarityConfig.TIERS (1 = la más común). 0 si no existe.
function UnitMath.rank(rarities: { string }, id: string?): number
	if id == nil then
		return 0
	end
	return table.find(rarities, id) or 0
end

-- Un sorteo de la receta (huevo, cinta, pesca) como entradas de Lib/Rarity: la suerte multiplica las
-- unidades de rareza `luckyFrom` para arriba. Las unidades que no existen se saltean.
function UnitMath.entries(pool: { Types.PoolEntry }, units: { [string]: Types.UnitDef }, rarities: { string }, luckyFrom: string?): { Rarity.Entry }
	local from = UnitMath.rank(rarities, luckyFrom)
	local out: { Rarity.Entry } = {}
	for _, entry in pool do
		local def = units[entry.unit]
		if def then
			local rank = UnitMath.rank(rarities, def.rarity)
			table.insert(out, { id = entry.unit, weight = entry.weight, lucky = from > 0 and rank >= from })
		end
	end
	return out
end

-- Mutación o tamaño al azar (nil = Normal). `luck` vuelve más probables las variantes marcadas lucky.
function UnitMath.rollVariant(list: { Variant }, luck: number, random: () -> number): string?
	if #list == 0 then
		return nil
	end
	local picked = Rarity.roll(list :: { any }, luck, random)
	return if picked.id == NORMAL then nil else picked.id
end

-- La mejor probabilidad de conseguir cada unidad en los sorteos de la receta (huevos, cinta, pesca,
-- pilas, salvajes), para el "1 in 400" del índice. Lo que solo sale fusionando o cultivando no está.
function UnitMath.chances(recipe: Types.KitConfig): { [string]: number }
	local best: { [string]: number } = {}
	local function scan(pool: { Types.PoolEntry })
		local total = 0
		for _, entry in pool do
			total += math.max(0, entry.weight)
		end
		if total <= 0 then
			return
		end
		for _, entry in pool do
			local chance = math.max(0, entry.weight) / total
			if chance > (best[entry.unit] or 0) then
				best[entry.unit] = chance
			end
		end
	end
	if recipe.rolls then
		for _, roll in recipe.rolls.list do
			scan(roll.pool)
		end
	end
	if recipe.belt then
		scan(recipe.belt.pool)
	end
	if recipe.fishing then
		for _, pool in recipe.fishing.pools do
			scan(pool.entries)
		end
	end
	if recipe.search then
		for _, pile in recipe.search.piles do
			scan(pile.entries)
		end
	end
	if recipe.wild then
		for _, spawn in recipe.wild.spawns do
			scan(spawn.entries)
		end
	end
	return best
end

-- Probabilidad de una variante sola (Gold, Huge) sin suerte: su peso sobre el total.
function UnitMath.variantChance(list: { Variant }, id: string?): number
	local total, mine = 0, 0
	for _, variant in list do
		total += variant.weight
		if variant.id == (id or NORMAL) then
			mine = variant.weight
		end
	end
	return if total > 0 then mine / total else 0
end

-- Kilos al azar en el rango de la unidad, con los pesados más raros (como en los juegos de pesca).
function UnitMath.rollWeight(def: Types.UnitDef, random: () -> number): number?
	local range = def.weight
	if not range then
		return nil
	end
	local r = random()
	local kilos = range.min + (range.max - range.min) * r * r
	return math.floor(kilos * 10 + 0.5) / 10
end

return UnitMath
