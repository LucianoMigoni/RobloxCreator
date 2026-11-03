--!strict
-- Lo que el cliente ve de sus datos (Types.PlayerSnapshot): lo pide al entrar (GetPlayerState) y el
-- servidor manda uno nuevo cuando algo cambia (Signals.dirty), agrupando los cambios seguidos para no
-- inundar la red. Los números que cambian cada segundo (monedas, multiplicadores, ingreso) viajan como
-- atributos del jugador. Nunca incluye recibos ni otros datos internos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConfig = require(ReplicatedStorage.Shared.Config.NetConfig)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local BoostService = require("./Boosts/BoostService")
local DataService = require("./Data/DataService")
local Remotes = require("./Net/Remotes")
local DailyService = require("./Retention/DailyService")
local IndexService = require("./Retention/IndexService")
local ObjectiveService = require("./Retention/ObjectiveService")
local RebirthService = require("./Retention/RebirthService")
local ShopService = require("./Shop/ShopService")
local Signals = require("./Signals")

local PlayerStateService = {}

local PUSH_SECONDS = 0.25

local changed: RemoteEvent? = nil
local dirty: { [Player]: boolean } = {}
local kitProvider: ((Player) -> any)? = nil

-- El kit agrega lo suyo al estado (unidades, huevos, velocidad...) en `snapshot.kit`.
function PlayerStateService.setKitProvider(provider: (Player) -> any)
	kitProvider = provider
end

local function clone<T>(t: T): T
	return table.clone(t :: any) :: any
end

function PlayerStateService.snapshot(player: Player): Types.PlayerSnapshot?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	local multipliers: { Types.MultiplierView } = {}
	for _, source in BoostService.sources(player) do
		local view: Types.MultiplierView = { stat = source.stat, kind = source.kind, value = source.value, label = source.label }
		table.insert(multipliers, view)
	end
	local owned = {}
	for _, pass in ShopConfig.PASSES do
		if ShopService.ownsPass(player, pass.key) then
			table.insert(owned, pass.key)
		end
	end
	local objective = nil
	local def = ObjectiveService.current(player)
	if def then
		objective = { text = def.text, progress = data.objective.progress, target = def.target, money = def.money == true }
	end
	local found, total = IndexService.counts(player)
	local daily = DailyService.status(player) or { canClaim = false, slot = 1, streak = 0, nextIn = 0 }
	local kit = nil
	if kitProvider then
		local ok, result = pcall(kitProvider, player)
		if ok then
			kit = result
		else
			warn("[PlayerStateService] error en el estado del kit: " .. tostring(result))
		end
	end
	return {
		currencies = clone(data.currencies),
		inventory = clone(data.inventory),
		savesProgress = DataService.canSave(player),
		multipliers = multipliers,
		boosts = BoostService.active(player),
		daily = daily,
		playtime = { seconds = data.playtime.seconds, claimed = clone(data.playtime.claimed), day = data.playtime.day },
		quests = {
			ids = clone(data.quests.ids),
			progress = clone(data.quests.progress),
			claimed = clone(data.quests.claimed),
			bonusClaimed = data.quests.bonusClaimed,
		},
		spins = { tickets = data.spins.tickets, nextFreeAt = data.spins.nextFreeAt },
		objective = objective,
		rebirths = data.rebirths,
		rebirthCost = RebirthService.cost(data.rebirths),
		index = { found = found, total = total, keys = clone(data.index), zones = IndexService.zones(player) },
		groupClaimed = data.groupClaimed,
		ownedPasses = owned,
		boughtOnce = clone(data.boughtOnce),
		giftTokens = clone(data.giftTokens),
		pendingOffline = data.pendingOffline,
		settings = clone(data.settings),
		kit = kit,
	}
end

function PlayerStateService.push(player: Player)
	local snapshot = PlayerStateService.snapshot(player)
	if changed and snapshot then
		changed:FireClient(player, snapshot)
	end
end

function PlayerStateService.start()
	changed = Remotes.toClient("StateChanged")
	Remotes.onInvoke("GetPlayerState", { args = {}, rate = NetConfig.STATE_RATE }, function(player: Player)
		DataService.waitForData(player)
		return PlayerStateService.snapshot(player)
	end)
	Signals.Dirtied:Connect(function(player: Player)
		dirty[player] = true
	end)
	DataService.StateChanged:Connect(function(player: Player)
		dirty[player] = true
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		dirty[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(PUSH_SECONDS)
			for player in dirty do
				dirty[player] = nil
				if player.Parent then
					PlayerStateService.push(player)
				end
			end
		end
	end)
end

return PlayerStateService
