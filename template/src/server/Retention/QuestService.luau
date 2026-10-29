--!strict
-- Misiones diarias (RetentionConfig.QUESTS, Lib/Quests): 3 por día UTC, iguales en todos los servidores
-- para cada jugador, avanzan con Signals.track (los sistemas y los kits mandan sus eventos) y se
-- reclaman una por una; completar todas da el bono.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local Quests = require(ReplicatedStorage.Shared.Lib.Quests)
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local RewardService = require("../Rewards/RewardService")
local Signals = require("../Signals")

local QuestService = {}

local REFRESH_SECONDS = 30
local pool: { Quests.Def } = {}
local byId: { [string]: RetentionConfig.QuestDef } = {}
for _, def in RetentionConfig.QUESTS.pool do
	table.insert(pool, { id = def.id, text = def.text, stat = def.stat, target = def.target })
	byId[def.id] = def
end

local function refresh(player: Player)
	local data = DataService.get(player)
	if data and Quests.refresh(data.quests, pool, os.time(), player.UserId, RetentionConfig.QUESTS.count) then
		Signals.dirty(player)
	end
end

local function claim(player: Player, id: string): (boolean, string?)
	local data = DataService.get(player)
	if not data then
		return false, "LOADING"
	end
	refresh(player)
	if not Quests.claim(data.quests, pool, id) then
		return false, "NOT_READY"
	end
	local reward = table.clone(byId[id].reward)
	reward.label = reward.label or "QUEST COMPLETE!"
	RewardService.grant(player, reward, Enum.AnalyticsEconomyTransactionType.TimedReward, "Quest_" .. id, true)
	Signals.track(player, "QuestClaimed", 1)
	return true
end

local function claimBonus(player: Player): (boolean, string?)
	local data = DataService.get(player)
	if not data then
		return false, "LOADING"
	end
	if not Quests.claimBonus(data.quests) then
		return false, "NOT_READY"
	end
	RewardService.grant(player, RetentionConfig.QUESTS.bonus, Enum.AnalyticsEconomyTransactionType.TimedReward, "QuestBonus", true)
	return true
end

function QuestService.start()
	local ids = {}
	for id in byId do
		table.insert(ids, id)
	end
	Remotes.onInvoke("ClaimQuest", { args = { Validate.oneOf(ids) }, rate = { count = 4, perSeconds = 1 } }, claim)
	Remotes.onInvoke("ClaimQuestBonus", { args = {}, rate = { count = 2, perSeconds = 1 } }, claimBonus)
	DataService.StateChanged:Connect(function(player: Player, state: string)
		if state ~= "loading" then
			refresh(player)
		end
	end)
	Signals.Tracked:Connect(function(player: Player, stat: string, amount: number)
		local data = DataService.get(player)
		if not data then
			return
		end
		local done = Quests.track(data.quests, pool, stat, amount)
		if #done > 0 then
			Signals.dirty(player)
		end
	end)
	-- Al pasar la medianoche UTC cambian las misiones de quien sigue jugando.
	task.spawn(function()
		while true do
			task.wait(REFRESH_SECONDS)
			for _, player in Players:GetPlayers() do
				refresh(player)
			end
		end
	end)
end

return QuestService
