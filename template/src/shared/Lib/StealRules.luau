--!strict
-- Cuándo se puede robar una unidad de otra base (bloque Steal). Sin Roblox (tests/StealRules.spec.luau).
-- Los motivos viajan al cliente como código para mostrar el aviso.

local StealRules = {}

export type Check = {
	now: number,
	own: boolean, -- es de su propia base
	locked: boolean, -- la base de la víctima tiene la traba puesta
	victimJoinedAt: number,
	protectNewSeconds: number, -- los recién llegados no pierden nada al principio
	stolenAt: number?, -- cuándo la robaron la última vez
	recentSeconds: number,
	isBest: boolean, -- es la más valiosa de esa base
	protectBest: boolean,
	thiefFull: boolean,
	carrying: boolean, -- el ladrón ya lleva algo
}

function StealRules.check(c: Check): (boolean, string?)
	if c.own then
		return false, "OWN"
	end
	if c.carrying then
		return false, "CARRYING"
	end
	if c.locked then
		return false, "LOCKED"
	end
	if c.now - c.victimJoinedAt < c.protectNewSeconds then
		return false, "PROTECTED"
	end
	local stolenAt = c.stolenAt
	if stolenAt and c.now - stolenAt < c.recentSeconds then
		return false, "RECENT"
	end
	if c.protectBest and c.isBest then
		return false, "BEST"
	end
	if c.thiefFull then
		return false, "FULL"
	end
	return true, nil
end

return StealRules
