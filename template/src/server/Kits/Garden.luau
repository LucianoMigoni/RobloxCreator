--!strict
-- Bloque Garden del armador: cultivar como Grow a Garden.
-- - Tienda de semillas que se repone cada `restock` segundos de reloj real, igual en todos los
--   servidores (Lib/GardenShop); cada jugador compra hasta lo que trae su tienda (BuySeed).
-- - Parcelas KitGardenTile (atributo Index) dentro de su base: abiertas = `tiles` + compradas
--   (BuyTile, `tilePrices`) + mejora "tiles", sin pasar `maxTiles` ni las que hay en el mapa.
-- - Plantar (prompt de la parcela) con la semilla elegida (SelectSeed); crece con el reloj
--   real, así que también sin conexión (`readyAt`); la mejora "grow" la acorta.
-- - Cosechar da la unidad de la semilla (con peso y tamaño; mutación con `mutationChance`).
-- Premios "Seed:<id>" (semillas) y "Garden:Skip" (todo lo plantado, listo; si no hay nada, la próxima
-- plantada sale lista).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local UnitModel = require(ReplicatedStorage.Shared.Kits.UnitModel)
local GardenShop = require(ReplicatedStorage.Shared.Lib.GardenShop)
local Ladder = require(ReplicatedStorage.Shared.Lib.Ladder)
local UnitMath = require(ReplicatedStorage.Shared.Lib.UnitMath)
local Types = require(ReplicatedStorage.Shared.Types)
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local Signals = require("../Signals")
local Bonus = require("./Bonus")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")
local Plots = require("./Plots")
local Units = require("./Units")

type GardenData = {
	seeds: { [string]: number },
	plants: { [string]: KitTypes.Plant },
	bought: number, -- parcelas compradas
	selected: string?,
	shop: { window: number, counts: { [string]: number } },
	skips: number,
}

local Garden = {}

local TICK = 1
local MAX_BATCH = 50
local SPROUT_SIZE = Vector3.new(1, 1.4, 1)

local config: KitTypes.GardenConfig? = nil
local seeds: { [string]: KitTypes.Seed } = {}
local tilesOf: { [Model]: { [number]: BasePart } } = {}
local shown: { [BasePart]: { model: Model, ready: boolean } } = {}
local rng = Random.new()

local function data(player: Player): GardenData?
	local d = DataService.get(player)
	return if d then d.kits.garden :: GardenData else nil
end

local function tiles(player: Player): { [number]: BasePart }
	local plot = Plots.plotOf(player)
	return if plot then tilesOf[plot] or {} else {}
end

local function physical(player: Player): number
	local count = 0
	for _ in tiles(player) do
		count += 1
	end
	return count
end

function Garden.tileCount(player: Player): number
	local cfg = config
	local d = data(player)
	if not cfg or not d then
		return 0
	end
	local total = cfg.tiles + d.bought + math.floor(Bonus.get(player, "tiles"))
	return math.clamp(total, 0, math.min(cfg.maxTiles, physical(player)))
end

local function nextTilePrice(player: Player): number?
	local cfg = config
	local d = data(player)
	if not cfg or not d or Garden.tileCount(player) >= math.min(cfg.maxTiles, physical(player)) then
		return nil
	end
	return Ladder.price(d.bought + 1, cfg.tilePrices)
end

-- Lo que ya compró en la reposición de ahora (se vacía al cambiar de reposición).
local function shopState(player: Player, d: GardenData): ({ [string]: number }, { [string]: number }, number)
	local cfg = config :: KitTypes.GardenConfig
	local window, endsAt = GardenShop.window(os.time(), cfg.restock)
	if d.shop.window ~= window then
		d.shop = { window = window, counts = {} }
	end
	return GardenShop.stock(cfg.seeds, window), d.shop.counts, endsAt
end

function Garden.buySeed(player: Player, id: string, count: number): (boolean, string?)
	local seed = seeds[id]
	local d = data(player)
	if not seed or not d then
		return false, "UNKNOWN"
	end
	local stock, bought = shopState(player, d)
	local left = (stock[id] or 0) - (bought[id] or 0)
	if left <= 0 then
		return false, "SOLD_OUT"
	end
	local amount = math.min(count, left)
	if not CurrencyService.spend(player, seed.price.amount * amount, Enum.AnalyticsEconomyTransactionType.Shop, "Seed_" .. id, seed.price.currency) then
		return false, "NOT_ENOUGH"
	end
	bought[id] = (bought[id] or 0) + amount
	d.seeds[id] = (d.seeds[id] or 0) + amount
	Signals.track(player, "SeedBought", amount)
	Signals.dirty(player)
	return true
end

local function buyTile(player: Player): (boolean, string?)
	local d = data(player)
	local price = nextTilePrice(player)
	if not d then
		return false, "LOADING"
	end
	if not price then
		return false, "MAX"
	end
	if not CurrencyService.spend(player, price, Enum.AnalyticsEconomyTransactionType.Shop, "Tile") then
		return false, "NOT_ENOUGH"
	end
	d.bought += 1
	Signals.track(player, "TileBought", 1)
	Signals.dirty(player)
	return true
end

local function clearVisual(tile: BasePart)
	local visual = shown[tile]
	if visual then
		visual.model:Destroy()
		shown[tile] = nil
	end
end

-- Brote mientras crece; el cultivo de verdad cuando está listo. El prompt dice qué se puede hacer.
local function showPlant(tile: BasePart, plant: KitTypes.Plant?)
	local ready = plant ~= nil and os.time() >= plant.readyAt
	local prompt = tile:FindFirstChild("GardenTile")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.ActionText = if ready then UiText.PROMPT_HARVEST elseif plant then UiText.GROWING else UiText.PROMPT_PLANT
		prompt.Enabled = ready or plant == nil
	end
	local current = shown[tile]
	if current and plant and current.ready == ready then
		return
	end
	clearVisual(tile)
	if not plant then
		tile:SetAttribute("ReadyAt", nil)
		return
	end
	local seed = seeds[plant.seed]
	local def = if seed then Units.def(seed.unit) else nil
	local model: Model
	if ready and def then
		model = UnitModel.make(def, { kind = def.id })
	else
		model = Instance.new("Model")
		local sprout = Instance.new("Part")
		sprout.Name = "Sprout"
		sprout.Size = SPROUT_SIZE
		sprout.Color = Color3.fromRGB(90, 210, 80)
		sprout.Material = Enum.Material.SmoothPlastic
		sprout.Anchored = true
		sprout.CanCollide = false
		sprout.Parent = model
		model.PrimaryPart = sprout
	end
	UnitModel.standOn(model, tile.CFrame * CFrame.new(0, tile.Size.Y / 2, 0))
	model.Name = "Plant"
	model.Parent = tile
	tile:SetAttribute("ReadyAt", plant.readyAt)
	shown[tile] = { model = model, ready = ready }
end

local function refreshTiles(player: Player)
	local d = data(player)
	if not d then
		return
	end
	local open = Garden.tileCount(player)
	for index, tile in tiles(player) do
		tile:SetAttribute("Open", index <= open)
		showPlant(tile, d.plants[tostring(index)])
	end
end

function Garden.plant(player: Player, index: number, seedId: string?): (boolean, string?)
	local d = data(player)
	if not d then
		return false, "LOADING"
	end
	if index < 1 or index > Garden.tileCount(player) or not tiles(player)[index] then
		return false, "LOCKED"
	end
	local key = tostring(index)
	if d.plants[key] then
		return false, "TAKEN"
	end
	local id = seedId or d.selected
	if not id or (d.seeds[id] or 0) <= 0 then
		-- Sin elegida: la primera que tenga.
		id = nil
		for seedKey, count in d.seeds do
			if count > 0 and seeds[seedKey] then
				id = seedKey
				break
			end
		end
	end
	local seed = if id then seeds[id] else nil
	if not id or not seed then
		return false, "NO_SEEDS"
	end
	d.seeds[id] -= 1
	if d.seeds[id] <= 0 then
		d.seeds[id] = nil
	end
	local now = os.time()
	local grow = GardenShop.growSeconds(seed, Bonus.get(player, "grow"))
	if d.skips > 0 then
		d.skips -= 1
		grow = 0
	end
	d.plants[key] = { seed = id, plantedAt = now, readyAt = now + math.ceil(grow) }
	Signals.track(player, "Plant", 1)
	refreshTiles(player)
	Signals.dirty(player)
	return true
end

function Garden.harvest(player: Player, index: number): (boolean, string?)
	local cfg = config
	local d = data(player)
	if not cfg or not d then
		return false, "LOADING"
	end
	local key = tostring(index)
	local plant = d.plants[key]
	if not plant then
		return false, "EMPTY"
	end
	if os.time() < plant.readyAt then
		return false, "GROWING"
	end
	local seed = seeds[plant.seed]
	if not seed then
		d.plants[key] = nil
		return false, "UNKNOWN"
	end
	if Units.isFull(player) then
		return false, "FULL"
	end
	-- Una semilla pagada con una moneda que se compra con Robux da un resultado al azar: aleatorio pago
	-- (Lib/PaidRandom). A quien PolicyService se lo restringe, la cosecha sale sin azar.
	local fixed = EconomyConfig.isPurchasable(seed.price.currency) and Units.restricted(player)
	local variant: string? = nil
	local chance = cfg.mutationChance
	if chance and not fixed and rng:NextNumber() < chance then
		local mutations = Units.variants()
		local pool = {}
		for _, v in mutations do
			if v.id ~= "Normal" then
				table.insert(pool, v)
			end
		end
		variant = UnitMath.rollVariant(pool, 1, function()
			return rng:NextNumber()
		end)
	end
	local unit, reason, isNew = Units.add(player, seed.unit, { source = "Harvest", roll = true, fixed = fixed, variant = variant })
	if not unit then
		return false, reason
	end
	d.plants[key] = nil
	Signals.track(player, "Harvest", 1)
	KitFx.send(player, "Harvested", { kind = unit.kind, variant = unit.variant, size = unit.size, weight = unit.weight, isNew = isNew })
	refreshTiles(player)
	Signals.dirty(player)
	return true
end

local function giveSeed(player: Player, value: string, count: number): (boolean, Types.RewardLine?)
	local seed = seeds[value]
	local d = data(player)
	if not seed or not d then
		return false, nil
	end
	d.seeds[value] = (d.seeds[value] or 0) + count
	Signals.dirty(player)
	return true, { icon = "gift", text = (if count > 1 then count .. "x " else "") .. seed.name, kind = "item" }
end

local function giveSkip(player: Player, _value: string, count: number): (boolean, Types.RewardLine?)
	local d = data(player)
	if not d then
		return false, nil
	end
	local now = os.time()
	local any = false
	for _, plant in d.plants do
		if plant.readyAt > now then
			plant.readyAt = now
			any = true
		end
	end
	if not any then
		d.skips += count
	end
	refreshTiles(player)
	Signals.dirty(player)
	return true, { icon = "timer", text = UiText.GARDEN_SKIPPED, kind = "item" }
end

local function addTile(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	local plot = Plots.plotContaining(instance)
	local index = KitWorld.number(instance, "Index")
	if not plot or not index then
		warn("[Garden] " .. instance:GetFullName() .. " tiene KitGardenTile pero no está dentro de un KitPlot o no tiene Index")
		return
	end
	local list = tilesOf[plot] or {}
	tilesOf[plot] = list
	list[index] = instance
	local prompt = KitWorld.prompt(instance, { action = UiText.PROMPT_PLANT, name = "GardenTile", distance = 9 })
	if prompt then
		KitWorld.onPrompt(prompt, function(player: Player)
			if Plots.plotOf(player) ~= plot then
				return
			end
			local d = data(player)
			local ok, reason
			if d and d.plants[tostring(index)] then
				ok, reason = Garden.harvest(player, index)
			else
				ok, reason = Garden.plant(player, index, nil)
			end
			if not ok then
				KitFx.send(player, "Error", { code = reason })
			end
		end, 0.4)
	end
	local owner = Plots.ownerOf(plot)
	if owner then
		refreshTiles(owner)
	end
end

function Garden.init(recipe: KitTypes.KitConfig)
	local cfg = recipe.garden
	if not cfg then
		return
	end
	config = cfg
	for _, seed in cfg.seeds do
		seeds[seed.id] = seed
	end
	DataService.registerKit("garden", { seeds = {}, plants = {}, bought = 0, selected = nil, shop = { window = -1, counts = {} }, skips = 0 })
end

function Garden.start(_recipe: KitTypes.KitConfig)
	local cfg = config
	if not cfg then
		return
	end
	local ids = {}
	for id in seeds do
		table.insert(ids, id)
	end
	Remotes.onInvoke("BuySeed", {
		args = { Validate.oneOf(ids), Validate.number({ integer = true, min = 1, max = MAX_BATCH }) },
		rate = { count = 5, perSeconds = 1 },
	}, Garden.buySeed)
	Remotes.onInvoke("SelectSeed", { args = { Validate.oneOf(ids) }, rate = { count = 5, perSeconds = 1 } }, function(player: Player, id: string): boolean
		local d = data(player)
		if d then
			d.selected = id
			Signals.dirty(player)
		end
		return d ~= nil
	end)
	-- Plantar y cosechar solo por el prompt de la parcela: KitWorld.onPrompt mide la distancia en el
	-- servidor. Un remote sin distancia dejaría cosechar todo el mapa sin caminar.
	Remotes.onInvoke("BuyTile", { args = {}, rate = { count = 3, perSeconds = 1 } }, buyTile)
	KitWorld.tagged(Tags.GARDEN_TILE, addTile)
	Plots.Assigned:Connect(function(player: Player)
		refreshTiles(player)
	end)
	Plots.Released:Connect(function(_player: Player, plot: Model)
		local list = tilesOf[plot]
		if list then
			for _, tile in list do
				clearVisual(tile)
				tile:SetAttribute("ReadyAt", nil)
			end
		end
	end)
	Bonus.Changed:Connect(function(player: Player, effect: string)
		if effect == "tiles" then
			refreshTiles(player)
			Signals.dirty(player)
		end
	end)
	-- Las plantas que llegan a estar listas cambian de brote a cultivo.
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in Players:GetPlayers() do
				local d = data(player)
				if d and next(d.plants) then
					refreshTiles(player)
				end
			end
		end
	end)
end

function Garden.snapshot(player: Player): KitTypes.GardenState?
	local cfg = config
	local d = data(player)
	if not cfg or not d then
		return nil
	end
	local stock, bought, endsAt = shopState(player, d)
	return {
		seeds = d.seeds,
		plants = d.plants,
		tiles = Garden.tileCount(player),
		maxTiles = cfg.maxTiles,
		nextTilePrice = nextTilePrice(player),
		shop = { endsAt = endsAt, stock = stock, bought = bought },
	}
end

Garden.items = { Seed = giveSeed, Garden = giveSkip }

return Garden
