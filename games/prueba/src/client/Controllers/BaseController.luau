--!strict
-- Base del jugador en el cliente: oculta los prompts "Steal" de su propia base, muestra los avisos del
-- servidor y los botones "Lock" (con su cuenta regresiva) y "Push" (solo con un ladrón cerca).
-- Todo es pedido: el servidor decide si se traba, a quién se empuja y qué se puede robar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Net = require(ReplicatedStorage.Shared.Net)
local UIKit = require(ReplicatedStorage.Shared.UIKit)

local BaseController = {}

local REFRESH_SECONDS = 0.25

local function ownPlot(player: Player): Model?
	local plots = workspace:WaitForChild("Plots")
	while true do
		for _, plot in plots:GetChildren() do
			if plot:GetAttribute("OwnerUserId") == player.UserId then
				return plot :: Model
			end
		end
		task.wait(REFRESH_SECONDS)
	end
end

-- Nadie se roba a sí mismo: el prompt queda apagado solo en este cliente, aunque el servidor lo prenda.
local function hideOwnPrompts(plot: Model)
	local function hide(inst: Instance)
		if inst:IsA("ProximityPrompt") and inst.Name == "StealPrompt" then
			inst.Enabled = false
			inst:GetPropertyChangedSignal("Enabled"):Connect(function()
				inst.Enabled = false
			end)
		end
	end
	local critters = plot:WaitForChild("Critters")
	for _, inst in critters:GetDescendants() do
		hide(inst)
	end
	critters.DescendantAdded:Connect(hide)
end

local function thiefNearby(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	for _, other in Players:GetPlayers() do
		local otherCharacter = other.Character
		local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?
		if other ~= player and otherCharacter and otherRoot and otherCharacter:GetAttribute("CarryingFrom") then
			if (otherRoot.Position - root.Position).Magnitude <= GameplayConfig.PUSH_RANGE then
				return true
			end
		end
	end
	return false
end

function BaseController.start(screen: ScreenGui)
	local player = Players.LocalPlayer
	Net.event("Notify").OnClientEvent:Connect(function(text: string)
		UIKit.notify(screen, text, "Info")
	end)

	-- A la derecha, por encima de la zona del botón de salto (zonas reservadas de la guía de estilo).
	local lockButton = UIKit.button({
		name = "LockButton",
		text = UiText.LOCK,
		variant = "Info",
		size = UDim2.fromScale(0.3, 0.11),
		position = UDim2.fromScale(0.98, 0.42),
		anchorPoint = Vector2.new(1, 0.5),
		parent = screen,
	})
	lockButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
	local pushButton = UIKit.button({
		name = "PushButton",
		text = UiText.PUSH,
		variant = "Close",
		size = UDim2.fromScale(0.3, 0.11),
		position = UDim2.fromScale(0.98, 0.28),
		anchorPoint = Vector2.new(1, 0.5),
		parent = screen,
	})
	pushButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
	pushButton.Visible = false

	local lockRemote = Net.event("LockBase")
	local pushRemote = Net.event("Push")
	lockButton.Activated:Connect(function()
		lockRemote:FireServer()
	end)
	pushButton.Activated:Connect(function()
		pushRemote:FireServer()
	end)

	task.spawn(function()
		local plot = ownPlot(player) :: Model
		hideOwnPrompts(plot)
		while screen.Parent do
			local t = workspace:GetServerTimeNow()
			local lockedUntil = plot:GetAttribute("LockedUntil") or 0
			local readyAt = plot:GetAttribute("LockReadyAt") or 0
			if lockedUntil > t then
				UIKit.setText(lockButton, string.format(UiText.LOCK_ACTIVE, math.ceil(lockedUntil - t)))
			elseif readyAt > t then
				UIKit.setText(lockButton, string.format(UiText.LOCK_WAIT, math.ceil(readyAt - t)))
			else
				UIKit.setText(lockButton, UiText.LOCK)
			end
			pushButton.Visible = thiefNearby(player)
			task.wait(REFRESH_SECONDS)
		end
	end)
end

return BaseController
