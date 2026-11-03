--!strict
-- Entrega cualquier premio (Types.Reward): moneda fija o "N minutos de tus ganancias", impulsos propios
-- o de servidor, tiradas de la ruleta e ítems del kit. Diario, regalos por tiempo, misiones, ruleta,
-- códigos, grupo, referidos, campañas y productos premian todos por acá, así el jugador siempre ve el
-- mismo popup con cada parte del premio (RewardShown) y las analíticas de economía quedan completas.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BoostConfig = require(ReplicatedStorage.Shared.Config.BoostConfig)
local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Types = require(ReplicatedStorage.Shared.Types)
local BoostService = require("../Boosts/BoostService")
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Signals = require("../Signals")

type Line = Types.RewardLine
-- Entrega un ítem del kit ("Egg:Rare", "Pet:Dragon"). Devuelve si pudo y la línea para el popup.
type ItemHandler = (Player, string, number) -> (boolean, Line?)
type IncomeProvider = (Player) -> number

local RewardService = {}

local INCOME_SECONDS = 1

local shown: RemoteEvent? = nil
local itemHandler: ItemHandler? = nil
local incomeProvider: IncomeProvider? = nil

-- El kit dice cuánto gana el jugador por segundo (base de los premios en minutos de ganancia).
function RewardService.setIncomeProvider(provider: IncomeProvider)
	incomeProvider = provider
end

-- El kit entrega sus ítems (huevos, mascotas, cañas...).
function RewardService.setItemHandler(handler: ItemHandler)
	itemHandler = handler
end

-- Lo que gana el jugador por segundo según el kit (0 sin kit). Las ganancias sin conexión usan este.
function RewardService.rawIncome(player: Player): number
	if incomeProvider then
		local ok, value = pcall(incomeProvider, player)
		if ok and typeof(value) == "number" and value == value and value ~= math.huge then
			return math.max(0, value)
		end
	end
	return 0
end

-- Base de los premios en minutos de ganancia, con piso para que nunca sean 0.
function RewardService.incomePerSecond(player: Player): number
	return math.max(EconomyConfig.MIN_INCOME_PER_SECOND, RewardService.rawIncome(player))
end

-- Monto de moneda de un premio, sin entregarlo (para mostrar "Get $1.2M" en la tienda).
function RewardService.amountOf(player: Player, reward: Types.Reward): number
	local amount = reward.amount or 0
	if reward.incomeMinutes then
		amount += reward.incomeMinutes * 60 * RewardService.incomePerSecond(player)
	end
	return math.floor(amount)
end

-- Entrega el premio y devuelve las partes otorgadas. `transaction` y `sku` van a las analíticas de
-- economía (IAP para compras, TimedReward para diarios y regalos...). Con `show`, el jugador ve el popup.
function RewardService.grant(
	player: Player,
	reward: Types.Reward,
	transaction: Enum.AnalyticsEconomyTransactionType,
	sku: string,
	show: boolean?
): { Line }
	local lines: { Line } = {}
	local data = DataService.get(player)
	if not data then
		return lines
	end
	local currencyId = reward.currency
	if currencyId then
		local currency = EconomyConfig.CURRENCIES[currencyId]
		local amount = RewardService.amountOf(player, reward)
		if currency and amount > 0 and CurrencyService.add(player, amount, transaction, sku, currencyId) then
			table.insert(lines, {
				icon = currency.icon,
				text = Format.money(amount, currency.symbol),
				kind = "currency",
				color = currency.color,
			})
		end
	end
	local boostId = reward.boost
	if boostId and reward.seconds and BoostService.grant(player, boostId, reward.seconds) then
		local def = BoostConfig.TIMED[boostId]
		table.insert(lines, { icon = def.icon, text = def.label .. " · " .. Format.short(reward.seconds), kind = "boost" })
	end
	local serverBoostId = reward.serverBoost
	if serverBoostId and reward.seconds and BoostService.grantServer(serverBoostId, reward.seconds) then
		local def = BoostConfig.SERVER[serverBoostId]
		table.insert(lines, { icon = def.icon, text = def.label .. " · " .. Format.short(reward.seconds), kind = "serverBoost" })
	end
	if reward.spins and reward.spins > 0 then
		data.spins.tickets += reward.spins
		table.insert(lines, { icon = "spin", text = "+" .. reward.spins .. (if reward.spins == 1 then " Spin" else " Spins"), kind = "spins" })
	end
	local item = reward.item
	if item then
		if itemHandler then
			local ok, given, line = pcall(itemHandler, player, item, reward.count or 1)
			if ok and given and line then
				table.insert(lines, line)
			elseif not ok then
				warn("[RewardService] error al entregar " .. item .. ": " .. tostring(given))
			end
		else
			warn("[RewardService] premio con item '" .. item .. "' sin kit que lo entregue")
		end
	end
	Signals.dirty(player)
	local remote = shown
	if show and remote and #lines > 0 then
		local popup: Types.RewardPopup = { title = reward.label or "REWARD!", lines = lines, source = sku }
		remote:FireClient(player, popup)
	end
	return lines
end

-- Muestra un popup de premio sin entregar nada (lo ya entregado por otro camino, como un robo).
function RewardService.show(player: Player, popup: Types.RewardPopup)
	if shown then
		shown:FireClient(player, popup)
	end
end

function RewardService.start()
	shown = Remotes.toClient("RewardShown")
	-- El HUD muestra "+$1.2K/s": el ingreso viaja como atributo (cambia seguido y no reenvía el estado).
	task.spawn(function()
		while true do
			task.wait(INCOME_SECONDS)
			for _, player in Players:GetPlayers() do
				local income = RewardService.rawIncome(player)
				if player:GetAttribute("Income") ~= income then
					player:SetAttribute("Income", income)
				end
			end
		end
	end)
end

return RewardService
