--!strict
-- Pantalla de carga estilo hit: sale antes que todo y tapa la de Roblox con el fondo del juego, el
-- nombre en grande con contorno, una barra que avanza con lo que falta cargar y consejos que cambian.
-- Se va con una animación cuando el juego cargó (al menos MIN_SECONDS) o con "Skip" (a los
-- SKIP_AFTER segundos). No requiere nada de ReplicatedStorage (todavía no llegó): se arma sola con el
-- mismo material que UIKit (degradé, contorno oscuro, letras gordas) y lo editable está en
-- LoadingConfig.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")

local Config = require("./LoadingConfig")

local INK = Color3.fromRGB(20, 16, 32)
local GREEN = Color3.fromRGB(70, 214, 75)
local GREEN_DARK = Color3.fromRGB(35, 166, 46)
local FONT = Font.fromEnum(Enum.Font.FredokaOne)

local player = Players.LocalPlayer

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local instance = Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	instance.Parent = parent
	return instance
end

local function text(label: GuiObject, value: string, maxSize: number)
	local t: any = label -- TextLabel o TextButton: las dos tienen estas propiedades
	t.Text = value
	t.FontFace = FONT
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	if label:IsA("TextLabel") then
		label.BackgroundTransparency = 1
	end
	new("UITextSizeConstraint", { MaxTextSize = maxSize, MinTextSize = 10 }, label)
	new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
		Thickness = 0.14,
		Color = INK,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, label)
end

local function hex(value: string, fallback: Color3): Color3
	local ok, color = pcall(Color3.fromHex, value)
	return if ok then color else fallback
end

ReplicatedFirst:RemoveDefaultLoadingScreen()

local gui = new("ScreenGui", {
	Name = "LoadingScreen",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 1000,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui")) :: ScreenGui

local root = new("Frame", { Name = "Root", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1) }, gui) :: Frame
local gradient = Config.GRADIENT
new("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(hex(gradient[1], Color3.fromRGB(122, 44, 255)), hex(gradient[2], Color3.fromRGB(255, 79, 216))),
}, root)
if Config.IMAGE ~= "" then
	new("ImageLabel", {
		Name = "Background",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Image = Config.IMAGE,
		ScaleType = Enum.ScaleType.Crop,
	}, root)
end
-- Oscurece abajo para que se lean la barra y los consejos.
local shade = new("Frame", { Name = "Shade", BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.fromScale(1, 1), ZIndex = 2 }, root)
new("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 0.35) }),
}, shade)

local title = new("TextLabel", {
	Name = "Title",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.36),
	Size = UDim2.fromScale(0.8, 0.2),
	ZIndex = 5,
}, root) :: TextLabel
text(title, Config.TITLE, 140)
-- Letras doradas como los títulos de los hits (el degradé tiñe el texto; el contorno queda oscuro).
new("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(Color3.fromRGB(255, 244, 120), Color3.fromRGB(255, 166, 30)),
}, title)
new("UIScale", { Name = "Pop" }, title)

-- Barra: pista oscura, relleno verde con labio y el porcentaje encima.
local track = new("Frame", {
	Name = "Bar",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.72),
	Size = UDim2.fromScale(0.5, 0.055),
	BackgroundColor3 = Color3.fromRGB(25, 26, 34),
	ZIndex = 5,
}, root) :: Frame
new("UIAspectRatioConstraint", { AspectRatio = 12 }, track)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, track)
new("UIStroke", { Thickness = 0.06, StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize, Color = INK }, track)
local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0.04, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, track) :: Frame
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(GREEN, GREEN_DARK) }, fill)
local percent = new("TextLabel", {
	Name = "Percent",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.9, 0.8),
	ZIndex = 7,
}, track) :: TextLabel
text(percent, string.format(Config.LOADING, 0), 40)

local tip = new("TextLabel", {
	Name = "Tip",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.83),
	Size = UDim2.fromScale(0.7, 0.06),
	ZIndex = 5,
}, root) :: TextLabel
text(tip, Config.TIPS[1] or "", 44)

local skip = new("TextButton", {
	Name = "Skip",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.fromScale(0.97, 0.95),
	Size = UDim2.fromScale(0.13, 0.08),
	BackgroundColor3 = Color3.fromRGB(154, 160, 173),
	AutoButtonColor = true,
	Visible = false,
	ZIndex = 8,
}, root) :: TextButton
new("UIAspectRatioConstraint", { AspectRatio = 2.6 }, skip)
new("UICorner", { CornerRadius = UDim.new(0.25, 0) }, skip)
new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 0.06, StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize, Color = INK }, skip)
text(skip, Config.SKIP, 36)

-- El nombre entra con rebote y late suave.
local pop = title:FindFirstChild("Pop") :: UIScale
pop.Scale = 0
TweenService:Create(pop, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
task.delay(0.6, function()
	TweenService:Create(pop, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.05 }):Play()
end)

local started = os.clock()
local skipped = false
skip.Activated:Connect(function()
	skipped = true
end)

-- Consejos que cambian.
task.spawn(function()
	local index = 1
	while gui.Parent do
		task.wait(Config.TIP_SECONDS)
		if #Config.TIPS > 0 then
			index = index % #Config.TIPS + 1
			tip.Text = Config.TIPS[index]
		end
	end
end)

-- Avance: lo que va quedando en la cola de descargas, con un piso que crece con el tiempo para que la
-- barra nunca se quede quieta.
local firstQueue = math.max(ContentProvider.RequestQueueSize, 1)
local shown = 0
while true do
	local elapsed = os.clock() - started
	local queue = ContentProvider.RequestQueueSize
	firstQueue = math.max(firstQueue, queue)
	local real = if game:IsLoaded() then 1 - queue / firstQueue else 0.6 * (1 - queue / firstQueue)
	local floor = math.min(elapsed / Config.MIN_SECONDS, 1) * 0.85
	shown = math.max(shown, math.clamp(math.max(real, floor), 0, 1))
	fill.Size = UDim2.fromScale(math.max(shown, 0.04), 1)
	percent.Text = string.format(Config.LOADING, math.floor(shown * 100))
	skip.Visible = elapsed >= Config.SKIP_AFTER
	local done = game:IsLoaded() and queue == 0 and elapsed >= Config.MIN_SECONDS
	if done or skipped or elapsed >= Config.MAX_SECONDS then
		break
	end
	task.wait(0.05)
end

fill.Size = UDim2.fromScale(1, 1)
percent.Text = string.format(Config.LOADING, 100)
task.wait(0.25)
local fade = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
TweenService:Create(root, fade, { BackgroundTransparency = 1 }):Play()
for _, child in root:GetDescendants() do
	if child:IsA("TextLabel") or child:IsA("TextButton") then
		TweenService:Create(child, fade, { TextTransparency = 1 }):Play()
	elseif child:IsA("ImageLabel") then
		TweenService:Create(child, fade, { ImageTransparency = 1 }):Play()
	elseif child:IsA("Frame") then
		TweenService:Create(child, fade, { BackgroundTransparency = 1 }):Play()
	elseif child:IsA("UIStroke") then
		TweenService:Create(child, fade, { Transparency = 1 }):Play()
	end
end
task.wait(0.5)
gui:Destroy()
