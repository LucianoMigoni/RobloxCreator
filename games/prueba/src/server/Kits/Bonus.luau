--!strict
-- Bonos entre bloques del armador sin que se requieran en círculo: las mejoras (bloque Upgrades) y lo
-- que se compre registran proveedores, y Units, Plots, Equip, Search, Garden, Stats, Fishing y Wild
-- preguntan cuánto suma cada efecto (Lib/KitCheck.EFFECTS: "inventory", "slots", "bag"...).
-- Changed avisa para que el bloque recalcule (un espacio más en la base, por ejemplo).

local Bonus = {}

type Provider = (Player, string) -> number

local providers: { Provider } = {}
local changed = Instance.new("BindableEvent")
-- (player, effect)
Bonus.Changed = changed.Event

function Bonus.register(provider: Provider)
	table.insert(providers, provider)
end

-- Suma de lo que dan todos los proveedores para ese efecto (0 si nadie da nada).
function Bonus.get(player: Player, effect: string): number
	local total = 0
	for _, provider in providers do
		local ok, value = pcall(provider, player, effect)
		if ok and typeof(value) == "number" and value == value and value ~= math.huge then
			total += value
		elseif not ok then
			warn("[Bonus] error en un proveedor de " .. effect .. ": " .. tostring(value))
		end
	end
	return total
end

function Bonus.notify(player: Player, effect: string)
	changed:Fire(player, effect)
end

return Bonus
