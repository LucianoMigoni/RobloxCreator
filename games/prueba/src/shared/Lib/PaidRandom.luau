--!strict
-- Aleatorio pago, con las reglas oficiales (/production/monetization/paid-random-items, verificado el
-- 2026-11-03): lo que se paga con Robux, o con una moneda que se compra con Robux, y da un resultado al
-- azar. Son los huevos, las fusiones con chance de mutación y las semillas que mutan al cosechar.
-- - Antes de pagar se muestran todos los resultados con su probabilidad (que sumen 100 %, con la suerte
--   activa): Rarity.percentages sobre estas entradas.
-- - A quien PolicyService le pone ArePaidRandomItemsRestricted (atributo "PaidRandomRestricted"), no se
--   le vende (huevos) o se le da sin azar (fusión y cosecha), dos de los tratamientos permitidos.
-- Sin Roblox (tests/PaidRandom.spec.luau).

local Types = require("../Kits/Types")
local Rarity = require("./Rarity")
local UnitMath = require("./UnitMath")

local PaidRandom = {}

export type Variant = UnitMath.Variant

-- ¿La tirada es aleatorio pago? Marcada `paidRandom`, o pagada con una moneda que se vende por Robux
-- (por ejemplo, la plata del núcleo, que tiene paquetes en la tienda).
function PaidRandom.roll(def: Types.RollDef, purchasable: (string) -> boolean): boolean
	local price = def.price
	return def.paidRandom == true or (price ~= nil and purchasable(price.currency))
end

local function share(list: { Variant }, luck: number): { [string]: number }
	local plain: { Rarity.Entry } = {}
	for _, v in list do
		table.insert(plain, { id = v.id, weight = v.weight, lucky = v.lucky })
	end
	local out: { [string]: number } = {}
	for _, o in Rarity.odds(plain, luck) do
		out[o.id] = o.chance
	end
	return out
end

-- Solo los resultados posibles, en el orden de la configuración.
local function entries(order: { Variant }, chances: { [string]: number }): { Rarity.Entry }
	local out: { Rarity.Entry } = {}
	for _, v in order do
		local p = chances[v.id] or 0
		if p > 0 then
			table.insert(out, { id = v.id, weight = p })
		end
	end
	return out
end

-- Fusión por nivel con `mutationChance`: sin mutación ("Normal", 1 - chance) o una de las mutaciones
-- según su peso, sin suerte (server/Kits/Merge).
function PaidRandom.mergeOdds(chance: number, mutations: { Variant }): { Rarity.Entry }
	local pool: { Variant } = {}
	for _, v in mutations do
		if v.id ~= "Normal" then
			table.insert(pool, v)
		end
	end
	local chances: { [string]: number } = { Normal = 1 - chance }
	for id, p in share(pool, 1) do
		chances[id] = chance * p
	end
	return entries(mutations, chances)
end

-- Fusión con la probabilidad de cada mutación (`odds` o `lucky`): el resto sale Normal.
function PaidRandom.fixedOdds(odds: { [string]: number }, mutations: { Variant }): { Rarity.Entry }
	local chances: { [string]: number } = {}
	local total = 0
	for _, v in mutations do
		if v.id ~= "Normal" then
			chances[v.id] = odds[v.id] or 0
			total += chances[v.id]
		end
	end
	chances.Normal = math.max(0, 1 - total)
	return entries(mutations, chances)
end

-- Mutación de una cosecha (server/Kits/Garden): con `chance` sale una del grupo sin "Normal" (sin suerte);
-- si no, la tirada de siempre de las mutaciones, con la suerte del jugador.
function PaidRandom.harvestOdds(chance: number?, mutations: { Variant }, luck: number): { Rarity.Entry }
	local c = chance or 0
	local pool: { Variant } = {}
	for _, v in mutations do
		if v.id ~= "Normal" then
			table.insert(pool, v)
		end
	end
	local forced = share(pool, 1)
	local rolled = share(mutations, luck)
	local chances: { [string]: number } = {}
	for _, v in mutations do
		chances[v.id] = c * (forced[v.id] or 0) + (1 - c) * (rolled[v.id] or 0)
	end
	return entries(mutations, chances)
end

-- "Gold 4.43% · Diamond 1.11%..." con todos los resultados (Normal incluido), sumando 100 %.
function PaidRandom.line(odds: { Rarity.Entry }): string
	local parts: { string } = {}
	for _, p in Rarity.percentages(odds) do
		table.insert(parts, p.id .. " " .. p.text)
	end
	return table.concat(parts, " · ")
end

return PaidRandom
