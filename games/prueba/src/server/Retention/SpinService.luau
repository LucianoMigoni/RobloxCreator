--!strict
-- Ruleta (RetentionConfig.SPIN): una tirada gratis cada FREE_EVERY segundos de tiempo real y tiradas
-- extra de premios o productos. El servidor elige la casilla (Lib/Rarity) y entrega el premio; el
-- cliente solo anima la rueda hasta esa casilla y después muestra el popup. Si las tiradas se venden
-- por Robux es aleatorio pago: la rueda muestra la probabilidad chica en cada casilla y ShopService
-- no las ofrece a quien PolicyService se lo prohíbe.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local Rarity = require(ReplicatedStorage.Shared.Lib.Rarity)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local RewardService = require("../Rewards/RewardService")
local Signals = require("../Signals")

local SpinService = {}

local random = Random.new()
local entries: { Rarity.Entry } = {}
for _, segment in RetentionConfig.SPIN.SEGMENTS do
	table.insert(entries, { id = segment.id, weight = segment.weight })
end

-- Devuelve (casilla, partes del premio) o (false, código).
local function spin(player: Player): (any, any)
	local data = DataService.get(player)
	if not data then
		return false, "LOADING"
	end
	local now = os.time()
	local source
	if now >= data.spins.nextFreeAt then
		data.spins.nextFreeAt = now + RetentionConfig.SPIN.FREE_EVERY
		source = "SpinFree"
	elseif data.spins.tickets > 0 then
		data.spins.tickets -= 1
		source = "SpinTicket"
	else
		return false, "NO_SPINS"
	end
	local chosen = Rarity.roll(entries, 1, function()
		return random:NextNumber()
	end)
	local index = 1
	for i, segment in RetentionConfig.SPIN.SEGMENTS do
		if segment.id == chosen.id then
			index = i
		end
	end
	local segment = RetentionConfig.SPIN.SEGMENTS[index]
	local lines: { Types.RewardLine } =
		RewardService.grant(player, segment.reward, Enum.AnalyticsEconomyTransactionType.TimedReward, source .. "_" .. segment.id, false)
	Signals.track(player, "Spin", 1)
	Signals.dirty(player)
	return index, lines
end

function SpinService.start()
	Remotes.onInvoke("SpinWheel", { args = {}, rate = { count = 1, perSeconds = 1 } }, spin)
end

return SpinService
