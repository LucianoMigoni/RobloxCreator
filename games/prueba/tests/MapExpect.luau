--!strict
-- Lo que cada bloque de una receta tiene que encontrar en su mapa (etiquetas y atributos de
-- Kits/Tags). Lo usan tests/MapPlan.spec y tests/Presets.spec. Devuelve la lista de faltas (vacía = bien).
local MapPlan = require("../src/shared/Lib/MapPlan")
local Types = require("../src/shared/Kits/Types")

local MapExpect = {}

local function hasTag(tags: { string }?, tag: string): boolean
	return tags ~= nil and table.find(tags, tag) ~= nil
end
MapExpect.hasTag = hasTag

-- Partes y grupos con una etiqueta.
function MapExpect.tagged(plan: MapPlan.Plan, tag: string): ({ MapPlan.Part }, { MapPlan.Group })
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
	local parts, groups = MapExpect.tagged(plan, tag)
	return #parts + #groups
end

-- Cuántas veces aparece cada valor de un atributo.
local function attrCounts(list: { any }, name: string): { [any]: number }
	local out: { [any]: number } = {}
	for _, item in list do
		local value = item.attrs and item.attrs[name]
		if value ~= nil then
			out[value] = (out[value] or 0) + 1
		end
	end
	return out
end
MapExpect.attrCounts = attrCounts

-- Base (grupo KitPlot) a la que pertenece una parte, o nil.
local function plotOf(byKey: { [string]: MapPlan.Group }, p: MapPlan.Part): string?
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

function MapExpect.check(recipe: Types.KitConfig, plan: MapPlan.Plan): { string }
	local out: { string } = {}
	local function expect(actual: any, wanted: any, what: string)
		if actual ~= wanted then
			table.insert(out, what .. ": esperado " .. tostring(wanted) .. ", hay " .. tostring(actual))
		end
	end
	local byKey: { [string]: MapPlan.Group } = {}
	for _, g in plan.groups do
		byKey[g.key] = g
	end
	local map = recipe.map

	-- Bases: lo de cada una.
	local plots = recipe.plots
	local _, plotGroups = MapExpect.tagged(plan, "KitPlot")
	expect(#plotGroups, if plots then plots.count else 0, "bases")
	if plots then
		local per: { [string]: { [string]: number } } = {}
		local slotIndex: { [string]: { [number]: boolean } } = {}
		local signs: { [string]: number } = {}
		for _, p in plan.parts do
			local key = plotOf(byKey, p)
			if key then
				local tags = per[key] or {}
				per[key] = tags
				for _, tag in p.tags or ({} :: { string }) do
					tags[tag] = (tags[tag] or 0) + 1
				end
				local attrs = p.attrs
				if hasTag(p.tags, "KitSlot") and attrs and typeof(attrs.Index) == "number" then
					local indexes = slotIndex[key] or {}
					slotIndex[key] = indexes
					indexes[attrs.Index] = true
				end
				if p.name == "Sign" then
					signs[key] = (signs[key] or 0) + 1
				end
			end
		end
		for _, g in plotGroups do
			local tags = per[g.key] or ({} :: { [string]: number })
			local label = g.key .. ": "
			expect(tags.KitSlot or 0, plots.maxSlots, label .. "espacios")
			for i = 1, plots.maxSlots do
				if not (slotIndex[g.key] and slotIndex[g.key][i]) then
					table.insert(out, label .. "falta el espacio " .. i)
				end
			end
			expect(tags.KitCollectPad, 1, label .. "cobro")
			expect(tags.KitSpawn, 1, label .. "reaparecer")
			expect(tags.KitBarrier, 1, label .. "láser")
			expect(signs[g.key], 1, label .. "parte Sign")
			expect(tags.KitLockButton, if plots.lock then 1 else nil, label .. "traba")
			expect(tags.KitSlotShop, if plots.slotPrices and #plots.slotPrices > 0 then 1 else nil, label .. "compra de espacios")
			expect(tags.KitGardenTile, if recipe.garden then recipe.garden.maxTiles else nil, label .. "parcelas")
			expect(tags.KitTycoonButton, if recipe.tycoon then #recipe.tycoon.buildings else nil, label .. "botones")
		end
		if recipe.tycoon then
			local _, buildings = MapExpect.tagged(plan, "KitBuilding")
			expect(#buildings, plots.count * #recipe.tycoon.buildings, "edificios")
		end
	end

	-- Zonas: regiones, puertas (menos la primera) y teletransportes.
	local zones: { Types.ZoneDef } = if recipe.zones then recipe.zones.list else {}
	local regions = MapExpect.tagged(plan, "KitZone")
	local gates = MapExpect.tagged(plan, "KitGate")
	local teleports = MapExpect.tagged(plan, "KitTeleport")
	expect(#regions, #zones, "regiones de zona")
	expect(#gates, math.max(0, #zones - 1), "puertas")
	expect(#teleports, math.max(0, #zones - 1), "teletransportes")
	local first: Types.ZoneDef? = nil
	for _, z in zones do
		if first == nil or z.order < first.order then
			first = z
		end
	end
	local gateZones = attrCounts(gates, "Zone")
	for _, z in zones do
		expect(gateZones[z.id], if first and z.id == first.id then nil else 1, "puerta de " .. z.id)
	end

	-- Cada bloque.
	if recipe.rolls then
		local _, stations = MapExpect.tagged(plan, "KitRollStation")
		local ids = attrCounts(stations, "Roll")
		for _, def in recipe.rolls.list do
			expect(ids[def.id], 1, "estación de " .. def.id)
		end
	end
	if recipe.fishing then
		local waters = attrCounts((MapExpect.tagged(plan, "KitWater")), "Pool")
		for _, pool in recipe.fishing.pools do
			expect(waters[pool.id], 1, "agua de " .. pool.id)
		end
	end
	if recipe.search then
		local piles = attrCounts((MapExpect.tagged(plan, "KitPile")), "Pile")
		for _, pile in recipe.search.piles do
			expect(piles[pile.id], 1, "pila " .. pile.id)
		end
		expect(count(plan, "KitDepositPad"), 1, "depósito")
	end
	if recipe.wild then
		expect(count(plan, "KitWildSpawn"), #recipe.wild.spawns, "áreas de salvajes")
	end
	if recipe.stages then
		local checkpoints = MapExpect.tagged(plan, "KitCheckpoint")
		local stages = attrCounts(checkpoints, "Stage")
		expect(#checkpoints, recipe.stages.count, "checkpoints")
		for i = 1, recipe.stages.count do
			expect(stages[i], 1, "checkpoint " .. i)
		end
		expect(count(plan, "KitStageStart"), 1, "comienzo de etapas")
		expect(count(plan, "KitWinPad"), 1, "meta")
	end
	local treadmills = if map then map.treadmills else nil
	if treadmills then
		local islands = if recipe.zones then #recipe.zones.list else 1
		local list = MapExpect.tagged(plan, "KitTreadmill")
		expect(#list, islands * 3, "cintas de correr")
		for _, t in list do
			local attrs = t.attrs
			if not (attrs and attrs.Stat == treadmills.stat and typeof(attrs.Gain) == "number") then
				table.insert(out, "cinta de correr sin Stat o Gain")
			end
		end
	end
	expect(count(plan, "KitBelt"), if recipe.belt then 1 else 0, "cinta")
	expect(count(plan, "KitSellPad"), if recipe.sell then 1 else 0, "puesto de venta")
	expect(count(plan, "KitUpgradeStation"), if recipe.upgrades then 1 else 0, "mejoras")
	expect(count(plan, "KitMergeMachine"), if recipe.merge then 1 else 0, "fusión")

	-- Lobby: un puesto por ventana (la ruleta una sola vez), tablas, cofre y vitrina.
	local _, stands = MapExpect.tagged(plan, "KitShopStand")
	local windows = attrCounts(stands, "Window")
	for _, window in MapPlan.shops(recipe) do
		expect(windows[window], 1, "puesto " .. window)
	end
	if map and map.spin then
		expect(windows.Spin, 1, "ruleta")
	end
	local boards = if map and map.leaderboard then math.min(2, #(recipe.leaderstats or { "Money" })) else 0
	expect(count(plan, "KitLeaderboard"), boards, "tablas de posiciones")
	expect(count(plan, "KitGroupChest"), if map and map.groupChest then 1 else 0, "cofre del grupo")
	expect(count(plan, "KitShowcase"), if MapPlan.showcase(recipe) then 1 else 0, "vitrina")
	return out
end

return MapExpect
