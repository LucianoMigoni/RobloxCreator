--!strict
-- Regalos por tiempo jugado en el día ("FREE!" de los hits, RetentionConfig.PLAYTIME): el tiempo lo
-- cuenta el servidor, los primeros llegan rápido para enganchar y cada minuto jugado suma a las
-- misiones ("Play for 15 minutes").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local Playtime = require(ReplicatedStorage.Shared.Lib.Playtime)
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local RewardService = require("../Rewards/RewardService")
local Signals = require("../Signals")

local PlaytimeService = {}

local TICK_SECONDS = 1
local gifts: { number } = {}
for _, gift in RetentionConfig.PLAYTIME do
	table.insert(gifts, gift.seconds)
end

local function claim(player: Player, index: number): (boolean, string?)
	local data = DataService.get(player)
	if not data then
		return false, "LOADING"
	end
	if not Playtime.claim(data.playtime, gifts, index) then
		return false, "NOT_READY"
	end
	local reward = table.clone(RetentionConfig.PLAYTIME[index].reward)
	reward.label = reward.label or "FREE GIFT!"
	RewardService.grant(player, reward, Enum.AnalyticsEconomyTransactionType.TimedReward, "Playtime" .. index, true)
	return true
end

local function tick()
	local now = os.time()
	for _, player in Players:GetPlayers() do
		local data = DataService.get(player)
		if data then
			local readyBefore = #Playtime.ready(data.playtime, gifts)
			local day = data.playtime.day
			Playtime.add(data.playtime, now, TICK_SECONDS)
			if math.floor(data.playtime.seconds) % 60 == 0 then
				Signals.track(player, "Minutes", 1)
			end
			-- Solo se manda estado nuevo cuando se desbloquea un regalo o empieza otro día.
			if #Playtime.ready(data.playtime, gifts) ~= readyBefore or data.playtime.day ~= day then
				Signals.dirty(player)
			end
		end
	end
end

function PlaytimeService.start()
	Remotes.onInvoke("ClaimPlaytimeGift", {
		args = { Validate.number({ min = 1, max = #gifts, integer = true }) },
		rate = { count = 4, perSeconds = 1 },
	}, claim)
	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)
			tick()
		end
	end)
end

return PlaytimeService
