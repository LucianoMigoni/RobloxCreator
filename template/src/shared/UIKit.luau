--!strict
-- UIKit: componentes de UI con el material de los hits (roblox-ui-designer/references/hud-hits.md y la
-- muestra hud-hits/muestra-kit.jpg).
-- - Botones de color plano con degradé, labio oscuro abajo, bisel claro adentro, brillo arriba, studs
--   y contorno oscuro grueso.
-- - Texto blanco gordo con contorno; números enormes.
-- - Ventanas con cabecera de color y franjas de brillo, ícono que se sale del marco, X roja en la
--   esquina y cuerpo gris carbón con studs.
-- - Ofertas flotando sobre rayos que giran, botones con el estilo de la barra de Roblox y precios con el
--   ícono de Robux.
-- Solo presentación: nunca cambia monedas ni inventario; eso lo confirma el servidor.
-- Tamaños en escala (los botones del HUD, relativos al alto de pantalla). Los contornos usan
-- StrokeSizingMode.ScaledSize: se ven igual en teléfono y en PC. Excepción: la barra de Roblox
-- (ScreenInsets TopbarSafeInsets) mide en píxeles porque Roblox fija su alto.

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local AssetIds = require("./Config/AssetIds")
local Icons = require("./Icons")

export type Variant =
	"Accept"
	| "Close"
	| "Premium"
	| "Info"
	| "Neutral"
	| "Purple"
	| "Pink"
	| "Orange"
	| "Cyan"
	| "Panel"
	| "Light"
	| "Dark"
	| "Rainbow"

export type MenuStyle = "wide" | "tile"

export type ButtonProps = {
	name: string,
	text: string,
	variant: Variant?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	aspectRatio: number?, -- 2.5 por defecto; 0 = sin relación fija (toma `size`, para botones en filas)
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
	style: MenuStyle?, -- "wide": ancho con ícono plano (Steal An Egg); "tile": cuadrado con ícono 3D (Anime Dice)
}

export type WindowProps = {
	name: string,
	title: string,
	icon: string?,
	variant: Variant?, -- color de la cabecera
	aspectRatio: number?, -- ancho/alto (1.45 por defecto: cabe acostado en el teléfono)
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

export type OfferProps = {
	name: string,
	label: string,
	icon: string,
	tag: string?, -- "OP!", "NEW!", "BEST VALUE!"
	headline: string?, -- texto arriba del ícono ("999x LUCK!")
	layoutOrder: number?,
}

export type TopbarProps = {
	name: string,
	label: string?, -- sin etiqueta: botón redondo solo con ícono (como el engranaje)
	icon: string,
	layoutOrder: number?,
}

export type Tab = { id: string, label: string, icon: string?, variant: Variant? }
export type Tabs = { frame: Frame, select: (id: string) -> (), selected: () -> string }

local UIKit = {}

type Palette = { base: Color3, dark: Color3 }

-- Colores por función, como en los hits: verde comprar y plata, celeste índice, rosa renacer, violeta
-- regalo e intercambio, rojo cerrar u oferta especial, amarillo y naranja premio y evento.
UIKit.Colors = {
	Accept = { base = Color3.fromRGB(70, 214, 75), dark = Color3.fromRGB(35, 166, 46) },
	Close = { base = Color3.fromRGB(255, 59, 79), dark = Color3.fromRGB(200, 30, 50) },
	Premium = { base = Color3.fromRGB(255, 210, 58), dark = Color3.fromRGB(242, 161, 15) },
	Info = { base = Color3.fromRGB(46, 197, 245), dark = Color3.fromRGB(27, 143, 214) },
	Neutral = { base = Color3.fromRGB(154, 160, 173), dark = Color3.fromRGB(107, 113, 128) },
	Purple = { base = Color3.fromRGB(163, 92, 255), dark = Color3.fromRGB(110, 43, 214) },
	Pink = { base = Color3.fromRGB(255, 92, 138), dark = Color3.fromRGB(224, 36, 94) },
	Orange = { base = Color3.fromRGB(255, 166, 43), dark = Color3.fromRGB(240, 106, 16) },
	Cyan = { base = Color3.fromRGB(47, 224, 200), dark = Color3.fromRGB(17, 168, 154) },
	Panel = { base = Color3.fromRGB(45, 47, 58), dark = Color3.fromRGB(31, 32, 41) },
	Light = { base = Color3.fromRGB(242, 244, 248), dark = Color3.fromRGB(205, 211, 224) },
	Dark = { base = Color3.fromRGB(25, 26, 34), dark = Color3.fromRGB(16, 17, 22) },
	Rainbow = { base = Color3.fromRGB(255, 92, 138), dark = Color3.fromRGB(163, 92, 255) },
} :: { [string]: Palette }
UIKit.STROKE_COLOR = Color3.fromRGB(20, 16, 32)
UIKit.TEXT_COLOR = Color3.new(1, 1, 1)
UIKit.MONEY_COLOR = Color3.fromRGB(93, 255, 74)
UIKit.Font = Font.fromEnum(Enum.Font.FredokaOne)
UIKit.TitleFont = Font.fromEnum(Enum.Font.FredokaOne)
-- La barra de Roblox y el ícono de Robux (el glifo U+E002 se dibuja con Builder Sans; según el DevForum,
-- no según la documentación oficial: probar en Studio y, si sale un cuadrado, usar AssetIds.icons.robux).
UIKit.TopbarFont = Font.fromEnum(Enum.Font.BuilderSansBold)
UIKit.ROBUX = utf8.char(0xE002)
UIKit.MIN_TOUCH_PX = 44 -- botones del HUD; Roblox no fija mínimo: 44 pt de la guía de Apple
-- Alto de pantalla (px) por debajo del cual es un teléfono acostado: las ventanas usan casi todo el alto
-- y las grillas tienen menos columnas, para que cada botón mida 44 px o más (audit_ui.luau).
UIKit.SMALL_SCREEN_PX = 500

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 92, 138)),
	ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 210, 58)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(70, 214, 75)),
	ColorSequenceKeypoint.new(0.78, Color3.fromRGB(46, 197, 245)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(163, 92, 255)),
})

local PRESS = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local OPEN = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local FILL = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SPIN = TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

-- Teléfono acostado (o pantalla igual de baja): ver SMALL_SCREEN_PX.
function UIKit.isSmallScreen(): boolean
	local camera = Workspace.CurrentCamera
	local height = if camera then camera.ViewportSize.Y else 0
	return height > 0 and height < UIKit.SMALL_SCREEN_PX
end

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

local function palette(variant: Variant?): Palette
	return UIKit.Colors[variant or "Neutral"] or UIKit.Colors.Neutral
end

local function lighten(c: Color3, t: number): Color3
	return c:Lerp(Color3.new(1, 1, 1), t)
end

-- Degradé de arriba abajo con el labio oscuro de los botones de los hits (la franja de abajo).
local function material(variant: Variant?, lip: boolean): ColorSequence
	if variant == "Rainbow" then
		return RAINBOW
	end
	local p = palette(variant)
	if not lip then
		return ColorSequence.new(lighten(p.base, 0.18), p.dark)
	end
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, lighten(p.base, 0.22)),
		ColorSequenceKeypoint.new(0.5, p.base),
		ColorSequenceKeypoint.new(0.83, p.base:Lerp(p.dark, 0.35)),
		ColorSequenceKeypoint.new(0.86, p.dark),
		ColorSequenceKeypoint.new(1, p.dark),
	})
end

-- Contorno con grosor relativo al tamaño (se ve igual en cualquier pantalla).
local function stroke(parent: Instance, name: string, thickness: number, color: Color3, transparency: number?, inner: boolean?): UIStroke
	local s = parent:FindFirstChild(name) :: UIStroke?
	if not s then
		s = new("UIStroke", { Name = name }, parent)
	end
	local st = s :: UIStroke
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
	st.Thickness = thickness
	st.Color = color
	st.Transparency = transparency or 0
	st.LineJoinMode = Enum.LineJoinMode.Round
	st.BorderStrokePosition = if inner then Enum.BorderStrokePosition.Inner else Enum.BorderStrokePosition.Outer
	return st
end

-- Imagen de assets/ui/hit-skin si el juego ya la subió (AssetIds.textures); si no, "".
function UIKit.textureId(name: string): string
	local id = AssetIds.textures[name]
	return if id and id ~= "" then id else ""
end

-- Mosaico de textura encima de un fondo (studs, damero, lunares). Sin la textura subida no hace nada.
function UIKit.texture(obj: GuiObject, name: string, tilePx: number?, transparency: number?, cornerScale: number?): ImageLabel?
	local id = UIKit.textureId(name)
	if id == "" then
		return nil
	end
	local layer = obj:FindFirstChild("Texture") :: ImageLabel?
	if not layer then
		layer = new("ImageLabel", {
			Name = "Texture",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ScaleType = Enum.ScaleType.Tile,
			ZIndex = obj.ZIndex,
		}, obj)
		new("UICorner", { CornerRadius = UDim.new(cornerScale or 0.18, 0) }, layer)
	end
	local l = layer :: ImageLabel
	l.Image = id
	-- Tamaño del mosaico en píxeles: es la escala de la textura, no un tamaño de layout.
	l.TileSize = UDim2.fromOffset(tilePx or 46, tilePx or 46)
	l.ImageTransparency = transparency or 0.7
	return l
end

-- Material de hit sobre cualquier Frame o botón.
function UIKit.style(obj: GuiObject, variant: Variant, cornerScale: number?, strokeScale: number?, texture: string?)
	obj.BackgroundColor3 = Color3.new(1, 1, 1) -- el UIGradient multiplica este color
	obj.BackgroundTransparency = 0
	obj.BorderSizePixel = 0
	local radius = cornerScale or 0.18
	local corner = obj:FindFirstChildOfClass("UICorner") or new("UICorner", {}, obj)
	corner.CornerRadius = UDim.new(radius, 0)
	stroke(obj, "Border", strokeScale or 0.05, UIKit.STROKE_COLOR)
	local gradient = obj:FindFirstChildOfClass("UIGradient") or new("UIGradient", {}, obj)
	gradient.Rotation = if variant == "Rainbow" then 25 else 90
	gradient.Color = material(variant, variant ~= "Panel" and variant ~= "Dark")
	if variant ~= "Panel" and variant ~= "Dark" then
		-- Bisel claro por dentro.
		local bevel = obj:FindFirstChild("Bevel") :: Frame?
		if not bevel then
			bevel = new("Frame", { Name = "Bevel", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = obj.ZIndex }, obj)
			new("UICorner", { CornerRadius = UDim.new(radius, 0) }, bevel)
		end
		stroke(bevel :: Frame, "Light", 0.035, Color3.new(1, 1, 1), 0.55, true)
		UIKit.gloss(obj, radius)
	end
	UIKit.texture(obj, texture or "studs", nil, if variant == "Panel" or variant == "Dark" then 0.86 else 0.7, radius)
end

-- Cambia el color de algo ya estilizado (pestaña elegida, botón que pasa a "Claim").
function UIKit.recolor(obj: GuiObject, variant: Variant)
	local gradient = obj:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Rotation = if variant == "Rainbow" then 25 else 90
		gradient.Color = material(variant, variant ~= "Panel" and variant ~= "Dark")
	end
end

-- Brillo blanco en la parte de arriba.
function UIKit.gloss(obj: GuiObject, cornerScale: number?)
	if obj:FindFirstChild("Gloss") then
		return
	end
	local gloss = new("Frame", {
		Name = "Gloss",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.07),
		Size = UDim2.fromScale(0.92, 0.38),
		ZIndex = obj.ZIndex,
	}, obj)
	new("UICorner", { CornerRadius = UDim.new(cornerScale or 0.18, 0) }, gloss)
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.62),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, gloss)
end

-- Texto blanco, fuente gorda, contorno oscuro relativo al tamaño de letra.
function UIKit.text(label: GuiObject, text: string, maxSize: number?, font: Font?, strokeScale: number?)
	local t: any = label
	t.Text = text
	t.FontFace = font or UIKit.Font
	t.TextColor3 = UIKit.TEXT_COLOR
	t.TextScaled = true
	t.AutoLocalize = true -- la traducción automática de Roblox solo captura texto con AutoLocalize
	t.BackgroundTransparency = 1
	local constraint = label:FindFirstChildOfClass("UITextSizeConstraint") or new("UITextSizeConstraint", {}, label)
	constraint.MinTextSize = 9
	constraint.MaxTextSize = maxSize or 56
	local s = label:FindFirstChild("TextStroke") :: UIStroke?
	if not s then
		s = new("UIStroke", { Name = "TextStroke" }, label)
	end
	local st = s :: UIStroke
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	st.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
	st.Thickness = strokeScale or 0.14
	st.Color = UIKit.STROKE_COLOR
	st.LineJoinMode = Enum.LineJoinMode.Round
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

-- Ícono 3D por nombre (shared/Icons): imagen si ya está subido, emoji si no. Devuelve un contenedor que
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

local function applyIcon(holder: Instance, resolved: Icons.Resolved)
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

function UIKit.setIcon(holder: Instance, key: string?)
	applyIcon(holder, Icons.resolve(key))
end

-- Ícono plano (assets/ui/icons-flat): blanco con contorno para botones de color, o blanco liso (`plain`)
-- para la barra de Roblox.
function UIKit.flatIcon(parent: Instance, key: string, plain: boolean?, props: { [string]: any }?): Frame
	local holder = UIKit.icon(parent, nil, props)
	applyIcon(holder, Icons.flat(key, plain))
	return holder
end

-- Rebote al presionar/soltar (mouse y toque). Usa UIScale para no tocar Size.
function UIKit.bounce(button: GuiButton)
	local scale = button:FindFirstChild("PressScale") or new("UIScale", { Name = "PressScale" }, button)
	local function isPress(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
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

-- Barra propia dentro de la barra de Roblox (a la derecha), como "Daily" o "Quests" en los hits.
function UIKit.topbar(parent: Instance?): Frame
	local gui = new("ScreenGui", {
		Name = "Topbar",
		ResetOnSpawn = false,
		DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets, -- el espacio libre de la barra (GuiService.TopbarInset)
	}, parent)
	local bar = new("Frame", { Name = "Bar", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, bar)
	new("UIPadding", { PaddingRight = UDim.new(0, 12) }, bar)
	return bar
end

-- Botón con el mismo estilo que los de Roblox: píldora oscura translúcida, ícono plano y texto.
function UIKit.topbarButton(bar: Instance, p: TopbarProps): TextButton
	local iconOnly = p.label == nil
	local button: TextButton = new("TextButton", {
		Name = p.name,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(18, 18, 21),
		BackgroundTransparency = 0.28,
		Size = UDim2.new(0, 0, 1, -8),
		AutomaticSize = if iconOnly then Enum.AutomaticSize.None else Enum.AutomaticSize.X,
		LayoutOrder = p.layoutOrder or 0,
	}, bar)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, button)
	if iconOnly then
		new("UIAspectRatioConstraint", { AspectRatio = 1 }, button)
	else
		new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 18) }, button)
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, button)
	end
	local icon = UIKit.flatIcon(button, p.icon, true, {
		Size = UDim2.fromScale(0.56, 0.56),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		LayoutOrder = 1,
	})
	if iconOnly then
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
	else
		new("TextLabel", {
			Name = "Label",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			FontFace = UIKit.TopbarFont,
			Text = p.label,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 18,
			AutoLocalize = true,
			LayoutOrder = 2,
		}, button)
	end
	UIKit.badgeOn(button, 0.36)
	UIKit.bounce(button)
	return button
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
	UIKit.style(button, p.variant or "Accept", 0.22)
	-- Sin mínimo en píxeles: dentro de una ventana todo escala junto, así nada se encima en el teléfono.
	local aspect = p.aspectRatio or 2.5
	if aspect > 0 then
		new("UIAspectRatioConstraint", { AspectRatio = aspect }, button)
	end
	-- El texto va en un hijo para tener margen interno sin UIPadding (que desplazaría íconos).
	local label = new("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.47),
		Size = UDim2.fromScale(0.86, 0.66),
		ZIndex = 3,
	}, button)
	UIKit.text(label, p.text)
	if p.icon then
		UIKit.icon(button, p.icon, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.05, 0.47),
			Size = UDim2.fromScale(0.95, 0.95),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			ZIndex = 3,
		})
		label.AnchorPoint = Vector2.new(1, 0.5)
		label.Position = UDim2.fromScale(0.94, 0.47)
		label.Size = UDim2.fromScale(0.6, 0.66)
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

-- Globito rojo de aviso (oculto hasta UIKit.setBadge).
function UIKit.badgeOn(button: GuiObject, sizeScale: number?): Frame
	local existing = button:FindFirstChild("Badge") :: Frame?
	if existing then
		return existing
	end
	local badge: Frame = new("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.95, 0.06),
		Size = UDim2.fromScale(sizeScale or 0.34, sizeScale or 0.34),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Visible = false,
		ZIndex = 8,
	}, button)
	UIKit.style(badge, "Close", 0.5, 0.08)
	local count = new("TextLabel", {
		Name = "Count",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromScale(0.72, 0.72),
		ZIndex = 9,
	}, badge)
	UIKit.text(count, "!", 28)
	new("UIScale", { Name = "Pulse" }, badge)
	return badge
end

-- Globito: número, "!" o nil para ocultarlo.
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

-- Reloj chico del botón ("02:15" en el regalo gratis): nil o "" lo oculta. En el botón ancho va arriba;
-- en el cuadrado reemplaza al nombre (arriba chocaría con la barra de Roblox en el teléfono).
function UIKit.setTimer(button: Instance, text: string?)
	local timer = button:FindFirstChild("Timer") :: Frame?
	local tile = button:GetAttribute("MenuStyle") == "tile"
	if not timer then
		local b = button :: GuiObject
		timer = new("Frame", {
			Name = "Timer",
			AnchorPoint = if tile then Vector2.new(0.5, 0.5) else Vector2.new(0.5, 1),
			Position = if tile then UDim2.fromScale(0.5, 0.9) else UDim2.fromScale(0.5, 0.02),
			Size = if tile then UDim2.fromScale(0.95, 0.3) else UDim2.fromScale(0.62, 0.22),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundColor3 = Color3.fromRGB(20, 16, 32),
			BackgroundTransparency = 0.25,
			ZIndex = b.ZIndex + 6,
		}, button)
		new("UICorner", { CornerRadius = UDim.new(0.45, 0) }, timer)
		local label = new("TextLabel", {
			Name = "Text",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.86, 0.8),
			ZIndex = b.ZIndex + 7,
		}, timer)
		UIKit.text(label, "", 26)
	end
	local t = timer :: Frame
	t.Visible = text ~= nil and text ~= ""
	local label = t:FindFirstChild("Text") :: TextLabel
	label.Text = text or ""
	local name = button:FindFirstChild("Label") :: TextLabel?
	if tile and name then
		name.Visible = not t.Visible
	end
end

-- Botón ancho del menú (Steal An Egg, Ride a Dino): color plano, ícono plano a la izquierda y nombre.
function UIKit.menuButton(p: HudButtonProps): TextButton
	local button: TextButton = new("TextButton", {
		Name = p.name,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 0.16),
		LayoutOrder = p.layoutOrder or 0,
	})
	UIKit.style(button, p.variant or "Info", 0.2, 0.05)
	new("UIAspectRatioConstraint", { AspectRatio = 3.25 }, button)
	new("UISizeConstraint", { MinSize = Vector2.new(UIKit.MIN_TOUCH_PX * 3, UIKit.MIN_TOUCH_PX) }, button)
	UIKit.flatIcon(button, p.icon, false, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.035, 0.47),
		Size = UDim2.fromScale(0.82, 0.82),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		ZIndex = 3,
	})
	local label = new("TextLabel", {
		Name = "Label",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.33, 0.46),
		Size = UDim2.fromScale(0.62, 0.62),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}, button)
	UIKit.text(label, p.label, 44)
	UIKit.badgeOn(button)
	UIKit.bounce(button)
	button:SetAttribute("MenuStyle", "wide")
	return button
end

-- Botón cuadrado del menú (Anime Dice, +1 Speed): ícono 3D grande que se sale por arriba y etiqueta
-- montada sobre el borde de abajo.
function UIKit.hudButton(p: HudButtonProps): TextButton
	if p.style == "wide" then
		return UIKit.menuButton(p)
	end
	local button: TextButton = new("TextButton", {
		Name = p.name,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		LayoutOrder = p.layoutOrder or 0,
	})
	UIKit.style(button, p.variant or "Info", 0.16, 0.045, "checker")
	new("UIAspectRatioConstraint", { AspectRatio = 1.04 }, button)
	new("UISizeConstraint", { MinSize = Vector2.new(UIKit.MIN_TOUCH_PX, UIKit.MIN_TOUCH_PX) }, button)
	UIKit.icon(button, p.icon, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromScale(0.94, 0.94),
		Rotation = -6,
		ZIndex = 4,
	})
	local label = new("TextLabel", {
		Name = "Label",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.9),
		Size = UDim2.fromScale(1.15, 0.3),
		ZIndex = 5,
	}, button)
	UIKit.text(label, p.label, 32)
	UIKit.badgeOn(button, 0.3)
	UIKit.bounce(button)
	button:SetAttribute("MenuStyle", "tile")
	return button
end

-- Columna del menú. "wide": lista de botones anchos; "tile": dos columnas de cuadrados. Va arriba de la
-- zona del joystick en el teléfono.
function UIKit.sideBar(parent: Instance, name: string?, rightSide: boolean?, style: MenuStyle?): Frame
	local tile = style ~= "wide"
	local bar = new("Frame", {
		Name = name or "SideBar",
		BackgroundTransparency = 1,
		AnchorPoint = if rightSide then Vector2.new(1, 0.5) else Vector2.new(0, 0.5),
		Position = if rightSide then UDim2.fromScale(0.988, 0.46) else UDim2.fromScale(0.012, 0.46),
		Size = if tile then UDim2.fromScale(0.3, 0.46) else UDim2.fromScale(0.25, 0.46),
		SizeConstraint = Enum.SizeConstraint.RelativeYY, -- mismo tamaño en 19.5:9 y en 4:3
	}, parent)
	if tile then
		new("UIGridLayout", {
			CellSize = UDim2.fromScale(0.44, 0.29),
			CellPadding = UDim2.fromScale(0.08, 0.05),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = if rightSide then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			StartCorner = if rightSide then Enum.StartCorner.TopRight else Enum.StartCorner.TopLeft,
		}, bar)
	else
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = if rightSide then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0.035, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, bar)
	end
	new("UISizeConstraint", { MinSize = Vector2.new(UIKit.MIN_TOUCH_PX, 0) }, bar)
	return bar
end

-- Botón de la barra (compatibilidad): igual que hudButton.
function UIKit.sideButton(bar: Instance, name: string, text: string, variant: Variant?, icon: string?): TextButton
	local button = UIKit.hudButton({ name = name, label = text, icon = icon or "star", variant = variant or "Info" })
	button.Parent = bar
	return button
end

-- Estadística suelta como en los hits: ícono 3D y número gordo con contorno, sin fondo. `heightScale` es
-- el alto relativo al contenedor. Devuelve el contenedor y la etiqueta del número.
function UIKit.stat(parent: Instance, name: string, icon: string?, color: Color3?, heightScale: number?): (Frame, TextLabel)
	local row: Frame = new("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, heightScale or 0.2),
	}, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.02, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	new("UIScale", { Name = "Pop" }, row)
	if icon then
		UIKit.icon(row, icon, {
			Size = UDim2.fromScale(1.15, 1.15),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			LayoutOrder = 1,
		})
	end
	local amount: TextLabel = new("TextLabel", {
		Name = "Amount",
		Size = UDim2.fromScale(5.5, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
	}, row)
	UIKit.text(amount, "0", 120, nil, 0.12)
	amount.TextColor3 = color or UIKit.TEXT_COLOR
	return row, amount
end

-- Compatibilidad con la UI anterior: la "barra de monedas" ahora es una columna de estadísticas.
function UIKit.currencyBar(parent: Instance): Frame
	local bar = new("Frame", {
		Name = "CurrencyBar",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0.02, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, bar)
	return bar
end

function UIKit.currency(bar: Instance, name: string, _variant: Variant?, icon: string?, _withPlus: boolean?): (TextLabel, TextButton?)
	local _, amount = UIKit.stat(bar, name, icon, nil, 0.3)
	return amount, nil
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
		TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 1.1 }):Play()
		task.delay(0.08, function()
			TweenService:Create(scale, RELEASE, { Scale = 1 }):Play()
		end)
	end
end

-- Barra de progreso: pista oscura, relleno verde con labio y el número grande encima ("3/8").
function UIKit.progressBar(parent: Instance, name: string, props: { [string]: any }?, fillVariant: Variant?): Frame
	local track = new("Frame", { Name = name, Size = UDim2.fromScale(1, 0.1) }, parent)
	if props then
		for key, value in props do
			track[key] = value
		end
	end
	UIKit.style(track, "Dark", 0.3, 0.05)
	local fill = new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		ZIndex = track.ZIndex,
	}, track)
	UIKit.style(fill, fillVariant or "Accept", 0.3, 0)
	local border = fill:FindFirstChild("Border") :: UIStroke
	border.Enabled = false
	local text = new("TextLabel", {
		Name = "Text",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.92, 0.72),
		ZIndex = track.ZIndex + 2,
	}, track)
	UIKit.text(text, "", 48)
	return track
end

function UIKit.setProgress(track: Instance, fraction: number, text: string?)
	local fill = track:FindFirstChild("Fill") :: Frame?
	if fill then
		local f = math.clamp(fraction, 0, 1)
		fill.Visible = f > 0.001
		TweenService:Create(fill, FILL, { Size = UDim2.fromScale(math.max(f, 0.05), 1) }):Play()
	end
	local label = track:FindFirstChild("Text") :: TextLabel?
	if label and text then
		label.Text = text
	end
end

-- Botón de compra: verde con el ícono de Robux y el precio ("⏣ 99"). Con `strike`, el precio tachado de
-- ancla arriba (solo si ese precio existió de verdad). Actualizar con UIKit.setPrice.
function UIKit.priceButton(parent: Instance, name: string, price: number?, props: { [string]: any }?, variant: Variant?, strike: number?): TextButton
	local button: TextButton = new("TextButton", {
		Name = name,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(0.9, 0.22),
	}, parent)
	if props then
		for key, value in props do
			(button :: any)[key] = value
		end
	end
	UIKit.style(button, variant or "Accept", 0.24, 0.05)
	local glyph = new("TextLabel", {
		Name = "Robux",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.1, 0.47),
		Size = UDim2.fromScale(0.62, 0.62),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		ZIndex = 3,
	}, button)
	UIKit.text(glyph, UIKit.ROBUX, 48, UIKit.TopbarFont, 0.16)
	glyph.AutoLocalize = false
	local label = new("TextLabel", {
		Name = "Label",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.92, 0.46),
		Size = UDim2.fromScale(0.62, 0.64),
		ZIndex = 3,
	}, button)
	UIKit.text(label, if price then UIKit.commas(price) else "...", 52)
	label.AutoLocalize = false
	if strike then
		local old = new("TextLabel", {
			Name = "Strike",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, -0.04),
			Size = UDim2.fromScale(0.7, 0.42),
			ZIndex = 4,
		}, button)
		UIKit.text(old, UIKit.commas(strike), 30)
		old.TextColor3 = Color3.fromRGB(255, 107, 107)
		old.AutoLocalize = false
		new("Frame", {
			Name = "Line",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromScale(0.62, 0.09),
			BackgroundColor3 = Color3.fromRGB(255, 70, 70),
			BorderSizePixel = 0,
			ZIndex = 5,
		}, old)
	end
	UIKit.bounce(button)
	return button
end

function UIKit.setPrice(button: Instance, price: number)
	local label = button:FindFirstChild("Label") :: TextLabel?
	if label then
		label.Text = UIKit.commas(price)
	end
end

-- 1234567 -> "1,234,567" (precios en Robux: siempre exactos).
function UIKit.commas(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- Compatibilidad: píldora de precio. Sin `currencyIcon` es Robux; con ícono, moneda del juego (amarilla).
function UIKit.pricePill(parent: Instance, name: string, price: string, currencyIcon: string?, props: { [string]: any }?): TextButton
	if currencyIcon == nil then
		local number = tonumber((price:gsub("[^%d]", "")))
		local button = UIKit.priceButton(parent, name, number, props)
		if not number then
			UIKit.setText(button, price)
		end
		return button
	end
	local button = UIKit.button({
		name = name,
		text = price,
		variant = "Premium",
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

-- Botón de regalo violeta al lado de cada compra.
function UIKit.giftButton(parent: Instance, props: { [string]: any }?): TextButton
	local button: TextButton = new("TextButton", {
		Name = "Gift",
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(0.2, 0.2),
	}, parent)
	if props then
		for key, value in props do
			(button :: any)[key] = value
		end
	end
	UIKit.style(button, "Purple", 0.24, 0.06)
	new("UIAspectRatioConstraint", { AspectRatio = 1 }, button)
	UIKit.flatIcon(button, "gift", true, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.47),
		Size = UDim2.fromScale(0.72, 0.72),
		ZIndex = 3,
	})
	UIKit.bounce(button)
	return button
end

-- Calcomanía inclinada ("BEST VALUE!", "NEW!", "OP!") sobre la esquina de una tarjeta o botón.
function UIKit.ribbon(parent: Instance, text: string, variant: Variant?): Frame
	local ribbon = new("Frame", {
		Name = "Ribbon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.24, 0.05),
		Size = UDim2.fromScale(0.56, 0.13),
		Rotation = -9,
		ZIndex = 8,
	}, parent)
	UIKit.style(ribbon, variant or "Close", 0.3, 0.07)
	new("UIAspectRatioConstraint", { AspectRatio = 3.4 }, ribbon)
	local label = new("TextLabel", {
		Name = "Text",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromScale(0.88, 0.7),
		ZIndex = 9,
	}, ribbon)
	UIKit.text(label, text, 30)
	return ribbon
end

-- Tarjeta (tienda, índice, recompensas): degradé del color, damero, ícono grande, nombre, efecto en una
-- línea y pie (`Footer`) para el precio o el botón.
function UIKit.card(parent: Instance, p: CardProps): Frame
	local card = new("Frame", { Name = p.name, LayoutOrder = p.layoutOrder or 0, Size = UDim2.fromScale(1, 1) }, parent)
	UIKit.style(card, p.variant or "Info", 0.1, 0.03, "checker")
	-- Pie alto (26%): en el teléfono, con 2 columnas, el botón llega a 44 px.
	local icon = UIKit.icon(card, p.icon, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.04),
		Size = UDim2.fromScale(0.62, 0.38),
		ZIndex = 3,
	})
	new("UIAspectRatioConstraint", { AspectRatio = 1 }, icon)
	local title = new("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.92, 0.13),
		ZIndex = 3,
	}, card)
	UIKit.text(title, p.title, 36)
	local desc = new("TextLabel", {
		Name = "Desc",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.555),
		Size = UDim2.fromScale(0.9, 0.12),
		ZIndex = 3,
		Visible = p.desc ~= nil,
	}, card)
	UIKit.text(desc, p.desc or "", 24)
	new("Frame", {
		Name = "Footer",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.965),
		Size = UDim2.fromScale(0.92, 0.26),
		ZIndex = 3,
	}, card)
	return card
end

-- Modelo 3D dentro de la UI (mascota, huevo). `silhouette`: en negro, para lo que todavía no se
-- encontró en el índice. Encuadra solo el modelo.
function UIKit.viewport(parent: Instance, model: Model, silhouette: boolean?, props: { [string]: any }?): ViewportFrame
	local frame: ViewportFrame = new("ViewportFrame", {
		Name = "Viewport",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Ambient = if silhouette then Color3.new(0, 0, 0) else Color3.fromRGB(200, 200, 200),
		LightColor = if silhouette then Color3.new(0, 0, 0) else Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-0.6, -1, -0.7),
	}, parent)
	if props then
		for key, value in props do
			(frame :: any)[key] = value
		end
	end
	if silhouette then
		frame.ImageColor3 = Color3.fromRGB(24, 20, 34)
	end
	local clone = model:Clone()
	clone.Parent = frame
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.Parent = frame
	frame.CurrentCamera = camera
	local cf, size = clone:GetBoundingBox()
	local radius = size.Magnitude / 2
	local distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * 1.05
	local eye = cf.Position + (cf.LookVector * -1 + Vector3.new(0.35, 0.3, 0)).Unit * distance
	camera.CFrame = CFrame.lookAt(eye, cf.Position)
	return frame
end

-- Alto que sigue al ancho (ancho/alto = `aspect`), en píxeles, para filas dentro de listas con scroll.
-- No se usa UIAspectRatioConstraint con alto 0 porque la documentación no dice qué hace con un eje en
-- cero; esto da el mismo resultado en cualquier pantalla. `minPx`: alto mínimo (filas con botones en el
-- teléfono). Se recalcula si cambia el ancho. El atributo FitHeight le avisa a audit_ui.luau.
function UIKit.fitHeight(obj: GuiObject, aspect: number, minPx: number?)
	obj:SetAttribute("FitHeight", aspect)
	local function update()
		local width = obj.AbsoluteSize.X
		if width > 0 then
			local height = math.max(math.floor(width / aspect + 0.5), minPx or 0)
			obj.Size = UDim2.new(obj.Size.X, UDim.new(0, height))
		end
	end
	obj:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	update()
end

-- Lo mismo para las celdas de una grilla: el ancho sale de CellSize y el alto se calcula.
function UIKit.fitCells(layout: UIGridLayout, aspect: number)
	local function update()
		local width = layout.AbsoluteCellSize.X
		if width > 0 then
			layout.CellSize = UDim2.new(layout.CellSize.X, UDim.new(0, math.floor(width / aspect + 0.5)))
		end
	end
	layout:GetPropertyChangedSignal("AbsoluteCellSize"):Connect(update)
	task.defer(update)
end

-- Grilla con scroll (tienda, índice, inventario). `cell` es el tamaño de cada celda relativo a la grilla
-- (solo cuenta el ancho si hay `aspect`).
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
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.5,
		ElasticBehavior = Enum.ElasticBehavior.Always,
	}, parent)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 14), -- lugar para la barra de scroll
	}, scroll)
	local layout = new("UIGridLayout", {
		CellSize = if aspect then UDim2.new(cell.X, UDim.new(0, 100)) else cell,
		-- Alto en píxeles: en un ScrollingFrame que crece con su contenido, la escala vertical se movería.
		CellPadding = UDim2.new(0.025, 0, 0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, scroll)
	if aspect then
		UIKit.fitCells(layout, aspect)
	end
	return scroll
end

-- Lista vertical con scroll (tienda por secciones, misiones, ajustes).
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
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.5,
	}, parent)
	new("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, scroll)
	new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 14), PaddingRight = UDim.new(0, 12) }, scroll)
	return scroll
end

-- Título de sección centrado entre dos líneas ("FEATURED", "Game Passes"), para listas con scroll.
function UIKit.section(parent: Instance, title: string, order: number, color: Color3?): Frame
	local row = new("Frame", {
		Name = "Section_" .. title,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.96, 0, 0, 40),
		LayoutOrder = order,
	}, parent)
	UIKit.fitHeight(row, 16)
	for _, side in { 0, 1 } do
		new("Frame", {
			Name = "Line" .. side,
			AnchorPoint = Vector2.new(side, 0.5),
			Position = UDim2.fromScale(side, 0.5),
			Size = UDim2.fromScale(0.3, 0.09),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.72,
			BorderSizePixel = 0,
		}, row)
	end
	local label = new("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.38, 0.86),
		ZIndex = 3,
	}, row)
	UIKit.text(label, title, 44)
	if color then
		label.TextColor3 = color
	end
	return row
end

-- Fila de tarjetas dentro de una lista con scroll: crece con su contenido.
function UIKit.row(parent: Instance, name: string, order: number, columns: number, aspect: number): Frame
	local row = new("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.96, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
	}, parent)
	local layout = new("UIGridLayout", {
		CellSize = UDim2.new((1 - 0.03 * (columns - 1)) / columns, 0, 0, 100),
		CellPadding = UDim2.new(0.03, 0, 0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, row)
	UIKit.fitCells(layout, aspect)
	return row
end

-- Pestañas en fila (variantes del índice, secciones). Llenan el alto de la fila y se reparten el ancho
-- sin pasar del 30% cada una, así nunca se enciman en el teléfono: la fila debe medir 40 px o más.
-- Con `variant`, cada pestaña tiene siempre su color (Normal, Golden, Rainbow) y la elegida crece con
-- borde blanco; sin `variant`, la elegida es clara y las demás grises. `onSelect(id)` al tocar otra.
function UIKit.tabs(parent: Instance, tabs: { Tab }, onSelect: (string) -> ()): Tabs
	local frame = new("Frame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.12),
	}, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.02, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, frame)
	local buttons: { [string]: TextButton } = {}
	local colored: { [string]: boolean } = {}
	local current = tabs[1] and tabs[1].id or ""
	local width = math.min(0.3, (1 - 0.02 * (#tabs - 1)) / math.max(#tabs, 1))
	local function select(id: string)
		current = id
		for tabId, button in buttons do
			local on = tabId == id
			if colored[tabId] then
				local border = button:FindFirstChild("Border") :: UIStroke
				border.Color = if on then Color3.new(1, 1, 1) else UIKit.STROKE_COLOR
			else
				UIKit.recolor(button, if on then "Light" else "Panel")
			end
			local scale = button:FindFirstChild("Selected") :: UIScale
			TweenService:Create(scale, RELEASE, { Scale = if on then 1.06 else 1 }):Play()
		end
	end
	for i, tab in tabs do
		local button: TextButton = new("TextButton", {
			Name = tab.id,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromScale(width, 0.92),
			LayoutOrder = i,
		}, frame)
		UIKit.style(button, tab.variant or "Panel", 0.28, 0.06)
		local label = new("TextLabel", {
			Name = "Label",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.47),
			Size = UDim2.fromScale(0.86, 0.66),
			ZIndex = 3,
		}, button)
		UIKit.text(label, tab.label, 40)
		if tab.icon then
			UIKit.icon(button, tab.icon, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0.04, 0.47),
				Size = UDim2.fromScale(0.9, 0.9),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 3,
			})
			label.AnchorPoint = Vector2.new(1, 0.5)
			label.Position = UDim2.fromScale(0.95, 0.47)
			label.Size = UDim2.fromScale(0.62, 0.66)
		end
		-- Sin UIKit.bounce: su UIScale ya se usa para agrandar la elegida.
		new("UIScale", { Name = "Selected" }, button)
		buttons[tab.id] = button
		colored[tab.id] = tab.variant ~= nil
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

-- Ventana grande: cabecera de color con franjas de brillo, título a la izquierda con el ícono saliéndose
-- del marco, X roja montada en la esquina y cuerpo gris carbón con studs (`Body`). Cerrada por defecto;
-- abrir con UIKit.open.
function UIKit.window(parent: Instance, p: WindowProps): (Frame, Frame)
	local window: Frame = new("Frame", {
		Name = p.name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.52, 0.54),
		Size = UDim2.fromScale(p.widthScale or 0.66, 0.84),
		Visible = false,
		ZIndex = 20,
	}, parent)
	UIKit.style(window, "Panel", 0.03, 0.008)
	new("UIAspectRatioConstraint", { AspectRatio = p.aspectRatio or 1.45 }, window)
	new("UIScale", { Scale = 0 }, window)
	-- En el teléfono acostado el alto es lo que falta: la ventana usa casi todo (tapa el HUD, como en los
	-- hits; detrás queda el fondo oscuro de UI/Windows).
	local screen = if parent:IsA("ScreenGui") then parent else parent:FindFirstAncestorOfClass("ScreenGui")
	if screen then
		local function fit()
			local small = UIKit.isSmallScreen()
			window.Position = if small then UDim2.fromScale(0.5, 0.53) else UDim2.fromScale(0.52, 0.54)
			window.Size = if small then UDim2.fromScale(0.96, 0.9) else UDim2.fromScale(p.widthScale or 0.66, 0.84)
		end
		screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
		fit()
	end
	local head: Frame = new("Frame", {
		Name = "Head",
		Size = UDim2.fromScale(1, 0.125),
		ZIndex = 21,
	}, window)
	UIKit.style(head, p.variant or "Info", 0.24, 0)
	local headBorder = head:FindFirstChild("Border") :: UIStroke
	headBorder.Enabled = false
	local stripesId = UIKit.textureId("stripes")
	if stripesId ~= "" then
		new("ImageLabel", {
			Name = "Stripes",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = stripesId,
			ImageTransparency = 0.5,
			ScaleType = Enum.ScaleType.Stretch,
			ZIndex = 21,
		}, head)
	end
	new("Frame", {
		Name = "Line",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0.06),
		BackgroundColor3 = UIKit.STROKE_COLOR,
		BorderSizePixel = 0,
		ZIndex = 22,
	}, head)
	local titleX = 0.03
	if p.icon then
		UIKit.icon(window, p.icon, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.065, 0.03),
			Size = UDim2.fromScale(0.17, 0.17),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Rotation = -8,
			ZIndex = 25,
		})
		titleX = 0.125
	end
	local title = new("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(titleX, 0.46),
		Size = UDim2.fromScale(0.62, 0.68),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 24,
	}, head)
	UIKit.text(title, p.title, 72)
	local close = UIKit.button({
		name = "CloseButton",
		text = "X",
		variant = "Close",
		anchorPoint = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.985, 0.025), -- montada en la esquina
		size = UDim2.fromScale(0.11, 0.11),
		aspectRatio = 1,
		parent = window,
	})
	close.SizeConstraint = Enum.SizeConstraint.RelativeYY
	close.ZIndex = 26
	close.Activated:Connect(function()
		UIKit.close(window)
	end)
	local body: Frame = new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.97),
		Size = UDim2.fromScale(0.95, 0.82),
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

-- Rayos de sol girando detrás de algo (oferta, premio, mascota nueva). Sin la textura subida no hace nada.
function UIKit.sunburst(parent: GuiObject, color: Color3?, scale: number?, transparency: number?): ImageLabel?
	local id = UIKit.textureId("sunburst")
	if id == "" then
		return nil
	end
	local rays: ImageLabel = new("ImageLabel", {
		Name = "Rays",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromScale(scale or 1.45, scale or 1.45),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		Image = id,
		ImageColor3 = color or Color3.new(1, 1, 1),
		ImageTransparency = transparency or 0.15,
		ZIndex = parent.ZIndex,
	}, parent)
	TweenService:Create(rays, SPIN, { Rotation = 360 }):Play()
	return rays
end

-- Oferta flotando (VIP, 2x Cash, giro del premio mayor): rayos, ícono 3D, etiqueta inclinada, nombre y
-- precio en Robux. Es un botón transparente; actualizar el precio con UIKit.setPrice.
function UIKit.offer(parent: Instance, p: OfferProps): TextButton
	local button: TextButton = new("TextButton", {
		Name = p.name,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		LayoutOrder = p.layoutOrder or 0,
		ZIndex = 2,
	}, parent)
	new("UIAspectRatioConstraint", { AspectRatio = 1 }, button)
	UIKit.sunburst(button, nil, 1.35, 0.2)
	UIKit.icon(button, p.icon, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromScale(0.62, 0.62),
		ZIndex = 4,
	})
	if p.tag then
		local tag = new("TextLabel", {
			Name = "Tag",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.86, 0.12),
			Size = UDim2.fromScale(0.42, 0.2),
			Rotation = 14,
			ZIndex = 6,
		}, button)
		UIKit.text(tag, p.tag, 48)
		tag.TextColor3 = Color3.fromRGB(255, 75, 92)
	end
	if p.headline then
		local headline = new("TextLabel", {
			Name = "Headline",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.06),
			Size = UDim2.fromScale(1.05, 0.18),
			ZIndex = 6,
		}, button)
		UIKit.text(headline, p.headline, 40)
		headline.TextColor3 = Color3.fromRGB(255, 225, 79)
	end
	local name = new("TextLabel", {
		Name = "Name",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.68),
		Size = UDim2.fromScale(1, 0.17),
		ZIndex = 5,
	}, button)
	UIKit.text(name, p.label, 44)
	local price = new("Frame", {
		Name = "Price",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.84),
		Size = UDim2.fromScale(0.8, 0.17),
		ZIndex = 5,
	}, button)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.03, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, price)
	local glyph = new("TextLabel", {
		Name = "Robux",
		Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		LayoutOrder = 1,
		ZIndex = 5,
	}, price)
	UIKit.text(glyph, UIKit.ROBUX, 44, UIKit.TopbarFont, 0.16)
	glyph.TextColor3 = UIKit.MONEY_COLOR
	glyph.AutoLocalize = false
	local label = new("TextLabel", {
		Name = "Label",
		Size = UDim2.fromScale(2.6, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
		ZIndex = 5,
	}, price)
	UIKit.text(label, "...", 44)
	label.TextColor3 = UIKit.MONEY_COLOR
	label.AutoLocalize = false
	UIKit.bounce(button)
	return button
end

-- Objetivo de una línea arriba al centro, sobre franja oscura translúcida, con una línea chica debajo.
function UIKit.objective(parent: Instance): Frame
	local frame: Frame = new("Frame", {
		Name = "Objective",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.075),
		Size = UDim2.fromScale(0.62, 0.11),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Visible = false,
	}, parent)
	new("UIAspectRatioConstraint", { AspectRatio = 5.6 }, frame)
	local band = new("Frame", {
		Name = "Band",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(1.15, 0.62),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
	}, frame)
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, 0.68),
			NumberSequenceKeypoint.new(0.75, 0.68),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, band)
	local title = new("TextLabel", {
		Name = "Title",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.04),
		Size = UDim2.fromScale(1, 0.54),
		ZIndex = 3,
	}, frame)
	UIKit.text(title, "", 64)
	local sub = new("TextLabel", {
		Name = "Sub",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.64),
		Size = UDim2.fromScale(1, 0.32),
		ZIndex = 3,
		Visible = false,
	}, frame)
	UIKit.text(sub, "", 36)
	sub.TextColor3 = Color3.fromRGB(255, 225, 79)
	return frame
end

function UIKit.setObjective(frame: Frame, text: string?, sub: string?)
	frame.Visible = text ~= nil and text ~= ""
	local title = frame:FindFirstChild("Title") :: TextLabel
	title.Text = text or ""
	local subLabel = frame:FindFirstChild("Sub") :: TextLabel
	subLabel.Text = sub or ""
	subLabel.Visible = sub ~= nil and sub ~= ""
end

-- Avisos en fila arriba al centro ("2x Money activated!"): franja oscura, no se pisan, salen de a uno.
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
		Size = UDim2.fromScale(0.42, 0.07),
		ZIndex = 60,
	}, screen)
	UIKit.style(pill, item.variant, 0.4, 0.06)
	new("UIAspectRatioConstraint", { AspectRatio = 7 }, pill)
	if item.icon then
		UIKit.icon(pill, item.icon, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.06, 0.45),
			Size = UDim2.fromScale(1.45, 1.45),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			ZIndex = 62,
		})
	end
	local label = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.54, 0.47),
		Size = UDim2.fromScale(0.8, 0.7),
		ZIndex = 61,
	}, pill)
	UIKit.text(label, item.text, 36)
	TweenService:Create(pill, OPEN, { Position = UDim2.fromScale(0.5, 0.2) }):Play()
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
	assert(UIKit.formatNumber(999999) == "999.9K")
	assert(UIKit.formatNumber(1500000) == "1.5M")
	assert(UIKit.formatNumber(-2500) == "-2.5K")
	assert(UIKit.commas(3499) == "3,499" and UIKit.commas(99) == "99" and UIKit.commas(1234567) == "1,234,567")

	local screen = UIKit.screen("UIKitSelfTest")
	assert(screen.ScreenInsets == Enum.ScreenInsets.CoreUISafeInsets)
	local button = UIKit.button({ name = "B", text = "OK", parent = screen })
	for _, class in { "UICorner", "UIStroke", "UIGradient", "UIAspectRatioConstraint", "UIScale" } do
		assert(button:FindFirstChildOfClass(class), "falta " .. class)
	end
	assert(button.Size.X.Offset == 0 and button.Size.Y.Offset == 0, "botón con Offset")
	assert(not button:FindFirstChildOfClass("UISizeConstraint"), "mínimo en píxeles dentro de una ventana")
	local free = UIKit.button({ name = "Free", text = "OK", aspectRatio = 0, parent = screen })
	assert(not free:FindFirstChildOfClass("UIAspectRatioConstraint"), "aspectRatio 0 sin relación fija")
	local border = button:FindFirstChild("Border") :: UIStroke
	assert(border.StrokeSizingMode == Enum.StrokeSizingMode.ScaledSize, "contorno en píxeles")
	local window, body = UIKit.window(screen, { name = "TestWindow", title = "Title", icon = "shop" })
	assert(window:FindFirstChild("CloseButton") and window:FindFirstChild("Head") and body.Parent == window and not window.Visible)
	local wide = UIKit.hudButton({ name = "Shop", label = "Shop", icon = "shop", variant = "Accept", style = "wide" })
	wide.Parent = UIKit.sideBar(screen, "Left", false, "wide")
	UIKit.setBadge(wide, 3)
	assert((wide:FindFirstChild("Badge") :: Frame).Visible)
	UIKit.setBadge(wide, nil)
	assert(not (wide:FindFirstChild("Badge") :: Frame).Visible)
	local tile = UIKit.hudButton({ name = "Index", label = "Index", icon = "index" })
	UIKit.setTimer(tile, "02:15")
	assert((tile:FindFirstChild("Timer") :: Frame).Visible)
	local _, amount = UIKit.stat(screen, "Money", "cash", UIKit.MONEY_COLOR)
	UIKit.setCurrency(amount, 1250)
	assert(amount.Text == "1.2K")
	local buy = UIKit.priceButton(screen, "Buy", 99, nil, nil, 199)
	UIKit.setPrice(buy, 3499)
	assert(((buy:FindFirstChild("Label") :: TextLabel).Text) == "3,499" and buy:FindFirstChild("Strike"))
	local offer = UIKit.offer(screen, { name = "VIP", label = "VIP", icon = "crown", tag = "OP!" })
	assert(offer:FindFirstChild("Price") and offer:FindFirstChild("Tag"))
	local objective = UIKit.objective(screen)
	UIKit.setObjective(objective, "Steal an egg!", nil)
	assert(objective.Visible and not (objective:FindFirstChild("Sub") :: TextLabel).Visible)
	local bar = UIKit.progressBar(screen, "P")
	UIKit.setProgress(bar, 0.5, "1/2")
	assert(((bar:FindFirstChild("Text") :: TextLabel).Text) == "1/2")
	local picked = ""
	local tabs = UIKit.tabs(screen, { { id = "Normal", label = "Normal", variant = "Light" }, { id = "Golden", label = "Golden", variant = "Premium" } }, function(id)
		picked = id
	end)
	tabs.select("Golden")
	assert(tabs.selected() == "Golden" and picked == "", "select() no llama a onSelect")
	assert(((tabs.frame:FindFirstChild("Golden") :: Frame):FindFirstChild("Border") :: UIStroke).Color == Color3.new(1, 1, 1))
	local list = UIKit.list(screen, "List")
	local section = UIKit.section(list, "Featured", 1)
	assert(section.Size.Y.Scale == 0, "alto de sección en píxeles")
	local grid = UIKit.grid(screen, "Grid", UDim2.fromScale(0.3, 0), 1)
	assert((grid:FindFirstChildOfClass("UIGridLayout") :: UIGridLayout).CellSize.Y.Scale == 0 and not grid:FindFirstChildOfClass("UIAspectRatioConstraint"))
	local top = UIKit.topbar(screen)
	local daily = UIKit.topbarButton(top, { name = "Daily", label = "Daily", icon = "daily" })
	assert(daily:FindFirstChild("Label") and (top.Parent :: ScreenGui).ScreenInsets == Enum.ScreenInsets.TopbarSafeInsets)
	;(top.Parent :: Instance):Destroy()
	screen:Destroy()
	return "UIKit selfTest OK"
end

return UIKit
