--!strict
-- Cómo se ve un critter en el mundo. Hito 1: un cubo de color por nivel con su cartel (nombre, ingreso
-- y una línea de info: precio en la cinta o monedas sin juntar en el pedestal). Los modelos reales
-- llegan en el hito 6 y reemplazan solo build().

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)

local CritterVisual = {}

-- Un color por nivel para distinguirlos mientras son cubos.
local TIER_COLORS = {
	Color3.fromRGB(190, 190, 190),
	Color3.fromRGB(110, 200, 90),
	Color3.fromRGB(80, 170, 255),
	Color3.fromRGB(255, 220, 60),
	Color3.fromRGB(240, 240, 255),
	Color3.fromRGB(255, 110, 40),
	Color3.fromRGB(150, 110, 255),
	Color3.fromRGB(120, 255, 240),
}

local function line(name: string, order: number, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1 / 3)
	label.Position = UDim2.fromScale(0, (order - 1) / 3)
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.FredokaOne
	label.Parent = parent
	return label
end

function CritterVisual.build(tier: number, mutation: string): Model
	local info = GameplayConfig.TIERS[tier]
	local model = Instance.new("Model")
	model.Name = info.name
	model:SetAttribute("Tier", tier)
	model:SetAttribute("Mutation", mutation)

	local side = 2 + tier * 0.4
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.CanCollide = false
	body.Size = Vector3.new(side, side, side)
	body.Color = TIER_COLORS[tier]
	body.Parent = model
	model.PrimaryPart = body

	local sign = Instance.new("BillboardGui")
	sign.Name = "Sign"
	sign.Size = UDim2.fromScale(6, 3)
	sign.StudsOffset = Vector3.new(0, side / 2 + 2, 0)
	sign.MaxDistance = 80
	line("Title", 1, sign).Text = info.name
	line("Income", 2, sign).Text = "+" .. info.income * (GameplayConfig.MUTATIONS[mutation] or 1) .. "/s"
	line("Info", 3, sign)
	sign.Parent = body
	return model
end

function CritterVisual.setInfo(model: Model, text: string)
	local sign = (model.PrimaryPart :: BasePart):FindFirstChild("Sign") :: BillboardGui
	(sign:FindFirstChild("Info") :: TextLabel).Text = text
end

return CritterVisual
