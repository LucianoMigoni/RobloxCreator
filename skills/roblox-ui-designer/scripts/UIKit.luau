--!strict
-- UIKit: componentes de UI con el estilo del hub (ver references/style-guide.md).
-- Solo presentación: nunca cambia monedas ni inventario; eso lo confirma el servidor.
-- Uso: copiar a src/shared/UIKit.luau y requerir desde los controladores del cliente.

local TweenService = game:GetService("TweenService")

export type Variant = "Accept" | "Close" | "Premium" | "Info" | "Neutral"

export type ButtonProps = {
	name: string,
	text: string,
	variant: Variant?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	aspectRatio: number?,
	layoutOrder: number?,
	parent: Instance?,
}

local UIKit = {}

-- Gradiente arriba → abajo. Reemplazar por la paleta del usuario si la trae.
UIKit.Colors = {
	Accept = { Color3.fromRGB(91, 227, 60), Color3.fromRGB(46, 168, 30) },
	Close = { Color3.fromRGB(255, 86, 86), Color3.fromRGB(200, 30, 45) },
	Premium = { Color3.fromRGB(255, 214, 64), Color3.fromRGB(240, 150, 20) },
	Info = { Color3.fromRGB(80, 180, 255), Color3.fromRGB(30, 110, 230) },
	Neutral = { Color3.fromRGB(70, 74, 100), Color3.fromRGB(45, 48, 70) },
}
UIKit.STROKE_COLOR = Color3.fromRGB(25, 22, 40)
UIKit.TEXT_COLOR = Color3.new(1, 1, 1)
UIKit.Font = Font.fromEnum(Enum.Font.FredokaOne)
UIKit.MIN_TOUCH_PX = 44 -- Roblox no fija mínimo; 44 pt de la guía de Apple

local PRESS = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local OPEN = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In)

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

local openPopup: GuiObject? = nil

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local inst: any = Instance.new(className)
	for key, value in props do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

-- Fondo con gradiente, esquinas redondeadas y borde grueso oscuro.
function UIKit.style(obj: GuiObject, variant: Variant, cornerScale: number?, strokePx: number?)
	local colors = (UIKit.Colors :: any)[variant]
	obj.BackgroundColor3 = Color3.new(1, 1, 1) -- el UIGradient multiplica este color
	obj.BorderSizePixel = 0
	new("UICorner", { CornerRadius = UDim.new(cornerScale or 0.25, 0) }, obj)
	new("UIStroke", {
		Thickness = strokePx or 3,
		Color = UIKit.STROKE_COLOR,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, obj)
	new("UIGradient", { Color = ColorSequence.new(colors[1], colors[2]), Rotation = 90 }, obj)
end

-- Texto blanco, fuente gruesa, contorno oscuro, escalable con límite.
function UIKit.text(label: GuiObject, text: string, maxSize: number?)
	local t: any = label
	t.Text = text
	t.FontFace = UIKit.Font
	t.TextColor3 = UIKit.TEXT_COLOR
	t.TextScaled = true
	new("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = maxSize or 48 }, label)
	new("UIStroke", {
		Thickness = 2,
		Color = UIKit.STROKE_COLOR,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, label)
end

-- Rebote al presionar/soltar (mouse y toque). Usa UIScale para no tocar Size.
function UIKit.bounce(button: GuiButton)
	local scale = button:FindFirstChildOfClass("UIScale") or new("UIScale", {}, button)
	local function isPress(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end
	button.InputBegan:Connect(function(input)
		if isPress(input) then
			TweenService:Create(scale, PRESS, { Scale = 0.9 }):Play()
		end
	end)
	button.InputEnded:Connect(function(input)
		if isPress(input) then
			TweenService:Create(scale, RELEASE, { Scale = 1 }):Play()
		end
	end)
end

function UIKit.screen(name: string, parent: Instance?): ScreenGui
	return new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets, -- evita notch y barra de Roblox
	}, parent)
end

function UIKit.button(p: ButtonProps): TextButton
	local button: TextButton = new("TextButton", {
		Name = p.name,
		Text = "",
		Size = p.size or UDim2.fromScale(0.25, 0.1),
		Position = p.position or UDim2.new(),
		AnchorPoint = p.anchorPoint or Vector2.zero,
		LayoutOrder = p.layoutOrder or 0,
	})
	UIKit.style(button, p.variant or "Accept")
	new("UIAspectRatioConstraint", { AspectRatio = p.aspectRatio or 2.5 }, button)
	new("UISizeConstraint", { MinSize = Vector2.new(UIKit.MIN_TOUCH_PX, UIKit.MIN_TOUCH_PX) }, button)
	-- El texto va en un hijo para tener margen interno sin UIPadding (que desplazaría iconos).
	local label = new("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.85, 0.7),
	}, button)
	UIKit.text(label, p.text)
	UIKit.bounce(button)
	button.Parent = p.parent
	return button
end

function UIKit.setText(button: GuiButton, text: string)
	(button:FindFirstChild("Label") :: TextLabel).Text = text
end

-- Columna de botones arriba a la izquierda. En móvil Roblox reserva las esquinas inferiores
-- (joystick dinámico abajo a la izquierda, desde ~43 % del alto; salto abajo a la derecha).
function UIKit.sideBar(parent: Instance): Frame
	local bar = new("Frame", {
		Name = "SideBar",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.01, 0.02),
		Size = UDim2.fromScale(0.12, 0.4),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, -- mismo tamaño en 19.5:9 y en 4:3
	}, parent)
	new("UIListLayout", {
		Padding = UDim.new(0.03, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Wraps = true, -- desde el 4.º botón abre otra columna en vez de bajar hacia el joystick
	}, bar)
	return bar
end

function UIKit.sideButton(bar: Instance, name: string, text: string, variant: Variant?, image: string?): TextButton
	local button = UIKit.button({
		name = name,
		text = text,
		variant = variant or "Info",
		size = UDim2.fromScale(1, 1),
		aspectRatio = 1,
		parent = bar,
	})
	if image then
		new("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			Image = image,
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.06),
			Size = UDim2.fromScale(0.8, 0.58),
		}, button)
		local label = button:FindFirstChild("Label") :: TextLabel
		label.Position = UDim2.fromScale(0.5, 0.82)
		label.Size = UDim2.fromScale(0.92, 0.3)
	end
	return button
end

-- Fila de monedas arriba al centro, debajo de la barra de Roblox.
function UIKit.currencyBar(parent: Instance): Frame
	local bar = new("Frame", {
		Name = "CurrencyBar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.01),
		Size = UDim2.fromScale(0.6, 0.1),
	}, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0.02, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, bar)
	return bar
end

-- Devuelve la etiqueta del monto; actualizarla con UIKit.setCurrency.
function UIKit.currency(bar: Instance, name: string, iconVariant: Variant?, image: string?): TextLabel
	local pill = new("Frame", { Name = name, Size = UDim2.fromScale(1, 1) }, bar)
	UIKit.style(pill, "Neutral", 0.5, 3)
	new("UIAspectRatioConstraint", { AspectRatio = 3 }, pill)
	new("UIScale", {}, pill)
	local iconProps = {
		Name = "Icon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.04, 0.5),
		Size = UDim2.fromScale(0.8, 0.8),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
	}
	if image then
		local icon = new("ImageLabel", iconProps, pill)
		icon.BackgroundTransparency = 1
		icon.Image = image
		icon.ScaleType = Enum.ScaleType.Fit
	else
		UIKit.style(new("Frame", iconProps, pill), iconVariant or "Premium", 0.5, 2)
	end
	local amount = new("TextLabel", {
		Name = "Amount",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.94, 0.5),
		Size = UDim2.fromScale(0.62, 0.75),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, pill)
	UIKit.text(amount, "0", 36)
	return amount
end

-- 1250 -> "1.2K". Trunca (no redondea) para no mostrar más de lo que se tiene.
function UIKit.formatNumber(n: number): string
	local sign = if n < 0 then "-" else ""
	n = math.abs(n)
	local i = 1
	while n >= 1000 and i < #SUFFIXES do
		n /= 1000
		i += 1
	end
	if i == 1 then
		return sign .. tostring(math.floor(n))
	end
	local s = string.format("%.1f", math.floor(n * 10 + 1e-9) / 10)
	return sign .. (s:gsub("%.0$", "")) .. SUFFIXES[i]
end

-- Llamar solo con el valor que confirmó el servidor.
function UIKit.setCurrency(amountLabel: TextLabel, value: number)
	amountLabel.Text = UIKit.formatNumber(value)
	local scale = (amountLabel.Parent :: Instance):FindFirstChildOfClass("UIScale")
	if scale then
		TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 1.15 }):Play()
		task.delay(0.08, function()
			TweenService:Create(scale, RELEASE, { Scale = 1 }):Play()
		end)
	end
end

-- Popup centrado, cerrado por defecto. Devuelve (popup, content): poner el contenido en `content`.
function UIKit.popup(parent: Instance, name: string, title: string): (Frame, Frame)
	local popup: Frame = new("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.6, 0.75),
		Visible = false,
	}, parent)
	UIKit.style(popup, "Neutral", 0.08, 4)
	new("UIAspectRatioConstraint", { AspectRatio = 1.4 }, popup)
	new("UIScale", { Scale = 0 }, popup)
	local titleLabel = new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.03),
		Size = UDim2.fromScale(0.7, 0.13),
	}, popup)
	UIKit.text(titleLabel, title, 60)
	local close = UIKit.button({
		name = "CloseButton",
		text = "X",
		variant = "Close",
		anchorPoint = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.97, 0.03), -- sobresale de la esquina
		size = UDim2.fromScale(0.14, 0.14),
		aspectRatio = 1,
		parent = popup,
	})
	close.SizeConstraint = Enum.SizeConstraint.RelativeYY
	close.Activated:Connect(function()
		UIKit.close(popup)
	end)
	local content: Frame = new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.04, 0.19),
		Size = UDim2.fromScale(0.92, 0.77),
	}, popup)
	return popup, content
end

-- Escala desde el centro. Cierra el popup abierto antes (uno a la vez, clave en móvil).
function UIKit.open(popup: GuiObject)
	if openPopup and openPopup ~= popup then
		UIKit.close(openPopup)
	end
	openPopup = popup
	local scale = popup:FindFirstChildOfClass("UIScale") :: UIScale
	scale.Scale = 0
	popup.Visible = true
	TweenService:Create(scale, OPEN, { Scale = 1 }):Play()
end

function UIKit.close(popup: GuiObject)
	if openPopup == popup then
		openPopup = nil
	end
	local scale = popup:FindFirstChildOfClass("UIScale") :: UIScale
	local tween = TweenService:Create(scale, CLOSE, { Scale = 0 })
	tween.Completed:Once(function(state)
		-- Si se reabrió durante el cierre, el tween se cancela y el popup sigue visible.
		if state == Enum.PlaybackState.Completed then
			popup.Visible = false
		end
	end)
	tween:Play()
end

function UIKit.toggle(popup: GuiObject)
	if openPopup == popup then
		UIKit.close(popup)
	else
		UIKit.open(popup)
	end
end

-- shortcut: notificaciones simultáneas se superponen; agregar cola si el juego lanza varias seguidas.
function UIKit.notify(screen: Instance, text: string, variant: Variant?)
	local hidden = UDim2.fromScale(0.5, -0.15)
	local pill = new("Frame", {
		Name = "Notification",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = hidden,
		Size = UDim2.fromScale(0.45, 0.08),
	}, screen)
	UIKit.style(pill, variant or "Info", 0.5, 3)
	new("UIAspectRatioConstraint", { AspectRatio = 6 }, pill)
	local label = new("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.75),
	}, pill)
	UIKit.text(label, text, 32)
	TweenService:Create(pill, OPEN, { Position = UDim2.fromScale(0.5, 0.12) }):Play()
	task.delay(2.5, function()
		local out = TweenService:Create(pill, CLOSE, { Position = hidden })
		out.Completed:Once(function()
			pill:Destroy()
		end)
		out:Play()
	end)
end

-- Ejecutar en Studio: require(ReplicatedStorage.Shared.UIKit).selfTest()
function UIKit.selfTest(): string
	assert(UIKit.formatNumber(0) == "0")
	assert(UIKit.formatNumber(999) == "999")
	assert(UIKit.formatNumber(1000) == "1K")
	assert(UIKit.formatNumber(1250) == "1.2K")
	assert(UIKit.formatNumber(4100) == "4.1K")
	assert(UIKit.formatNumber(999999) == "999.9K")
	assert(UIKit.formatNumber(1500000) == "1.5M")
	assert(UIKit.formatNumber(-2500) == "-2.5K")

	local screen = UIKit.screen("UIKitSelfTest")
	assert(screen.ScreenInsets == Enum.ScreenInsets.CoreUISafeInsets)
	local button = UIKit.button({ name = "B", text = "OK", parent = screen })
	for _, class in { "UICorner", "UIStroke", "UIGradient", "UIAspectRatioConstraint", "UISizeConstraint", "UIScale" } do
		assert(button:FindFirstChildOfClass(class), "falta " .. class)
	end
	assert(button.Size.X.Offset == 0 and button.Size.Y.Offset == 0, "botón con Offset")
	local popup, content = UIKit.popup(screen, "TestPopup", "Título")
	assert(popup:FindFirstChild("CloseButton") and content.Parent == popup and not popup.Visible)
	local amount = UIKit.currency(UIKit.currencyBar(screen), "Coins")
	UIKit.setCurrency(amount, 1250)
	assert(amount.Text == "1.2K")
	screen:Destroy()
	return "UIKit selfTest OK"
end

return UIKit
