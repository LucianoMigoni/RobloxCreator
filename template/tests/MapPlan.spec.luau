--!strict
-- Plan del mapa (Lib/MapPlan): cada bloque encuentra sus partes con las etiquetas y atributos que
-- espera, nada choca, lo que se usa está sobre un piso y el mismo nombre da el mismo mapa.
local TestKit = require("./TestKit")
local MapExpect = require("./MapExpect")
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

local hasTag = MapExpect.hasTag
local tagged = MapExpect.tagged

local function groupsByKey(plan: MapPlan.Plan): { [string]: MapPlan.Group }
	local out: { [string]: MapPlan.Group } = {}
	for _, g in plan.groups do
		out[g.key] = g
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

	["cada bloque encuentra lo suyo (bases, zonas, puestos, vitrina)"] = function()
		for name, make in RECIPES do
			local recipe = make()
			local missing = MapExpect.check(recipe, MapPlan.build(recipe))
			equal(#missing, 0, name .. ": " .. table.concat(missing, "; "))
		end
	end,

	["las faltas se notan"] = function()
		-- Un plan al que le sacan un espacio de una base y la meta tiene que fallar.
		local recipe = full()
		local plan = MapPlan.build(recipe)
		for i = #plan.parts, 1, -1 do
			local p = plan.parts[i]
			if p.name == "Slot3" or p.name == "Win" then
				table.remove(plan.parts, i)
			end
		end
		local missing = MapExpect.check(recipe, plan)
		truthy(#missing >= 2, "faltas: " .. table.concat(missing, "; "))
	end,

	["nada choca y lo que se usa está sobre un piso"] = function()
		for name, make in RECIPES do
			local problems = MapPlan.audit(MapPlan.build(make()))
			equal(#problems, 0, name .. ": " .. table.concat(problems, "; "))
		end
	end,

	["vitrina y arcos de las zonas"] = function()
		for name, make in RECIPES do
			local recipe = make()
			local plan = MapPlan.build(recipe)
			local wanted = MapPlan.showcase(recipe)
			local _, showcases = tagged(plan, "KitShowcase")
			equal(#showcases, if wanted then 1 else 0, name .. ": vitrina")
			if wanted then
				local attrs = showcases[1].attrs
				equal(if attrs then attrs.Unit else nil, wanted, name .. ": unidad de la vitrina")
			end
			local arches = 0
			for _, g in plan.groups do
				if string.sub(g.name, 1, 9) == "ZoneArch_" then
					arches += 1
					truthy(hasTag(g.tags, "HitSign") and g.attrs and typeof(g.attrs.Text) == "string", name .. ": arco con cartel")
				end
			end
			equal(arches, if recipe.zones then #recipe.zones.list else 0, name .. ": un arco por zona")
		end
		-- La vitrina usa la unidad pedida o la última; "" la saca.
		local recipe = steal()
		recipe.units = { label = "Snacks", maxInventory = 10, list = { { id = "A", name = "A", rarity = "Common" }, { id = "B", name = "B", rarity = "Secret" } } }
		equal(MapPlan.showcase(recipe), "B")
		local map = recipe.map :: Types.MapConfig
		map.showcase = "A"
		equal(MapPlan.showcase(recipe), "A")
		map.showcase = ""
		equal(MapPlan.showcase(recipe), nil)
	end,

	["bases en corral o en edificio"] = function()
		local recipe = steal()
		local pen = MapPlan.build(recipe)
		local map = recipe.map :: Types.MapConfig
		map.bases = "building"
		local building = MapPlan.build(recipe)
		local function count2(plan: MapPlan.Plan, partName: string): number
			local n = 0
			for _, p in plan.parts do
				if p.name == partName then
					n += 1
				end
			end
			return n
		end
		truthy(count2(pen, "FenceRail") > 0 and count2(pen, "Wall") == 0, "corral: cercos")
		truthy(count2(building, "Wall") > 0, "edificio: paredes")
		equal(#MapPlan.audit(building), 0, "edificio sano")
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
