--!strict
-- Reglas del saldo, sin Roblox (se prueban en tests/). Los montos son enteros positivos y finitos;
-- el saldo nunca baja de 0 ni pasa de `max`. Un monto inválido no cambia nada.

local Balance = {}

local function validAmount(amount: number): boolean
	return amount == amount and amount > 0 and amount < math.huge and amount % 1 == 0
end

function Balance.add(balance: number, amount: number, max: number): (boolean, number)
	if not validAmount(amount) then
		return false, balance
	end
	return true, math.min(balance + amount, max)
end

function Balance.spend(balance: number, amount: number): (boolean, number)
	if not validAmount(amount) or amount > balance then
		return false, balance
	end
	return true, balance - amount
end

return Balance
