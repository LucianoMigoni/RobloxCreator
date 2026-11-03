--!strict
-- Índice estilo Steal An Egg y Anime Dice (roblox-ui-designer/references/hud-hits.md §Índice y la
-- muestra aprobada en hud-hits/muestra-kit.jpg):
-- - Zonas a la izquierda, con foto y candado si todavía no se abrieron.
-- - Variantes arriba (Normal, Golden, Rainbow), solo si el kit las usa.
-- - Tarjetas con el degradé de su rareza: lo descubierto con su modelo o ícono; lo que falta, en silueta
--   negra con "???". Cada una con su probabilidad ("1 in 400").
-- - A la derecha, la pieza elegida en grande con su rareza y lo que da, y el premio de la zona con CLAIM
--   (lo valida el servidor: ClaimIndexZone).
-- - Abajo, el total: "Unlocked: 3/112".
-- Las piezas las da el kit con Bus.handle("IndexEntries", ...) y las zonas, el servidor
-- (IndexService.setZones). Sin kit se ve solo el total.
-- Las partes se apilan con UIListLayout y UIFlexItem: en el teléfono se achican, pero nunca se enciman.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RarityConfig = require(ReplicatedStorage.Shared.Config.RarityConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Collection = require(ReplicatedStorage.Shared.Lib.Collection)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local RewardText = require(ReplicatedStorage.Shared.Lib.RewardText)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local PlayerState = require("../PlayerState")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local IndexController = {}

-- Lo que el kit devuelve por cada cosa coleccionable.
export type Entry = {
	key: string, -- el mismo que usa IndexService.discover ("Kitty|Normal")
	name: string,
	zone: string?, -- id de la zona (IndexService.setZones); sin zona, va a la primera
	variant: string?, -- pestaña de arriba ("Normal", "Golden", "Rainbow")
	rarity: string?, -- RarityConfig.TIERS[].id: color de la tarjeta
	chance: number?, -- probabilidad de 0 a 1: "1 in 400"
	detail: string?, -- lo que da, ya con formato ("$12/s", "+500 Speed")
	icon: string?, -- nombre de shared/Icons o rbxassetid
	model: Model?, -- si está, se ve en 3D (y en silueta mientras falte)
	order: number?,
}

local player = Players.LocalPlayer

local GAP = 8 -- píxeles entre bloques
local SMALL_SCREEN = 500 -- alto en píxeles: menos es un teléfono acostado (3 columnas en vez de 4)
local ALL = "" -- id de la zona única cuando el kit no usa zonas

local VARIANT_COLORS: { [string]: UIKit.Variant } = {
	Normal = "Light",
	Gold = "Premium",
	Golden = "Premium",
	Diamond = "Cyan",
	Shiny = "Cyan",
	Rainbow = "Rainbow",
	Galaxy = "Purple",
	Big = "Orange",
	Huge = "Purple",
	Titanic = "Close",
}
local ZONE_COLORS: { UIKit.Variant } = { "Accept", "Info", "Orange", "Purple", "Pink", "Cyan" }

local tiers: { [string]: RarityConfig.Tier } = {}
for _, tier in RarityConfig.TIERS do
	tiers[tier.id] = tier
end

local function invoke(name: string, ...: any): (boolean, string?)
	local args = table.pack(...)
	local ok, result, reason = pcall(function()
		return Net.func(name):InvokeServer(table.unpack(args, 1, args.n))
	end)
	if not ok then
		return false, "NETWORK"
	end
	return result == true, reason
end

-- Contenedor que apila sus hijos en fila o en columna.
local function stack(parent: Instance, name: string, horizontal: boolean, size: UDim2, order: number): Frame
	local frame = UIKit.new("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = size,
		LayoutOrder = order,
	}, parent) :: Frame
	UIKit.new("UIListLayout", {
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		Padding = UDim.new(0, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, frame)
	return frame
end

-- Ocupa lo que dejan libre los demás de su fila o columna.
local function fill<T>(obj: T): T
	UIKit.new("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, obj :: any)
	return obj
end

-- Alto mínimo en píxeles para leer en el teléfono. Dentro de una columna con UIFlexItem no encima nada:
-- lo que falta lo pone el bloque que se estira.
local function atLeast(obj: GuiObject, x: number, y: number)
	UIKit.new("UISizeConstraint", { MinSize = Vector2.new(x, y) }, obj)
end

-- Degradé del color de la rareza sobre algo ya estilizado.
local function tint(obj: GuiObject, color: Color3)
	local gradient = obj:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color:Lerp(Color3.new(1, 1, 1), 0.35)),
			ColorSequenceKeypoint.new(0.55, color),
			ColorSequenceKeypoint.new(1, color:Lerp(Color3.new(0, 0, 0), 0.35)),
		})
	end
end

local function rarityStyle(obj: GuiObject, rarity: string?)
	local tier = if rarity then tiers[rarity] else nil
	if tier and tier.rainbow then
		UIKit.style(obj, "Rainbow", 0.12, 0.035, "checker")
		return
	end
	UIKit.style(obj, "Neutral", 0.12, 0.035, "checker")
	if tier then
		tint(obj, tier.color)
	end
end

-- Arte de una pieza: modelo 3D o ícono, en silueta negra si todavía no se descubrió.
local function art(parent: Instance, entry: Entry, found: boolean, props: { [string]: any })
	local model = entry.model
	if model then
		UIKit.viewport(parent, model, not found, props)
		return
	end
	local icon = UIKit.icon(parent, entry.icon, props)
	if not found then
		local image = icon:FindFirstChild("Image") :: ImageLabel
		image.ImageColor3 = Color3.new(0, 0, 0)
		image.ImageTransparency = 0.15
		local glyph = icon:FindFirstChild("Glyph") :: TextLabel
		if glyph.Visible then
			glyph.Text = "?" -- un emoji no se puede oscurecer
		end
	end
end

local function setBorder(obj: Instance, selected: boolean)
	local border = obj:FindFirstChild("Border") :: UIStroke?
	if border then
		border.Color = if selected then Color3.new(1, 1, 1) else UIKit.STROKE_COLOR
	end
end

function IndexController.start(hud: Hud.Hud)
	local window, body = UIKit.window(hud.screen, {
		name = "Index",
		title = UiText.INDEX_TITLE,
		icon = "index",
		variant = "Info",
		aspectRatio = 1.5,
		widthScale = 0.72,
	})
	local hudButton = hud.addButton("left", { name = "Index", label = UiText.INDEX, icon = "index", variant = "Info", layoutOrder = 2 })
	-- En el teléfono no entra la pieza en grande: las tarjetas ya la muestran y el premio usa el costado.
	local small = UIKit.isSmallScreen()

	-- Esqueleto fijo: zonas | (principal | costado) sobre el total.
	local root = stack(body, "Root", true, UDim2.fromScale(1, 1), 0)
	local zoneList = UIKit.list(root, "Zones")
	zoneList.Size = UDim2.fromScale(0.19, 1)
	zoneList.LayoutOrder = 1
	local content = fill(stack(root, "Content", false, UDim2.fromScale(0, 1), 2))
	local top = fill(stack(content, "Top", true, UDim2.fromScale(1, 0), 1))
	local main = fill(stack(top, "Main", false, UDim2.fromScale(0, 1), 1))
	-- En el teléfono el costado es más ancho: el botón CLAIM tiene que llegar a 44 px de alto.
	local side = stack(top, "Side", false, UDim2.fromScale(if small then 0.32 else 0.25, 1), 2)

	local tabsRow = UIKit.new("Frame", {
		Name = "TabsRow",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.11),
		LayoutOrder = 1,
	}, main) :: Frame
	atLeast(tabsRow, 0, 44) -- las pestañas se tocan con el dedo
	local holder = fill(UIKit.new("Frame", {
		Name = "Holder",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		LayoutOrder = 2,
	}, main) :: Frame)
	local progress = UIKit.progressBar(main, "Progress", { Size = UDim2.fromScale(1, 0.13), LayoutOrder = 3 }, "Accept")
	atLeast(progress, 0, 22)

	-- La pieza elegida, en grande.
	local preview = fill(UIKit.new("Frame", { Name = "Preview", Size = UDim2.fromScale(1, 0), LayoutOrder = 1 }, side) :: Frame)
	UIKit.style(preview, "Panel", 0.08, 0.025, "checker")
	tint(preview, Color3.fromRGB(58, 61, 76))
	local previewArt = UIKit.new("Frame", {
		Name = "Art",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.04),
		Size = UDim2.fromScale(0.86, 0.56),
		ZIndex = 3,
	}, preview) :: Frame
	UIKit.new("UIAspectRatioConstraint", { AspectRatio = 1 }, previewArt)
	local previewName = UIKit.label(preview, "Name", "", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.62),
		Size = UDim2.fromScale(0.92, 0.14),
		ZIndex = 4,
	}, 40)
	local previewRarity = UIKit.label(preview, "Rarity", "", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.76),
		Size = UDim2.fromScale(0.92, 0.1),
		ZIndex = 4,
	}, 30)
	local previewDetail = UIKit.label(preview, "Detail", "", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.87),
		Size = UDim2.fromScale(0.92, 0.1),
		ZIndex = 4,
	}, 30)
	previewDetail.TextColor3 = UIKit.MONEY_COLOR

	-- Premio de la zona.
	local rewardPanel = UIKit.new("Frame", { Name = "Reward", Size = UDim2.fromScale(1, if small then 1 else 0.46), LayoutOrder = 2 }, side) :: Frame
	atLeast(rewardPanel, 0, 100)
	if small then
		preview.Parent = nil
	end
	UIKit.style(rewardPanel, "Panel", 0.08, 0.025)
	tint(rewardPanel, Color3.fromRGB(34, 92, 50))
	UIKit.label(rewardPanel, "Title", UiText.ZONE_REWARD, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.04),
		Size = UDim2.fromScale(0.92, 0.16),
		ZIndex = 4,
	}, 34)
	local parts = UIKit.new("Frame", {
		Name = "Parts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.21),
		Size = UDim2.fromScale(0.94, 0.38),
		ZIndex = 4,
	}, rewardPanel) :: Frame
	UIKit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.04, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, parts)
	local claim = UIKit.button({
		name = "Claim",
		text = UiText.CLAIM,
		variant = "Neutral",
		anchorPoint = Vector2.new(0.5, 1),
		position = UDim2.fromScale(0.5, 0.95),
		size = UDim2.fromScale(0.88, 0.3),
		aspectRatio = if small then 1.8 else 2.4,
		parent = rewardPanel,
	})
	claim.ZIndex = 5

	-- Total de abajo, con el libro saliéndose de la barra.
	local footer = UIKit.new("Frame", { Name = "Total", Size = UDim2.fromScale(1, 0.13), LayoutOrder = 2 }, content) :: Frame
	atLeast(footer, 0, 28)
	UIKit.style(footer, "Dark", 0.3, 0.03)
	UIKit.icon(footer, "index", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.01, 0.42),
		Size = UDim2.fromScale(1.3, 1.3),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Rotation = -8,
		ZIndex = 4,
	})
	local total = UIKit.label(footer, "Text", "", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.55, 0.5),
		Size = UDim2.fromScale(0.7, 0.72),
		ZIndex = 3,
	}, 52)

	local zoneId: string? = nil
	local variant: string? = nil
	local selectedKey: string? = nil
	local claimable = false
	local zones: { Types.IndexZone } = {}
	local cards: { [string]: GuiObject } = {}
	local byKey: { [string]: Entry } = {}
	local stops: { Juice.Stop } = {}
	local signature = ""
	local grid: ScrollingFrame? = nil
	local tabs: UIKit.Tabs? = nil
	local lastFound = -1
	local render: (state: Types.PlayerSnapshot) -> ()

	local function currentZone(): Types.IndexZone?
		for _, zone in zones do
			if zone.id == zoneId then
				return zone
			end
		end
		return nil
	end

	local function showPreview(entry: Entry?, found: boolean)
		for _, child in previewArt:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		if not entry then
			previewName.Text = ""
			previewRarity.Text = ""
			previewDetail.Text = ""
			return
		end
		art(previewArt, entry, found, { Size = UDim2.fromScale(1, 1), ZIndex = 3 })
		previewName.Text = if found then entry.name else UiText.UNKNOWN
		local tier = if entry.rarity then tiers[entry.rarity] else nil
		previewRarity.Text = entry.rarity or ""
		previewRarity.TextColor3 = if tier then tier.color else UIKit.TEXT_COLOR
		previewDetail.Text = if found then entry.detail or "" else UiText.UNKNOWN
	end

	local function select(key: string)
		selectedKey = key
		for k, card in cards do
			setBorder(card, k == key)
		end
		local state = PlayerState.get()
		local entry = byKey[key]
		showPreview(entry, state ~= nil and state.index.keys[key] == true)
	end

	local function zoneTile(zone: Types.IndexZone, order: number)
		local tile = UIKit.new("TextButton", {
			Name = zone.id,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(0.94, 0, 0, 80),
			LayoutOrder = order,
		}, zoneList) :: TextButton
		UIKit.fitHeight(tile, 1.25)
		UIKit.style(tile, ZONE_COLORS[(order - 1) % #ZONE_COLORS + 1], 0.12, 0.04)
		if zone.image then
			local photo = UIKit.new("ImageLabel", {
				Name = "Photo",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Image = zone.image,
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = 2,
			}, tile)
			UIKit.new("UICorner", { CornerRadius = UDim.new(0.12, 0) }, photo)
		end
		if not zone.unlocked then
			local shade = UIKit.new("Frame", {
				Name = "Locked",
				BackgroundColor3 = Color3.fromRGB(10, 8, 20),
				BackgroundTransparency = 0.45,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 3,
			}, tile)
			UIKit.new("UICorner", { CornerRadius = UDim.new(0.12, 0) }, shade)
			UIKit.icon(tile, "lock", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.4),
				Size = UDim2.fromScale(0.42, 0.42),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 4,
			})
		end
		UIKit.label(tile, "Name", zone.name, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.95),
			Size = UDim2.fromScale(0.9, 0.3),
			ZIndex = 5,
		}, 34)
		setBorder(tile, zone.id == zoneId)
		UIKit.badgeOn(tile, 0.3)
		local ready = zone.unlocked and not zone.claimed and zone.reward ~= nil and zone.total > 0 and zone.found >= zone.total
		UIKit.setBadge(tile, if ready then "!" else nil)
		UIKit.bounce(tile)
		tile.Activated:Connect(function()
			if zoneId == zone.id then
				return
			end
			Sound.play("Click")
			zoneId = zone.id
			variant = nil
			selectedKey = nil
			signature = ""
			local state = PlayerState.get()
			if state then
				render(state)
			end
		end)
	end

	local function card(parent: Instance, entry: Entry, found: boolean, order: number)
		local button = UIKit.new("TextButton", {
			Name = entry.key,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = order,
		}, parent) :: TextButton
		rarityStyle(button, entry.rarity)
		art(button, entry, found, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromScale(0.74, 0.6),
			ZIndex = 3,
		})
		UIKit.label(button, "Name", if found then entry.name else UiText.UNKNOWN, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.04),
			Size = UDim2.fromScale(0.92, 0.17),
			ZIndex = 4,
		}, 30)
		local chance = entry.chance
		if chance then
			local odds = UIKit.label(button, "Odds", Format.oneIn(chance), {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.96),
				Size = UDim2.fromScale(0.92, 0.16),
				ZIndex = 4,
			}, 28)
			odds.AutoLocalize = false
		end
		UIKit.bounce(button)
		button.Activated:Connect(function()
			Sound.play("Click")
			select(entry.key)
		end)
		cards[entry.key] = button
	end

	local function rewardParts(zone: Types.IndexZone)
		for _, child in parts:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local reward = zone.reward
		if not reward then
			return
		end
		local income = player:GetAttribute("Income")
		local list = RewardText.parts(reward, if typeof(income) == "number" then income else 0)
		local width = math.min(0.46, (1 - 0.04 * (#list - 1)) / math.max(#list, 1))
		for i, part in list do
			local tile = UIKit.new("Frame", {
				Name = "Part" .. i,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(width, 1),
				LayoutOrder = i,
				ZIndex = 4,
			}, parts) :: Frame
			UIKit.new("UIAspectRatioConstraint", { AspectRatio = 0.9 }, tile)
			UIKit.icon(tile, part.icon, { Size = UDim2.fromScale(1, 0.72), ZIndex = 5 })
			UIKit.label(tile, "Text", part.text, {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.fromScale(1.1, 0.32),
				ZIndex = 6,
			}, 28)
		end
	end

	local function rewardState(zone: Types.IndexZone?)
		claimable = false
		local show = zone ~= nil and zone.reward ~= nil
		rewardPanel.Parent = if show then side else nil
		if not zone or not show then
			return
		end
		rewardParts(zone)
		local complete = zone.total > 0 and zone.found >= zone.total
		claimable = zone.unlocked and complete and not zone.claimed
		UIKit.recolor(claim, if claimable then "Accept" else "Neutral")
		UIKit.setText(claim, if zone.claimed then UiText.CLAIMED else UiText.CLAIM)
		if claimable then
			table.insert(stops, Juice.pulse(claim, 0.06))
			table.insert(stops, Juice.shine(claim, 2.5))
		end
	end

	render = function(state: Types.PlayerSnapshot)
		for _, stop in stops do
			stop()
		end
		table.clear(stops)
		local index = state.index
		zones = index.zones
		total.Text = string.format(UiText.UNLOCKED, index.found, index.total)

		-- Zona elegida: la que estaba, o la primera abierta.
		if not currentZone() then
			zoneId = nil
			for _, zone in zones do
				if zone.unlocked then
					zoneId = zone.id
					break
				end
			end
			if not zoneId and zones[1] then
				zoneId = zones[1].id
			end
		end
		for _, child in zoneList:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		zoneList.Parent = if #zones > 0 then root else nil
		for i, zone in zones do
			zoneTile(zone, i)
		end

		-- Piezas de la zona y variantes que tiene.
		local entries = Bus.call("IndexEntries")
		local inZone: { Entry } = {}
		local variants: { string } = {}
		local orderOf: { [string]: number } = {}
		table.clear(byKey)
		if typeof(entries) == "table" then
			local first = if zones[1] then zones[1].id else ALL
			for i, entry: Entry in entries do
				local entryZone = entry.zone or first
				if (#zones == 0 or entryZone == zoneId) and typeof(entry.key) == "string" then
					orderOf[entry.key] = entry.order or i
					table.insert(inZone, entry)
					byKey[entry.key] = entry
					local v = entry.variant
					if v and not table.find(variants, v) then
						table.insert(variants, v)
					end
				end
			end
		end
		if not variant or not table.find(variants, variant) then
			variant = variants[1]
		end
		if tabs then
			tabs.frame:Destroy()
			tabs = nil
		end
		tabsRow.Parent = if #variants > 1 then main else nil
		if #variants > 1 then
			local list: { UIKit.Tab } = {}
			for _, v in variants do
				table.insert(list, { id = v, label = v, variant = VARIANT_COLORS[v] or "Info" })
			end
			local t = UIKit.tabs(tabsRow, list, function(id: string)
				Sound.play("Click")
				variant = id
				selectedKey = nil
				signature = ""
				local current = PlayerState.get()
				if current then
					render(current)
				end
			end)
			t.frame.Size = UDim2.fromScale(1, 1)
			t.select(variant or variants[1])
			tabs = t
		end
		local shown: { Entry } = {}
		for _, entry in inZone do
			if #variants <= 1 or entry.variant == variant then
				table.insert(shown, entry)
			end
		end
		table.sort(shown, function(a: Entry, b: Entry)
			return orderOf[a.key] < orderOf[b.key]
		end)

		-- Tarjetas.
		if grid then
			grid:Destroy()
		end
		table.clear(cards)
		local columns = if hud.screen.AbsoluteSize.Y < SMALL_SCREEN then 3 else 4
		local cellWidth = (1 - 0.025 * (columns - 1)) / columns
		local g = UIKit.grid(holder, "Grid", UDim2.fromScale(cellWidth, 0), 0.92)
		grid = g
		local keys: { string } = {}
		for i, entry in shown do
			table.insert(keys, entry.key)
			card(g, entry, index.keys[entry.key] == true, i)
		end
		local found, count = Collection.progress(index.keys, keys)
		UIKit.setProgress(progress, found / math.max(count, 1), string.format(UiText.ZONE_PROGRESS, found, count))
		progress.Parent = if count > 0 then main else nil

		if not selectedKey or not byKey[selectedKey] or not table.find(keys, selectedKey) then
			selectedKey = keys[1]
		end
		if selectedKey then
			select(selectedKey)
		else
			showPreview(nil, false)
		end
		rewardState(currentZone())
		-- El costado sobra si no hay piezas, o en el teléfono si la zona no tiene premio.
		side.Parent = if count > 0 and (not small or rewardPanel.Parent == side) then top else nil
	end

	-- Solo se rehace si cambió algo del índice (el estado llega por muchas otras razones).
	local function signatureOf(state: Types.PlayerSnapshot): string
		local bits = { tostring(state.index.found), tostring(state.index.total) }
		for _, zone in state.index.zones do
			table.insert(bits, string.format("%s:%d:%s:%s", zone.id, zone.found, tostring(zone.unlocked), tostring(zone.claimed)))
		end
		return table.concat(bits, "|")
	end

	local function refresh(state: Types.PlayerSnapshot, force: boolean?)
		local s = signatureOf(state)
		if force or s ~= signature then
			signature = s
			render(state)
		end
	end

	local function updateBadge(state: Types.PlayerSnapshot, isNew: boolean)
		local ready = 0
		for _, zone in state.index.zones do
			if zone.unlocked and not zone.claimed and zone.reward ~= nil and zone.total > 0 and zone.found >= zone.total then
				ready += 1
			end
		end
		if ready > 0 then
			UIKit.setBadge(hudButton, ready)
		elseif isNew then
			UIKit.setBadge(hudButton, UiText.TAG_NEW)
		end
	end

	local function open()
		local state = PlayerState.get()
		if state then
			refresh(state, true)
		end
		UIKit.open(window)
	end

	claim.Activated:Connect(function()
		local zone = currentZone()
		if not zone or not claimable then
			Sound.play("Error")
			Juice.shake(claim)
			if zone and not zone.unlocked then
				UIKit.notify(hud.screen, UiText.ZONE_LOCKED, "Close", "lock")
			end
			return
		end
		Sound.play("Click")
		claimable = false
		local ok = invoke("ClaimIndexZone", zone.id)
		if not ok then
			Sound.play("Error")
			UIKit.notify(hud.screen, UiText.TRY_AGAIN, "Close")
		end
	end)

	PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
		local found = state.index.found
		local isNew = lastFound >= 0 and found > lastFound
		lastFound = found
		updateBadge(state, isNew)
		if UIKit.isOpen(window) then
			refresh(state)
		end
	end)
	hudButton.Activated:Connect(function()
		Sound.play("Click")
		UIKit.setBadge(hudButton, nil)
		if UIKit.isOpen(window) then
			UIKit.close(window)
		else
			open()
		end
	end)
	Bus.handle("OpenIndex", open)
end

return IndexController
