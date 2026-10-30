--!strict
-- Bloque Plots del armador: una base por jugador con espacios (pedestales) donde las unidades pagan $/s,
-- como Steal a Brainrot, Chicken Farm o un tycoon. Al cargar los datos le asigna una base libre (cartel
-- "Leo's Base") y lo hace aparecer ahí; muestra cada unidad colocada sobre su espacio (modelos del
-- servidor: los ven todos y se pueden robar); junta lo que pagan en el pad de cobro, o directo a la
-- moneda con el pase o en modo "auto"; vende espacios nuevos; y pone la traba con láser.
-- Partes (Kits/Tags): KitPlot (Model) con KitSlot (atributo Index), KitCollectPad, KitSpawn,
-- KitBarrier, KitLockButton y KitSlotShop adentro; una parte llamada "Sign" lleva el cartel del dueño.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local UnitModel = require(ReplicatedStorage.Shared.Kits.UnitModel)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Ladder = require(ReplicatedStorage.Shared.Lib.Ladder)
local BoostService = require("../Boosts/BoostService")
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local ShopService = require("../Shop/ShopService")
local Signals = require("../Signals")
local Bonus = require("./Bonus")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")
local Units = require("./Units")

type PlotData = { bought: number, stored: number }

type Plot = {
	model: Model,
	order: number,
	owner: Player?,
	slots: { [number]: BasePart },
	pads: { BasePart },
	spawn: BasePart?,
	sign: Instance,
	barriers: { BasePart },
	lockButtons: { BasePart },
	shops: { [BasePart]: ProximityPrompt },
	shown: { [number]: Model }, -- uid → modelo sobre su espacio
	lockedUntil: number,
	lockReadyAt: number,
}

local Plots = {}

local assigned = Instance.new("BindableEvent")
-- (player, plotModel)
Plots.Assigned = assigned.Event
local released = Instance.new("BindableEvent")
-- (player, plotModel)
Plots.Released = released.Event
local shownEvent = Instance.new("BindableEvent")
-- (owner, unit, model): una unidad apareció sobre su espacio (el bloque Steal le pone su prompt)
Plots.Shown = shownEvent.Event

local TICK = 1
local NEAR_BASE = 90 -- studs: la traba desde la UI se pone estando en la base
local COLLECT_COOLDOWN = 0.75

local config: KitTypes.PlotsConfig? = nil
local label = UiText.PLOT_DEFAULT
local plots: { Plot } = {}
local byModel: { [Model]: Plot } = {}
local byPlayer: { [Player]: Plot } = {}
local wired: { [Instance]: boolean } = {}
local mainSymbol = EconomyConfig.CURRENCIES[EconomyConfig.MAIN].symbol

local function plotData(player: Player): PlotData?
	local d = DataService.get(player)
	return if d then d.kits.plots :: PlotData else nil
end

local function slotParts(plot: Plot): number
	local count = 0
	for _ in plot.slots do
		count += 1
	end
	return count
end

function Plots.plotOf(player: Player): Model?
	local plot = byPlayer[player]
	return if plot then plot.model else nil
end

function Plots.ownerOf(model: Model): Player?
	local plot = byModel[model]
	return if plot then plot.owner else nil
end

-- La base que contiene a la instancia (una parte o modelo adentro de un KitPlot).
function Plots.plotContaining(instance: Instance): Model?
	local found = KitWorld.ancestor(instance, Tags.PLOT)
	return if found and found:IsA("Model") then found else nil
end

function Plots.isLocked(model: Model): boolean
	local plot = byModel[model]
	return plot ~= nil and plot.lockedUntil > os.time()
end

-- El modelo que muestra esa unidad sobre su espacio (para robarla).
function Plots.unitModel(owner: Player, uid: number): Model?
	local plot = byPlayer[owner]
	return if plot then plot.shown[uid] else nil
end

-- Espacios abiertos: los de la receta, los comprados, el pase y las mejoras, sin pasar los que hay.
function Plots.slotCount(player: Player): number
	local cfg = config
	if not cfg then
		return 0
	end
	local d = plotData(player)
	local pass = 0
	if cfg.slotPass and ShopService.ownsPass(player, cfg.slotPass) then
		pass = cfg.passSlots or 0
	end
	local total = cfg.slots + (if d then d.bought else 0) + pass + math.floor(Bonus.get(player, "slots"))
	local plot = byPlayer[player]
	local physical = if plot then math.min(cfg.maxSlots, slotParts(plot)) else cfg.maxSlots
	return math.clamp(total, 0, physical)
end

function Plots.freeSlot(player: Player): number?
	local taken: { [number]: boolean } = {}
	for _, unit in Units.list(player) do
		local slot = unit.slot
		if slot then
			taken[slot] = true
		end
	end
	for index = 1, Plots.slotCount(player) do
		if not taken[index] then
			return index
		end
	end
	return nil
end

-- Lo que pagan por segundo las unidades colocadas, con los multiplicadores de plata del jugador.
function Plots.income(player: Player): number
	local total = 0
	for _, unit in Units.list(player) do
		if unit.slot then
			total += Units.income(unit)
		end
	end
	return if total > 0 then total * BoostService.multiplier(player, "Money") else 0
end

local function auto(player: Player): boolean
	local cfg = config
	if not cfg then
		return false
	end
	local pass = cfg.autoCollectPass
	return cfg.collect == "auto" or (pass ~= nil and ShopService.ownsPass(player, pass))
end

local function nextPrice(player: Player): number?
	local cfg = config
	local d = plotData(player)
	if not cfg or not d or not byPlayer[player] then
		return nil
	end
	local plot = byPlayer[player] :: Plot
	if Plots.slotCount(player) >= math.min(cfg.maxSlots, slotParts(plot)) then
		return nil
	end
	return Ladder.price(d.bought + 1, cfg.slotPrices)
end

local function updatePads(plot: Plot)
	local owner = plot.owner
	local d = if owner then plotData(owner) else nil
	for _, pad in plot.pads do
		if owner and d and not auto(owner) then
			KitWorld.sign(pad, string.format(UiText.PLOT_COLLECT, Format.money(math.floor(d.stored), mainSymbol)), "Accept", "cash", 9)
		else
			pad:SetAttribute("Text", nil)
		end
	end
end

local function updateShops(plot: Plot)
	local owner = plot.owner
	local price = if owner then nextPrice(owner) else nil
	for _, prompt in plot.shops do
		prompt.Enabled = owner ~= nil and price ~= nil
		prompt.ObjectText = if price then UiText.PLOT_BUY_SLOT .. " · " .. Format.money(price, mainSymbol) else UiText.PLOT_MAX_SLOTS
	end
end

local function updateSlots(plot: Plot)
	local owner = plot.owner
	local open = if owner then Plots.slotCount(owner) else 0
	for index, part in plot.slots do
		part:SetAttribute("Open", index <= open)
	end
end

local function setBarriers(plot: Plot, on: boolean)
	for _, barrier in plot.barriers do
		barrier.CanCollide = on
		barrier.Transparency = if on then 0.35 else 1
		barrier:SetAttribute("Active", on)
	end
	for _, button in plot.lockButtons do
		KitWorld.sign(button, if on then string.format(UiText.PLOT_LOCKED, Format.clock(math.max(0, plot.lockedUntil - os.time()))) else UiText.PLOT_LOCK, if on then "Close" else "Info", "lock", 7)
	end
end

local function sign(plot: Plot)
	local owner = plot.owner
	if owner then
		KitWorld.sign(plot.sign, string.format(UiText.PLOT_SIGN, owner.DisplayName, label), "Info", nil, 16)
	else
		KitWorld.sign(plot.sign, string.format(UiText.PLOT_FREE, label), "Neutral", nil, 16)
	end
end

local function folder(plot: Plot): Instance
	local existing = plot.model:FindFirstChild("KitUnits")
	if existing then
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = "KitUnits"
	created.Parent = plot.model
	return created
end

local function hide(plot: Plot, uid: number)
	local model = plot.shown[uid]
	if model then
		plot.shown[uid] = nil
		model:Destroy()
	end
end

local function show(owner: Player, plot: Plot, unit: Units.Unit)
	hide(plot, unit.uid)
	local slot = if unit.slot then plot.slots[unit.slot] else nil
	local def = Units.def(unit.kind)
	if not slot or not def then
		return
	end
	local model = UnitModel.make(def, unit)
	model:SetAttribute("Owner", owner.UserId)
	model:SetAttribute("Uid", unit.uid)
	model:SetAttribute("Income", Units.income(unit))
	UnitModel.standOn(model, slot.CFrame * CFrame.new(0, slot.Size.Y / 2, 0))
	model.Parent = folder(plot)
	plot.shown[unit.uid] = model
	shownEvent:Fire(owner, unit, model)
end

local function collect(player: Player, plot: Plot)
	if plot.owner ~= player then
		return
	end
	local d = plotData(player)
	if not d or d.stored < 1 then
		return
	end
	local amount = math.floor(d.stored)
	d.stored -= amount
	if CurrencyService.add(player, amount, Enum.AnalyticsEconomyTransactionType.Gameplay, "Collect") then
		Signals.track(player, "Collect", 1)
		KitFx.send(player, "Collect", { amount = amount })
	else
		d.stored += amount
	end
	updatePads(plot)
	Signals.dirty(player)
end

local function buySlot(player: Player): (boolean, string?)
	local d = plotData(player)
	local plot = byPlayer[player]
	if not d or not plot then
		return false, "LOADING"
	end
	local price = nextPrice(player)
	if price == nil then
		return false, "MAX"
	end
	if not CurrencyService.spend(player, price, Enum.AnalyticsEconomyTransactionType.Shop, "Slot") then
		return false, "NOT_ENOUGH"
	end
	d.bought += 1
	updateSlots(plot)
	updateShops(plot)
	Signals.track(player, "SlotBought", 1)
	KitFx.send(player, "SlotBought", { slots = Plots.slotCount(player) })
	Signals.dirty(player)
	return true
end

local function lock(player: Player)
	local cfg = config
	local plot = byPlayer[player]
	local lockCfg = if cfg then cfg.lock else nil
	if not lockCfg or not plot then
		return
	end
	local now = os.time()
	if now < plot.lockReadyAt then
		return
	end
	plot.lockedUntil = now + lockCfg.seconds
	plot.lockReadyAt = plot.lockedUntil + lockCfg.cooldown
	setBarriers(plot, true)
	Signals.track(player, "Lock", 1)
	KitFx.send(player, "Locked", { endsAt = plot.lockedUntil })
	Signals.dirty(player)
end

-- Coloca la unidad en un espacio abierto y libre (`slot` nil = el primero libre).
function Plots.place(player: Player, uid: number, slot: number?): (boolean, string?)
	local unit = Units.find(player, uid)
	if not unit then
		return false, "UNKNOWN"
	end
	if not byPlayer[player] then
		return false, "NO_PLOT"
	end
	if unit.equipped then
		return false, "EQUIPPED"
	end
	local target = slot or Plots.freeSlot(player)
	if target == nil then
		return false, "NO_SLOT"
	end
	if target < 1 or target > Plots.slotCount(player) then
		return false, "LOCKED"
	end
	for _, other in Units.list(player) do
		if other.slot == target and other.uid ~= uid then
			return false, "TAKEN"
		end
	end
	Units.place(player, unit, target)
	Signals.track(player, "Place", 1)
	return true
end

function Plots.store(player: Player, uid: number): boolean
	local unit = Units.find(player, uid)
	if not unit or unit.slot == nil then
		return false
	end
	Units.place(player, unit, nil)
	return true
end

local function spawnAt(player: Player, plot: Plot)
	local spawn = plot.spawn
	if not spawn then
		return
	end
	if spawn:IsA("SpawnLocation") then
		player.RespawnLocation = spawn
	end
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
	end
end

-- Revisa lo colocado al cargar: espacios cerrados o repetidos vuelven al inventario.
local function tidy(player: Player)
	local count = Plots.slotCount(player)
	local taken: { [number]: boolean } = {}
	for _, unit in Units.list(player) do
		local slot = unit.slot
		if slot then
			if slot > count or taken[slot] or unit.equipped then
				Units.place(player, unit, nil)
			else
				taken[slot] = true
			end
		end
	end
end

local function assign(player: Player)
	if byPlayer[player] or not player.Parent then
		return
	end
	for _, plot in plots do
		if plot.owner == nil then
			plot.owner = player
			byPlayer[player] = plot
			plot.model:SetAttribute(Tags.OWNER, player.UserId)
			plot.model:SetAttribute(Tags.OWNER_NAME, player.DisplayName)
			sign(plot)
			tidy(player)
			updateSlots(plot)
			updateShops(plot)
			updatePads(plot)
			setBarriers(plot, false)
			for _, unit in Units.list(player) do
				if unit.slot then
					show(player, plot, unit)
				end
			end
			spawnAt(player, plot)
			assigned:Fire(player, plot.model)
			Signals.dirty(player)
			return
		end
	end
	warn(string.format("[Plots] no hay base libre para %s: Max Players tiene que ser %d", player.Name, #plots))
end

local function release(player: Player)
	local plot = byPlayer[player]
	if not plot then
		return
	end
	byPlayer[player] = nil
	for uid in plot.shown do
		hide(plot, uid)
	end
	plot.owner = nil
	plot.lockedUntil = 0
	plot.lockReadyAt = 0
	plot.model:SetAttribute(Tags.OWNER, 0)
	plot.model:SetAttribute(Tags.OWNER_NAME, nil)
	setBarriers(plot, false)
	sign(plot)
	updateSlots(plot)
	updateShops(plot)
	updatePads(plot)
	released:Fire(player, plot.model)
end

-- Encuentra las partes de la base (las que ya están y las que aparezcan después).
local function scan(plot: Plot)
	for _, part in plot.model:GetDescendants() do
		if not part:IsA("BasePart") or wired[part] then
			continue
		end
		if part:HasTag(Tags.SLOT) then
			local index = KitWorld.number(part, "Index")
			if index then
				plot.slots[index] = part
				wired[part] = true
			end
		elseif part:HasTag(Tags.COLLECT_PAD) then
			wired[part] = true
			table.insert(plot.pads, part)
			KitWorld.onTouch(part, function(player: Player)
				collect(player, plot)
			end, COLLECT_COOLDOWN)
		elseif part:HasTag(Tags.SPAWN) then
			wired[part] = true
			plot.spawn = part
		elseif part:HasTag(Tags.BARRIER) then
			wired[part] = true
			table.insert(plot.barriers, part)
		elseif part:HasTag(Tags.LOCK_BUTTON) then
			wired[part] = true
			table.insert(plot.lockButtons, part)
			KitWorld.onTouch(part, function(player: Player)
				if plot.owner == player then
					lock(player)
				end
			end)
		elseif part:HasTag(Tags.SLOT_SHOP) then
			wired[part] = true
			local prompt = KitWorld.prompt(part, { action = UiText.BUY, object = UiText.PLOT_BUY_SLOT, name = "SlotShop" })
			if prompt then
				plot.shops[part] = prompt
				KitWorld.onPrompt(prompt, function(player: Player)
					if plot.owner == player then
						local ok, reason = buySlot(player)
						if not ok then
							KitFx.send(player, "Error", { code = reason })
						end
					end
				end)
			end
		end
		if part.Name == "Sign" then
			plot.sign = part
		end
	end
	if plot.sign == plot.model and plot.spawn then
		plot.sign = plot.spawn :: BasePart
	end
	setBarriers(plot, plot.lockedUntil > os.time())
	sign(plot)
	updateSlots(plot)
	updateShops(plot)
	updatePads(plot)
end

local function addPlot(instance: Instance)
	if not instance:IsA("Model") or byModel[instance] then
		return
	end
	local plot: Plot = {
		model = instance,
		order = KitWorld.number(instance, "Order") or (#plots + 1),
		owner = nil,
		slots = {},
		pads = {},
		spawn = nil,
		sign = instance,
		barriers = {},
		lockButtons = {},
		shops = {},
		shown = {},
		lockedUntil = 0,
		lockReadyAt = 0,
	}
	byModel[instance] = plot
	table.insert(plots, plot)
	table.sort(plots, function(a, b)
		return a.order < b.order
	end)
	instance:SetAttribute(Tags.OWNER, 0)
	scan(plot)
	instance.DescendantAdded:Connect(function()
		task.defer(scan, plot)
	end)
	-- Jugadores que cargaron antes de que existiera la base.
	for _, player in Players:GetPlayers() do
		if DataService.get(player) and not byPlayer[player] then
			assign(player)
		end
	end
end

function Plots.init(recipe: KitTypes.KitConfig)
	local cfg = recipe.plots
	if not cfg then
		return
	end
	config = cfg
	label = cfg.label or UiText.PLOT_DEFAULT
	DataService.registerKit("plots", { bought = 0, stored = 0 })
end

function Plots.start(_recipe: KitTypes.KitConfig)
	local cfg = config
	if not cfg then
		return
	end
	KitWorld.tagged(Tags.PLOT, addPlot)
	DataService.StateChanged:Connect(function(player: Player, state: string)
		if state ~= "loading" then
			assign(player)
		end
	end)
	Players.PlayerRemoving:Connect(release)
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			local plot = byPlayer[player]
			local spawn = if plot then plot.spawn else nil
			if spawn and not spawn:IsA("SpawnLocation") then
				character:WaitForChild("HumanoidRootPart", 10)
				task.wait()
				if character.Parent then
					character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
				end
			end
		end)
	end)
	Units.Added:Connect(function(player: Player, unit: Units.Unit)
		if cfg.autoPlace and unit.slot == nil and byPlayer[player] then
			local slot = Plots.freeSlot(player)
			if slot then
				Units.place(player, unit, slot)
			end
		end
	end)
	Units.Changed:Connect(function(player: Player, unit: Units.Unit)
		local plot = byPlayer[player]
		if not plot then
			return
		end
		if unit.slot then
			show(player, plot, unit)
		else
			hide(plot, unit.uid)
		end
	end)
	Units.Removed:Connect(function(player: Player, unit: Units.Unit)
		local plot = byPlayer[player]
		if plot then
			hide(plot, unit.uid)
		end
	end)
	Bonus.Changed:Connect(function(player: Player, effect: string)
		local plot = byPlayer[player]
		if effect == "slots" and plot then
			updateSlots(plot)
			updateShops(plot)
			Signals.dirty(player)
		end
	end)
	Remotes.onInvoke("PlaceUnit", {
		args = { Validate.number({ integer = true, min = 1 }), Validate.optional(Validate.number({ integer = true, min = 1, max = cfg.maxSlots })) },
		rate = { count = 8, perSeconds = 1 },
	}, Plots.place)
	Remotes.onInvoke("StoreUnit", {
		args = { Validate.number({ integer = true, min = 1 }) },
		rate = { count = 8, perSeconds = 1 },
	}, function(player: Player, uid: number): boolean
		return Plots.store(player, uid)
	end)
	Remotes.onInvoke("BuySlot", { args = {}, rate = { count = 3, perSeconds = 1 } }, buySlot)
	if cfg.lock then
		Remotes.onEvent("LockBase", { args = {}, rate = { count = 2, perSeconds = 1 } }, function(player: Player)
			local plot = byPlayer[player]
			if plot and KitWorld.near(player, plot.model, NEAR_BASE) then
				lock(player)
			end
		end)
	end
	-- Ingreso de cada segundo y relojes de la traba.
	task.spawn(function()
		while true do
			task.wait(TICK)
			local now = os.time()
			for player, plot in byPlayer do
				local d = plotData(player)
				local income = Plots.income(player) * TICK
				if d and income > 0 then
					if auto(player) then
						CurrencyService.add(player, income, Enum.AnalyticsEconomyTransactionType.Gameplay, "Base", nil, true)
					else
						d.stored += income
						updatePads(plot)
					end
				end
				if plot.lockedUntil > 0 then
					if now >= plot.lockedUntil then
						plot.lockedUntil = 0
						setBarriers(plot, false)
						Signals.dirty(player)
					else
						setBarriers(plot, true)
					end
				end
			end
		end
	end)
	task.delay(5, function()
		if #plots > 0 and Players.MaxPlayers > #plots then
			warn(string.format("[Plots] hay %d bases y Max Players es %d: ponerlo en %d", #plots, Players.MaxPlayers, #plots))
		end
	end)
end

function Plots.snapshot(player: Player): KitTypes.PlotsState?
	local d = plotData(player)
	if not d then
		return nil
	end
	local plot = byPlayer[player]
	local cfg = config
	return {
		plot = if plot then plot.model.Name else nil,
		slots = Plots.slotCount(player),
		maxSlots = if cfg then cfg.maxSlots else 0,
		nextPrice = nextPrice(player),
		stored = math.floor(d.stored),
		auto = auto(player),
		lockedUntil = if plot then plot.lockedUntil else 0,
		lockReadyAt = if plot then plot.lockReadyAt else 0,
	}
end

return Plots
