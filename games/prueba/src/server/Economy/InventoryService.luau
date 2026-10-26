--!strict
-- Ítems del jugador (ids de ShopConfig.ITEMS). Solo el servidor los cambia.

local DataService = require("../Data/DataService")
local PlayerStateService = require("../PlayerStateService")

local InventoryService = {}

function InventoryService.has(player: Player, itemId: string): boolean
	local data = DataService.get(player)
	return data ~= nil and table.find(data.inventory, itemId) ~= nil
end

-- Ítems únicos: devuelve false si ya lo tiene o si los datos no están cargados.
function InventoryService.add(player: Player, itemId: string): boolean
	local data = DataService.get(player)
	if not data or table.find(data.inventory, itemId) then
		return false
	end
	table.insert(data.inventory, itemId)
	PlayerStateService.push(player)
	return true
end

function InventoryService.list(player: Player): { string }
	local data = DataService.get(player)
	return if data then table.clone(data.inventory) else {}
end

return InventoryService
