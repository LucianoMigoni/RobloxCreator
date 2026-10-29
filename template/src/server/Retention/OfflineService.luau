--!strict
-- Ganancias sin conexión (RetentionConfig.OFFLINE, Lib/Progression.offline): al volver, una parte de
-- lo que el jugador ganaba por segundo, con tope de horas. Se entregan al entrar con el popup
-- "WELCOME BACK!" y la oferta de duplicarlas (producto OfflineDouble de ShopConfig). El ingreso por
-- segundo lo informa el kit (RewardService.setIncomeProvider).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Progression = require(ReplicatedStorage.Shared.Lib.Progression)
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local RewardService = require("../Rewards/RewardService")
local Signals = require("../Signals")

local OfflineService = {}

-- Cada cuánto se anota la última vez visto: si el servidor se cae, no se pierde más que esto.
local MARK_SECONDS = 30

local function mark(player: Player)
	local data = DataService.get(player)
	if data and DataService.canSave(player) then
		data.lastSeen = os.time()
		data.lastIncome = RewardService.rawIncome(player)
	end
end

local function welcome(player: Player)
	local data = DataService.get(player)
	if not data or data.lastSeen == 0 then
		return
	end
	local cfg = RetentionConfig.OFFLINE
	local earned, seconds = Progression.offline(data.lastSeen, os.time(), data.lastIncome, cfg.rate, cfg.capSeconds, cfg.minSeconds)
	data.pendingOffline = 0
	earned = math.floor(earned)
	if earned <= 0 then
		return
	end
	local main = EconomyConfig.MAIN
	if CurrencyService.add(player, earned, Enum.AnalyticsEconomyTransactionType.TimedReward, "Offline", main) then
		data.pendingOffline = earned
		local currency = EconomyConfig.CURRENCIES[main]
		RewardService.show(player, {
			title = "WELCOME BACK!",
			lines = {
				{ icon = currency.icon, text = Format.money(earned, currency.symbol), kind = "currency", color = currency.color },
				{ icon = "timer", text = "Earned while away · " .. Format.duration(seconds), kind = "info" },
			},
			source = "Offline",
		})
		Signals.dirty(player)
	end
end

-- Lo que pagó el producto OfflineDouble: vuelve a dar lo ganado sin conexión, una vez.
function OfflineService.double(player: Player): boolean
	local data = DataService.get(player)
	if not data or data.pendingOffline <= 0 then
		return false
	end
	local amount = data.pendingOffline
	data.pendingOffline = 0
	Signals.dirty(player)
	return CurrencyService.add(player, amount, Enum.AnalyticsEconomyTransactionType.IAP, "OfflineDouble", EconomyConfig.MAIN)
end

function OfflineService.start()
	DataService.StateChanged:Connect(function(player: Player, state: string)
		if state == "loaded" then
			-- Un momento después de cargar: el kit ya tiene el ingreso y el cliente ya escucha el popup.
			task.delay(3, welcome, player)
		end
	end)
	Players.PlayerRemoving:Connect(mark)
	task.spawn(function()
		while true do
			task.wait(MARK_SECONDS)
			for _, player in Players:GetPlayers() do
				mark(player)
			end
		end
	end)
end

return OfflineService
