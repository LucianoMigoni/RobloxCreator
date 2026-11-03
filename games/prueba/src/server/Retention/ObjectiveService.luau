--!strict
-- Cadena de objetivos arriba al centro (ObjectiveConfig, Lib/Objectives): enseña el juego sin pantallas
-- de tutorial y después sigue con metas que crecen. Reemplaza al embudo de onboarding: "Joined" y los
-- primeros objetivos se registran con LogOnboardingFunnelStepEvent para ver en Creator Analytics en qué
-- paso se van los jugadores nuevos (el rebote antes de 60 s es lo que más castiga Home).

local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObjectiveConfig = require(ReplicatedStorage.Shared.Config.ObjectiveConfig)
local Objectives = require(ReplicatedStorage.Shared.Lib.Objectives)
local DataService = require("../Data/DataService")
local RewardService = require("../Rewards/RewardService")
local Signals = require("../Signals")

local ObjectiveService = {}

local function funnel(player: Player, step: number, name: string)
	if step > ObjectiveConfig.FUNNEL_STEPS then
		return
	end
	local ok, err = pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, name)
	end)
	if not ok then
		warn("[ObjectiveService] no se pudo registrar el paso del embudo: " .. tostring(err))
	end
end

-- El objetivo actual tal como lo muestra el HUD (nil si la cadena terminó y no hay infinitos).
function ObjectiveService.current(player: Player): Objectives.Def?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	return Objectives.current(ObjectiveConfig.CHAIN, ObjectiveConfig.ENDLESS, data.objective)
end

function ObjectiveService.start()
	DataService.StateChanged:Connect(function(player: Player, state: string)
		local data = DataService.get(player)
		if state == "loaded" and data and data.objective.index == 1 and data.objective.progress == 0 then
			funnel(player, 1, "Joined")
		end
	end)
	Signals.Tracked:Connect(function(player: Player, stat: string, amount: number)
		local data = DataService.get(player)
		if not data then
			return
		end
		local index = data.objective.index
		local before = data.objective.progress
		local done = Objectives.track(ObjectiveConfig.CHAIN, ObjectiveConfig.ENDLESS, data.objective, stat, amount)
		if done then
			-- Paso 1 es "Joined": el objetivo N es el paso N + 1.
			funnel(player, index + 1, done.id)
			local reward = table.clone(ObjectiveConfig.REWARD)
			reward.label = reward.label or "OBJECTIVE COMPLETE!"
			RewardService.grant(player, reward, Enum.AnalyticsEconomyTransactionType.Onboarding, "Objective_" .. done.id, true)
			Signals.dirty(player)
		elseif data.objective.progress ~= before then
			Signals.dirty(player)
		end
	end)
end

return ObjectiveService
