--!strict
-- Valores de las tablas de posiciones del mundo. OrderedDataStore solo guarda enteros (referencia de
-- OrderedDataStore en creator-docs, verificada el 2026-11-03), y en los juegos incrementales la plata
-- llega a 1e30 y más: se guarda floor(log10(valor + 1) × 1e13), que conserva el orden y entra exacto
-- en un double hasta 1e308 (3,08e15 < 2^53). Al leerlo vuelve exacto hasta 1e12 y con 12 cifras
-- después, más de lo que muestra la tabla ("1.25Qa").

local Ranking = {}

local SCALE = 1e13
local CAP = math.floor(308.25 * SCALE) -- tope (math.huge y lo que se pase)

function Ranking.encode(value: number): number
	if value ~= value or value <= 0 then -- NaN, cero o negativo
		return 0
	end
	if value == math.huge then
		return CAP
	end
	return math.min(CAP, math.floor(math.log10(value + 1) * SCALE))
end

function Ranking.decode(stored: number): number
	if typeof(stored) ~= "number" or stored ~= stored or stored <= 0 then
		return 0
	end
	local value = 10 ^ (stored / SCALE) - 1
	if value < 1e12 then
		return math.floor(value + 0.5)
	end
	return value
end

-- UserId de una clave de la tabla ("12345"), o nil si no es un número entero positivo.
function Ranking.userId(key: any): number?
	local id = tonumber(key)
	if id and id > 0 and id == math.floor(id) then
		return id
	end
	return nil
end

return Ranking
