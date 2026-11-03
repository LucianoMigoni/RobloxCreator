--!strict
-- UI del bloque Garden (como Grow a Garden):
-- - Ventana "Seed Shop" (menú "Seeds", Bus "OpenSeeds" o el puesto del lobby): cada semilla con lo que
--   queda en esta reposición, lo que tiene y cuánto tarda; comprar de a una y elegir cuál se planta
--   (SelectSeed). Arriba, el reloj de la próxima reposición: es igual en todos los servidores
--   (Lib/GardenShop), así que el cliente la calcula y avisa cuando llega.
-- - Arriba de la lista: "Grow All Plants" por Robux si algo crece, y la parcela siguiente.
-- - Sobre cada parcela propia que crece, el tiempo que falta; "READY!" cuando se puede cosechar.
-- - Lo cosechado: popup si es nuevo o raro, aviso corto si no.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local GardenShop = require(ReplicatedStorage.Shared.Lib.GardenShop)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local Sound = require("../UI/Sound")
local KitState = require("./KitState")
local KitUi = require("./KitUi")

local Garden = {}

local player = Players.LocalPlayer

local READY_COLOR = Color3.fromRGB(110, 255, 90)
local TIMER_COLOR = Color3.fromRGB(255, 255, 255)
local TIMER_DISTANCE = 60

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

function Garden.start(_hud: HudController.Hud)
	local cfg = KitConfig.garden
	if not cfg then
		return
	end
	local seedsById: { [string]: KitTypes.Seed } = {}
	for _, seed in cfg.seeds do
		seedsById[seed.id] = seed
	end
	local state: KitTypes.GardenState? = nil
	local selected: string? = nil
	local shopEnds = 0
	local stock: { [string]: number } = {}
	local bought: { [string]: number } = {}

	-- Ventana -----------------------------------------------------------------------------------------
	local list = KitUi.listWindow({ name = "Seeds", title = UiText.SEED_SHOP, icon = "seed", variant = "Accept" })

	local function growing(): boolean
		local s = state
		if not s then
			return false
		end
		local now = os.time()
		for _, plant in s.plants do
			if plant.readyAt > now then
				return true
			end
		end
		return false
	end

	local function render()
		local s = state
		local owned = if s then s.seeds else {}
		local rows: { KitUi.Row } = {}
		local growAll = KitUi.productFor("Garden:Skip")
		if growAll and growing() then
			table.insert(rows, {
				id = "GrowAll",
				icon = "timer",
				title = UiText.GROW_ALL,
				detail = UiText.GROW_ALL_INFO,
				variant = "Pink",
				buttons = { { robux = growAll, variant = "Accept", onClick = function()
					KitUi.buyProduct(growAll)
				end } },
			})
		end
		local tilePrice = if s then s.nextTilePrice else nil
		if tilePrice then
			local main = EconomyConfig.CURRENCIES[EconomyConfig.MAIN]
			local price: KitTypes.Price = { currency = EconomyConfig.MAIN, amount = tilePrice }
			table.insert(rows, {
				id = "Tile",
				icon = "base",
				title = UiText.NEW_TILE,
				detail = UiText.NEW_TILE_INFO,
				variant = "Info",
				buttons = { {
					text = Format.money(tilePrice, main.symbol),
					variant = if KitUi.canPay(price) then "Premium" else "Neutral",
					icon = main.icon,
					onClick = function()
						Sound.play("Click")
						if not KitUi.canPay(price) then
							KitUi.notEnough(EconomyConfig.MAIN)
							return
						end
						if KitUi.ask("BuyTile") then
							Sound.play("Purchase")
						end
					end,
				} },
			})
		end
		for _, seed in cfg.seeds do
			local left = math.max(0, (stock[seed.id] or 0) - (bought[seed.id] or 0))
			local have = owned[seed.id] or 0
			-- Lo que no vino en esta reposición y no tiene no ocupa lugar.
			if left > 0 or have > 0 then
				local text, icon = KitUi.price(seed.price)
				local isSelected = selected == seed.id
				local row: KitUi.Row = {
					id = seed.id,
					icon = KitUi.unitIcon(seed.unit),
					title = seed.name,
					detail = string.format(UiText.SEED_STOCK, left, have, Format.short(seed.grow)),
					variant = if isSelected then "Accept" elseif left > 0 then "Info" else "Neutral",
					buttons = {
						{
							text = if left > 0 then text else UiText.SOLD_OUT,
							variant = if left > 0 and KitUi.canPay(seed.price) then "Premium" else "Neutral",
							icon = if left > 0 then icon else "timer",
							onClick = function()
								Sound.play("Click")
								if left <= 0 then
									KitUi.error("SOLD_OUT")
									return
								end
								if not KitUi.canPay(seed.price) then
									KitUi.notEnough(seed.price.currency)
									return
								end
								if KitUi.ask("BuySeed", seed.id, 1) then
									Sound.play("Purchase")
									if not selected then
										selected = seed.id
										KitUi.fire("SelectSeed", seed.id)
									end
								end
							end,
						},
					},
				}
				if have > 0 then
					table.insert(row.buttons, {
						text = if isSelected then UiText.SELECTED else UiText.SELECT,
						variant = if isSelected then "Neutral" else "Accept",
						icon = if isSelected then "check" else "seed",
						onClick = function()
							Sound.play("Click")
							selected = seed.id
							KitUi.ask("SelectSeed", seed.id)
							render()
						end,
					})
				end
				table.insert(rows, row)
			end
		end
		list.setRows(rows)
		list.setNote(string.format(UiText.RESTOCK_IN, Format.clock(shopEnds - os.time())))
	end

	local function open()
		render()
		list.open()
	end
	local menu = KitUi.menuButton("Seeds", UiText.SEEDS, "seed", "Accept", 8)
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
	Bus.handle("OpenSeeds", open)

	KitState.on("garden", function(s: KitTypes.GardenState)
		state = s
		shopEnds = s.shop.endsAt
		stock = s.shop.stock
		bought = s.shop.bought
		if list.isOpen() then
			render()
		end
	end)

	-- Reposición: la calcula el cliente con la misma cuenta que el servidor.
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			if shopEnds > 0 and now >= shopEnds then
				local window, endsAt = GardenShop.window(now, cfg.restock)
				shopEnds = endsAt
				stock = GardenShop.stock(cfg.seeds, window)
				bought = {}
				Sound.play("Notify")
				KitUi.notify(UiText.RESTOCKED, "Accept", "seed")
			end
			if list.isOpen() then
				render()
			end
		end
	end)
	player.AttributeChanged:Connect(function()
		if list.isOpen() then
			render()
		end
	end)

	-- Relojes sobre las parcelas propias ----------------------------------------------------------------
	local timers: { [Instance]: { gui: BillboardGui, label: TextLabel } } = {}
	local function clearTimer(tile: Instance)
		local t = timers[tile]
		if t then
			t.gui:Destroy()
			timers[tile] = nil
		end
	end
	local function refreshTimer(tile: Instance)
		local readyAt = tile:GetAttribute("ReadyAt")
		local plot = plotOf(tile)
		local mine = plot ~= nil and plot:GetAttribute(Tags.OWNER) == player.UserId
		if typeof(readyAt) ~= "number" or not mine or not tile:IsA("BasePart") then
			clearTimer(tile)
			return
		end
		local t = timers[tile]
		if not t then
			local gui = Instance.new("BillboardGui")
			gui.Name = "GrowTimer"
			gui.Adornee = tile
			gui.Size = UDim2.fromScale(5, 1.6)
			gui.StudsOffsetWorldSpace = Vector3.new(0, tile.Size.Y / 2 + 4.5, 0)
			gui.MaxDistance = TIMER_DISTANCE
			gui.LightInfluence = 0
			gui.ResetOnSpawn = false
			local label = UIKit.label(gui, "Time", "", { Size = UDim2.fromScale(1, 1) }, 80, UIKit.TitleFont)
			gui.Parent = player:WaitForChild("PlayerGui")
			t = { gui = gui, label = label }
			timers[tile] = t
		end
		local left = readyAt - os.time()
		local timer = t :: { gui: BillboardGui, label: TextLabel }
		timer.label.Text = if left <= 0 then UiText.READY else Format.clock(left)
		timer.label.TextColor3 = if left <= 0 then READY_COLOR else TIMER_COLOR
	end
	local function watchTile(tile: Instance)
		tile:GetAttributeChangedSignal("ReadyAt"):Connect(function()
			refreshTimer(tile)
		end)
		refreshTimer(tile)
	end
	for _, tile in CollectionService:GetTagged(Tags.GARDEN_TILE) do
		watchTile(tile)
	end
	CollectionService:GetInstanceAddedSignal(Tags.GARDEN_TILE):Connect(watchTile)
	CollectionService:GetInstanceRemovedSignal(Tags.GARDEN_TILE):Connect(clearTimer)
	task.spawn(function()
		while true do
			task.wait(1)
			for tile in timers do
				refreshTimer(tile)
			end
		end
	end)

	Bus.on("Kit:Harvested", function(payload: any)
		if typeof(payload) == "table" and typeof(payload.kind) == "string" then
			KitUi.announce({ kind = payload.kind, variant = payload.variant, size = payload.size, weight = payload.weight, isNew = payload.isNew == true }, "Harvest")
		end
	end)
end

return Garden
