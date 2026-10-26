--!strict
-- Cinta compartida (M2 y M3 de docs/spec.md): cada BELT_SPAWN_SECONDS sale un critter al azar según
-- BELT_WEIGHTS, cruza la cinta y desaparece. El primero que toca "Buy" (y paga) se lo lleva.
-- El nivel lo sortea el servidor con monedas del juego, no con Robux.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)
local CritterRules = require("./CritterRules")
local CritterService = require("./CritterService")
local CritterVisual = require("./CritterVisual")

local BeltService = {}

local function inReach(player: Player, target: BasePart): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil
		and (root.Position - target.Position).Magnitude <= GameplayConfig.BUY_DISTANCE + GameplayConfig.BUY_DISTANCE_TOLERANCE
end

local function spawnCritter(belt: BasePart, folder: Folder)
	local tier = CritterRules.rollTier(GameplayConfig.BELT_WEIGHTS, math.random())
	local info = GameplayConfig.TIERS[tier]
	local price = assert(info.price, "BELT_WEIGHTS incluye un nivel sin precio en TIERS")
	local model = CritterVisual.build(tier, "Normal")
	CritterVisual.setInfo(model, price .. " coins")
	local body = model.PrimaryPart :: BasePart
	local half = GameplayConfig.BELT_LENGTH / 2
	local y = belt.Position.Y + belt.Size.Y / 2 + body.Size.Y / 2
	body.CFrame = CFrame.new(-half, y, 0)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy"
	prompt.ObjectText = info.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = GameplayConfig.BUY_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(function(player: Player)
		-- "Sold" se marca antes de cobrar: si dos jugadores tocan a la vez, gana el primero.
		if model:GetAttribute("Sold") or not inReach(player, body) then
			return
		end
		model:SetAttribute("Sold", true)
		if CritterService.buy(player, tier) then
			model:Destroy()
		else
			model:SetAttribute("Sold", nil)
		end
	end)

	model.Parent = folder
	local walk = TweenService:Create(body, TweenInfo.new(GameplayConfig.BELT_WALK_SECONDS, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(half, y, 0),
	})
	walk.Completed:Once(function()
		if model.Parent then
			model:Destroy()
		end
	end)
	walk:Play()
end

function BeltService.start()
	local belt = Instance.new("Part")
	belt.Name = "Belt"
	belt.Anchored = true
	belt.Size = Vector3.new(GameplayConfig.BELT_LENGTH, 1, 6)
	belt.Position = Vector3.new(0, 0.5, 0)
	belt.Color = Color3.fromRGB(70, 70, 75)
	belt.Parent = workspace
	local folder = Instance.new("Folder")
	folder.Name = "BeltCritters"
	folder.Parent = workspace
	task.spawn(function()
		while true do
			spawnCritter(belt, folder)
			task.wait(GameplayConfig.BELT_SPAWN_SECONDS)
		end
	end)
end

return BeltService
