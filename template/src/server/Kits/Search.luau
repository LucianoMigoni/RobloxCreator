--!strict
-- Bloque Search del armador: buscar en pilas, como Search For The Needle o los juegos de cavar.
-- - DigPile() cerca de una KitPile (atributo Pile = id de search.piles), con la zona abierta y la
--   herramienta lista (`cooldown`). Cada golpe encuentra algo con chance `findChance` × poder de la
--   herramienta (+ mejora "power"), sorteado con la suerte del jugador; `coins` paga algo por golpe.
-- - Lo encontrado va a la mochila (`bag` + mejora "bag"); llena, no se puede seguir.
-- - Pisar KitDepositPad vacía la mochila: al inventario o, con `depositCurrency`, vendido por su valor
--   (igual queda anotado en el índice).
-- Herramientas: la primera se tiene al empezar; las demás se compran (BuyTool) o se ganan ("Tool:<id>").

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Rarity = require(ReplicatedStorage.Shared.Lib.Rarity)
local UnitMath = require(ReplicatedStorage.Shared.Lib.UnitMath)
local Types = require(ReplicatedStorage.Shared.Types)
local BoostService = require("../Boosts/BoostService")
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local IndexService = require("../Retention/IndexService")
local Signals = require("../Signals")
local Bonus = require("./Bonus")
local Gates = require("./Gates")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")
local Units = require("./Units")

type SearchData = { tool: string, owned: { [string]: boolean }, bag: { KitTypes.Found } }

local Search = {}

local PILE_RANGE = 14
local MAX_FIND = 0.95

local config: KitTypes.SearchConfig? = nil
local unitsConfig: KitTypes.UnitsConfig? = nil
local piles: { [string]: KitTypes.Pile } = {}
local tools: { [string]: KitTypes.SearchTool } = {}
local lastDig: { [Player]: number } = {}
local rng = Random.new()

local function data(player: Player): SearchData?
	local d = DataService.get(player)
	return if d then d.kits.search :: SearchData else nil
end

function Search.tool(player: Player): KitTypes.SearchTool?
	local cfg = config
	local d = data(player)
	if not cfg then
		return nil
	end
	return (if d then tools[d.tool] else nil) or cfg.tools[1]
end

function Search.capacity(player: Player): number
	local cfg = config
	return (if cfg then cfg.bag else 0) + math.floor(Bonus.get(player, "bag"))
end

local function nearPile(player: Player): (KitTypes.Pile?, Instance?)
	for _, instance in CollectionService:GetTagged(Tags.PILE) do
		local pile = piles[KitWorld.text(instance, "Pile") or ""]
		if pile and KitWorld.near(player, instance, PILE_RANGE) and Gates.open(player, pile.zone or KitWorld.inherited(instance, "Zone")) then
			return pile, instance
		end
	end
	return nil, nil
end

function Search.dig(player: Player): (boolean, string?)
	local cfg = config
	local d = data(player)
	local tool = Search.tool(player)
	if not cfg or not d or not tool then
		return false, "LOADING"
	end
	local now = os.clock()
	if now - (lastDig[player] or 0) < tool.cooldown then
		return false, "COOLDOWN"
	end
	if #d.bag >= Search.capacity(player) then
		return false, "BAG_FULL"
	end
	local pile = nearPile(player)
	if not pile then
		return false, "FAR"
	end
	lastDig[player] = now
	Signals.track(player, "Dig", 1)
	local coins = pile.coins
	if coins then
		CurrencyService.add(player, coins.amount * BoostService.multiplier(player, coins.currency), Enum.AnalyticsEconomyTransactionType.Gameplay, "Dig", coins.currency, true)
	end
	local power = tool.power + Bonus.get(player, "power")
	if rng:NextNumber() >= math.min(MAX_FIND, pile.findChance * power) then
		KitFx.send(player, "Dug", { found = false })
		return true
	end
	local units = unitsConfig
	local entries = UnitMath.entries(pile.entries, Units.defs(), Units.rarities(), if units then units.luckyFrom else nil)
	if #entries == 0 then
		return true
	end
	local function random(): number
		return rng:NextNumber()
	end
	local picked = Rarity.roll(entries, BoostService.multiplier(player, "Luck"), random)
	local def = Units.def(picked.id)
	if not def then
		return true
	end
	local variant, size = Units.rollVariants(player)
	local found: KitTypes.Found = { kind = def.id, variant = variant, size = size, weight = UnitMath.rollWeight(def, random) }
	table.insert(d.bag, found)
	Signals.track(player, "Found", 1)
	KitFx.send(player, "Found", { kind = found.kind, variant = found.variant, size = found.size, isNew = not (DataService.get(player) :: any).index[UnitMath.key(found.kind, found.variant)] })
	Signals.dirty(player)
	return true
end

-- Vacía la mochila: al inventario (lo que entre) o vendido con `depositCurrency`.
function Search.deposit(player: Player): number
	local cfg = config
	local d = data(player)
	if not cfg or not d or #d.bag == 0 then
		return 0
	end
	local currency = cfg.depositCurrency
	local count, earned = 0, 0
	local kept: { KitTypes.Found } = {}
	for _, found in d.bag do
		if currency then
			local unit: Units.Unit = { uid = 0, kind = found.kind, variant = found.variant, size = found.size, weight = found.weight }
			earned += Units.value(unit)
			IndexService.discover(player, UnitMath.key(found.kind, found.variant))
			count += 1
		else
			local unit = Units.add(player, found.kind, { source = "Search", variant = found.variant, size = found.size, weight = found.weight })
			if unit then
				count += 1
			else
				table.insert(kept, found)
			end
		end
	end
	d.bag = kept
	if currency and earned > 0 then
		earned *= BoostService.multiplier(player, currency)
		CurrencyService.add(player, earned, Enum.AnalyticsEconomyTransactionType.Gameplay, "Deposit", currency)
	end
	if count > 0 then
		Signals.track(player, "Deposit", count)
		KitFx.send(player, "Deposited", { count = count, amount = math.floor(earned), currency = currency })
	end
	Signals.dirty(player)
	return count
end

local function own(player: Player, tool: KitTypes.SearchTool)
	local d = data(player)
	if d then
		d.owned[tool.id] = true
		d.tool = tool.id
		Signals.dirty(player)
	end
end

function Search.buyTool(player: Player, id: string): (boolean, string?)
	local tool = tools[id]
	local d = data(player)
	if not tool or not d then
		return false, "UNKNOWN"
	end
	if d.owned[id] then
		d.tool = id
		Signals.dirty(player)
		return true
	end
	local price = tool.price
	if not price then
		return false, "NOT_FOR_SALE"
	end
	if not CurrencyService.spend(player, price.amount, Enum.AnalyticsEconomyTransactionType.Shop, "Tool_" .. id, price.currency) then
		return false, "NOT_ENOUGH"
	end
	own(player, tool)
	Signals.track(player, "ToolBought", 1)
	return true
end

local function give(player: Player, value: string, _count: number): (boolean, Types.RewardLine?)
	local tool = tools[value]
	if not tool or not data(player) then
		return false, nil
	end
	own(player, tool)
	return true, { icon = "pickaxe", text = tool.name, kind = "item" }
end

function Search.init(recipe: KitTypes.KitConfig)
	local cfg = recipe.search
	if not cfg then
		return
	end
	config = cfg
	unitsConfig = recipe.units
	for _, pile in cfg.piles do
		piles[pile.id] = pile
	end
	for _, tool in cfg.tools do
		tools[tool.id] = tool
	end
	local first = cfg.tools[1]
	DataService.registerKit("search", { tool = if first then first.id else "", owned = if first then { [first.id] = true } else {}, bag = {} })
end

function Search.start(_recipe: KitTypes.KitConfig)
	if not config then
		return
	end
	local ids = {}
	for id in tools do
		table.insert(ids, id)
	end
	Remotes.onInvoke("DigPile", { args = {}, rate = { count = 12, perSeconds = 1 } }, Search.dig)
	Remotes.onInvoke("BuyTool", { args = { Validate.oneOf(ids) }, rate = { count = 3, perSeconds = 1 } }, Search.buyTool)
	KitWorld.tagged(Tags.PILE, function(instance: Instance)
		local prompt = KitWorld.prompt(instance, { action = UiText.PROMPT_SEARCH, name = "Pile", distance = PILE_RANGE })
		if prompt then
			-- Cada toque del prompt es un golpe (el botón de la barra de acción hace lo mismo).
			KitWorld.onPrompt(prompt, function(player: Player)
				local ok, reason = Search.dig(player)
				if not ok and reason ~= "COOLDOWN" then
					KitFx.send(player, "Error", { code = reason })
				end
			end, 0.1)
		end
	end)
	KitWorld.tagged(Tags.DEPOSIT_PAD, function(instance: Instance)
		local part = KitWorld.part(instance)
		if part then
			KitWorld.sign(instance, UiText.DEPOSIT_SIGN, "Accept", "inventory", 10)
			KitWorld.onTouch(part, function(player: Player)
				Search.deposit(player)
			end, 1.5)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		lastDig[player] = nil
	end)
end

function Search.snapshot(player: Player): KitTypes.SearchState?
	local d = data(player)
	local tool = Search.tool(player)
	if not d or not tool then
		return nil
	end
	return { tool = tool.id, owned = d.owned, bag = d.bag, capacity = Search.capacity(player) }
end

Search.items = { Tool = give }

return Search
