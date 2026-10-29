--!strict
-- Efectos de partículas como los de los hits, en la UI y en el mundo:
-- - burst: destellos y confeti que salen de un punto de la pantalla (premio, compra, botón).
-- - rays: rayos que giran detrás de un premio.
-- - confetti: lluvia de confeti en toda la pantalla (renacer, SECRET).
-- - worldBurst: ParticleEmitter en una posición del mundo con nuestras texturas (assets/vfx/hit).
-- - floatingText: "+$1.2K" que sube y se desvanece sobre algo del mundo.
-- Las texturas salen de AssetIds.vfx cuando están subidas; si no, se usan formas simples (marcos de
-- colores) y las partículas de Roblox, así todo se ve desde el primer playtest.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local AssetIds = require(ReplicatedStorage.Shared.Config.AssetIds)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Juice = require("./Juice")

local Effects = {}

local CONFETTI_COLORS = {
	Color3.fromRGB(255, 80, 90),
	Color3.fromRGB(255, 210, 60),
	Color3.fromRGB(90, 220, 110),
	Color3.fromRGB(80, 180, 255),
	Color3.fromRGB(190, 110, 255),
	Color3.fromRGB(255, 130, 200),
}
-- Partícula de destello incluida en Roblox (la que usa Sparkles).
local DEFAULT_SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"

local function vfx(name: string): string?
	local id = AssetIds.vfx[name]
	return if id and id ~= "" then id else nil
end

local function piece(parent: Instance, texture: string?, color: Color3, size: number): GuiObject
	if texture then
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Image = texture
		image.ImageColor3 = color
		image.Size = UDim2.fromOffset(size, size)
		image.Parent = parent
		return image
	end
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromOffset(size, size * 0.6)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = frame
	frame.Parent = parent
	return frame
end

-- Destellos/confeti desde `at` (píxeles de pantalla). `kind`: "sparkle" (blancos y dorados) o "confetti".
function Effects.burst(screen: Instance, at: Vector2, kind: string?, count: number?)
	local confetti = kind == "confetti"
	local texture = if confetti then nil else (vfx("sparkle") or vfx("star"))
	local n = count or 14
	for _ = 1, n do
		local color = if confetti
			then CONFETTI_COLORS[math.random(#CONFETTI_COLORS)]
			else (if math.random() < 0.5 then Color3.fromRGB(255, 240, 150) else Color3.new(1, 1, 1))
		local size = if confetti then math.random(10, 18) else math.random(14, 30)
		local p = piece(screen, texture, color, size)
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Position = UDim2.fromOffset(at.X, at.Y)
		p.Rotation = math.random(0, 360)
		p.ZIndex = 140
		local angle = math.random() * math.pi * 2
		local distance = math.random(60, 170)
		local goal = at + Vector2.new(math.cos(angle), math.sin(angle)) * distance + Vector2.new(0, if confetti then 60 else 0)
		local duration = 0.5 + math.random() * 0.4
		local props: { [string]: any } = { Position = UDim2.fromOffset(goal.X, goal.Y), Rotation = p.Rotation + math.random(-180, 180) }
		if p:IsA("ImageLabel") then
			props.ImageTransparency = 1
		else
			props.BackgroundTransparency = 1
		end
		TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
		Debris:AddItem(p, duration + 0.1)
	end
end

-- Rayos que giran detrás de `parent` (que debe tener ClipsDescendants = false). Devuelve cómo pararlos.
function Effects.rays(parent: GuiObject, color: Color3?, scale: number?): Juice.Stop
	local holder = Instance.new("Frame")
	holder.Name = "Rays"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(scale or 1.8, scale or 1.8)
	holder.ZIndex = math.max(parent.ZIndex - 1, 1)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = holder
	local texture = vfx("rays")
	if texture then
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Image = texture
		image.ImageColor3 = color or Color3.fromRGB(255, 230, 120)
		image.ImageTransparency = 0.15
		image.Size = UDim2.fromScale(1, 1)
		image.ZIndex = holder.ZIndex
		image.Parent = holder
	else
		-- Sin textura: 12 rayos de marcos con degradé hacia afuera.
		for i = 1, 12 do
			local ray = Instance.new("Frame")
			ray.BackgroundColor3 = color or Color3.fromRGB(255, 230, 120)
			ray.BorderSizePixel = 0
			ray.AnchorPoint = Vector2.new(0.5, 1)
			ray.Position = UDim2.fromScale(0.5, 0.5)
			ray.Size = UDim2.fromScale(0.07, 0.5)
			ray.Rotation = i * 30
			ray.ZIndex = holder.ZIndex
			local gradient = Instance.new("UIGradient")
			gradient.Rotation = 90
			gradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0.35),
			})
			gradient.Parent = ray
			ray.Parent = holder
		end
	end
	holder.Parent = parent
	local stopSpin = Juice.spin(holder, 25)
	return function()
		stopSpin()
		holder:Destroy()
	end
end

-- Lluvia de confeti en toda la pantalla.
function Effects.confetti(screen: GuiBase2d, count: number?)
	local size = screen.AbsoluteSize
	for _ = 1, count or 60 do
		local color = CONFETTI_COLORS[math.random(#CONFETTI_COLORS)]
		local p = piece(screen, nil, color, math.random(10, 18))
		local x = math.random() * size.X
		p.Position = UDim2.fromOffset(x, -20)
		p.Rotation = math.random(0, 360)
		p.ZIndex = 140
		local duration = 1.6 + math.random() * 1.2
		local delay = math.random() * 0.6
		task.delay(delay, function()
			TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.fromOffset(x + math.random(-120, 120), size.Y + 30),
				Rotation = p.Rotation + math.random(-540, 540),
			}):Play()
		end)
		Debris:AddItem(p, duration + delay + 0.1)
	end
end

-- Partículas en el mundo: "sparkle" (premio), "coins" (cobrar), "rare" (rayos y brillo), "smoke" (aparece algo).
function Effects.worldBurst(position: Vector3, kind: string?, color: Color3?, amount: number?)
	local part = Instance.new("Part")
	part.Name = "Burst"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.one
	part.CFrame = CFrame.new(position)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.LightEmission = 1
	emitter.Lifetime = NumberRange.new(0.6, 1.1)
	emitter.Speed = NumberRange.new(8, 16)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-180, 180)
	emitter.Drag = 3
	emitter.Acceleration = Vector3.new(0, -6, 0)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.8, 0.2), NumberSequenceKeypoint.new(1, 1) })
	emitter.Color = ColorSequence.new(color or Color3.fromRGB(255, 225, 110))
	local k = kind or "sparkle"
	if k == "smoke" then
		emitter.Texture = vfx("smoke_2x2") or "rbxasset://textures/particles/smoke_main.dds"
		emitter.LightEmission = 0
		emitter.Color = ColorSequence.new(color or Color3.new(1, 1, 1))
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 3) })
		emitter.Speed = NumberRange.new(3, 6)
		emitter.Acceleration = Vector3.new(0, 2, 0)
		if vfx("smoke_2x2") then
			emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2
			emitter.FlipbookMode = Enum.ParticleFlipbookMode.Random
		end
	elseif k == "confetti" and vfx("confetti_4x4") then
		emitter.Texture = vfx("confetti_4x4") :: string
		emitter.LightEmission = 0
		emitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
		emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		emitter.FlipbookMode = Enum.ParticleFlipbookMode.Random
		emitter.Acceleration = Vector3.new(0, -20, 0)
	elseif k == "coins" then
		emitter.Texture = vfx("star") or DEFAULT_SPARKLE
		emitter.Color = ColorSequence.new(color or Color3.fromRGB(255, 205, 60))
		emitter.Acceleration = Vector3.new(0, -25, 0)
		emitter.Speed = NumberRange.new(12, 20)
		emitter.SpreadAngle = Vector2.new(35, 35)
		emitter.EmissionDirection = Enum.NormalId.Top
	else
		emitter.Texture = vfx("sparkle") or DEFAULT_SPARKLE
	end
	emitter.Parent = part
	if k == "rare" then
		local glow = Instance.new("ParticleEmitter")
		glow.Enabled = false
		glow.Texture = vfx("rays") or DEFAULT_SPARKLE
		glow.LightEmission = 1
		glow.Lifetime = NumberRange.new(1.2)
		glow.Speed = NumberRange.new(0)
		glow.RotSpeed = NumberRange.new(40)
		glow.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(0.3, 9), NumberSequenceKeypoint.new(1, 11) })
		glow.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		glow.Color = ColorSequence.new(color or Color3.fromRGB(255, 225, 110))
		glow.Parent = part
		glow:Emit(2)
	end
	part.Parent = Workspace
	emitter:Emit(amount or 24)
	Debris:AddItem(part, 3)
end

-- "+$1.2K" que sube y se desvanece sobre `adornee` (una pieza o attachment del mundo).
function Effects.floatingText(adornee: Instance, text: string, color: Color3?, big: boolean?)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FloatingText"
	billboard.Size = UDim2.fromScale(if big then 8 else 5, if big then 2 else 1.4)
	billboard.StudsOffsetWorldSpace = Vector3.new(math.random(-10, 10) / 10, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 120
	billboard.Adornee = adornee :: any
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	UIKit.text(label, text, 80, UIKit.TitleFont)
	label.TextColor3 = color or Color3.fromRGB(120, 255, 120)
	label.Parent = billboard
	billboard.Parent = Workspace
	TweenService:Create(billboard, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = billboard.StudsOffsetWorldSpace + Vector3.new(0, 3, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.6), {
		TextTransparency = 1,
	}):Play()
	local stroke = label:FindFirstChild("TextStroke") :: UIStroke?
	if stroke then
		TweenService:Create(stroke, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.6), { Transparency = 1 }):Play()
	end
	Debris:AddItem(billboard, 1.2)
end

-- Brillo del contorno de un modelo (lo que acaba de salir de un huevo, lo robado).
function Effects.highlight(model: Instance, color: Color3?, duration: number?)
	local h = Instance.new("Highlight")
	h.FillTransparency = 0.6
	h.OutlineColor = color or Color3.fromRGB(255, 230, 120)
	h.FillColor = color or Color3.fromRGB(255, 230, 120)
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = model
	TweenService:Create(h, TweenInfo.new(duration or 1.2), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	Debris:AddItem(h, (duration or 1.2) + 0.1)
end

return Effects
