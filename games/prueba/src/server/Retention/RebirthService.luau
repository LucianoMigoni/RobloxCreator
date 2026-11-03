--!strict
-- Renacer (RetentionConfig.REBIRTH): cuesta cada vez más plata, la deja en 0 y suma un multiplicador
-- permanente de plata (BoostService lo aplica desde data.rebirths). El kit reinicia lo suyo (mejoras,
-- zonas) con RebirthService.onRebirth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local Progression = require(ReplicatedStorage.Shared.Lib.Progression)
local BoostService = require("../Boosts/BoostService")
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local RewardService = require("../Rewards/RewardService")
local Signals = require("../Signals")

local RebirthService = {}

local callbacks: { (Player, number) -> () } = {}

function RebirthService.cost(rebirths: number): number
	local cfg = RetentionConfig.REBIRTH
	return Progression.rebirthCost(cfg.base, cfg.growth, rebirths)
end

-- El kit reinicia lo suyo: callback(player, rebirthsNuevos).
function RebirthService.onRebirth(callback: (Player, number) -> ())
	table.insert(callbacks, callback)
end

local function rebirth(player: Player): (boolean, string?)
	local data = DataService.get(player)
	if not data then
		return false, "LOADING"
	end
	local cfg = RetentionConfig.REBIRTH
	local cost = RebirthService.cost(data.rebirths)
	if CurrencyService.get(player, cfg.currency) < cost then
		return false, "NOT_ENOUGH"
	end
	CurrencyService.set(player, cfg.currency, 0)
	data.rebirths += 1
	for _, callback in callbacks do
		xpcall(callback, function(err)
			warn("[RebirthService] error en un reinicio del kit: " .. tostring(err))
		end, player, data.rebirths)
	end
	local reward = table.clone(cfg.reward)
	reward.label = reward.label or ("REBIRTH " .. data.rebirths .. "!")
	RewardService.grant(player, reward, Enum.AnalyticsEconomyTransactionType.Gameplay, "Rebirth", true)
	player:SetAttribute("Rebirths", data.rebirths)
	BoostService.refresh(player)
	Signals.track(player, "Rebirth", 1)
	Signals.dirty(player)
	return true
end

function RebirthService.start()
	Remotes.onInvoke("RequestRebirth", { args = {}, rate = { count = 2, perSeconds = 2 } }, rebirth)
	DataService.StateChanged:Connect(function(player: Player, state: string)
		local data = DataService.get(player)
		if state ~= "loading" and data then
			player:SetAttribute("Rebirths", data.rebirths)
		end
	end)
end

return RebirthService
