--!strict
-- Lo social que mueve el algoritmo (jugar con amigos, volver) dentro de las reglas:
-- - Grupo: botón con premio por unirse (permitido y verificable). Abre el aviso oficial de unirse
--   (GroupService:PromptJoinAsync) y después cobra con ClaimGroupReward. El cofre del mapa
--   (KitGroupChest) hace lo mismo con un prompt; también Bus "ClaimGroup".
-- - Invitar amigos: aviso oficial de invitación (SocialService); los referidos premian a los dos.
-- - Pedir el like sin premio (premiar el like no está permitido) y ofrecer las notificaciones del
--   juego (ExperienceNotificationService), sin bloquear nada ni dar algo a cambio.

local CollectionService = game:GetService("CollectionService")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local BoostConfig = require(ReplicatedStorage.Shared.Config.BoostConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Net = require(ReplicatedStorage.Shared.Net)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local PlayerState = require("../PlayerState")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local SocialController = {}

local player = Players.LocalPlayer

function SocialController.start(hud: Hud.Hud)
	-- Grupo: cobrar el premio (si no es miembro, el aviso oficial para unirse y se cobra de nuevo).
	local function claimGroup()
		local ok, status = pcall(function()
			return Net.func("ClaimGroupReward"):InvokeServer()
		end)
		if ok and status == "NOT_MEMBER" then
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
	end
	if GameConfig.GROUP_ID ~= 0 then
		Bus.handle("ClaimGroup", claimGroup)
		local button = hud.addButton("right", { name = "Group", label = UiText.GROUP, icon = "friends", variant = "Info", layoutOrder = 3 })
		UIKit.setBadge(button, "!")
		local stop = Juice.wiggle(button, 5)
		button.Activated:Connect(function()
			Sound.play("Click")
			claimGroup()
		end)
		-- Cofre del mapa: prompt local; ya cobrado, dice CLAIMED y no se usa más.
		local claimed = false
		local prompts: { [Instance]: ProximityPrompt } = {}
		local function markClaimed(chest: Instance)
			local prompt = prompts[chest]
			if prompt then
				prompt.Enabled = false
			end
			chest:SetAttribute("Text", UiText.CHEST_CLAIMED)
			chest:SetAttribute("Variant", "Neutral")
		end
		local function addChest(chest: Instance)
			local part = if chest:IsA("BasePart") then chest elseif chest:IsA("Model") then chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart", true) else nil
			if not part or prompts[chest] then
				return
			end
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "ChestPrompt"
			prompt.ActionText = UiText.CHEST_PROMPT
			prompt.ObjectText = UiText.CHEST_OBJECT
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = 12
			prompt.Parent = part
			prompts[chest] = prompt
			prompt.Triggered:Connect(function()
				Sound.play("Click")
				claimGroup()
			end)
			if claimed then
				markClaimed(chest)
			end
		end
		for _, chest in CollectionService:GetTagged(Tags.GROUP_CHEST) do
			addChest(chest)
		end
		CollectionService:GetInstanceAddedSignal(Tags.GROUP_CHEST):Connect(addChest)
		PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
			if state.groupClaimed and not claimed then
				claimed = true
				button.Visible = false
				stop()
				for chest in prompts do
					markClaimed(chest)
				end
			end
		end)
	end

	-- Invitar amigos: el bono por amigo en el servidor es real (BoostConfig.FRIENDS), así que se dice.
	local function invite()
		task.spawn(function()
			local ok, can = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
			if ok and can then
				pcall(SocialService.PromptGameInvite, SocialService, player)
			end
		end)
	end
	Bus.handle("Invite", invite)
	local bonus = string.format(UiText.INVITE_BONUS, math.floor(BoostConfig.FRIENDS.perFriend * 100 + 0.5))
	local corner = hud.addCorner("Invite", "invite", UiText.INVITE_FRIENDS, bonus, 3, UiText.INVITE)
	corner.Activated:Connect(function()
		Sound.play("Click")
		invite()
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
