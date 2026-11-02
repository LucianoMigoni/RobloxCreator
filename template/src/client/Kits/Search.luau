--!strict
-- UI del bloque Search (pilas para revolver, juegos de cavar):
-- - "Dig" en la barra de acción cerca de una pila (KitPile); mantener apretado repite al ritmo de la
--   herramienta. Lo encontrado: popup si es nuevo o raro, aviso corto si no.
-- - Mochila en la columna del HUD ("7/20", roja si está llena). Llena: aviso y flechas en el piso hasta
--   el depósito (KitDepositPad) más cercano; se van al vaciarla.
-- - Ventana "Tools" (menú, Bus "OpenTools" o un puesto con Window "Tools"), como la de cañas.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local ActionBar = require("./ActionBar")
local Gear = require("./Gear")
local KitState = require("./KitState")
local KitUi = require("./KitUi")

local Search = {}

local player = Players.LocalPlayer

local PILE_RANGE = 14 -- como el servidor
local CHECK_EVERY = 0.25
local BUTTON = "Dig"
local FULL_COLOR = Color3.fromRGB(255, 90, 90)
local BAG_COLOR = Color3.fromRGB(255, 225, 160)

local function partOf(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function nearest(tag: string, from: Vector3): (BasePart?, number)
	local best: BasePart? = nil
	local bestDistance = math.huge
	for _, instance in CollectionService:GetTagged(tag) do
		local part = partOf(instance)
		if part then
			local distance = (part.Position - from).Magnitude
			if distance < bestDistance then
				best = part
				bestDistance = distance
			end
		end
	end
	return best, bestDistance
end

function Search.start(hud: HudController.Hud)
	local cfg = KitConfig.search
	if not cfg then
		return
	end
	local state: KitTypes.SearchState? = nil
	local toolsById: { [string]: KitTypes.SearchTool } = {}
	for _, tool in cfg.tools do
		toolsById[tool.id] = tool
	end
	local showingPath = false

	local function currentTool(): KitTypes.SearchTool?
		local s = state
		return (if s then toolsById[s.tool] else nil) or cfg.tools[1]
	end

	-- Mochila en el HUD.
	local row, amount = UIKit.stat(hud.stats, "Bag", "inventory", BAG_COLOR, 0.15)
	row.LayoutOrder = 46
	local function full(): boolean
		local s = state
		return s ~= nil and #s.bag >= s.capacity
	end
	local function setPath(on: boolean)
		if on == showingPath then
			return
		end
		showingPath = on
		if on then
			local character = player.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			local pad = if root and root:IsA("BasePart") then nearest(Tags.DEPOSIT_PAD, root.Position) else nil
			if pad then
				Bus.call("ShowPath", pad)
			end
		else
			Bus.call("ShowPath", nil)
		end
	end
	local function refreshBag()
		local s = state
		if not s then
			return
		end
		amount.Text = #s.bag .. "/" .. s.capacity
		amount.TextColor3 = if full() then FULL_COLOR else BAG_COLOR
		if not full() then
			setPath(false)
		end
	end

	-- Botón de cavar.
	local function dig()
		local ok, reason = KitUi.invoke("DigPile")
		if ok then
			return
		end
		if reason == "COOLDOWN" then
			return -- el ritmo lo pone la herramienta: mantener apretado no es un error
		end
		KitUi.error(reason)
		if reason == "BAG_FULL" then
			setPath(true)
		end
	end
	local function addButton()
		local tool = currentTool()
		ActionBar.add(BUTTON, {
			text = UiText.DIG,
			icon = "pickaxe",
			variant = "Orange",
			order = 4,
			key = Enum.KeyCode.G,
			repeatEvery = math.max(if tool then tool.cooldown else 0.5, 0.15),
			onClick = function()
				local button = ActionBar.get(BUTTON)
				if button then
					Juice.pop(button, 0.06)
				end
				task.spawn(dig)
			end,
		})
		ActionBar.show(BUTTON, false)
	end
	addButton()
	local shownTool = currentTool()

	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			local character = player.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			local near = false
			if root and root:IsA("BasePart") then
				local _, distance = nearest(Tags.PILE, root.Position)
				near = distance <= PILE_RANGE + 4
			end
			ActionBar.show(BUTTON, near)
		end
	end)

	-- Ventana de herramientas.
	local list = KitUi.listWindow({ name = "Tools", title = UiText.TOOLS, icon = "pickaxe", variant = "Orange" })
	local items: { Gear.Item } = {}
	for _, tool in cfg.tools do
		table.insert(items, { id = tool.id, name = tool.name, price = tool.price })
	end
	local function render()
		local s = state
		list.setRows(Gear.rows(items, if s then s.owned else {}, if s then s.tool else nil, "BuyTool", "Tool", "pickaxe", function(item: Gear.Item): string
			local tool = toolsById[item.id]
			return string.format(UiText.TOOL_STATS, Format.multiplier(tool.power), tostring(tool.cooldown))
		end))
	end
	local function open()
		render()
		list.open()
	end
	if #cfg.tools > 1 then
		local menu = KitUi.menuButton("Tools", UiText.TOOLS, "pickaxe", "Orange", 7)
		if menu then
			menu.Activated:Connect(function()
				Sound.play("Click")
				if list.isOpen() then
					list.close()
				else
					open()
				end
			end)
		end
	end
	Bus.handle("OpenTools", open)

	KitState.on("search", function(s: KitTypes.SearchState)
		local before = state
		state = s
		refreshBag()
		if before and #s.bag > #before.bag then
			Juice.pop(row, 0.1)
		end
		-- Otra herramienta: el botón repite a su ritmo.
		local tool = currentTool()
		if tool ~= shownTool then
			shownTool = tool
			addButton()
		end
		if list.isOpen() then
			render()
		end
	end)
	player.AttributeChanged:Connect(function()
		if list.isOpen() then
			render()
		end
	end)

	-- Avisos del servidor.
	Bus.on("Kit:Dug", function()
		Sound.play("Pickup")
	end)
	Bus.on("Kit:Found", function(payload: any)
		if typeof(payload) == "table" and typeof(payload.kind) == "string" then
			KitUi.announce({ kind = payload.kind, variant = payload.variant, size = payload.size, isNew = payload.isNew == true }, "Search")
		end
	end)
	Bus.on("Kit:Deposited", function(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		setPath(false)
		local count = payload.count or 0
		local currencyId = payload.currency
		local currency = if typeof(currencyId) == "string" then EconomyConfig.CURRENCIES[currencyId] else nil
		if currency and (payload.amount or 0) > 0 then
			Sound.play("Cash")
			KitUi.notify(string.format(UiText.SOLD, count, Format.money(payload.amount, currency.symbol)), "Accept", currency.icon)
		else
			Sound.play("Reward")
			KitUi.notify(string.format(UiText.DEPOSITED, count), "Accept", "inventory")
		end
	end)
end

return Search
