--!strict
-- Misiones diarias (RetentionConfig.QUESTS): lista con barra de progreso y premio de cada una, botón
-- CLAIM al completarla y bono por terminar todas. Globito en el HUD con las listas para cobrar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local RetentionConfig = require(ReplicatedStorage.Shared.Config.RetentionConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local RewardText = require(ReplicatedStorage.Shared.Lib.RewardText)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local PlayerState = require("../PlayerState")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local QuestController = {}

local defs: { [string]: RetentionConfig.QuestDef } = {}
for _, def in RetentionConfig.QUESTS.pool do
	defs[def.id] = def
end

local function invoke(name: string, ...: any): boolean
	local args = table.pack(...)
	local ok, result = pcall(function()
		return Net.func(name):InvokeServer(table.unpack(args, 1, args.n))
	end)
	return ok and result == true
end

function QuestController.start(hud: Hud.Hud)
	local window, body = UIKit.window(hud.screen, { name = "Quests", title = UiText.QUESTS_TITLE, icon = "quests", variant = "Orange" })
	local list = UIKit.list(body, "List")
	list.Size = UDim2.fromScale(1, 0.8)
	list.ZIndex = 21
	local bonus = UIKit.button({
		name = "Bonus",
		text = UiText.QUEST_BONUS,
		variant = "Neutral",
		icon = "chest",
		anchorPoint = Vector2.new(0.5, 1),
		position = UDim2.fromScale(0.5, 0.99),
		size = UDim2.fromScale(0.6, 0.16),
		aspectRatio = 6,
		parent = body,
	})
	bonus.ZIndex = 22
	local hudButton = hud.addButton("left", { name = "Quests", label = UiText.QUESTS, icon = "quests", variant = "Orange", layoutOrder = 4 })
	local quests: { ids: { string }, progress: { [string]: number }, claimed: { [string]: boolean }, bonusClaimed: boolean }? = nil
	local stops: { Juice.Stop } = {}

	local function row(order: number, id: string): ()
		local def = defs[id]
		local q = quests
		if not def or not q then
			return
		end
		local progress = q.progress[id] or 0
		local done = progress >= def.target
		local claimed = q.claimed[id] == true
		local frame = UIKit.new("Frame", { Name = id, LayoutOrder = order, Size = UDim2.fromScale(0.96, 0.27), ZIndex = 22 }, list) :: Frame
		UIKit.style(frame, if claimed then "Neutral" elseif done then "Accept" else "Info", 0.2, 3)
		local target = if def.money then Format.money(def.target, EconomyConfig.CURRENCIES[EconomyConfig.MAIN].symbol) else Format.number(def.target)
		UIKit.label(frame, "Text", string.format(def.text, target), {
			Position = UDim2.fromScale(0.03, 0.08),
			Size = UDim2.fromScale(0.6, 0.38),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 24,
		}, 34, UIKit.TitleFont)
		local bar = UIKit.progressBar(frame, "Progress", {
			Position = UDim2.fromScale(0.03, 0.56),
			Size = UDim2.fromScale(0.6, 0.32),
			ZIndex = 24,
		}, "Premium")
		local shown = math.min(progress, def.target)
		UIKit.setProgress(bar, shown / def.target, (if def.money then Format.number(shown) else tostring(math.floor(shown))) .. " / " .. (if def.money then Format.number(def.target) else tostring(def.target)))
		local parts = RewardText.parts(def.reward, 0)
		UIKit.icon(frame, RewardText.icon(def.reward), {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.7, 0.5),
			Size = UDim2.fromScale(0.75, 0.75),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			ZIndex = 24,
		})
		local claim = UIKit.button({
			name = "Claim",
			text = if claimed then UiText.CLAIMED elseif done then UiText.CLAIM else (if parts[1] then parts[1].text else ""),
			variant = if claimed then "Neutral" elseif done then "Premium" else "Neutral",
			anchorPoint = Vector2.new(1, 0.5),
			position = UDim2.fromScale(0.97, 0.5),
			size = UDim2.fromScale(0.22, 0.7),
			aspectRatio = 2.6,
			parent = frame,
		})
		claim.ZIndex = 25
		if done and not claimed then
			table.insert(stops, Juice.pulse(claim, 0.06))
		end
		claim.Activated:Connect(function()
			if not done or claimed then
				Sound.play("Error")
				Juice.shake(claim)
				return
			end
			Sound.play("Click")
			if not invoke("ClaimQuest", id) then
				Sound.play("Error")
			end
		end)
	end

	local function render()
		for _, stop in stops do
			stop()
		end
		table.clear(stops)
		for _, child in list:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local q = quests
		if not q then
			return
		end
		local ready = 0
		local all = #q.ids > 0
		for i, id in q.ids do
			row(i, id)
			local def = defs[id]
			local done = def ~= nil and (q.progress[id] or 0) >= def.target
			if done and not q.claimed[id] then
				ready += 1
			end
			if not q.claimed[id] then
				all = false
			end
		end
		UIKit.setBadge(hudButton, if ready > 0 then ready else nil)
		UIKit.recolor(bonus, if all and not q.bonusClaimed then "Premium" elseif q.bonusClaimed then "Neutral" else "Neutral")
		UIKit.setText(bonus, if q.bonusClaimed then UiText.CLAIMED else UiText.QUEST_BONUS)
	end

	bonus.Activated:Connect(function()
		Sound.play("Click")
		if not invoke("ClaimQuestBonus") then
			Sound.play("Error")
			Juice.shake(bonus)
		end
	end)
	PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
		quests = state.quests
		render()
	end)
	hudButton.Activated:Connect(function()
		Sound.play("Click")
		UIKit.toggle(window)
	end)
	Bus.handle("OpenQuests", function()
		UIKit.open(window)
	end)
end

return QuestController
