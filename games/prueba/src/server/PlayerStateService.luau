--!strict
-- Lo que el cliente ve de sus datos: lo pide al entrar (GetPlayerState) y el servidor lo reenvía en
-- cada cambio (StateChanged). Nunca incluye recibos ni otros datos internos.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConfig = require(ReplicatedStorage.Shared.Config.NetConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require("./Data/DataService")
local Remotes = require("./Net/Remotes")

local PlayerStateService = {}

local changed: RemoteEvent? = nil

function PlayerStateService.snapshot(player: Player): Types.PlayerSnapshot?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	return {
		coins = data.coins,
		inventory = table.clone(data.inventory),
		savesProgress = DataService.canSave(player),
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
end

return PlayerStateService
