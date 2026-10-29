--!strict
-- Códigos canjeables (los hits los publican en la página del juego y en el grupo). Sin Roblox
-- (tests/Codes.spec.luau). Sin distinguir mayúsculas, uno por jugador, con vencimiento opcional.

local Codes = {}

export type Code = {
	expiresAt: number?, -- os.time UTC; nil = no vence
	reward: any?, -- lo que da (Types.Reward); acá no se mira
}

function Codes.normalize(text: string): string
	return (text:gsub("%s+", "")):upper()
end

-- "OK", "INVALID", "EXPIRED" o "USED".
function Codes.check(codes: { [string]: Code }, redeemed: { [string]: boolean }, text: string, now: number): string
	local key = Codes.normalize(text)
	local code = codes[key]
	if not code then
		return "INVALID"
	end
	if code.expiresAt and now >= code.expiresAt then
		return "EXPIRED"
	end
	if redeemed[key] then
		return "USED"
	end
	return "OK"
end

return Codes
