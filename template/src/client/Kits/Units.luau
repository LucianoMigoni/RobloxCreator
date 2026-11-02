--!strict
-- UI del bloque Units:
-- - Las piezas del índice (cada unidad en cada mutación, con el color de su rareza, su "1 in N" y lo
--   que da) para la ventana del núcleo (IndexController).
-- - El cartel sobre cada unidad del mundo (etiqueta "KitUnit": bases, cinta, salvajes): nombre con su
--   mutación, rareza en su color y lo que da ("$12/s"), su precio en la cinta o lo que pide para
--   capturarla; "Being stolen!" mientras se la llevan.
-- - Lo que comparten el inventario y las mascotas que siguen: mutaciones, tamaños, modelo y detalle.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local RarityConfig = require(ReplicatedStorage.Shared.Config.RarityConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local UnitModel = require(ReplicatedStorage.Shared.Kits.UnitModel)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local UnitMath = require(ReplicatedStorage.Shared.Lib.UnitMath)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local IndexController = require("../Controllers/IndexController")
local World = require("../UI/World")
local KitUi = require("./KitUi")

local Units = {}

local PRICE_COLOR = Color3.fromRGB(255, 220, 80)
local STOLEN_COLOR = Color3.fromRGB(255, 80, 80)
local TAG_WIDTH = 7

local mutations: { UnitMath.Variant } = {}
for _, v in RarityConfig.MUTATIONS do
	table.insert(mutations, { id = v.id, weight = v.weight, mult = v.mult, lucky = v.lucky })
end
local sizes: { UnitMath.Variant } = {}
for _, v in RarityConfig.SIZES do
	table.insert(sizes, { id = v.id, weight = v.weight, mult = v.mult, lucky = v.lucky })
end

-- Mutaciones y tamaños como los usa UnitMath.
function Units.variants(): ({ UnitMath.Variant }, { UnitMath.Variant })
	return mutations, sizes
end

-- Modelo de la unidad en ReplicatedStorage.Assets.Units (sin modelo, el índice usa el ícono).
function Units.model(def: KitTypes.UnitDef): Model?
	local name = def.model
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = if assets then assets:FindFirstChild("Units") else nil
	local found = if folder and name then folder:FindFirstChild(name) else nil
	return if found and found:IsA("Model") then found else nil
end

-- Lo que da, con formato: "$12/s" en una base, "+25% Money" equipada o "$500" al venderla.
function Units.detail(def: KitTypes.UnitDef, unit: KitTypes.Unit): string?
	local symbol = EconomyConfig.CURRENCIES[EconomyConfig.MAIN].symbol
	if def.income then
		return Format.perSecond(UnitMath.income(def, unit, mutations, sizes), symbol)
	end
	local equip = KitConfig.equip
	if def.power and equip then
		return "+" .. Format.percent(UnitMath.power(def, unit, mutations, sizes), 0) .. " " .. equip.stat
	end
	if def.value then
		return Format.money(UnitMath.value(def, unit, mutations, sizes), symbol)
	end
	return nil
end

local function entries(): { IndexController.Entry }
	local cfg = KitConfig.units
	local out: { IndexController.Entry } = {}
	if not cfg then
		return out
	end
	local chances = UnitMath.chances(KitConfig)
	local variants: { string? } = { nil }
	if cfg.mutations then
		variants = {}
		for _, v in mutations do
			table.insert(variants, v.id)
		end
	end
	for order, def in cfg.list do
		local base = chances[def.id]
		local model = Units.model(def)
		for v, variant in variants do
			local unit: KitTypes.Unit = { uid = 0, kind = def.id, variant = if variant == "Normal" then nil else variant }
			local chance = if base then base * (if cfg.mutations then UnitMath.variantChance(mutations, variant) else 1) else nil
			table.insert(out, {
				key = UnitMath.key(def.id, unit.variant),
				name = UnitMath.name(def, unit),
				zone = def.zone,
				variant = if cfg.mutations then variant or "Normal" else nil,
				rarity = def.rarity,
				chance = chance,
				detail = Units.detail(def, unit),
				icon = def.icon,
				model = model,
				order = (v - 1) * #cfg.list + order,
			})
		end
	end
	return out
end

local function text(instance: Instance, name: string): string?
	local value = instance:GetAttribute(name)
	return if typeof(value) == "string" and value ~= "" then value else nil
end

local function statLabel(id: string?): string
	for _, def in KitConfig.stats or ({} :: { KitTypes.StatDef }) do
		if def.id == id then
			return def.label
		end
	end
	return id or ""
end

-- Líneas del cartel de una unidad del mundo según sus atributos (Kind, Variant, Size, Income, Price,
-- BeingStolen).
local function tagLines(model: Instance): { World.Line }?
	local kind = text(model, "Kind")
	local def = if kind then KitUi.unitDef(kind) else nil
	if not kind or not def then
		return nil
	end
	local info = { kind = kind, variant = text(model, "Variant"), size = text(model, "Size") }
	local symbol = EconomyConfig.CURRENCIES[EconomyConfig.MAIN].symbol
	local lines: { World.Line } = {}
	if model:GetAttribute("BeingStolen") ~= nil then
		table.insert(lines, { text = UiText.BEING_STOLEN, color = STOLEN_COLOR })
	end
	table.insert(lines, { text = UnitMath.name(def, info), color = KitUi.variantColor(info.variant) or KitUi.rarityColor(def.rarity) })
	table.insert(lines, { text = def.rarity, color = KitUi.rarityColor(def.rarity) })
	local income = model:GetAttribute("Income")
	local price = model:GetAttribute("Price")
	local wild = KitConfig.wild
	if typeof(income) == "number" then
		table.insert(lines, { text = Format.perSecond(income, symbol), color = UIKit.MONEY_COLOR })
	elseif typeof(price) == "number" then
		table.insert(lines, { text = Format.money(price, symbol), color = PRICE_COLOR })
	elseif def.requirement and wild and wild.stat then
		table.insert(lines, { text = string.format(UiText.NEEDS, Format.number(def.requirement), statLabel(wild.stat)), color = PRICE_COLOR })
	end
	return lines
end

local function watchTags()
	local guis: { [Instance]: BillboardGui } = {}
	local connections: { [Instance]: { RBXScriptConnection } } = {}
	local function refresh(model: Instance)
		local lines = tagLines(model)
		local gui = guis[model]
		if not lines then
			return
		end
		if gui and gui.Parent then
			World.setTag(gui, lines)
		else
			local made = World.tag(model, lines, TAG_WIDTH)
			if made then
				guis[model] = made
			end
		end
	end
	local function added(model: Instance)
		if connections[model] then
			return
		end
		local list = {}
		for _, name in { "Income", "Price", "BeingStolen", "Variant", "Size" } do
			table.insert(list, model:GetAttributeChangedSignal(name):Connect(function()
				refresh(model)
			end))
		end
		connections[model] = list
		-- Al aparecer, las partes del modelo pueden estar llegando todavía.
		task.defer(refresh, model)
	end
	local function removed(model: Instance)
		local list = connections[model]
		if list then
			for _, connection in list do
				connection:Disconnect()
			end
		end
		connections[model] = nil
		local gui = guis[model]
		if gui then
			gui:Destroy()
		end
		guis[model] = nil
	end
	for _, model in CollectionService:GetTagged(UnitModel.TAG) do
		added(model)
	end
	CollectionService:GetInstanceAddedSignal(UnitModel.TAG):Connect(added)
	CollectionService:GetInstanceRemovedSignal(UnitModel.TAG):Connect(removed)
end

function Units.start(_hud: HudController.Hud)
	Bus.handle("IndexEntries", entries)
	watchTags()
end

return Units
