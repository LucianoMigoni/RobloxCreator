--!strict
-- Piezas comunes de la UI de los bloques del armador (client/Kits):
-- - Pedidos al servidor: KitUi.invoke (devuelve "ok, resultado o motivo"), KitUi.ask (lo mismo y
--   avisa el error) y KitUi.fire.
-- - Avisos en inglés por código de error ("FULL", "NOT_ENOUGH"...): los de los pedidos y los que manda
--   el servidor (KitFx "Error").
-- - Lo conseguido: nombre, color y popup de una unidad ("NEW! Huge Gold Dragon").
-- - Precios en monedas del juego y compras por clave de ShopConfig (Bus "BuyProduct" y "BuyPass" de
--   ShopController): "Finish Now", "Extra Life", el pase de abrir x3.
-- - Ventana de lista para las tiendas de los bloques (mejoras, cañas, herramientas, semillas, zonas):
--   filas con ícono, nombre, detalle o barra de nivel y uno o dos botones, como las misiones.
-- - Prompts del mundo: el dueño no ve "Steal" en lo suyo y en las bases ajenas no se ven la compra de
--   espacios ni las parcelas (el servidor igual lo valida). Se esconden con distancia 0, así no se
--   pisan con el Enabled que maneja el servidor.
-- - Puestos que abren una ventana: el prompt "RollStation" (atributo Roll) del servidor y prompts
--   locales en KitShopStand (atributo Window) y KitUpgradeStation (atributo Upgrade).
-- Solo pide y muestra: lo que vale lo decide el servidor.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local RarityConfig = require(ReplicatedStorage.Shared.Config.RarityConfig)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local UnitMath = require(ReplicatedStorage.Shared.Lib.UnitMath)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")

export type UnitInfo = { kind: string, variant: string?, size: string?, weight: number?, isNew: boolean? }

export type RowButton = {
	text: string?,
	variant: UIKit.Variant?,
	icon: string?,
	robux: string?, -- clave de producto o pase de ShopConfig: botón verde con el precio en Robux
	pulse: boolean?, -- late para llamar la atención (listo para cobrar)
	onClick: () -> (),
}

export type Row = {
	id: string,
	icon: string?,
	title: string,
	titleColor: Color3?,
	detail: string?,
	variant: UIKit.Variant?, -- color de la fila
	level: { value: number, max: number }?, -- barra de nivel (el detalle va adentro)
	tag: string?, -- calcomanía ("NEW!", "BEST")
	buttons: { RowButton }, -- uno o dos, el primero a la derecha
}

export type ListWindow = {
	window: Frame,
	setRows: (rows: { Row }) -> (),
	setNote: (text: string?) -> (), -- línea de arriba ("Restock in 2:31")
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
}

export type ListProps = { name: string, title: string, icon: string?, variant: UIKit.Variant? }

local KitUi = {}

local player = Players.LocalPlayer
local hud: HudController.Hud? = nil

local STATION_PROMPT = "KitStation"
local STATION_DISTANCE = 12
local ERROR_REPEAT = 1.2 -- segundos: el mismo aviso no se repite antes
local HIDE_RULES = { Steal = true, SlotShop = true, GardenTile = true }

local unitDefs: { [string]: KitTypes.UnitDef } = {}
local unitsConfig = KitConfig.units
if unitsConfig then
	for _, def in unitsConfig.list do
		unitDefs[def.id] = def
	end
end
local tierColors: { [string]: Color3 } = {}
for _, tier in RarityConfig.TIERS do
	tierColors[tier.id] = tier.color
end
local variantColors: { [string]: Color3 } = {}
for _, v in RarityConfig.MUTATIONS do
	if v.color then
		variantColors[v.id] = v.color
	elseif v.rainbow then
		variantColors[v.id] = Color3.fromRGB(255, 120, 200)
	end
end

local ERRORS: { [string]: { text: string, icon: string? } } = {
	FULL = { text = UiText.INVENTORY_FULL, icon = "inventory" },
	NOT_ENOUGH = { text = UiText.NOT_ENOUGH, icon = "cash" },
	ZONE = { text = UiText.ZONE_LOCKED, icon = "lock" },
	NO_SLOT = { text = UiText.PLOT_NO_SLOT, icon = "base" },
	SELL_FAR = { text = UiText.ERR_SELL_FAR, icon = "cash" },
	FAR = { text = UiText.ERR_FAR },
	LOCKED = { text = UiText.ERR_LOCKED, icon = "lock" },
	PROTECTED = { text = UiText.ERR_PROTECTED, icon = "shield" },
	RECENT = { text = UiText.ERR_RECENT, icon = "timer" },
	BEST = { text = UiText.ERR_BEST, icon = "shield" },
	OWN = { text = UiText.ERR_OWN },
	CARRYING = { text = UiText.ERR_CARRYING },
	BAG_FULL = { text = UiText.ERR_BAG_FULL, icon = "inventory" },
	COOLDOWN = { text = UiText.ERR_COOLDOWN, icon = "timer" },
	MAX = { text = UiText.ERR_MAX, icon = "star" },
	TAKEN = { text = UiText.ERR_TAKEN },
	NO_PLOT = { text = UiText.ERR_NO_PLOT, icon = "base" },
	NOT_FOR_SALE = { text = UiText.ERR_NOT_FOR_SALE },
	GONE = { text = UiText.ERR_GONE },
	BUSY = { text = UiText.ERR_BUSY, icon = "timer" },
	TOO_EARLY = { text = UiText.ERR_TOO_EARLY, icon = "fishing" },
	ESCAPED = { text = UiText.ERR_ESCAPED, icon = "fishing" },
	NO_CAST = { text = UiText.ERR_NO_CAST, icon = "fishing" },
	SOLD_OUT = { text = UiText.ERR_SOLD_OUT, icon = "timer" },
	RESTRICTED = { text = UiText.ERR_RESTRICTED },
	REQUIREMENT = { text = UiText.ERR_REQUIREMENT, icon = "lock" },
	ORDER = { text = UiText.ERR_ORDER, icon = "lock" },
	OWNED = { text = UiText.ERR_OWNED, icon = "check" },
	AMOUNT = { text = UiText.ERR_AMOUNT, icon = "egg" },
	AUTO = { text = UiText.ERR_AUTO, icon = "egg" },
	EQUIPPED = { text = UiText.ERR_EQUIPPED },
	PLACED = { text = UiText.ERR_PLACED, icon = "base" },
	EMPTY = { text = UiText.ERR_EMPTY },
	NO_SEEDS = { text = UiText.ERR_NO_SEEDS },
	NO_REVIVES = { text = UiText.ERR_NO_REVIVES, icon = "heart" },
	GROWING = { text = UiText.ERR_GROWING, icon = "timer" },
	NONE = { text = UiText.ERR_NONE },
	LOADING = { text = UiText.ERR_LOADING },
}

local lastError: { [string]: number } = {}

local function screen(): Instance?
	local h = hud
	return if h then h.screen else nil
end

-- Pide al servidor y espera. Devuelve si salió bien y lo segundo que devolvió el servidor (el
-- resultado o el código del motivo).
function KitUi.invoke(name: string, ...: any): (boolean, any)
	local args = table.pack(...)
	local ok, first, second = pcall(function()
		return Net.func(name):InvokeServer(table.unpack(args, 1, args.n))
	end)
	if not ok then
		warn("[KitUi] " .. name .. " falló: " .. tostring(first))
		return false, "NETWORK"
	end
	return first == true, second
end

-- Como invoke, y si sale mal avisa el motivo.
function KitUi.ask(name: string, ...: any): (boolean, any)
	local ok, result = KitUi.invoke(name, ...)
	if not ok then
		KitUi.error(if typeof(result) == "string" then result else nil)
	end
	return ok, result
end

-- Pide sin esperar respuesta.
function KitUi.fire(name: string, ...: any)
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(function()
			Net.event(name):FireServer(table.unpack(args, 1, args.n))
		end)
		if not ok then
			warn("[KitUi] " .. name .. " falló: " .. tostring(err))
		end
	end)
end

function KitUi.notify(text: string, variant: UIKit.Variant?, icon: string?)
	local s = screen()
	if s then
		UIKit.notify(s, text, variant, icon)
	end
end

local function statLabel(id: string?): string
	for _, def in KitConfig.stats or ({} :: { KitTypes.StatDef }) do
		if def.id == id then
			return def.label
		end
	end
	return id or ""
end

-- Aviso de error en inglés por código. `payload` completa lo que haga falta ("needs" en WEAK).
function KitUi.error(code: string?, payload: any?)
	local key = code or "UNKNOWN"
	local now = os.clock()
	if now - (lastError[key] or 0) < ERROR_REPEAT then
		return
	end
	lastError[key] = now
	local text = UiText.TRY_AGAIN
	local icon: string? = nil
	if key == "WEAK" then
		local wild = KitConfig.wild
		local needs = if typeof(payload) == "table" and typeof(payload.needs) == "number" then payload.needs else 0
		text = string.format(UiText.ERR_WEAK, Format.number(needs), statLabel(if wild then wild.stat else nil))
		icon = "strength"
	else
		local entry = ERRORS[key]
		if entry then
			text = entry.text
			icon = entry.icon
		end
	end
	Sound.play("Error")
	KitUi.notify(text, "Close", icon)
end

-- Unidades --------------------------------------------------------------------------------------------

function KitUi.unitDef(kind: string): KitTypes.UnitDef?
	return unitDefs[kind]
end

function KitUi.rarityColor(rarity: string?): Color3
	return if rarity then tierColors[rarity] or UIKit.TEXT_COLOR else UIKit.TEXT_COLOR
end

function KitUi.variantColor(variant: string?): Color3?
	return if variant then variantColors[variant] else nil
end

-- "Huge Gold Dragon (2.4 kg)".
function KitUi.unitName(info: UnitInfo): string
	local def = unitDefs[info.kind]
	local name = if def then UnitMath.name(def, info) else info.kind
	if info.weight then
		name ..= string.format(" (%.1f kg)", info.weight)
	end
	return name
end

function KitUi.unitIcon(kind: string): string
	local def = unitDefs[kind]
	return if def and def.icon then def.icon else "pets"
end

-- Línea de premio de una unidad, con el color de su mutación o de su rareza.
function KitUi.unitLine(info: UnitInfo): Types.RewardLine
	local def = unitDefs[info.kind]
	local color = KitUi.variantColor(info.variant) or KitUi.rarityColor(if def then def.rarity else nil)
	return { icon = KitUi.unitIcon(info.kind), text = KitUi.unitName(info), kind = "item", color = color }
end

-- Popup de lo conseguido ("NEW!" si es nueva en el índice). Para lo que llega seguido (cosechas,
-- pilas), mejor KitUi.toast.
function KitUi.showUnit(info: UnitInfo, source: string)
	Bus.call("ShowReward", {
		title = if info.isNew then UiText.NEW_UNIT else UiText.YOU_GOT,
		lines = { KitUi.unitLine(info) },
		source = source,
	})
end

-- Aviso corto de lo conseguido arriba al centro ("+1 Gold Carrot").
function KitUi.toast(info: UnitInfo)
	local prefix = if info.isNew then UiText.NEW_UNIT .. " " else "+1 "
	Sound.play(if info.isNew then "Reward" else "Pickup")
	KitUi.notify(prefix .. KitUi.unitName(info), if info.isNew then "Premium" else "Accept", KitUi.unitIcon(info.kind))
end

-- Monedas y compras ------------------------------------------------------------------------------------

-- "$1.2K" con el ícono de su moneda.
function KitUi.price(price: KitTypes.Price): (string, string?)
	local currency = EconomyConfig.CURRENCIES[price.currency]
	return Format.money(price.amount, if currency then currency.symbol else ""), if currency then currency.icon else nil
end

function KitUi.balance(currency: string): number
	local value = player:GetAttribute(currency)
	return if typeof(value) == "number" then value else 0
end

function KitUi.canPay(price: KitTypes.Price): boolean
	return KitUi.balance(price.currency) >= price.amount
end

-- No alcanza: aviso y, si esa moneda se vende por Robux, la tienda en su sección.
function KitUi.notEnough(currency: string?)
	KitUi.error("NOT_ENOUGH")
	local def = if currency then EconomyConfig.CURRENCIES[currency] else nil
	if def and def.purchasable then
		task.delay(0.6, function()
			Bus.call("OpenShop", "Currency")
		end)
	end
end

function KitUi.ownsPass(key: string?): boolean
	if not key then
		return false
	end
	for _, pass in ShopConfig.PASSES do
		if pass.key == key then
			return player:GetAttribute(pass.attribute) == true
		end
	end
	return false
end

function KitUi.buyProduct(key: string)
	Sound.play("Click")
	Bus.call("BuyProduct", key)
end

function KitUi.buyPass(key: string)
	Sound.play("Click")
	Bus.call("BuyPass", key)
end

-- Ventana de lista ------------------------------------------------------------------------------------

local function rowButton(frame: Frame, spec: RowButton, x: number, width: number): GuiButton
	local props = {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(x, 0.5),
		Size = UDim2.fromScale(width, 0.7),
		ZIndex = 25,
	}
	local button: GuiButton
	local robux = spec.robux
	if robux then
		local priced = UIKit.priceButton(frame, "Robux", nil, props, spec.variant)
		Bus.call("RobuxPrice", robux, function(price: number)
			if priced.Parent then
				UIKit.setPrice(priced, price)
			end
		end)
		button = priced
	else
		local plain = UIKit.button({
			name = "Button",
			text = spec.text or "",
			variant = spec.variant or "Accept",
			icon = spec.icon,
			aspectRatio = 0,
			parent = frame,
		})
		for key, value in props do
			(plain :: any)[key] = value
		end
		button = plain
	end
	button.Activated:Connect(function()
		spec.onClick()
	end)
	return button
end

-- Ventana con una lista de filas, para las tiendas de los bloques. `setRows` la rehace entera (son
-- pocas filas y cambian juntas con el estado).
function KitUi.listWindow(props: ListProps): ListWindow
	local h = hud
	assert(h, "KitUi.listWindow antes de KitUi.start")
	local window, body = UIKit.window(h.screen, { name = props.name, title = props.title, icon = props.icon, variant = props.variant })
	local note = UIKit.label(body, "Note", "", {
		Size = UDim2.fromScale(1, 0.1),
		Visible = false,
		ZIndex = 22,
	}, 34)
	local list = UIKit.list(body, "List")
	list.ZIndex = 21
	local stops: { Juice.Stop } = {}

	local function setNote(text: string?)
		note.Visible = text ~= nil
		note.Text = text or ""
		list.Position = UDim2.fromScale(0, if text then 0.11 else 0)
		list.Size = UDim2.fromScale(1, if text then 0.89 else 1)
	end

	local function setRows(rows: { Row })
		for _, stop in stops do
			stop()
		end
		table.clear(stops)
		for _, child in list:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		for order, row in rows do
			local frame = UIKit.new("Frame", { Name = row.id, LayoutOrder = order, Size = UDim2.new(0.96, 0, 0, 90), ZIndex = 22 }, list) :: Frame
			UIKit.fitHeight(frame, 7.4, 64) -- 64 px: el botón (70 % del alto) llega a 44 en el teléfono
			UIKit.style(frame, row.variant or "Info", 0.2, 0.04)
			UIKit.icon(frame, row.icon, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0.012, 0.5),
				Size = UDim2.fromScale(0.86, 0.86),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 24,
			})
			local count = math.min(#row.buttons, 2)
			local width = if count == 2 then 0.2 else 0.22
			local textWidth = 0.97 - count * (width + 0.015) - 0.14
			local title = UIKit.label(frame, "Title", row.title, {
				Position = UDim2.fromScale(0.14, 0.07),
				Size = UDim2.fromScale(textWidth, 0.44),
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 24,
			}, 34, UIKit.TitleFont)
			if row.titleColor then
				title.TextColor3 = row.titleColor
			end
			local level = row.level
			if level then
				local bar = UIKit.progressBar(frame, "Level", {
					Position = UDim2.fromScale(0.14, 0.56),
					Size = UDim2.fromScale(textWidth, 0.32),
					ZIndex = 24,
				}, "Premium")
				UIKit.setProgress(bar, if level.max > 0 then level.value / level.max else 1, row.detail or (level.value .. "/" .. level.max))
			elseif row.detail then
				UIKit.label(frame, "Detail", row.detail, {
					Position = UDim2.fromScale(0.14, 0.53),
					Size = UDim2.fromScale(textWidth, 0.38),
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 24,
				}, 26)
			end
			if row.tag then
				local ribbon = UIKit.ribbon(frame, row.tag, "Close")
				ribbon.Position = UDim2.fromScale(0.06, 0.08)
				ribbon.Size = UDim2.fromScale(0.13, 0.42)
			end
			local x = 0.985
			for i = 1, count do
				local spec = row.buttons[i]
				local button = rowButton(frame, spec, x, width)
				if spec.pulse then
					table.insert(stops, Juice.pulse(button, 0.06))
				end
				x -= width + 0.015
			end
		end
	end

	return {
		window = window,
		setRows = setRows,
		setNote = setNote,
		open = function()
			UIKit.open(window)
		end,
		close = function()
			UIKit.close(window)
		end,
		isOpen = function()
			return UIKit.isOpen(window)
		end,
	}
end

-- Botón del menú del HUD (izquierda) para la ventana de un bloque.
function KitUi.menuButton(name: string, label: string, icon: string, variant: UIKit.Variant?, order: number): TextButton?
	local h = hud
	if not h then
		return nil
	end
	return h.addButton("left", { name = name, label = label, icon = icon, variant = variant, layoutOrder = order })
end

-- Prompts del mundo -----------------------------------------------------------------------------------

local hiddenPrompts: { [ProximityPrompt]: number } = setmetatable({}, { __mode = "k" }) :: any
local trackedPrompts: { [ProximityPrompt]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function plotOf(instance: Instance): Instance?
	local current = instance.Parent
	while current and current ~= Workspace do
		if current:HasTag(Tags.PLOT) then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function shouldHide(prompt: ProximityPrompt): boolean
	if prompt.Name == "Steal" then
		return prompt:GetAttribute("Owner") == player.UserId
	end
	-- SlotShop y GardenTile: solo en la base propia.
	local plot = plotOf(prompt)
	return plot == nil or plot:GetAttribute(Tags.OWNER) ~= player.UserId
end

local function applyRule(prompt: ProximityPrompt)
	local hide = shouldHide(prompt)
	local saved = hiddenPrompts[prompt]
	if hide and saved == nil then
		hiddenPrompts[prompt] = prompt.MaxActivationDistance
		prompt.MaxActivationDistance = 0
	elseif not hide and saved ~= nil then
		hiddenPrompts[prompt] = nil
		prompt.MaxActivationDistance = saved
	end
end

local function trackPrompt(instance: Instance)
	if not instance:IsA("ProximityPrompt") or not HIDE_RULES[instance.Name] then
		return
	end
	local prompt = instance :: ProximityPrompt
	if trackedPrompts[prompt] then
		return
	end
	trackedPrompts[prompt] = true
	prompt:GetAttributeChangedSignal("Owner"):Connect(function()
		applyRule(prompt)
	end)
	applyRule(prompt)
end

local function applyAll()
	for prompt in trackedPrompts do
		if prompt.Parent then
			applyRule(prompt)
		end
	end
end

local function watchPlot(plot: Instance)
	plot:GetAttributeChangedSignal(Tags.OWNER):Connect(applyAll)
end

-- Puestos que abren una ventana -----------------------------------------------------------------------

local function partOf(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") and instance.PrimaryPart then
		return instance.PrimaryPart
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function inherited(instance: Instance, attribute: string): any
	local current: Instance? = instance
	while current and current ~= Workspace do
		local value = current:GetAttribute(attribute)
		if value ~= nil then
			return value
		end
		current = current.Parent
	end
	return nil
end

-- Abre la ventana `window` ("Shop", "Seeds", "Upgrades"...) con lo que registró su módulo en el Bus
-- ("OpenSeeds").
function KitUi.openWindow(window: string, arg: any?)
	local handler = "Open" .. window
	if Bus.has(handler) then
		Bus.call(handler, arg)
	else
		warn("[KitUi] no hay ventana " .. window .. " (nadie registró " .. handler .. ")")
	end
end

local function addStation(instance: Instance, window: string, arg: any?, label: string?)
	local part = partOf(instance)
	if not part or part:FindFirstChild(STATION_PROMPT) then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = STATION_PROMPT
	prompt.ActionText = UiText.OPEN
	prompt.ObjectText = label or window
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = STATION_DISTANCE
	prompt.Parent = part
	prompt.Triggered:Connect(function()
		Sound.play("Click")
		KitUi.openWindow(window, arg)
	end)
end

local function watchTag(tag: string, onAdded: (Instance) -> ())
	for _, instance in CollectionService:GetTagged(tag) do
		task.spawn(onAdded, instance)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(onAdded)
end

function KitUi.start(h: HudController.Hud)
	hud = h
	Bus.on("Kit:Error", function(payload: any)
		local code = if typeof(payload) == "table" and typeof(payload.code) == "string" then payload.code else nil
		KitUi.error(code, payload)
	end)
	-- Reglas de prompts: lo que aparece (también al cargar partes con streaming) y cambios de dueño.
	for _, instance in Workspace:GetDescendants() do
		trackPrompt(instance)
	end
	Workspace.DescendantAdded:Connect(trackPrompt)
	watchTag(Tags.PLOT, watchPlot)
	-- Puestos: estación de tiradas (prompt del servidor), tiendas y mejoras (prompts locales).
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
		if prompt.Name == "RollStation" then
			local id = inherited(prompt, "Roll")
			if typeof(id) == "string" then
				KitUi.openWindow("Roll", id)
			end
		end
	end)
	watchTag(Tags.SHOP_STAND, function(instance: Instance)
		local window = instance:GetAttribute("Window")
		local label = instance:GetAttribute("Label")
		if typeof(window) == "string" then
			addStation(instance, window, nil, if typeof(label) == "string" then label else nil)
		end
	end)
	if KitConfig.upgrades then
		watchTag(Tags.UPGRADE_STATION, function(instance: Instance)
			local upgrade = instance:GetAttribute("Upgrade")
			addStation(instance, "Upgrades", if typeof(upgrade) == "string" then upgrade else nil, UiText.UPGRADES_SIGN)
		end)
	end
end

return KitUi
