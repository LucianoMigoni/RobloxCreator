--!strict
-- Tienda de semillas que se repone cada `restock` segundos de reloj real, como Grow a Garden: la misma
-- en todos los servidores (la semilla del sorteo es el número de reposición), así los jugadores
-- comentan "¡salió la Mango!". Cada jugador compra hasta lo que hay en su tienda.
-- Sin Roblox (tests/GardenShop.spec.luau).

local Prng = require("./Prng")
local Types = require("../Kits/Types")

local GardenShop = {}

-- Número de reposición de este momento y cuándo termina (os.time).
function GardenShop.window(now: number, restock: number): (number, number)
	local window = math.floor(now / restock)
	return window, (window + 1) * restock
end

-- Cuántas trae cada semilla en esa reposición (0 = no salió).
function GardenShop.stock(seeds: { Types.Seed }, window: number): { [string]: number }
	local random = Prng.new(window * 7919 + 17)
	local out: { [string]: number } = {}
	for _, seed in seeds do
		local appears = random() < (seed.chance or 1)
		local roll = random()
		out[seed.id] = if appears then seed.stock.min + math.floor(roll * (seed.stock.max - seed.stock.min + 1)) else 0
	end
	return out
end

-- Segundos que tarda en crecer con la mejora "grow" (fracción menos, con tope).
function GardenShop.growSeconds(seed: Types.Seed, bonus: number): number
	return seed.grow * (1 - math.clamp(bonus, 0, 0.9))
end

return GardenShop
