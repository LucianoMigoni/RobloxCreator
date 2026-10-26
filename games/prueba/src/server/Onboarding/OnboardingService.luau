--!strict
-- Embudo de onboarding (OnboardingConfig.STEPS): registra cada paso con AnalyticsService para ver en
-- Creator Analytics dónde se van los jugadores nuevos. El paso alcanzado se guarda en los datos; el
-- premio final solo se da si el último paso lo confirma el servidor.

local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OnboardingConfig = require(ReplicatedStorage.Shared.Config.OnboardingConfig)
local DataService = require("../Data/DataService")
local CurrencyService = require("../Economy/CurrencyService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local Steps = require("./Steps")

local OnboardingService = {}

local function advance(player: Player, name: string, source: "server" | "client")
	local data = DataService.get(player)
	if not data then
		return
	end
	local index = Steps.advance(OnboardingConfig.STEPS, data.onboardingStep, name, source)
	if not index then
		return
	end
	data.onboardingStep = index
	local ok, err = pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, index, name)
	end)
	if not ok then
		warn("[OnboardingService] no se pudo registrar el paso: " .. tostring(err))
	end
	local last = OnboardingConfig.STEPS[#OnboardingConfig.STEPS]
	if index == #OnboardingConfig.STEPS and last.source == "server" then
		CurrencyService.add(player, OnboardingConfig.COMPLETION_REWARD, Enum.AnalyticsEconomyTransactionType.Onboarding)
	end
end

-- Para los pasos que confirma el servidor (compras, logros).
function OnboardingService.complete(player: Player, stepName: string)
	advance(player, stepName, "server")
end

function OnboardingService.start()
	local clientSteps = {}
	for _, step in OnboardingConfig.STEPS do
		if step.source == "client" then
			table.insert(clientSteps, step.name)
		end
	end
	Remotes.onEvent("ReportOnboardingStep", {
		args = { Validate.oneOf(clientSteps) },
		rate = OnboardingConfig.REPORT_RATE,
	}, function(player: Player, stepName: string)
		advance(player, stepName, "client")
	end)
	DataService.StateChanged:Connect(function(player: Player, state: string)
		if state ~= "loading" then
			OnboardingService.complete(player, OnboardingConfig.STEPS[1].name)
		end
	end)
end

return OnboardingService
