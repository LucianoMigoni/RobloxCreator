--!strict
-- Grupo del juego (GameConfig.GROUP_ID): premio único por unirse (RetentionConfig.GROUP_REWARD) además
-- del bono permanente de BoostConfig.GROUP. Premiar la unión al grupo está permitido; el like no.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local BoostService = require("../Boosts/BoostService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local RewardService = require("../Rewards/RewardService")

local GroupService = {}

-- Devuelve "OK", "NO_GROUP", "CLAIMED", "NOT_MEMBER", "LOADING" o "ERROR".
local function claim(player: Player): string
	local data = DataService.get(player)
	if not data then
		return "LOADING"
	end
	if GameConfig.GROUP_ID == 0 then
		return "NO_GROUP"
	end
	if data.groupClaimed then
		return "CLAIMED"
	end
	local ok, member = pcall(player.IsInGroupAsync, player, GameConfig.GROUP_ID)
	if not ok then
		return "ERROR"
	end
	if not member then
		return "NOT_MEMBER"
	end
	data.groupClaimed = true
	RewardService.grant(player, RetentionConfig.GROUP_REWARD, Enum.AnalyticsEconomyTransactionType.TimedReward, "Group", true)
	BoostService.refresh(player)
	return "OK"
end

function GroupService.start()
	Remotes.onInvoke("ClaimGroupReward", { args = {}, rate = { count = 2, perSeconds = 5 } }, claim)
end

return GroupService
