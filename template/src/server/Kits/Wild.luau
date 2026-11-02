--!strict
-- Bloque Wild del armador: criaturas sueltas que se capturan, como Ride a Dino o los huevos en nidos.
-- Cada parte KitWildSpawn (atributos Pool = número de wild.spawns y, si hace falta, Zone) mantiene
-- hasta `max` criaturas que deambulan dentro de la parte y reaparecen a los `respawn` segundos.
-- Capturar: mantener apretado el prompt "Catch" `captureSeconds` (menos la mejora "capture"; el
-- servidor mide el tiempo apretado, no le cree al cliente) con la zona abierta, lugar en el inventario
-- y, si la unidad tiene `requirement`, la estadística `stat` que alcance. Con `toBase` va a la base.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local UnitModel = require(ReplicatedStorage.Shared.Kits.UnitModel)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Rarity = require(ReplicatedStorage.Shared.Lib.Rarity)
local UnitMath = require(ReplicatedStorage.Shared.Lib.UnitMath)
local Signals = require("../Signals")
local Bonus = require("./Bonus")
local Gates = require("./Gates")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")
local Plots = require("./Plots")
local Stats = require("./Stats")
local Units = require("./Units")

type Creature = {
	model: Model,
	unit: Units.Unit,
	area: Area,
	from: Vector3,
	to: Vector3,
	offset: Vector3, -- del suelo al pivote
	moveStart: number,
	moveTime: number,
	caught: boolean,
	holds: { [Player]: number }, -- cuándo empezó a mantener apretado cada jugador
}

type Area = { part: BasePart, spawn: KitTypes.WildSpawn, zone: string?, alive: { Creature }, nextAt: number }

local Wild = {}

local WANDER_SPEED = 5
local HOLD_SLACK = 0.85 -- se acepta un poco menos por la latencia
local MAX_CAPTURE_BONUS = 0.9
local PROMPT_DISTANCE = 12

local config: KitTypes.WildConfig? = nil
local unitsConfig: KitTypes.UnitsConfig? = nil
local areas: { [BasePart]: Area } = {}
local rng = Random.new()

local function random(): number
	return rng:NextNumber()
end

local function randomPoint(part: BasePart): Vector3
	local x = (rng:NextNumber() - 0.5) * part.Size.X
	local z = (rng:NextNumber() - 0.5) * part.Size.Z
	return (part.CFrame * CFrame.new(x, part.Size.Y / 2, z)).Position
end

local function captureSeconds(player: Player): number
	local cfg = config
	local bonus = math.clamp(Bonus.get(player, "capture"), 0, MAX_CAPTURE_BONUS)
	return (if cfg then cfg.captureSeconds else 0) * (1 - bonus)
end

local function despawn(creature: Creature)
	creature.caught = true
	if creature.model.Parent then
		creature.model:Destroy()
	end
end

local function capture(player: Player, creature: Creature)
	local cfg = config
	if not cfg or creature.caught then
		return
	end
	local started = creature.holds[player]
	creature.holds[player] = nil
	local need = captureSeconds(player)
	if need > 0 and (not started or os.clock() - started < need * HOLD_SLACK) then
		return
	end
	if not Gates.open(player, creature.area.zone) then
		KitFx.send(player, "Error", { code = "ZONE" })
		return
	end
	local def = Units.def(creature.unit.kind)
	local needs = if def then def.requirement else nil
	local stat = cfg.stat
	if needs and stat and Stats.value(player, stat) < needs then
		KitFx.send(player, "Error", { code = "WEAK", needs = needs })
		return
	end
	if Units.isFull(player) then
		KitFx.send(player, "Error", { code = "FULL" })
		return
	end
	local u = creature.unit
	despawn(creature)
	local unit, _, isNew = Units.add(player, u.kind, { source = "Capture", variant = u.variant, size = u.size, weight = u.weight })
	if not unit then
		return
	end
	if cfg.toBase and unit.slot == nil then
		Plots.place(player, unit.uid)
	end
	Signals.track(player, "Capture", 1)
	KitFx.send(player, "Captured", { kind = unit.kind, variant = unit.variant, size = unit.size, isNew = isNew })
end

local function spawnCreature(area: Area)
	local units = unitsConfig
	if not units then
		return
	end
	local entries = UnitMath.entries(area.spawn.entries, Units.defs(), Units.rarities(), units.luckyFrom)
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
	local model = UnitModel.make(def, unit)
	local start = randomPoint(area.part)
	UnitModel.standOn(model, CFrame.new(start))
	local creature: Creature = {
		model = model,
		unit = unit,
		area = area,
		from = start,
		to = start,
		offset = model:GetPivot().Position - start,
		moveStart = os.clock(),
		moveTime = 0,
		caught = false,
		holds = {},
	}
	model.Parent = area.part.Parent or area.part
	local cfg = config :: KitTypes.WildConfig
	local stat = if cfg.stat then Stats.def(cfg.stat) else nil
	local needs = def.requirement
	local prompt = KitWorld.prompt(model, {
		action = UiText.PROMPT_CATCH,
		object = if needs and stat then string.format(UiText.WILD_NEEDS, UnitMath.name(def, unit), Format.number(needs), stat.label) else UnitMath.name(def, unit),
		hold = cfg.captureSeconds,
		distance = PROMPT_DISTANCE,
		name = "Catch",
	})
	if prompt then
		prompt.PromptButtonHoldBegan:Connect(function(player: Player)
			creature.holds[player] = os.clock()
		end)
		prompt.PromptButtonHoldEnded:Connect(function(player: Player)
			-- Soltó antes de tiempo: se borra (si terminó, Triggered ya lo usó).
			task.defer(function()
				creature.holds[player] = nil
			end)
		end)
		KitWorld.onPrompt(prompt, function(player: Player)
			capture(player, creature)
		end, 0.5)
	end
	table.insert(area.alive, creature)
end

local function step()
	local cfg = config
	if not cfg then
		return
	end
	local now = os.clock()
	for _, area in areas do
		for i = #area.alive, 1, -1 do
			local creature = area.alive[i]
			if creature.caught or not creature.model.Parent then
				table.remove(area.alive, i)
				area.nextAt = math.max(area.nextAt, now + area.spawn.respawn)
				continue
			end
			local alpha = if creature.moveTime > 0 then (now - creature.moveStart) / creature.moveTime else 1
			if alpha >= 1 then
				-- Llegó: elige otro punto de su área.
				creature.from = creature.to
				creature.to = randomPoint(area.part)
				creature.moveStart = now
				creature.moveTime = (creature.to - creature.from).Magnitude / WANDER_SPEED + rng:NextNumber() * 2
			else
				local position = creature.from:Lerp(creature.to, math.clamp(alpha, 0, 1))
				local facing = if (creature.to - creature.from).Magnitude > 0.1 then CFrame.lookAt(creature.from, creature.to).Rotation else CFrame.identity
				creature.model:PivotTo(facing + position + creature.offset)
			end
		end
		if #area.alive < area.spawn.max and now >= area.nextAt then
			area.nextAt = now + 1
			spawnCreature(area)
		end
	end
end

function Wild.init(recipe: KitTypes.KitConfig)
	config = recipe.wild
	unitsConfig = recipe.units
end

function Wild.start(_recipe: KitTypes.KitConfig)
	local cfg = config
	if not cfg then
		return
	end
	KitWorld.tagged(Tags.WILD_SPAWN, function(instance: Instance)
		local part = KitWorld.part(instance)
		local index = KitWorld.number(instance, "Pool") or 1
		local spawn = cfg.spawns[index]
		if not part or not spawn or areas[part] then
			if not spawn then
				warn("[Wild] " .. instance:GetFullName() .. ": Pool " .. index .. " no existe en wild.spawns")
			end
			return
		end
		areas[part] = { part = part, spawn = spawn, zone = spawn.zone or KitWorld.inherited(instance, "Zone"), alive = {}, nextAt = os.clock() }
	end, function(instance: Instance)
		local part = if instance:IsA("BasePart") then instance else nil
		local area = if part then areas[part] else nil
		if area and part then
			areas[part] = nil
			for _, creature in area.alive do
				despawn(creature)
			end
		end
	end)
	RunService.Heartbeat:Connect(step)
	Players.PlayerRemoving:Connect(function(player: Player)
		for _, area in areas do
			for _, creature in area.alive do
				creature.holds[player] = nil
			end
		end
	end)
end

return Wild
