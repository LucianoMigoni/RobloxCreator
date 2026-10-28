--!strict
-- Números al azar reproducibles a partir de una semilla (para elegir las misiones del día iguales en
-- todos los servidores). Sin Roblox: el `Random` de Roblox no existe en el CLI de los tests.

local Prng = {}

-- Generador congruencial (parámetros de Numerical Recipes), aritmética exacta en doubles.
function Prng.new(seed: number): () -> number
	local state = math.floor(math.abs(seed)) % 4294967296
	return function(): number
		state = (1664525 * state + 1013904223) % 4294967296
		return state / 4294967296
	end
end

-- `count` índices distintos de 1..n, en orden de elección.
function Prng.pick(random: () -> number, n: number, count: number): { number }
	local pool = {}
	for i = 1, n do
		pool[i] = i
	end
	local out = {}
	for _ = 1, math.min(count, n) do
		local k = math.floor(random() * #pool) + 1
		table.insert(out, table.remove(pool, k) :: number)
	end
	return out
end

return Prng
