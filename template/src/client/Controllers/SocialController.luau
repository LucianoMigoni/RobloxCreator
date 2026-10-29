--!strict
-- Lo social que mueve el algoritmo (jugar con amigos, volver) dentro de las reglas:
-- - Grupo: botón con premio por unirse (permitido y verificable). Abre el aviso oficial de unirse
--   (GroupService:PromptJoinAsync) y después cobra con ClaimGroupReward.
-- - Invitar amigos: aviso oficial de invitación (SocialService); los referidos premian a los dos.
-- - Pedir el like sin premio (premiar el like no está permitido) y ofrecer las notificaciones del
--   juego (ExperienceNotificationService), sin bloquear nada ni dar algo a cambio.

local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local PlayerState = require("../PlayerState")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local SocialController = {}

local player = Players.LocalPlayer

function SocialController.start(hud: Hud.Hud)
	-- Grupo
	if GameConfig.GROUP_ID ~= 0 then
		local button = hud.addButton("right", { name = "Group", label = UiText.GROUP, icon = "friends", variant = "Info", layoutOrder = 3 })
		UIKit.setBadge(button, "!")
		local stop = Juice.wiggle(button, 5)
		button.Activated:Connect(function()
			Sound.play("Click")
			local ok, status = pcall(function()
				return Net.func("ClaimGroupReward"):InvokeServer()
			end)
			if ok and status == "NOT_MEMBER" then
				-- Aviso oficial para unirse sin salir del juego; si acepta, se cobra de nuevo.
				local joined, membership = pcall(GroupService.PromptJoinAsync, GroupService, GameConfig.GROUP_ID)
				if joined and membership == Enum.GroupMembershipStatus.Joined then
					pcall(function()
						return Net.func("ClaimGroupReward"):InvokeServer()
					end)
				else
					UIKit.notify(hud.screen, UiText.NOT_MEMBER, "Info", "friends")
				end
			elseif not ok or (status ~= "OK" and status ~= "CLAIMED") then
				Sound.play("Error")
			end
		end)
		PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
			if state.groupClaimed then
				button.Visible = false
				stop()
			end
		end)
	end

	-- Invitar amigos
	local invite = hud.addButton("right", { name = "Invite", label = UiText.INVITE, icon = "friends", variant = "Pink", layoutOrder = 5 })
	invite.Activated:Connect(function()
		Sound.play("Click")
		task.spawn(function()
			local ok, can = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
			if ok and can then
				pcall(SocialService.PromptGameInvite, SocialService, player)
			end
		end)
	end)

	-- Recordatorios sin premio
	task.delay(RetentionConfig.NOTIFY_PROMPT_AFTER, function()
		local ok, can = pcall(ExperienceNotificationService.CanPromptOptInAsync, ExperienceNotificationService)
		if ok and can then
			pcall(ExperienceNotificationService.PromptOptIn, ExperienceNotificationService)
		end
	end)
	task.delay(RetentionConfig.LIKE_REMINDER_AFTER, function()
		UIKit.notify(hud.screen, UiText.LIKE_REMINDER, "Accept", "star")
	end)
end

return SocialController
