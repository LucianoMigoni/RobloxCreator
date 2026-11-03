--!strict
-- Acciones entre controladores sin requerirse en círculo: el que abre la tienda la registra
-- (Bus.handle("OpenShop", ...)) y cualquiera la pide (Bus.call("OpenShop", "Currency")). También
-- avisos sueltos (Bus.emit / Bus.on) como "HatchStarted" para que un kit pause el HUD.

local Bus = {}

local handlers: { [string]: (...any) -> ...any } = {}
local listeners: { [string]: { (...any) -> () } } = {}

function Bus.handle(name: string, handler: (...any) -> ...any)
	handlers[name] = handler
end

-- Devuelve lo que devuelva el handler, o nada si nadie lo registró (un juego sin esa ventana).
function Bus.call(name: string, ...: any): ...any
	local handler = handlers[name]
	if handler then
		return handler(...)
	end
	return nil
end

function Bus.has(name: string): boolean
	return handlers[name] ~= nil
end

function Bus.on(name: string, listener: (...any) -> ())
	local list = listeners[name] or {}
	listeners[name] = list
	table.insert(list, listener)
end

function Bus.emit(name: string, ...: any)
	local list = listeners[name]
	if list then
		for _, listener in list do
			task.spawn(listener, ...)
		end
	end
end

return Bus
