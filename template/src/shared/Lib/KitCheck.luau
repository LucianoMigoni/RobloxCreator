--!strict
-- Revisa una receta del armador (Config/KitConfig o Kits/Presets) antes de jugar: ids repetidos o con
-- caracteres raros, rarezas, monedas, pases o impulsos que no existen, bloques que necesitan otro bloque,
-- referencias rotas y premios mal escritos. Sin Roblox: tests/Presets.spec.luau revisa cada receta y
-- server/Kits/Kits.luau la vuelve a revisar al arrancar con las listas reales. Devuelve los problemas
-- en texto (para el equipo, en español); una lista vacía es una receta sana.

local Types = require("../Kits/Types")

export type Known = {
	rarities: { string }, -- RarityConfig.TIERS, de la más común a la más rara
	mutations: { string }, -- RarityConfig.MUTATIONS
	sizes: { string }, -- RarityConfig.SIZES
	currencies: { string }, -- EconomyConfig.CURRENCIES del núcleo (las de la receta se suman solas)
	boosts: { string }, -- BoostConfig.TIMED
	passes: { string }?, -- ShopConfig.PASSES (sin la lista, no se revisan)
	products: { string }?, -- ShopConfig.PRODUCTS (sin la lista, no se revisan)
}

local KitCheck = {}

-- Estilos de mapa de MapKit.
KitCheck.THEMES = { "meadow", "beach", "candy", "farm", "jungle", "snow", "desert", "space", "city", "volcano" }

-- Efectos de las mejoras (además de "stat:<Stat>") y el bloque que los usa.
KitCheck.EFFECTS = {
	slots = "plots", -- espacios de la base
	equip = "equip", -- espacios para equipar
	inventory = "units", -- lugar en el inventario
	bag = "search", -- capacidad de la mochila
	power = "search", -- poder de la herramienta
	tiles = "garden", -- parcelas
	grow = "garden", -- velocidad de crecimiento (fracción por nivel)
	walkSpeed = "stats", -- velocidad de caminar
	reel = "fishing", -- picada más rápida (fracción por nivel)
	capture = "wild", -- captura más rápida (fracción por nivel)
} :: { [string]: string }

-- Premios por ítem ("Unit:Dragon:Gold"): prefijo → bloque que los entrega.
KitCheck.ITEMS = {
	Unit = "units", -- Unit:<unidad>[:<mutación>[:<tamaño>]]
	Roll = "rolls", -- Roll:<tirada> (tiradas gratis de ese huevo o puesto)
	Item = "items", -- Item:<objeto>
	Upgrade = "upgrades", -- Upgrade:<mejora> (un nivel)
	Zone = "zones", -- Zone:<zona> (la abre)
	Stat = "stats", -- Stat:<estadística> (suma `count`)
	Rod = "fishing", -- Rod:<caña>
	Tool = "search", -- Tool:<herramienta>
	Seed = "garden", -- Seed:<semilla>
	Garden = "garden", -- Garden:Skip (todo lo plantado, listo)
	Merge = "merge", -- Merge:Skip (la fusión en curso, lista)
	Stages = "stages", -- Stages:Revive (una vida más en la corrida)
} :: { [string]: string }

-- Bloques que solo funcionan con otros.
local NEEDS: { [string]: { string } } = {
	belt = { "units" },
	steal = { "units", "plots" },
	rolls = { "units" },
	merge = { "units" },
	sell = { "units" },
	equip = { "units" },
	fishing = { "units" },
	garden = { "units", "plots" },
	search = { "units" },
	wild = { "units" },
	tycoon = { "plots" },
}

-- Campos de la receta que son bloques, en el orden en que arrancan.
KitCheck.BLOCKS = {
	"upgrades",
	"units",
	"items",
	"stats",
	"zones",
	"plots",
	"equip",
	"sell",
	"merge",
	"rolls",
	"belt",
	"steal",
	"fishing",
	"garden",
	"search",
	"wild",
	"stages",
	"tycoon",
}

type Ctx = {
	errors: { string },
	recipe: Types.KitConfig,
	known: Known,
	currencies: { [string]: boolean },
	rarity: { [string]: number },
	mutations: { [string]: boolean },
	sizes: { [string]: boolean },
	boosts: { [string]: boolean },
	passes: { [string]: boolean }?,
	products: { [string]: boolean }?,
	units: { [string]: Types.UnitDef },
	zones: { [string]: boolean },
	stats: { [string]: boolean },
}

local function set(list: { string }?): { [string]: boolean }
	local out: { [string]: boolean } = {}
	for _, value in list or ({} :: { string }) do
		out[value] = true
	end
	return out
end

local function add(ctx: Ctx, path: string, message: string)
	table.insert(ctx.errors, path .. ": " .. message)
end

-- Los ids se guardan en los datos y viajan en premios ("Unit:Dragon:Gold") y claves del índice
-- ("Dragon|Gold"): letras, números y guion bajo.
local function id(ctx: Ctx, path: string, value: string?)
	if typeof(value) ~= "string" or value == "" then
		add(ctx, path, "falta el id")
	elseif not string.match(value, "^[%w_]+$") then
		add(ctx, path, "id '" .. value .. "' con caracteres no permitidos (solo letras, números y _)")
	end
end

local function text(ctx: Ctx, path: string, value: string?)
	if typeof(value) ~= "string" or value == "" then
		add(ctx, path, "falta el texto")
	end
end

local function number(ctx: Ctx, path: string, value: number?, min: number, integer: boolean?)
	if typeof(value) ~= "number" or value ~= value or value == math.huge then
		add(ctx, path, "falta un número válido")
	elseif value < min then
		add(ctx, path, "tiene que ser al menos " .. min)
	elseif integer and value % 1 ~= 0 then
		add(ctx, path, "tiene que ser entero")
	end
end

local function optionalNumber(ctx: Ctx, path: string, value: number?, min: number, integer: boolean?)
	if value ~= nil then
		number(ctx, path, value, min, integer)
	end
end

local function unique<T>(ctx: Ctx, path: string, list: { T }, key: (T) -> string?): { [string]: T }
	local seen: { [string]: T } = {}
	for i, entry in list do
		local k = key(entry)
		if k ~= nil then
			if seen[k] ~= nil then
				add(ctx, path .. "[" .. i .. "]", "id repetido '" .. k .. "'")
			end
			seen[k] = entry
		end
	end
	return seen
end

local function currency(ctx: Ctx, path: string, value: string?)
	if value ~= nil and not ctx.currencies[value] then
		add(ctx, path, "moneda '" .. value .. "' no existe (EconomyConfig.CURRENCIES o currencies de la receta)")
	end
end

local function price(ctx: Ctx, path: string, value: Types.Price?)
	if value == nil then
		return
	end
	if typeof(value.currency) ~= "string" then
		add(ctx, path .. ".currency", "falta la moneda")
	else
		currency(ctx, path .. ".currency", value.currency)
	end
	number(ctx, path .. ".amount", value.amount, 0)
end

local function rarity(ctx: Ctx, path: string, value: string?)
	if value ~= nil and ctx.rarity[value] == nil then
		add(ctx, path, "rareza '" .. value .. "' no existe (RarityConfig.TIERS)")
	end
end

local function pass(ctx: Ctx, path: string, value: string?)
	local passes = ctx.passes
	if value ~= nil and passes and not passes[value] then
		add(ctx, path, "pase '" .. value .. "' no existe (ShopConfig.PASSES)")
	end
end

local function product(ctx: Ctx, path: string, value: string?)
	local products = ctx.products
	if value ~= nil and products and not products[value] then
		add(ctx, path, "producto '" .. value .. "' no existe (ShopConfig.PRODUCTS)")
	end
end

local function zoneRef(ctx: Ctx, path: string, value: string?)
	if value == nil then
		return
	end
	if ctx.recipe.zones == nil then
		add(ctx, path, "usa la zona '" .. value .. "' pero la receta no tiene el bloque zones")
	elseif not ctx.zones[value] then
		add(ctx, path, "zona '" .. value .. "' no existe en zones.list")
	end
end

local function statRef(ctx: Ctx, path: string, value: string?)
	if value == nil then
		return
	end
	if ctx.recipe.stats == nil then
		add(ctx, path, "usa la estadística '" .. value .. "' pero la receta no tiene el bloque stats")
	elseif not ctx.stats[value] then
		add(ctx, path, "estadística '" .. value .. "' no existe en stats")
	end
end

local function pool(ctx: Ctx, path: string, entries: { Types.PoolEntry }?)
	if entries == nil or #entries == 0 then
		add(ctx, path, "no tiene resultados")
		return
	end
	local total = 0
	for i, entry in entries do
		local where = path .. "[" .. i .. "]"
		if ctx.units[entry.unit] == nil then
			add(ctx, where, "unidad '" .. tostring(entry.unit) .. "' no existe en units.list")
		end
		number(ctx, where .. ".weight", entry.weight, 0)
		if typeof(entry.weight) == "number" then
			total += entry.weight
		end
	end
	if total <= 0 then
		add(ctx, path, "los pesos suman 0")
	end
end

-- Un premio por ítem ("Unit:Dragon:Gold"). nil si está bien; si no, el problema.
function KitCheck.item(recipe: Types.KitConfig, known: Known, item: string): string?
	local prefix, rest = string.match(item, "^(%a+):(.+)$")
	if not prefix or not rest then
		return "'" .. item .. "' no tiene la forma Bloque:valor"
	end
	local block = KitCheck.ITEMS[prefix]
	if not block then
		return "'" .. item .. "': prefijo '" .. prefix .. "' desconocido"
	end
	local r = recipe :: any
	if r[block] == nil then
		return "'" .. item .. "' necesita el bloque " .. block
	end
	local function has(list: { any }?, value: string): boolean
		for _, entry in list or ({} :: { any }) do
			if entry.id == value then
				return true
			end
		end
		return false
	end
	if prefix == "Unit" then
		local parts = string.split(rest, ":")
		local units = recipe.units
		if not units or not has(units.list, parts[1]) then
			return "'" .. item .. "': la unidad '" .. parts[1] .. "' no existe"
		end
		if parts[2] and not table.find(known.mutations, parts[2]) then
			return "'" .. item .. "': mutación '" .. parts[2] .. "' no existe"
		end
		if parts[3] and not table.find(known.sizes, parts[3]) then
			return "'" .. item .. "': tamaño '" .. parts[3] .. "' no existe"
		end
		if #parts > 3 then
			return "'" .. item .. "': sobran partes"
		end
		return nil
	end
	local lists: { [string]: { any }? } = {
		Roll = if recipe.rolls then recipe.rolls.list else nil,
		Item = if recipe.items then recipe.items.list else nil,
		Upgrade = recipe.upgrades,
		Zone = if recipe.zones then recipe.zones.list else nil,
		Stat = recipe.stats,
		Rod = if recipe.fishing then recipe.fishing.rods else nil,
		Tool = if recipe.search then recipe.search.tools else nil,
		Seed = if recipe.garden then recipe.garden.seeds else nil,
	}
	if lists[prefix] ~= nil then
		if not has(lists[prefix], rest) then
			return "'" .. item .. "': '" .. rest .. "' no existe en " .. block
		end
		return nil
	end
	local fixed = if prefix == "Stages" then "Revive" else "Skip"
	if rest ~= fixed then
		return "'" .. item .. "': solo existe " .. prefix .. ":" .. fixed
	end
	return nil
end

local function reward(ctx: Ctx, path: string, value: Types.Reward?)
	if value == nil then
		return
	end
	currency(ctx, path .. ".currency", value.currency)
	if value.boost ~= nil and not ctx.boosts[value.boost] then
		add(ctx, path .. ".boost", "impulso '" .. value.boost .. "' no existe (BoostConfig.TIMED)")
	end
	if value.boost ~= nil or value.serverBoost ~= nil then
		number(ctx, path .. ".seconds", value.seconds, 1)
	end
	if value.item ~= nil then
		local problem = KitCheck.item(ctx.recipe, ctx.known, value.item)
		if problem then
			add(ctx, path .. ".item", problem)
		end
	end
	optionalNumber(ctx, path .. ".count", value.count, 1, true)
	optionalNumber(ctx, path .. ".amount", value.amount, 0)
	optionalNumber(ctx, path .. ".incomeMinutes", value.incomeMinutes, 0)
	optionalNumber(ctx, path .. ".spins", value.spins, 0, true)
end

local function checkCurrencies(ctx: Ctx)
	local list = ctx.recipe.currencies
	if not list then
		return
	end
	unique(ctx, "currencies", list, function(c)
		return c.id
	end)
	for i, c in list do
		local path = "currencies[" .. i .. "]"
		id(ctx, path .. ".id", c.id)
		if table.find(ctx.known.currencies, c.id) then
			add(ctx, path .. ".id", "'" .. c.id .. "' ya es una moneda del núcleo")
		end
		if typeof(c.color) ~= "string" or not (string.match(c.color, "^#?%x%x%x%x%x%x$") or string.match(c.color, "^#?%x%x%x$")) then
			add(ctx, path .. ".color", "color en hex (\"#FFD23A\")")
		end
		text(ctx, path .. ".icon", c.icon)
		number(ctx, path .. ".start", c.start, 0)
	end
end

local function checkUnits(ctx: Ctx)
	local units = ctx.recipe.units
	if not units then
		return
	end
	text(ctx, "units.label", units.label)
	number(ctx, "units.maxInventory", units.maxInventory, 1, true)
	rarity(ctx, "units.announceFrom", units.announceFrom)
	rarity(ctx, "units.luckyFrom", units.luckyFrom)
	if #units.list == 0 then
		add(ctx, "units.list", "no tiene unidades")
	end
	unique(ctx, "units.list", units.list, function(u)
		return u.id
	end)
	local indexZones: { [string]: boolean }? = nil
	if units.zones then
		local ids: { [string]: boolean } = {}
		for _, z in units.zones do
			ids[z.id] = true
		end
		indexZones = ids
	end
	local used: { [string]: boolean } = {}
	for i, u in units.list do
		local path = "units.list[" .. i .. "]"
		id(ctx, path .. ".id", u.id)
		text(ctx, path .. ".name", u.name)
		if ctx.rarity[u.rarity] == nil then
			add(ctx, path .. ".rarity", "rareza '" .. tostring(u.rarity) .. "' no existe (RarityConfig.TIERS)")
		end
		optionalNumber(ctx, path .. ".income", u.income, 0)
		optionalNumber(ctx, path .. ".value", u.value, 0)
		optionalNumber(ctx, path .. ".power", u.power, 0)
		optionalNumber(ctx, path .. ".tier", u.tier, 1, true)
		optionalNumber(ctx, path .. ".requirement", u.requirement, 0)
		optionalNumber(ctx, path .. ".price", u.price, 0)
		local weight = u.weight
		if weight then
			number(ctx, path .. ".weight.min", weight.min, 0)
			number(ctx, path .. ".weight.max", weight.max, 0)
			if typeof(weight.min) == "number" and typeof(weight.max) == "number" and weight.min > weight.max then
				add(ctx, path .. ".weight", "min mayor que max")
			end
		end
		if u.color ~= nil and not (string.match(u.color, "^#?%x%x%x%x%x%x$") or string.match(u.color, "^#?%x%x%x$")) then
			add(ctx, path .. ".color", "color en hex (\"#FFD23A\")")
		end
		if indexZones and u.zone ~= nil then
			if not indexZones[u.zone] then
				add(ctx, path .. ".zone", "zona '" .. u.zone .. "' no existe en units.zones")
			end
			used[u.zone] = true
		end
	end
	for i, zone in units.zones or ({} :: { Types.IndexZone }) do
		local path = "units.zones[" .. i .. "]"
		id(ctx, path .. ".id", zone.id)
		text(ctx, path .. ".name", zone.name)
		if not used[zone.id] then
			add(ctx, path, "la zona '" .. zone.id .. "' no tiene unidades (unit.zone)")
		end
		reward(ctx, path .. ".reward", zone.reward)
	end
	if units.zones then
		unique(ctx, "units.zones", units.zones, function(z)
			return z.id
		end)
	end
end

local function checkPlots(ctx: Ctx)
	local plots = ctx.recipe.plots
	if not plots then
		return
	end
	number(ctx, "plots.count", plots.count, 1, true)
	number(ctx, "plots.slots", plots.slots, 0, true)
	number(ctx, "plots.maxSlots", plots.maxSlots, 0, true)
	if typeof(plots.slots) == "number" and typeof(plots.maxSlots) == "number" then
		if plots.slots > plots.maxSlots then
			add(ctx, "plots.slots", "más espacios al empezar que maxSlots")
		end
		if plots.slots > 0 and ctx.recipe.units == nil then
			add(ctx, "plots", "espacios para unidades sin el bloque units")
		end
		local prices = plots.slotPrices
		if prices and #prices < plots.maxSlots - plots.slots then
			add(ctx, "plots.slotPrices", "faltan precios: hay " .. #prices .. " y se compran " .. (plots.maxSlots - plots.slots))
		end
	end
	for i, value in plots.slotPrices or ({} :: { number }) do
		number(ctx, "plots.slotPrices[" .. i .. "]", value, 0)
	end
	if plots.collect ~= "pad" and plots.collect ~= "auto" then
		add(ctx, "plots.collect", "tiene que ser \"pad\" o \"auto\"")
	end
	pass(ctx, "plots.autoCollectPass", plots.autoCollectPass)
	pass(ctx, "plots.slotPass", plots.slotPass)
	if plots.slotPass ~= nil then
		number(ctx, "plots.passSlots", plots.passSlots, 1, true)
	end
	local lock = plots.lock
	if lock then
		number(ctx, "plots.lock.seconds", lock.seconds, 1)
		number(ctx, "plots.lock.cooldown", lock.cooldown, 0)
	end
end

local function checkBelt(ctx: Ctx)
	local belt = ctx.recipe.belt
	if not belt then
		return
	end
	pool(ctx, "belt.pool", belt.pool)
	number(ctx, "belt.spawnEvery", belt.spawnEvery, 0.1)
	number(ctx, "belt.walkSeconds", belt.walkSeconds, 1)
	optionalNumber(ctx, "belt.priceMultiplier", belt.priceMultiplier, 0)
	optionalNumber(ctx, "belt.maxOnBelt", belt.maxOnBelt, 1, true)
	for i, entry in belt.pool do
		local unit = ctx.units[entry.unit]
		if unit and unit.price == nil and unit.value == nil then
			add(ctx, "belt.pool[" .. i .. "]", "la unidad '" .. entry.unit .. "' no tiene price ni value: no se puede vender en la cinta")
		end
	end
end

local function checkSteal(ctx: Ctx)
	local steal = ctx.recipe.steal
	if not steal then
		return
	end
	number(ctx, "steal.holdSeconds", steal.holdSeconds, 0)
	number(ctx, "steal.carrySpeed", steal.carrySpeed, 0.1)
	number(ctx, "steal.protectNewSeconds", steal.protectNewSeconds, 0)
	number(ctx, "steal.recentSeconds", steal.recentSeconds, 0)
	number(ctx, "steal.pushRange", steal.pushRange, 0)
end

local function checkRolls(ctx: Ctx)
	local rolls = ctx.recipe.rolls
	if not rolls then
		return
	end
	pass(ctx, "rolls.autoPass", rolls.autoPass)
	if #rolls.list == 0 then
		add(ctx, "rolls.list", "no tiene tiradas")
	end
	unique(ctx, "rolls.list", rolls.list, function(r)
		return r.id
	end)
	for i, roll in rolls.list do
		local path = "rolls.list[" .. i .. "]"
		id(ctx, path .. ".id", roll.id)
		text(ctx, path .. ".name", roll.name)
		price(ctx, path .. ".price", roll.price)
		if roll.price == nil then
			number(ctx, path .. ".cooldown", roll.cooldown, 1)
		end
		pool(ctx, path .. ".pool", roll.pool)
		zoneRef(ctx, path .. ".zone", roll.zone)
		if #roll.amounts == 0 then
			add(ctx, path .. ".amounts", "sin cantidades ({ count = 1 })")
		end
		for j, amount in roll.amounts do
			number(ctx, path .. ".amounts[" .. j .. "].count", amount.count, 1, true)
			pass(ctx, path .. ".amounts[" .. j .. "].pass", amount.pass)
		end
		local p = roll.price
		if p and ctx.recipe.currencies then
			for _, c in ctx.recipe.currencies do
				if c.id == p.currency and c.purchasable and not roll.paidRandom then
					add(ctx, path .. ".paidRandom", "se paga con '" .. c.id .. "', que se compra con Robux: marcarla paidRandom")
				end
			end
		end
	end
end

local function checkMerge(ctx: Ctx)
	local merge = ctx.recipe.merge
	local units = ctx.recipe.units
	if not merge or not units then
		return
	end
	number(ctx, "merge.count", merge.count, 2, true)
	optionalNumber(ctx, "merge.mutationChance", merge.mutationChance, 0)
	optionalNumber(ctx, "merge.seconds", merge.seconds, 0)
	if merge.mode == "tier" then
		local tiers: { [number]: string } = {}
		local count = 0
		for _, u in units.list do
			local tier = u.tier
			if tier then
				if tiers[tier] then
					add(ctx, "units.list", "nivel " .. tier .. " repetido ('" .. tiers[tier] .. "' y '" .. u.id .. "')")
				end
				tiers[tier] = u.id
				count += 1
			end
		end
		if count < 2 then
			add(ctx, "merge", "modo tier necesita al menos 2 unidades con tier")
		end
		for t = 1, count do
			if tiers[t] == nil then
				add(ctx, "units.list", "falta una unidad de nivel " .. t .. " (los niveles van de 1 en 1)")
				break
			end
		end
	elseif merge.mode == "variant" then
		local chain = merge.variantChain
		if not units.mutations then
			add(ctx, "merge", "modo variant necesita units.mutations = true")
		end
		if not chain or #chain < 2 then
			add(ctx, "merge.variantChain", "al menos dos variantes (\"Normal\" → \"Gold\")")
		else
			for i, variant in chain do
				if not ctx.mutations[variant] then
					add(ctx, "merge.variantChain[" .. i .. "]", "mutación '" .. variant .. "' no existe")
				end
			end
		end
	else
		add(ctx, "merge.mode", "tiene que ser \"tier\" o \"variant\"")
	end
end

local function checkSell(ctx: Ctx)
	local sell = ctx.recipe.sell
	if not sell then
		return
	end
	currency(ctx, "sell.currency", sell.currency)
	optionalNumber(ctx, "sell.multiplier", sell.multiplier, 0)
	rarity(ctx, "sell.keepFrom", sell.keepFrom)
	local units = ctx.recipe.units
	if units then
		local any = false
		for _, u in units.list do
			if u.value ~= nil then
				any = true
			end
		end
		if not any then
			add(ctx, "sell", "ninguna unidad tiene value: no hay nada para vender")
		end
	end
end

local function checkEquip(ctx: Ctx)
	local equip = ctx.recipe.equip
	if not equip then
		return
	end
	number(ctx, "equip.slots", equip.slots, 1, true)
	number(ctx, "equip.maxSlots", equip.maxSlots, 1, true)
	if typeof(equip.slots) == "number" and typeof(equip.maxSlots) == "number" and equip.slots > equip.maxSlots then
		add(ctx, "equip.slots", "más espacios al empezar que maxSlots")
	end
	text(ctx, "equip.stat", equip.stat)
	pass(ctx, "equip.slotPass", equip.slotPass)
	optionalNumber(ctx, "equip.passSlots", equip.passSlots, 1, true)
end

local function checkStats(ctx: Ctx)
	local stats = ctx.recipe.stats
	if not stats then
		return
	end
	unique(ctx, "stats", stats, function(s)
		return s.id
	end)
	for i, s in stats do
		local path = "stats[" .. i .. "]"
		id(ctx, path .. ".id", s.id)
		if ctx.currencies[s.id] then
			add(ctx, path .. ".id", "'" .. s.id .. "' choca con una moneda (las dos son atributos del jugador)")
		end
		text(ctx, path .. ".label", s.label)
		currency(ctx, path .. ".currency", s.currency)
		optionalNumber(ctx, path .. ".perStep", s.perStep, 0)
		optionalNumber(ctx, path .. ".perSecond", s.perSecond, 0)
		optionalNumber(ctx, path .. ".perClick", s.perClick, 0)
		optionalNumber(ctx, path .. ".clickRate", s.clickRate, 1)
		pass(ctx, path .. ".autoPass", s.autoPass)
		local walk = s.walkSpeed
		if walk then
			number(ctx, path .. ".walkSpeed.base", walk.base, 1)
			number(ctx, path .. ".walkSpeed.per", walk.per, 0)
			number(ctx, path .. ".walkSpeed.max", walk.max, walk.base or 1)
		end
		if s.perClick ~= nil and s.clickRate == nil then
			add(ctx, path .. ".clickRate", "con perClick hace falta un tope de toques por segundo")
		end
	end
end

local function checkZones(ctx: Ctx)
	local zones = ctx.recipe.zones
	if not zones then
		return
	end
	if #zones.list == 0 then
		add(ctx, "zones.list", "no tiene zonas")
		return
	end
	unique(ctx, "zones.list", zones.list, function(z)
		return z.id
	end)
	unique(ctx, "zones.list (order)", zones.list, function(z)
		return tostring(z.order)
	end)
	local first: Types.ZoneDef? = nil
	for i, z in zones.list do
		local path = "zones.list[" .. i .. "]"
		id(ctx, path .. ".id", z.id)
		text(ctx, path .. ".name", z.name)
		number(ctx, path .. ".order", z.order, 1, true)
		price(ctx, path .. ".price", z.price)
		local stat = z.stat
		if stat then
			statRef(ctx, path .. ".stat.id", stat.id)
			number(ctx, path .. ".stat.value", stat.value, 0)
		end
		optionalNumber(ctx, path .. ".rebirths", z.rebirths, 0, true)
		if first == nil or (typeof(z.order) == "number" and z.order < first.order) then
			first = z
		end
	end
	if first and (first.price ~= nil or first.stat ~= nil or first.rebirths ~= nil) then
		add(ctx, "zones.list", "la primera zona ('" .. first.id .. "') tiene que estar abierta: es donde se aparece")
	end
end

local function checkStages(ctx: Ctx)
	local stages = ctx.recipe.stages
	if not stages then
		return
	end
	number(ctx, "stages.count", stages.count, 1, true)
	price(ctx, "stages.reward", stages.reward)
	statRef(ctx, "stages.stat", stages.stat)
	local requirements = stages.requirements
	if requirements then
		if stages.stat == nil then
			add(ctx, "stages.requirements", "con requisitos hace falta stages.stat")
		end
		if #requirements ~= stages.count then
			add(ctx, "stages.requirements", "tiene " .. #requirements .. " valores y hay " .. tostring(stages.count) .. " etapas")
		end
	end
	local run = stages.run
	if run then
		number(ctx, "stages.run.freeRevives", run.freeRevives, 0, true)
		product(ctx, "stages.run.reviveProduct", run.reviveProduct)
	end
end

local function checkFishing(ctx: Ctx)
	local fishing = ctx.recipe.fishing
	if not fishing then
		return
	end
	if #fishing.pools == 0 then
		add(ctx, "fishing.pools", "no tiene aguas")
	end
	unique(ctx, "fishing.pools", fishing.pools, function(p)
		return p.id
	end)
	for i, p in fishing.pools do
		local path = "fishing.pools[" .. i .. "]"
		id(ctx, path .. ".id", p.id)
		zoneRef(ctx, path .. ".zone", p.zone)
		pool(ctx, path .. ".entries", p.entries)
	end
	number(ctx, "fishing.wait.min", fishing.wait.min, 0)
	number(ctx, "fishing.wait.max", fishing.wait.max, 0)
	if fishing.wait.min > fishing.wait.max then
		add(ctx, "fishing.wait", "min mayor que max")
	end
	number(ctx, "fishing.reelSeconds", fishing.reelSeconds, 0.5)
	optionalNumber(ctx, "fishing.castRange", fishing.castRange, 1)
	if #fishing.rods == 0 then
		add(ctx, "fishing.rods", "hace falta la caña inicial")
	end
	unique(ctx, "fishing.rods", fishing.rods, function(r)
		return r.id
	end)
	for i, rod in fishing.rods do
		local path = "fishing.rods[" .. i .. "]"
		id(ctx, path .. ".id", rod.id)
		text(ctx, path .. ".name", rod.name)
		number(ctx, path .. ".luck", rod.luck, 1)
		number(ctx, path .. ".speed", rod.speed, 0.1)
		price(ctx, path .. ".price", rod.price)
	end
	local first = fishing.rods[1]
	if first and first.price ~= nil then
		add(ctx, "fishing.rods[1]", "la primera caña es la inicial: sin precio")
	end
	local units = ctx.recipe.units
	if units then
		for _, p in fishing.pools do
			for _, entry in p.entries do
				local unit = ctx.units[entry.unit]
				if unit and unit.weight == nil then
					add(ctx, "units.list", "'" .. unit.id .. "' sale pescando y no tiene weight (kilos)")
				end
			end
		end
	end
end

local function checkGarden(ctx: Ctx)
	local garden = ctx.recipe.garden
	if not garden then
		return
	end
	if #garden.seeds == 0 then
		add(ctx, "garden.seeds", "no tiene semillas")
	end
	unique(ctx, "garden.seeds", garden.seeds, function(s)
		return s.id
	end)
	for i, seed in garden.seeds do
		local path = "garden.seeds[" .. i .. "]"
		id(ctx, path .. ".id", seed.id)
		text(ctx, path .. ".name", seed.name)
		if ctx.units[seed.unit] == nil then
			add(ctx, path .. ".unit", "unidad '" .. tostring(seed.unit) .. "' no existe en units.list")
		end
		price(ctx, path .. ".price", seed.price)
		number(ctx, path .. ".grow", seed.grow, 1)
		number(ctx, path .. ".stock.min", seed.stock.min, 0, true)
		number(ctx, path .. ".stock.max", seed.stock.max, 0, true)
		if seed.stock.min > seed.stock.max then
			add(ctx, path .. ".stock", "min mayor que max")
		end
		optionalNumber(ctx, path .. ".chance", seed.chance, 0)
	end
	number(ctx, "garden.restock", garden.restock, 10)
	number(ctx, "garden.tiles", garden.tiles, 1, true)
	number(ctx, "garden.maxTiles", garden.maxTiles, 1, true)
	if garden.tiles > garden.maxTiles then
		add(ctx, "garden.tiles", "más parcelas al empezar que maxTiles")
	end
	local prices = garden.tilePrices
	if prices and #prices < garden.maxTiles - garden.tiles then
		add(ctx, "garden.tilePrices", "faltan precios: hay " .. #prices .. " y se compran " .. (garden.maxTiles - garden.tiles))
	end
	optionalNumber(ctx, "garden.mutationChance", garden.mutationChance, 0)
end

local function checkSearch(ctx: Ctx)
	local search = ctx.recipe.search
	if not search then
		return
	end
	if #search.piles == 0 then
		add(ctx, "search.piles", "no tiene pilas")
	end
	unique(ctx, "search.piles", search.piles, function(p)
		return p.id
	end)
	for i, pile in search.piles do
		local path = "search.piles[" .. i .. "]"
		id(ctx, path .. ".id", pile.id)
		zoneRef(ctx, path .. ".zone", pile.zone)
		pool(ctx, path .. ".entries", pile.entries)
		number(ctx, path .. ".findChance", pile.findChance, 0)
		price(ctx, path .. ".coins", pile.coins)
	end
	if #search.tools == 0 then
		add(ctx, "search.tools", "hace falta la herramienta inicial")
	end
	unique(ctx, "search.tools", search.tools, function(t)
		return t.id
	end)
	for i, tool in search.tools do
		local path = "search.tools[" .. i .. "]"
		id(ctx, path .. ".id", tool.id)
		text(ctx, path .. ".name", tool.name)
		number(ctx, path .. ".power", tool.power, 1)
		number(ctx, path .. ".cooldown", tool.cooldown, 0.05)
		price(ctx, path .. ".price", tool.price)
	end
	local first = search.tools[1]
	if first and first.price ~= nil then
		add(ctx, "search.tools[1]", "la primera herramienta es la inicial: sin precio")
	end
	number(ctx, "search.bag", search.bag, 1, true)
	currency(ctx, "search.depositCurrency", search.depositCurrency)
end

local function checkWild(ctx: Ctx)
	local wild = ctx.recipe.wild
	if not wild then
		return
	end
	if #wild.spawns == 0 then
		add(ctx, "wild.spawns", "no tiene lugares de aparición")
	end
	for i, spawn in wild.spawns do
		local path = "wild.spawns[" .. i .. "]"
		zoneRef(ctx, path .. ".zone", spawn.zone)
		pool(ctx, path .. ".entries", spawn.entries)
		number(ctx, path .. ".max", spawn.max, 1, true)
		number(ctx, path .. ".respawn", spawn.respawn, 1)
	end
	statRef(ctx, "wild.stat", wild.stat)
	number(ctx, "wild.captureSeconds", wild.captureSeconds, 0)
end

local function checkUpgrades(ctx: Ctx)
	local upgrades = ctx.recipe.upgrades
	if not upgrades then
		return
	end
	unique(ctx, "upgrades", upgrades, function(u)
		return u.id
	end)
	local r = ctx.recipe :: any
	for i, u in upgrades do
		local path = "upgrades[" .. i .. "]"
		id(ctx, path .. ".id", u.id)
		text(ctx, path .. ".name", u.name)
		text(ctx, path .. ".desc", u.desc)
		local stat = if typeof(u.effect) == "string" then string.match(u.effect, "^stat:([%w_]+)$") else nil
		if stat == nil then
			local block = KitCheck.EFFECTS[u.effect]
			if block == nil then
				add(ctx, path .. ".effect", "efecto '" .. tostring(u.effect) .. "' no existe (stat:<Stat> o KitCheck.EFFECTS)")
			elseif r[block] == nil then
				add(ctx, path .. ".effect", "'" .. u.effect .. "' necesita el bloque " .. block)
			end
		end
		number(ctx, path .. ".per", u.per, 0)
		if u.kind ~= nil and u.kind ~= "add" and u.kind ~= "mult" then
			add(ctx, path .. ".kind", "tiene que ser \"add\" o \"mult\"")
		end
		number(ctx, path .. ".maxLevel", u.maxLevel, 1, true)
		currency(ctx, path .. ".currency", u.currency)
		local prices = u.prices
		if prices then
			if #prices ~= u.maxLevel then
				add(ctx, path .. ".prices", "tiene " .. #prices .. " precios y " .. tostring(u.maxLevel) .. " niveles")
			end
			for j, value in prices do
				number(ctx, path .. ".prices[" .. j .. "]", value, 0)
			end
		elseif not u.robux then
			number(ctx, path .. ".base", u.base, 0)
			number(ctx, path .. ".growth", u.growth, 1)
		end
	end
end

local function checkTycoon(ctx: Ctx)
	local tycoon = ctx.recipe.tycoon
	if not tycoon then
		return
	end
	if #tycoon.buildings == 0 then
		add(ctx, "tycoon.buildings", "no tiene edificios")
	end
	unique(ctx, "tycoon.buildings", tycoon.buildings, function(b)
		return b.id
	end)
	local before: { [string]: boolean } = {}
	for i, b in tycoon.buildings do
		local path = "tycoon.buildings[" .. i .. "]"
		id(ctx, path .. ".id", b.id)
		text(ctx, path .. ".name", b.name)
		price(ctx, path .. ".price", b.price)
		number(ctx, path .. ".income", b.income, 0)
		if b.after ~= nil and not before[b.after] then
			add(ctx, path .. ".after", "'" .. b.after .. "' tiene que estar antes en la lista")
		end
		before[b.id] = true
	end
end

local function checkItems(ctx: Ctx)
	local items = ctx.recipe.items
	if not items then
		return
	end
	number(ctx, "items.maxStack", items.maxStack, 1, true)
	unique(ctx, "items.list", items.list, function(item)
		return item.id
	end)
	for i, item in items.list do
		local path = "items.list[" .. i .. "]"
		id(ctx, path .. ".id", item.id)
		text(ctx, path .. ".name", item.name)
		text(ctx, path .. ".icon", item.icon)
		if not ctx.boosts[item.boost] then
			add(ctx, path .. ".boost", "impulso '" .. tostring(item.boost) .. "' no existe (BoostConfig.TIMED)")
		end
		number(ctx, path .. ".seconds", item.seconds, 1)
	end
end

local function checkRetention(ctx: Ctx)
	local objectives = ctx.recipe.objectives
	if objectives then
		unique(ctx, "objectives", objectives, function(o)
			return o.id
		end)
		for i, o in objectives do
			local path = "objectives[" .. i .. "]"
			id(ctx, path .. ".id", o.id)
			text(ctx, path .. ".text", o.text)
			text(ctx, path .. ".stat", o.stat)
			number(ctx, path .. ".target", o.target, 1)
		end
	end
	local quests = ctx.recipe.quests
	if quests then
		if #quests < 3 then
			add(ctx, "quests", "hacen falta al menos 3 misiones (se eligen 3 por día)")
		end
		unique(ctx, "quests", quests, function(q)
			return q.id
		end)
		for i, q in quests do
			local path = "quests[" .. i .. "]"
			id(ctx, path .. ".id", q.id)
			text(ctx, path .. ".text", q.text)
			text(ctx, path .. ".stat", q.stat)
			number(ctx, path .. ".target", q.target, 1)
			reward(ctx, path .. ".reward", q.reward)
		end
	end
	for i, name in ctx.recipe.leaderstats or ({} :: { string }) do
		if not ctx.currencies[name] and name ~= "Rebirths" and not ctx.stats[name] then
			add(ctx, "leaderstats[" .. i .. "]", "'" .. name .. "' no es una moneda, \"Rebirths\" ni una estadística")
		end
	end
	local map = ctx.recipe.map
	if map and not table.find(KitCheck.THEMES, map.theme) then
		add(ctx, "map.theme", "tema '" .. tostring(map.theme) .. "' no existe (" .. table.concat(KitCheck.THEMES, ", ") .. ")")
	end
end

-- Revisa la receta entera. Lista vacía = sana.
function KitCheck.check(recipe: Types.KitConfig, known: Known): { string }
	local currencies = set(known.currencies)
	for _, c in recipe.currencies or ({} :: { Types.CurrencyDef }) do
		currencies[c.id] = true
	end
	local rarityRank: { [string]: number } = {}
	for i, r in known.rarities do
		rarityRank[r] = i
	end
	local ctx: Ctx = {
		errors = {},
		recipe = recipe,
		known = known,
		currencies = currencies,
		rarity = rarityRank,
		mutations = set(known.mutations),
		sizes = set(known.sizes),
		boosts = set(known.boosts),
		passes = if known.passes then set(known.passes) else nil,
		products = if known.products then set(known.products) else nil,
		units = {},
		zones = {},
		stats = {},
	}
	text(ctx, "name", recipe.name)
	local r = recipe :: any
	for block, needs in NEEDS do
		if r[block] ~= nil then
			for _, other in needs do
				if r[other] == nil then
					add(ctx, block, "necesita el bloque " .. other)
				end
			end
		end
	end
	if recipe.units then
		for _, u in recipe.units.list do
			if typeof(u.id) == "string" then
				ctx.units[u.id] = u
			end
		end
	end
	if recipe.zones then
		for _, z in recipe.zones.list do
			ctx.zones[z.id] = true
		end
	end
	for _, s in recipe.stats or ({} :: { Types.StatDef }) do
		ctx.stats[s.id] = true
	end
	checkCurrencies(ctx)
	checkUnits(ctx)
	checkPlots(ctx)
	checkBelt(ctx)
	checkSteal(ctx)
	checkRolls(ctx)
	checkMerge(ctx)
	checkSell(ctx)
	checkEquip(ctx)
	checkStats(ctx)
	checkZones(ctx)
	checkStages(ctx)
	checkFishing(ctx)
	checkGarden(ctx)
	checkSearch(ctx)
	checkWild(ctx)
	checkUpgrades(ctx)
	checkTycoon(ctx)
	checkItems(ctx)
	checkRetention(ctx)
	return ctx.errors
end

-- Bloques que usa la receta, en el orden en que arrancan ("units", "plots"...).
function KitCheck.blocks(recipe: Types.KitConfig): { string }
	local out = {}
	local r = recipe :: any
	for _, block in KitCheck.BLOCKS do
		if r[block] ~= nil then
			table.insert(out, block)
		end
	end
	return out
end

return KitCheck
