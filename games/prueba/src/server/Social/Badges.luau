--!strict
-- Insignias de Roblox que se ganan solas (Config/BadgeConfig): escucha las señales (Signals.Tracked) y
-- revisa los datos al entrar, así también se ponen al día los jugadores de antes. Lo entregado queda en
-- data.badges para no volver a llamar a la API (tiene límite por minuto). Si la llamada falla por red,
-- se borra la marca y se vuelve a intentar con la próxima señal o al volver a entrar. Las insignias sin
-- `badgeId` (todavía no creadas en el Dashboard) no hacen nada. API verificada en la referencia de
-- BadgeService (2026-11-02): AwardBadgeAsync (AwardBadge quedó obsoleto), solo desde el servidor.

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BadgeConfig = require(ReplicatedStorage.Shared.Config.BadgeConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local BoostService = require("../Boosts/BoostService")
local DataService = require("../Data/DataService")
local IndexService = require("../Retention/IndexService")
local Signals = require("../Signals")

local Badges = {}

-- Señales que cambian lo que miran las reglas por valor.
local RECHECK: { [string]: BadgeConfig.Rule } = {
	Rebirth = "rebirths",
	Discover = "index",
	DailyClaimed = "streak",
	Minutes = "playtime",
}

local function award(player: Player, badge: BadgeConfig.Badge)
	if badge.badgeId == 0 then
		return
	end
	local data = DataService.get(player)
	if not data or data.badges[badge.key] then
		return
	end
	-- Se marca antes de llamar: dos señales seguidas no piden la misma insignia dos veces.
	data.badges[badge.key] = true
	task.spawn(function()
		local ok, err = pcall(BadgeService.AwardBadgeAsync, BadgeService, player.UserId, badge.badgeId)
		if not ok then
			data.badges[badge.key] = nil
			warn("[Badges] no se pudo dar " .. badge.key .. ": " .. tostring(err))
		end
	end)
end

local function reached(player: Player, badge: BadgeConfig.Badge): boolean
	local data = DataService.get(player)
	local value = badge.value or 1
	if not data then
		return false
	end
	if badge.rule == "rebirths" then
		return data.rebirths >= value
	elseif badge.rule == "index" then
		local found = IndexService.counts(player)
		return found >= value
	elseif badge.rule == "streak" then
		return data.daily.streak >= value
	elseif badge.rule == "playtime" then
		return data.playtime.seconds >= value
	end
	return false
end

local function checkValues(player: Player, only: BadgeConfig.Rule?)
	for _, badge in BadgeConfig.LIST do
		if (only == nil or badge.rule == only) and reached(player, badge) then
			award(player, badge)
		end
	end
end

local function isDev(player: Player): boolean
	if table.find(GameConfig.DEV_USER_IDS, player.UserId) then
		return true
	end
	return game.CreatorType == Enum.CreatorType.User and game.CreatorId == player.UserId
end

local function social()
	local players = Players:GetPlayers()
	local devHere = false
	for _, player in players do
		if isDev(player) then
			devHere = true
		end
	end
	for _, player in players do
		for _, badge in BadgeConfig.LIST do
			if badge.rule == "friend" and BoostService.friends(player) > 0 then
				award(player, badge)
			elseif badge.rule == "dev" and devHere then
				award(player, badge)
			end
		end
	end
end

function Badges.start()
	DataService.StateChanged:Connect(function(player: Player, state: string)
		if state == "loading" then
			return
		end
		for _, badge in BadgeConfig.LIST do
			if badge.rule == "join" then
				award(player, badge)
			end
		end
		checkValues(player, nil)
	end)
	Signals.Tracked:Connect(function(player: Player, stat: string)
		for _, badge in BadgeConfig.LIST do
			if badge.rule == "signal" and badge.stat == stat then
				award(player, badge)
			end
		end
		local rule = RECHECK[stat]
		if rule then
			checkValues(player, rule :: BadgeConfig.Rule)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(BadgeConfig.CHECK_SECONDS)
			social()
		end
	end)
end

return Badges
