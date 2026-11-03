--!strict
-- Bloque Tycoon del armador: edificios que se compran pisando botones en la base, en orden, como
-- My Small Business o los tycoons clásicos. Dentro de cada KitPlot: botones KitTycoonButton
-- (atributo Building) y edificios KitBuilding (mismo atributo). Cada edificio aparece al comprarlo
-- (vive escondido en ServerStorage hasta entonces), y su botón solo se ve cuando ya se compró el
-- anterior (`after`). Lo que pagan por segundo (× el multiplicador de plata) entra por el cobro de la
-- base (Plots.addStored).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local BoostService = require("../Boosts/BoostService")
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local Signals = require("../Signals")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")
local Plots = require("./Plots")

type TycoonData = { built: { [string]: boolean } }
type Piece = { instance: Instance, plot: Model, home: Instance }

local Tycoon = {}

local TICK = 1
local SIGN_TAG = "HitSign"

local list: { KitTypes.Building } = {}
local byId: { [string]: KitTypes.Building } = {}
local buildings: { [Model]: { [string]: Piece } } = {}
local buttons: { [Model]: { [string]: BasePart } } = {}
local hidden: Folder? = nil

local function data(player: Player): TycoonData?
	local d = DataService.get(player)
	return if d then d.kits.tycoon :: TycoonData else nil
end

local function storage(): Folder
	local folder = hidden
	if not folder then
		local created = Instance.new("Folder")
		created.Name = "KitHiddenBuildings"
		created.Parent = ServerStorage
		folder = created
		hidden = created
	end
	return folder :: Folder
end

local function setBuilt(piece: Piece, built: boolean)
	piece.instance.Parent = if built then piece.home else storage()
end

local function setButton(button: BasePart, building: KitTypes.Building?)
	if building then
		local currency = EconomyConfig.CURRENCIES[building.price.currency]
		KitWorld.sign(button, building.name .. " · " .. Format.money(building.price.amount, if currency then currency.symbol else ""), "Accept", "cash", 9)
		button.Transparency = 0
		button.CanTouch = true
	else
		button:RemoveTag(SIGN_TAG)
		button.Transparency = 1
		button.CanTouch = false
	end
end

-- Muestra lo comprado y los botones que se pueden usar en la base de ese jugador (o todo cerrado).
local function refresh(plot: Model, owner: Player?)
	local d = if owner then data(owner) else nil
	local built: { [string]: boolean } = if d then d.built else {}
	local pieces = buildings[plot]
	if pieces then
		for id, piece in pieces do
			setBuilt(piece, built[id] == true)
		end
	end
	local pads = buttons[plot]
	if pads then
		for id, button in pads do
			local building = byId[id]
			local after = if building then building.after else nil
			local available = owner ~= nil and building ~= nil and not built[id] and (after == nil or built[after] == true)
			setButton(button, if available then building else nil)
		end
	end
end

function Tycoon.income(player: Player): number
	local d = data(player)
	if not d then
		return 0
	end
	local total = 0
	for id in d.built do
		local building = byId[id]
		if building then
			total += building.income
		end
	end
	return if total > 0 then total * BoostService.multiplier(player, "Money") else 0
end

function Tycoon.build(player: Player, id: string): (boolean, string?)
	local building = byId[id]
	local d = data(player)
	local plot = Plots.plotOf(player)
	if not building or not d or not plot then
		return false, "UNKNOWN"
	end
	if d.built[id] then
		return false, "OWNED"
	end
	local after = building.after
	if after and not d.built[after] then
		return false, "ORDER"
	end
	if not CurrencyService.spend(player, building.price.amount, Enum.AnalyticsEconomyTransactionType.Shop, "Build_" .. id, building.price.currency) then
		return false, "NOT_ENOUGH"
	end
	d.built[id] = true
	refresh(plot, player)
	Signals.track(player, "Build", 1)
	KitFx.send(player, "Built", { id = id, name = building.name })
	Signals.dirty(player)
	return true
end

local function register(instance: Instance, isButton: boolean)
	local plot = Plots.plotContaining(instance)
	local id = KitWorld.text(instance, "Building")
	if not plot or not id then
		warn("[Tycoon] " .. instance:GetFullName() .. " no está dentro de un KitPlot o no tiene Building")
		return
	end
	if isButton then
		local part = KitWorld.part(instance)
		if not part then
			return
		end
		local map = buttons[plot] or {}
		buttons[plot] = map
		map[id] = part
		KitWorld.onTouch(part, function(player: Player)
			if Plots.plotOf(player) == plot then
				local ok, reason = Tycoon.build(player, id)
				if not ok and reason ~= "OWNED" then
					KitFx.send(player, "Error", { code = reason })
				end
			end
		end, 1)
	else
		local map = buildings[plot] or {}
		buildings[plot] = map
		map[id] = { instance = instance, plot = plot, home = instance.Parent or plot }
	end
	refresh(plot, Plots.ownerOf(plot))
end

function Tycoon.init(recipe: KitTypes.KitConfig)
	local cfg = recipe.tycoon
	if not cfg then
		return
	end
	list = cfg.buildings
	for _, building in list do
		byId[building.id] = building
	end
	DataService.registerKit("tycoon", { built = {} })
end

function Tycoon.start(_recipe: KitTypes.KitConfig)
	if #list == 0 then
		return
	end
	KitWorld.tagged(Tags.TYCOON_BUTTON, function(instance: Instance)
		register(instance, true)
	end)
	KitWorld.tagged(Tags.BUILDING, function(instance: Instance)
		-- Lo que ya se escondió en ServerStorage no se vuelve a registrar.
		if not instance:IsDescendantOf(ServerStorage) then
			register(instance, false)
		end
	end)
	Plots.Assigned:Connect(function(player: Player, plot: Model)
		refresh(plot, player)
	end)
	Plots.Released:Connect(function(_player: Player, plot: Model)
		refresh(plot, nil)
	end)
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in Players:GetPlayers() do
				local income = Tycoon.income(player) * TICK
				if income > 0 then
					Plots.addStored(player, income, "Tycoon")
				end
			end
		end
	end)
end

function Tycoon.snapshot(player: Player): KitTypes.TycoonState?
	local d = data(player)
	return if d then { built = d.built } else nil
end

return Tycoon
