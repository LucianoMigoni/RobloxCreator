--!strict
-- Lógica de retención: diarios, regalos por tiempo, misiones, objetivos, eventos, códigos y progresión.
local TestKit = require("./TestKit")
local Codes = require("../src/shared/Lib/Codes")
local DailyRewards = require("../src/shared/Lib/DailyRewards")
local Multipliers = require("../src/shared/Lib/Multipliers")
local Objectives = require("../src/shared/Lib/Objectives")
local Playtime = require("../src/shared/Lib/Playtime")
local Prng = require("../src/shared/Lib/Prng")
local Progression = require("../src/shared/Lib/Progression")
local Quests = require("../src/shared/Lib/Quests")
local Schedule = require("../src/shared/Lib/Schedule")

local equal = TestKit.equal
local DAY = 86400
local T0 = 20000 * DAY + 3600 -- un día cualquiera, 01:00 UTC

TestKit.run("Retention", {
	["diario: racha sube día a día y se corta si saltea"] = function()
		local s: DailyRewards.State = { lastClaimDay = -1, streak = 0 }
		local ok, slot = DailyRewards.claim(s, T0, 7)
		equal(ok, true)
		equal(slot, 1)
		equal((DailyRewards.claim(s, T0 + 60, 7)), false, "una vez por día")
		equal(DailyRewards.status(s, T0 + 60, 7).nextIn, DAY - 3660, "falta hasta las 00:00 UTC")
		ok, slot = DailyRewards.claim(s, T0 + DAY, 7)
		equal(slot, 2, "día siguiente suma")
		ok, slot = DailyRewards.claim(s, T0 + 3 * DAY, 7)
		equal(slot, 1, "saltear un día reinicia")
	end,

	["diario: el calendario vuelve a empezar"] = function()
		local s: DailyRewards.State = { lastClaimDay = 20000 - 1, streak = 7 }
		local _, slot = DailyRewards.claim(s, T0, 7)
		equal(slot, 1, "día 8 = casilla 1")
		equal(s.streak, 8)
	end,

	["regalos por tiempo: se desbloquean, se reclaman una vez y se reinician por día"] = function()
		local gifts = { 60, 300, 600 }
		local s: Playtime.State = { day = -1, seconds = 0, claimed = {} }
		Playtime.add(s, T0, 299)
		equal(#Playtime.ready(s, gifts), 1)
		equal(Playtime.nextIn(s, gifts), 1)
		equal(Playtime.claim(s, gifts, 1), true)
		equal(Playtime.claim(s, gifts, 1), false, "no dos veces")
		equal(Playtime.claim(s, gifts, 2), false, "todavía no")
		Playtime.add(s, T0 + DAY, 10)
		equal(s.seconds, 10, "día nuevo empieza de cero")
		equal(#s.claimed, 0)
	end,

	["misiones: mismas para el mismo jugador y día, avanzan y dan bono"] = function()
		local pool: { Quests.Def } = {
			{ id = "collect", text = "Collect %s", stat = "MoneyEarned", target = 100 },
			{ id = "hatch", text = "Hatch %s eggs", stat = "Hatch", target = 3 },
			{ id = "steal", text = "Steal %s", stat = "Steal", target = 1 },
			{ id = "play", text = "Play %s minutes", stat = "Minutes", target = 10 },
		}
		local a: Quests.State = { day = -1, ids = {}, progress = {}, claimed = {}, bonusClaimed = false }
		local b: Quests.State = { day = -1, ids = {}, progress = {}, claimed = {}, bonusClaimed = false }
		Quests.refresh(a, pool, T0, 42, 3)
		Quests.refresh(b, pool, T0 + 100, 42, 3)
		equal(table.concat(a.ids, ","), table.concat(b.ids, ","), "deterministas")
		equal(#a.ids, 3)
		equal(Quests.refresh(a, pool, T0 + 200, 42, 3), false, "mismo día no cambia")
		for _, id in a.ids do
			for _, def in pool do
				if def.id == id then
					Quests.track(a, pool, def.stat, def.target * 2)
				end
			end
		end
		equal(Quests.claimBonus(a), false, "sin reclamar todas")
		for _, id in a.ids do
			equal(Quests.claim(a, pool, id), true, id)
		end
		equal(Quests.claimBonus(a), true)
		equal(Quests.claimBonus(a), false, "bono una vez")
	end,

	["objetivos: cadena fija y después infinitos que crecen"] = function()
		local chain: { Objectives.Def } = {
			{ id = "earn", text = "Earn $%s", stat = "MoneyEarned", target = 100, money = true },
			{ id = "steal", text = "Steal a pet", stat = "Steal", target = 1 },
		}
		local endless: Objectives.Endless = { text = "Earn $%s", stat = "MoneyEarned", base = 1000, growth = 3, money = true }
		local s: Objectives.State = { index = 1, progress = 0 }
		equal(Objectives.track(chain, endless, s, "Steal", 1), nil, "evento de otro objetivo")
		equal(Objectives.track(chain, endless, s, "MoneyEarned", 60), nil)
		equal(s.progress, 60)
		local done = Objectives.track(chain, endless, s, "MoneyEarned", 60)
		equal(done and done.id, "earn")
		equal(Objectives.track(chain, endless, s, "Steal", 1) ~= nil, true)
		local first = Objectives.current(chain, endless, s)
		equal(first and first.target, 1000)
		Objectives.track(chain, endless, s, "MoneyEarned", 1000)
		local second = Objectives.current(chain, endless, s)
		equal(second and second.target, 3000)
	end,

	["eventos: recurrentes y con fecha, efecto mientras duran"] = function()
		local events: { Schedule.Event } = {
			{ id = "lucky", title = "LUCKY HOUR", duration = 900, every = 7200, offset = 0, effects = { Luck = 2 } },
			{ id = "admin", title = "ADMIN ABUSE", duration = 3600, starts = { T0 + 5000 }, effects = { Money = 3, Luck = 5 } },
		}
		local start = (T0 // 7200) * 7200
		equal(#Schedule.active(events, start + 100), 1, "lucky activo")
		equal(Schedule.effect(events, start + 100, "Luck"), 2)
		equal(#Schedule.active(events, start + 1000), 0, "lucky terminó")
		local up = Schedule.upcoming(events, start + 1000)
		equal(up[1].event.id, "lucky", "el próximo lucky (T0+3600) antes que admin (T0+5000)")
		equal(up[2].event.id, "admin")
		equal(up[1].startsAt, start + 7200)
		equal(Schedule.effect(events, T0 + 5100, "Luck"), 5, "admin solo (lucky no coincide)")
		equal(#Schedule.active(events, T0 + 9000), 0, "admin terminó")
	end,

	["códigos: sin mayúsculas, vencidos, usados"] = function()
		local codes: { [string]: Codes.Code } = { RELEASE = {}, OLD = { expiresAt = T0 } }
		local used: { [string]: boolean } = {}
		equal(Codes.check(codes, used, " release ", T0), "OK")
		used.RELEASE = true
		equal(Codes.check(codes, used, "Release", T0), "USED")
		equal(Codes.check(codes, used, "old", T0), "EXPIRED")
		equal(Codes.check(codes, used, "nope", T0), "INVALID")
	end,

	["multiplicadores: suma los add y multiplica los mult"] = function()
		local sources: { Multipliers.Source } = {
			{ stat = "Money", kind = "mult", value = 2, label = "Gamepass" },
			{ stat = "Money", kind = "add", value = 0.1, label = "Friends" },
			{ stat = "Money", kind = "add", value = 0.2, label = "Group" },
			{ stat = "Money", kind = "mult", value = 1, label = "Neutral" },
			{ stat = "Luck", kind = "mult", value = 3, label = "Potion" },
		}
		equal(math.abs(Multipliers.total(sources, "Money") - 2.6) < 1e-9, true)
		equal(Multipliers.total(sources, "Speed"), 1)
		local b = Multipliers.breakdown(sources, "Money")
		equal(#b, 3, "sin la neutra")
		equal(Multipliers.describe(b[1]), "x2 (Gamepass)")
		equal(Multipliers.describe(b[3]), "+10% (Friends)")
	end,

	["progresión: sin conexión con tope, renacer y curvas"] = function()
		local amount, away = Progression.offline(T0, T0 + 10 * 3600, 100, 0.5, 2 * 3600, 60)
		equal(away, 7200, "tope de 2 h")
		equal(amount, 360000)
		equal((Progression.offline(T0, T0 + 30, 100, 0.5, 7200, 60)), 0, "poco tiempo no da nada")
		equal(Progression.rebirthCost(1e6, 2.5, 2), 6250000)
		equal(Progression.rebirthMultiplier(0.5, 3), 2.5)
		local c = Progression.curve(10, 6, 4)
		equal(table.concat(c, ","), "10,60,360,2200")
		equal(Progression.payback(400, 7), 400 / 7)
	end,

	["prng: reproducible y elige sin repetir"] = function()
		local a, b = Prng.new(123), Prng.new(123)
		equal(a(), b())
		local picks = Prng.pick(Prng.new(5), 10, 10)
		table.sort(picks)
		equal(table.concat(picks, ","), "1,2,3,4,5,6,7,8,9,10")
	end,
})
