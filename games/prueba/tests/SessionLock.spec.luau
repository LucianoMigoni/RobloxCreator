--!strict
local TestKit = require("./TestKit")
local SessionLock = require("../src/server/Data/SessionLock")

local equal = TestKit.equal
local EXPIRY = 600
local NOW = 10_000

local function locked(id: string, at: number)
	return { LockId = id, LockTime = at }
end

TestKit.run("SessionLock", {
	["clave nueva o sin bloqueo se puede tomar"] = function()
		equal(SessionLock.check(nil, "yo", NOW, EXPIRY, false), "ok", "sin metadata")
		equal(SessionLock.check({}, "yo", NOW, EXPIRY, false), "ok", "metadata vacía")
	end,

	["bloqueo ajeno vigente impide tomarla"] = function()
		equal(SessionLock.check(locked("otro", NOW - 10), "yo", NOW, EXPIRY, false), "locked")
		equal(SessionLock.check(locked("otro", NOW - EXPIRY + 1), "yo", NOW, EXPIRY, false), "locked", "un segundo antes de vencer")
	end,

	["bloqueo ajeno vencido se puede tomar"] = function()
		equal(SessionLock.check(locked("otro", NOW - EXPIRY), "yo", NOW, EXPIRY, false), "ok", "justo al vencer")
		equal(SessionLock.check({ LockId = "otro" }, "yo", NOW, EXPIRY, false), "ok", "sin hora")
		equal(SessionLock.check({ LockId = "otro", LockTime = "ayer" }, "yo", NOW, EXPIRY, false), "ok", "hora inválida")
	end,

	["el propio bloqueo sigue siendo nuestro"] = function()
		equal(SessionLock.check(locked("yo", NOW - 5), "yo", NOW, EXPIRY, true), "ok")
		equal(SessionLock.check(locked("yo", NOW - 5), "yo", NOW, EXPIRY, false), "ok", "aunque no lo recordemos")
	end,

	["si lo teníamos y otro lo tomó, se perdió"] = function()
		equal(SessionLock.check(locked("otro", NOW), "yo", NOW, EXPIRY, true), "lost", "otro lo tiene")
		equal(SessionLock.check(nil, "yo", NOW, EXPIRY, true), "lost", "otro lo tomó y lo liberó")
		equal(SessionLock.check({}, "yo", NOW, EXPIRY, true), "lost", "metadata sin bloqueo")
	end,

	["apply pone y quita el bloqueo sin tocar otras claves"] = function()
		local original = { Version = 3, LockId = "viejo", LockTime = 1 }
		local taken = SessionLock.apply(original, "yo", NOW, false)
		equal(taken.LockId, "yo", "id")
		equal(taken.LockTime, NOW, "hora")
		equal(taken.Version, 3, "otra clave")
		equal(original.LockId, "viejo", "no modifica la original")
		local released = SessionLock.apply(taken, "yo", NOW, true)
		equal(released.LockId, nil, "liberado")
		equal(released.LockTime, nil, "sin hora")
		equal(released.Version, 3, "otra clave sigue")
		equal(SessionLock.apply(nil, "yo", NOW, false).LockId, "yo", "desde nil")
	end,
})
