--!strict
-- ¿El jugador tiene abierta esta zona? Lo responde el bloque Zones cuando la receta lo usa (lo registra
-- al arrancar); sin Zones, todo está abierto. Así tiradas, pesca, búsqueda, salvajes y el índice
-- preguntan lo mismo sin requerir el bloque Zones.

local Gates = {}

local checker: ((Player, string) -> boolean)? = nil

function Gates.register(check: (Player, string) -> boolean)
	checker = check
end

-- `zone` nil = sin zona: abierto.
function Gates.open(player: Player, zone: string?): boolean
	local check = checker
	if zone == nil or check == nil then
		return true
	end
	local ok, result = pcall(check, player, zone)
	return ok and result == true
end

return Gates
