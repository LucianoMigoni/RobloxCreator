--!strict
-- De dónde llegó cada jugador y su premio de bienvenida (Player:GetJoinData):
-- - LaunchData de campañas de Ads Manager, share links y capturas compartidas → CampaignConfig, una vez
--   por código y jugador. El LaunchData viaja en la URL, así que se trata como texto no confiable.
-- - Referidos (ReferredByPlayerId, sistema oficial de invitaciones) → RetentionConfig.REFERRAL para el
--   invitado y, si está en el servidor, para quien invitó.
-- - Entradas desde un evento (GameJoinContext.EventId).
-- Cada entrada se registra como evento personalizado ("Join_<tipo>") para medir campañas en Creator
-- Analytics junto con la fuente "Sponsored ads".

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CampaignConfig = require(ReplicatedStorage.Shared.Config.CampaignConfig)
local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require("../Data/DataService")
local RewardService = require("../Rewards/RewardService")

local CampaignService = {}

local function log(player: Player, event: string, field: string?)
	local ok, err = pcall(function()
		if field then
			AnalyticsService:LogCustomEvent(player, event, 1, { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = field })
		else
			AnalyticsService:LogCustomEvent(player, event, 1)
		end
	end)
	if not ok then
		warn("[CampaignService] no se pudo registrar " .. event .. ": " .. tostring(err))
	end
end

-- El premio de un código: exacto o por prefijo.
function CampaignService.rewardFor(code: string): Types.Reward?
	local exact = CampaignConfig.CODES[code]
	if exact then
		return exact
	end
	for prefix, reward in CampaignConfig.PREFIXES do
		if string.sub(code, 1, #prefix) == prefix then
			return reward
		end
	end
	return nil
end

local function welcome(player: Player, joinData: { [string]: any })
	local data = DataService.get(player)
	if not data then
		return
	end
	local launch = joinData.LaunchData
	if typeof(launch) == "string" and #launch > 0 and #launch <= CampaignConfig.MAX_LENGTH then
		local code = string.lower(launch)
		local reward = CampaignService.rewardFor(code)
		log(player, "Join_Campaign", code)
		if reward and not data.campaignCodes[code] then
			data.campaignCodes[code] = true
			RewardService.grant(player, reward, Enum.AnalyticsEconomyTransactionType.Onboarding, "Campaign_" .. code, true)
		end
	end
	local referrer = joinData.ReferredByPlayerId
	if typeof(referrer) == "number" and referrer > 0 and referrer ~= player.UserId then
		log(player, "Join_Referral")
		if not data.referralRewarded then
			data.referralRewarded = true
			RewardService.grant(player, RetentionConfig.REFERRAL.invitee, Enum.AnalyticsEconomyTransactionType.Onboarding, "ReferralInvitee", true)
			local inviter = Players:GetPlayerByUserId(referrer)
			if inviter and DataService.canSave(inviter) then
				RewardService.grant(inviter, RetentionConfig.REFERRAL.inviter, Enum.AnalyticsEconomyTransactionType.Onboarding, "ReferralInviter", true)
			end
		end
	end
	local context = joinData.GameJoinContext
	if typeof(context) == "table" and context.EventId then
		log(player, "Join_Event", tostring(context.EventId))
	end
end

function CampaignService.start()
	DataService.StateChanged:Connect(function(player: Player, state: string)
		if state ~= "loaded" then
			return
		end
		local ok, joinData = pcall(player.GetJoinData, player)
		if ok and typeof(joinData) == "table" then
			-- Un momento después de cargar, para que el cliente ya escuche el popup.
			task.delay(2, welcome, player, joinData)
		end
	end)
end

return CampaignService
