--!strict
-- Monedas del jugador (EconomyConfig.CURRENCIES). Solo el servidor las cambia. Cada saldo se refleja en
-- un atributo del jugador ("Money", "Gems") que el HUD escucha: la plata que sube cada segundo no
-- reenvía todo el estado. Los eventos de economía se agrupan por minuto: AnalyticsService admite
-- 120 + 20 × jugadores eventos por minuto y un ingreso por segundo lo pasaría enseguida.

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local DataService = require("../Data/DataService")
local Signals = require("../Signals")
local Balance = require("./Balance")

local CurrencyService = {}

local changed = Instance.new("BindableEvent")
-- (player, currency, balance, delta): para la tabla de jugadores, objetivos y efectos.
CurrencyService.Changed = changed.Event

type Pending = { [string]: { amount: number, flow: Enum.AnalyticsEconomyFlowType, transaction: string, sku: string? } }

local FLUSH_SECONDS = 60
local pending: { [Player]: Pending } = {}
local fractions: { [Player]: { [string]: number } } = {}

local function log(player: Player, currency: string, flow: Enum.AnalyticsEconomyFlowType, amount: number, transaction: string, sku: string?)
	local data = DataService.get(player)
	local balance = if data then data.currencies[currency] or 0 else 0
	-- Las analíticas no deben cortar una compra: si fallan, solo se avisa.
	local ok, err = pcall(function()
		AnalyticsService:LogEconomyEvent(player, flow, currency, amount, balance, transaction, sku)
	end)
	if not ok then
		warn("[CurrencyService] no se pudo registrar el evento de economía: " .. tostring(err))
	end
end

local function queue(player: Player, currency: string, flow: Enum.AnalyticsEconomyFlowType, amount: number, transaction: string, sku: string?)
	local key = currency .. "|" .. flow.Name .. "|" .. transaction .. "|" .. (sku or "")
	local byPlayer = pending[player] or {}
	pending[player] = byPlayer
	local entry = byPlayer[key]
	if entry then
		entry.amount += amount
	else
		byPlayer[key] = { amount = amount, flow = flow, transaction = transaction, sku = sku }
	end
end

local function flush(player: Player)
	local byPlayer = pending[player]
	pending[player] = nil
	if not byPlayer then
		return
	end
	for key, entry in byPlayer do
		local currency = string.split(key, "|")[1]
		log(player, currency, entry.flow, math.floor(entry.amount), entry.transaction, entry.sku)
	end
end

local function setAttribute(player: Player, currency: string, balance: number)
	player:SetAttribute(currency, balance)
end

function CurrencyService.get(player: Player, currency: string?): number
	local data = DataService.get(player)
	return if data then data.currencies[currency or EconomyConfig.MAIN] or 0 else 0
end

-- Suma `amount` (puede tener decimales: se acumulan hasta formar unidades). `transaction` es un
-- Enum.AnalyticsEconomyTransactionType (IAP, Gameplay, TimedReward, Onboarding, Shop...); `sku`, qué fue.
-- `batch` = true agrupa el evento de analíticas por minuto (ingresos por segundo).
function CurrencyService.add(player: Player, amount: number, transaction: Enum.AnalyticsEconomyTransactionType, sku: string?, currency: string?, batch: boolean?): boolean
	local data = DataService.get(player)
	local id = currency or EconomyConfig.MAIN
	if not data or EconomyConfig.CURRENCIES[id] == nil or amount ~= amount or amount <= 0 or amount == math.huge then
		return false
	end
	local carry = fractions[player] or {}
	fractions[player] = carry
	local total = amount + (carry[id] or 0)
	local whole = math.floor(total)
	carry[id] = total - whole
	if whole <= 0 then
		return true
	end
	local ok, balance = Balance.add(data.currencies[id] or 0, whole, EconomyConfig.MAX_BALANCE)
	if not ok then
		return false
	end
	data.currencies[id] = balance
	setAttribute(player, id, balance)
	if batch then
		queue(player, id, Enum.AnalyticsEconomyFlowType.Source, whole, transaction.Name, sku)
	else
		log(player, id, Enum.AnalyticsEconomyFlowType.Source, whole, transaction.Name, sku)
	end
	changed:Fire(player, id, balance, whole)
	-- Lo ganado jugando hace avanzar misiones y objetivos ("Earn $10K"); lo comprado o regalado, no.
	if id == EconomyConfig.MAIN and transaction == Enum.AnalyticsEconomyTransactionType.Gameplay then
		Signals.track(player, "MoneyEarned", whole)
	end
	return true
end

function CurrencyService.spend(player: Player, amount: number, transaction: Enum.AnalyticsEconomyTransactionType, sku: string?, currency: string?): boolean
	local data = DataService.get(player)
	local id = currency or EconomyConfig.MAIN
	if not data or EconomyConfig.CURRENCIES[id] == nil then
		return false
	end
	local ok, balance = Balance.spend(data.currencies[id] or 0, math.ceil(amount))
	if not ok then
		return false
	end
	data.currencies[id] = balance
	setAttribute(player, id, balance)
	log(player, id, Enum.AnalyticsEconomyFlowType.Sink, math.ceil(amount), transaction.Name, sku)
	changed:Fire(player, id, balance, -math.ceil(amount))
	return true
end

-- Deja un saldo en un valor (renacer lo vuelve a 0). No registra analíticas: no es fuente ni sumidero.
function CurrencyService.set(player: Player, currency: string, value: number)
	local data = DataService.get(player)
	if not data or EconomyConfig.CURRENCIES[currency] == nil then
		return
	end
	local before = data.currencies[currency] or 0
	data.currencies[currency] = math.max(0, value)
	setAttribute(player, currency, data.currencies[currency])
	changed:Fire(player, currency, data.currencies[currency], data.currencies[currency] - before)
end

function CurrencyService.start()
	DataService.StateChanged:Connect(function(player: Player)
		local data = DataService.get(player)
		if data then
			for id in EconomyConfig.CURRENCIES do
				setAttribute(player, id, data.currencies[id] or 0)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		flush(player)
		fractions[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(FLUSH_SECONDS)
			for player in pending do
				flush(player)
			end
		end
	end)
end

return CurrencyService
