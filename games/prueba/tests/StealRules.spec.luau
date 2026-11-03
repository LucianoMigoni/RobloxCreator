--!strict
-- Cuándo se puede robar.
local TestKit = require("./TestKit")
local StealRules = require("../src/shared/Lib/StealRules")

local equal = TestKit.equal

local function base(): StealRules.Check
	return {
		now = 1000,
		own = false,
		locked = false,
		victimJoinedAt = 0,
		protectNewSeconds = 120,
		stolenAt = nil,
		recentSeconds = 60,
		isBest = false,
		protectBest = true,
		thiefFull = false,
		carrying = false,
	}
end

TestKit.run("StealRules", {
	["se puede robar sin nada en contra"] = function()
		local ok, reason = StealRules.check(base())
		equal(ok, true)
		equal(reason, nil)
	end,

	["cada protección tiene su motivo"] = function()
		local function reason(change: (StealRules.Check) -> ()): string?
			local c = base()
			change(c)
			local _, why = StealRules.check(c)
			return why
		end
		equal(reason(function(c) c.own = true end), "OWN")
		equal(reason(function(c) c.carrying = true end), "CARRYING")
		equal(reason(function(c) c.locked = true end), "LOCKED")
		equal(reason(function(c) c.victimJoinedAt = 950 end), "PROTECTED")
		equal(reason(function(c) c.stolenAt = 990 end), "RECENT")
		equal(reason(function(c) c.isBest = true end), "BEST")
		equal(reason(function(c) c.thiefFull = true end), "FULL")
		equal(reason(function(c)
			c.isBest = true
			c.protectBest = false
		end), nil, "sin protectBest se puede la mejor")
		equal(reason(function(c) c.stolenAt = 900 end), nil, "lo robado hace rato se puede")
	end,
})
