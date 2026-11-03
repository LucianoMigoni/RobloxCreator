--!strict
-- Bloque Belt del armador: la cinta compartida de Steal a Brainrot. Cada `spawnEvery` s aparece una
-- unidad sorteada del `pool` (con mutación, tamaño y peso si la receta los usa) que cruza la parte
-- KitBelt de punta a punta, por su eje X, en `walkSeconds`; quien la compra primero (prompt "Buy") se
-- la lleva. Precio = def.price o def.value × priceMultiplier, por lo que multiplican su mutación,
-- tamaño y peso. Con plots.autoPlace va sola a la base.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local UnitModel = require(ReplicatedStorage.Shared.Kits.UnitModel)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Rarity = require(ReplicatedStorage.Shared.Lib.Rarity)
local UnitMath = require(ReplicatedStorage.Shared.Lib.UnitMath)
local CurrencyService = require("../Economy/CurrencyService")
local Signals = require("../Signals")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")
local Units = require("./Units")

type Item = {
	model: Model,
	unit: Units.Unit,
	price: number,
	rotation: CFrame,
	from: Vector3,
	to: Vector3,
	offset: Vector3, -- del punto de la cinta al pivote del modelo
	born: number,
	sold: boolean,
}

type Lane = { part: BasePart, items: { Item }, nextAt: number }

local Belt = {}

local DEFAULT_MAX = 8
local PROMPT_DISTANCE = 12

local config: KitTypes.BeltConfig? = nil
local unitsConfig: KitTypes.UnitsConfig? = nil
local lanes: { [BasePart]: Lane } = {}
local rng = Random.new()
local symbol = EconomyConfig.CURRENCIES[EconomyConfig.MAIN].symbol

local function random(): number
	return rng:NextNumber()
end

-- Precio en la moneda principal de esa unidad con su mutación, tamaño y peso.
function Belt.price(def: KitTypes.UnitDef, unit: Units.Unit): number
	local cfg = config
	local base = def.price or ((def.value or 0) * (if cfg then cfg.priceMultiplier or 1 else 1))
	local mutations, sizes = Units.variants()
	return math.max(0, math.floor(base * UnitMath.multiplier(def, unit, mutations, sizes) + 0.5))
end

local function buy(player: Player, item: Item)
	if item.sold or not item.model.Parent then
		return
	end
	if Units.isFull(player) then
		KitFx.send(player, "Error", { code = "FULL" })
		return
	end
	if not CurrencyService.spend(player, item.price, Enum.AnalyticsEconomyTransactionType.Shop, "Belt") then
		KitFx.send(player, "Error", { code = "NOT_ENOUGH" })
		return
	end
	item.sold = true
	local u = item.unit
	local unit, _, isNew = Units.add(player, u.kind, { source = "Belt", variant = u.variant, size = u.size, weight = u.weight })
	if not unit then
		-- No debería pasar (se miró el lugar antes de cobrar): se devuelve la plata.
		item.sold = false
		CurrencyService.add(player, item.price, Enum.AnalyticsEconomyTransactionType.Shop, "BeltRefund")
		return
	end
	item.model:Destroy()
	Signals.track(player, "UnitBought", 1)
	KitFx.send(player, "Bought", { kind = unit.kind, variant = unit.variant, size = unit.size, isNew = isNew, price = item.price })
end

local function spawnUnit(lane: Lane)
	local cfg = config
	local units = unitsConfig
	if not cfg or not units then
		return
	end
	local entries = UnitMath.entries(cfg.pool, Units.defs(), Units.rarities(), units.luckyFrom)
	if #entries == 0 then
		return
	end
	local picked = Rarity.roll(entries, 1, random)
	local def = Units.def(picked.id)
	if not def then
		return
	end
	local mutations, sizes = Units.variants()
	local unit: Units.Unit = {
		uid = 0,
		kind = def.id,
		variant = if units.mutations then UnitMath.rollVariant(mutations, 1, random) else nil,
		size = if units.sizes then UnitMath.rollVariant(sizes, 1, random) else nil,
		weight = UnitMath.rollWeight(def, random),
	}
	local part = lane.part
	local half = part.Size.X / 2
	local from = (part.CFrame * CFrame.new(-half, part.Size.Y / 2, 0)).Position
	local to = (part.CFrame * CFrame.new(half, part.Size.Y / 2, 0)).Position
	local facing = CFrame.lookAt(from, to)
	local model = UnitModel.make(def, unit)
	UnitModel.standOn(model, facing)
	local item: Item = {
		model = model,
		unit = unit,
		price = Belt.price(def, unit),
		rotation = facing.Rotation,
		from = from,
		to = to,
		offset = model:GetPivot().Position - from,
		born = os.clock(),
		sold = false,
	}
	model:SetAttribute("Price", item.price) -- para el cartel de cada cliente
	model.Parent = part.Parent or part
	local prompt = KitWorld.prompt(model, {
		action = UiText.PROMPT_BUY,
		object = UnitMath.name(def, unit) .. " · " .. Format.money(item.price, symbol),
		distance = PROMPT_DISTANCE,
		name = "BeltBuy",
	})
	if prompt then
		KitWorld.onPrompt(prompt, function(player: Player)
			buy(player, item)
		end, 0.5)
	end
	table.insert(lane.items, item)
end

local function step()
	local cfg = config
	if not cfg then
		return
	end
	local now = os.clock()
	for _, lane in lanes do
		if now >= lane.nextAt then
			lane.nextAt = now + cfg.spawnEvery
			if #lane.items < (cfg.maxOnBelt or DEFAULT_MAX) then
				spawnUnit(lane)
			end
		end
		for i = #lane.items, 1, -1 do
			local item = lane.items[i]
			local alpha = (now - item.born) / cfg.walkSeconds
			if item.sold or alpha >= 1 or not item.model.Parent then
				table.remove(lane.items, i)
				if item.model.Parent then
					item.model:Destroy()
				end
			else
				item.model:PivotTo(item.rotation + item.from:Lerp(item.to, alpha) + item.offset)
			end
		end
	end
end

function Belt.init(recipe: KitTypes.KitConfig)
	config = recipe.belt
	unitsConfig = recipe.units
end

function Belt.start(_recipe: KitTypes.KitConfig)
	if not config then
		return
	end
	KitWorld.tagged(Tags.BELT, function(instance: Instance)
		if instance:IsA("BasePart") and not lanes[instance] then
			lanes[instance] = { part = instance, items = {}, nextAt = os.clock() }
		end
	end, function(instance: Instance)
		local lane = if instance:IsA("BasePart") then lanes[instance] else nil
		if lane then
			lanes[instance :: BasePart] = nil
			for _, item in lane.items do
				item.model:Destroy()
			end
		end
	end)
	RunService.Heartbeat:Connect(step)
end

return Belt
