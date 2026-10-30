--!strict
-- Cargador del armador: lee la receta (Config/KitConfig), la revisa con las listas reales (Lib/KitCheck)
-- y arranca los bloques que usa, en el orden de KitCheck.BLOCKS. Conecta los bloques con el núcleo en un
-- solo lugar:
-- - RewardService.setItemHandler: cada premio "Prefijo:valor" va al bloque de ese prefijo
--   (KitCheck.ITEMS: "Unit:Dragon:Gold", "Roll:Basic", "Upgrade:Slots"...).
-- - RewardService.setIncomeProvider: lo que gana el jugador por segundo es la suma de los bloques
--   (bases, tycoon); de ahí salen los premios "N minutos de ganancias" y las ganancias sin conexión.
-- - PlayerStateService.setKitProvider: el cliente ve lo de cada bloque en state.kit.<bloque>.
-- Main.server: init() antes de arrancar el núcleo (los bloques registran sus datos) y start() después,
-- pero antes de DataService.start (así escuchan la carga de cada jugador).
-- Cada bloque nuevo se suma a BLOCKS con la misma forma (references/bloques.md).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BoostConfig = require(ReplicatedStorage.Shared.Config.BoostConfig)
local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local RarityConfig = require(ReplicatedStorage.Shared.Config.RarityConfig)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local KitCheck = require(ReplicatedStorage.Shared.Lib.KitCheck)
local Types = require(ReplicatedStorage.Shared.Types)
local PlayerStateService = require("../PlayerStateService")
local RewardService = require("../Rewards/RewardService")
local Units = require("./Units")

-- Entrega un premio del bloque: (jugador, valor después del prefijo, cantidad) → si pudo y la línea
-- del popup ("+1 Dragon").
export type ItemHandler = (Player, string, number) -> (boolean, Types.RewardLine?)

export type Block = {
	key: string, -- campo de la receta ("units"): el bloque arranca si la receta lo tiene
	init: (KitTypes.KitConfig) -> (), -- registra sus datos (DataService.registerKit)
	start: (KitTypes.KitConfig) -> (), -- remotes, partes del mapa, bucles
	snapshot: ((Player) -> any)?, -- lo que ve el cliente en state.kit.<key>
	income: ((Player) -> number)?, -- plata por segundo que genera (con multiplicadores)
	items: { [string]: ItemHandler }?, -- premios por prefijo de KitCheck.ITEMS
}

local Kits = {}

-- Un bloque por fila, en el orden de KitCheck.BLOCKS.
local BLOCKS: { Block } = {
	{ key = "units", init = Units.init, start = Units.start, snapshot = Units.snapshot, items = Units.items },
}

local active: { Block } = {}
local handlers: { [string]: ItemHandler } = {}
local initialized = false

local function enabled(block: Block): boolean
	return (KitConfig :: any)[block.key] ~= nil
end

-- Las listas reales del núcleo, para revisar la receta igual que tests/KitKnown.luau.
local function known(): KitCheck.Known
	local fromRecipe: { [string]: boolean } = {}
	for _, c in KitConfig.currencies or ({} :: { KitTypes.CurrencyDef }) do
		fromRecipe[c.id] = true
	end
	local rarities, mutations, sizes, currencies, boosts, passes, products = {}, {}, {}, {}, {}, {}, {}
	for _, tier in RarityConfig.TIERS do
		table.insert(rarities, tier.id)
	end
	for _, variant in RarityConfig.MUTATIONS do
		table.insert(mutations, variant.id)
	end
	for _, variant in RarityConfig.SIZES do
		table.insert(sizes, variant.id)
	end
	for id in EconomyConfig.CURRENCIES do
		if not fromRecipe[id] then
			table.insert(currencies, id)
		end
	end
	for id in BoostConfig.TIMED do
		table.insert(boosts, id)
	end
	for _, pass in ShopConfig.PASSES do
		table.insert(passes, pass.key)
	end
	for _, product in ShopConfig.PRODUCTS do
		table.insert(products, product.key)
	end
	return {
		rarities = rarities,
		mutations = mutations,
		sizes = sizes,
		currencies = currencies,
		boosts = boosts,
		passes = passes,
		products = products,
	}
end

local function giveItem(player: Player, item: string, count: number): (boolean, Types.RewardLine?)
	local prefix, value = string.match(item, "^(%a+):(.+)$")
	local handler = if prefix then handlers[prefix] else nil
	if not handler or not value then
		warn("[Kits] premio '" .. item .. "' sin bloque activo que lo entregue")
		return false, nil
	end
	return handler(player, value, math.max(1, math.floor(count)))
end

local function income(player: Player): number
	local total = 0
	for _, block in active do
		local provider = block.income
		if provider then
			local ok, value = pcall(provider, player)
			if ok and typeof(value) == "number" and value == value and value ~= math.huge then
				total += math.max(0, value)
			elseif not ok then
				warn("[Kits] error en el ingreso de " .. block.key .. ": " .. tostring(value))
			end
		end
	end
	return total
end

local function snapshot(player: Player): { [string]: any }
	local out: { [string]: any } = {}
	for _, block in active do
		local provider = block.snapshot
		if provider then
			local ok, value = pcall(provider, player)
			if ok then
				out[block.key] = value
			else
				warn("[Kits] error en el estado de " .. block.key .. ": " .. tostring(value))
			end
		end
	end
	return out
end

-- ¿La receta usa este bloque? ("units", "plots"...)
function Kits.uses(key: string): boolean
	return (KitConfig :: any)[key] ~= nil
end

function Kits.init()
	if initialized then
		return
	end
	initialized = true
	local problems = KitCheck.check(KitConfig, known())
	for _, problem in problems do
		warn("[Kits] receta '" .. KitConfig.name .. "': " .. problem)
	end
	for _, block in BLOCKS do
		if enabled(block) then
			-- El cast deja leer el error: pcall de una función sin retorno solo tipa el booleano.
			local ok, err = pcall(block.init :: (KitTypes.KitConfig) -> ...any, KitConfig)
			if ok then
				table.insert(active, block)
				local items = block.items
				if items then
					for prefix, handler in items do
						handlers[prefix] = handler
					end
				end
			else
				warn("[Kits] el bloque " .. block.key .. " no arrancó: " .. tostring(err))
			end
		end
	end
	if #active == 0 then
		return
	end
	RewardService.setItemHandler(giveItem)
	RewardService.setIncomeProvider(income)
	PlayerStateService.setKitProvider(snapshot)
	local names = {}
	for _, block in active do
		table.insert(names, block.key)
	end
	print(string.format("[Kits] receta '%s': %s%s", KitConfig.name, table.concat(names, ", "), if #problems > 0 then string.format(" (%d problemas)", #problems) else ""))
end

function Kits.start()
	for _, block in active do
		local ok, err = pcall(block.start :: (KitTypes.KitConfig) -> ...any, KitConfig)
		if not ok then
			warn("[Kits] el bloque " .. block.key .. " falló al empezar: " .. tostring(err))
		end
	end
end

return Kits
