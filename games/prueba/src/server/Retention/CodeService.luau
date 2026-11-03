--!strict
-- Códigos canjeables (RetentionConfig.CODES, Lib/Codes): uno por jugador, sin distinguir mayúsculas y
-- con vencimiento opcional. Se publican en la página del juego y en el grupo (nunca links a Discord).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local Codes = require(ReplicatedStorage.Shared.Lib.Codes)
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local RewardService = require("../Rewards/RewardService")

local CodeService = {}

local MAX_LENGTH = 30

-- Devuelve "OK", "INVALID", "EXPIRED", "USED" o "LOADING".
local function redeem(player: Player, text: string): string
	local data = DataService.get(player)
	if not data then
		return "LOADING"
	end
	local status = Codes.check(RetentionConfig.CODES, data.codes, text, os.time())
	if status ~= "OK" then
		return status
	end
	local key = Codes.normalize(text)
	data.codes[key] = true
	local reward = table.clone(RetentionConfig.CODES[key].reward)
	reward.label = reward.label or "CODE REDEEMED!"
	RewardService.grant(player, reward, Enum.AnalyticsEconomyTransactionType.TimedReward, "Code_" .. key, true)
	return "OK"
end

function CodeService.start()
	Remotes.onInvoke("RedeemCode", {
		args = { Validate.string({ maxLength = MAX_LENGTH, minLength = 1 }) },
		rate = { count = 3, perSeconds = 5 },
	}, redeem)
end

return CodeService
