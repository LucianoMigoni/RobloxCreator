--!strict
-- Reglas del bloqueo de sesión, según la guía oficial "Implement player data and purchasing systems"
-- (create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing). Sin dependencias de
-- Roblox: DataService las aplica dentro del callback de UpdateAsync y tests/ las prueba.

export type Metadata = { [string]: any }
-- ok: este servidor puede leer/escribir. locked: otro servidor lo tiene. lost: este servidor lo tenía y ya no.
export type Status = "ok" | "locked" | "lost"

local SessionLock = {}

SessionLock.LOCK_ID = "LockId"
SessionLock.LOCK_TIME = "LockTime"

-- `heldBefore`: este servidor ya había puesto su bloqueo en una lectura anterior de la clave.
function SessionLock.check(metadata: Metadata?, lockId: string, now: number, expirySeconds: number, heldBefore: boolean): Status
	local current = if metadata then metadata[SessionLock.LOCK_ID] else nil
	if heldBefore then
		-- Aunque no haya bloqueo, otro servidor pudo tomarlo y liberarlo mientras tanto: los datos en memoria ya no son los últimos.
		return if current == lockId then "ok" else "lost"
	end
	if current == nil or current == lockId then
		return "ok"
	end
	local lockTime = if metadata then metadata[SessionLock.LOCK_TIME] else nil
	-- Sin hora válida no hay forma de saber si el otro servidor sigue vivo: se trata como vencido.
	if typeof(lockTime) ~= "number" or now - lockTime >= expirySeconds then
		return "ok"
	end
	return "locked"
end

-- Copia de la metadata con el bloqueo puesto (o quitado si `release`), sin tocar las demás claves.
function SessionLock.apply(metadata: Metadata?, lockId: string, now: number, release: boolean): Metadata
	local result: Metadata = {}
	if metadata then
		for key, value in metadata do
			result[key] = value
		end
	end
	if release then
		result[SessionLock.LOCK_ID] = nil
		result[SessionLock.LOCK_TIME] = nil
	else
		result[SessionLock.LOCK_ID] = lockId
		result[SessionLock.LOCK_TIME] = now
	end
	return result
end

return SessionLock
