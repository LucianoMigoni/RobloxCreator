--!strict
-- UI del bloque Units: las piezas del índice (cada unidad en cada mutación, con el color de su rareza,
-- su "1 in N" y lo que da) para la ventana del núcleo (IndexController). El inventario se suma con la
-- UI de los bloques.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local RarityConfig = require(ReplicatedStorage.Shared.Config.RarityConfig)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local UnitMath = require(ReplicatedStorage.Shared.Lib.UnitMath)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local IndexController = require("../Controllers/IndexController")

local Units = {}

local mutations: { UnitMath.Variant } = {}
for _, v in RarityConfig.MUTATIONS do
	table.insert(mutations, { id = v.id, weight = v.weight, mult = v.mult, lucky = v.lucky })
end
local sizes: { UnitMath.Variant } = {}
for _, v in RarityConfig.SIZES do
	table.insert(sizes, { id = v.id, weight = v.weight, mult = v.mult, lucky = v.lucky })
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

function Units.start(_hud: HudController.Hud)
	Bus.handle("IndexEntries", entries)
end

return Units
