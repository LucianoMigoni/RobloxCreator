--!strict
-- Índice de colección ("Index" de los hits): qué unidades y variantes descubrió cada jugador. El kit
-- avisa cada hallazgo (discover) y dice cuántas hay en total (setTotal); completar el índice es una
-- meta larga y el HUD muestra "12/80".

local DataService = require("../Data/DataService")
local Signals = require("../Signals")

local IndexService = {}

local total = 0

function IndexService.setTotal(count: number)
	total = math.max(0, count)
end

-- Anota un hallazgo ("Dragon|Gold"). Devuelve true si es nuevo (para el "NEW!" del popup).
function IndexService.discover(player: Player, key: string): boolean
	local data = DataService.get(player)
	if not data or data.index[key] then
		return false
	end
	data.index[key] = true
	Signals.track(player, "Discover", 1)
	Signals.dirty(player)
	return true
end

function IndexService.counts(player: Player): (number, number)
	local data = DataService.get(player)
	local found = 0
	if data then
		for _ in data.index do
			found += 1
		end
	end
	return found, math.max(total, found)
end

function IndexService.start() end

return IndexService
