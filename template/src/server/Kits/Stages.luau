--!strict
-- Bloque Stages del armador: escape y obby por etapas (+1 Speed Keyboard Escape) o corrida con resumen
-- (Ride a Dino).
-- - Obby: tocar el checkpoint KitCheckpoint (atributo Stage) guarda la etapa si es más alta y, si la
--   receta pide `requirements` de `stat`, si el jugador llega (el servidor no cree en el salto: valida).
--   Al reaparecer vuelve a su etapa. La meta KitWinPad, con todas las etapas, da `reward` (× el
--   multiplicador de esa moneda: "2x Wins") y con `returnToStart` lo manda al KitStageStart.
-- - Corrida (`run`): empieza al pisar KitStageStart; cada etapa nueva suma; al morir se pausa y el
--   jugador elige revivir (gratis `freeRevives` veces, después el producto "Stages:Revive") o terminar:
--   el resumen paga `reward` por etapa alcanzada. La meta termina la corrida con todo.
-- Premio "Stages:Revive": revive ya si está muerto en una corrida; si no, queda guardado.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Types = require(ReplicatedStorage.Shared.Types)
local BoostService = require("../Boosts/BoostService")
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Signals = require("../Signals")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")
local Stats = require("./Stats")

type StagesData = { stage: number, best: number, wins: number, revives: number }
type Run = { stage: number, dead: boolean, freeUsed: number, reviving: boolean, record: boolean }

local Stages = {}

local SPAWN_HEIGHT = 4
local RESPAWN_DELAY = 0.15 -- después del reaparecer de la base (Plots), para que gane la etapa

local config: KitTypes.StagesConfig? = nil
local runs: { [Player]: Run } = {}

local function data(player: Player): StagesData?
	local d = DataService.get(player)
	return if d then d.kits.stages :: StagesData else nil
end

local function checkpoint(stage: number): BasePart?
	for _, instance in CollectionService:GetTagged(Tags.CHECKPOINT) do
		if KitWorld.number(instance, "Stage") == stage then
			return KitWorld.part(instance)
		end
	end
	return nil
end

local function startPart(): BasePart?
	local list = CollectionService:GetTagged(Tags.STAGE_START)
	return if list[1] then KitWorld.part(list[1]) else nil
end

local function moveTo(player: Player, part: BasePart?)
	local character = player.Character
	if part and character then
		character:PivotTo(part.CFrame + Vector3.new(0, part.Size.Y / 2 + SPAWN_HEIGHT, 0))
	end
end

-- Lo que paga `amount` de la moneda del premio, con su multiplicador ("Wins" → Mult_Wins).
local function pay(player: Player, amount: number, sku: string): number
	local cfg = config
	if not cfg or amount <= 0 then
		return 0
	end
	local total = amount * BoostService.multiplier(player, cfg.reward.currency)
	CurrencyService.add(player, total, Enum.AnalyticsEconomyTransactionType.Gameplay, sku, cfg.reward.currency)
	return math.floor(total)
end

local function allowed(player: Player, stage: number): boolean
	local cfg = config
	local requirements = if cfg then cfg.requirements else nil
	local stat = if cfg then cfg.stat else nil
	if not requirements or not stat then
		return true
	end
	return Stats.value(player, stat) >= (requirements[stage] or 0)
end

local function reach(player: Player, stage: number)
	local d = data(player)
	local cfg = config
	if not d or not cfg or stage < 1 or stage > cfg.count then
		return
	end
	if not allowed(player, stage) then
		return
	end
	local run = runs[player]
	if cfg.run then
		if not run or run.dead or stage <= run.stage then
			return
		end
		run.stage = stage
	elseif stage <= d.stage then
		return
	else
		d.stage = stage
	end
	-- "NEW RECORD!" una vez por corrida, al pasar el mejor anterior (en el obby cada etapa nueva ya lo es).
	local record = false
	if stage > d.best then
		if run and d.best > 0 and not run.record then
			run.record = true
			record = true
		end
		d.best = stage
	end
	Signals.track(player, "Stage", 1)
	KitFx.send(player, "Stage", { stage = stage, record = record })
	Signals.dirty(player)
end

local function endRun(player: Player, finished: boolean)
	local run = runs[player]
	local cfg = config
	if not run or not cfg then
		return
	end
	runs[player] = nil
	local stages = if finished then cfg.count else run.stage
	local earned = pay(player, cfg.reward.amount * stages, "RunEnd")
	Signals.track(player, "RunEnded", 1)
	if finished then
		Signals.track(player, "Win", 1)
	end
	local d = data(player)
	KitFx.send(player, "RunEnded", { stage = stages, earned = earned, best = if d then d.best else stages, finished = finished })
	Signals.dirty(player)
end

local function win(player: Player)
	local d = data(player)
	local cfg = config
	if not d or not cfg then
		return
	end
	if cfg.run then
		local run = runs[player]
		if run and not run.dead and run.stage >= cfg.count then
			endRun(player, true)
		end
		return
	end
	if d.stage < cfg.count then
		return
	end
	d.wins += 1
	local earned = pay(player, cfg.reward.amount, "Win")
	Signals.track(player, "Win", 1)
	KitFx.send(player, "Win", { wins = d.wins, earned = earned })
	if cfg.returnToStart then
		d.stage = 0
		moveTo(player, startPart())
	end
	Signals.dirty(player)
end

-- Revive en la corrida: gratis mientras queden, después con lo comprado ("Stages:Revive").
function Stages.revive(player: Player): (boolean, string?)
	local cfg = config
	local run = runs[player]
	local d = data(player)
	local runCfg = if cfg then cfg.run else nil
	if not run or not run.dead or not runCfg or not d then
		return false, "NOT_DEAD"
	end
	if run.freeUsed < runCfg.freeRevives then
		run.freeUsed += 1
	elseif d.revives > 0 then
		d.revives -= 1
	else
		return false, "NO_REVIVES"
	end
	run.dead = false
	run.reviving = true
	Signals.track(player, "Revive", 1)
	-- Si ya reapareció, va ya a su checkpoint; si no, lo lleva el CharacterAdded.
	if KitWorld.humanoid(player) then
		run.reviving = false
		moveTo(player, checkpoint(run.stage) or startPart())
	end
	KitFx.send(player, "Revived", { stage = run.stage })
	Signals.dirty(player)
	return true
end

local function give(player: Player, _value: string, count: number): (boolean, Types.RewardLine?)
	local d = data(player)
	if not d then
		return false, nil
	end
	d.revives += count
	local run = runs[player]
	if run and run.dead then
		Stages.revive(player)
	end
	Signals.dirty(player)
	return true, { icon = "heart", text = UiText.REVIVED, kind = "item" }
end

function Stages.init(recipe: KitTypes.KitConfig)
	config = recipe.stages
	if config then
		DataService.registerKit("stages", { stage = 0, best = 0, wins = 0, revives = 0 })
	end
end

function Stages.start(_recipe: KitTypes.KitConfig)
	local cfg = config
	if not cfg then
		return
	end
	local symbol = UiText.STAGE_SIGN
	KitWorld.tagged(Tags.CHECKPOINT, function(instance: Instance)
		local part = KitWorld.part(instance)
		local stage = KitWorld.number(instance, "Stage")
		if not part or not stage then
			return
		end
		local requirements = cfg.requirements
		local stat = if cfg.stat then Stats.def(cfg.stat) else nil
		local need = if requirements then requirements[stage] else nil
		local text = if need and stat and need > 0 then string.format(UiText.STAGE_NEEDS, stage, Format.number(need), stat.label) else string.format(symbol, stage)
		KitWorld.sign(instance, text, "Info", nil, 9)
		KitWorld.onTouch(part, function(player: Player)
			reach(player, stage)
		end, 0.5)
	end)
	KitWorld.tagged(Tags.WIN_PAD, function(instance: Instance)
		local part = KitWorld.part(instance)
		if part then
			KitWorld.sign(instance, UiText.WIN_SIGN, "Premium", "trophy", 10)
			KitWorld.onTouch(part, win, 1.5)
		end
	end)
	KitWorld.tagged(Tags.STAGE_START, function(instance: Instance)
		local part = KitWorld.part(instance)
		if not part then
			return
		end
		KitWorld.sign(instance, UiText.START_SIGN, "Accept", nil, 9)
		if cfg.run then
			KitWorld.onTouch(part, function(player: Player)
				-- Una corrida muerta sin decidir termina al volver a empezar.
				local old = runs[player]
				if old and old.dead then
					endRun(player, false)
				end
				if not runs[player] and data(player) then
					runs[player] = { stage = 0, dead = false, freeUsed = 0, reviving = false, record = false }
					Signals.track(player, "RunStarted", 1)
					KitFx.send(player, "RunStarted", {})
					Signals.dirty(player)
				end
			end, 2)
		end
	end)
	if cfg.run then
		Remotes.onInvoke("Revive", { args = {}, rate = { count = 2, perSeconds = 1 } }, Stages.revive)
		Remotes.onEvent("EndRun", { args = {}, rate = { count = 2, perSeconds = 1 } }, function(player: Player)
			local run = runs[player]
			if run and run.dead then
				endRun(player, false)
			end
		end)
	end
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			local humanoid = character:WaitForChild("Humanoid", 10)
			if humanoid and humanoid:IsA("Humanoid") then
				humanoid.Died:Connect(function()
					local run = runs[player]
					if run and not run.dead then
						run.dead = true
						local runCfg = cfg.run
						local d = data(player)
						local freeLeft = if runCfg then runCfg.freeRevives - run.freeUsed else 0
						KitFx.send(player, "RunDied", { stage = run.stage, freeLeft = freeLeft, bought = if d then d.revives else 0 })
						Signals.dirty(player)
					end
				end)
			end
			task.wait(RESPAWN_DELAY)
			if not character.Parent then
				return
			end
			local run = runs[player]
			if run then
				if run.reviving then
					run.reviving = false
					moveTo(player, checkpoint(run.stage) or startPart())
				end
				return
			end
			local d = data(player)
			if d and not cfg.run and d.stage > 0 then
				moveTo(player, checkpoint(d.stage))
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		runs[player] = nil
	end)
end

function Stages.snapshot(player: Player): KitTypes.StagesState?
	local d = data(player)
	local cfg = config
	if not d or not cfg then
		return nil
	end
	local run = runs[player]
	local runCfg = cfg.run
	return {
		stage = if run then run.stage else d.stage,
		best = d.best,
		wins = d.wins,
		revives = d.revives,
		run = if run and runCfg then { active = true, dead = run.dead, stage = run.stage, freeLeft = runCfg.freeRevives - run.freeUsed } else nil,
	}
end

Stages.items = { Stages = give }

return Stages
