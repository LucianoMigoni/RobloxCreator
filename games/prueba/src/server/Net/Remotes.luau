--!strict
-- Única puerta de entrada del cliente al servidor. Todo RemoteEvent/RemoteFunction se crea acá, con
-- validación de argumentos y límite de frecuencia por jugador. Cada remote lleva atributos (Direction,
-- Validated, RateLimit) para que la auditoría de roblox-security detecte los creados por fuera.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RateLimiter = require("./RateLimiter")
local Validate = require("./Validate")

export type Spec = {
	-- Un validador por argumento, en orden. Sobrantes o faltantes se rechazan.
	args: { Validate.Validator },
	-- Pedidos permitidos por ventana: { count = 5, perSeconds = 1 } admite ráfagas de 5 y 5 por segundo.
	rate: { count: number, perSeconds: number },
}

local Remotes = {}

local folder: Folder? = nil
local limiters: { RateLimiter.RateLimiter } = {}
local rejections: { [Player]: number } = {}
local started = false

local function getFolder(): Folder
	if not folder then
		local created = Instance.new("Folder")
		created.Name = "Remotes"
		created.Parent = ReplicatedStorage
		folder = created
	end
	return folder :: Folder
end

local function reject(player: Player, name: string, reason: string)
	local count = (rejections[player] or 0) + 1
	rejections[player] = count
	-- Un cliente legítimo casi nunca llega acá: se registra el primero y cada 50 para no inundar la consola.
	if count == 1 or count % 50 == 0 then
		warn(string.format("[Remotes] %s rechazado para %s (%d en total): %s", name, player.Name, count, reason))
	end
end

local function create(className: string, name: string, direction: string, spec: Spec?): Instance
	local parent = getFolder()
	assert(parent:FindFirstChild(name) == nil, "remote duplicado: " .. name)
	local remote = Instance.new(className)
	remote.Name = name
	remote:SetAttribute("Direction", direction)
	remote:SetAttribute("Validated", true)
	if spec then
		remote:SetAttribute("RateLimit", string.format("%d/%gs", spec.rate.count, spec.rate.perSeconds))
	end
	remote.Parent = parent
	return remote
end

-- Devuelve una función que da el motivo de rechazo, o nil si el pedido pasa límite y validación.
local function guard(spec: Spec): (Player, ...any) -> string?
	local limiter = RateLimiter.new(spec.rate.count, spec.rate.count / spec.rate.perSeconds)
	table.insert(limiters, limiter)
	local check = Validate.args(spec.args)
	return function(player: Player, ...: any): string?
		if not limiter:allow(player) then
			return "límite de frecuencia"
		end
		local ok, err = check(...)
		if not ok then
			return err or "argumentos inválidos"
		end
		return nil
	end
end

-- Cliente → servidor, sin respuesta (equipar, usar habilidad...).
function Remotes.onEvent(name: string, spec: Spec, handler: (Player, ...any) -> ()): RemoteEvent
	local remote = create("RemoteEvent", name, "ClientToServer", spec) :: RemoteEvent
	local blocked = guard(spec)
	remote.OnServerEvent:Connect(function(player: Player, ...: any)
		local reason = blocked(player, ...)
		if reason then
			reject(player, name, reason)
			return
		end
		-- El cast deja leer el mensaje de error: pcall de un handler sin retorno solo tipa el booleano.
		local ok, err = pcall(handler :: (Player, ...any) -> ...any, player, ...)
		if not ok then
			warn(string.format("[Remotes] error en %s: %s", name, tostring(err)))
		end
	end)
	return remote
end

-- Cliente pide y espera respuesta (comprar, reclamar...). Lo que devuelve el handler llega al cliente.
-- Ante rechazo o error el cliente recibe (false, código), nunca el mensaje interno del error.
function Remotes.onInvoke(name: string, spec: Spec, handler: (Player, ...any) -> ...any): RemoteFunction
	local remote = create("RemoteFunction", name, "ClientToServer", spec) :: RemoteFunction
	local blocked = guard(spec)
	remote.OnServerInvoke = function(player: Player, ...: any): ...any
		local reason = blocked(player, ...)
		if reason then
			reject(player, name, reason)
			return false, "REJECTED"
		end
		local results = table.pack(pcall(handler, player, ...))
		if not results[1] then
			warn(string.format("[Remotes] error en %s: %s", name, tostring(results[2])))
			return false, "SERVER_ERROR"
		end
		return table.unpack(results, 2, results.n)
	end
	return remote
end

-- Servidor → cliente (avisos, saldo actualizado). Si un cliente lo dispara es un cliente modificado:
-- se rechaza y se registra.
function Remotes.toClient(name: string): RemoteEvent
	local remote = create("RemoteEvent", name, "ServerToClient") :: RemoteEvent
	remote.OnServerEvent:Connect(function(player: Player)
		reject(player, name, "remote solo servidor→cliente")
	end)
	return remote
end

-- Rechazos acumulados del jugador en esta sesión (para que un juego decida, por ejemplo, expulsar).
function Remotes.rejections(player: Player): number
	return rejections[player] or 0
end

function Remotes.start()
	if started then
		return
	end
	started = true
	Players.PlayerRemoving:Connect(function(player: Player)
		rejections[player] = nil
		for _, limiter in limiters do
			limiter:remove(player)
		end
	end)
end

return Remotes
