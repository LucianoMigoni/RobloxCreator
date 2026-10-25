--!strict
-- Copias profundas y completado de datos guardados con los valores por defecto.
-- Sin dependencias de Roblox: se prueba con tests/.

local Reconcile = {}

function Reconcile.deepCopy<T>(value: T): T
	if typeof(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value :: any do
		copy[Reconcile.deepCopy(k)] = Reconcile.deepCopy(v)
	end
	return copy :: any
end

-- Agrega a `data` las claves que faltan respecto de `defaults` (con copias, para no compartir tablas
-- entre jugadores). No pisa valores existentes: un juego que agrega campos nuevos no borra progreso.
-- Solo entra en diccionarios: completar una lista (ítems iniciales) devolvería lo que el jugador ya vendió.
function Reconcile.fill(data: { [any]: any }, defaults: { [any]: any }): { [any]: any }
	for key, default in defaults do
		local current = data[key]
		if current == nil then
			data[key] = Reconcile.deepCopy(default)
		elseif typeof(current) == "table" and typeof(default) == "table" and #default == 0 and next(default) ~= nil then
			Reconcile.fill(current, default)
		end
	end
	return data
end

return Reconcile
