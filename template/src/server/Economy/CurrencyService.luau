--!strict
-- Monedas del jugador. Solo el servidor las cambia; cada cambio se registra como evento de economía en
-- AnalyticsService (fuentes y sumideros en Creator Analytics) y se reenvía al cliente.

local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local DataService = require("../Data/DataService")
local PlayerStateService = require("../PlayerStateService")
local Balance = require("./Balance")

local CurrencyService = {}

local function log(
	player: Player,
	flow: Enum.AnalyticsEconomyFlowType,
	amount: number,
	balance: number,
	transaction: Enum.AnalyticsEconomyTransactionType,
	sku: string?
)
	-- Las analíticas no deben cortar una compra: si fallan, solo se avisa.
	local ok, err = pcall(function()
		AnalyticsService:LogEconomyEvent(player, flow, EconomyConfig.CURRENCY, amount, balance, transaction.Name, sku)
	end)
	if not ok then
		warn("[CurrencyService] no se pudo registrar el evento de economía: " .. tostring(err))
	end
end

function CurrencyService.get(player: Player): number
	local data = DataService.get(player)
	return if data then data.coins else 0
end

-- `transaction` dice de dónde vienen (IAP, Gameplay, TimedReward, Onboarding...); `sku` identifica qué.
function CurrencyService.add(player: Player, amount: number, transaction: Enum.AnalyticsEconomyTransactionType, sku: string?): boolean
	local data = DataService.get(player)
	if not data then
		return false
	end
	local ok, balance = Balance.add(data.coins, amount, EconomyConfig.MAX_BALANCE)
	if not ok then
		return false
	end
	data.coins = balance
	log(player, Enum.AnalyticsEconomyFlowType.Source, amount, balance, transaction, sku)
	PlayerStateService.push(player)
	return true
end

function CurrencyService.spend(player: Player, amount: number, transaction: Enum.AnalyticsEconomyTransactionType, sku: string?): boolean
	local data = DataService.get(player)
	if not data then
		return false
	end
	local ok, balance = Balance.spend(data.coins, amount)
	if not ok then
		return false
	end
	data.coins = balance
	log(player, Enum.AnalyticsEconomyFlowType.Sink, amount, balance, transaction, sku)
	PlayerStateService.push(player)
	return true
end

return CurrencyService
