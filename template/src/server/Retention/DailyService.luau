--!strict
-- Premio diario con racha (RetentionConfig.DAILY, Lib/DailyRewards): uno por día UTC; el séptimo es el
-- grande y saltear un día reinicia la racha. El HUD muestra el globito cuando hay para reclamar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local DailyRewards = require(ReplicatedStorage.Shared.Lib.DailyRewards)
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local RewardService = require("../Rewards/RewardService")
local Signals = require("../Signals")

local DailyService = {}

function DailyService.status(player: Player): DailyRewards.Status?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	return DailyRewards.status(data.daily, os.time(), #RetentionConfig.DAILY)
end

local function claim(player: Player): (boolean, string?)
	local data = DataService.get(player)
	if not data then
		return false, "LOADING"
	end
	local ok, slot = DailyRewards.claim(data.daily, os.time(), #RetentionConfig.DAILY)
	if not ok or not slot then
		return false, "ALREADY_CLAIMED"
	end
	local reward = table.clone(RetentionConfig.DAILY[slot])
	reward.label = reward.label or ("DAY " .. slot .. "!")
	RewardService.grant(player, reward, Enum.AnalyticsEconomyTransactionType.TimedReward, "Daily" .. slot, true)
	Signals.track(player, "DailyClaimed", 1)
	return true
end

function DailyService.start()
	Remotes.onInvoke("ClaimDailyReward", { args = {}, rate = { count = 2, perSeconds = 1 } }, claim)
end

return DailyService
