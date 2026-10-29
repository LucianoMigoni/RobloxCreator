--!strict
-- Eventos globales con horario real (Lib/Schedule): todos los servidores los ven a la vez y el HUD
-- muestra la cuenta regresiva. Los recurrentes traen gente a horas fijas; los "admin abuse" se
-- anuncian con fecha (en el grupo y en las notas del update) y suelen romper récords.

local Schedule = require("../Lib/Schedule")

local HOUR = 3600

return {
	EVENTS = {
		{ id = "LuckyHour", title = "LUCKY HOUR", duration = 15 * 60, every = 2 * HOUR, offset = 0, effects = { Luck = 2 } },
		{ id = "MoneyRush", title = "MONEY RUSH", duration = 10 * 60, every = 3 * HOUR, offset = HOUR, effects = { Money = 2 } },
		-- Fechas UTC con os.time({ year = ..., month = ..., day = ..., hour = ... }) o un número fijo.
		{ id = "AdminAbuse", title = "ADMIN ABUSE", duration = HOUR, starts = {}, effects = { Money = 3, Luck = 5, Speed = 2 } },
	} :: { Schedule.Event },
	-- Con cuánta anticipación se avisa en el HUD que un evento está por empezar.
	ANNOUNCE_BEFORE = 5 * 60,
}
