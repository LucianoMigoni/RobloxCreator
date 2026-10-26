--!strict
-- Registro de compras de Robux ya otorgadas (PurchaseId → hora), sin Roblox (se prueba en tests/).
-- ProcessReceipt puede volver a llamarse por una compra que ya se respondió como otorgada, así que
-- el registro vive en los datos del jugador.

export type Log = { [string]: number }

local Receipts = {}

function Receipts.has(log: Log, purchaseId: string): boolean
	return log[purchaseId] ~= nil
end

-- Anota la compra y descarta las más viejas por encima de `max` para que los datos no crezcan sin
-- límite. Nunca descarta la recién anotada, aunque otras tengan la misma hora.
function Receipts.record(log: Log, purchaseId: string, now: number, max: number)
	log[purchaseId] = now
	local count = 0
	for _ in log do
		count += 1
	end
	while count > max do
		local oldestId: string? = nil
		local oldestTime = math.huge
		for id, time in log do
			if id ~= purchaseId and time < oldestTime then
				oldestId, oldestTime = id, time
			end
		end
		if not oldestId then
			break
		end
		log[oldestId] = nil
		count -= 1
	end
end

return Receipts
