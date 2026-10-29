--!strict
-- UIKit: componentes de UI con el estilo de los hits (skills/_shared/hits-2026.md §3.7 y
-- roblox-ui-designer/references/hud-hits.md): contorno oscuro grueso, degradé con brillo arriba,
-- esquinas redondeadas, íconos que se salen del borde, letra gorda blanca con contorno, ventanas con X
-- roja, pestañas píldora, tarjetas, píldoras de precio y globitos de aviso.
-- Solo presentación: nunca cambia monedas ni inventario; eso lo confirma el servidor.
-- Todo en escala (sin Offset) para que funcione igual en teléfono, tablet y PC.

local TweenService = game:GetService("TweenService")

local Icons = require("./Icons")

export type Variant = "Accept" | "Close" | "Premium" | "Info" | "Neutral" | "Purple" | "Pink" | "Orange" | "Cyan" | "Panel" | "Light"

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
	icon: string?, -- nombre de shared/Icons, a la izquierda del texto
}

export type HudButtonProps = {
	name: string,
	label: string,
	icon: string,
	variant: Variant?,
	layoutOrder: number?,
}

export type WindowProps = {
	name: string,
	title: string,
	icon: string?,
	variant: Variant?, -- color del cartel del título
	aspectRatio: number?, -- ancho/alto (1.55 por defecto: cabe acostado en el teléfono)
	widthScale: number?, -- ancho máximo relativo a la pantalla
}

export type CardProps = {
	name: string,
	title: string,
	desc: string?,
	icon: string?,
	variant: Variant?,
	layoutOrder: number?,
}

export type Tab = { id: string, label: string, icon: string? }
export type Tabs = { frame: Frame, select: (id: string) -> (), selected: () -> string }

local UIKit = {}

-- Degradé arriba → abajo. Reemplazar por la paleta del juego si la trae.
UIKit.Colors = {
	Accept = { Color3.fromRGB(122, 240, 72), Color3.fromRGB(38, 168, 38) },
	Close = { Color3.fromRGB(255, 98, 92), Color3.fromRGB(205, 28, 48) },
	Premium = { Color3.fromRGB(255, 226, 72), Color3.fromRGB(246, 148, 14) },
	Info = { Color3.fromRGB(88, 196, 255), Color3.fromRGB(28, 108, 236) },
	Neutral = { Color3.fromRGB(76, 82, 120), Color3.fromRGB(42, 46, 76) },
	Purple = { Color3.fromRGB(196, 118, 255), Color3.fromRGB(118, 48, 222) },
	Pink = { Color3.fromRGB(255, 128, 206), Color3.fromRGB(226, 46, 138) },
	Orange = { Color3.fromRGB(255, 176, 64), Color3.fromRGB(240, 96, 18) },
	Cyan = { Color3.fromRGB(96, 244, 232), Color3.fromRGB(18, 168, 204) },
	Panel = { Color3.fromRGB(58, 74, 150), Color3.fromRGB(30, 38, 92) },
	Light = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(206, 218, 240) },
}
UIKit.STROKE_COLOR = Color3.fromRGB(22, 18, 44)
UIKit.TEXT_COLOR = Color3.new(1, 1, 1)
UIKit.Font = Font.fromEnum(Enum.Font.FredokaOne)
UIKit.TitleFont = Font.fromEnum(Enum.Font.LuckiestGuy)
UIKit.MIN_TOUCH_PX = 44 -- Roblox no fija mínimo; 44 pt de la guía de Apple

local PRESS = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local OPEN = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local FILL = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

local openPopup: GuiObject? = nil
local opened = Instance.new("BindableEvent")
-- (popup, isOpen): para el sonido, el desenfoque y ocultar el HUD mientras hay una ventana.
UIKit.PopupToggled = opened.Event

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local inst: any = Instance.new(className)
	for key, value in props do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end
UIKit.new = new

-- Fondo con degradé, brillo arriba, esquinas redondeadas y borde grueso oscuro.
function UIKit.style(obj: GuiObject, variant: Variant, cornerScale: number?, strokePx: number?)
	local colors = (UIKit.Colors :: any)[variant] or UIKit.Colors.Neutral
	obj.BackgroundColor3 = Color3.new(1, 1, 1) -- el UIGradient multiplica este color
	obj.BackgroundTransparency = 0
	obj.BorderSizePixel = 0
	local corner = obj:FindFirstChildOfClass("UICorner") or new("UICorner", {}, obj)
	corner.CornerRadius = UDim.new(cornerScale or 0.25, 0)
	local stroke = obj:FindFirstChild("Border") or new("UIStroke", { Name = "Border" }, obj)
	stroke.Thickness = strokePx or 3
	stroke.Color = UIKit.STROKE_COLOR
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	local gradient = obj:FindFirstChildOfClass("UIGradient") or new("UIGradient", { Rotation = 90 }, obj)
	gradient.Color = ColorSequence.new(colors[1], colors[2])
	UIKit.gloss(obj, cornerScale)
end

-- Cambia el color de algo ya estilizado (pestaña elegida, botón que pasa a "Claim").
function UIKit.recolor(obj: GuiObject, variant: Variant)
	local colors = (UIKit.Colors :: any)[variant] or UIKit.Colors.Neutral
	local gradient = obj:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(colors[1], colors[2])
	end
end

-- Brillo blanco en la mitad de arriba: lo que hace que los botones de los hits parezcan caramelos.
function UIKit.gloss(obj: GuiObject, cornerScale: number?)
	if obj:FindFirstChild("Gloss") then
		return
	end
	local gloss = new("Frame", {
		Name = "Gloss",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.06),
		Size = UDim2.fromScale(0.9, 0.42),
		ZIndex = obj.ZIndex,
	}, obj)
	new("UICorner", { CornerRadius = UDim.new(cornerScale or 0.25, 0) }, gloss)
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.62),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, gloss)
end

-- Texto blanco, fuente gruesa, contorno oscuro, escalable con límite.
function UIKit.text(label: GuiObject, text: string, maxSize: number?, font: Font?)
	local t: any = label
	t.Text = text
	t.FontFace = font or UIKit.Font
	t.TextColor3 = UIKit.TEXT_COLOR
	t.TextScaled = true
	t.AutoLocalize = true -- la traducción automática de Roblox solo captura texto con AutoLocalize
	t.BackgroundTransparency = 1
	local constraint = label:FindFirstChildOfClass("UITextSizeConstraint") or new("UITextSizeConstraint", {}, label)
	constraint.MinTextSize = 8
	constraint.MaxTextSize = maxSize or 48
	if not label:FindFirstChild("TextStroke") then
		new("UIStroke", {
			Name = "TextStroke",
			Thickness = 2.5,
			Color = UIKit.STROKE_COLOR,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			LineJoinMode = Enum.LineJoinMode.Round,
		}, label)
	end
end

-- Etiqueta suelta con el estilo del juego.
function UIKit.label(parent: Instance, name: string, text: string, props: { [string]: any }?, maxSize: number?, font: Font?): TextLabel
	local label = new("TextLabel", { Name = name, BackgroundTransparency = 1 }, parent)
	if props then
		for key, value in props do
			label[key] = value
		end
	end
	UIKit.text(label, text, maxSize, font)
	return label
end

-- Ícono por nombre (shared/Icons): imagen si ya está subido, emoji si no. Devuelve un contenedor que
-- se actualiza con UIKit.setIcon.
function UIKit.icon(parent: Instance, key: string?, props: { [string]: any }?): Frame
	local holder = new("Frame", { Name = "Icon", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, parent)
	if props then
		for k, value in props do
			holder[k] = value
		end
	end
	new("ImageLabel", {
		Name = "Image",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = holder.ZIndex,
	}, holder)
	new("TextLabel", {
		Name = "Glyph",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		TextScaled = true,
		FontFace = UIKit.Font,
		TextColor3 = UIKit.TEXT_COLOR,
		AutoLocalize = false,
		ZIndex = holder.ZIndex,
	}, holder)
	UIKit.setIcon(holder, key)
	return holder
end

function UIKit.setIcon(holder: Instance, key: string?)
	local resolved = Icons.resolve(key)
	local image = holder:FindFirstChild("Image") :: ImageLabel?
	local glyph = holder:FindFirstChild("Glyph") :: TextLabel?
	if image then
		image.Image = resolved.image or ""
		image.Visible = resolved.image ~= nil
	end
	if glyph then
		glyph.Text = resolved.text or ""
		glyph.Visible = resolved.text ~= nil
	end
end

-- Rebote al presionar/soltar (mouse y toque). Usa UIScale para no tocar Size.
function UIKit.bounce(button: GuiButton)
	local scale = button:FindFirstChild("PressScale") or new("UIScale", { Name = "PressScale" }, button)
	local function isPress(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	button.InputBegan:Connect(function(input)
		if isPress(input) then
			TweenService:Create(scale, PRESS, { Scale = 0.88 }):Play()
		end
	end)
	button.InputEnded:Connect(function(input)
		if isPress(input) then
			TweenService:Create(scale, RELEASE, { Scale = 1 }):Play()
		end
	end)
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, RELEASE, { Scale = 1.06 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, RELEASE, { Scale = 1 }):Play()
	end)
end

function UIKit.screen(name: string, parent: Instance?, displayOrder: number?): ScreenGui
	return new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		DisplayOrder = displayOrder or 0,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets, -- evita notch y barra de Roblox
	}, parent)
end

function UIKit.button(p: ButtonProps): TextButton
	local button: TextButton = new("TextButton", {
		Name = p.name,
		Text = "",
		AutoButtonColor = false,
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
		ZIndex = 2,
	}, button)
	UIKit.text(label, p.text)
	if p.icon then
		UIKit.icon(button, p.icon, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.06, 0.5),
			Size = UDim2.fromScale(0.95, 0.95),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			ZIndex = 2,
		})
		label.AnchorPoint = Vector2.new(1, 0.5)
		label.Position = UDim2.fromScale(0.94, 0.5)
		label.Size = UDim2.fromScale(0.6, 0.7)
	end
	UIKit.bounce(button)
	button.Parent = p.parent
	return button
end

function UIKit.setText(button: GuiObject, text: string)
	local label = button:FindFirstChild("Label") :: TextLabel?
	if label then
		label.Text = text
	end
end

-- Columna de botones a la izquierda. En móvil Roblox reserva las esquinas inferiores (joystick
-- dinámico abajo a la izquierda desde ~43 % del alto; salto abajo a la derecha): la columna arranca
-- debajo de la barra de Roblox y abre otra columna en vez de bajar hacia el joystick.
function UIKit.sideBar(parent: Instance, name: string?, rightSide: boolean?): Frame
	local bar = new("Frame", {
		Name = name or "SideBar",
		BackgroundTransparency = 1,
		AnchorPoint = if rightSide then Vector2.new(1, 0) else Vector2.zero,
		Position = if rightSide then UDim2.fromScale(0.99, 0.2) else UDim2.fromScale(0.01, 0.2),
		Size = UDim2.fromScale(0.105, 0.5),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, -- mismo tamaño en 19.5:9 y en 4:3
	}, parent)
	new("UIGridLayout", {
		CellSize = UDim2.fromScale(1, 0.29),
		CellPadding = UDim2.fromScale(0.16, 0.06),
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = if rightSide then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Left,
		StartCorner = if rightSide then Enum.StartCorner.TopRight else Enum.StartCorner.TopLeft,
	}, bar)
	new("UISizeConstraint", { MinSize = Vector2.new(UIKit.MIN_TOUCH_PX, 0) }, bar)
	return bar
end

-- Botón de la barra (compatibilidad): igual que hudButton.
function UIKit.sideButton(bar: Instance, name: string, text: string, variant: Variant?, icon: string?): TextButton
	local button = UIKit.hudButton({ name = name, label = text, icon = icon or "star", variant = variant or "Info" })
	button.Parent = bar
	return button
end

-- Botón cuadrado del HUD como en los hits: ícono grande que se sale por arriba, etiqueta abajo
-- montada sobre el borde, globito rojo de aviso y lugar para un reloj ("02:15").
function UIKit.hudButton(p: HudButtonProps): TextButton
	local button: TextButton = new("TextButton", {
		Name = p.name,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		LayoutOrder = p.layoutOrder or 0,
	})
	UIKit.style(button, p.variant or "Info", 0.28, 3)
	new("UIAspectRatioConstraint", { AspectRatio = 1 }, button)
	new("UISizeConstraint", { MinSize = Vector2.new(UIKit.MIN_TOUCH_PX, UIKit.MIN_TOUCH_PX) }, button)
	UIKit.icon(button, p.icon, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.36),
		Size = UDim2.fromScale(1.08, 1.08),
		Rotation = -6,
		ZIndex = 3,
	})
	local label = new("TextLabel", {
		Name = "Label",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.9),
		Size = UDim2.fromScale(1.25, 0.36),
		ZIndex = 4,
	}, button)
	UIKit.text(label, p.label, 28, UIKit.TitleFont)
	local badge = new("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.92, 0.06),
		Size = UDim2.fromScale(0.42, 0.42),
		Visible = false,
		ZIndex = 5,
	}, button)
	UIKit.style(badge, "Close", 1, 2)
	local count = new("TextLabel", {
		Name = "Count",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.8),
		ZIndex = 6,
	}, badge)
	UIKit.text(count, "!", 24)
	new("UIScale", { Name = "Pulse" }, badge)
	UIKit.bounce(button)
	return button
end

-- Globito rojo: número, "!" o nil para ocultarlo.
function UIKit.setBadge(button: Instance, value: (number | string)?)
	local badge = button:FindFirstChild("Badge") :: Frame?
	if not badge then
		return
	end
	local show = value ~= nil and value ~= 0 and value ~= ""
	badge.Visible = show
	if show then
		local count = badge:FindFirstChild("Count") :: TextLabel
		count.Text = if typeof(value) == "number" then (if value > 99 then "99+" else tostring(value)) else tostring(value)
	end
end

-- Fila de monedas arriba al centro, debajo de la barra de Roblox.
function UIKit.currencyBar(parent: Instance): Frame
	local bar = new("Frame", {
		Name = "CurrencyBar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.01),
		Size = UDim2.fromScale(0.62, 0.085),
		ZIndex = 10, -- por encima de las ventanas: el saldo se ve mientras se compra
	}, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0.025, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, bar)
	return bar
end

-- Píldora de moneda: ícono que se sale a la izquierda, monto grande y "+" verde opcional para ir a la
-- tienda. Devuelve la etiqueta del monto (UIKit.setCurrency) y el botón "+" si se pidió.
function UIKit.currency(bar: Instance, name: string, iconVariantOrNil: Variant?, icon: string?, withPlus: boolean?): (TextLabel, TextButton?)
	local pill = new("Frame", { Name = name, Size = UDim2.fromScale(1, 1), ZIndex = 10 }, bar)
	UIKit.style(pill, iconVariantOrNil or "Neutral", 0.5, 3)
	new("UIAspectRatioConstraint", { AspectRatio = 3.4 }, pill)
	new("UIScale", { Name = "Pop" }, pill)
	UIKit.icon(pill, icon, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.08, 0.5),
		Size = UDim2.fromScale(1.35, 1.35),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		ZIndex = 12,
	})
	local amount = new("TextLabel", {
		Name = "Amount",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.27, 0.5),
		Size = UDim2.fromScale(if withPlus then 0.5 else 0.66, 0.78),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 12,
	}, pill)
	UIKit.text(amount, "0", 40, UIKit.TitleFont)
	local plus: TextButton? = nil
	if withPlus then
		local button = UIKit.button({
			name = "Plus",
			text = "+",
			variant = "Accept",
			anchorPoint = Vector2.new(1, 0.5),
			position = UDim2.fromScale(0.97, 0.5),
			size = UDim2.fromScale(0.8, 0.8),
			aspectRatio = 1,
			parent = pill,
		})
		button.SizeConstraint = Enum.SizeConstraint.RelativeYY
		button.ZIndex = 12
		plus = button
	end
	return amount, plus
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
		TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 1.12 }):Play()
		task.delay(0.08, function()
			TweenService:Create(scale, RELEASE, { Scale = 1 }):Play()
		end)
	end
end

-- Barra de progreso con texto encima ("3/5", "$1.2K / $10K"). Actualizar con UIKit.setProgress.
function UIKit.progressBar(parent: Instance, name: string, props: { [string]: any }?, fillVariant: Variant?): Frame
	local track = new("Frame", { Name = name, Size = UDim2.fromScale(1, 0.1) }, parent)
	if props then
		for key, value in props do
			track[key] = value
		end
	end
	UIKit.style(track, "Neutral", 0.5, 3)
	local fill = new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		ZIndex = track.ZIndex,
	}, track)
	UIKit.style(fill, fillVariant or "Accept", 0.5, 0)
	local border = fill:FindFirstChild("Border") :: UIStroke
	border.Enabled = false
	local text = new("TextLabel", {
		Name = "Text",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.92, 0.8),
		ZIndex = track.ZIndex + 1,
	}, track)
	UIKit.text(text, "", 30)
	return track
end

function UIKit.setProgress(track: Instance, fraction: number, text: string?)
	local fill = track:FindFirstChild("Fill") :: Frame?
	if fill then
		local f = math.clamp(fraction, 0, 1)
		fill.Visible = f > 0.001
		TweenService:Create(fill, FILL, { Size = UDim2.fromScale(math.max(f, 0.06), 1) }):Play()
	end
	local label = track:FindFirstChild("Text") :: TextLabel?
	if label and text then
		label.Text = text
	end
end

-- Píldora de precio: verde con "R$" para Robux; amarilla con el ícono de la moneda del juego.
function UIKit.pricePill(parent: Instance, name: string, price: string, currencyIcon: string?, props: { [string]: any }?): TextButton
	local robux = currencyIcon == nil
	local button = UIKit.button({
		name = name,
		text = if robux then "R$ " .. price else price,
		variant = if robux then "Accept" else "Premium",
		icon = currencyIcon,
		size = UDim2.fromScale(0.9, 0.22),
		aspectRatio = 3,
		parent = parent,
	})
	if props then
		for key, value in props do
			(button :: any)[key] = value
		end
	end
	return button
end

-- Calcomanía inclinada ("BEST VALUE", "NEW!", "x2"): sobre la esquina de una tarjeta o botón.
function UIKit.ribbon(parent: Instance, text: string, variant: Variant?): Frame
	local ribbon = new("Frame", {
		Name = "Ribbon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.22, 0.04),
		Size = UDim2.fromScale(0.62, 0.15),
		Rotation = -10,
		ZIndex = 8,
	}, parent)
	UIKit.style(ribbon, variant or "Orange", 0.4, 2)
	new("UIAspectRatioConstraint", { AspectRatio = 3.6 }, ribbon)
	local label = new("TextLabel", {
		Name = "Text",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.78),
		ZIndex = 9,
	}, ribbon)
	UIKit.text(label, text, 24, UIKit.TitleFont)
	return ribbon
end

-- Tarjeta de tienda/índice: degradé de color, ícono grande, nombre, efecto en una línea y pie para
-- el precio o el botón (`Footer`).
function UIKit.card(parent: Instance, p: CardProps): Frame
	local card = new("Frame", { Name = p.name, LayoutOrder = p.layoutOrder or 0, Size = UDim2.fromScale(1, 1) }, parent)
	UIKit.style(card, p.variant or "Info", 0.1, 3)
	UIKit.icon(card, p.icon, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.04),
		Size = UDim2.fromScale(0.62, 0.4),
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		ZIndex = 3,
	})
	local icon = card:FindFirstChild("Icon") :: Frame
	new("UIAspectRatioConstraint", { AspectRatio = 1 }, icon)
	local title = new("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.44),
		Size = UDim2.fromScale(0.92, 0.14),
		ZIndex = 3,
	}, card)
	UIKit.text(title, p.title, 30, UIKit.TitleFont)
	local desc = new("TextLabel", {
		Name = "Desc",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.58),
		Size = UDim2.fromScale(0.9, 0.16),
		ZIndex = 3,
		Visible = p.desc ~= nil,
	}, card)
	UIKit.text(desc, p.desc or "", 18)
	new("Frame", {
		Name = "Footer",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.97),
		Size = UDim2.fromScale(0.92, 0.2),
		ZIndex = 3,
	}, card)
	return card
end

-- Grilla con scroll (tienda, índice, inventario). `cell` es el tamaño de cada celda relativo a la grilla.
function UIKit.grid(parent: Instance, name: string, cell: UDim2, aspect: number?): ScrollingFrame
	local scroll = new("ScrollingFrame", {
		Name = name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = UIKit.STROKE_COLOR,
		ElasticBehavior = Enum.ElasticBehavior.Always,
	}, parent)
	new("UIPadding", {
		PaddingTop = UDim.new(0.03, 0),
		PaddingBottom = UDim.new(0.03, 0),
		PaddingLeft = UDim.new(0.02, 0),
		PaddingRight = UDim.new(0.03, 0),
	}, scroll)
	local layout = new("UIGridLayout", {
		CellSize = cell,
		CellPadding = UDim2.fromScale(0.025, 0.03),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, scroll)
	if aspect then
		new("UIAspectRatioConstraint", { AspectRatio = aspect }, layout)
	end
	return scroll
end

-- Lista vertical con scroll (misiones, ajustes).
function UIKit.list(parent: Instance, name: string): ScrollingFrame
	local scroll = new("ScrollingFrame", {
		Name = name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = UIKit.STROKE_COLOR,
	}, parent)
	new("UIListLayout", {
		Padding = UDim.new(0.02, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, scroll)
	new("UIPadding", { PaddingTop = UDim.new(0.02, 0), PaddingBottom = UDim.new(0.02, 0) }, scroll)
	return scroll
end

-- Pestañas píldora con el ícono asomando por arriba. `onSelect(id)` se llama al tocar una.
function UIKit.tabs(parent: Instance, tabs: { Tab }, onSelect: (string) -> ()): Tabs
	local frame = new("Frame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.13),
	}, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.015, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, frame)
	local buttons: { [string]: TextButton } = {}
	local current = tabs[1] and tabs[1].id or ""
	local function select(id: string)
		current = id
		for tabId, button in buttons do
			local on = tabId == id
			UIKit.recolor(button, if on then "Premium" else "Neutral")
			local scale = button:FindFirstChild("Selected") :: UIScale
			TweenService:Create(scale, RELEASE, { Scale = if on then 1.08 else 1 }):Play()
		end
	end
	for i, tab in tabs do
		local button = UIKit.button({
			name = tab.id,
			text = tab.label,
			variant = "Neutral",
			icon = tab.icon,
			size = UDim2.fromScale(math.min(0.24, 0.96 / #tabs), 0.85),
			aspectRatio = 3.1,
			layoutOrder = i,
			parent = frame,
		})
		new("UIScale", { Name = "Selected" }, button)
		buttons[tab.id] = button
		button.Activated:Connect(function()
			if current ~= tab.id then
				select(tab.id)
				onSelect(tab.id)
			end
		end)
	end
	select(current)
	return {
		frame = frame,
		select = select,
		selected = function()
			return current
		end,
	}
end

-- Ventana grande: cartel de color con el título arriba (montado sobre el borde), X roja en la esquina
-- y el cuerpo en `Body`. Cerrada por defecto; abrir con UIKit.open.
function UIKit.window(parent: Instance, p: WindowProps): (Frame, Frame)
	local window: Frame = new("Frame", {
		Name = p.name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.54),
		Size = UDim2.fromScale(p.widthScale or 0.72, 0.78),
		Visible = false,
		ZIndex = 20,
	}, parent)
	UIKit.style(window, "Panel", 0.06, 4)
	new("UIAspectRatioConstraint", { AspectRatio = p.aspectRatio or 1.55 }, window)
	new("UIScale", { Scale = 0 }, window)
	local banner = new("Frame", {
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.01),
		Size = UDim2.fromScale(0.46, 0.15),
		ZIndex = 22,
	}, window)
	UIKit.style(banner, p.variant or "Info", 0.35, 4)
	if p.icon then
		UIKit.icon(banner, p.icon, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.02, 0.45),
			Size = UDim2.fromScale(1.6, 1.6),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Rotation = -8,
			ZIndex = 24,
		})
	end
	local title = new("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.54, 0.5),
		Size = UDim2.fromScale(0.82, 0.82),
		ZIndex = 23,
	}, banner)
	UIKit.text(title, p.title, 64, UIKit.TitleFont)
	local close = UIKit.button({
		name = "CloseButton",
		text = "X",
		variant = "Close",
		anchorPoint = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.985, 0.03), -- sobresale de la esquina
		size = UDim2.fromScale(0.15, 0.15),
		aspectRatio = 1,
		parent = window,
	})
	close.SizeConstraint = Enum.SizeConstraint.RelativeYY
	close.ZIndex = 25
	local closeLabel = close:FindFirstChild("Label") :: TextLabel
	closeLabel.FontFace = UIKit.TitleFont
	close.Activated:Connect(function()
		UIKit.close(window)
	end)
	local body: Frame = new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.97),
		Size = UDim2.fromScale(0.94, 0.84),
		ZIndex = 21,
	}, window)
	return window, body
end

-- Popup centrado (compatibilidad): una ventana con el título dado. Devuelve (popup, content).
function UIKit.popup(parent: Instance, name: string, title: string): (Frame, Frame)
	return UIKit.window(parent, { name = name, title = title })
end

-- Escala desde el centro. Cierra la ventana abierta antes (una a la vez, clave en móvil).
function UIKit.open(popup: GuiObject)
	if openPopup and openPopup ~= popup then
		UIKit.close(openPopup)
	end
	openPopup = popup
	local scale = popup:FindFirstChildOfClass("UIScale") :: UIScale
	scale.Scale = 0
	popup.Visible = true
	TweenService:Create(scale, OPEN, { Scale = 1 }):Play()
	opened:Fire(popup, true)
end

function UIKit.close(popup: GuiObject)
	if openPopup == popup then
		openPopup = nil
	end
	if not popup.Visible then
		return
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
	opened:Fire(popup, false)
end

function UIKit.toggle(popup: GuiObject)
	if openPopup == popup then
		UIKit.close(popup)
	else
		UIKit.open(popup)
	end
end

function UIKit.isOpen(popup: GuiObject): boolean
	return openPopup == popup
end

function UIKit.current(): GuiObject?
	return openPopup
end

-- Avisos en fila arriba al centro ("2x Money activated!"): no se pisan, salen de a uno.
local queue: { { text: string, variant: Variant, icon: string? } } = {}
local showing = false

local function showNext(screen: Instance)
	local item = table.remove(queue, 1)
	if not item then
		showing = false
		return
	end
	showing = true
	local hidden = UDim2.fromScale(0.5, -0.15)
	local pill = new("Frame", {
		Name = "Notification",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = hidden,
		Size = UDim2.fromScale(0.5, 0.075),
		ZIndex = 60,
	}, screen)
	UIKit.style(pill, item.variant, 0.5, 3)
	new("UIAspectRatioConstraint", { AspectRatio = 7 }, pill)
	if item.icon then
		UIKit.icon(pill, item.icon, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.06, 0.5),
			Size = UDim2.fromScale(1.4, 1.4),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			ZIndex = 62,
		})
	end
	local label = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.53, 0.5),
		Size = UDim2.fromScale(0.82, 0.75),
		ZIndex = 61,
	}, pill)
	UIKit.text(label, item.text, 32)
	TweenService:Create(pill, OPEN, { Position = UDim2.fromScale(0.5, 0.12) }):Play()
	task.delay(2.2, function()
		local out = TweenService:Create(pill, CLOSE, { Position = hidden })
		out.Completed:Once(function()
			pill:Destroy()
			showNext(screen)
		end)
		out:Play()
	end)
end

function UIKit.notify(screen: Instance, text: string, variant: Variant?, icon: string?)
	table.insert(queue, { text = text, variant = variant or "Info", icon = icon })
	if not showing then
		showNext(screen)
	end
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
	local window, body = UIKit.window(screen, { name = "TestWindow", title = "Título", icon = "shop" })
	assert(window:FindFirstChild("CloseButton") and body.Parent == window and not window.Visible)
	local amount = UIKit.currency(UIKit.currencyBar(screen), "Coins", nil, "cash")
	UIKit.setCurrency(amount, 1250)
	assert(amount.Text == "1.2K")
	local hud = UIKit.hudButton({ name = "Shop", label = "Shop", icon = "shop", variant = "Close" })
	hud.Parent = screen
	UIKit.setBadge(hud, 3)
	assert((hud:FindFirstChild("Badge") :: Frame).Visible)
	UIKit.setBadge(hud, nil)
	assert(not (hud:FindFirstChild("Badge") :: Frame).Visible)
	local bar = UIKit.progressBar(screen, "P")
	UIKit.setProgress(bar, 0.5, "1/2")
	assert(((bar:FindFirstChild("Text") :: TextLabel).Text) == "1/2")
	screen:Destroy()
	return "UIKit selfTest OK"
end

return UIKit
