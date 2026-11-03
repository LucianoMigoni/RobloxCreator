--!strict
-- HUD estilo hit (roblox-ui-designer/references/hud-hits.md, muestra hud-hits/muestra-kit.jpg):
-- - Barra de Roblox, a la derecha: botones propios con su mismo estilo (Daily, Quests, Codes, ajustes).
-- - Arriba al centro: el objetivo de ahora en una línea, con el progreso en amarillo debajo.
-- - Izquierda: pocos botones de menú grandes, anchos (Steal An Egg) o cuadrados (Anime Dice), según
--   GameConfig.HUD_MENU.
-- - Derecha: ofertas flotando sobre rayos (VIP, paquete de inicio) y botones cuadrados.
-- - Abajo a la izquierda: la plata enorme en verde sin fondo, las otras monedas, lo que se gana por
--   segundo y "Friend Boost +10%" con "+" para invitar.
-- - Abajo a la derecha: impulsos activos con su reloj, el evento del momento e invitar.
-- - Abajo al centro: lugar libre para el kit (barra de nivel, botón de acción).
-- Con pantalla táctil, las esquinas de abajo son del joystick y del salto (guía oficial: ni botones ni
-- información importante ahí; muestra en hud-hits/muestra-telefono.jpg): el menú pasa a una grilla de
-- 4x2 arriba a la izquierda (con los botones de la derecha, el evento e invitar), la plata arriba a la
-- derecha, las ofertas debajo y los impulsos arriba al centro. Se decide al arrancar.
-- Las monedas llegan como atributos del jugador (cambian cada segundo); el resto, del estado.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local BoostConfig = require(ReplicatedStorage.Shared.Config.BoostConfig)
local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local EventConfig = require(ReplicatedStorage.Shared.Config.EventConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Schedule = require(ReplicatedStorage.Shared.Lib.Schedule)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local PlayerState = require("../PlayerState")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")

export type Side = "left" | "right"

export type Hud = {
	screen: ScreenGui,
	topbar: Frame,
	top: Frame,
	left: Frame,
	right: Frame,
	bottom: Frame,
	stats: Frame,
	corner: Frame,
	menuStyle: UIKit.MenuStyle,
	-- Menú de la izquierda o botón cuadrado de la derecha.
	addButton: (side: Side, props: UIKit.HudButtonProps) -> TextButton,
	-- Botón en la barra de Roblox (sin `label`: redondo, solo ícono).
	addTopbarButton: (props: UIKit.TopbarProps) -> TextButton,
	-- Oferta flotando a la derecha; el precio se pone con UIKit.setPrice.
	addOffer: (props: UIKit.OfferProps) -> TextButton,
	-- Fila de la esquina de abajo a la derecha: ícono y una o dos líneas de texto. En táctil es un
	-- cuadrado del menú con `short` (o `text`) de nombre.
	addCorner: (name: string, icon: string, text: string, sub: string?, order: number?, short: string?) -> TextButton,
	setObjective: (text: string?, sub: string?) -> (),
	currencyPill: (currency: string) -> GuiObject?,
}

local HudController = {}

local player = Players.LocalPlayer

local function serverNow(): number
	return Workspace:GetServerTimeNow()
end

local function sortedCurrencies(): { string }
	local list = {}
	for id in EconomyConfig.CURRENCIES do
		if id ~= EconomyConfig.MAIN then
			table.insert(list, id)
		end
	end
	table.sort(list)
	return list
end

local function isTouch(): boolean
	return UserInputService.PreferredInput == Enum.PreferredInput.Touch
end

function HudController.start(screen: ScreenGui): Hud
	local touch = isTouch()
	local menuStyle: UIKit.MenuStyle = if touch or GameConfig.HUD_MENU == "tile" then "tile" else "wide"

	-- Barra de Roblox
	local topbar = UIKit.topbar(screen.Parent)

	-- Objetivo arriba al centro
	local objective = UIKit.objective(screen)
	local lastObjective = ""

	-- Menú a la izquierda y columna derecha (ofertas y botones cuadrados)
	local left = UIKit.sideBar(screen, "Left", false, menuStyle)
	local right = UIKit.new("Frame", {
		Name = "Right",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.988, 0.47),
		Size = UDim2.fromScale(0.23, 0.66),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
	}, screen) :: Frame
	UIKit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.05, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, right)

	-- Estadísticas abajo a la izquierda, de abajo hacia arriba (en táctil, arriba a la derecha)
	local stats = UIKit.new("Frame", {
		Name = "Stats",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0.012, 0.985),
		Size = UDim2.fromScale(0.95, 0.34),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
	}, screen) :: Frame
	UIKit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0.012, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, stats)

	local icons: { [string]: GuiObject } = {}
	local function currencyRow(id: string, order: number, height: number, color: Color3)
		local currency = EconomyConfig.CURRENCIES[id]
		local row, amount = UIKit.stat(stats, id, currency.icon, color, height)
		row.LayoutOrder = order
		icons[id] = (row:FindFirstChild("Icon") :: GuiObject?) or row
		local last = 0
		local function refresh()
			local value = player:GetAttribute(id)
			if typeof(value) ~= "number" then
				return
			end
			amount.Text = Format.money(value, currency.symbol)
			-- Las subidas grandes saltan; el goteo de cada segundo no (cansaría).
			if value > last and last > 0 and (value - last) / math.max(last, 1) > 0.02 then
				Juice.pop(row, 0.08)
			end
			last = value
		end
		player:GetAttributeChangedSignal(id):Connect(refresh)
		refresh()
	end
	for i, id in sortedCurrencies() do
		currencyRow(id, i, 0.17, EconomyConfig.CURRENCIES[id].color)
	end

	-- Lo que se gana por segundo, chico y verde arriba de la plata.
	local income = UIKit.label(stats, "Income", "", {
		Size = UDim2.fromScale(0.5, 0.09),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 50,
		Visible = false,
	}, 34)
	income.TextColor3 = UIKit.MONEY_COLOR
	local function refreshIncome()
		local value = player:GetAttribute("Income")
		local main = EconomyConfig.CURRENCIES[EconomyConfig.MAIN]
		if typeof(value) == "number" and value > 0 then
			income.Text = string.format(UiText.INCOME, Format.money(value, main.symbol))
			income.Visible = true
		else
			income.Visible = false
		end
	end
	player:GetAttributeChangedSignal("Income"):Connect(refreshIncome)
	refreshIncome()

	currencyRow(EconomyConfig.MAIN, 60, 0.3, UIKit.MONEY_COLOR)

	-- "Friend Boost +10%" con "+" para invitar (el bono lo calcula el servidor: BoostConfig.FRIENDS).
	local friendRow = UIKit.new("Frame", {
		Name = "FriendBoost",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.13),
		LayoutOrder = 70,
	}, stats) :: Frame
	UIKit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.02, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, friendRow)
	local friendText = UIKit.label(friendRow, "Text", string.format(UiText.FRIEND_BOOST, 0), {
		Size = UDim2.fromScale(6.4, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	}, 44)
	local invitePlus = UIKit.button({ name = "Invite", text = "+", variant = "Accept", size = UDim2.fromScale(1.15, 1.15), aspectRatio = 1, layoutOrder = 2, parent = friendRow })
	invitePlus.SizeConstraint = Enum.SizeConstraint.RelativeYY
	invitePlus.Activated:Connect(function()
		Sound.play("Click")
		Bus.call("Invite")
	end)
	-- En el teléfono esa esquina es del joystick: ahí no va un botón.
	local function placeForInput()
		invitePlus.Visible = not isTouch()
	end

	-- Esquina de abajo a la derecha: impulsos, evento, invitar
	local corner = UIKit.new("Frame", {
		Name = "Corner",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(0.988, 0.985),
		Size = UDim2.fromScale(0.62, 0.36),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
	}, screen) :: Frame
	UIKit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0.03, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, corner)

	local function cornerRow(name: string, icon: string, text: string, sub: string?, order: number?, short: string?): TextButton
		if touch then
			-- La esquina de abajo es del botón de salto: va a la grilla del menú.
			local tile = UIKit.hudButton({ name = name, label = short or text, icon = icon, variant = "Accept", layoutOrder = 20 + (order or 0), style = "tile" })
			tile.Parent = left
			return tile
		end
		local row = UIKit.new("TextButton", {
			Name = name,
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.26),
			LayoutOrder = order or 0,
		}, corner) :: TextButton
		UIKit.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0.02, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, row)
		local lines = UIKit.new("Frame", {
			Name = "Lines",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(3.4, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			LayoutOrder = 1,
		}, row) :: Frame
		local top = UIKit.label(lines, "Text", text, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, if sub then 0.04 else 0.2),
			Size = UDim2.fromScale(1, if sub then 0.46 else 0.6),
			TextXAlignment = Enum.TextXAlignment.Right,
		}, 36)
		top.Name = "Text"
		local bottom = UIKit.label(lines, "Sub", sub or "", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromScale(1, 0.44),
			TextXAlignment = Enum.TextXAlignment.Right,
			Visible = sub ~= nil,
		}, 34)
		bottom.TextColor3 = Color3.fromRGB(255, 225, 79)
		UIKit.icon(row, icon, {
			Size = UDim2.fromScale(1.05, 1.05),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			LayoutOrder = 2,
		})
		UIKit.bounce(row)
		return row
	end

	-- Impulsos activos ("2x Money" con 14:59 debajo): tocarlos abre el detalle de multiplicadores.
	local boosts = UIKit.new("TextButton", {
		Name = "Boosts",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.3),
		LayoutOrder = 1,
	}, corner) :: TextButton
	UIKit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0.02, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, boosts)
	boosts.Activated:Connect(function()
		Sound.play("Click")
		Bus.call("OpenBoosts")
	end)
	local chips: { [string]: { frame: Frame, label: TextLabel, endsAt: number } } = {}

	local function chip(id: string, icon: string, endsAt: number)
		local existing = chips[id]
		if existing then
			existing.endsAt = endsAt
			return
		end
		local frame = UIKit.new("Frame", {
			Name = id,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.95, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
		}, boosts) :: Frame
		UIKit.icon(frame, icon, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromScale(0.78, 0.78),
		})
		local label = UIKit.label(frame, "Time", "", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.fromScale(1.1, 0.32),
			ZIndex = 3,
		}, 26)
		chips[id] = { frame = frame, label = label, endsAt = endsAt }
		Juice.bounceIn(frame)
	end

	-- Evento con horario real ("Lucky Hour in 4m 36s" / "LUCKY HOUR 12:34"). En táctil, un cuadrado
	-- violeta del menú con el reloj en lugar del nombre.
	local event: TextButton
	if touch then
		event = UIKit.hudButton({ name = "Event", label = "", icon = "moon", variant = "Purple", layoutOrder = 19, style = "tile" })
		event.Parent = left
	else
		event = cornerRow("Event", "moon", "", nil, 2)
	end
	event.Visible = false
	event.Activated:Connect(function()
		Sound.play("Click")
		Bus.call("OpenBoosts")
	end)
	local eventLines = event:FindFirstChild("Lines") :: Frame?
	local eventText = if eventLines then eventLines:FindFirstChild("Text") :: TextLabel? else nil
	local eventSub = if eventLines then eventLines:FindFirstChild("Sub") :: TextLabel? else nil
	local eventTop = if eventText then eventText.Position else UDim2.new()
	local stopEventPulse: Juice.Stop? = nil

	local function tickClocks()
		local now = serverNow()
		for id, info in chips do
			local left = info.endsAt - now
			if left <= 0 then
				info.frame:Destroy()
				chips[id] = nil
			else
				info.label.Text = Format.clock(left)
			end
		end
		local active = Schedule.active(EventConfig.EVENTS, now)
		local title, time: string?, live = nil, nil, false
		if #active > 0 then
			local window = active[1]
			title, time, live = window.event.title, Format.clock(window.endsAt - now), true
		else
			local window = Schedule.upcoming(EventConfig.EVENTS, now)[1]
			if window and window.startsAt - now <= EventConfig.ANNOUNCE_BEFORE * 3 then
				title, time = string.format(UiText.EVENT_IN, window.event.title), Format.short(window.startsAt - now)
			end
		end
		event.Visible = title ~= nil
		if title and eventText and eventSub then
			eventText.Text = title
			eventText.Position = eventTop
			eventSub.Text = time or ""
			eventSub.Visible = true
			eventSub.TextColor3 = if live then Color3.fromRGB(255, 225, 79) else Color3.new(1, 1, 1)
		elseif title then
			UIKit.setText(event, title)
			UIKit.setTimer(event, time)
		end
		if live and not stopEventPulse then
			stopEventPulse = Juice.pulse(event, 0.05, 1.2)
		elseif not live and stopEventPulse then
			stopEventPulse()
			stopEventPulse = nil
		end
	end
	task.spawn(function()
		while screen.Parent do
			tickClocks()
			task.wait(1)
		end
	end)

	-- Lugar del kit abajo al centro
	local bottom = UIKit.new("Frame", {
		Name = "Bottom",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.98),
		Size = UDim2.fromScale(0.36, 0.16),
	}, screen) :: Frame

	-- Impulsos arriba al centro en táctil (abajo a la derecha está el salto).
	local buffs = UIKit.new("Frame", {
		Name = "Buffs",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.2),
		Size = UDim2.fromScale(0.9, 0.1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Visible = touch,
	}, screen) :: Frame

	if touch then
		-- Menú: grilla de 4x2 arriba a la izquierda, entera por encima de la zona del joystick.
		left.AnchorPoint = Vector2.new(0, 0)
		left.Position = UDim2.fromScale(0.012, 0.04)
		left.Size = UDim2.fromScale(0.68, 0.34)
		local grid = left:FindFirstChildOfClass("UIGridLayout")
		if grid then
			grid.CellSize = UDim2.fromScale(0.22, 0.42)
			grid.CellPadding = UDim2.fromScale(0.04, 0.06)
			grid.FillDirection = Enum.FillDirection.Horizontal
			grid.FillDirectionMaxCells = 4
			grid.StartCorner = Enum.StartCorner.TopLeft
			grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
			grid.VerticalAlignment = Enum.VerticalAlignment.Top
		end
		-- Plata arriba a la derecha, alineada a la derecha y primero.
		stats.AnchorPoint = Vector2.new(1, 0)
		stats.Position = UDim2.fromScale(0.988, 0.015)
		stats.Size = UDim2.fromScale(0.75, 0.34)
		local list = stats:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		list.VerticalAlignment = Enum.VerticalAlignment.Top
		list.HorizontalAlignment = Enum.HorizontalAlignment.Right
		for _, child in stats:GetChildren() do
			if child:IsA("GuiObject") then
				if child.Name == EconomyConfig.MAIN then
					child.LayoutOrder = 1
				elseif child.Name == "Income" then
					child.LayoutOrder = 2
				elseif child.Name == "FriendBoost" then
					child.LayoutOrder = 90
				else
					child.LayoutOrder += 10
				end
				local rowLayout = child:FindFirstChildOfClass("UIListLayout")
				if rowLayout then
					rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
				end
				local icon = child:FindFirstChild("Icon")
				if icon and icon:IsA("GuiObject") then
					icon.LayoutOrder = 3 -- después del número: "$1.25K 💵"
				end
				local labels: { Instance? } = { child, child:FindFirstChild("Amount"), child:FindFirstChild("Text") }
				for _, label in labels do
					if label and label:IsA("TextLabel") then
						label.TextXAlignment = Enum.TextXAlignment.Right
					end
				end
			end
		end
		-- Ofertas debajo de la plata, arriba de la zona del salto.
		right.AnchorPoint = Vector2.new(1, 0)
		right.Position = UDim2.fromScale(0.988, 0.3)
		right.Size = UDim2.fromScale(0.18, 0.4) -- dos ofertas terminan en 0.68: el salto empieza en ~0.72
		local rightList = right:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		rightList.VerticalAlignment = Enum.VerticalAlignment.Top
		boosts.Parent = buffs
		boosts.Size = UDim2.fromScale(1, 1)
		local boostsList = boosts:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		boostsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
		corner.Visible = false
		-- Lugar del kit entre las dos zonas de abajo.
		bottom.Position = UDim2.fromScale(0.59, 0.98)
		bottom.Size = UDim2.fromScale(0.34, 0.16)
	end
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(placeForInput)
	placeForInput()

	local warned = false
	PlayerState.Changed:Connect(function(state: Types.PlayerSnapshot)
		if not state.savesProgress and not warned then
			warned = true
			UIKit.notify(screen, UiText.NOT_SAVING, "Close")
		end
		-- Objetivo
		local o = state.objective
		if o then
			local target = if o.money then Format.money(o.target, EconomyConfig.CURRENCIES[EconomyConfig.MAIN].symbol) else Format.number(o.target)
			local text = string.format(o.text, target)
			if text ~= lastObjective and lastObjective ~= "" then
				Sound.play("LevelUp")
				Juice.pop(objective, 0.15)
			end
			lastObjective = text
			local progress = if o.money then Format.number(o.progress) .. " / " .. Format.number(o.target) else math.floor(o.progress) .. " / " .. o.target
			UIKit.setObjective(objective, text, progress)
		else
			UIKit.setObjective(objective, nil, nil)
		end
		-- Impulsos
		local seen: { [string]: boolean } = {}
		for _, b in state.boosts do
			local key = (if b.server then "S_" else "P_") .. b.id
			seen[key] = true
			chip(key, b.icon, b.endsAt)
		end
		for key, info in chips do
			if not seen[key] then
				info.frame:Destroy()
				chips[key] = nil
			end
		end
		-- Bono por amigos en el servidor
		local friends = 0
		for _, m in state.multipliers do
			if m.label == BoostConfig.FRIENDS.label then
				friends += m.value
			end
		end
		friendText.Text = string.format(UiText.FRIEND_BOOST, math.floor(friends * 100 + 0.5))
	end)

	local function addButton(side: Side, props: UIKit.HudButtonProps): TextButton
		local styled = table.clone(props)
		styled.style = if side == "left" then menuStyle else "tile"
		local button = UIKit.hudButton(styled)
		-- En táctil todo botón va a la grilla del menú (la columna derecha queda para las ofertas).
		local toLeft = side == "left" or touch
		if not toLeft then
			button.Size = UDim2.fromScale(0.5, 0.2)
		elseif touch and side == "right" then
			button.LayoutOrder += 10
		end
		button.Parent = if toLeft then left else right
		Juice.bounceIn(button, (props.layoutOrder or 0) * 0.04)
		return button
	end

	local function addOffer(props: UIKit.OfferProps): TextButton
		local offer = UIKit.offer(right, props)
		offer.Size = UDim2.fromScale(1, if touch then 0.45 else 0.38)
		Juice.bounceIn(offer, (props.layoutOrder or 0) * 0.05)
		return offer
	end

	return {
		screen = screen,
		topbar = topbar,
		top = objective,
		left = left,
		right = right,
		bottom = bottom,
		stats = stats,
		corner = corner,
		menuStyle = menuStyle,
		addButton = addButton,
		addTopbarButton = function(props: UIKit.TopbarProps): TextButton
			return UIKit.topbarButton(topbar, props)
		end,
		addOffer = addOffer,
		addCorner = cornerRow,
		setObjective = function(text: string?, sub: string?)
			UIKit.setObjective(objective, text, sub)
		end,
		currencyPill = function(currency: string): GuiObject?
			return icons[currency]
		end,
	}
end

return HudController
