--!strict
-- Plan del mapa (Lib/MapPlan): cada bloque encuentra sus partes con las etiquetas y atributos que
-- espera, nada choca, lo que se usa está sobre un piso y el mismo nombre da el mismo mapa.
local TestKit = require("./TestKit")
local MapPlan = require("../src/shared/Lib/MapPlan")
local Types = require("../src/shared/Kits/Types")

local equal = TestKit.equal
local truthy = TestKit.truthy

local EMPTY_POOL: { Types.PoolEntry } = {}

-- Todo prendido: bases con traba, cinta, cultivo y tycoon; cuatro zonas con tiradas, pesca, pilas,
-- salvajes y cintas de correr; etapas, venta, mejoras, fusión y todo lo del lobby.
local function full(): Types.KitConfig
	return {
		name = "FullTest",
		leaderstats = { "Money", "Rebirths" },
		plots = { count = 8, slots = 4, maxSlots = 12, slotPrices = { 100, 500 }, collect = "pad", lock = { seconds = 60, cooldown = 30 } },
		belt = { spawnEvery = 2, walkSeconds = 20, pool = EMPTY_POOL } :: any,
		garden = { seeds = {}, restock = 300, tiles = 4, maxTiles = 8 },
		tycoon = {
			buildings = {
				{ id = "Farm", name = "Farm", price = { currency = "Money", amount = 10 }, income = 1 },
				{ id = "Mill", name = "Mill", price = { currency = "Money", amount = 20 }, income = 2 },
				{ id = "Shop", name = "Shop", price = { currency = "Money", amount = 30 }, income = 3 },
				{ id = "Bank", name = "Bank", price = { currency = "Money", amount = 40 }, income = 4 },
				{ id = "Tower", name = "Tower", price = { currency = "Money", amount = 50 }, income = 5 },
				{ id = "Castle", name = "Castle", price = { currency = "Money", amount = 60 }, income = 6 },
			},
		},
		zones = {
			list = {
				{ id = "Meadow", name = "Green Meadow", order = 1 },
				{ id = "Beach", name = "Sunny Beach", order = 2, price = { currency = "Money", amount = 1000 } },
				{ id = "Snow", name = "Snowy Peaks", order = 3, rebirths = 1 },
				{ id = "Volcano", name = "Lava Volcano", order = 4, rebirths = 3 },
			},
		},
		rolls = {
			list = {
				{ id = "Basic", name = "Basic Egg", pool = EMPTY_POOL, amounts = { { count = 1 } } },
				{ id = "Gold", name = "Gold Egg", pool = EMPTY_POOL, amounts = { { count = 1 } }, zone = "Meadow" },
				{ id = "Shell", name = "Shell Egg", pool = EMPTY_POOL, amounts = { { count = 1 } }, zone = "Beach" },
				{ id = "Ice", name = "Ice Egg", pool = EMPTY_POOL, amounts = { { count = 1 } }, zone = "Snow" },
				{ id = "Fire", name = "Fire Egg", pool = EMPTY_POOL, amounts = { { count = 1 } }, zone = "Volcano" },
			},
		},
		fishing = {
			pools = {
				{ id = "Pond", zone = "Meadow", entries = EMPTY_POOL },
				{ id = "Lake", zone = "Meadow", entries = EMPTY_POOL },
				{ id = "Reef", zone = "Beach", entries = EMPTY_POOL },
			},
			wait = { min = 2, max = 5 },
			reelSeconds = 2,
			rods = { { id = "Basic", name = "Basic Rod", power = 1 } :: any, { id = "Pro", name = "Pro Rod", power = 2 } :: any },
		},
		search = {
			piles = {
				{ id = "Sand1", zone = "Beach", entries = EMPTY_POOL, findChance = 0.5 },
				{ id = "Sand2", zone = "Beach", entries = EMPTY_POOL, findChance = 0.5 },
				{ id = "Ash", zone = "Volcano", entries = EMPTY_POOL, findChance = 0.5 },
			},
			tools = { { id = "Shovel", name = "Shovel", power = 1, cooldown = 1 }, { id = "Drill", name = "Drill", power = 3, cooldown = 1 } },
			bag = 10,
		},
		wild = {
			spawns = {
				{ zone = "Meadow", entries = EMPTY_POOL, max = 5, respawn = 10 },
				{ zone = "Snow", entries = EMPTY_POOL, max = 5, respawn = 10 },
			},
			captureSeconds = 3,
		},
		stats = { { id = "Speed", label = "Speed", perStep = 1 } } :: any,
		stages = { count = 12, reward = { currency = "Money", amount = 100 } },
		upgrades = { { id = "Cash", name = "Cash", desc = "+10%", effect = "stat:Money", per = 0.1, maxLevel = 5, base = 100, growth = 2 } } :: { Types.UpgradeDef },
		merge = { mode = "tier", count = 3 },
		sell = { keepFrom = "Legendary" },
		map = {
			theme = "meadow",
			shops = { "Shop", "Sell", "Upgrades", "Seeds", "Rods", "Tools", "Index", "Spin", "Robux" },
			treadmills = { stat = "Speed", gains = { 1, 3, 10, 30 } },
			spin = true,
			leaderboard = true,
			groupChest = true,
			nextUpdate = "Saturday 3PM EST",
		},
	}
end

-- Robar y colocar: bases y cinta, sin zonas.
local function steal(): Types.KitConfig
	return {
		name = "StealTest",
		plots = { count = 8, slots = 10, maxSlots = 10, collect = "pad", lock = { seconds = 60, cooldown = 30 } },
		belt = { spawnEvery = 2, walkSeconds = 20, pool = EMPTY_POOL } :: any,
		steal = {} :: any,
		map = { theme = "candy", leaderboard = true, groupChest = true },
	}
end

-- Obby con zonas por estadística y sin bases.
local function obby(): Types.KitConfig
	return {
		name = "ObbyTest",
		stats = { { id = "Speed", label = "Speed", perStep = 1 } } :: any,
		zones = { list = { { id = "Start", name = "Start", order = 1 }, { id = "Space", name = "Outer Space", order = 2, stat = { id = "Speed", value = 100 } } } },
		stages = { count = 30, reward = { currency = "Money", amount = 100 } },
		map = { theme = "space", treadmills = { stat = "Speed", gains = { 1, 5 } }, nextUpdate = "Friday" },
	}
end

-- Tiradas sin zonas: el área de actividades.
local function eggs(): Types.KitConfig
	return {
		name = "EggsTest",
		rolls = {
			list = {
				{ id = "A", name = "A", pool = EMPTY_POOL, amounts = { { count = 1 } } },
				{ id = "B", name = "B", pool = EMPTY_POOL, amounts = { { count = 1 } } },
				{ id = "C", name = "C", pool = EMPTY_POOL, amounts = { { count = 1 } } },
			},
		},
		map = { theme = "beach", spin = true },
	}
end

local RECIPES: { [string]: () -> Types.KitConfig } = { full = full, steal = steal, obby = obby, eggs = eggs }

-- Ayudas ---------------------------------------------------------------------------------------------

local function groupsByKey(plan: MapPlan.Plan): { [string]: MapPlan.Group }
	local out: { [string]: MapPlan.Group } = {}
	for _, g in plan.groups do
		out[g.key] = g
	end
	return out
end

local function hasTag(tags: { string }?, tag: string): boolean
	return tags ~= nil and table.find(tags, tag) ~= nil
end

-- Partes con una etiqueta y grupos con una etiqueta.
local function tagged(plan: MapPlan.Plan, tag: string): ({ MapPlan.Part }, { MapPlan.Group })
	local parts, groups = {}, {}
	for _, p in plan.parts do
		if hasTag(p.tags, tag) then
			table.insert(parts, p)
		end
	end
	for _, g in plan.groups do
		if hasTag(g.tags, tag) then
			table.insert(groups, g)
		end
	end
	return parts, groups
end

local function count(plan: MapPlan.Plan, tag: string): number
	local parts, groups = tagged(plan, tag)
	return #parts + #groups
end

-- Base (grupo KitPlot) a la que pertenece una parte, o nil.
local function plotOf(plan: MapPlan.Plan, byKey: { [string]: MapPlan.Group }, p: MapPlan.Part): string?
	local key: string? = p.group
	while key do
		local g = byKey[key]
		if not g then
			return nil
		end
		if hasTag(g.tags, "KitPlot") then
			return g.key
		end
		key = g.parent
	end
	return nil
end

local function attrSet(list: { MapPlan.Part } | { MapPlan.Group }, name: string): { [any]: number }
	local out: { [any]: number } = {}
	for _, item in list :: { any } do
		local value = item.attrs and item.attrs[name]
		if value ~= nil then
			out[value] = (out[value] or 0) + 1
		end
	end
	return out
end

local MATERIALS = {
	SmoothPlastic = true, Plastic = true, Neon = true, Wood = true, WoodPlanks = true, Grass = true, Sand = true,
	Glass = true, Ground = true, DiamondPlate = true, Metal = true, ForceField = true, Slate = true,
}

local function finite(n: number): boolean
	return n == n and n ~= math.huge and n ~= -math.huge
end

-- Casos ----------------------------------------------------------------------------------------------

TestKit.run("MapPlan", {
	["grupos únicos y cada parte en un grupo que existe"] = function()
		for name, make in RECIPES do
			local plan = MapPlan.build(make())
			local byKey = groupsByKey(plan)
			equal(#plan.groups, (function()
				local n = 0
				for _ in byKey do
					n += 1
				end
				return n
			end)(), name .. ": claves repetidas")
			for _, g in plan.groups do
				if g.key ~= "Map" then
					truthy(g.parent and byKey[g.parent], name .. ": el padre de " .. g.key .. " no existe")
				end
			end
			for _, p in plan.parts do
				truthy(byKey[p.group], name .. ": " .. p.name .. " está en el grupo inexistente " .. p.group)
			end
		end
	end,

	["partes válidas para Roblox"] = function()
		for name, make in RECIPES do
			local plan = MapPlan.build(make())
			local spawns = 0
			for _, p in plan.parts do
				local label = name .. ": " .. p.name
				for _, value in { p.size.x, p.size.y, p.size.z } do
					truthy(finite(value) and value > 0, label .. " con tamaño inválido")
				end
				for _, value in { p.pos.x, p.pos.y, p.pos.z } do
					truthy(finite(value), label .. " con posición inválida")
				end
				truthy(string.match(p.color, "^#%x%x%x%x%x%x$") ~= nil, label .. " con color " .. p.color)
				truthy(p.material == nil or MATERIALS[p.material], label .. " con material " .. tostring(p.material))
				truthy(p.shape == nil or p.shape == "Block" or p.shape == "Ball" or p.shape == "Cylinder" or p.shape == "Wedge", label .. " con forma " .. tostring(p.shape))
				truthy(p.mesh == nil or p.mesh == "Sphere", label .. " con malla " .. tostring(p.mesh))
				if p.shape == "Ball" then
					truthy(p.size.x == p.size.y and p.size.y == p.size.z, label .. ": una Ball tiene que ser pareja (usar mesh = 'Sphere')")
				elseif p.shape == "Cylinder" then
					truthy(p.size.y == p.size.z, label .. ": el cilindro tiene que ser redondo (Y = Z)")
				end
				if p.spawn then
					spawns += 1
				end
			end
			equal(spawns, 1, name .. ": un solo SpawnLocation")
			equal(#plan.warnings, 0, name .. ": " .. table.concat(plan.warnings, "; "))
		end
	end,

	["bases: espacios, parcelas, tycoon y lo de la entrada en cada una"] = function()
		for name, make in RECIPES do
			local recipe = make()
			local plan = MapPlan.build(recipe)
			local byKey = groupsByKey(plan)
			local _, plotGroups = tagged(plan, "KitPlot")
			local plots = recipe.plots
			equal(#plotGroups, if plots then plots.count else 0, name .. ": bases")
			if plots then
				local orders = attrSet(plotGroups, "Order")
				for i = 1, plots.count do
					equal(orders[i], 1, name .. ": Order " .. i)
				end
				local per: { [string]: { [string]: number } } = {}
				local slotIndex: { [string]: { [number]: boolean } } = {}
				local signs: { [string]: number } = {}
				for _, p in plan.parts do
					local key = plotOf(plan, byKey, p)
					if key then
						per[key] = per[key] or {}
						for _, tag in p.tags or ({} :: { string }) do
							per[key][tag] = (per[key][tag] or 0) + 1
						end
						if hasTag(p.tags, "KitSlot") then
							slotIndex[key] = slotIndex[key] or {}
							slotIndex[key][p.attrs and p.attrs.Index] = true
						end
						if p.name == "Sign" then
							signs[key] = (signs[key] or 0) + 1
						end
					end
				end
				for _, g in plotGroups do
					local tags = per[g.key] or ({} :: { [string]: number })
					equal(tags.KitSlot, plots.maxSlots, name .. " " .. g.key .. ": espacios")
					for i = 1, plots.maxSlots do
						truthy(slotIndex[g.key][i], name .. " " .. g.key .. ": falta el espacio " .. i)
					end
					equal(tags.KitCollectPad, 1, name .. " " .. g.key .. ": cobro")
					equal(tags.KitSpawn, 1, name .. " " .. g.key .. ": reaparecer")
					equal(tags.KitBarrier, 1, name .. " " .. g.key .. ": láser")
					equal(signs[g.key], 1, name .. " " .. g.key .. ": parte Sign")
					equal(tags.KitLockButton, if plots.lock then 1 else nil, name .. " " .. g.key .. ": traba")
					equal(tags.KitSlotShop, if plots.slotPrices then 1 else nil, name .. " " .. g.key .. ": compra de espacios")
					equal(tags.KitGardenTile, if recipe.garden then recipe.garden.maxTiles else nil, name .. " " .. g.key .. ": parcelas")
					equal(tags.KitTycoonButton, if recipe.tycoon then #recipe.tycoon.buildings else nil, name .. " " .. g.key .. ": botones")
				end
				if recipe.tycoon then
					local _, buildings = tagged(plan, "KitBuilding")
					equal(#buildings, plots.count * #recipe.tycoon.buildings, name .. ": un edificio de cada uno por base")
				end
			end
		end
	end,

	["zonas: islas, regiones, puertas y teletransportes"] = function()
		for name, make in RECIPES do
			local recipe = make()
			local plan = MapPlan.build(recipe)
			local zones: { Types.ZoneDef } = if recipe.zones then recipe.zones.list else {}
			local regions = tagged(plan, "KitZone")
			local gates = tagged(plan, "KitGate")
			local teleports = tagged(plan, "KitTeleport")
			equal(#regions, #zones, name .. ": regiones")
			equal(#gates, math.max(0, #zones - 1), name .. ": puertas")
			equal(#teleports, math.max(0, #zones - 1), name .. ": teletransportes")
			local first = nil :: string?
			for _, z in zones do
				if not first or z.order < (function()
					for _, other in zones do
						if other.id == first then
							return other.order
						end
					end
					return math.huge
				end)() then
					first = z.id
				end
			end
			local gateZones = attrSet(gates, "Zone")
			for _, z in zones do
				equal(gateZones[z.id], if z.id == first then nil else 1, name .. ": puerta de " .. z.id)
			end
		end
	end,

	["cada bloque encuentra lo suyo"] = function()
		for name, make in RECIPES do
			local recipe = make()
			local plan = MapPlan.build(recipe)
			local map = recipe.map
			if recipe.rolls then
				local _, stations = tagged(plan, "KitRollStation")
				local ids = attrSet(stations, "Roll")
				for _, def in recipe.rolls.list do
					equal(ids[def.id], 1, name .. ": estación de " .. def.id)
				end
			end
			if recipe.fishing then
				local waters = attrSet((tagged(plan, "KitWater")), "Pool")
				for _, pool in recipe.fishing.pools do
					equal(waters[pool.id], 1, name .. ": agua de " .. pool.id)
				end
			end
			if recipe.search then
				local piles = attrSet((tagged(plan, "KitPile")), "Pile")
				for _, pile in recipe.search.piles do
					equal(piles[pile.id], 1, name .. ": pila " .. pile.id)
				end
				equal(count(plan, "KitDepositPad"), 1, name .. ": depósito")
			end
			if recipe.wild then
				equal(count(plan, "KitWildSpawn"), #recipe.wild.spawns, name .. ": áreas de salvajes")
			end
			if recipe.stages then
				local checkpoints = tagged(plan, "KitCheckpoint")
				local stages = attrSet(checkpoints, "Stage")
				equal(#checkpoints, recipe.stages.count, name .. ": checkpoints")
				for i = 1, recipe.stages.count do
					equal(stages[i], 1, name .. ": checkpoint " .. i)
				end
				equal(count(plan, "KitStageStart"), 1, name .. ": comienzo")
				equal(count(plan, "KitWinPad"), 1, name .. ": meta")
			end
			if map and map.treadmills then
				local islands = if recipe.zones then #recipe.zones.list else 1
				local treadmills = tagged(plan, "KitTreadmill")
				equal(#treadmills, islands * 3, name .. ": tres cintas de correr por isla")
				for _, t in treadmills do
					truthy(t.attrs and t.attrs.Stat == map.treadmills.stat and typeof(t.attrs.Gain) == "number", name .. ": cinta con Stat y Gain")
				end
			end
			equal(count(plan, "KitBelt"), if recipe.belt then 1 else 0, name .. ": cinta")
			equal(count(plan, "KitSellPad"), if recipe.sell then 1 else 0, name .. ": puesto de venta")
			equal(count(plan, "KitUpgradeStation"), if recipe.upgrades then 1 else 0, name .. ": mejoras")
			equal(count(plan, "KitMergeMachine"), if recipe.merge then 1 else 0, name .. ": fusión")
			-- Lobby: un puesto por ventana (la ruleta una sola vez), tablas, cofre y cartel.
			local shops = MapPlan.shops(recipe)
			local _, stands = tagged(plan, "KitShopStand")
			local windows = attrSet(stands, "Window")
			for _, window in shops do
				equal(windows[window], 1, name .. ": puesto " .. window)
			end
			if map and map.spin then
				equal(windows.Spin, 1, name .. ": una sola ruleta")
			end
			local boards = if map and map.leaderboard then math.min(2, #(recipe.leaderstats or { "Money" })) else 0
			equal(count(plan, "KitLeaderboard"), boards, name .. ": tablas de posiciones")
			equal(count(plan, "KitGroupChest"), if map and map.groupChest then 1 else 0, name .. ": cofre del grupo")
		end
	end,

	["nada choca y lo que se usa está sobre un piso"] = function()
		for name, make in RECIPES do
			local plan = MapPlan.build(make())
			local list = plan.footprints
			for i = 1, #list do
				local a = list[i]
				if a.kind == "piece" then
					truthy(MapPlan.onFloor(plan, a), name .. ": " .. a.name .. " no está sobre un piso")
				end
				for j = i + 1, #list do
					local c = list[j]
					if MapPlan.overlaps(a, c) then
						local kinds = a.kind .. "+" .. c.kind
						local bad = kinds == "piece+piece"
							or kinds == "area+area"
							or ((kinds == "piece+corridor" or kinds == "corridor+piece") and (a.solid and a.kind == "piece" or c.solid and c.kind == "piece"))
							or (a.kind == "decor" and c.kind ~= "area")
							or (c.kind == "decor" and a.kind ~= "area")
						truthy(not bad, name .. ": " .. a.name .. " (" .. a.kind .. ") choca con " .. c.name .. " (" .. c.kind .. ")")
					end
				end
			end
		end
	end,

	["el mismo nombre da el mismo mapa"] = function()
		local function fingerprint(plan: MapPlan.Plan): string
			local out = {}
			for _, p in plan.parts do
				table.insert(out, string.format("%s@%.2f,%.2f,%.2f", p.name, p.pos.x, p.pos.y, p.pos.z))
			end
			return table.concat(out, "|")
		end
		local a = fingerprint(MapPlan.build(full()))
		local b = fingerprint(MapPlan.build(full()))
		equal(a == b, true, "mismo plan")
		local other = full()
		other.name = "OtherName"
		equal(fingerprint(MapPlan.build(other)) == a, false, "otro nombre, otra decoración")
	end,

	["tamaño razonable"] = function()
		for name, make in RECIPES do
			local plan = MapPlan.build(make())
			truthy(#plan.parts < 5000, name .. ": " .. #plan.parts .. " partes")
		end
		local plan = MapPlan.build(full())
		truthy(#plan.parts > 300, "el mapa completo tiene contenido")
	end,

	["bases más grandes cuando llevan más cosas"] = function()
		local small = MapPlan.plotLayout(steal())
		local big = MapPlan.plotLayout(full())
		truthy(small.size >= 56 and small.size % 2 == 0, "base de robar: mínimo 56 y par")
		truthy(big.size > small.size, "con cultivo y tycoon, más grande")
	end,

	["biomas por nombre"] = function()
		equal(MapPlan.biome("Sunny Beach"), "beach")
		equal(MapPlan.biome("Snowy Peaks"), "snow")
		equal(MapPlan.biome("LAVA LAND"), "volcano")
		equal(MapPlan.biome("Crystal Caves"), nil)
	end,
})
