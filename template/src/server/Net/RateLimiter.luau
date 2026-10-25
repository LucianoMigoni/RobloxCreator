--!strict
-- Límite de frecuencia por clave (jugador) con balde de fichas: permite ráfagas cortas hasta `capacity`
-- y después `refillPerSecond` pedidos por segundo. Sin dependencias de Roblox: se prueba con tests/.

export type RateLimiter = {
	allow: (self: RateLimiter, key: any) -> boolean,
	remove: (self: RateLimiter, key: any) -> (),
}

type Bucket = { tokens: number, updated: number }

local RateLimiter = {}

-- `clock` se inyecta en los tests; en Roblox, os.clock es tiempo transcurrido y monótono.
function RateLimiter.new(capacity: number, refillPerSecond: number, clock: (() -> number)?): RateLimiter
	assert(capacity >= 1 and refillPerSecond > 0, "capacidad >= 1 y recarga > 0")
	local now = clock or os.clock
	-- Claves débiles: si alguien olvida llamar a remove, el jugador que se fue no queda en memoria.
	local buckets: { [any]: Bucket } = setmetatable({}, { __mode = "k" }) :: any

	local limiter = {}

	function limiter.allow(_self: RateLimiter, key: any): boolean
		local t = now()
		local bucket = buckets[key]
		if not bucket then
			bucket = { tokens = capacity, updated = t }
			buckets[key] = bucket
		end
		bucket.tokens = math.min(capacity, bucket.tokens + (t - bucket.updated) * refillPerSecond)
		bucket.updated = t
		if bucket.tokens < 1 then
			return false
		end
		bucket.tokens -= 1
		return true
	end

	function limiter.remove(_self: RateLimiter, key: any)
		buckets[key] = nil
	end

	return limiter :: RateLimiter
end

return RateLimiter
