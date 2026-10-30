--!strict
-- Modelo 3D de una unidad del armador: el de ReplicatedStorage.Assets.Units[def.model] o, mientras no
-- haya modelo, una bola del color de la unidad (o de su mutación). Escalado por su tamaño (Big, Huge),
-- anclado y sin choque, con sus datos en atributos (Kind, Variant, Size) y la etiqueta "KitUnit" para
-- que cada cliente le ponga su cartel. Lo usan el servidor (bases, cinta, salvajes) y el cliente
-- (mascotas que siguen, revelado de huevos).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RarityConfig = require("../Config/RarityConfig")
local Types = require("./Types")

local UnitModel = {}

UnitModel.TAG = "KitUnit"

local PLACEHOLDER_SIZE = 3

local function colorOf(def: Types.UnitDef, variant: string?): Color3
	for _, v in RarityConfig.MUTATIONS do
		if v.id == variant and v.color then
			return v.color
		end
	end
	if def.color then
		local ok, color = pcall(Color3.fromHex, def.color)
		if ok then
			return color
		end
	end
	for _, tier in RarityConfig.TIERS do
		if tier.id == def.rarity then
			return tier.color
		end
	end
	return Color3.new(1, 1, 1)
end

local function scaleOf(size: string?): number
	for _, v in RarityConfig.SIZES do
		if v.id == size and v.scale then
			return v.scale
		end
	end
	return 1
end

local function template(def: Types.UnitDef): Model?
	local name = def.model
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = if assets then assets:FindFirstChild("Units") else nil
	local found = if folder and name then folder:FindFirstChild(name) else nil
	return if found and found:IsA("Model") then found else nil
end

-- Un modelo nuevo de la unidad (sin padre). `unit` necesita kind y, si tiene, variant y size.
function UnitModel.make(def: Types.UnitDef, unit: { kind: string, variant: string?, size: string? }): Model
	local source = template(def)
	local model: Model
	if source then
		model = source:Clone()
	else
		model = Instance.new("Model")
		local ball = Instance.new("Part")
		ball.Name = "Body"
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.one * PLACEHOLDER_SIZE
		ball.Color = colorOf(def, unit.variant)
		ball.Material = Enum.Material.SmoothPlastic
		ball.TopSurface = Enum.SurfaceType.Smooth
		ball.BottomSurface = Enum.SurfaceType.Smooth
		ball.Parent = model
		model.PrimaryPart = ball
	end
	model.Name = def.id
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.Massless = true
		end
	end
	local scale = scaleOf(unit.size)
	if scale ~= 1 then
		model:ScaleTo(scale)
	end
	model:SetAttribute("Kind", unit.kind)
	model:SetAttribute("Variant", unit.variant)
	model:SetAttribute("Size", unit.size)
	model:AddTag(UnitModel.TAG)
	return model
end

-- Apoya el modelo con su base sobre el punto de `cframe` (mirando hacia donde mira `cframe`).
function UnitModel.standOn(model: Model, cframe: CFrame)
	local pivot = model:GetPivot()
	local box, size = model:GetBoundingBox()
	local bottom = box.Position.Y - size.Y / 2
	local lift = pivot.Position.Y - bottom
	model:PivotTo(cframe.Rotation + cframe.Position + Vector3.new(0, lift, 0))
end

return UnitModel
