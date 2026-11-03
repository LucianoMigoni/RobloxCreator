--!strict
-- Índice por zonas, como Steal An Egg: cada zona tiene sus piezas y un premio que se reclama una vez al
-- descubrirlas todas. Sin Roblox (tests/Collection.spec.luau).

local Collection = {}

export type Zone = { id: string, keys: { string } }

-- (descubiertas, total) de un grupo de claves ("Kitty|Normal").
function Collection.progress(found: { [string]: boolean }, keys: { string }): (number, number)
	local count = 0
	for _, key in keys do
		if found[key] then
			count += 1
		end
	end
	return count, #keys
end

function Collection.complete(found: { [string]: boolean }, zone: Zone): boolean
	local count, total = Collection.progress(found, zone.keys)
	return total > 0 and count >= total
end

-- Anota el premio de la zona como reclamado. false si falta descubrir algo o ya lo reclamó.
function Collection.claim(found: { [string]: boolean }, claimed: { [string]: boolean }, zone: Zone): boolean
	if claimed[zone.id] or not Collection.complete(found, zone) then
		return false
	end
	claimed[zone.id] = true
	return true
end

-- Cuántas claves distintas hay entre todas las zonas (el "Unlocked: 3/112" de abajo).
function Collection.total(zones: { Zone }): number
	local seen: { [string]: boolean } = {}
	local count = 0
	for _, zone in zones do
		for _, key in zone.keys do
			if not seen[key] then
				seen[key] = true
				count += 1
			end
		end
	end
	return count
end

return Collection
